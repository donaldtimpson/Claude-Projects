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

    private let container: ModelContainer
    private var ctx: ModelContext { container.mainContext }

    private init() {
        do { container = try ModelContainer(for: DrillItemMastery.self) }
        catch { fatalError("DrillMastery SwiftData container: \(error)") }
    }

    private func key(_ userId: String, _ slug: String, _ item: String) -> String {
        "\(userId):\(slug):\(item)"
    }

    // Wipe every local Leitner box (account deletion) — see LessonProgress.purgeAll.
    func purgeAll() {
        try? ctx.delete(model: DrillItemMastery.self)
        try? ctx.save()
    }

    private func row(_ key: String) -> DrillItemMastery? {
        var d = FetchDescriptor<DrillItemMastery>(predicate: #Predicate { $0.key == key })
        d.fetchLimit = 1
        return try? ctx.fetch(d).first
    }

    func box(userId: String, slug: String, item: String) -> Int {
        row(key(userId, slug, item))?.box ?? 0
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
        return r.box
    }

    func masteredCount(userId: String, slug: String, items: [String]) -> Int {
        items.reduce(0) { $0 + (box(userId: userId, slug: slug, item: $1) >= Self.masteredBox ? 1 : 0) }
    }

}

// A never-ending Learn session using graduated introduction + expanding rehearsal
// (Anki-style "learning steps" + a new-item cap). New items are introduced only a few at
// a time (due reviews take priority), a freshly-seen item recurs soon and then at widening
// gaps as it sticks, and a miss resets it to the short interval. Scheduling is by "card
// position from now"; the session never ends — once everything is mastered it keeps
// cycling all items at long, jittered intervals. Persistent mastery lives in DrillMastery.
@MainActor
final class LearnSession {
    private let userId: String
    private let slug: String
    private let store = DrillMastery.shared
    let items: [String]

    // Reappearance gaps (cards ahead) for successive correct reps; after the last the card
    // "graduates" (long review interval). A miss sends it back to steps[0].
    private let steps = [3, 4, 6, 10]
    private let reviewInterval = 16
    private let maxLearning = 4          // cap on items still in the learning stage → gentle intro

    private struct Card { var id: String; var due: Int; var step: Int }  // step >= steps.count ⇒ graduated
    private var scheduled: [Card] = []
    private var newQueue: [String] = []
    private var t = 0
    private var currentId: String?

    private(set) var answered = 0
    private(set) var correctCount = 0

    init(userId: String, slug: String, items: [String]) {
        self.userId = userId; self.slug = slug; self.items = items
        for id in items.shuffled() {
            let box = store.box(userId: userId, slug: slug, item: id)
            if box == 0 {
                newQueue.append(id)                                   // not yet introduced
            } else if box >= DrillMastery.masteredBox {
                scheduled.append(Card(id: id, due: Int.random(in: 1...reviewInterval), step: steps.count))
            } else {
                scheduled.append(Card(id: id, due: Int.random(in: 1...6), step: min(box, steps.count - 1)))
            }
        }
    }

    var masteredCount: Int { store.masteredCount(userId: userId, slug: slug, items: items) }
    private var learningCount: Int { scheduled.filter { $0.step < steps.count }.count }

    /// The next item to show (nil only if the pool is empty). Never terminates otherwise.
    func next() -> String? {
        guard !items.isEmpty else { return nil }
        t += 1
        if let i = dueIndex() {                                       // a review is due — highest priority
            currentId = scheduled[i].id
        } else if !newQueue.isEmpty && learningCount < maxLearning {  // room to introduce a new one
            let id = newQueue.removeFirst()
            scheduled.append(Card(id: id, due: t, step: 0))
            currentId = id
        } else if let i = soonestIndex() {                            // nothing due — bring the next one forward
            currentId = scheduled[i].id
        }
        return currentId
    }

    func grade(correct: Bool) {
        answered += 1
        if correct { correctCount += 1 }
        guard let id = currentId, let i = scheduled.firstIndex(where: { $0.id == id }) else { return }
        store.grade(userId: userId, slug: slug, item: id, correct: correct)   // persistent mastery
        if correct {
            let s = scheduled[i].step
            if s < steps.count {
                scheduled[i].due = t + steps[s]
                scheduled[i].step = s + 1
            } else {
                scheduled[i].due = t + reviewInterval + Int.random(in: 0...6)
            }
        } else {
            scheduled[i].step = 0
            scheduled[i].due = t + steps[0]
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
