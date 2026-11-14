import SwiftUI

// MARK: - Archimedes' Seesaw (Vesuvius · Science — forces & levers)
//
// A long oak beam balances on a stone pivot in a sunny garden below Vesuvius. Bronze weights sit on
// one side; drag the weight from the bench onto a peg so the beam BALANCES. Let go and the prop
// drops: balanced, it bobs and settles level (sparkles); wrong, it slams down on the heavy side —
// then the right weight slides onto the right peg and the beam rises level, so every miss shows
// the answer. The lever law, felt with a finger: weight × distance on one side = weight × distance
// on the other (2 blocks on peg 3 balance 3 blocks on peg 2).
//
// Continuous difficulty (all off `d`):
//   • pegs per side 3 → 6;  heaviest weight 1 block → 5 blocks (at d≈1 every weight is one block,
//     so the answer is the MIRROR peg — pure "same on both sides").
//   • while a weight hovers over a peg the beam LEANS the way it would go — a full-strength hint at
//     d≈1 that fades to nothing by d≈4 (the 12-year-old has to work it out).
//   • content kinds fade in by `tier`: one weight on the far side → two weights on one side →
//     weights on BOTH sides (the answer may then be on the left).
//   • the bench offers 1 weight at first, then 2, 3, 4 to choose from (only one can balance).
//   • peg numbers fade in from d≈2.5 (counting pegs works before then).
// No clock at any level.

// MARK: Rounds

private struct SSWeight: Identifiable, Equatable {
    let id: Int
    let w: Int          // blocks
    var peg: Int = 0    // signed peg: −n … −1 left, 1 … n right (0 = on the bench)
}

private struct SSRound {
    var pegs = 3
    var fixed: [SSWeight] = []
    var bench: [SSWeight] = []
    var answerID = 0
    var answerPeg = 1
    var torque: Int { fixed.reduce(0) { $0 + $1.w * $1.peg } }
}

/// Builds a round with exactly one (bench weight, free peg) that balances the beam.
private func ssRound(pegs n: Int, maxW: Int, kind: Int, benchCount: Int, base: Int) -> SSRound {
    for _ in 0..<400 {
        let wa = Int.random(in: 1...maxW), pa = Int.random(in: 1...n)
        let need = wa * pa                     // torque the answer adds on the right
        var fixed: [SSWeight] = []
        var id = base
        func put(_ w: Int, _ p: Int) { fixed.append(SSWeight(id: id, w: w, peg: p)); id += 1 }
        // Ways to write t as w × p with w ≤ maxW, p ≤ n.
        func splits(_ t: Int) -> [(Int, Int)] {
            (1...maxW).compactMap { w in t % w == 0 && t / w >= 1 && t / w <= n ? (w, t / w) : nil }
        }
        switch kind {
        case 0:
            // One weight on the left. Prefer a different shape from the answer when there is one.
            let s = splits(need)
            let other = s.filter { $0.0 != wa }
            guard let (w, p) = (other.isEmpty || Bool.random() && maxW <= 2 ? s : other).randomElement() else { continue }
            put(w, -p)
        case 1:
            // Two weights on the left, on different pegs.
            guard need >= 2 else { continue }
            let t1 = Int.random(in: 1..<need)
            guard let a = splits(t1).randomElement(), let b = splits(need - t1).filter({ $0.1 != a.1 }).randomElement() else { continue }
            put(a.0, -a.1); put(b.0, -b.1)
        default:
            // Weights on both sides: one on the right (not on the answer peg), the rest on the left.
            let rw = Int.random(in: 1...maxW)
            let rpChoices = (1...n).filter { $0 != pa }
            guard let rp = rpChoices.randomElement() else { continue }
            let left = need + rw * rp
            let s = splits(left)
            if let (w, p) = s.randomElement() { put(w, -p) }
            else {
                // Two on the left.
                let t1 = Int.random(in: 1..<left)
                guard let a = splits(t1).randomElement(), let b = splits(left - t1).filter({ $0.1 != a.1 }).randomElement() else { continue }
                put(a.0, -a.1); put(b.0, -b.1)
            }
            put(rw, rp)
        }
        var r = SSRound(pegs: n, fixed: fixed)
        // Mirror half the "both sides" rounds so the answer sits on the LEFT.
        let flip = kind == 2 && Bool.random()
        if flip { r.fixed = r.fixed.map { var x = $0; x.peg = -x.peg; return x } }
        let answerPeg = flip ? -pa : pa
        // The bench: the answer + weights that can't balance on ANY free peg.
        let occupied = Set(r.fixed.map(\.peg))
        func works(_ w: Int) -> [Int] {
            (-n...n).filter { $0 != 0 && !occupied.contains($0) && r.torque + w * $0 == 0 }
        }
        guard works(wa) == [answerPeg] else { continue }
        var bench = [SSWeight(id: id, w: wa)]
        let answerID = id; id += 1
        for w in (1...max(maxW, 5)).shuffled() where bench.count < benchCount && w != wa && works(w).isEmpty {
            bench.append(SSWeight(id: id, w: w)); id += 1
        }
        r.bench = bench.shuffled()
        r.answerID = answerID
        r.answerPeg = answerPeg
        return r
    }
    // Fallback (never expected): the mirror round.
    return SSRound(pegs: n, fixed: [SSWeight(id: base, w: 1, peg: -2)], bench: [SSWeight(id: base + 1, w: 1)],
                   answerID: base + 1, answerPeg: 2)
}

#if DEBUG
private func ssSelfCheck() -> String? {
    for n in 3...6 {
        for maxW in 1...5 {
            for kind in 0...2 {
                for bc in 1...4 {
                    for i in 0..<60 {
                        let r = ssRound(pegs: n, maxW: maxW, kind: kind, benchCount: bc, base: i * 10)
                        let occupied = Set(r.fixed.map(\.peg))
                        if occupied.count != r.fixed.count { return "stacked pegs" }
                        var ways = 0
                        for b in r.bench {
                            for p in -n...n where p != 0 && !occupied.contains(p) && r.torque + b.w * p == 0 {
                                ways += 1
                                if b.id != r.answerID || p != r.answerPeg { return "second answer \(b.w)@\(p)" }
                            }
                        }
                        if ways != 1 { return "n\(n) w\(maxW) k\(kind): \(ways) answers" }
                        if r.torque == 0 { return "already balanced" }
                        if r.fixed.contains(where: { abs($0.peg) > n || $0.w > max(maxW, 5) }) { return "out of range" }
                    }
                }
            }
        }
    }
    return nil
}
#endif

// MARK: Model

@MainActor
private final class SeesawModel: ArcadeModel {
    enum Stage { case waiting, balanced, slam, fix }
    @Published var round = SSRound()
    @Published var placed: SSWeight?        // the bench weight the child put on the beam
    @Published var stage: Stage = .waiting
    @Published var hover: (id: Int, peg: Int)?   // a weight held over a peg (drives the lean hint)
    @Published var selected: Int?           // tap-to-select on the bench
    @Published var roundID = 0
    @Published var cheers = 0
    @Published var thuds = 0
    private let clock = VesRunClock()
    #if DEBUG
    private static let checked: Bool = {
        if let bad = ssSelfCheck() { assertionFailure("Seesaw self-check: \(bad)") }
        return true
    }()
    #endif

    init() {
        super.init(key: GameID.seesaw.rawValue)
        #if DEBUG
        _ = SeesawModel.checked
        #endif
    }

    override func perLevel(_ level: Int) -> Int { 5 }

    /// How strongly the beam leans while a weight hovers (1 at the start → 0 by d≈4).
    var hint: Double { ramp(1, 0, from: 2, to: 4) }
    var showNumbers: Double { ramp(0, 1, from: 2.2, to: 3.2) }

    override func onBegin() {
        clock.reset()
        newRound()
    }

    private func newRound() {
        roundID += 1
        let n = rampInt(3, 6, to: 7)
        let maxW = rampInt(1, 5, from: 1.3, to: 6.5)
        let kind = maxW == 1 ? 0 : tier([1, 3.5, 6])
        let bench = rampInt(1, 4, from: 1.8, to: 8)
        round = ssRound(pegs: n, maxW: maxW, kind: kind, benchCount: bench, base: roundID * 100)
        placed = nil; hover = nil; stage = .waiting
        selected = round.bench.count == 1 ? round.bench[0].id : nil
    }

    /// Net turning effect (positive = right side down).
    var torque: Int {
        var t = round.torque
        if let p = placed { t += p.w * p.peg }
        return t
    }

    /// The beam angle (degrees) the scene should show right now.
    var angle: Double {
        func tilt(_ t: Int) -> Double { max(-14, min(14, Double(t) * 2.2 + (t == 0 ? 0 : (t > 0 ? 5 : -5)))) }
        switch stage {
        case .waiting:
            guard let h = hover, let w = round.bench.first(where: { $0.id == h.id }) else { return 0 }
            return tilt(round.torque + w.w * h.peg) * hint * 0.6
        case .balanced: return 0
        case .slam: return tilt(torque)
        case .fix: return 0
        }
    }

    func isFree(_ peg: Int) -> Bool {
        peg != 0 && abs(peg) <= round.pegs && !round.fixed.contains { $0.peg == peg }
    }

    /// Put bench weight `id` on `peg` (a drag's drop, a tap on a peg, and the bot all land here).
    func place(_ id: Int, on peg: Int) {
        guard phase == .playing, stage == .waiting, isFree(peg),
              var w = round.bench.first(where: { $0.id == id }) else { return }
        hover = nil
        w.peg = peg
        Sfx.play(.thud)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { placed = w }
        if torque == 0 {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.35)) { stage = .balanced }
            cheers += 1
            Sfx.play(.sparkle)
            hit()
            clock.after(1.6) { self.next() }
        } else {
            clock.after(0.25) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) { self.stage = .slam }
                self.thuds += 1
                Sfx.play(.thud)
                Haptics.tap(1)
            }
            let last = miss(delay: 3.0)
            clock.after(1.4) {
                // The right weight slides onto the right peg and the beam rises level.
                guard let right = self.round.bench.first(where: { $0.id == self.round.answerID }) else { return }
                var r = right; r.peg = self.round.answerPeg
                Sfx.play(.whoosh)
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    self.placed = r
                    self.stage = .fix
                }
            }
            if !last { clock.after(3.2) { self.next() } }
        }
    }

    private func next() {
        guard phase == .playing else { return }
        withAnimation(.easeInOut(duration: 0.4)) { newRound() }
    }

    override func botAct(correct: Bool) {
        guard stage == .waiting else { return }
        if correct { place(round.answerID, on: round.answerPeg); return }
        // A wrong move: the answer weight on a wrong free peg (or a wrong weight).
        let wrongPegs = (-round.pegs...round.pegs).filter { isFree($0) && $0 != round.answerPeg }
        if let p = wrongPegs.randomElement() { place(round.answerID, on: p) }
    }
}

// MARK: Views

struct SeesawView: View {
    let onClose: () -> Void
    @StateObject private var model = SeesawModel()

    var body: some View {
        ArcadeShell(model: model,
                    spec: GameID.seesaw.spec ?? GameSpec(title: "Archimedes' Seesaw", mechanic: "", premise: "", game: .seesaw),
                    accent: Lu.tangerine, onClose: onClose,
                    backdrop: { SeesawGarden() }) {
            SeesawPlay(model: model)
        }
    }
}

private let ssSpace = "seesaw"

private struct SeesawPlay: View {
    @ObservedObject var model: SeesawModel
    @State private var drag: (id: Int, at: CGPoint)?

    var body: some View {
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            let beamW = min(W - 24, 560)
            let n = model.round.pegs
            let gap = beamW / 2 / (CGFloat(n) + 0.55)
            let pivot = CGPoint(x: W / 2, y: H * 0.6)
            let blockW = min(54, gap * 0.9)
            ZStack {
                // Prompt
                VStack(spacing: 2) {
                    Text(prompt).font(luSerif(22, .black)).foregroundStyle(Color(hex: 0x3b2410))
                        .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 18).padding(.vertical, 8)
                .background(Capsule().fill(Color(hex: 0xf7ecd0).opacity(0.92))
                    .overlay(Capsule().stroke(Color(hex: 0xb08a4a), lineWidth: 2)))
                .position(x: W / 2, y: 92)
                .animation(.easeInOut(duration: 0.2), value: model.stage)

                // Pivot (stone wedge) — drawn under the beam.
                PivotStone().fill(LinearGradient(colors: [Color(hex: 0xb9b2a4), Color(hex: 0x7d766a)], startPoint: .top, endPoint: .bottom))
                    .overlay(PivotStone().stroke(Color(hex: 0x5c564c), lineWidth: 2))
                    .frame(width: 92, height: 96)
                    .position(x: pivot.x, y: pivot.y + 50)

                // The beam + everything on it, rotating about the pivot.
                beam(width: beamW, gap: gap, blockW: blockW)
                    .frame(width: beamW, height: 260)
                    .rotationEffect(.degrees(model.angle), anchor: UnitPoint(x: 0.5, y: 230.0 / 260.0))
                    .position(x: pivot.x, y: pivot.y - 230 + 130)
                    .animation(model.stage == .waiting ? .spring(response: 0.5, dampingFraction: 0.55) : nil, value: model.angle)
                    .modifier(VesShake(amount: 3, shakes: 4, beats: CGFloat(model.thuds)))
                    .animation(.linear(duration: 0.35), value: model.thuds)

                VesBurst(trigger: model.cheers, emojis: ["✨", "⭐️", "⚖️", "💛"], radius: 140, size: 30)
                    .position(x: pivot.x, y: pivot.y - 40)

                // Minerva's owl stands on the terrace and watches the beam.
                SeesawOwl(mood: model.stage == .balanced ? .cheer : (model.stage == .slam || model.stage == .fix ? .shock : .watch),
                          lean: model.angle)
                    .frame(width: 64, height: 70)
                    .position(x: W - 44, y: pivot.y + 84)

                // Bench of weights
                bench(width: W, y: H - 110, blockW: min(56, max(44, blockW * 1.1)), pivot: pivot, gap: gap)
                // The weight in the hand (it hangs just above the finger so it isn't hidden).
                if let d = drag, let w = model.round.bench.first(where: { $0.id == d.id }) {
                    WeightStack(w: w.w, blockW: blockW, tint: Lu.tangerine, glow: true)
                        .position(x: d.at.x, y: d.at.y - stackH(w.w, blockW) / 2 - 24)
                        .allowsHitTesting(false)
                }
            }
            .coordinateSpace(name: ssSpace)
            .onChange(of: drag?.at) { _ in
                guard let d = drag else { model.hover = nil; return }
                let p = pegAt(d.at, pivot: pivot, gap: gap)
                if let p, model.isFree(p) { if model.hover?.peg != p || model.hover?.id != d.id { model.hover = (d.id, p); Sfx.play(.tick, volume: 0.4) } }
                else if model.hover != nil { model.hover = nil }
            }
        }
    }

    private var prompt: String {
        switch model.stage {
        case .waiting: return model.d < 2.5 ? "Make it balance!" : "Which weight, which peg?"
        case .balanced: return ["Balanced! ⚖️", "Perfect balance!", "Aequilibrium!"][model.roundID % 3]
        case .slam: return "Bump! It tipped over"
        case .fix: return explain
        }
    }

    /// After a miss: why the right peg balances (weight × distance on each side).
    private var explain: String {
        let r = model.round
        let a = r.bench.first { $0.id == r.answerID }?.w ?? 1
        if r.fixed.count == 1, r.fixed[0].w == a { return "Same weight, same distance!" }
        let s = r.answerPeg > 0 ? 1 : -1
        let each = r.fixed.filter { $0.peg * s > 0 }.reduce(a * abs(r.answerPeg)) { $0 + $1.w * abs($1.peg) }
        return "\(a) on peg \(abs(r.answerPeg)): weight × distance = \(each) on each side"
    }

    /// Where the garden's right-hand column ends (the backdrop is laid out full-screen, the play
    /// area inside the safe area).
    private func columnTop(_ g: GeometryProxy) -> CGFloat {
        let top = g.frame(in: .global).minY
        let fullH = g.size.height + top + g.safeAreaInsets.bottom
        return fullH * 0.42 - fullH * 0.25 - top
    }

    /// The signed peg nearest to a point (nil if far from the beam).
    private func pegAt(_ p: CGPoint, pivot: CGPoint, gap: CGFloat) -> Int? {
        guard p.y > pivot.y - 230, p.y < pivot.y + 60 else { return nil }
        let x = (p.x - pivot.x) / gap
        let k = Int(x.rounded())
        guard k != 0, abs(k) <= model.round.pegs else { return nil }
        return k
    }

    @ViewBuilder
    private func beam(width: CGFloat, gap: CGFloat, blockW: CGFloat) -> some View {
        let n = model.round.pegs
        let beamY: CGFloat = 230
        ZStack {
            // Oak plank
            RoundedRectangle(cornerRadius: 7)
                .fill(LinearGradient(colors: [Color(hex: 0xc58b4e), Color(hex: 0x8a5528)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: 0x5a3416), lineWidth: 2))
                .overlay(HStack(spacing: 40) { ForEach(0..<8, id: \.self) { _ in Capsule().fill(Color(hex: 0x7a4820).opacity(0.35)).frame(width: 26, height: 2) } })
                .frame(width: width, height: 18)
                .position(x: width / 2, y: beamY)
            // Bronze pivot pin
            Circle().fill(Color(hex: Lu.gold)).overlay(Circle().stroke(Color(hex: 0x7a5a16), lineWidth: 2))
                .frame(width: 16, height: 16).position(x: width / 2, y: beamY)
            // Pegs
            ForEach(Array((-n...n).filter { $0 != 0 }), id: \.self) { p in
                let x = width / 2 + CGFloat(p) * gap
                let hovering = model.hover?.peg == p
                let showFix = model.stage == .fix && p == model.round.answerPeg
                ZStack {
                    Capsule().fill(Color(hex: hovering || showFix ? Lu.gold : 0x4a2c12))
                        .frame(width: hovering ? 12 : 8, height: 14)
                    Text("\(abs(p))").font(luFont(12, .heavy)).foregroundStyle(Color(hex: 0xfff4dc))
                        .offset(y: 22).opacity(model.showNumbers)
                }
                .position(x: x, y: beamY - 12)
                .onTapGesture { if let s = model.selected { model.place(s, on: p) } }
            }
            // Weights on the beam
            ForEach(model.round.fixed) { w in
                WeightStack(w: w.w, blockW: blockW, tint: 0x8d6f53)
                    .position(x: width / 2 + CGFloat(w.peg) * gap, y: beamY - 9 - stackH(w.w, blockW) / 2)
            }
            if let w = model.placed {
                WeightStack(w: w.w, blockW: blockW, tint: Lu.tangerine, glow: model.stage == .fix || model.stage == .balanced)
                    .position(x: width / 2 + CGFloat(w.peg) * gap, y: beamY - 9 - stackH(w.w, blockW) / 2)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func stackH(_ w: Int, _ bw: CGFloat) -> CGFloat { CGFloat(w) * bw * 0.5 + 7 }

    private func bench(width: CGFloat, y: CGFloat, blockW: CGFloat, pivot: CGPoint, gap: CGFloat) -> some View {
        let items = model.round.bench
        return ZStack {
            // Stone bench
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [Color(hex: 0xe6dccb), Color(hex: 0xb9ad97)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0x8a7e69), lineWidth: 2))
                .frame(width: width - 28, height: 40)
                .position(x: width / 2, y: y + 48)
            HStack(spacing: 18) {
                ForEach(items) { w in
                    let used = model.placed?.id == w.id
                    let isDragging = drag?.id == w.id
                    WeightStack(w: w.w, blockW: blockW, tint: Lu.tangerine, glow: model.selected == w.id && items.count > 1)
                        .frame(minWidth: 64, minHeight: 92, alignment: .bottom)
                        .contentShape(Rectangle())
                        .opacity(used || isDragging ? 0 : 1)
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .named(ssSpace))
                                .onChanged { v in
                                    guard model.stage == .waiting else { return }
                                    if hypot(v.translation.width, v.translation.height) > 6 {
                                        drag = (w.id, v.location)
                                    }
                                }
                                .onEnded { v in
                                    defer { withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { drag = nil }; model.hover = nil }
                                    guard model.stage == .waiting else { return }
                                    if hypot(v.translation.width, v.translation.height) < 8 {
                                        model.selected = w.id; Sfx.play(.tick)
                                        return
                                    }
                                    if let p = pegAt(v.location, pivot: pivot, gap: gap), model.isFree(p) {
                                        model.place(w.id, on: p)
                                    }
                                }
                        )
                }
            }
            .position(x: width / 2, y: y)
        }
    }
}

/// A little drawn owl: watches (tilting its head with the beam), cheers (wings up), or gasps.
private struct SeesawOwl: View {
    enum Mood { case watch, cheer, shock }
    let mood: Mood
    let lean: Double
    var body: some View {
        let brown = Color(hex: 0x8a5a34), light = Color(hex: 0xe9cfa4)
        ZStack {
            // wings
            Ellipse().fill(Color(hex: 0x6e4424)).frame(width: 20, height: 34)
                .rotationEffect(.degrees(mood == .cheer ? 60 : 10), anchor: .top).position(x: 12, y: 40)
            Ellipse().fill(Color(hex: 0x6e4424)).frame(width: 20, height: 34)
                .rotationEffect(.degrees(mood == .cheer ? -60 : -10), anchor: .top).position(x: 52, y: 40)
            // body
            Ellipse().fill(brown).frame(width: 46, height: 52).position(x: 32, y: 42)
            Ellipse().fill(light).frame(width: 28, height: 32).position(x: 32, y: 48)
            // head
            ZStack {
                Ellipse().fill(brown).frame(width: 48, height: 36)
                // ear tufts
                Triangle().fill(brown).frame(width: 12, height: 12).offset(x: -16, y: -18)
                Triangle().fill(brown).frame(width: 12, height: 12).offset(x: 16, y: -18)
                ForEach([-11.0, 11.0], id: \.self) { x in
                    ZStack {
                        Circle().fill(.white).frame(width: mood == .shock ? 19 : 16)
                        if mood == .cheer {
                            Capsule().fill(Color(hex: 0x2a1a10)).frame(width: 10, height: 3).offset(y: 1)
                        } else {
                            Circle().fill(Color(hex: 0x2a1a10)).frame(width: mood == .shock ? 6 : 8)
                        }
                    }
                    .offset(x: x, y: -1)
                }
                Triangle().fill(Color(hex: 0xf0a030)).frame(width: 8, height: 7).rotationEffect(.degrees(180)).offset(y: 10)
            }
            .rotationEffect(.degrees(lean * 1.5))
            .position(x: 32, y: 18)
            // feet
            HStack(spacing: 8) { Capsule().fill(Color(hex: 0xf0a030)).frame(width: 8, height: 5); Capsule().fill(Color(hex: 0xf0a030)).frame(width: 8, height: 5) }
                .position(x: 32, y: 68)
        }
        .frame(width: 64, height: 70)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: mood)
    }
}

private struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.closeSubpath()
        }
    }
}

/// A stack of bronze blocks (one per unit of weight), with its number on the top block.
private struct WeightStack: View {
    let w: Int
    let blockW: CGFloat
    var tint: UInt = Lu.tangerine
    var glow = false
    var body: some View {
        let h = blockW * 0.5
        VStack(spacing: 0) {
            // little lifting ring
            Circle().stroke(Color(hex: 0x5a3a1a), lineWidth: 2.5).frame(width: 10, height: 10).padding(.bottom, -3)
            ForEach(0..<w, id: \.self) { i in
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [luShade(tint, 40), Color(hex: tint), luShade(tint, -50)], startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(luShade(tint, -90), lineWidth: 1.5))
                    if i == 0 {
                        Text("\(w)").font(luFont(min(15, h * 0.85), .black)).foregroundStyle(Color(hex: 0x2a1606))
                    }
                }
                .frame(width: blockW, height: h)
            }
        }
        .shadow(color: glow ? Color(hex: Lu.gold).opacity(0.9) : .black.opacity(0.25), radius: glow ? 10 : 2, y: glow ? 0 : 2)
    }
}

private struct PivotStone: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.midX - 8, y: r.minY))
            p.addLine(to: CGPoint(x: r.midX + 8, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            p.closeSubpath()
        }
    }
}

/// The garden: a warm sky, Vesuvius smoking on the horizon, a colonnade and a mosaic terrace.
private struct SeesawGarden: View {
    var body: some View {
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0x7cc3ea), Color(hex: 0xcfe9f2), Color(hex: 0xf6e3bf)], startPoint: .top, endPoint: .bottom)
                Circle().fill(Color(hex: 0xfff2b0)).frame(width: 70, height: 70).blur(radius: 1)
                    .shadow(color: Color(hex: 0xffe680), radius: 30).position(x: W * 0.82, y: H * 0.12)
                VesMountain(smoke: true)
                    .frame(width: W * 0.9, height: H * 0.24)
                    .position(x: W * 0.36, y: H * 0.36)
                // distant cypress trees
                ForEach(0..<5, id: \.self) { i in
                    Capsule().fill(Color(hex: 0x3e6b3a)).frame(width: 14, height: 54 + CGFloat(i % 2) * 14)
                        .position(x: W * (0.58 + CGFloat(i) * 0.09), y: H * 0.44 - CGFloat(i % 2) * 7)
                }
                // garden lawn + terrace
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0x8fbf6a), Color(hex: 0x6a9a4c)], startPoint: .top, endPoint: .bottom))
                    .frame(height: H * 0.18).position(x: W / 2, y: H * 0.56)
                Rectangle().fill(Color(hex: 0xe9dcc2)).frame(height: H * 0.38).position(x: W / 2, y: H * 0.84)
                // terrace flagstones in perspective
                Path { p in
                    let top = H * 0.66
                    for i in 0...10 { let x = W * CGFloat(i) / 10; p.move(to: CGPoint(x: x, y: top)); p.addLine(to: CGPoint(x: W / 2 + (x - W / 2) * 1.8, y: H)) }
                    var y = top; var step: CGFloat = 16
                    while y < H { p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: W, y: y)); y += step; step *= 1.35 }
                }
                .stroke(Color(hex: 0xc9b896), lineWidth: 1.5)
                VesMosaicBand().frame(height: 14).position(x: W / 2, y: H * 0.66)
                // colonnade at the sides
                ForEach([0.05, 0.95], id: \.self) { fx in
                    VesColumn().frame(width: 34, height: H * 0.5).position(x: W * fx, y: H * 0.42)
                }
            }
        }
    }
}
