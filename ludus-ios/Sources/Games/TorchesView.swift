import SwiftUI

// MARK: - Torches of the Arena  (Brain Benders · lights-out)
//
// Tapping a torch flips it AND its neighbours (left/right/up/down): lit ↔ dark. Light them all.
// Pressing a torch outlines the ones it will flip, so cause and effect is visible before the
// finger lifts. Each board has a tap allowance (the fewest taps + some spare); run out and the
// game shows the answer by tapping it out itself. Solving in the fewest taps scores a PERFECT.
// Boards are made by tapping a lit board at random, so every board is solvable; a GF(2) solver
// gives the fewest taps (the par, the hint glow, the reveal and the autoplayer).
//
// Difficulty is continuous (`d`, 3 boards a level):
//   • the arena grows: a row of 3 → a row of 4 → 2 × 3 → 3 × 3 → 3 × 4 → 4 × 4 → odd-shaped arenas
//     (ring, oval, cross) from d≈7 → 5 × 5 and holed arenas from d≈8.5 (a smaller board now and
//     then stays as review);
//   • the scramble deepens: 1 tap at d 1 → 5–8 taps by d≈10;
//   • spare taps shrink 4 → 2 (d 3 → 7) and the hint glow waits longer (3 s → 14 s by d 8).
// The FEWEST number shows from Gradus III (before that, only the tap dots).

// MARK: Board + solver

private struct TBoard {
    let rows: Int, cols: Int
    let cells: [(r: Int, c: Int)]     // present cells; index = bit position
    let masks: [UInt64]               // the cells a tap on cell i flips
    var full: UInt64 { cells.count == 64 ? ~0 : (UInt64(1) << UInt64(cells.count)) - 1 }

    init(_ shape: [String]) {
        rows = shape.count
        cols = shape.map(\.count).max() ?? 0
        var cs: [(r: Int, c: Int)] = []
        for (r, line) in shape.enumerated() {
            for (c, ch) in line.enumerated() where ch == "#" { cs.append((r, c)) }
        }
        cells = cs
        var index: [Int: Int] = [:]
        for (i, p) in cs.enumerated() { index[p.r * 100 + p.c] = i }
        masks = cs.map { p in
            var m: UInt64 = 0
            for (dr, dc) in [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)] {
                if let j = index[(p.r + dr) * 100 + (p.c + dc)] { m |= UInt64(1) << UInt64(j) }
            }
            return m
        }
    }

    func index(r: Int, c: Int) -> Int? { cells.firstIndex { $0.r == r && $0.c == c } }
}

/// The fewest taps that flip exactly `target` (bit set = must change), or nil if impossible.
/// Gauss–Jordan over GF(2), then the smallest choice over the free variables.
private func tSolve(_ masks: [UInt64], _ target: UInt64) -> UInt64? {
    let n = masks.count
    var rows: [(UInt64, Bool)] = (0..<n).map { i in
        var r: UInt64 = 0
        for j in 0..<n where (masks[j] >> UInt64(i)) & 1 == 1 { r |= UInt64(1) << UInt64(j) }
        return (r, (target >> UInt64(i)) & 1 == 1)
    }
    var pivots: [Int] = []
    var top = 0
    for c in 0..<n {
        guard let p = (top..<n).first(where: { (rows[$0].0 >> UInt64(c)) & 1 == 1 }) else { continue }
        rows.swapAt(top, p)
        for k in 0..<n where k != top && (rows[k].0 >> UInt64(c)) & 1 == 1 {
            rows[k].0 ^= rows[top].0
            rows[k].1 = rows[k].1 != rows[top].1
        }
        pivots.append(c)
        top += 1
    }
    for k in top..<n where rows[k].1 { return nil }
    let pivotSet = Set(pivots)
    let free = (0..<n).filter { !pivotSet.contains($0) }
    guard free.count <= 16 else { return nil }
    var best: UInt64?
    for combo in 0..<(1 << free.count) {
        var x: UInt64 = 0
        for (b, f) in free.enumerated() where (combo >> b) & 1 == 1 { x |= UInt64(1) << UInt64(f) }
        for (ri, c) in pivots.enumerated() {
            let parity = (rows[ri].0 & x).nonzeroBitCount & 1
            if (rows[ri].1 ? 1 : 0) ^ parity == 1 { x |= UInt64(1) << UInt64(c) }
        }
        if best == nil || x.nonzeroBitCount < best!.nonzeroBitCount { best = x }
    }
    return best
}

private let tShapes: [String: [String]] = [
    "row3": ["###"], "row4": ["####"], "2x3": ["###", "###"], "3x3": ["###", "###", "###"],
    "3x4": ["####", "####", "####"], "4x4": ["####", "####", "####", "####"],
    "5x5": ["#####", "#####", "#####", "#####", "#####"],
    "ring": ["####", "#..#", "#..#", "####"],
    "oval": [".####.", "######", "######", ".####."],
    "cross": [".###.", "#####", "#####", "#####", ".###."],
    "holed": [".###.", "#####", "##.##", "#####", ".###."],
]

private let tLadder: [[String]] = [["row3"], ["row4"], ["2x3"], ["3x3"], ["3x4"], ["4x4"],
                                     ["ring", "oval", "cross"], ["5x5", "holed", "cross", "oval"]]

/// A board recipe at difficulty `d`: the shape and how many random taps scramble it.
@MainActor private func tRecipe(_ m: ArcadeModel) -> (shape: String, taps: ClosedRange<Int>) {
    var i = Int(m.ramp(0, Double(tLadder.count) - 0.01, from: 1, to: 8.5))
    if i > 1 && Double.random(in: 0..<1) < 0.2 { i -= 1 }          // a smaller board as review
    let lo = m.rampInt(1, 5, to: 9), hi = max(lo, m.rampInt(1, 8, to: 11))
    return (tLadder[i].randomElement()!, lo...hi)
}

/// A fresh board: (board, starting lit bits, par). `single` = a one-tap board (the very start).
private func tMake(_ shape: String, _ taps: ClosedRange<Int>, single: Bool) -> (TBoard, UInt64, Int) {
    let board = TBoard(tShapes[shape]!)
    var fallback: (UInt64, Int)?
    for _ in 0..<80 {
        let k = Int.random(in: taps)
        let picks = Array(0..<board.cells.count).shuffled().prefix(k)
        var lit = board.full
        for i in picks { lit ^= board.masks[i] }
        guard lit != board.full, let sol = tSolve(board.masks, board.full ^ lit) else { continue }
        let par = sol.nonzeroBitCount
        if par >= max(1, taps.lowerBound - 1) && (!single || par == 1) { return (board, lit, par) }
        fallback = (lit, par)
    }
    let f = fallback ?? (board.full ^ board.masks[board.cells.count / 2], 1)
    return (board, f.0, f.1)
}

// MARK: - Model

@MainActor
private final class TorchModel: ArcadeModel {
    @Published var board = TBoard(["###"])
    @Published var lit: UInt64 = 0
    @Published var taps = 0
    @Published var par = 1
    @Published var budget = 5
    @Published var hint: Int?
    @Published var reveal: UInt64 = 0      // cells still to tap in the shown answer
    @Published var revealing = false
    @Published var pressed: Int?
    @Published var celebrate = false
    @Published var perfect = false
    @Published var boardID = 0

    private var busy = false
    private var gen = 0
    private var hintGen = 0

    init() {
        super.init(key: GameID.torches.rawValue)
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { tSelfCheck() }
        #endif
    }

    override func perLevel(_ level: Int) -> Int { 3 }
    override func onBegin() { newBoard() }

    private func later(_ s: Double, _ f: @escaping () -> Void) {
        let g = gen
        DispatchQueue.main.asyncAfter(deadline: .now() + s) { [weak self] in
            guard let self, self.gen == g, self.phase == .playing else { return }
            f()
        }
    }

    var tapsLeft: Int { max(0, budget - taps) }

    private func newBoard() {
        gen += 1
        let r = tRecipe(self)
        let (b, l, p) = tMake(r.shape, r.taps, single: d < 1.7)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            board = b; lit = l; par = p; taps = 0
            budget = p + rampInt(4, 2, from: 3, to: 7)
            hint = nil; reveal = 0; revealing = false; celebrate = false; perfect = false; pressed = nil
            boardID += 1
        }
        busy = false
        armHint()
    }

    private func armHint() {
        hintGen += 1
        let h = hintGen
        later(ramp(3, 14, to: 8)) { [unowned self] in
            guard h == hintGen, !busy, let sol = tSolve(board.masks, board.full ^ lit), sol != 0 else { return }
            withAnimation(.easeOut(duration: 0.25)) { hint = sol.trailingZeroBitCount }
        }
    }

    func tap(_ i: Int) {
        guard phase == .playing, !busy, i < board.masks.count else { return }
        let lighting = (board.masks[i] & ~lit).nonzeroBitCount >= (board.masks[i] & lit).nonzeroBitCount
        withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) { lit ^= board.masks[i] }
        taps += 1
        hint = nil
        Haptics.tap(0.45)
        Sfx.play(lighting ? .whoosh : .tick, volume: lighting ? 0.55 : 0.8)
        if lit == board.full { solved() }
        else if taps >= budget { outOfTaps() }
        else { armHint() }
    }

    private func solved() {
        busy = true
        hintGen += 1
        perfect = taps <= par
        withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) { celebrate = true }
        hit(points: perfect ? 3 : 1)
        later(1.4) { [unowned self] in newBoard() }
    }

    /// Out of taps: show the fewest taps from here, then tap them out one by one.
    private func outOfTaps() {
        busy = true
        hintGen += 1
        let sol = tSolve(board.masks, board.full ^ lit) ?? 0
        let steps = (0..<board.cells.count).filter { (sol >> UInt64($0)) & 1 == 1 }
        let show = 0.9, step = 0.55
        miss(reason: "Out of hearts!", delay: show + step * Double(steps.count) + 0.7)
        withAnimation(.easeOut(duration: 0.25)) { reveal = sol; revealing = true }
        for (k, i) in steps.enumerated() {
            later(show + step * Double(k)) { [unowned self] in
                withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                    lit ^= board.masks[i]
                    reveal &= ~(UInt64(1) << UInt64(i))
                }
                Haptics.light()
            }
        }
        later(show + step * Double(steps.count) + 0.9) { [unowned self] in if !dying { newBoard() } }
    }

    override func botAct(correct: Bool) {
        guard !busy, let sol = tSolve(board.masks, board.full ^ lit) else { return }
        let n = board.cells.count
        if correct && sol != 0 { tap(sol.trailingZeroBitCount); return }
        let off = (0..<n).filter { (sol >> UInt64($0)) & 1 == 0 }
        tap(off.randomElement() ?? Int.random(in: 0..<n))
    }
}

#if DEBUG
/// LUDUS_SELFCHECK=1: every board starts unsolved, its par solution really lights every torch,
/// par fits the budget, and (for boards up to 16 torches) par matches a brute-force minimum.
@MainActor private func tSelfCheck() {
    var lines: [String] = []
    for shape in tShapes.keys.sorted() {
        let level = shape
        var bad = 0, brute = 0, bruteBad = 0, pars: [Int] = []
        for k in 0..<200 {
            let (b, lit, par) = tMake(shape, 1...8, single: false)
            pars.append(par)
            guard lit != b.full, let sol = tSolve(b.masks, b.full ^ lit) else { bad += 1; continue }
            var s = lit
            for i in 0..<b.cells.count where (sol >> UInt64(i)) & 1 == 1 { s ^= b.masks[i] }
            if s != b.full || sol.nonzeroBitCount != par || par < 1 { bad += 1 }
            if b.cells.count <= 16 && k < 25 {
                brute += 1
                var best = Int.max
                for m in 0..<(1 << b.cells.count) {
                    var x: UInt64 = 0
                    for i in 0..<b.cells.count where (m >> i) & 1 == 1 { x ^= b.masks[i] }
                    if x == b.full ^ lit { best = min(best, m.nonzeroBitCount) }
                }
                if best != par { bruteBad += 1 }
            }
        }
        lines.append("L\(level): bad=\(bad) par \(pars.min()!)…\(pars.max()!) brute-checked=\(brute) bruteMismatch=\(bruteBad)")
    }
    let out = "TORCHES SELFCHECK\n" + lines.joined(separator: "\n")
    print(out)
    try? out.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("torches_selfcheck.txt"), atomically: true, encoding: .utf8)
}
#endif

// MARK: - Pictures

/// The bronze bowl of a brazier.
private struct TBowl: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY), control: CGPoint(x: r.maxX - r.width * 0.08, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY), control: CGPoint(x: r.minX + r.width * 0.08, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// A flame: a teardrop with a pointed, slightly wavering tip.
private struct TFlame: Shape {
    var lean: CGFloat = 0
    var animatableData: CGFloat { get { lean } set { lean = newValue } }
    func path(in r: CGRect) -> Path {
        var p = Path()
        let tip = CGPoint(x: r.midX + lean * r.width * 0.25, y: r.minY)
        p.move(to: tip)
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
                   control1: CGPoint(x: r.maxX + r.width * 0.1, y: r.minY + r.height * 0.45),
                   control2: CGPoint(x: r.maxX, y: r.maxY))
        p.addCurve(to: tip,
                   control1: CGPoint(x: r.minX, y: r.maxY),
                   control2: CGPoint(x: r.minX - r.width * 0.1, y: r.minY + r.height * 0.45))
        p.closeSubpath()
        return p
    }
}

private struct TFire: View {
    let s: CGFloat
    @State private var flick = false
    var body: some View {
        ZStack(alignment: .bottom) {
            TFlame(lean: flick ? 0.5 : -0.4)
                .fill(LinearGradient(colors: [Color(hex: 0xff5a1f), Color(hex: 0xff9a2a)], startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.5, height: s * 0.62)
            TFlame(lean: flick ? -0.3 : 0.4)
                .fill(LinearGradient(colors: [Color(hex: 0xffc23a), Color(hex: 0xffe680)], startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.32, height: s * 0.42)
            TFlame(lean: flick ? 0.2 : -0.2)
                .fill(Color(hex: 0xfff6d0))
                .frame(width: s * 0.14, height: s * 0.2)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: Double.random(in: 0.28...0.4)).repeatForever(autoreverses: true)) { flick = true }
        }
    }
}

private struct TorchTile: View {
    let lit: Bool
    let size: CGFloat
    let preview: Bool       // a press elsewhere will flip this one
    let pointing: Bool      // hint / reveal finger
    let celebrate: Bool

    var body: some View {
        ZStack {
            // Stone plinth
            RoundedRectangle(cornerRadius: size * 0.16)
                .fill(LinearGradient(colors: lit ? [Color(hex: 0x8a6a52), Color(hex: 0x5a4234)]
                                                 : [Color(hex: 0x4a4658), Color(hex: 0x2c2a38)],
                                     startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: size * 0.12).stroke(.black.opacity(0.3), lineWidth: 1.5)
                .padding(size * 0.06)
            if lit {
                RadialGradient(colors: [Color(hex: 0xffb04a).opacity(0.65), .clear],
                               center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: size * 0.55)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.16))
            }
            // Tripod legs
            ForEach([-1.0, 1.0], id: \.self) { k in
                Capsule().fill(Color(hex: 0x6a4a2a)).frame(width: size * 0.05, height: size * 0.26)
                    .rotationEffect(.degrees(k * 16)).offset(x: CGFloat(k) * size * 0.08, y: size * 0.32)
            }
            // Coals + bowl
            Capsule().fill(lit ? Color(hex: 0xc0401a) : Color(hex: 0x2b2430))
                .frame(width: size * 0.46, height: size * 0.1).offset(y: size * 0.1)
            TBowl().fill(LinearGradient(colors: [Color(hex: 0xe4b46a), Color(hex: 0x8c5a2a)], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.58, height: size * 0.2).offset(y: size * 0.2)
            TFire(s: size)
                .scaleEffect(lit ? (celebrate ? 1.25 : 1) : 0.05, anchor: .bottom)
                .opacity(lit ? 1 : 0)
                .offset(y: -size * 0.15)
            if !lit {
                // A curl of smoke
                Path { p in
                    p.move(to: CGPoint(x: size * 0.5, y: size * 0.55))
                    p.addCurve(to: CGPoint(x: size * 0.52, y: size * 0.2),
                               control1: CGPoint(x: size * 0.38, y: size * 0.42), control2: CGPoint(x: size * 0.64, y: size * 0.32))
                }
                .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: size * 0.04, lineCap: .round))
            }
        }
        .frame(width: size, height: size)
        .shadow(color: lit ? Color(hex: 0xff9a2a).opacity(0.55) : .black.opacity(0.4), radius: lit ? size * 0.12 : 3, y: lit ? 0 : 3)
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.16)
                .stroke(Color(hex: preview ? 0xfff2c0 : (lit ? 0xe0a050 : 0x5a5670)),
                        style: StrokeStyle(lineWidth: preview ? 4 : 2, dash: preview ? [8, 5] : []))
        )
        .overlay(alignment: .bottomTrailing) {
            if pointing { TPointer(size: size) }
        }
    }
}

/// A pulsing gold ring + finger on the torch to tap.
private struct TPointer: View {
    let size: CGFloat
    @State private var pulse = false
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: size * 0.16).stroke(Color(hex: Lu.gold), lineWidth: 5)
                .frame(width: size, height: size)
                .scaleEffect(pulse ? 1.06 : 0.96)
                .opacity(pulse ? 1 : 0.6)
            Text("👆").font(.system(size: size * 0.32)).offset(x: size * 0.06, y: size * 0.1)
                .scaleEffect(pulse ? 1.1 : 0.9)
        }
        .allowsHitTesting(false)
        .onAppear { withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { pulse = true } }
    }
}

/// The Colosseum at night: deep sky, stars and a moon, the dark ring of arches, and the arena
/// floor in torchlight (brighter as more torches burn).
private struct TBackdrop: View {
    let glow: Double
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .top) {
                LinearGradient(colors: [Color(hex: 0x0b0d26), Color(hex: 0x1d1a44), Color(hex: 0x2a1f3a)],
                               startPoint: .top, endPoint: .bottom)
                Canvas { ctx, size in
                    for i in 0..<60 {
                        let x = CGFloat((i * 73) % 397) / 397 * size.width
                        let y = CGFloat((i * 151) % 211) / 211 * size.height * 0.3
                        let r: CGFloat = i % 7 == 0 ? 2.2 : 1.2
                        ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(.white.opacity(i % 3 == 0 ? 0.9 : 0.5)))
                    }
                }
                Circle().fill(Color(hex: 0xf6ecd4)).frame(width: 46).shadow(color: .white.opacity(0.5), radius: 16)
                    .overlay(Circle().fill(Color(hex: 0x0b0d26)).frame(width: 40).offset(x: 12, y: -6))
                    .position(x: w * 0.82, y: h * 0.13)
                // Ring of arches (two tiers), dark against the sky
                VStack(spacing: 0) {
                    TArches(count: 9).fill(Color(hex: 0x3a2e3e), style: FillStyle(eoFill: true)).frame(height: h * 0.09)
                    TArches(count: 11).fill(Color(hex: 0x2e2434), style: FillStyle(eoFill: true)).frame(height: h * 0.08)
                }
                .padding(.top, h * 0.17)
                // Arena floor in torchlight
                VStack(spacing: 0) {
                    Spacer().frame(height: h * 0.34)
                    ZStack {
                        LinearGradient(colors: [Color(hex: 0x4a3426), Color(hex: 0x2c2018)], startPoint: .top, endPoint: .bottom)
                        RadialGradient(colors: [Color(hex: 0xff9a2a).opacity(0.1 + 0.3 * glow), .clear],
                                       center: UnitPoint(x: 0.5, y: 0.4), startRadius: 10, endRadius: w)
                    }
                }
            }
        }
    }
}

/// A wall of arches: a band with round-topped openings cut out (fill even-odd).
private struct TArches: Shape {
    let count: Int
    func path(in r: CGRect) -> Path {
        var p = Path(r)
        let cw = r.width / CGFloat(count)
        for i in 0..<count {
            let x = r.minX + cw * CGFloat(i) + cw * 0.18
            let aw = cw * 0.64
            let top = r.minY + r.height * 0.22
            var a = Path()
            a.move(to: CGPoint(x: x, y: r.maxY))
            a.addLine(to: CGPoint(x: x, y: top + aw / 2))
            a.addArc(center: CGPoint(x: x + aw / 2, y: top + aw / 2), radius: aw / 2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            a.addLine(to: CGPoint(x: x + aw, y: r.maxY))
            a.closeSubpath()
            p.addPath(a)
        }
        return p
    }
}

// MARK: - View

struct TorchesView: View {
    let onClose: () -> Void
    @StateObject private var model = TorchModel()

    private var litShare: Double {
        let n = model.board.cells.count
        return n == 0 ? 0 : Double(model.lit.nonzeroBitCount) / Double(n)
    }

    var body: some View {
        ArcadeShell(model: model,
                    spec: GameID.torches.spec ?? GameSpec(title: "Torches of the Arena", mechanic: "", premise: "", game: .torches),
                    accent: Lu.tangerine, onClose: onClose,
                    backdrop: { TBackdrop(glow: litShare).animation(.easeOut(duration: 0.4), value: litShare) }) {
            VStack(spacing: 12) {
                Color.clear.frame(height: 56)
                tapsPanel
                GeometryReader { geo in board(in: geo.size) }
                message.frame(height: 56)
            }
            .padding(.horizontal, 14).padding(.bottom, 10)
        }
    }

    private var tapsPanel: some View {
        HStack(spacing: 10) {
            Text("👆").font(.system(size: 24))
            HStack(spacing: 5) {
                ForEach(0..<model.budget, id: \.self) { i in
                    Circle().fill(Color(hex: i < model.tapsLeft ? 0xffb04a : 0x4a3e3a))
                        .overlay(Circle().stroke(.black.opacity(0.3), lineWidth: 1))
                        .frame(width: 14, height: 14)
                }
            }
            .animation(.easeOut(duration: 0.2), value: model.taps)
            Spacer(minLength: 4)
            if model.level >= 3 {
                VStack(spacing: 0) {
                    Text("FEWEST").font(luFont(9, .heavy)).tracking(1.2).foregroundStyle(Color(hex: 0xe8d4b0))
                    Text("\(model.par)").font(luFont(22)).foregroundStyle(Color(hex: 0xffb04a))
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 14)
            .fill(LinearGradient(colors: [Color(hex: 0x5a4a44), Color(hex: 0x3a302e)], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0x8a7050), lineWidth: 2)))
    }

    private func board(in size: CGSize) -> some View {
        let b = model.board
        let gap: CGFloat = b.cols >= 5 ? 6 : 10
        let cs = min(110, (size.width - 24 - gap * CGFloat(b.cols - 1)) / CGFloat(b.cols),
                     (size.height - 24 - gap * CGFloat(b.rows - 1)) / CGFloat(b.rows))
        let previewMask = model.pressed.map { b.masks[$0] } ?? 0
        return VStack(spacing: gap) {
            ForEach(0..<b.rows, id: \.self) { r in
                HStack(spacing: gap) {
                    ForEach(0..<b.cols, id: \.self) { c in
                        if let i = b.index(r: r, c: c) {
                            let bit = UInt64(1) << UInt64(i)
                            TorchTile(lit: model.lit & bit != 0, size: cs,
                                      preview: previewMask & bit != 0,
                                      pointing: model.hint == i || model.reveal & bit != 0,
                                      celebrate: model.celebrate)
                                .contentShape(Rectangle())
                                .gesture(DragGesture(minimumDistance: 0)
                                    .onChanged { _ in if model.pressed != i { model.pressed = i } }
                                    .onEnded { v in
                                        model.pressed = nil
                                        if CGRect(x: 0, y: 0, width: cs, height: cs).insetBy(dx: -8, dy: -8).contains(v.location) {
                                            model.tap(i)
                                        }
                                    })
                        } else {
                            // A gap in the arena floor
                            Circle().fill(Color.black.opacity(0.25)).frame(width: cs * 0.5, height: cs * 0.5)
                                .frame(width: cs, height: cs)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: 0x1e1614).opacity(0.55))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: 0x6a5040).opacity(0.7), lineWidth: 2)))
        .id(model.boardID)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder private var message: some View {
        Group {
            if model.celebrate {
                Text(model.perfect ? "✨ PERFECT! ✨" : "🔥 ALL LIT! 🔥")
                    .font(luFont(30)).foregroundStyle(Color(hex: model.perfect ? Lu.gold : Lu.tangerine))
            } else if model.revealing {
                Text("👀 Watch — tap these!")
                    .font(luFont(24)).foregroundStyle(Color(hex: Lu.ink))
            } else if model.hint != nil {
                Text("Try this one 👆").font(luFont(22, .heavy)).foregroundStyle(Color(hex: Lu.gold))
            } else {
                Text("Light every torch!").font(luSerif(20, .heavy)).foregroundStyle(Color(hex: 0xe8d4b0))
            }
        }
        .shadow(color: .black.opacity(0.6), radius: 3)
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: model.celebrate)
    }
}
