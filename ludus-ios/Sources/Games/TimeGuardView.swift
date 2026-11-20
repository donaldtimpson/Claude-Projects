import SwiftUI

// MARK: - Time Guard (Forum · History)
//
// A clumsy time-wizard keeps dropping things from the wrong time into history. Each round you
// stand IN a painted scene from one era (it fills the screen) with a few things in it; exactly ONE
// is from the wrong time. Tap it and a time-portal zaps it home while the locals cheer. A miss
// lights up the intruder and the Time Guard says why in one line ("Phones are from our time!").
//
// Difficulty runs on `d` (GameKit), no level tables:
//   • things in the scene: 3 → 8 (rampInt);
//   • scenes — tier([1, 1.8, 3]): Roman street → + feast, Egypt, castle → + Wild West, Ice-Age cave;
//   • intruders — tier([1, 2.6, 3.8, 5]): modern gadgets (📱 🚗) → 1800s–1900s inventions (💡 🚲)
//     → food from the Americas at Old-World tables (🍅 🥔 before 1492) → subtle (👓 in Rome, 🛞 in
//     the cave). Below d≈1.8 only the unmistakable gadgets and classic Roman things appear;
//   • from d≈4.5 an hourglass drains, 22 s easing to 9 s.
// The Wild West deliberately shows corn, potatoes and trains as RIGHT-time things, so a child
// who has learned "potatoes = wrong" has to think about where and when.

// MARK: Data

private enum TGEra: CaseIterable { case rome, feast, egypt, castle, west, cave }

private struct TGScene {
    let era: TGEra
    let title: String
    let when: String
    let things: [String]     // right-time things (all conservative, well-attested)
    let people: [String]
}

private let tgScenes: [TGScene] = [
    TGScene(era: .rome, title: "Roman Street", when: "2,000 years ago",
            things: ["🏛️", "🏺", "🛡️", "⚔️", "🐎", "🌿", "📜", "🪔", "🎲", "🐐", "⛵️", "🐓"],
            people: ["🧔", "👩", "👴"]),
    TGScene(era: .feast, title: "Roman Feast", when: "2,000 years ago",
            things: ["🍇", "🫒", "🍞", "🧀", "🍯", "🐟", "🍎", "🍐", "🥚", "🏺", "🪔", "🍗"],
            people: ["🧔", "👵", "👦"]),
    TGScene(era: .egypt, title: "Pharaoh's Egypt", when: "over 3,000 years ago",
            things: ["🐈", "🐊", "🪲", "🌾", "🍞", "🧅", "🐟", "🦆", "🐄", "🏺", "🐍", "⛵️"],
            people: ["👸", "🧔", "👦"]),
    TGScene(era: .castle, title: "Knight's Castle", when: "700 years ago",
            things: ["🏰", "👑", "🛡️", "⚔️", "🐎", "🏹", "🍗", "🍞", "🧀", "🍎", "🕯️", "🪓", "🗝️", "🐕", "🪶", "📜", "🐖"],
            people: ["🤴", "👸", "🧑‍🌾"]),
    TGScene(era: .west, title: "Wild West", when: "150 years ago",
            things: ["🤠", "🐎", "🌵", "🦬", "🪕", "🎻", "🚂", "🪓", "🎩", "⛏️", "🥾", "🐄", "🌽", "🥔", "🔔"],
            people: ["🤠", "👩", "👦"]),
    TGScene(era: .cave, title: "Ice Age Cave", when: "over 12,000 years ago",
            things: ["🦣", "🔥", "🪨", "🦴", "🐺", "🦌", "🐻", "🍄", "🫐", "🐟", "🪶", "🐚"],
            people: ["🧔", "👩", "👧"]),
]

/// Something from the wrong time: its tier (0 blatant → 3 subtle), the eras it is SURELY wrong
/// for, and the one-line why shown on a zap or a miss.
private struct TGIntruder {
    let emoji: String
    let tier: Int
    let bad: Set<TGEra>
    let why: String
}

private let tgAll = Set(TGEra.allCases)
private let tgOldWorld: Set<TGEra> = [.rome, .feast, .egypt, .castle]
private let tgBefore1800 = tgAll.subtracting([.west])

private func tgFood(_ e: String, _ name: String) -> TGIntruder {
    TGIntruder(emoji: e, tier: 2, bad: tgOldWorld,
               why: "\(name) came from the Americas — no one here had them before 1492!")
}

private let tgIntruders: [TGIntruder] = [
    // Tier 0 — blatant modern gadgets (level I uses only these).
    TGIntruder(emoji: "📱", tier: 0, bad: tgAll, why: "Phones are from our time!"),
    TGIntruder(emoji: "💻", tier: 0, bad: tgAll, why: "Computers are from our time!"),
    TGIntruder(emoji: "🎮", tier: 0, bad: tgAll, why: "Video games are from our time!"),
    TGIntruder(emoji: "🚀", tier: 0, bad: tgAll, why: "Space rockets are from modern times!"),
    TGIntruder(emoji: "📺", tier: 0, bad: tgAll, why: "TVs are from modern times!"),
    TGIntruder(emoji: "✈️", tier: 0, bad: tgAll, why: "Planes first flew in 1903!"),
    TGIntruder(emoji: "🚁", tier: 0, bad: tgAll, why: "Helicopters are from modern times!"),
    TGIntruder(emoji: "🚗", tier: 0, bad: tgBefore1800, why: "Cars hadn't been invented yet!"),
    // Tier 1 — inventions of the 1800s and 1900s.
    TGIntruder(emoji: "💡", tier: 1, bad: tgBefore1800, why: "Light bulbs came in the 1800s!"),
    TGIntruder(emoji: "🚲", tier: 1, bad: tgBefore1800, why: "Bicycles came in the 1800s!"),
    TGIntruder(emoji: "📷", tier: 1, bad: tgBefore1800, why: "Cameras came in the 1800s!"),
    TGIntruder(emoji: "🚂", tier: 1, bad: tgBefore1800, why: "Steam trains came in the 1800s!"),
    TGIntruder(emoji: "🧸", tier: 1, bad: tgAll, why: "Teddy bears came in 1902!"),
    TGIntruder(emoji: "🛹", tier: 1, bad: tgAll, why: "Skateboards came in the 1950s!"),
    TGIntruder(emoji: "🎧", tier: 1, bad: tgAll, why: "Headphones are from modern times!"),
    TGIntruder(emoji: "🚦", tier: 1, bad: tgAll, why: "Traffic lights are about 100 years old!"),
    // Tier 2 — food from the Americas at Old-World tables (Columbus crossed in 1492).
    tgFood("🍅", "Tomatoes"), tgFood("🥔", "Potatoes"), tgFood("🌽", "Corn"),
    tgFood("🌶️", "Chili peppers"), tgFood("🍍", "Pineapples"), tgFood("🥑", "Avocados"),
    tgFood("🥜", "Peanuts"), tgFood("🦃", "Turkeys"),
    TGIntruder(emoji: "🍫", tier: 2, bad: tgOldWorld,
               why: "Chocolate is made from cacao from the Americas — no one here had it before 1492!"),
    // Tier 3 — subtler: older inventions, still too late for the scene.
    TGIntruder(emoji: "👓", tier: 3, bad: [.rome, .feast, .egypt, .cave], why: "Glasses were invented about 700 years ago!"),
    TGIntruder(emoji: "🔭", tier: 3, bad: tgBefore1800, why: "Telescopes were invented about 400 years ago!"),
    TGIntruder(emoji: "✏️", tier: 3, bad: tgBefore1800, why: "Pencils came about 450 years ago!"),
    TGIntruder(emoji: "🎻", tier: 3, bad: tgBefore1800, why: "Violins came about 500 years ago!"),
    TGIntruder(emoji: "⚔️", tier: 3, bad: [.cave], why: "Metal swords came long after the Ice Age!"),
    TGIntruder(emoji: "📜", tier: 3, bad: [.cave], why: "Writing came long after the Ice Age!"),
    TGIntruder(emoji: "🛞", tier: 3, bad: [.cave], why: "The wheel came long after the Ice Age!"),
]

/// Level I's Roman things: the unmistakably old-looking ones.
private let tgClassicRome = ["🏛️", "🏺", "🛡️", "⚔️", "🐎", "📜", "🌿", "🐐"]

/// Blatant, instantly-recognisable gadgets for level I.
private let tgLevelOne: Set<String> = ["📱", "🚗", "📺", "🚀", "🎮", "💻", "✈️"]

private struct TGItem: Identifiable {
    let id: Int
    let emoji: String
    let pos: CGPoint          // unit coordinates in the scene
    let intruder: Bool
}

private struct TGRound {
    let scene: TGScene
    let items: [TGItem]
    let intruder: TGIntruder
    var answer: Int { items.firstIndex(where: \.intruder) ?? 0 }
}


// MARK: Generator

private enum TGGen {
    /// A round in `era` with `n` things whose intruder is of `tier`. `classic` = the gentlest
    /// version (only unmistakable gadgets among classic Roman things). Nil if no intruder fits.
    static func round(era: TGEra, tier: Int, n: Int, classic: Bool, avoid: String?) -> TGRound? {
        let scene = tgScenes.first { $0.era == era }!
        var pool = tgIntruders.filter {
            $0.tier == tier && $0.bad.contains(era) && !scene.things.contains($0.emoji) && $0.emoji != avoid
        }
        if classic { pool = pool.filter { tgLevelOne.contains($0.emoji) } }
        guard let intruder = pool.randomElement() else { return nil }
        let things = classic && era == .rome ? tgClassicRome : scene.things
        let pick = Array(things.shuffled().prefix(n - 1)) + [intruder.emoji]
        let slots = layout(n)
        let items = pick.shuffled().enumerated().map { i, e in
            TGItem(id: i, emoji: e, pos: slots[i], intruder: e == intruder.emoji)
        }
        return TGRound(scene: scene, items: items, intruder: intruder)
    }

    /// Spread positions over the scene (a jittered grid, cells shuffled).
    static func layout(_ n: Int) -> [CGPoint] {
        let cols = n <= 4 ? 2 : 3
        let rows = n <= 4 ? 2 : (n <= 6 ? 2 : 3)
        let cells = (0..<(cols * rows)).shuffled().prefix(n)
        let x0 = 0.1, x1 = 0.9, y0 = 0.3, y1 = 0.97
        return cells.map { c in
            let cx = x0 + (x1 - x0) * (Double(c % cols) + 0.5) / Double(cols)
            let cy = y0 + (y1 - y0) * (Double(c / cols) + 0.5) / Double(rows)
            let jx = (x1 - x0) / Double(cols) * Double.random(in: -0.16...0.16)
            let jy = (y1 - y0) / Double(rows) * Double.random(in: -0.14...0.14)
            return CGPoint(x: cx + jx, y: cy + jy)
        }
    }

    #if DEBUG
    /// Every generated round has exactly one wrong-time thing and no right-time thing that is
    /// also listed as wrong for that era. Prints a one-line verdict (run with LUDUS_SELFCHECK=1).
    static func selfCheck() {
        var problems: [String] = []
        for s in tgScenes {
            if Set(s.things).count != s.things.count { problems.append("dup thing in \(s.title)") }
            for t in s.things where tgIntruders.contains(where: { $0.emoji == t && $0.bad.contains(s.era) }) {
                problems.append("\(t) is both right and wrong in \(s.title)")
            }
        }
        var rounds = 0
        for era in TGEra.allCases {
            for tier in 0...3 {
                for n in 3...8 {
                    for classic in [false, true] {
                        for _ in 0..<30 {
                            guard let r = round(era: era, tier: tier, n: n, classic: classic, avoid: nil) else { continue }
                            rounds += 1
                            let wrong = r.items.filter { e in tgIntruders.contains { $0.emoji == e.emoji && $0.bad.contains(r.scene.era) } }
                            if wrong.count != 1 || r.items.filter(\.intruder).count != 1 || r.items.count != n
                                || Set(r.items.map(\.emoji)).count != r.items.count {
                                problems.append("\(r.scene.title): \(r.items.map(\.emoji).joined())")
                            }
                        }
                    }
                }
            }
        }
        print("TG-SELFCHECK rounds=\(rounds) problems=\(problems.count) \(problems.prefix(5))"); fflush(stdout)
    }
    #endif
}

// MARK: Model

@MainActor
private final class TimeGuardModel: ArcadeModel {
    enum Stage: Equatable { case asking, zapped, missed(tapped: Int?) }

    @Published var round = TGGen.round(era: .rome, tier: 0, n: 3, classic: true, avoid: nil)!
    @Published var stage: Stage = .asking
    @Published var roundNo = 0
    @Published var tLeft: Double = 0
    @Published var perQ: Double = 0

    init() {
        super.init(key: GameID.timeGuard.rawValue)
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { TGGen.selfCheck() }
        #endif
    }

    override func perLevel(_ level: Int) -> Int { 5 }
    override func onBegin() { next() }

    func next() {
        let n = rampInt(3, 8, to: 8.5)
        let classic = d < 1.8
        let groups: [[TGEra]] = [[.rome], [.feast, .egypt, .castle], [.west, .cave]]
        var made: TGRound?
        for _ in 0..<40 where made == nil {
            let era = groups[tier([1, 1.8, 3])].randomElement()!
            let t = classic ? 0 : tier([1, 2.6, 3.8, 5])
            made = TGGen.round(era: era, tier: t, n: n, classic: classic, avoid: round.intruder.emoji)
        }
        round = made ?? TGGen.round(era: .rome, tier: 0, n: n, classic: false, avoid: nil)!
        stage = .asking
        roundNo += 1
        perQ = d >= 4.5 ? ramp(22, 9, from: 4.5, to: 10) : 0
        tLeft = perQ
    }

    func tap(_ i: Int) {
        guard phase == .playing, stage == .asking else { return }
        if i == round.answer {
            stage = .zapped
            hit()
            Sfx.play(.sparkle)
            forumAfter(self, 1.5, round: { $0.roundNo }) { $0.next() }
        } else {
            stage = .missed(tapped: i)
            let last = miss(reason: i < 0 ? "The hourglass ran out!" : "Out of hearts!", delay: 2.3)
            if !last { forumAfter(self, 2.4, round: { $0.roundNo }) { $0.next() } }
        }
    }

    func tick(_ dt: Double) {
        guard phase == .playing, stage == .asking, perQ > 0 else { return }
        tLeft -= dt
        if tLeft <= 0 { tLeft = 0; tap(-1) }
    }

    override func botAct(correct: Bool) {
        guard stage == .asking else { return }
        let wrong = round.items.indices.filter { $0 != round.answer }
        tap(correct ? round.answer : wrong.randomElement()!)
    }
}

// MARK: View

struct TimeGuardView: View {
    let onClose: () -> Void
    @StateObject private var model = TimeGuardModel()

    var body: some View {
        let era = model.phase == .intro ? TGEra.rome : model.round.scene.era
        ArcadeShell(model: model, spec: GameID.timeGuard.spec!, accent: Lu.gold, onClose: onClose,
                    backdrop: {
                        TGBackdrop(era: era)
                            .id(era)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.5), value: era)
                    }) {
            VStack(spacing: 6) {
                HUDSpace(58)
                header
                TGSceneView(model: model)
                    .id(model.roundNo)
                    .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity),
                                            removal: .opacity))
                caption
            }
            .padding(.horizontal, 12).padding(.bottom, 6)
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: model.roundNo)
        }
        // A task, not a Timer stored on this struct (that was rebuilt on every redraw).
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                model.tick(0.1)
            }
        }
    }

    /// A carved sign: where and when we are, and the hourglass once there's a rush.
    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(model.round.scene.title).font(luSerif(22, .black)).foregroundStyle(Color(hex: 0x3a2412))
                Text(model.round.scene.when.uppercased()).font(luFont(11, .heavy)).tracking(1.5)
                    .foregroundStyle(Color(hex: 0x8a5a2a))
            }
            Spacer()
            if model.perQ > 0 { TGHourglass(frac: model.tLeft / model.perQ) }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0xf3e3c0).opacity(0.94))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: Lu.goldLine), lineWidth: 2)))
        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
    }

    /// The Time Guard himself, saying the job — or why, after a zap or a miss.
    private var caption: some View {
        let why = model.round.intruder.why
        let mood: ForumPerson.Mood = {
            switch model.stage {
            case .asking: return .talk
            case .zapped: return .cheer
            case .missed: return .oops
            }
        }()
        let (text, hex): (String, UInt) = {
            switch model.stage {
            case .asking: return ("Tap the thing from the WRONG time!", Lu.inkDark)
            case .zapped: return ("Zapped! " + why, 0x2f6a2a)
            case .missed: return ("That one! " + why, 0x9a3a1a)
            }
        }()
        return HStack(alignment: .bottom, spacing: 4) {
            ForumPerson(mood: mood, hat: .helmet, tunic: 0x6a3fa0, skin: 0xf0c49a, size: 92)
            ForumBubble(fill: 0xfdf6e3, tailX: 0.06) {
                HStack(spacing: 8) {
                    if model.stage != .asking { Text(model.round.intruder.emoji).font(.system(size: 30)) }
                    Text(text).font(luFont(17, .heavy)).foregroundStyle(Color(hex: hex))
                        .lineLimit(3).minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                }
            }
            .frame(minHeight: 64)
            .padding(.bottom, 26)
        }
        .animation(.easeOut(duration: 0.2), value: model.stage)
    }
}

/// A sand-glass that drains (from d≈4.5).
private struct TGHourglass: View {
    let frac: Double
    var body: some View {
        HStack(spacing: 6) {
            Text("⏳").font(.system(size: 22))
            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: 0xd9c49a))
                Capsule().fill(Color(hex: frac < 0.3 ? Lu.coral : 0xc98a2a))
                    .frame(width: 90 * max(0, min(1, frac)))
            }
            .frame(width: 90, height: 10)
        }
    }
}

// MARK: Scene

private struct TGSceneView: View {
    @ObservedObject var model: TimeGuardModel
    @State private var shake = 0

    var body: some View {
        GeometryReader { geo in
            let size = CGSize(width: geo.size.width, height: geo.size.height - 92)   // the locals' strip below
            let n = model.round.items.count
            let glyph: CGFloat = n <= 3 ? 74 : (n <= 4 ? 64 : (n <= 6 ? 56 : 50))
            ZStack(alignment: .topLeading) {
                ForEach(model.round.items) { item in
                    TGThingView(item: item, glyph: glyph, stage: model.stage,
                                live: model.phase == .playing) { model.tap(item.id) }
                        .position(x: item.pos.x * size.width, y: item.pos.y * size.height)
                }
                locals(geo.size)
            }
            .modifier(TGShake(amount: CGFloat(shake)))
            .onChange(of: model.lastMiss) { _ in withAnimation(.linear(duration: 0.4)) { shake += 1 } }
        }
    }

    /// The scene's locals along the bottom, dressed for their time: they cheer on a zap and gasp
    /// on a miss.
    private func locals(_ size: CGSize) -> some View {
        let mood: ForumPerson.Mood = {
            switch model.stage {
            case .asking: return .idle
            case .zapped: return .cheer
            case .missed: return .oops
            }
        }()
        let folk = tgFolk(model.round.scene.era)
        return HStack(spacing: 18) {
            ForEach(Array(folk.enumerated()), id: \.offset) { i, f in
                ForumPerson(mood: mood, hat: f.hat, tunic: f.tunic, skin: f.skin, size: 84, beard: f.beard,
                            lookX: CGFloat(i - 1) * -0.8)
                    .offset(y: model.stage == .zapped ? -12 : 0)
                    .animation(.spring(response: 0.28, dampingFraction: 0.35).delay(Double(i) * 0.07), value: model.stage)
            }
        }
        .position(x: size.width / 2, y: size.height - 44)
        .allowsHitTesting(false)
    }
}

private struct TGFolk { let hat: ForumPerson.Hat; let tunic: UInt; let skin: UInt; let beard: Bool }

/// Three locals per scene, dressed for when they live.
private func tgFolk(_ era: TGEra) -> [TGFolk] {
    switch era {
    case .rome, .feast:
        return [TGFolk(hat: .laurel, tunic: 0xf2ead8, skin: 0xe8b88e, beard: false),
                TGFolk(hat: .hair(0x3a2412), tunic: 0xb5493a, skin: 0xd9a27a, beard: false),
                TGFolk(hat: .helmet, tunic: 0xa82820, skin: 0xf0c49a, beard: true)]
    case .egypt:
        return [TGFolk(hat: .hair(0x1a1410), tunic: 0xf4eedc, skin: 0xb07a4e, beard: false),
                TGFolk(hat: .hair(0x1a1410), tunic: 0x3f8fb0, skin: 0xa86f44, beard: false),
                TGFolk(hat: .hair(0x1a1410), tunic: 0xe8c45a, skin: 0xb98454, beard: false)]
    case .castle:
        return [TGFolk(hat: .helmet, tunic: 0x6b7a8a, skin: 0xf0c49a, beard: true),
                TGFolk(hat: .hood, tunic: 0x6b5a8a, skin: 0xe8b88e, beard: false),
                TGFolk(hat: .cap, tunic: 0x7a8a4a, skin: 0xd9a27a, beard: false)]
    case .west:
        return [TGFolk(hat: .sunHat, tunic: 0x8a4a2a, skin: 0xe8b88e, beard: true),
                TGFolk(hat: .hair(0x8a5a2a), tunic: 0x4f7fb0, skin: 0xf0c49a, beard: false),
                TGFolk(hat: .sunHat, tunic: 0x6a7a3a, skin: 0xc98d62, beard: false)]
    case .cave:
        return [TGFolk(hat: .hair(0x3a2412), tunic: 0x9a7a5a, skin: 0xd9a27a, beard: true),
                TGFolk(hat: .hair(0x5a3a22), tunic: 0x8a6a4a, skin: 0xe0b088, beard: false),
                TGFolk(hat: .hair(0x2a1a10), tunic: 0xa5865e, skin: 0xc98d62, beard: false)]
    }
}

/// One thing in the scene: bobs gently while waiting; the intruder spins into a portal on a zap;
/// on a miss the tapped one gets a ✗ and the intruder a glowing ring.
private struct TGThingView: View {
    let item: TGItem
    let glyph: CGFloat
    let stage: TimeGuardModel.Stage
    let live: Bool
    let action: () -> Void
    @State private var bob = false

    private var zapped: Bool { stage == .zapped && item.intruder }
    private var reveal: Bool { if case .missed = stage { return item.intruder }; return false }
    private var wrongTap: Bool { if case .missed(let t) = stage { return t == item.id }; return false }
    private var faded: Bool { stage != .asking && !item.intruder && !wrongTap }

    var body: some View {
        Button(action: action) {
            ZStack {
                Ellipse().fill(Color.black.opacity(0.22)).frame(width: glyph * 0.9, height: glyph * 0.22)
                    .offset(y: glyph * 0.52)
                if zapped {
                    TGPortal(size: glyph * 1.5)
                    TGSparks(size: glyph)
                }
                if reveal {
                    Circle().stroke(Color(hex: Lu.gold), lineWidth: 5)
                        .frame(width: glyph * 1.45, height: glyph * 1.45)
                        .shadow(color: Color(hex: Lu.gold), radius: 8)
                        .transition(.scale(scale: 1.8).combined(with: .opacity))
                }
                Text(item.emoji).font(.system(size: glyph))
                    .rotationEffect(.degrees(zapped ? 540 : 0))
                    .scaleEffect(zapped ? 0.05 : (reveal ? 1.18 : 1))
                    .opacity(zapped ? 0 : 1)
                    .offset(y: bob ? -4 : 3)
                if wrongTap {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white, Color(hex: Lu.coral))
                        .offset(x: glyph * 0.42, y: -glyph * 0.42)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: max(76, glyph * 1.4), height: max(76, glyph * 1.4))
            .contentShape(Rectangle())
            .opacity(faded ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .animation(.easeIn(duration: 0.7), value: zapped)
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: reveal)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: wrongTap)
        .animation(.easeOut(duration: 0.3), value: faded)
        .onAppear { setBob(live) }
        .onChange(of: live) { setBob($0) }
    }

    private func setBob(_ on: Bool) {
        if on {
            withAnimation(.easeInOut(duration: Double.random(in: 1.1...1.6)).repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...0.6))) { bob = true }
        } else {
            withAnimation(.easeOut(duration: 0.2)) { bob = false }
        }
    }
}

/// The time-portal: a swirl that opens, spins and closes again.
private struct TGPortal: View {
    let size: CGFloat
    @State private var t = false
    @State private var close = false
    var body: some View {
        Text("🌀").font(.system(size: size))
            .rotationEffect(.degrees(t ? -540 : 0))
            .scaleEffect(close ? 0.01 : (t ? 1.1 : 0.1))
            .onAppear {
                withAnimation(.easeOut(duration: 0.9)) { t = true }
                withAnimation(.easeIn(duration: 0.35).delay(0.95)) { close = true }
            }
    }
}

/// A few ✨ flying out of the portal.
private struct TGSparks: View {
    let size: CGFloat
    @State private var out = false
    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                let a = Double(i) / 6 * 2 * .pi
                Text(i.isMultiple(of: 2) ? "✨" : "⭐️").font(.system(size: 18))
                    .offset(x: out ? cos(a) * size : 0, y: out ? sin(a) * size : 0)
                    .opacity(out ? 0 : 1)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.9)) { out = true } }
    }
}

private struct TGShake: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat { get { amount } set { amount = newValue } }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 9 * sin(amount * .pi * 6), y: 0))
    }
}

// MARK: Backdrops — painted from simple shapes

private struct TGBackdrop: View {
    let era: TGEra

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                LinearGradient(colors: sky.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom)
                scenery(w, h)
                // ground
                Rectangle().fill(LinearGradient(colors: ground.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom))
                    .frame(height: h * 0.42).position(x: w / 2, y: h * 0.79)
            }
        }
    }

    private var sky: [UInt] {
        switch era {
        case .rome: return [0x7fb6e0, 0xf3d9a8]
        case .feast: return [0x8e2f25, 0xb5493a]          // Pompeian-red dining-room wall
        case .egypt: return [0xf2a541, 0xfbe3a0]
        case .castle: return [0x6f9fcf, 0xc9dceb]
        case .west: return [0xe8743b, 0xf6c177]
        case .cave: return [0x1d120c, 0x4a2e1c]
        }
    }
    private var ground: [UInt] {
        switch era {
        case .rome: return [0xc9b48a, 0xa8916a]
        case .feast: return [0x7a4a26, 0x5c3519]          // the long table
        case .egypt: return [0xe6c27a, 0xc9a157]
        case .castle: return [0x6fa857, 0x4f8a3c]
        case .west: return [0xc8743f, 0xa25a2e]
        case .cave: return [0x5a3a24, 0x3b2516]
        }
    }

    @ViewBuilder
    private func scenery(_ w: CGFloat, _ h: CGFloat) -> some View {
        switch era {
        case .rome:
            // A temple: pediment over columns.
            let tw = w * 0.56, base = h * 0.6
            ZStack {
                TGTriangle().fill(Color(hex: 0xefe4cc)).frame(width: tw * 1.1, height: h * 0.1)
                    .position(x: w * 0.5, y: base - h * 0.37)
                ForEach(0..<5, id: \.self) { i in
                    Rectangle().fill(Color(hex: 0xf4ecda))
                        .frame(width: tw * 0.08, height: h * 0.3)
                        .position(x: w * 0.5 - tw / 2 + tw * (0.06 + 0.22 * Double(i)), y: base - h * 0.17)
                }
                Rectangle().fill(Color(hex: 0xe2d4b6)).frame(width: tw * 1.08, height: h * 0.025)
                    .position(x: w * 0.5, y: base - h * 0.315)
            }
            .opacity(0.55)
        case .feast:
            ZStack {
                ForEach(0..<3, id: \.self) { i in   // painted wall panels with garlands
                    RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0x6e2219).opacity(0.5))
                        .frame(width: w * 0.24, height: h * 0.16)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: 0xe8b04a).opacity(0.6), lineWidth: 3))
                        .position(x: w * (0.2 + 0.3 * Double(i)), y: h * 0.33)
                    ForumArc().stroke(Color(hex: 0x5f9e3a), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: w * 0.26, height: h * 0.03).rotationEffect(.degrees(180))
                        .position(x: w * (0.2 + 0.3 * Double(i)), y: h * 0.23)
                }
                Rectangle().fill(Color(hex: 0x2a1410).opacity(0.6)).frame(height: h * 0.05).position(x: w / 2, y: h * 0.54)
            }
        case .egypt:
            ZStack {
                Circle().fill(Color(hex: 0xfff3c4)).frame(width: w * 0.16).position(x: w * 0.82, y: h * 0.16)
                TGTriangle().fill(Color(hex: 0xd9a95b)).frame(width: w * 0.62, height: h * 0.36)
                    .position(x: w * 0.36, y: h * 0.42)
                TGTriangle().fill(Color(hex: 0xcf9d50)).frame(width: w * 0.42, height: h * 0.25)
                    .position(x: w * 0.76, y: h * 0.475)
            }
            .opacity(0.8)
        case .castle:
            let wallTop = h * 0.36
            ZStack {
                Rectangle().fill(Color(hex: 0x9b9fa8)).frame(width: w, height: h * 0.3).position(x: w / 2, y: wallTop + h * 0.15)
                ForEach(0..<9, id: \.self) { i in
                    Rectangle().fill(Color(hex: 0x9b9fa8)).frame(width: w * 0.06, height: h * 0.04)
                        .position(x: w * (0.06 + 0.11 * Double(i)), y: wallTop - h * 0.02)
                }
                ForEach([0.12, 0.88], id: \.self) { x in
                    Rectangle().fill(Color(hex: 0x878b94)).frame(width: w * 0.17, height: h * 0.42)
                        .position(x: w * x, y: wallTop + h * 0.09)
                    TGTriangle().fill(Color(hex: 0x8c3b3b)).frame(width: w * 0.21, height: h * 0.1)
                        .position(x: w * x, y: wallTop - h * 0.17)
                }
            }
            .opacity(0.6)
        case .west:
            ZStack {
                Circle().fill(Color(hex: 0xffe08a)).frame(width: w * 0.22).position(x: w * 0.25, y: h * 0.4)
                RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0xb4572c)).frame(width: w * 0.36, height: h * 0.18)
                    .position(x: w * 0.75, y: h * 0.52)
                RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0xa64f28)).frame(width: w * 0.2, height: h * 0.26)
                    .position(x: w * 0.6, y: h * 0.5)
            }
            .opacity(0.75)
        case .cave:
            ZStack {
                RadialGradient(colors: [Color(hex: 0xf08a3a).opacity(0.45), .clear], center: .center,
                               startRadius: 0, endRadius: w * 0.6)
                    .position(x: w * 0.5, y: h * 0.6)
                Ellipse().fill(Color(hex: 0x6a4a33)).frame(width: w * 1.4, height: h * 0.5)
                    .position(x: w * 0.5, y: -h * 0.04)
                // cave paintings
                Text("🦌  🐂").font(.system(size: 26)).opacity(0.18).position(x: w * 0.5, y: h * 0.33)
            }
        }
    }
}

private struct TGTriangle: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.midX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            p.closeSubpath()
        }
    }
}
