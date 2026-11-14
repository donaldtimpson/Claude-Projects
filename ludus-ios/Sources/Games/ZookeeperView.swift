import SwiftUI

// MARK: - Zookeeper's Breakfast (Vesuvius · Science)
//
// Feeding time at the Emperor's menagerie. Drag (or tap) the right food to the hungry animal: it
// munches happily — or pulls a "yuck" face and spits the wrong food back, and the right one is
// shown going in. Later rounds sort animals into diet pens, fill gaps in food chains, and sort
// living things into producers, consumers and decomposers.
//
// Continuous difficulty (all off `d`):
//   • round kinds fade in by `tier` (old kinds stay as review): feeding → diet pens (HERBIVORE /
//     CARNIVORE, then OMNIVORE from d≈3.4) → food chains (fill the gap; 4-link chains from
//     d≈5.6) → PRODUCER / CONSUMER / DECOMPOSER;
//   • feeding offers 2 foods at first, up to 4 by d≈4.5; harder animals (koala, owl, frog, bee…)
//     join after the first few rounds; words under the pictures from d≈1.5;
//   • chain choices 3 → 4; the "drag it to the pen" hint fades out by d≈5. No clock at any level.
//
// One right answer, by construction: a plant-eater is only ever offered animal foods as
// distractors and a meat-eater only plant foods (so no "well, sometimes" pairs); chain gaps are
// filled only by organisms whose role cannot fit (see `chainRound`); pens use only animals whose
// textbook diet class is uncontroversial. `zkSelfCheck` (DEBUG) re-checks thousands of rounds.

// MARK: Facts

private enum Diet { case herbivore, carnivore, omnivore }

private struct Food { let emoji: String; let name: String }
private let plantFoods = [Food(emoji: "🥕", name: "carrot"), Food(emoji: "🎋", name: "bamboo"),
                          Food(emoji: "🍌", name: "banana"), Food(emoji: "🍎", name: "apple")]
private let animalFoods = [Food(emoji: "🥩", name: "meat"), Food(emoji: "🐟", name: "fish"),
                           Food(emoji: "🐭", name: "mouse"), Food(emoji: "🪰", name: "fly")]

/// An animal at the feeding round: what it eats (its textbook food) and whether it's a level-I face.
private struct Eater {
    let emoji: String, name: String
    let diet: Diet            // herbivore or carnivore only (omnivores never get a feeding round)
    let food: Food
    let easy: Bool
}

private let eaters: [Eater] = [
    Eater(emoji: "🐇", name: "rabbit", diet: .herbivore, food: Food(emoji: "🥕", name: "carrot"), easy: true),
    Eater(emoji: "🦛", name: "hippo", diet: .herbivore, food: Food(emoji: "🌾", name: "grass"), easy: false),
    Eater(emoji: "🐄", name: "cow", diet: .herbivore, food: Food(emoji: "🌾", name: "hay"), easy: true),
    Eater(emoji: "🐎", name: "horse", diet: .herbivore, food: Food(emoji: "🌾", name: "hay"), easy: true),
    Eater(emoji: "🦒", name: "giraffe", diet: .herbivore, food: Food(emoji: "🍃", name: "leaves"), easy: true),
    Eater(emoji: "🐘", name: "elephant", diet: .herbivore, food: Food(emoji: "🌾", name: "hay"), easy: false),
    Eater(emoji: "🦓", name: "zebra", diet: .herbivore, food: Food(emoji: "🌾", name: "grass"), easy: false),
    Eater(emoji: "🦘", name: "kangaroo", diet: .herbivore, food: Food(emoji: "🌾", name: "grass"), easy: false),
    Eater(emoji: "🐐", name: "goat", diet: .herbivore, food: Food(emoji: "🌾", name: "hay"), easy: false),
    Eater(emoji: "🦌", name: "deer", diet: .herbivore, food: Food(emoji: "🍃", name: "leaves"), easy: false),
    Eater(emoji: "🐛", name: "caterpillar", diet: .herbivore, food: Food(emoji: "🍃", name: "leaves"), easy: false),
    Eater(emoji: "🐝", name: "bee", diet: .herbivore, food: Food(emoji: "🌸", name: "flower nectar"), easy: false),
    Eater(emoji: "🐆", name: "leopard", diet: .carnivore, food: Food(emoji: "🥩", name: "meat"), easy: true),
    Eater(emoji: "🐅", name: "tiger", diet: .carnivore, food: Food(emoji: "🥩", name: "meat"), easy: true),
    Eater(emoji: "🦈", name: "shark", diet: .carnivore, food: Food(emoji: "🐟", name: "fish"), easy: true),
    Eater(emoji: "🐧", name: "penguin", diet: .carnivore, food: Food(emoji: "🐟", name: "fish"), easy: true),
    Eater(emoji: "🦭", name: "seal", diet: .carnivore, food: Food(emoji: "🐟", name: "fish"), easy: false),
    Eater(emoji: "🐬", name: "dolphin", diet: .carnivore, food: Food(emoji: "🐟", name: "fish"), easy: false),
    Eater(emoji: "🦉", name: "owl", diet: .carnivore, food: Food(emoji: "🐭", name: "mouse"), easy: false),
    Eater(emoji: "🐍", name: "snake", diet: .carnivore, food: Food(emoji: "🐭", name: "mouse"), easy: false),
    Eater(emoji: "🐸", name: "frog", diet: .carnivore, food: Food(emoji: "🪰", name: "fly"), easy: false),
    Eater(emoji: "🕷️", name: "spider", diet: .carnivore, food: Food(emoji: "🪰", name: "fly"), easy: false),
    Eater(emoji: "🦅", name: "eagle", diet: .carnivore, food: Food(emoji: "🐟", name: "fish"), easy: false),
]

/// Animals for the diet pens, textbook classes only (no panda, no "mostly" cases).
private let penAnimals: [(String, String, Diet)] = [
    ("🐇", "rabbit", .herbivore), ("🐄", "cow", .herbivore), ("🐎", "horse", .herbivore),
    ("🦒", "giraffe", .herbivore), ("🐘", "elephant", .herbivore), ("🦓", "zebra", .herbivore),
    ("🦛", "hippo", .herbivore), ("🦘", "kangaroo", .herbivore), ("🐐", "goat", .herbivore),
    ("🐆", "leopard", .carnivore), ("🐅", "tiger", .carnivore), ("🦈", "shark", .carnivore),
    ("🦉", "owl", .carnivore), ("🐍", "snake", .carnivore), ("🦅", "eagle", .carnivore),
    ("🐧", "penguin", .carnivore), ("🦭", "seal", .carnivore), ("🐸", "frog", .carnivore),
    ("🦡", "badger", .omnivore), ("🐖", "pig", .omnivore), ("🐓", "chicken", .omnivore),
    ("🐒", "monkey", .omnivore), ("🦨", "skunk", .omnivore), ("🐀", "rat", .omnivore),
]

private typealias Org = (emoji: String, name: String)

/// Food chains, producer first; each link is eaten by the next.
private let chains: [[Org]] = [
    [("🌾", "grass"), ("🐰", "rabbit"), ("🦊", "fox")],
    [("🌾", "grass"), ("🦓", "zebra"), ("🦁", "lion")],
    [("🍃", "leaves"), ("🦒", "giraffe"), ("🦁", "lion")],
    [("🍃", "leaves"), ("🐛", "caterpillar"), ("🐦", "bird")],
    [("🌾", "grain"), ("🐭", "mouse"), ("🦉", "owl")],
    [("🌽", "corn"), ("🐔", "chicken"), ("🦊", "fox")],
    [("🌱", "plant"), ("🐌", "snail"), ("🦔", "hedgehog")],
    [("🌱", "plant"), ("🦗", "grasshopper"), ("🐸", "frog"), ("🐍", "snake")],
    [("🌾", "grain"), ("🐭", "mouse"), ("🐍", "snake"), ("🦅", "eagle")],
    [("🌿", "algae"), ("🐟", "small fish"), ("🐧", "penguin"), ("🦭", "seal")],
]

/// Wrong-answer pools for chain gaps. Plants can't eat; strict plant-eaters eat no animals;
/// strict meat-eaters eat no plants; and nothing in a chain eats a lion, shark or tiger.
private let chainPlants: [Org] = [("🌾", "grass"), ("🍃", "leaves"), ("🌱", "plant"), ("🌽", "corn"), ("🌻", "sunflower"), ("🌵", "cactus")]
private let strictHerbivores: [Org] = [("🐮", "cow"), ("🐴", "horse"), ("🐰", "rabbit"), ("🦒", "giraffe"), ("🐘", "elephant"), ("🦓", "zebra"), ("🐨", "koala")]
private let strictCarnivores: [Org] = [("🦁", "lion"), ("🐯", "tiger"), ("🦈", "shark"), ("🦉", "owl"), ("🦅", "eagle"), ("🐍", "snake")]
private let bigBeasts: [Org] = [("🦁", "lion"), ("🐯", "tiger"), ("🦈", "shark"), ("🐘", "elephant"), ("🦅", "eagle")]

private enum Role: Int { case producer, consumer, decomposer }
private let roleThings: [(String, String, Role)] = [
    ("🌾", "grass", .producer), ("🌳", "tree", .producer), ("🌻", "sunflower", .producer),
    ("🌵", "cactus", .producer), ("🍀", "clover", .producer), ("🌲", "pine tree", .producer),
    ("🦁", "lion", .consumer), ("🐰", "rabbit", .consumer), ("🐻", "bear", .consumer),
    ("🐸", "frog", .consumer), ("🦉", "owl", .consumer), ("🐮", "cow", .consumer),
    ("🐟", "fish", .consumer), ("🦊", "fox", .consumer),
    ("🍄", "mushroom", .decomposer), ("🪱", "earthworm", .decomposer),
]

// MARK: Rounds

private enum ZKKind { case feed, pens, chain, roles }

private struct ZKItem: Identifiable, Equatable { let id: Int; let emoji: String; let label: String }
private struct ZKZone: Identifiable, Equatable { let id: Int; let emoji: String; let title: String; let sub: String }

private struct ZKRound {
    var kind: ZKKind
    var animal: Org = ("", "")     // feed: the hungry animal
    var tray: [ZKItem]             // what can be dragged
    var zones: [ZKZone]            // where it can go
    var answerItem: Int
    var answerZone: Int
    var chain: [Org] = []          // chain: the links (the gap's slot is `gap`)
    var gap = 0
    var lesson: String             // the fact, shown after every answer
}

private let dietZones: [ZKZone] = [
    ZKZone(id: 0, emoji: "🌿", title: "HERBIVORE", sub: "eats plants"),
    ZKZone(id: 1, emoji: "🥩", title: "CARNIVORE", sub: "eats meat"),
    ZKZone(id: 2, emoji: "🌿🥩", title: "OMNIVORE", sub: "eats both"),
]
private let roleZones: [ZKZone] = [
    ZKZone(id: 0, emoji: "☀️", title: "PRODUCER", sub: "makes its own food"),
    ZKZone(id: 1, emoji: "🍴", title: "CONSUMER", sub: "eats other living things"),
    ZKZone(id: 2, emoji: "♻️", title: "DECOMPOSER", sub: "breaks down dead things"),
]

private func feedRound(easy: Bool, choices: Int, base: Int) -> ZKRound {
    let pool = easy ? eaters.filter(\.easy) : eaters
    let a = pool.randomElement()!
    let wrongPool = a.diet == .herbivore ? animalFoods : plantFoods
    let wrong = wrongPool.filter { $0.emoji != a.food.emoji }.shuffled().prefix(choices - 1)
    let foods = ([a.food] + wrong).shuffled()
    let tray = foods.enumerated().map { ZKItem(id: base + $0.offset, emoji: $0.element.emoji, label: $0.element.name) }
    let right = tray.first { $0.emoji == a.food.emoji }!.id
    return ZKRound(kind: .feed, animal: (a.emoji, a.name), tray: tray,
                   zones: [ZKZone(id: 0, emoji: a.emoji, title: a.name, sub: "")],
                   answerItem: right, answerZone: 0,
                   lesson: "\(a.emoji) The \(a.name) eats \(a.food.emoji) \(a.food.name)")
}

private func penRound(omnivores: Bool, base: Int) -> ZKRound {
    let a = penAnimals.filter { omnivores || $0.2 != .omnivore }.randomElement()!
    let zones = Array(dietZones.prefix(omnivores ? 3 : 2))
    let z = a.2 == .herbivore ? 0 : a.2 == .carnivore ? 1 : 2
    let what = a.2 == .herbivore ? "plants" : a.2 == .carnivore ? "meat" : "plants AND meat"
    return ZKRound(kind: .pens, tray: [ZKItem(id: base, emoji: a.0, label: a.1)], zones: zones,
                   answerItem: base, answerZone: z,
                   lesson: "\(a.0) The \(a.1) eats \(what) — \(zones[z].title.lowercased())")
}

private func roleRound(base: Int) -> ZKRound {
    let role = [Role.producer, .consumer, .decomposer].randomElement()!
    let t = roleThings.filter { $0.2 == role }.randomElement()!
    let z = roleZones[role.rawValue]
    let a = ["a", "e", "i", "o", "u"].contains(String(t.1.prefix(1))) ? "An" : "A"
    return ZKRound(kind: .roles, tray: [ZKItem(id: base, emoji: t.0, label: t.1)], zones: roleZones,
                   answerItem: base, answerZone: role.rawValue,
                   lesson: "\(t.0) \(a) \(t.1) \(z.sub) — a \(z.title.lowercased())")
}

/// Fill the gap in a food chain. Wrong choices are picked by role so none of them can fit:
/// the first link (a plant) is offered big animals nothing in the chain eats; a plant-eating
/// link is offered plants (they can't eat) and strict meat-eaters (they don't eat plants); a
/// meat-eating link is offered plants and strict plant-eaters (they don't eat animals).
private func chainRound(links: Int?, choices: Int, base: Int) -> ZKRound {
    let pool = chains.filter { links == nil || $0.count == links! }
    let c = pool.randomElement()!
    let gap = Int.random(in: 0..<c.count)
    let right = c[gap]
    let decoys: [Org]
    switch gap {
    case 0: decoys = bigBeasts
    case 1: decoys = chainPlants + strictCarnivores
    default: decoys = chainPlants + strictHerbivores
    }
    let inChain = Set(c.map(\.emoji))
    var picks: [Org] = [right]
    for d in decoys.shuffled() where !inChain.contains(d.emoji) && !picks.contains(where: { $0.emoji == d.emoji }) {
        picks.append(d); if picks.count == choices { break }
    }
    picks.shuffle()
    let tray = picks.enumerated().map { ZKItem(id: base + $0.offset, emoji: $0.element.emoji, label: $0.element.name) }
    let lesson: String
    if gap + 1 < c.count { lesson = "\(c[gap + 1].emoji) The \(c[gap + 1].name) eats the \(right.name) \(right.emoji)" }
    else { lesson = "\(right.emoji) The \(right.name) eats the \(c[gap - 1].name) \(c[gap - 1].emoji)" }
    return ZKRound(kind: .chain, tray: tray, zones: [ZKZone(id: 0, emoji: "❓", title: "", sub: "")],
                   answerItem: tray.first { $0.emoji == right.emoji }!.id, answerZone: 0,
                   chain: c, gap: gap, lesson: lesson)
}

/// The knobs of one round (read off the continuous difficulty `d` by the model).
private struct ZKKnobs {
    var kind = 0             // 0 feed · 1 diet pens · 2 food chain · 3 producer/consumer/decomposer
    var easy = true          // level-I animals only
    var choices = 2          // foods on the tray (feed)
    var omnivores = false    // the third pen
    var links: Int? = 3      // chain length (nil = any)
    var chainChoices = 3
}

private func zkRound(_ k: ZKKnobs, base: Int) -> ZKRound {
    switch k.kind {
    case 0: return feedRound(easy: k.easy, choices: k.choices, base: base)
    case 1: return penRound(omnivores: k.omnivores, base: base)
    case 2: return chainRound(links: k.links, choices: k.chainChoices, base: base)
    default: return roleRound(base: base)
    }
}

#if DEBUG
/// Each round has exactly one right (item, zone) pair, and every wrong choice is wrong by the
/// rules in the header: checked against the diet / role tables, not the generator's own choice.
private func zkSelfCheck() -> String? {
    let plantSet = Set(plantFoods.map(\.emoji) + ["🌾", "🍃", "🌸"]), meatSet = Set(animalFoods.map(\.emoji))
    let herbs = Set(strictHerbivores.map(\.emoji)), carns = Set(strictCarnivores.map(\.emoji))
    let plants = Set(chainPlants.map(\.emoji)), bigs = Set(bigBeasts.map(\.emoji))
    for kind in 0...3 {
        for i in 0..<400 {
            let level = kind
            let k = ZKKnobs(kind: kind, easy: i % 3 == 0, choices: 2 + i % 3, omnivores: i % 2 == 0,
                            links: [3, 4, nil][i % 3], chainChoices: 3 + i % 2)
            let r = zkRound(k, base: 0)
            guard r.tray.contains(where: { $0.id == r.answerItem }), r.zones.contains(where: { $0.id == r.answerZone }) else {
                return "L\(level): answer missing"
            }
            if Set(r.tray.map(\.emoji)).count != r.tray.count { return "L\(level): duplicate choice" }
            switch r.kind {
            case .feed:
                guard let e = eaters.first(where: { $0.emoji == r.animal.emoji }) else { return "unknown eater" }
                for it in r.tray where it.id != r.answerItem {
                    let ok = e.diet == .herbivore ? meatSet.contains(it.emoji) : plantSet.contains(it.emoji) && !meatSet.contains(it.emoji)
                    if !ok { return "L\(level): \(e.name) offered \(it.emoji)" }
                }
                if k.easy && !e.easy { return "easy feed round with a hard animal" }
                if r.tray.count != k.choices { return "feed with \(r.tray.count) foods" }
            case .pens, .roles:
                if r.tray.count != 1 { return "pen round with \(r.tray.count) items" }
            case .chain:
                for it in r.tray where it.id != r.answerItem {
                    let ok = r.gap == 0 ? bigs.contains(it.emoji)
                        : r.gap == 1 ? (plants.contains(it.emoji) || carns.contains(it.emoji))
                        : (plants.contains(it.emoji) || herbs.contains(it.emoji))
                    if !ok || r.chain.contains(where: { $0.emoji == it.emoji }) { return "chain decoy \(it.emoji) could fit" }
                }
                if r.tray.count < 3 { return "chain with \(r.tray.count) choices" }
            }
        }
    }
    return nil
}
#endif

// MARK: Model

@MainActor
private final class ZooModel: ArcadeModel {
    enum Outcome: Equatable { case none, yum, yuck }
    @Published var round = ZKRound(kind: .feed, tray: [], zones: [], answerItem: 0, answerZone: 0, lesson: "")
    @Published var outcome: Outcome = .none
    @Published var revealing = false
    @Published var wrongItem: Int?
    @Published var wrongZone: Int?
    @Published var beat = 0          // bumps on each reaction (shake / munch)
    @Published var cheers = 0
    @Published var roundID = 0
    var dropFrames: [Int: CGRect] = [:]   // zone frames (kept current by the view)
    private var locked = false
    private let clock = VesRunClock()
    #if DEBUG
    private static let checked: Bool = {
        if let bad = zkSelfCheck() { assertionFailure("Zookeeper self-check: \(bad)") }
        return true
    }()
    #endif

    init() {
        super.init(key: GameID.zookeeper.rawValue)
        #if DEBUG
        _ = ZooModel.checked
        #endif
    }

    override func onBegin() {
        clock.reset()
        newRound()
    }

    /// Item `item` was dropped on zone `zone`. True = it's taken (the right pair).
    @discardableResult
    func drop(_ item: Int, on zone: Int) -> Bool {
        guard phase == .playing, !locked else { return false }
        locked = true
        if item == round.answerItem && zone == round.answerZone {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { outcome = .yum }
            beat += 1; cheers += 1
            hit()
            clock.after(1.5) { self.next() }
            return true
        }
        wrongItem = item; wrongZone = zone
        outcome = .yuck; beat += 1
        let last = miss(delay: 2.6)
        clock.after(0.8) { withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { self.revealing = true } }
        if !last { clock.after(2.8) { self.next() } }
        return false
    }

    /// A drag of `item` released at `p`: hit-test the zones, then drop. False = spring home.
    @discardableResult
    func release(_ item: Int, at p: CGPoint) -> Bool {
        guard let z = vesZoneHit(p, zones: dropFrames) else { return false }
        return drop(item, on: z)
    }

    private func next() {
        guard phase == .playing else { return }
        withAnimation(.easeInOut(duration: 0.4)) { newRound() }
    }

    private func newRound() {
        locked = false; outcome = .none; revealing = false; wrongItem = nil; wrongZone = nil
        roundID += 1
        let k = knobs()
        var r = zkRound(k, base: roundID * 100)
        // Avoid the same animal / chain twice in a row.
        if r.tray.map(\.emoji) == round.tray.map(\.emoji) || (r.kind == .feed && r.animal.emoji == round.animal.emoji) {
            r = zkRound(k, base: roundID * 100)
        }
        round = r
    }

    /// Everything about the next round, read off the continuous difficulty `d`.
    private func knobs() -> ZKKnobs {
        var k = ZKKnobs()
        k.kind = tier([1, 2.6, 4.6, 5.8])
        k.easy = !chance(1, from: 1.3, to: 2.3)
        k.choices = rampInt(2, 4, from: 1.4, to: 4.5)
        k.omnivores = chance(1, from: 3.4, to: 4.4)
        k.links = chance(0.6, from: 5.6, to: 7.5) ? 4 : 3
        k.chainChoices = rampInt(3, 4, from: 5.5, to: 7.5)
        return k
    }

    var words: Double { ramp(0, 1, from: 1.5, to: 2.1) }
    var penHint: Double { ramp(1, 0, from: 4, to: 5) }

    override func botAct(correct: Bool) {
        guard !locked, !round.tray.isEmpty else { return }
        // Release the item over the centre of a zone, through the same hit test a finger uses.
        func fling(_ item: Int, _ zone: Int) {
            guard let f = dropFrames[zone] else { return }
            release(item, at: CGPoint(x: f.midX, y: f.midY))
        }
        if correct { fling(round.answerItem, round.answerZone); return }
        if let w = round.tray.first(where: { $0.id != round.answerItem }) { fling(w.id, round.answerZone) }
        else if let z = round.zones.first(where: { $0.id != round.answerZone }) { fling(round.answerItem, z.id) }
    }
}

// MARK: Views

struct ZookeeperView: View {
    let onClose: () -> Void
    @StateObject private var model = ZooModel()
    private let space = "zookeeper"

    var body: some View {
        ArcadeShell(model: model, spec: GameID.zookeeper.spec ?? GameSpec(title: "Zookeeper's Breakfast", mechanic: "", premise: "", game: .zookeeper),
                    accent: Lu.mint, onClose: onClose,
                    backdrop: { Menagerie() }) {
            VStack(spacing: 10) {
                Color.clear.frame(height: 54)
                Text(header).font(luSerif(17, .black)).textCase(.uppercase).tracking(2)
                    .foregroundStyle(Color(hex: 0x3a2410))
                    .padding(.horizontal, 16).padding(.vertical, 5)
                    .background(Capsule().fill(Color(hex: 0xf7ecd0).opacity(0.92)).overlay(Capsule().stroke(Color(hex: 0x9c7b33), lineWidth: 2)))
                Group {
                    switch model.round.kind {
                    case .feed: feedStage
                    case .chain: chainStage
                    case .pens, .roles: penStage
                    }
                }
                .id(model.roundID)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                lesson
            }
            .padding(.horizontal, 14).padding(.bottom, 6)
            .coordinateSpace(name: space)
            .onPreferenceChange(VesDropZones.self) { model.dropFrames = $0 }
        }
    }

    private var header: String {
        switch model.round.kind {
        case .feed: return "Breakfast time!"
        case .pens: return "Which pen?"
        case .chain: return "Food chain"
        case .roles: return "What does it do?"
        }
    }

    private var showWords: Bool { model.words > 0.5 }

    /// The fact behind the answer — after every answer, right or wrong.
    private var lesson: some View {
        Text(model.round.lesson)
            .font(luFont(17, .heavy)).foregroundStyle(Color(hex: model.outcome == .yum ? Lu.mint : Lu.gold))
            .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, minHeight: 46)
            .padding(.horizontal, 10)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.45)))
            .opacity(model.outcome == .yum || model.revealing ? 1 : 0)
    }

    private func release(_ item: ZKItem) -> (CGPoint) -> Bool {
        { p in model.release(item.id, at: p) }
    }

    // Feed: the animal (the drop zone) above a tray of foods.
    private var feedStage: some View {
        let r = model.round
        let rightFood = r.tray.first { $0.id == r.answerItem }
        return VStack(spacing: 12) {
            ZStack {
                // The enclosure: a fence across the back, trampled earth, a stone water trough.
                VStack(spacing: 14) {
                    Rectangle().fill(Color(hex: 0x8a5a2e)).frame(height: 6)
                    Rectangle().fill(Color(hex: 0x8a5a2e)).frame(height: 6)
                }
                .overlay(HStack { ForEach(0..<8, id: \.self) { _ in Spacer(); Rectangle().fill(Color(hex: 0x6e4220)).frame(width: 8, height: 50) }; Spacer() })
                .frame(maxHeight: .infinity, alignment: .top).padding(.top, 30)
                Ellipse().fill(RadialGradient(colors: [Color(hex: 0xc9a46a), Color(hex: 0xb08850).opacity(0)], center: .center, startRadius: 10, endRadius: 170))
                    .frame(width: 330, height: 120)
                    .frame(maxHeight: .infinity, alignment: .bottom).padding(.bottom, 20)
                RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0xbdb3a2))
                    .overlay(RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0x5fa8d8)).padding(5))
                    .frame(width: 70, height: 26)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading).padding(16)
                AnimalActor(emoji: r.animal.emoji, outcome: model.outcome, beat: model.beat, size: 160)
                if model.outcome == .yum || model.revealing, let f = rightFood {
                    Text(f.emoji).font(.system(size: 54))
                        .offset(x: 52, y: 40)
                        .scaleEffect(model.outcome == .yum ? 0.6 : 1)
                        .transition(.scale(scale: 0.2).combined(with: .opacity))
                }
                VesBurst(trigger: model.cheers, emojis: ["❤️", "✨", "😋", "⭐️"], radius: 120, size: 28)
                bubble.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(14)
                if showWords {
                    Text(r.animal.name).font(luFont(18, .heavy)).foregroundStyle(Color(hex: Lu.ink))
                        .padding(.horizontal, 12).padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.3)))
                        .frame(maxHeight: .infinity, alignment: .bottom).padding(.bottom, 12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .vesDropZone(0, in: space)
            tray(r.tray, big: r.tray.count <= 2)
        }
    }

    @ViewBuilder private var bubble: some View {
        switch model.outcome {
        case .yum:
            VesBubble(text: model.round.kind == .feed ? ["Yum! 😋", "Mmm! 😋", "Thank you! 💛"][model.roundID % 3]
                                                    : ["Right! ⭐️", "Yes! 😄", "Bene! 💛"][model.roundID % 3]).transition(.scale.combined(with: .opacity))
        case .yuck: VesBubble(text: model.round.kind == .feed ? "Yuck! 🤢" : "Not my pen! 😠", hex: 0xf3c4b8).transition(.scale.combined(with: .opacity))
        case .none:
            if model.round.kind == .feed { VesBubble(text: "I'm hungry! 🍽️") }
        }
    }

    private func tray(_ items: [ZKItem], big: Bool) -> some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: max(1, min(4, items.count)))
        return LazyVGrid(columns: cols, spacing: 10) {
            ForEach(items) { it in
                let used = model.outcome == .yum && it.id == model.round.answerItem
                VesDragToken(space: space, enabled: model.outcome == .none,
                             onRelease: release(it), onTap: { model.drop(it.id, on: 0) }) {
                    ZKCard(item: it, big: big, words: showWords,
                           state: model.revealing && it.id == model.round.answerItem ? .right
                                : model.wrongItem == it.id ? .wrong : .plain)
                }
                .opacity(used ? 0.15 : 1)
            }
        }
        .zIndex(2)
    }

    // Chain: the links with a ❓ gap (the drop zone), then the choices.
    private var chainStage: some View {
        let r = model.round
        let filled = model.outcome == .yum || model.revealing
        let right = r.tray.first { $0.id == r.answerItem }
        return VStack(spacing: 14) {
            Spacer(minLength: 0)
            HStack(spacing: 4) {
                ForEach(Array(r.chain.enumerated()), id: \.offset) { i, o in
                    if i > 0 {
                        Image(systemName: "arrow.right").font(.system(size: 18, weight: .black))
                            .foregroundStyle(Color(hex: Lu.gold))
                    }
                    if i == r.gap {
                        ChainCard(emoji: filled ? (right?.emoji ?? "❓") : "❓", name: filled ? (right?.label ?? "") : "?",
                                  hex: filled ? (model.outcome == .yum ? Lu.mint : Lu.gold) : Lu.coral, dashed: !filled,
                                  count: r.chain.count)
                            .modifier(VesShake(amount: 8, shakes: 3, beats: CGFloat(model.outcome == .yuck ? model.beat : 0)))
                            .vesDropZone(0, in: space)
                    } else {
                        ChainCard(emoji: o.emoji, name: o.name, hex: Lu.line, dashed: false, count: r.chain.count)
                    }
                }
            }
            .padding(.vertical, 18).padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(luPanelShape(22))
            .overlay(VesBurst(trigger: model.cheers, emojis: ["✨", "⭐️", "🌿"], radius: 110))
            HStack(spacing: 6) {
                Image(systemName: "arrow.right").font(.system(size: 15, weight: .black)).foregroundStyle(Color(hex: Lu.gold))
                Text("means \"is eaten by\"").font(luFont(15, .bold)).foregroundStyle(Color(hex: Lu.inkDim))
            }
            Spacer(minLength: 0)
            tray(r.tray, big: false)
        }
    }

    // Pens / roles: one thing to sort (dragged) and 2–3 pens (drop zones, also tappable).
    private var penStage: some View {
        let r = model.round
        let item = r.tray.first!
        let placed = model.outcome == .yum
        return VStack(spacing: 14) {
            Spacer(minLength: 0)
            ZStack {
                VesDragToken(space: space, enabled: model.outcome == .none, onRelease: release(item)) {
                    VStack(spacing: 2) {
                        AnimalActor(emoji: item.emoji, outcome: model.outcome, beat: model.beat, size: 92)
                        Text(item.label).font(luFont(18, .heavy)).foregroundStyle(Color(hex: 0x3a2410))
                    }
                    .frame(width: 176, height: 176)
                    .background(Circle().fill(RadialGradient(colors: [Color(hex: 0xf3dc9a), Color(hex: 0xd9b464)], center: .center, startRadius: 10, endRadius: 90))
                        .overlay(Circle().stroke(Color(hex: 0x9c7b33), style: StrokeStyle(lineWidth: 4, dash: [3, 3]))))
                    .contentShape(Circle())
                }
                .opacity(placed ? 0.2 : 1)
                bubble.offset(x: 110, y: -80)
            }
            .zIndex(2)
            Text("Drag it to the right pen").font(luFont(15, .bold)).foregroundStyle(Color(hex: Lu.inkDim))
                .opacity(model.penHint)
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                ForEach(r.zones) { z in
                    let isAnswer = z.id == r.answerZone
                    PenView(zone: z, count: r.zones.count,
                            state: (placed || model.revealing) && isAnswer ? .right : (model.wrongZone == z.id ? .wrong : .plain),
                            resident: (placed || model.revealing) && isAnswer ? item.emoji : nil)
                        .vesDropZone(z.id, in: space)
                        .onTapGesture { model.drop(item.id, on: z.id) }
                }
            }
            .overlay(VesBurst(trigger: model.cheers, emojis: ["✨", "⭐️", "💛"], radius: 120))
        }
    }
}

private enum Mark { case plain, right, wrong }

/// The hungry animal: munches (bounces) when fed right, shakes its head and shows 🤢 when not.
private struct AnimalActor: View {
    let emoji: String
    let outcome: ZooModel.Outcome
    let beat: Int
    let size: CGFloat
    @State private var shake: CGFloat = 0
    @State private var munch = false

    var body: some View {
        Text(emoji).font(.system(size: size))
            .overlay(alignment: .topLeading) {
                if outcome == .yuck {
                    Text("🤢").font(.system(size: size * 0.36)).offset(x: -size * 0.1, y: -size * 0.05)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(munch ? 1.14 : 1, anchor: .bottom)
            .modifier(VesShake(amount: 12, shakes: 3, beats: shake))
            .onChange(of: beat) { _ in
                if outcome == .yuck {
                    withAnimation(.linear(duration: 0.55)) { shake += 1 }
                } else {
                    // three quick munches
                    for i in 0..<3 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.22) {
                            withAnimation(.spring(response: 0.12, dampingFraction: 0.5)) { munch = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
                                withAnimation(.spring(response: 0.12, dampingFraction: 0.5)) { munch = false }
                            }
                        }
                    }
                }
            }
    }
}

private struct ZKCard: View {
    let item: ZKItem
    let big: Bool
    let words: Bool
    let state: Mark
    var body: some View {
        VStack(spacing: 2) {
            Text(item.emoji).font(.system(size: big ? 66 : 46))
            if words {
                Text(item.label).font(luFont(13, .heavy)).foregroundStyle(Color(hex: 0x3a2410))
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, minHeight: big ? 124 : 90)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(state == .right ? AnyShapeStyle(Color(hex: 0xc8eec0))
                                      : AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xe9c98e), Color(hex: 0xc99a5a)], startPoint: .top, endPoint: .bottom)))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(hex: state == .right ? Lu.mint : state == .wrong ? Lu.coral : 0x8a5a2e),
                            lineWidth: state == .plain ? 3 : 4))
        )
        .scaleEffect(state == .right ? 1.06 : 1)
        .contentShape(Rectangle())
    }
}

private struct ChainCard: View {
    let emoji: String
    let name: String
    let hex: UInt
    let dashed: Bool
    let count: Int
    var body: some View {
        let w: CGFloat = count >= 4 ? 70 : 92
        VStack(spacing: 2) {
            Text(emoji).font(.system(size: count >= 4 ? 38 : 48))
            Text(name).font(luFont(12, .heavy)).foregroundStyle(Color(hex: Lu.ink))
                .lineLimit(1).minimumScaleFactor(0.5)
        }
        .frame(width: w, height: w + 16)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(Color(hex: Lu.panel))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: hex), style: StrokeStyle(lineWidth: dashed ? 3 : 2, dash: dashed ? [7, 5] : [])))
        )
    }
}

private struct PenView: View {
    let zone: ZKZone
    let count: Int
    let state: Mark
    let resident: String?
    var body: some View {
        VStack(spacing: 4) {
            Text(zone.emoji).font(.system(size: zone.emoji.count > 1 ? 26 : 34))
            Text(zone.title).font(luFont(count >= 3 ? 13 : 16, .black)).foregroundStyle(Color(hex: Lu.ink))
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(zone.sub).font(luFont(12, .bold)).foregroundStyle(Color(hex: Lu.inkDim))
                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.7)
            ZStack {
                if let r = resident { Text(r).font(.system(size: 40)).transition(.scale.combined(with: .opacity)) }
            }
            .frame(height: 44)
        }
        .padding(.vertical, 10).padding(.horizontal, 6)
        .frame(maxWidth: .infinity, minHeight: 170)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: state == .right ? 0x3f7a45 : state == .wrong ? 0x8a3a2a : 0x6e4a2a).opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: state == .right ? Lu.mint : state == .wrong ? Lu.coral : Lu.goldLine),
                            lineWidth: state == .plain ? 2 : 4))
        )
        // a picket fence along the top: it's a pen
        .overlay(alignment: .top) {
            HStack(spacing: 0) {
                ForEach(0..<6, id: \.self) { _ in
                    Spacer(minLength: 0)
                    PenPicket().fill(Color(hex: 0xc9965a)).frame(width: 8, height: 22)
                    Spacer(minLength: 0)
                }
            }
            .overlay(Rectangle().fill(Color(hex: 0x9a6a3a)).frame(height: 4).offset(y: 3))
            .offset(y: -12)
        }
        .contentShape(Rectangle())
    }
}

private struct PenPicket: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.minX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.width / 2))
            p.addLine(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.width / 2))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.closeSubpath()
        }
    }
}

/// The Emperor's menagerie at breakfast time: a dawn sky, Vesuvius, cypresses, a stone wall and
/// a meadow with a wooden fence, a water trough and a hay bale.
private struct Menagerie: View {
    var body: some View {
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0xf7b878), Color(hex: 0xfbe0b0), Color(hex: 0xcfe8d0)], startPoint: .top, endPoint: .center)
                Circle().fill(Color(hex: 0xffe08a)).frame(width: 90).blur(radius: 2).position(x: W * 0.2, y: H * 0.16)
                VesMountain(smoke: true, tint: 0x8a6f7c).frame(width: W * 0.8, height: H * 0.16).position(x: W * 0.6, y: H * 0.2)
                ForEach(0..<6, id: \.self) { i in
                    Capsule().fill(Color(hex: 0x40663a)).frame(width: 16, height: 60 + CGFloat(i % 3) * 10)
                        .position(x: W * (0.06 + CGFloat(i) * 0.18), y: H * 0.27 - CGFloat(i % 3) * 5)
                }
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0x9cc46e), Color(hex: 0x6f9e4c)], startPoint: .top, endPoint: .bottom))
                    .frame(height: H * 0.72).position(x: W / 2, y: H * 0.66)
                // stone wall along the back of the meadow
                Rectangle().fill(Color(hex: 0xcdbb98)).frame(height: 16).position(x: W / 2, y: H * 0.305)
                    .overlay(Rectangle().fill(Color(hex: 0x9c8a6a)).frame(height: 2).position(x: W / 2, y: H * 0.315))
                // grass tufts
                ForEach(0..<14, id: \.self) { i in
                    Text("🌱").font(.system(size: 14)).opacity(0.45)
                        .position(x: W * CGFloat((i * 37) % 100) / 100, y: H * (0.36 + CGFloat((i * 53) % 60) / 100))
                }
                // fence at the bottom
                VStack(spacing: 10) {
                    Rectangle().fill(Color(hex: 0x8a5a2e)).frame(height: 7)
                    Rectangle().fill(Color(hex: 0x8a5a2e)).frame(height: 7)
                }
                .frame(height: 30).position(x: W / 2, y: H * 0.965)
                HStack(spacing: W / 7) { ForEach(0..<7, id: \.self) { _ in Rectangle().fill(Color(hex: 0x6e4220)).frame(width: 8, height: 46) } }
                    .position(x: W / 2, y: H * 0.96)
            }
        }
    }
}
