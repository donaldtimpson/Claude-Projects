import SwiftUI

// MARK: - The Dig (Forum · History · eras in order)
//
// You're on an archaeology dig. The ground is cut open so you can see its layers — and the deeper
// a layer, the longer ago it was laid down. The archaeologist pulls a find out of her sieve; DRAG
// it down and bury it in the layer of its time (a dinosaur near the bottom, a phone on top). A
// right find settles into its layer with a puff of dust and stays there, so your dig fills up with
// everything you've placed; a wrong one floats over to its real layer, which glows.
//
// Difficulty runs on `d` (GameKit):
//   • layers: 2 (dinosaurs vs today) → 6, and the eras on show get closer together in time
//     (ages apart at first; Greece next to Rome later);
//   • finds — tier([1, 3, 5]): instantly-known pictures → subtler things → named events
//     (Magna Carta, the first Olympic Games);
//   • labels: a picture + name per layer → from d≈6 only DATES (BC/AD), so the child has to know
//     WHEN — and that 500 BC is older than AD 100;
//   • from d≈5 the sun is setting on the dig (20 s → 8 s a find).

// MARK: Data

private struct DigEra {
    let icon: String
    let name: String
    let dates: String
    let tint: UInt              // the layer's soil colour
    /// "It's from …": the Stone Age, Ancient Egypt, the 1900s, today.
    var from: String {
        switch name {
        case "Stone Age", "Middle Ages", "Steam Age", "1900s": return "the " + name
        case "Dinosaurs": return "dinosaur times"
        case "Explorers": return "the age of explorers"
        case "Today": return "today"
        default: return name
        }
    }
}

private let digEras: [DigEra] = [
    DigEra(icon: "🌋", name: "Dinosaurs", dates: "Over 66 million years ago", tint: 0x4a3426),
    DigEra(icon: "🔥", name: "Stone Age", dates: "Before 3000 BC", tint: 0x5c4030),
    DigEra(icon: "☥", name: "Ancient Egypt", dates: "3000 BC – 30 BC", tint: 0x8a6a3e),
    DigEra(icon: "🏺", name: "Ancient Greece", dates: "800 BC – 150 BC", tint: 0x7a5a3a),
    DigEra(icon: "🦅", name: "Ancient Rome", dates: "753 BC – AD 476", tint: 0x8d5a3c),
    DigEra(icon: "👑", name: "Middle Ages", dates: "AD 500 – 1450", tint: 0x6e5a44),
    DigEra(icon: "🧭", name: "Explorers", dates: "AD 1450 – 1700", tint: 0x7c6446),
    DigEra(icon: "🏭", name: "Steam Age", dates: "AD 1700 – 1900", tint: 0x6a5848),
    DigEra(icon: "📻", name: "1900s", dates: "AD 1900 – 2000", tint: 0x7a6a56),
    DigEra(icon: "🌐", name: "Today", dates: "AD 2000 – now", tint: 0x8a7a62),
]

private struct DigFind: Hashable {
    let emoji: String
    let name: String
    let era: Int
    let tier: Int        // 0 known on sight · 1 subtler · 2 a named event
}

private func df(_ e: String, _ n: String, _ era: Int, _ t: Int) -> DigFind { DigFind(emoji: e, name: n, era: era, tier: t) }

// Each is placed in the era it is best known for (dates checked against standard references).
private let digFinds: [DigFind] = [
    df("🦖", "T. rex", 0, 0), df("🦕", "Long-neck dinosaur", 0, 0),
    df("🥚", "Dinosaur egg", 0, 1), df("🦴", "Dinosaur bone", 0, 1),
    df("🦣", "Woolly mammoth", 1, 0), df("🪨", "Stone axe", 1, 1), df("🛖", "Mud hut", 1, 1),
    df("🖐️", "Cave hand painting", 1, 2), df("🦌", "Reindeer hunters", 1, 2),
    df("🔺", "Pyramid", 2, 0), df("🪲", "Scarab charm", 2, 1), df("⚱️", "Mummy jar", 2, 1),
    df("🐈", "Cat mummy", 2, 2), df("📜", "Hieroglyph papyrus", 2, 2),
    df("🎭", "Greek theatre mask", 3, 1), df("🦉", "Owl coin of Athens", 3, 1),
    df("🏅", "First Olympic Games (776 BC)", 3, 2), df("🏛️", "The Parthenon is built", 3, 2),
    df("🏟️", "Colosseum", 4, 0), df("🛡️", "Legion shield", 4, 1), df("🪙", "Silver denarius coin", 4, 1),
    df("🌋", "Vesuvius buries Pompeii", 4, 2), df("🧱", "Hadrian's Wall", 4, 2),
    df("🏰", "Castle", 5, 0), df("🏹", "Longbow archer", 5, 1), df("🪶", "Monk's quill pen", 5, 1),
    df("📃", "Magna Carta (AD 1215)", 5, 2), df("⚔️", "Battle of Hastings", 5, 2),
    df("⛵️", "Columbus's ship", 6, 0), df("🗺️", "Map of the New World", 6, 1), df("🔭", "Galileo's telescope", 6, 1),
    df("📖", "Gutenberg's printed Bible", 6, 2), df("🚢", "The Mayflower", 6, 2),
    df("🚂", "Steam train", 7, 0), df("💡", "Edison's light bulb", 7, 1), df("📷", "First photograph", 7, 1),
    df("☎️", "First telephone", 7, 2), df("🎩", "Lincoln's top hat", 7, 2),
    df("✈️", "First airplane", 8, 0), df("🚀", "Moon rocket", 8, 0), df("📺", "First TV", 8, 1),
    df("🚗", "Model T car", 8, 1), df("🌕", "Moon landing (1969)", 8, 2),
    df("📱", "Smartphone", 9, 0), df("🤳", "Selfie", 9, 1),
]

// MARK: Model

@MainActor
private final class DigModel: ArcadeModel {
    enum Stage: Equatable { case waiting, placed, missed(Int) }

    @Published var eras: [Int] = [0, 9]          // the layers showing, oldest first
    @Published var find = digFinds[0]
    @Published var stage: Stage = .waiting
    @Published var roundNo = 0
    @Published var datesOnly = false
    @Published var showName = false
    @Published var deadline: Date?
    @Published var limit: Double = 0
    @Published var buried: [Int: [String]] = [:]  // era → finds placed this run

    init() { super.init(key: GameID.dig.rawValue) }

    override func onBegin() { buried = [:]; next() }

    func next() {
        let n = rampInt(2, 6, to: 7.5)
        let gap = max(1, rampInt(4, 1, from: 1.5, to: 6))
        // The find first (a picture a child knows at the start, named events later), then its
        // layer and n-1 others around it in time.
        let t = tier([1, 3, 5])
        let pool = digFinds.filter { $0.emoji != find.emoji }
        find = (pool.filter { $0.tier == t }.randomElement()) ?? pool.randomElement()!
        eras = pickEras(n, gap: gap, including: find.era)
        datesOnly = chance(1, from: 6, to: 9)
        showName = d >= 1.8 || find.tier > 0
        stage = .waiting
        roundNo += 1
        limit = d >= 5 ? ramp(20, 8, from: 5, to: 10) : 0
        deadline = limit > 0 ? Date().addingTimeInterval(limit) : nil
        if limit > 0 {
            forumAfter(self, limit, round: { $0.roundNo }) { m in
                if m.stage == .waiting { m.fail(reason: "The sun set on the dig!") }
            }
        }
        if showName { LibraryVoice.say(find.name.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")) }
    }

    /// n eras from oldest to newest, at least `gap` apart in the list, one of them `must`.
    private func pickEras(_ n: Int, gap: Int, including must: Int) -> [Int] {
        var g = gap
        while g > 1 && (n - 1) * g > digEras.count - 1 { g -= 1 }
        while g >= 1 {
            for _ in 0..<300 {
                let others = Array(0..<digEras.count).filter { $0 != must }.shuffled().prefix(n - 1)
                let picks = (Array(others) + [must]).sorted()
                if zip(picks, picks.dropFirst()).allSatisfy({ $1 - $0 >= g }) { return picks }
            }
            g -= 1
        }
        return Array(Set([must] + Array(0..<digEras.count).shuffled().prefix(n - 1))).sorted()
    }

    /// The find is dropped on layer `i` (index into `eras`; drags, taps and the bot all land here).
    func drop(on i: Int) {
        guard phase == .playing, stage == .waiting, eras.indices.contains(i) else { return }
        deadline = nil
        if eras[i] == find.era {
            stage = .placed
            buried[find.era, default: []].append(find.emoji)
            hit()
            Sfx.play(.thud)
            forumAfter(self, 1.3, round: { $0.roundNo }) { $0.next() }
        } else {
            fail(reason: "Out of hearts!")
        }
    }

    func fail(reason: String) {
        guard stage == .waiting else { return }
        deadline = nil
        stage = .missed(eras.firstIndex(of: find.era) ?? 0)
        let last = miss(reason: reason, delay: 2.6)
        LibraryVoice.say("\(find.name) — \(digEras[find.era].name)")
        if !last { forumAfter(self, 2.8, round: { $0.roundNo }) { $0.next() } }
    }

    var answer: Int { eras.firstIndex(of: find.era) ?? 0 }

    override func botAct(correct: Bool) {
        guard stage == .waiting else { return }
        drop(on: correct ? answer : eras.indices.filter { $0 != answer }.randomElement() ?? 0)
    }
}

// MARK: View

struct TheDigView: View {
    let onClose: () -> Void
    @StateObject private var model = DigModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.dig.spec!, accent: Lu.tangerine,
                    onClose: { LibraryVoice.stop(); onClose() },
                    backdrop: { DigBackdrop() }) {
            DigPlay(model: model)
        }
        .onDisappear { LibraryVoice.stop() }
    }
}

private struct DigBackdrop: View {
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .top) {
                // The cut face of the dig: bands of soil, darker the deeper they go.
                VStack(spacing: 0) {
                    LinearGradient(colors: [Color(hex: 0x7cc0ea), Color(hex: 0xcfe8f0)], startPoint: .top, endPoint: .bottom)
                        .frame(height: g.size.height * 0.3)
                    Color(hex: 0x5f9a3a).frame(height: 22)
                    ForEach(0..<6, id: \.self) { k in
                        DigWavy(seed: k + 2).fill(luShade(0x8a7a62, -k * 14))
                    }
                }
            }
        }
    }
}

private struct DigLayerFrames: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) { value.merge(nextValue()) { $1 } }
}

private struct DigPlay: View {
    @ObservedObject var model: DigModel
    @State private var frames: [Int: CGRect] = [:]
    @State private var drag: CGSize = .zero
    @State private var dragPoint: CGPoint?
    @State private var findFrame: CGRect = .zero
    @State private var shakes: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 56)
            surface
                .zIndex(2)
            layers
                .zIndex(1)
        }
        .coordinateSpace(name: "dig")
        .onPreferenceChange(DigLayerFrames.self) { frames = $0 }
        .onChange(of: model.roundNo) { _ in drag = .zero; dragPoint = nil }
        .onChange(of: model.lastMiss) { _ in withAnimation(.linear(duration: 0.45)) { shakes += 1 } }
    }

    private var hoverLayer: Int? {
        guard let p = dragPoint else { return nil }
        return frames.first { $0.key >= 0 && $0.value.contains(p) }?.key
    }

    // MARK: Surface: grass, the archaeologist, her sieve with the find, and a caption.

    private var surface: some View {
        let mood: ForumPerson.Mood = {
            switch model.stage {
            case .placed: return .cheer
            case .missed: return .oops
            case .waiting: return dragPoint != nil ? .think : .talk
            }
        }()
        return ZStack(alignment: .bottom) {
            // Grass lip.
            Rectangle().fill(LinearGradient(colors: [Color(hex: 0x7dbb4e), Color(hex: 0x4f8a32)], startPoint: .top, endPoint: .bottom))
                .frame(height: 22)
            HStack(alignment: .bottom, spacing: 8) {
                ForumPerson(mood: mood, hat: .sunHat, tunic: 0x6b8f9e, skin: 0xc98d62, size: 112, lookX: 0.6)
                    .offset(y: 8)
                VStack(alignment: .leading, spacing: 6) {
                    caption
                    findView
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
            if model.limit > 0 {
                sunTimer.frame(maxWidth: .infinity, alignment: .trailing).padding(.trailing, 18).padding(.bottom, 22)
            }
        }
        .frame(height: 176)
    }

    private var caption: some View {
        let f = model.find
        let era = digEras[f.era]
        let text: String = {
            switch model.stage {
            case .waiting: return model.showName ? f.name : "Where does it go?"
            case .placed: return "Yes! \(era.name)!"
            case .missed: return "It's from \(era.from)!"
            }
        }()
        let hex: UInt = {
            switch model.stage {
            case .waiting: return Lu.inkDark
            case .placed: return 0x2f6a2a
            case .missed: return 0x9a3a1a
            }
        }()
        return ForumBubble(fill: 0xfdf6e3, tailX: 0.08) {
            HStack(spacing: 8) {
                Text(text).font(luFont(17, .heavy)).foregroundStyle(Color(hex: hex))
                    .lineLimit(2).minimumScaleFactor(0.6)
                if case .missed = model.stage, model.datesOnly {
                    Text(era.dates).font(luFont(12, .bold)).foregroundStyle(Color(hex: 0x6a5a48)).lineLimit(1).minimumScaleFactor(0.6)
                }
                Spacer(minLength: 0)
                LibrarySpeakerButton(size: 36) { LibraryVoice.say(model.showName ? f.name : "Drag it to its layer") }
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.stage)
    }

    /// The find in a wooden sieve: drag it down into the ground.
    private var findView: some View {
        let missedTo: Int? = { if case .missed(let i) = model.stage { return i }; return nil }()
        return ZStack {
            Circle().fill(Color(hex: 0x9a6a3a)).frame(width: 92, height: 92)
            Circle().stroke(Color(hex: 0x6a4224), lineWidth: 5).frame(width: 92, height: 92)
            Circle().fill(Color(hex: 0xc9a46a)).frame(width: 76, height: 76)
            Text(model.find.emoji).font(.system(size: 54))
                .offset(offsetForFind(missedTo))
                .scaleEffect(model.stage == .placed ? 0.2 : (dragPoint != nil ? 1.25 : 1))
                .opacity(model.stage == .placed ? 0 : 1)
                .shadow(color: missedTo != nil ? Color(hex: Lu.gold) : .black.opacity(0.3), radius: missedTo != nil ? 12 : 4)
                .animation(dragPoint != nil ? .interactiveSpring() : .spring(response: 0.55, dampingFraction: 0.75), value: drag)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: model.stage)
                .gesture(
                    DragGesture(minimumDistance: 2, coordinateSpace: .named("dig"))
                        .onChanged { v in
                            guard model.stage == .waiting, model.phase == .playing else { return }
                            if dragPoint == nil { Haptics.light(); Sfx.play(.tick) }
                            drag = v.translation; dragPoint = v.location
                        }
                        .onEnded { v in
                            dragPoint = nil
                            if let hit = frames.first(where: { $0.key >= 0 && $0.value.contains(v.location) })?.key {
                                // Keep it where it was dropped; it sinks in (or flies to its real layer).
                                if hit != model.answer { drag = .zero }
                                model.drop(on: hit)
                            } else {
                                drag = .zero
                            }
                        }
                )
                .zIndex(3)
        }
        .frame(width: 92, height: 92)
        .background(GeometryReader { g in Color.clear.onAppear { findFrame = g.frame(in: .named("dig")) }
            .onChange(of: g.frame(in: .named("dig"))) { findFrame = $0 } })
    }

    /// Where the find sits: following the finger, dropped, or flown to its real layer on a miss.
    private func offsetForFind(_ missedTo: Int?) -> CGSize {
        if let i = missedTo, let fr = frames[i], findFrame != .zero {
            return CGSize(width: fr.midX - findFrame.midX + 40, height: fr.midY - findFrame.midY)
        }
        if model.stage == .placed && drag == .zero, let fr = frames[model.answer], findFrame != .zero {
            return CGSize(width: fr.midX - findFrame.midX, height: fr.midY - findFrame.midY)
        }
        return drag
    }

    private var sunTimer: some View {
        TimelineView(.animation(minimumInterval: 0.1, paused: model.deadline == nil || model.phase != .playing)) { tl in
            let left = model.deadline.map { max(0, $0.timeIntervalSince(tl.date)) } ?? 0
            let f = model.limit > 0 ? left / model.limit : 0
            Circle().fill(Color(hex: f < 0.3 ? 0xe8743b : 0xffd95a)).frame(width: 46, height: 46)
                .shadow(color: Color(hex: 0xffb340), radius: 10)
                .offset(y: 8 + CGFloat(1 - f) * 52)
                .frame(width: 70, height: 60, alignment: .top)
                .clipped()
        }
    }

    // MARK: The layers (newest on top)

    private var layers: some View {
        let shown = Array(model.eras.enumerated()).reversed()
        return VStack(spacing: 0) {
            ForEach(Array(shown), id: \.element) { i, era in
                layer(i, era)
            }
        }
        .modifier(ForumShake(amount: 6, shakes: shakes))
        .id(model.roundNo)
        .transition(.opacity)
        .animation(.easeOut(duration: 0.25), value: model.roundNo)
    }

    private func layer(_ i: Int, _ e: Int) -> some View {
        let era = digEras[e]
        let depth = Double(e) / Double(digEras.count - 1)
        let hover = hoverLayer == i
        let missed: Bool = { if case .missed(let k) = model.stage { return k == i }; return false }()
        let placed = model.stage == .placed && i == model.answer
        let many = model.eras.count >= 5
        return ZStack(alignment: .leading) {
            DigWavy(seed: e)
                .fill(LinearGradient(colors: [luShade(era.tint, 12 - Int(depth * 0)), luShade(era.tint, -22)],
                                     startPoint: .top, endPoint: .bottom))
            DigPebbles(seed: e).fill(Color.black.opacity(0.16))
            // Finds buried here earlier in the run.
            GeometryReader { g in
                ForEach(Array((model.buried[e] ?? []).suffix(6).enumerated()), id: \.offset) { k, emo in
                    Text(emo).font(.system(size: many ? 22 : 28))
                        .rotationEffect(.degrees(Double((k * 47) % 60) - 30))
                        .opacity(0.55)
                        .position(x: g.size.width * (0.5 + 0.08 * CGFloat(k)), y: g.size.height * (k.isMultiple(of: 2) ? 0.45 : 0.68))
                }
            }
            // The label: a picture + name, or just the dates.
            HStack(spacing: 8) {
                if !model.datesOnly {
                    Text(era.icon).font(.system(size: many ? 26 : 34, weight: .bold)).foregroundStyle(Color(hex: Lu.gold))
                }
                VStack(alignment: .leading, spacing: 0) {
                    if !model.datesOnly {
                        Text(era.name).font(luFont(many ? 15 : 18, .heavy)).foregroundStyle(Color(hex: Lu.ink))
                    }
                    if model.datesOnly || model.d >= 3 {
                        Text(era.dates).font(luFont(model.datesOnly ? (many ? 15 : 17) : 11, .heavy))
                            .foregroundStyle(Color(hex: model.datesOnly ? Lu.ink : Lu.inkDim))
                    }
                }
                .lineLimit(1).minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Capsule().fill(Color.black.opacity(0.35)))
            .padding(.leading, 12)
            if i == 0 && model.eras.count >= 2 {
                Text("OLDEST ↓").font(luFont(10, .heavy)).tracking(1.2).foregroundStyle(Color(hex: Lu.inkDim).opacity(0.8))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing).padding(8)
            }
        }
        .overlay(DigWavy(seed: e).stroke(Color(hex: missed || placed ? Lu.mint : (hover ? Lu.gold : 0x2a1a10)),
                                         lineWidth: missed || placed || hover ? 4 : 1.5))
        .shadow(color: missed || placed ? Color(hex: Lu.mint).opacity(0.7) : .clear, radius: 10)
        .brightness(hover ? 0.08 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { if model.d < 2.5 { model.drop(on: i) } }   // little hands may tap instead of dragging
        .background(GeometryReader { g in
            Color.clear.preference(key: DigLayerFrames.self, value: [i: g.frame(in: .named("dig"))])
        })
        .zIndex(missed || placed ? 1 : 0)
    }
}

/// A soil band with a gently wavy top edge (different per era).
private struct DigWavy: Shape {
    let seed: Int
    func path(in r: CGRect) -> Path {
        Path { p in
            let amp: CGFloat = 5
            p.move(to: CGPoint(x: r.minX, y: r.minY + amp))
            let steps = 8
            for k in 1...steps {
                let x = r.minX + r.width * CGFloat(k) / CGFloat(steps)
                let y = r.minY + amp + amp * CGFloat(sin(Double(k + seed * 3) * 1.3))
                let cx = x - r.width / CGFloat(steps) / 2
                p.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: cx, y: r.minY + amp - amp * CGFloat(cos(Double(k + seed) * 1.7))))
            }
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY + 2))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY + 2))
            p.closeSubpath()
        }
    }
}

/// Little stones scattered through a layer.
private struct DigPebbles: Shape {
    let seed: Int
    func path(in r: CGRect) -> Path {
        Path { p in
            for k in 0..<18 {
                let fx = CGFloat((k * 73 + seed * 31) % 100) / 100
                let fy = CGFloat((k * 41 + seed * 17) % 80) / 100 + 0.15
                let s = CGFloat(3 + (k * 13 + seed) % 6)
                p.addEllipse(in: CGRect(x: r.minX + r.width * fx, y: r.minY + r.height * fy, width: s * 1.4, height: s))
            }
        }
    }
}
