import SwiftUI

// MARK: - Critter Sort  (Lab Rats · lane-sorter, animal classes)
//
// An animal tile (big picture + name) drifts down; tap the bin of its class. Built on the shared
// lane sorter (Games/LaneSorter.swift) and GameKit. A miss flies the animal to its right bin and
// says why ("A bat is a MAMMAL").
//
// Level ladder (one new bin at a time, only very typical animals until V):
//   I    MAMMAL vs BIRD — dog, cow, duck, owl… — very slow fall (15 s)
//   II   + FISH
//   III  + REPTILE
//   IV   + AMPHIBIAN (frog, toad, newt)
//   V    + the tricky ones: bat, whale, dolphin, seal, penguin, shark, axolotl, sea turtle…
//   VI+  mostly tricky; the fall speeds up a little each level (to a 5 s floor)

private let csBins: [SortBin] = [
    SortBin(id: "mammal", title: "MAMMAL", icon: "🐾", tint: Lu.coral, hint: "fur"),
    SortBin(id: "bird", title: "BIRD", icon: "🪶", tint: Lu.sky, hint: "feathers"),
    SortBin(id: "fish", title: "FISH", icon: "🫧", tint: 0x58c4c0, hint: "fins"),
    SortBin(id: "reptile", title: "REPTILE", icon: "🦎", tint: Lu.mint, hint: "scales"),
    SortBin(id: "amphibian", title: "AMPHIBIAN", icon: "🐸", tint: Lu.gold, hint: "wet skin"),
]

private struct Critter {
    let emoji: String
    let name: String
    let cls: String
    var hue = 0.0
    var tricky = false
}

private let csAnimals: [Critter] = [
    // Mammals — typical
    .init(emoji: "🐶", name: "Dog", cls: "mammal"), .init(emoji: "🐱", name: "Cat", cls: "mammal"),
    .init(emoji: "🐮", name: "Cow", cls: "mammal"), .init(emoji: "🐷", name: "Pig", cls: "mammal"),
    .init(emoji: "🐴", name: "Horse", cls: "mammal"), .init(emoji: "🐰", name: "Rabbit", cls: "mammal"),
    .init(emoji: "🦁", name: "Lion", cls: "mammal"), .init(emoji: "🐘", name: "Elephant", cls: "mammal"),
    .init(emoji: "🐭", name: "Mouse", cls: "mammal"), .init(emoji: "🐻", name: "Bear", cls: "mammal"),
    .init(emoji: "🐵", name: "Monkey", cls: "mammal"), .init(emoji: "🦒", name: "Giraffe", cls: "mammal"),
    .init(emoji: "🐯", name: "Tiger", cls: "mammal"), .init(emoji: "🦓", name: "Zebra", cls: "mammal"),
    .init(emoji: "🐑", name: "Sheep", cls: "mammal"),
    // Mammals — tricky (fly, swim, or live in the sea)
    .init(emoji: "🦇", name: "Bat", cls: "mammal", tricky: true),
    .init(emoji: "🐋", name: "Whale", cls: "mammal", tricky: true),
    .init(emoji: "🐬", name: "Dolphin", cls: "mammal", tricky: true),
    .init(emoji: "🦭", name: "Seal", cls: "mammal", tricky: true),
    .init(emoji: "🦦", name: "Otter", cls: "mammal", tricky: true),
    // Birds — typical
    .init(emoji: "🐔", name: "Chicken", cls: "bird"), .init(emoji: "🦆", name: "Duck", cls: "bird"),
    .init(emoji: "🦉", name: "Owl", cls: "bird"), .init(emoji: "🦜", name: "Parrot", cls: "bird"),
    .init(emoji: "🦅", name: "Eagle", cls: "bird"), .init(emoji: "🦢", name: "Swan", cls: "bird"),
    .init(emoji: "🦩", name: "Flamingo", cls: "bird"), .init(emoji: "🦚", name: "Peacock", cls: "bird"),
    .init(emoji: "🕊️", name: "Dove", cls: "bird"), .init(emoji: "🦃", name: "Turkey", cls: "bird"),
    // Birds — tricky (can't fly)
    .init(emoji: "🐧", name: "Penguin", cls: "bird", tricky: true),
    .init(emoji: "🦤", name: "Dodo", cls: "bird", tricky: true),
    // Fish
    .init(emoji: "🐠", name: "Tropical fish", cls: "fish"), .init(emoji: "🐡", name: "Pufferfish", cls: "fish"),
    .init(emoji: "🐟", name: "Tuna", cls: "fish"), .init(emoji: "🐟", name: "Salmon", cls: "fish", hue: 150),
    .init(emoji: "🦈", name: "Shark", cls: "fish", tricky: true),
    // Reptiles
    .init(emoji: "🐍", name: "Snake", cls: "reptile"), .init(emoji: "🦎", name: "Lizard", cls: "reptile"),
    .init(emoji: "🐢", name: "Turtle", cls: "reptile"), .init(emoji: "🐊", name: "Crocodile", cls: "reptile"),
    .init(emoji: "🐢", name: "Tortoise", cls: "reptile", tricky: true),
    .init(emoji: "🐢", name: "Sea turtle", cls: "reptile", tricky: true),
    .init(emoji: "🐊", name: "Alligator", cls: "reptile", tricky: true),
    .init(emoji: "🦎", name: "Iguana", cls: "reptile", tricky: true),
    // Amphibians (no emoji draws a newt or salamander, and a lizard would teach the wrong thing —
    // these are words only)
    .init(emoji: "🐸", name: "Frog", cls: "amphibian"), .init(emoji: "🐸", name: "Toad", cls: "amphibian", hue: -70),
    .init(emoji: "", name: "Newt", cls: "amphibian"),
    .init(emoji: "", name: "Salamander", cls: "amphibian", tricky: true),
    .init(emoji: "", name: "Axolotl", cls: "amphibian", tricky: true),
]

private func csBinsFor(_ level: Int) -> [SortBin] { Array(csBins.prefix(min(5, level + 1))) }

private func csFall(_ level: Int) -> Double {
    let table: [Double] = [15, 13, 12, 11, 10.5, 9, 8, 7]
    return level <= table.count ? table[level - 1] : max(5, 7 - Double(level - 8) * 0.4)
}

private func csArticle(_ s: String) -> String { "aeiou".contains(s.lowercased().first ?? "x") ? "An" : "A" }

private func csItem(_ c: Critter) -> SortItem {
    let title = csBins.first { $0.id == c.cls }?.title ?? c.cls
    let classArticle = csArticle(title).lowercased()
    return SortItem(emoji: c.emoji, hue: c.hue, text: c.name, bin: c.cls,
                    lesson: "\(c.emoji.isEmpty ? "" : c.emoji + " ")\(csArticle(c.name)) \(c.name.lowercased()) is \(classArticle) *\(title)*")
}

/// Level I–IV: typical animals of the bins in play, the newest bin served more often.
/// V+: the tricky ones join (half the tiles at V, more later).
private func csMake(_ level: Int) -> SortItem {
    let classes = csBinsFor(level).map(\.id)
    let typical = csAnimals.filter { !$0.tricky && classes.contains($0.cls) }
    let tricky = csAnimals.filter { $0.tricky && classes.contains($0.cls) }
    if level >= 5, Double.random(in: 0..<1) < (level == 5 ? 0.5 : 0.65) { return csItem(tricky.randomElement()!) }
    if level >= 2, level <= 4, Double.random(in: 0..<1) < 0.4, let newest = classes.last {
        return csItem(typical.filter { $0.cls == newest }.randomElement()!)
    }
    // Spread over the classes evenly (not by how many animals each has).
    let cls = classes.randomElement()!
    return csItem(typical.filter { $0.cls == cls }.randomElement()!)
}

#if DEBUG
/// Every level's items land in a bin that's on screen; no name has two classes.
private func csSelfCheck() {
    var seen: [String: String] = [:]
    for c in csAnimals {
        precondition(seen[c.name] == nil || seen[c.name] == c.cls, "Critter Sort: \(c.name) in two classes")
        seen[c.name] = c.cls
    }
    for lv in 1...12 {
        let ids = Set(csBinsFor(lv).map(\.id))
        for _ in 0..<400 { precondition(ids.contains(csMake(lv).bin), "Critter Sort: off-screen bin at \(lv)") }
    }
    print("SELFCHECK critterSort OK")
}
#endif

struct CritterSortView: View {
    let onClose: () -> Void
    @StateObject private var model = LaneSortModel(key: GameID.critterSort.rawValue, bins: csBinsFor, make: csMake, fall: csFall)

    var body: some View {
        LaneSorterView(model: model,
                       spec: GameID.critterSort.spec ?? GameSpec(title: "Critter Sort", mechanic: "", premise: "", game: .critterSort),
                       accent: Lu.tangerine, prompt: "Which group?", onClose: onClose)
            .onAppear {
                #if DEBUG
                csSelfCheck()
                #endif
            }
    }
}
