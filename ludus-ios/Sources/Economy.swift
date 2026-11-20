import SwiftUI

// MARK: - The Ludus economy
//
// Two coins, two jobs:
//   • DENARII (silver) — spending money. Every game pays the SAME: 1 per correct answer, +5 per level
//     climbed (GameKit). Score is each game's own business; denarii are fair across the arcade.
//   • AUREI (gold) — earned only by LAURELS: bronze 1, silver 2, gold 3 per game (so up to 6 a game).
//     Never bought with denarii. Computed from progress, so laurels won before this existed count.
//
// RANK is pinned to aurei EARNED (not the balance), so spending never demotes a child:
//   Tiro → Legionary (5) → Centurion (20) → Consul (50).
//
// Both coins are spent at the Villa (VillaView): garden, statues, pets, grand works.

enum LudusEconomy {
    static let spentAureiKey = "ludus_aurei_spent"
    static let ownedKey = "ludus_villa_owned"

    // MARK: Aurei

    /// Aurei earned so far — from every laurel held across the arcade.
    static var aureiEarned: Int {
        var n = 0
        for w in ludusWorlds {
            for g in w.games where g.playable { n += [0, 1, 3, 6][g.medal.rawValue] }
        }
        return n
    }
    static var aureiSpent: Int { LudusStore.defaults.integer(forKey: spentAureiKey) }
    static var aurei: Int { max(0, aureiEarned - aureiSpent) }

    // MARK: Rank

    struct Rank { let index: Int; let name: String; let next: Int? }
    static let rankSteps: [(String, Int)] = [("Tiro", 0), ("Legionary", 5), ("Centurion", 20), ("Consul", 50)]
    static var rank: Rank { rank(forAurei: aureiEarned) }
    static func rank(forAurei a: Int) -> Rank {
        var i = 0
        for (k, s) in rankSteps.enumerated() where a >= s.1 { i = k }
        return Rank(index: i, name: rankSteps[i].0, next: i + 1 < rankSteps.count ? rankSteps[i + 1].1 : nil)
    }

    // MARK: Villa purchases

    static var owned: Set<String> {
        Set(LudusStore.defaults.stringArray(forKey: ownedKey) ?? [])
    }
    static func owns(_ id: String) -> Bool { owned.contains(id) }

    /// Buys an item if affordable. Returns true on success.
    @discardableResult
    static func buy(_ item: VillaItem) -> Bool {
        guard !owns(item.id) else { return false }
        switch item.price {
        case .denarii(let n):
            guard LudusStore.denarii >= n else { return false }
            LudusStore.defaults.set(LudusStore.denarii - n, forKey: LudusStore.denariiKey)
        case .aurei(let n):
            guard aurei >= n else { return false }
            LudusStore.defaults.set(aureiSpent + n, forKey: spentAureiKey)
        }
        var o = owned; o.insert(item.id)
        LudusStore.defaults.set(Array(o), forKey: ownedKey)
        return true
    }

    static func canAfford(_ item: VillaItem) -> Bool {
        switch item.price {
        case .denarii(let n): return LudusStore.denarii >= n
        case .aurei(let n): return aurei >= n
        }
    }
}
