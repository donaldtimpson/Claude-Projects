import SwiftUI

// MARK: - Where's Leo?  (Brain Benders · tracking / memory)
//
// Leo the lion cub loves hide-and-seek. He waves, a gladiator helmet drops over him, and the
// helmets shuffle across the stage. Keep your eyes on Leo's helmet, then tap it. Right — he bursts
// out with a tiny "rawr!". Wrong — that helmet hides something silly (a sock, a banana…), and
// Leo's helmet lifts to show where he really went.
//
// Difficulty is continuous (`d`):
//   • helmets: 2 → 5;  shuffles: 1 → 11;  each shuffle 0.95 s → 0.34 s;
//   • swap kinds fade in by `tier`: neighbours (d 1) → any two helmets, crossing far (d 3.5) →
//     two swaps at once (d 6, needs 4+ helmets);
//   • from d≈5 a decoy cub sometimes peeks out of another helmet mid-shuffle to distract you.

private struct HLHelmet: Identifiable, Equatable {
    let id: Int
    var slot: Int
    var junk: String
}

private let hlJunk = ["🧦", "🍌", "🐸", "🥄", "🧀", "🦆", "🪶", "🍕", "🥾", "🐌", "🧽", "🥕"]

private enum HLStage { case show, cover, shuffle, guess, reveal }

@MainActor
private final class HelmetModel: ArcadeModel {
    @Published var helmets: [HLHelmet] = []
    @Published var leo = 0                 // id of the helmet Leo is under
    @Published var stage = HLStage.show
    @Published var lifted: Set<Int> = []   // helmet ids currently raised
    @Published var hop: [Int: CGFloat] = [:]   // vertical arc while swapping
    @Published var picked: Int?
    @Published var right = false
    @Published var roundID = 0
    @Published var swapDur = 0.9
    @Published var decoy: Int?             // a helmet a fake cub-tail peeks from

    private var gen = 0

    init() { super.init(key: GameID.whereLeo.rawValue) }

    override func perLevel(_ level: Int) -> Int { 5 }
    override func onBegin() { newRound() }

    private func later(_ s: Double, _ f: @escaping () -> Void) {
        let g = gen
        DispatchQueue.main.asyncAfter(deadline: .now() + s) { [weak self] in
            guard let self, self.gen == g, self.phase == .playing else { return }
            f()
        }
    }

    var count: Int { helmets.count }

    func newRound() {
        gen += 1
        let n = rampInt(2, 5, from: 1, to: 7)
        let junk = hlJunk.shuffled()
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) {
            helmets = (0..<n).map { HLHelmet(id: $0, slot: $0, junk: junk[$0]) }
            leo = Int.random(in: 0..<n)
            lifted = Set(helmets.map(\.id))
            hop = [:]; picked = nil; right = false; decoy = nil
            stage = .show
            roundID += 1
        }
        swapDur = ramp(0.95, 0.34, to: 9)
        // Long enough to find Leo and say hi before the helmets drop (young players need it).
        later(ramp(2.1, 1.3, to: 4)) { [unowned self] in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.62)) { lifted = [] }
            stage = .cover
            Sfx.play(.thud)
            Haptics.tap(0.6)
            later(0.7) { [unowned self] in shuffle() }
        }
    }

    /// Plans the swaps for this round: each step is one or two disjoint pairs of slots.
    private func plan() -> [[(Int, Int)]] {
        let n = count
        let k = rampInt(1, 11, to: 9)
        var steps: [[(Int, Int)]] = []
        for _ in 0..<k {
            let kind = tier([1, 3.5, 6])
            func pair(excluding ex: Set<Int> = []) -> (Int, Int)? {
                let free = (0..<n).filter { !ex.contains($0) }
                guard free.count >= 2 else { return nil }
                if kind == 0 || n == 2 {
                    let adj = free.filter { free.contains($0 + 1) }
                    guard let a = adj.randomElement() else { return nil }
                    return (a, a + 1)
                }
                let s = free.shuffled()
                return (s[0], s[1])
            }
            guard let p = pair() else { continue }
            if kind == 2 && n >= 4, let q = pair(excluding: [p.0, p.1]) { steps.append([p, q]) }
            else { steps.append([p]) }
        }
        return steps
    }

    private func shuffle() {
        stage = .shuffle
        let steps = plan()
        let gap = 0.06
        let decoyAt = chance(0.6, from: 5, to: 8) && steps.count >= 3 ? steps.count / 2 : -1
        for (i, step) in steps.enumerated() {
            later(Double(i) * (swapDur + gap)) { [unowned self] in
                doSwap(step)
                if i == decoyAt, let fake = helmets.filter({ $0.id != leo }).randomElement() {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { decoy = fake.id }
                    later(swapDur * 0.9) { [unowned self] in withAnimation(.easeOut(duration: 0.15)) { decoy = nil } }
                }
            }
        }
        later(Double(steps.count) * (swapDur + gap) + 0.15) { [unowned self] in
            stage = .guess
            Haptics.light()
        }
    }

    private func doSwap(_ step: [(Int, Int)]) {
        var arcs: [Int: CGFloat] = [:]
        withAnimation(.easeInOut(duration: swapDur)) {
            for (a, b) in step {
                guard let ia = helmets.firstIndex(where: { $0.slot == a }),
                      let ib = helmets.firstIndex(where: { $0.slot == b }) else { continue }
                helmets[ia].slot = b; helmets[ib].slot = a
                let lift = CGFloat(18 + 10 * abs(a - b))
                arcs[helmets[ia].id] = -lift; arcs[helmets[ib].id] = lift * 0.55
            }
        }
        withAnimation(.easeOut(duration: swapDur / 2)) { hop = arcs }
        later(swapDur / 2) { [unowned self] in withAnimation(.easeIn(duration: swapDur / 2)) { hop = [:] } }
        Sfx.play(.whoosh, volume: 0.35)
    }

    func tap(_ id: Int) {
        guard phase == .playing, stage == .guess else { return }
        stage = .reveal
        picked = id
        right = id == leo
        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { lifted = [id] }
        if right {
            Sfx.play(.pop)
            hit()
            later(1.4) { [unowned self] in newRound() }
        } else {
            Sfx.play(.tick)
            let last = miss(delay: 2.2)
            later(0.8) { [unowned self] in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { _ = lifted.insert(leo) }
                Sfx.play(.sparkle)
            }
            if !last { later(2.4) { [unowned self] in newRound() } }
        }
    }

    override func botAct(correct: Bool) {
        guard stage == .guess else { return }
        if correct { tap(leo) }
        else { tap(helmets.filter { $0.id != leo }.randomElement()?.id ?? leo) }
    }
}

// MARK: - Leo

/// Leo the lion cub, drawn from shapes: a fluffy mane, round face, big eyes, a little body and tail.
private struct HLLeoCub: View {
    let s: CGFloat
    var happy = true
    var wave = false
    var body: some View {
        ZStack {
            // Tail
            Path { p in
                p.move(to: CGPoint(x: s * 0.62, y: s * 0.9))
                p.addCurve(to: CGPoint(x: s * 0.95, y: s * 0.55),
                           control1: CGPoint(x: s * 0.9, y: s * 0.95), control2: CGPoint(x: s * 0.98, y: s * 0.75))
            }
            .stroke(Color(hex: 0xd99a3c), style: StrokeStyle(lineWidth: s * 0.05, lineCap: .round))
            Circle().fill(Color(hex: 0x9c5a1e)).frame(width: s * 0.11).position(x: s * 0.95, y: s * 0.53)
            // Body + paws
            Ellipse().fill(Color(hex: 0xe9b04f)).frame(width: s * 0.46, height: s * 0.36).position(x: s * 0.5, y: s * 0.82)
            Ellipse().fill(Color(hex: 0xf6d9a0)).frame(width: s * 0.24, height: s * 0.22).position(x: s * 0.5, y: s * 0.84)
            Ellipse().fill(Color(hex: 0xe9b04f)).frame(width: s * 0.16, height: s * 0.1).position(x: s * 0.37, y: s * 0.97)
            Ellipse().fill(Color(hex: 0xe9b04f)).frame(width: s * 0.16, height: s * 0.1).position(x: s * 0.63, y: s * 0.97)
            // Waving arm
            Capsule().fill(Color(hex: 0xe9b04f)).frame(width: s * 0.1, height: s * 0.26)
                .rotationEffect(.degrees(wave ? 150 : 120), anchor: .bottom)
                .position(x: s * 0.3, y: s * 0.68)
            // Mane
            ForEach(0..<12, id: \.self) { i in
                let a = Double(i) / 12 * 2 * .pi
                Circle().fill(Color(hex: i % 2 == 0 ? 0xb8641f : 0xc97a2a))
                    .frame(width: s * 0.24)
                    .position(x: s * 0.5 + cos(a) * s * 0.24, y: s * 0.38 + sin(a) * s * 0.24)
            }
            // Ears
            Circle().fill(Color(hex: 0xe9b04f)).frame(width: s * 0.14).position(x: s * 0.33, y: s * 0.2)
            Circle().fill(Color(hex: 0xe9b04f)).frame(width: s * 0.14).position(x: s * 0.67, y: s * 0.2)
            Circle().fill(Color(hex: 0xf3a0a0)).frame(width: s * 0.06).position(x: s * 0.33, y: s * 0.2)
            Circle().fill(Color(hex: 0xf3a0a0)).frame(width: s * 0.06).position(x: s * 0.67, y: s * 0.2)
            // Face
            Circle().fill(Color(hex: 0xf0c060)).frame(width: s * 0.44).position(x: s * 0.5, y: s * 0.4)
            // Eyes
            ForEach([0.41, 0.59], id: \.self) { x in
                ZStack {
                    Ellipse().fill(Color(hex: 0x2a1a10)).frame(width: s * 0.07, height: s * 0.09)
                    Circle().fill(.white).frame(width: s * 0.025).offset(x: s * 0.01, y: -s * 0.018)
                }
                .position(x: s * x, y: s * 0.36)
            }
            // Cheeks
            Circle().fill(Color(hex: 0xf08a6a).opacity(0.5)).frame(width: s * 0.07).position(x: s * 0.35, y: s * 0.45)
            Circle().fill(Color(hex: 0xf08a6a).opacity(0.5)).frame(width: s * 0.07).position(x: s * 0.65, y: s * 0.45)
            // Muzzle, nose, mouth
            Ellipse().fill(Color(hex: 0xfbe6bc)).frame(width: s * 0.2, height: s * 0.13).position(x: s * 0.5, y: s * 0.47)
            Ellipse().fill(Color(hex: 0x6a3a22)).frame(width: s * 0.08, height: s * 0.05).position(x: s * 0.5, y: s * 0.43)
            if happy {
                Ellipse().fill(Color(hex: 0x8a2a2a)).frame(width: s * 0.08, height: s * 0.06).position(x: s * 0.5, y: s * 0.5)
            } else {
                Capsule().fill(Color(hex: 0x6a3a22)).frame(width: s * 0.06, height: s * 0.015).position(x: s * 0.5, y: s * 0.5)
            }
        }
        .frame(width: s, height: s)
    }
}

// MARK: - Helmet

/// A bronze gladiator helmet (galea): dome, brim, cheek guards, eye grille and a red crest.
private struct HLHelmetView: View {
    let s: CGFloat
    var glow = false
    var body: some View {
        ZStack {
            // Crest
            HLCrest().fill(LinearGradient(colors: [Color(hex: 0xe8503a), Color(hex: 0xa52a1e)], startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.7, height: s * 0.3).position(x: s * 0.5, y: s * 0.14)
            ForEach(0..<6, id: \.self) { i in
                Capsule().fill(Color(hex: 0x7a1a12).opacity(0.5)).frame(width: s * 0.02, height: s * 0.14)
                    .position(x: s * (0.24 + 0.1 * CGFloat(i)), y: s * 0.17)
            }
            // Dome
            HLDome().fill(LinearGradient(colors: [Color(hex: 0xf2d38a), Color(hex: 0xc9973e), Color(hex: 0x8a5e22)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: s * 0.86, height: s * 0.74).position(x: s * 0.5, y: s * 0.6)
            // Grille
            RoundedRectangle(cornerRadius: s * 0.06).fill(Color(hex: 0x3a2a1a))
                .frame(width: s * 0.42, height: s * 0.24).position(x: s * 0.5, y: s * 0.66)
            ForEach(0..<4, id: \.self) { i in
                Rectangle().fill(Color(hex: 0xc9973e)).frame(width: s * 0.025, height: s * 0.24)
                    .position(x: s * (0.38 + 0.08 * CGFloat(i)), y: s * 0.66)
            }
            Rectangle().fill(Color(hex: 0xc9973e)).frame(width: s * 0.42, height: s * 0.025).position(x: s * 0.5, y: s * 0.66)
            // Brim
            Capsule().fill(LinearGradient(colors: [Color(hex: 0xe0b860), Color(hex: 0x8a5e22)], startPoint: .top, endPoint: .bottom))
                .frame(width: s * 1.0, height: s * 0.1).position(x: s * 0.5, y: s * 0.95)
            // Shine
            Ellipse().fill(.white.opacity(0.35)).frame(width: s * 0.12, height: s * 0.22)
                .rotationEffect(.degrees(25)).position(x: s * 0.3, y: s * 0.45)
            // Rivets
            ForEach(0..<5, id: \.self) { i in
                Circle().fill(Color(hex: 0xfbe3a0)).frame(width: s * 0.04)
                    .position(x: s * (0.2 + 0.15 * CGFloat(i)), y: s * 0.86)
            }
        }
        .frame(width: s, height: s)
        .shadow(color: glow ? Color(hex: Lu.gold) : .clear, radius: glow ? 12 : 0)
    }
}

private struct HLDome: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY), control1: CGPoint(x: r.minX, y: r.minY + r.height * 0.3),
                   control2: CGPoint(x: r.minX + r.width * 0.2, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.maxY), control1: CGPoint(x: r.maxX - r.width * 0.2, y: r.minY),
                   control2: CGPoint(x: r.maxX, y: r.minY + r.height * 0.3))
        p.closeSubpath()
        return p
    }
}

private struct HLCrest: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.6))
        p.closeSubpath()
        return p
    }
}

// MARK: - Scene

/// Backstage at the Colosseum: a striped awning, warm lamplight, and a wooden stage.
private struct HLBackdrop: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .top) {
                LinearGradient(colors: [Color(hex: 0x3a1a2a), Color(hex: 0x5a2a2a), Color(hex: 0x2a1418)],
                               startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [Color(hex: 0xffc070).opacity(0.35), .clear],
                               center: UnitPoint(x: 0.5, y: 0.55), startRadius: 10, endRadius: w * 0.9)
                // Stone arches at the back
                HStack(spacing: w * 0.06) {
                    ForEach(0..<4, id: \.self) { _ in
                        HLArchShape().fill(Color(hex: 0x1a0c12).opacity(0.55))
                            .frame(width: w * 0.18, height: h * 0.26)
                    }
                }
                .position(x: w / 2, y: h * 0.33)
                // Awning: red/cream scallops
                HStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { i in
                        HLScallop().fill(Color(hex: i % 2 == 0 ? 0xc0392b : 0xf3e3c3))
                            .frame(width: w / 9, height: h * 0.12)
                    }
                }
                .shadow(color: .black.opacity(0.35), radius: 6, y: 4)
                // Stage floor
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle().fill(Color(hex: 0x6a3e22)).frame(height: 10)
                    LinearGradient(colors: [Color(hex: 0xa8703e), Color(hex: 0x7a4a26)], startPoint: .top, endPoint: .bottom)
                        .overlay(
                            HStack(spacing: w / 7) {
                                ForEach(0..<7, id: \.self) { _ in Rectangle().fill(.black.opacity(0.12)).frame(width: 2) }
                            }
                        )
                        .frame(height: h * 0.42)
                }
            }
        }
    }
}

private struct HLScallop: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY * 0.7))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY * 0.7), control: CGPoint(x: r.midX, y: r.maxY * 1.25))
        p.closeSubpath()
        return p
    }
}

private struct HLArchShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.width / 2))
        p.addArc(center: CGPoint(x: r.midX, y: r.minY + r.width / 2), radius: r.width / 2,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - View

struct WhereLeoView: View {
    let onClose: () -> Void
    @StateObject private var model = HelmetModel()
    @State private var wave = false

    var body: some View {
        ArcadeShell(model: model,
                    spec: GameID.whereLeo.spec ?? GameSpec(title: "Where's Leo?", mechanic: "", premise: "", game: .whereLeo),
                    accent: Lu.tangerine, onClose: onClose,
                    backdrop: { HLBackdrop() }) {
            GeometryReader { geo in stage(geo.size) }
        }
        .onAppear { withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) { wave = true } }
    }

    private func stage(_ size: CGSize) -> some View {
        let n = max(1, model.count)
        let w = size.width - 16
        let slotW = w / CGFloat(n)
        let hs = min(118, slotW * 0.92)
        let floorY = size.height * 0.66
        return ZStack {
            caption.position(x: size.width / 2, y: size.height * 0.24)
            ForEach(model.helmets) { h in
                let x = 8 + slotW * (CGFloat(h.slot) + 0.5)
                let up = model.lifted.contains(h.id)
                let isLeo = h.id == model.leo
                ZStack {
                    // What's underneath
                    Group {
                        if isLeo {
                            HLLeoCub(s: hs * 0.9, happy: true,
                                   wave: model.stage == .show && wave)
                                .scaleEffect(model.stage == .reveal && model.right ? 1.15 : 1, anchor: .bottom)
                        } else {
                            Text(h.junk).font(.system(size: hs * 0.5))
                        }
                    }
                    .offset(y: -hs * 0.02)
                    .opacity(up ? 1 : 0)
                    // Decoy tail peeking out
                    if model.decoy == h.id {
                        Text("🐾").font(.system(size: hs * 0.28)).offset(x: hs * 0.42, y: hs * 0.38)
                            .transition(.scale.combined(with: .opacity))
                    }
                    HLHelmetView(s: hs, glow: model.stage == .reveal && isLeo && !model.right && up)
                        .offset(y: up ? -hs * 1.2 : 0)
                        .rotationEffect(.degrees(up ? -8 : 0))
                }
                .frame(width: hs, height: hs)
                .background(alignment: .bottom) {
                    Ellipse().fill(.black.opacity(0.3)).frame(width: hs * 0.9, height: hs * 0.14).offset(y: hs * 0.05)
                }
                .position(x: x, y: floorY - hs / 2 + (model.hop[h.id] ?? 0))
                .zIndex((model.hop[h.id] ?? 0) < 0 ? 2 : 1)
                .contentShape(Rectangle())
                .onTapGesture { model.tap(h.id) }
            }
            if model.stage == .reveal, let p = model.picked, let h = model.helmets.first(where: { $0.id == p }) {
                Text(model.right ? "rawr! 🎉" : "Not Leo — \(h.junk)!")
                    .font(luFont(20, .heavy)).foregroundStyle(Color(hex: model.right ? Lu.gold : Lu.ink))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(Color.black.opacity(0.4)))
                    .fixedSize()
                    // Below the row, on the open floor: above it, the lifted helmet would cover it.
                    .position(x: min(max(8 + slotW * (CGFloat(h.slot) + 0.5), 90), size.width - 90), y: floorY + 46)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .id(model.roundID)
        .frame(width: size.width, height: size.height)
    }

    private var caption: some View {
        let text: String
        switch model.stage {
        case .show: text = "Say hi to Leo! 👋"
        case .cover, .shuffle: text = "Keep your eyes on Leo… 👀"
        case .guess: text = "Where's Leo? Tap his helmet!"
        case .reveal: text = model.right ? "You found him!" : "Leo was here!"
        }
        return Text(text)
            .font(luSerif(24, .black)).foregroundStyle(Color(hex: Lu.ink))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18).padding(.vertical, 10)
            .background(Capsule().fill(Color.black.opacity(0.35)))
            .shadow(color: .black.opacity(0.5), radius: 4)
    }
}
