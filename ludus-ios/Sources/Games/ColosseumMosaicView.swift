import SwiftUI

// MARK: - Mosaic Mender  (Brain Benders · patterns)
//
// Mus the mouse dashes across the Emperor's mosaic floor and pinches a tile! Work out the pattern
// and drag the right tile from the basket up into the gap (or just tap it). The right one clicks
// in with a sparkle; a wrong one pops back out and the right tile glides in, so the answer shows.
//
// Difficulty is continuous (`d`). Pattern KINDS fade in by `tier` and older kinds stay as review:
//   d 1    A B A B …               (two colours)
//   d 2.2  A B C / A A B / A B B   (longer units, the gap moves inside the row)
//   d 3.4  growing dots (1 2 3 …, or counting down) and tiles that turn a quarter each step
//   d 4.6  two rules at once — shapes in twos, colours in threes
//   d 5.8  grids: every row has its shape, every column its colour
//   d 7    grids where each row slides one along (a Latin square)
//   d 8    mirror mosaics — the right half reflects the left
// Basket size grows 2 → 5, and the wrong tiles creep closer to the right one (one feature off).

// MARK: Tiles

private struct MTile: Hashable {
    var shape: Int          // 0 circle, 1 square, 2 triangle, 3 diamond, 4 half, 5 star, 6 dots
    var colour: Int         // index into mColours
    var rot = 0             // quarter turns (triangle, half)
    var pips = 0            // shape 6
}

private let mColours: [UInt] = [0xc8553d, 0x3e6e9a, 0xe0a83a, 0x5d8a3a, 0x2f2a33]
private let mPlainShapes = [0, 1, 3, 5]        // look the same however you mirror or turn them

private func mRandom(_ shapes: [Int] = mPlainShapes) -> MTile {
    MTile(shape: shapes.randomElement()!, colour: Int.random(in: 0..<mColours.count))
}

private struct MPuzzle {
    var rows: Int, cols: Int
    var tiles: [MTile]
    var gap: Int
    var mirror = false
    var answer: MTile { tiles[gap] }
}

// MARK: Pattern makers

/// Distinct tiles (by colour, and by shape when `shapes` is true).
private func mDistinct(_ n: Int, shapes: Bool) -> [MTile] {
    let cs = Array(0..<mColours.count).shuffled()
    let ss = mPlainShapes.shuffled()
    let one = ss[0]
    return (0..<n).map { i in MTile(shape: shapes ? ss[i % ss.count] : one, colour: cs[i % cs.count]) }
}

@MainActor
private func mMake(_ m: ArcadeModel) -> MPuzzle {
    func gapIn(_ n: Int, minIdx: Int) -> Int {
        m.chance(1, from: 2, to: 5) ? Int.random(in: minIdx..<n) : n - 1
    }
    switch m.tier([1, 2.2, 3.4, 4.6, 5.8, 7, 8]) {
    case 0:   // A B A B A B
        let u = mDistinct(2, shapes: m.d < 1.6)
        let n = 6
        return MPuzzle(rows: 1, cols: n, tiles: (0..<n).map { u[$0 % 2] }, gap: gapIn(n, minIdx: 2))
    case 1:   // units of three
        let t = mDistinct(3, shapes: Bool.random())
        let units = [[t[0], t[1], t[2]], [t[0], t[0], t[1]], [t[0], t[1], t[1]]]
        let u = units.randomElement()!
        let n = m.rampInt(6, 8, from: 2.2, to: 5)
        return MPuzzle(rows: 1, cols: n, tiles: (0..<n).map { u[$0 % 3] }, gap: gapIn(n, minIdx: 3))
    case 2:   // growing dots, or a turning tile
        let c = Int.random(in: 0..<mColours.count)
        if Bool.random() {
            let down = m.chance(0.5, from: 3.4, to: 6)
            let n = 5
            let start = down ? 6 : Int.random(in: 1...2)
            let tiles = (0..<n).map { MTile(shape: 6, colour: c, pips: down ? start - $0 : start + $0) }
            return MPuzzle(rows: 1, cols: n, tiles: tiles, gap: gapIn(n, minIdx: 2))
        } else {
            let shape = [2, 4].randomElement()!
            let step = m.chance(0.5, from: 4, to: 7) ? 3 : 1          // clockwise, or anticlockwise
            let r0 = Int.random(in: 0..<4)
            let n = 6
            let tiles = (0..<n).map { MTile(shape: shape, colour: c, rot: (r0 + step * $0) % 4) }
            return MPuzzle(rows: 1, cols: n, tiles: tiles, gap: gapIn(n, minIdx: 2))
        }
    case 3:   // two rules at once: shape period 2, colour period 3 (or turning + two colours)
        let n = 8
        if Bool.random() {
            let ss = Array(mPlainShapes.shuffled().prefix(2)), cs = Array(Array(0..<mColours.count).shuffled().prefix(3))
            let tiles = (0..<n).map { MTile(shape: ss[$0 % 2], colour: cs[$0 % 3]) }
            return MPuzzle(rows: 1, cols: n, tiles: tiles, gap: Int.random(in: 6..<n))
        } else {
            let cs = Array(Array(0..<mColours.count).shuffled().prefix(2))
            let r0 = Int.random(in: 0..<4)
            let tiles = (0..<n).map { MTile(shape: 4, colour: cs[$0 % 2], rot: (r0 + $0) % 4) }
            return MPuzzle(rows: 1, cols: n, tiles: tiles, gap: Int.random(in: 4..<n))
        }
    case 4:   // grid: shape by row, colour by column
        let rows = 3, cols = m.rampInt(3, 4, from: 6, to: 8)
        let ss = Array(mPlainShapes.shuffled().prefix(rows)), cs = Array(Array(0..<mColours.count).shuffled().prefix(cols))
        let tiles = (0..<rows * cols).map { MTile(shape: ss[$0 / cols], colour: cs[$0 % cols]) }
        return MPuzzle(rows: rows, cols: cols, tiles: tiles, gap: Int.random(in: 0..<rows * cols))
    case 5:   // Latin square: each row slides one along
        let n = m.rampInt(3, 4, from: 7.5, to: 9.5)
        let base = mDistinct(n, shapes: true)
        let dir = Bool.random() ? 1 : n - 1
        let tiles = (0..<n * n).map { i in base[(i % n + (i / n) * dir) % n] }
        return MPuzzle(rows: n, cols: n, tiles: tiles, gap: Int.random(in: n..<n * n))
    default:  // mirror: right half reflects left
        let rows = m.rampInt(3, 4, from: 8, to: 10), half = 2
        var tiles = Array(repeating: MTile(shape: 0, colour: 0), count: rows * half * 2)
        for r in 0..<rows {
            for c in 0..<half {
                var t = mRandom(mPlainShapes + [2])
                if t.shape == 2 { t.rot = Bool.random() ? 0 : 2 }   // up/down triangles mirror to themselves
                tiles[r * 4 + c] = t
                tiles[r * 4 + 3 - c] = t
            }
        }
        let gap = Int.random(in: 0..<rows) * 4 + Int.random(in: 2...3)
        return MPuzzle(rows: rows, cols: 4, tiles: tiles, gap: gap, mirror: true)
    }
}

/// Wrong tiles for the basket: one feature off from the answer (or two, early on).
@MainActor
private func mDecoys(_ p: MPuzzle, _ k: Int, close: Bool) -> [MTile] {
    let a = p.answer
    var out = Set<MTile>()
    var tries = 0
    // Tiles from the mosaic itself are the most tempting decoys.
    for t in p.tiles.shuffled() where t != a && out.count < k && close { out.insert(t) }
    while out.count < k && tries < 200 {
        tries += 1
        var t = a
        let flips = close ? 1 : 2
        var kinds = [0, 1]
        if a.shape == 2 || a.shape == 4 { kinds.append(2) }
        if a.shape == 6 { kinds = [3, 3, 0] }
        for kind in kinds.shuffled().prefix(flips) {
            switch kind {
            case 0: t.colour = (t.colour + Int.random(in: 1..<mColours.count)) % mColours.count
            case 1: if a.shape == 2 || a.shape == 4 { t.rot = (t.rot + Int.random(in: 1...3)) % 4 }
                    else { t.shape = mPlainShapes.filter { $0 != a.shape }.randomElement()! }
            case 2: t.rot = (t.rot + Int.random(in: 1...3)) % 4
            default: t.pips = max(1, min(6, a.pips + [-2, -1, 1, 2].randomElement()!))
            }
        }
        if t != a { out.insert(t) }
    }
    return Array(out.prefix(k))
}

// MARK: - Model

@MainActor
private final class MosaicModel: ArcadeModel {
    @Published var puzzle = MPuzzle(rows: 1, cols: 6, tiles: Array(repeating: MTile(shape: 0, colour: 0), count: 6), gap: 5)
    @Published var basket: [MTile] = []
    @Published var holeOpen = false          // the mouse has taken the tile
    @Published var mouseX: CGFloat = -0.2    // 0…1 across the mosaic
    @Published var placed: MTile?            // what sits in the gap now
    @Published var bounced: MTile?           // a wrong tile popping back out
    @Published var glowRight = false
    @Published var sparkle = false
    @Published var busy = true
    @Published var roundID = 0

    private var gen = 0

    init() { super.init(key: GameID.mosaicMender.rawValue) }

    override func perLevel(_ level: Int) -> Int { 5 }
    override func onBegin() { newRound() }

    private func later(_ s: Double, _ f: @escaping () -> Void) {
        let g = gen
        DispatchQueue.main.asyncAfter(deadline: .now() + s) { [weak self] in
            guard let self, self.gen == g, self.phase == .playing else { return }
            f()
        }
    }

    func newRound() {
        gen += 1
        let p = mMake(self)
        let k = max(p.rows > 1 ? 2 : 1, rampInt(1, 4, to: 7))
        let decoys = mDecoys(p, k, close: chance(1, from: 2, to: 6))
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) {
            puzzle = p
            basket = (decoys + [p.answer]).shuffled()
            holeOpen = true; placed = nil; bounced = nil; glowRight = false; sparkle = false
            mouseX = -0.25
            busy = false
            roundID += 1
        }
        // Mus the mouse scampers off with his loot (the tile's in his sack — no peeking!).
        later(0.2) { [unowned self] in
            Sfx.play(.whoosh, volume: 0.5)
            withAnimation(.linear(duration: 1.3)) { mouseX = 1.25 }
        }
    }

    func place(_ tile: MTile) {
        guard phase == .playing, !busy, placed == nil else { return }
        busy = true
        let right = tile == puzzle.answer
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { placed = tile }
        Sfx.play(.thud, volume: 0.6)
        if right {
            later(0.2) { [unowned self] in
                withAnimation(.easeOut(duration: 0.5)) { sparkle = true }
                Sfx.play(.sparkle)
            }
            hit()
            later(1.3) { [unowned self] in newRound() }
        } else {
            let last = miss(delay: 2.2)
            later(0.6) { [unowned self] in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { placed = nil; bounced = tile; glowRight = true }
            }
            later(1.3) { [unowned self] in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { placed = puzzle.answer }
                Sfx.play(.sparkle)
            }
            if !last { later(2.6) { [unowned self] in newRound() } }
        }
    }

    override func botAct(correct: Bool) {
        guard !busy else { return }
        if correct { place(puzzle.answer) }
        else { place(basket.first { $0 != puzzle.answer } ?? puzzle.answer) }
    }
}

// MARK: - Tile pictures

private struct MTri: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct MHalf: Shape {      // the lower-left half of a square
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct MDiamond: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p
    }
}

private struct MStar: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY + r.height * 0.04)
        for i in 0..<10 {
            let a = Double(i) * .pi / 5 - .pi / 2
            let rad = (i % 2 == 0 ? r.width / 2 : r.width * 0.21)
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * rad, y: c.y + CGFloat(sin(a)) * rad)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

private struct MTileView: View {
    let tile: MTile
    let s: CGFloat
    var body: some View {
        let col = Color(hex: mColours[tile.colour])
        let ink = LinearGradient(colors: [luShade(mColours[tile.colour], 30), col], startPoint: .top, endPoint: .bottom)
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.1).fill(Color(hex: 0xf3e6c8))
            RoundedRectangle(cornerRadius: s * 0.1).stroke(Color(hex: 0xd8c49a), lineWidth: 1)
            switch tile.shape {
            case 0: Circle().fill(ink).padding(s * 0.16)
            case 1: RoundedRectangle(cornerRadius: s * 0.06).fill(ink).padding(s * 0.2)
            case 2: MTri().fill(ink).padding(s * 0.16).rotationEffect(.degrees(Double(tile.rot) * 90))
            case 3: MDiamond().fill(ink).padding(s * 0.12)
            case 4: MHalf().fill(ink).padding(s * 0.08).rotationEffect(.degrees(Double(tile.rot) * 90))
            case 5: MStar().fill(ink).padding(s * 0.1)
            default: MPips(n: tile.pips, colour: col).padding(s * 0.12)
            }
        }
        .frame(width: s, height: s)
    }
}

/// Dots laid out like a die face.
private struct MPips: View {
    let n: Int
    let colour: Color
    var body: some View {
        GeometryReader { g in
            let s = g.size.width
            let spots: [[(CGFloat, CGFloat)]] = [
                [], [(0.5, 0.5)], [(0.25, 0.25), (0.75, 0.75)], [(0.22, 0.22), (0.5, 0.5), (0.78, 0.78)],
                [(0.25, 0.25), (0.75, 0.25), (0.25, 0.75), (0.75, 0.75)],
                [(0.22, 0.22), (0.78, 0.22), (0.5, 0.5), (0.22, 0.78), (0.78, 0.78)],
                [(0.27, 0.2), (0.73, 0.2), (0.27, 0.5), (0.73, 0.5), (0.27, 0.8), (0.73, 0.8)],
            ]
            ForEach(Array(spots[max(0, min(6, n))].enumerated()), id: \.offset) { _, p in
                Circle().fill(colour).frame(width: s * 0.24).position(x: s * p.0, y: s * p.1)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Mus the mouse, drawn: grey body, big pink ears, a long tail — carrying the stolen tile.
private struct MMouse: View {
    let s: CGFloat
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: s * 0.15, y: s * 0.62))
                p.addCurve(to: CGPoint(x: -s * 0.2, y: s * 0.4), control1: CGPoint(x: 0, y: s * 0.8), control2: CGPoint(x: -s * 0.1, y: s * 0.3))
            }
            .stroke(Color(hex: 0xd99aa0), style: StrokeStyle(lineWidth: s * 0.04, lineCap: .round))
            Ellipse().fill(Color(hex: 0x9a929e)).frame(width: s * 0.62, height: s * 0.42).position(x: s * 0.42, y: s * 0.6)
            Circle().fill(Color(hex: 0x9a929e)).frame(width: s * 0.34).position(x: s * 0.76, y: s * 0.48)
            Circle().fill(Color(hex: 0xb0a8b4)).frame(width: s * 0.22).position(x: s * 0.68, y: s * 0.26)
            Circle().fill(Color(hex: 0xf3a8b0)).frame(width: s * 0.13).position(x: s * 0.68, y: s * 0.26)
            Circle().fill(Color(hex: 0x2a1a20)).frame(width: s * 0.06).position(x: s * 0.82, y: s * 0.44)
            Circle().fill(Color(hex: 0xf08a9a)).frame(width: s * 0.07).position(x: s * 0.94, y: s * 0.52)
            Capsule().fill(Color(hex: 0x7a727e)).frame(width: s * 0.08, height: s * 0.14).position(x: s * 0.3, y: s * 0.82)
            Capsule().fill(Color(hex: 0x7a727e)).frame(width: s * 0.08, height: s * 0.14).position(x: s * 0.55, y: s * 0.82)
        }
        .frame(width: s, height: s)
    }
}

// MARK: - Scene

/// A villa floor of small tesserae around the Emperor's mosaic.
private struct MBackdrop: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x6a4630)))
            let t: CGFloat = 13
            let tones: [UInt] = [0xb07850, 0xa36d47, 0xbd865a, 0x9a6440, 0xc49166]
            var y: CGFloat = 0, row = 0
            while y < size.height {
                var x: CGFloat = row % 2 == 0 ? 0 : -t / 2, col = 0
                while x < size.width {
                    let h = tones[(row * 7 + col * 13 + (row * col) % 5) % tones.count]
                    ctx.fill(Path(roundedRect: CGRect(x: x + 1, y: y + 1, width: t - 2, height: t - 2), cornerRadius: 2),
                             with: .color(Color(hex: h)))
                    x += t; col += 1
                }
                y += t; row += 1
            }
            // A soft vignette
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .radialGradient(Gradient(colors: [.clear, .black.opacity(0.45)]),
                                           center: CGPoint(x: size.width / 2, y: size.height * 0.45),
                                           startRadius: size.width * 0.3, endRadius: size.height * 0.75))
        }
    }
}

// MARK: - View

struct MosaicMenderView: View {
    let onClose: () -> Void
    @StateObject private var model = MosaicModel()
    @State private var drag: (MTile, CGSize)?

    var body: some View {
        ArcadeShell(model: model,
                    spec: GameID.mosaicMender.spec ?? GameSpec(title: "Mosaic Mender", mechanic: "", premise: "", game: .mosaicMender),
                    accent: Lu.tangerine, onClose: onClose,
                    backdrop: { MBackdrop() }) {
            VStack(spacing: 10) {
                Color.clear.frame(height: 58)
                emperor
                GeometryReader { geo in mosaic(geo.size) }
                basket
            }
            .padding(.horizontal, 12).padding(.bottom, 10)
        }
    }

    /// Emperor Pompous watches over his floor and has opinions.
    private var emperor: some View {
        let mood: MEmperor.Mood = model.sparkle ? .pleased : (model.glowRight ? .cross : .neutral)
        let line: String
        switch mood {
        case .pleased: line = ["Splendid!", "Magnificent!", "Bravo, little tiler!", "Perfect fit!"][model.roundID % 4]
        case .cross: line = "Bah! THIS one fits!"
        case .neutral:
            line = !model.holeOpen ? "Ah, my beautiful floor…"
                : (model.puzzle.mirror ? "Mus! Make both sides match!" : "Mus took a tile! Which fits?")
        }
        return HStack(spacing: 6) {
            MEmperor(s: 118, mood: mood)
            Text(line)
                .font(luSerif(21, .black)).foregroundStyle(Color(hex: Lu.inkDark))
                .multilineTextAlignment(.leading).lineLimit(2).minimumScaleFactor(0.7)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                .background(MBubble().fill(Color(hex: 0xfbf3e0)).shadow(color: .black.opacity(0.35), radius: 4, y: 2))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: line)
        }
    }

    private func mosaic(_ size: CGSize) -> some View {
        let p = model.puzzle
        let gap: CGFloat = 4
        let frameW: CGFloat = 14
        let s = min(96, (size.width - frameW * 2 - gap * CGFloat(p.cols - 1)) / CGFloat(p.cols),
                    (size.height - frameW * 2 - 40 - gap * CGFloat(p.rows - 1)) / CGFloat(p.rows))
        let w = s * CGFloat(p.cols) + gap * CGFloat(p.cols - 1)
        let h = s * CGFloat(p.rows) + gap * CGFloat(p.rows - 1)
        return ZStack(alignment: .topLeading) {
            ForEach(0..<p.tiles.count, id: \.self) { i in
                let x = CGFloat(i % p.cols) * (s + gap) + s / 2, y = CGFloat(i / p.cols) * (s + gap) + s / 2
                Group {
                    if i == p.gap && model.holeOpen {
                        ZStack {
                            RoundedRectangle(cornerRadius: s * 0.1).fill(Color(hex: 0x2a1a12))
                            RoundedRectangle(cornerRadius: s * 0.1)
                                .stroke(Color(hex: Lu.gold).opacity(0.8), style: StrokeStyle(lineWidth: 2.5, dash: [6, 4]))
                            if let t = model.placed {
                                MTileView(tile: t, s: s)
                                    .transition(.scale(scale: 1.5).combined(with: .opacity))
                            } else {
                                Text("?").font(luFont(s * 0.45)).foregroundStyle(Color(hex: Lu.gold).opacity(0.7))
                            }
                        }
                        .frame(width: s, height: s)
                    } else {
                        MTileView(tile: p.tiles[i], s: s)
                    }
                }
                .scaleEffect(model.sparkle ? 1.06 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.4).delay(Double(i) * 0.02), value: model.sparkle)
                .position(x: x, y: y)
            }
            if p.mirror {
                Rectangle().fill(Color(hex: Lu.gold).opacity(0.85)).frame(width: 2, height: h + 10)
                    .position(x: w / 2, y: h / 2)
            }
            if model.sparkle {
                Text("✨").font(.system(size: s * 0.8))
                    .position(x: CGFloat(p.gap % p.cols) * (s + gap) + s / 2, y: CGFloat(p.gap / p.cols) * (s + gap))
                    .transition(.scale.combined(with: .opacity))
            }
            // Mus the mouse, running along the bottom edge with the tile.
            MMouse(s: min(70, s * 0.9))
                .overlay(alignment: .top) {
                    // His loot sack
                    ZStack {
                        Circle().fill(Color(hex: 0xa0703a)).frame(width: 22, height: 22)
                        Capsule().fill(Color(hex: 0x6a4a22)).frame(width: 12, height: 4).offset(y: -10)
                    }
                    .offset(x: -4, y: 4)
                }
                .position(x: -20 + (w + 40) * model.mouseX, y: h + frameW + 6)
                .opacity(model.mouseX > -0.2 && model.mouseX < 1.2 ? 1 : 0)
        }
        .frame(width: w, height: h)
        .padding(frameW)
        .background(MFrame())
        .id(model.roundID)
        .transition(.opacity)
        .frame(width: size.width, height: size.height)
    }

    private var basket: some View {
        HStack(spacing: 12) {
            ForEach(Array(model.basket.enumerated()), id: \.offset) { _, t in
                let isDragging = drag?.0 == t
                MTileView(tile: t, s: model.basket.count > 4 ? 60 : 70)
                    .shadow(color: model.glowRight && t == model.puzzle.answer ? Color(hex: Lu.gold) : .black.opacity(0.35),
                            radius: model.glowRight && t == model.puzzle.answer ? 12 : 3, y: 2)
                    .scaleEffect(isDragging ? 1.15 : 1)
                    .offset(isDragging ? drag!.1 : .zero)
                    .opacity((model.placed == t && !model.glowRight) || (model.placed == t && t == model.puzzle.answer) ? 0.25 : 1)
                    .rotationEffect(.degrees(model.bounced == t ? 10 : 0))
                    .zIndex(isDragging ? 2 : 1)
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { v in drag = (t, v.translation) }
                        .onEnded { v in
                            let moved = hypot(v.translation.width, v.translation.height)
                            // A tap, or a toss up toward the mosaic, places it.
                            if moved < 12 || v.translation.height < -50 { model.place(t) }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { drag = nil }
                        })
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(colors: [Color(hex: 0xc99a5a), Color(hex: 0x8a5e30)], startPoint: .top, endPoint: .bottom))
                .overlay(
                    VStack(spacing: 7) { ForEach(0..<6, id: \.self) { _ in Rectangle().fill(.black.opacity(0.1)).frame(height: 2) } }
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                )
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: 0x5e3a1e), lineWidth: 3))
        )
        .overlay(alignment: .top) {
            Text("BASKET").font(luFont(10, .heavy)).tracking(2).foregroundStyle(Color(hex: 0xfff4dc))
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(Capsule().fill(Color(hex: 0x5e3a1e))).offset(y: -9)
        }
    }
}

/// Emperor Pompous: a round face under a laurel wreath, a toga with a purple stripe.
private struct MEmperor: View {
    enum Mood { case neutral, pleased, cross }
    let s: CGFloat
    let mood: Mood
    var body: some View {
        ZStack {
            // Toga
            RoundedRectangle(cornerRadius: s * 0.2).fill(Color(hex: 0xf4efe4))
                .frame(width: s * 0.78, height: s * 0.4).position(x: s * 0.5, y: s * 0.9)
            Capsule().fill(Color(hex: 0x7a2a6a)).frame(width: s * 0.1, height: s * 0.5)
                .rotationEffect(.degrees(-35)).position(x: s * 0.42, y: s * 0.86)
            // Head
            Ellipse().fill(Color(hex: 0xf1c79a)).frame(width: s * 0.56, height: s * 0.6).position(x: s * 0.5, y: s * 0.46)
            Circle().fill(Color(hex: 0xf1c79a)).frame(width: s * 0.12).position(x: s * 0.22, y: s * 0.5)
            Circle().fill(Color(hex: 0xf1c79a)).frame(width: s * 0.12).position(x: s * 0.78, y: s * 0.5)
            // Hair + wreath
            Capsule().fill(Color(hex: 0x6a4a2a)).frame(width: s * 0.5, height: s * 0.14).position(x: s * 0.5, y: s * 0.22)
            HStack(spacing: -s * 0.06) {
                Image(systemName: "laurel.leading"); Image(systemName: "laurel.trailing")
            }
            .font(.system(size: s * 0.3, weight: .bold)).foregroundStyle(Color(hex: 0x4e8a3a))
            .rotationEffect(.degrees(180)).position(x: s * 0.5, y: s * 0.2)
            // Brows
            Capsule().fill(Color(hex: 0x5a3a20)).frame(width: s * 0.12, height: s * 0.03)
                .rotationEffect(.degrees(mood == .cross ? 20 : -8)).position(x: s * 0.39, y: s * 0.37)
            Capsule().fill(Color(hex: 0x5a3a20)).frame(width: s * 0.12, height: s * 0.03)
                .rotationEffect(.degrees(mood == .cross ? -20 : 8)).position(x: s * 0.61, y: s * 0.37)
            // Eyes
            ForEach([0.4, 0.6], id: \.self) { x in
                Group {
                    if mood == .pleased {
                        MSmile().stroke(Color(hex: 0x2a1a10), style: StrokeStyle(lineWidth: s * 0.025, lineCap: .round))
                            .frame(width: s * 0.08, height: s * 0.04).rotationEffect(.degrees(180))
                    } else {
                        Circle().fill(Color(hex: 0x2a1a10)).frame(width: s * 0.06)
                    }
                }
                .position(x: s * x, y: s * 0.44)
            }
            // Nose (a proper Roman one) + cheeks
            Capsule().fill(Color(hex: 0xe0a87a)).frame(width: s * 0.07, height: s * 0.14).position(x: s * 0.5, y: s * 0.52)
            Circle().fill(Color(hex: 0xf08a6a).opacity(0.45)).frame(width: s * 0.08).position(x: s * 0.33, y: s * 0.56)
            Circle().fill(Color(hex: 0xf08a6a).opacity(0.45)).frame(width: s * 0.08).position(x: s * 0.67, y: s * 0.56)
            // Mouth
            MSmile().stroke(Color(hex: 0x7a2a1a), style: StrokeStyle(lineWidth: s * 0.03, lineCap: .round))
                .frame(width: s * (mood == .pleased ? 0.2 : 0.12), height: s * 0.06)
                .rotationEffect(.degrees(mood == .cross ? 180 : 0))
                .position(x: s * 0.5, y: s * 0.64)
        }
        .frame(width: s, height: s)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: mood)
    }
}

private struct MSmile: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY * 2 - r.minY))
        return p
    }
}

/// A speech bubble with its tail on the left.
private struct MBubble: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path(roundedRect: r, cornerRadius: 16)
        p.move(to: CGPoint(x: r.minX + 2, y: r.midY - 8))
        p.addLine(to: CGPoint(x: r.minX - 12, y: r.midY + 4))
        p.addLine(to: CGPoint(x: r.minX + 2, y: r.midY + 8))
        p.closeSubpath()
        return p
    }
}

/// The mosaic's dark border with a gold meander band.
private struct MFrame: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(hex: 0x2a1f24))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: 0xe0b860), style: StrokeStyle(lineWidth: 3, dash: [8, 4, 2, 4])).padding(4))
            .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
    }
}
