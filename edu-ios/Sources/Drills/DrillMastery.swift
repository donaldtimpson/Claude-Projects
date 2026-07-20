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

    /// Build a session deck: weakest/newest items first (by box, shuffled within a tier),
    /// plus a small maintenance sample of already-mastered items so they still surface
    /// occasionally. If everything is mastered, returns a shuffled review of all items.
    func buildDeck(userId: String, slug: String, items: [String], maintenance: Int = 4) -> [String] {
        let b = boxes(userId: userId, slug: slug, items: items)
        let weak = items.filter { (b[$0] ?? 0) < Self.masteredBox }
        let mastered = items.filter { (b[$0] ?? 0) >= Self.masteredBox }
        if weak.isEmpty { return mastered.shuffled() }
        let weakSorted = Dictionary(grouping: weak) { b[$0] ?? 0 }
            .sorted { $0.key < $1.key }
            .flatMap { $0.value.shuffled() }
        return weakSorted + Array(mastered.shuffled().prefix(maintenance))
    }

    private func boxes(userId: String, slug: String, items: [String]) -> [String: Int] {
        var out: [String: Int] = [:]
        for it in items { out[it] = box(userId: userId, slug: slug, item: it) }
        return out
    }
}
