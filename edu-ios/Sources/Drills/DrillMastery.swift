import Foundation
import SwiftData

// On-device mastery for Learn mode (spaced-repetition, prototype v1 — no backend yet).
// Each drill item (a country/state, keyed "<userId>:<slug>:<itemId>") carries a Leitner
// box 0…5: correct promotes, wrong demotes, box 5 = mastered. Stored in its own SwiftData
// container so it's fully decoupled from the offline write queue.
@Model
final class DrillItemMastery {
    @Attribute(.unique) var key: String
    var box: Int
    var reps: Int
    var lapses: Int
    var lastSeen: Date

    init(key: String, box: Int = 0, reps: Int = 0, lapses: Int = 0, lastSeen: Date = .now) {
        self.key = key; self.box = box; self.reps = reps; self.lapses = lapses; self.lastSeen = lastSeen
    }
}

@MainActor
final class DrillMastery {
    static let shared = DrillMastery()
    static let masteredBox = 5

    private var ctx: ModelContext { DrillStore.container.mainContext }

    private init() {}

    private func key(_ userId: String, _ slug: String, _ item: String) -> String {
        "\(userId):\(slug):\(item)"
    }

    // Boxes for one (user, drill), item id → box, read with a SINGLE fetch and kept.
    // Callers ask per item — masteredCount over the Grammar Gauntlet is 601 lookups, and
    // LearnSession.init is one per item in the pool — so a fetch each meant hundreds of
    // predicate fetches on the main thread every time a row was laid out. This is the
    // only writer, so the cache can't go stale behind our back.
    private var boxes: [String: [String: Int]] = [:]

    private func boxes(userId: String, slug: String) -> [String: Int] {
        let scope = "\(userId):\(slug)"
        if let cached = boxes[scope] { return cached }
        let prefix = scope + ":"
        let rows = (try? ctx.fetch(FetchDescriptor<DrillItemMastery>(
            predicate: #Predicate { $0.key.starts(with: prefix) }))) ?? []
        var map: [String: Int] = [:]
        map.reserveCapacity(rows.count)
        for r in rows { map[String(r.key.dropFirst(prefix.count))] = r.box }
        boxes[scope] = map
        return map
    }

    // Wipe every local Leitner box (account deletion) — see LessonProgress.purgeAll.
    func purgeAll() {
        boxes.removeAll()
        try? ctx.delete(model: DrillItemMastery.self)
        try? ctx.save()
    }

    private func row(_ key: String) -> DrillItemMastery? {
        var d = FetchDescriptor<DrillItemMastery>(predicate: #Predicate { $0.key == key })
        d.fetchLimit = 1
        return try? ctx.fetch(d).first
    }

    func box(userId: String, slug: String, item: String) -> Int {
        boxes(userId: userId, slug: slug)[item] ?? 0
    }

    /// Grade one item and return its new box. Correct → +1 (cap 5); wrong → −2 (floor 0, +lapse).
    @discardableResult
    func grade(userId: String, slug: String, item: String, correct: Bool) -> Int {
        let k = key(userId, slug, item)
        let r: DrillItemMastery
        if let existing = row(k) { r = existing }
        else { r = DrillItemMastery(key: k); ctx.insert(r) }
        if correct {
            r.box = min(r.box + 1, Self.masteredBox)
        } else {
            if r.box > 0 { r.lapses += 1 }
            r.box = max(r.box - 2, 0)
        }
        r.reps += 1
        r.lastSeen = .now
        try? ctx.save()
        _ = boxes(userId: userId, slug: slug)      // ensure the scope is loaded before we patch it
        boxes["\(userId):\(slug)"]?[item] = r.box
        return r.box
    }

    func masteredCount(userId: String, slug: String, items: [String]) -> Int {
        let map = boxes(userId: userId, slug: slug)
        return items.reduce(0) { $0 + ((map[$1] ?? 0) >= Self.masteredBox ? 1 : 0) }
    }

    /// How far along `items` are toward mastery, 0…1, with partial credit for every box.
    /// Mastery takes five correct reps, so on a large pool "N mastered" only ticks once per
    /// five right answers and reads as stuck — this moves on every one of them.
    func progress(userId: String, slug: String, items: [String]) -> Double {
        guard !items.isEmpty else { return 0 }
        let map = boxes(userId: userId, slug: slug)
        let sum = items.reduce(0) { $0 + min(map[$1] ?? 0, Self.masteredBox) }
        return Double(sum) / Double(items.count * Self.masteredBox)
    }

}

// A never-ending Learn session using graduated introduction + expanding rehearsal
// (Anki-style "learning steps" + a new-item cap). A freshly-introduced item recurs soon and
// then at widening gaps as it sticks; anything already known to some degree comes back as a
// review, spaced by how well it's known; a miss drops an item back to the short interval.
// Scheduling is by "card position from now"; the session never ends — once everything is
// mastered it keeps cycling at long intervals. Persistent mastery lives in DrillMastery.
//
// The distinction between LEARNING and REVIEW is load-bearing. `maxLearning` caps how many
// items are mid-introduction at once, and restoring every partially-known item as "learning"
// filled that cap on the first card of any resumed session — so the new queue never drained.
// The bigger the pool the worse it read: Easy behaved (its pool is barely larger than the
// items you'd started), while Hard just re-drilled the same handful and never once reached
// the hard material.
@MainActor
final class LearnSession {
    private let userId: String
    private let slug: String
    private let store = DrillMastery.shared
    let items: [String]

    // Reappearance gaps (cards ahead) for successive correct reps while an item is being
    // introduced; after the last it graduates onto the review schedule. A miss sends it back
    // to steps[0] (a lapse re-enters learning, which is why the cap is self-limiting).
    private let steps = [3, 4, 6, 10]
    private let newEvery = 5             // a new item gets a turn at least this often
    // How many items may be mid-introduction at once. Scales with the deck: four at a time
    // over the Gauntlet's 601 items is a trickle, while four is right for a 45-item lesson.
    // Capped at eight — measured over simulated sessions, going past that gets more items
    // SEEN but fewer actually mastered, which is the wrong trade for a learning mode.
    private let maxLearning: Int

    // `step` drives spacing (>= steps.count ⇒ on the review schedule). `intro` is separate on
    // purpose: it means "being met for the first time this session", and ONLY intro cards count
    // against maxLearning. Deriving that from `step` instead conflated two different things —
    // a review you just lapsed also sits at a low step, so a normal miss rate kept the
    // introduction cap permanently full and new material still never arrived.
    private struct Card { var id: String; var due: Int; var step: Int; var intro: Bool }
    private var scheduled: [Card] = []
    private var newQueue: [String] = []
    private var t = 0
    private var lastIntroT = 0
    private var currentId: String?

    private(set) var answered = 0
    private(set) var correctCount = 0

    init(userId: String, slug: String, items: [String]) {
        self.userId = userId; self.slug = slug; self.items = items
        self.maxLearning = min(8, max(4, items.count / 75))
        for id in items.shuffled() {
            let box = store.box(userId: userId, slug: slug, item: id)
            if box == 0 {
                newQueue.append(id)          // never introduced, or missed all the way back down
            } else {
                // Already known to some degree ⇒ a REVIEW, spaced by how well it's known.
                // Not a learning card: it must not consume the introduction cap.
                scheduled.append(Card(id: id, due: Int.random(in: 1...reviewGap(box)),
                                      step: steps.count, intro: false))
            }
        }
    }

    // Review spacing in cards-from-now, by persistent box. A barely-known item comes back
    // soon; a mastered one rarely, so the pool keeps making room for new material.
    private func reviewGap(_ box: Int) -> Int {
        switch box {
        case 0, 1: return 6
        case 2:    return 10
        case 3:    return 15
        case 4:    return 22
        default:   return 30
        }
    }

    var masteredCount: Int { store.masteredCount(userId: userId, slug: slug, items: items) }
    /// 0…1 toward mastering the whole pool, with partial credit per box.
    var progress: Double { store.progress(userId: userId, slug: slug, items: items) }
    private var learningCount: Int { scheduled.reduce(0) { $0 + ($1.intro ? 1 : 0) } }

    /// The next item to show (nil only if the pool is empty). Never terminates otherwise.
    func next() -> String? {
        guard !items.isEmpty else { return nil }
        t += 1
        let due = dueIndex()
        let roomForNew = !newQueue.isEmpty && learningCount < maxLearning
        // Due reviews come first, but never to the point of never reaching new material:
        // while there's room under the cap, a new item takes a turn every `newEvery` cards.
        // Without that, a pool with more due reviews than the session can clear (any large
        // Hard pool) would introduce nothing at all.
        if roomForNew && (due == nil || t - lastIntroT >= newEvery) {
            let id = newQueue.removeFirst()
            scheduled.append(Card(id: id, due: t, step: 0, intro: true))
            lastIntroT = t
            currentId = id
        } else if let i = due {
            currentId = scheduled[i].id
        } else if let i = soonestIndex() {                            // nothing due — pull the next one forward
            currentId = scheduled[i].id
        }
        return currentId
    }

    func grade(correct: Bool) {
        answered += 1
        if correct { correctCount += 1 }
        guard let id = currentId, let i = scheduled.firstIndex(where: { $0.id == id }) else { return }
        let box = store.grade(userId: userId, slug: slug, item: id, correct: correct)   // persistent mastery
        if !correct {
            scheduled[i].step = 0                                     // a lapse re-enters learning
            scheduled[i].due = t + steps[0]
        } else if scheduled[i].step < steps.count {
            scheduled[i].due = t + steps[scheduled[i].step]
            scheduled[i].step += 1
            if scheduled[i].step >= steps.count { scheduled[i].intro = false }   // introduced; frees a slot
        } else {
            scheduled[i].due = t + reviewGap(box) + Int.random(in: 0...4)
        }
    }

    private func dueIndex() -> Int? {
        var best: Int?
        for (i, c) in scheduled.enumerated() where c.due <= t {
            if best == nil || c.due < scheduled[best!].due { best = i }
        }
        return best
    }
    private func soonestIndex() -> Int? {
        guard !scheduled.isEmpty else { return nil }
        var best = 0
        for (i, c) in scheduled.enumerated() where c.due < scheduled[best].due { best = i }
        return best
    }
}
