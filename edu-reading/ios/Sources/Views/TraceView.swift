import SwiftUI
import CoreText

// Writing, not just reading. A faint letter with a dotted line down its CENTRE, and
// the child draws over it with a finger. No wrong stroke, no scolding — the card
// notices when the centre-line has been traced and celebrates.
//
// The centre-line is the glyph's skeleton, derived straight from the real Andika
// outline by morphological thinning (Zhang–Suen). That means it is genuinely centred
// for every letter with nothing hand-authored, so what is drawn is also exactly what
// recognition checks.

enum Glyph {
    private static let font: CTFont? = {
        guard let url = Bundle.main.url(forResource: "Andika-Bold", withExtension: "ttf"),
              let provider = CGDataProvider(url: url as CFURL),
              let cg = CGFont(provider) else { return nil }
        return CTFontCreateWithGraphicsFont(cg, 100, nil, nil)
    }()

    static func path(_ ch: Character) -> CGPath? {
        guard let font else { return nil }
        var uni = Array(String(ch).utf16)
        var g = CGGlyph()
        guard CTFontGetGlyphsForCharacters(font, &uni, &g, 1) else { return nil }
        return CTFontCreatePathForGlyph(font, g, nil)
    }

    /// The glyph outline, scaled and centred to fill `rect` (aspect preserved, y flipped).
    static func fitted(_ ch: Character, in rect: CGRect) -> CGPath? {
        guard let raw = path(ch) else { return nil }
        let box = raw.boundingBoxOfPath
        guard box.width > 0, box.height > 0 else { return nil }
        let s = min(rect.width / box.width, rect.height / box.height)
        let offX = rect.midX - box.midX * s
        let offY = rect.midY + box.midY * s
        var tf = CGAffineTransform(a: s, b: 0, c: 0, d: -s, tx: offX, ty: offY)
        return raw.copy(using: &tf)
    }

    /// The centre-line of a filled glyph, as points, via Zhang–Suen thinning of a
    /// raster of the shape. Centred by construction, one cell wide.
    static func skeleton(_ path: CGPath, in fb: CGRect, step: CGFloat) -> [CGPoint] {
        guard step > 0, fb.width > 0, fb.height > 0 else { return [] }
        let cols = Int(ceil(fb.width / step)) + 2
        let rows = Int(ceil(fb.height / step)) + 2
        let ox = fb.minX - step, oy = fb.minY - step
        func center(_ c: Int, _ r: Int) -> CGPoint {
            CGPoint(x: ox + (CGFloat(c) + 0.5) * step, y: oy + (CGFloat(r) + 0.5) * step)
        }
        var g = Array(repeating: Array(repeating: false, count: cols), count: rows)
        for r in 0..<rows { for c in 0..<cols { g[r][c] = path.contains(center(c, r), using: .winding) } }

        // P2..P9, clockwise from north.
        func nb(_ r: Int, _ c: Int) -> [Bool] {
            [g[r-1][c], g[r-1][c+1], g[r][c+1], g[r+1][c+1],
             g[r+1][c], g[r+1][c-1], g[r][c-1], g[r-1][c-1]]
        }
        var changed = true
        while changed {
            changed = false
            for sub in 0..<2 {
                var rem: [(Int, Int)] = []
                for r in 1..<rows - 1 { for c in 1..<cols - 1 where g[r][c] {
                    let n = nb(r, c)
                    let b = n.filter { $0 }.count
                    if b < 2 || b > 6 { continue }
                    var a = 0
                    for i in 0..<8 where !n[i] && n[(i + 1) % 8] { a += 1 }
                    if a != 1 { continue }
                    if sub == 0 {
                        if n[0] && n[2] && n[4] { continue }
                        if n[2] && n[4] && n[6] { continue }
                    } else {
                        if n[0] && n[2] && n[6] { continue }
                        if n[0] && n[4] && n[6] { continue }
                    }
                    rem.append((r, c))
                }}
                if !rem.isEmpty { changed = true; for (r, c) in rem { g[r][c] = false } }
            }
        }
        var pts: [CGPoint] = []
        for r in 1..<rows - 1 { for c in 1..<cols - 1 where g[r][c] {
            if nb(r, c).contains(true) { pts.append(center(c, r)) }  // drop lone specks
        }}
        return pts
    }
}

struct TraceView: View {
    @Environment(Progress.self) private var progress
    @Environment(\.dismiss) private var dismiss
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0x7A5EA8)

    enum Mode: CaseIterable {
        case upper, lower, digit
        var next: Mode {
            switch self { case .upper: return .lower; case .lower: return .digit; case .digit: return .upper }
        }
        var badge: String {
            switch self { case .upper: return "A"; case .lower: return "a"; case .digit: return "1" }
        }
    }

    @State private var index = 0
    @State private var mode: Mode = .upper
    @State private var strokes: [[CGPoint]] = []
    @State private var current: [CGPoint] = []
    @State private var ghost = Path()
    @State private var dots: [CGPoint] = []          // the centre-line, and the target
    @State private var guideDots: [CGPoint] = []     // a spaced subset, for drawing
    @State private var dotCell: [Int] = []
    @State private var covered: [Bool] = []
    @State private var cellTotal: [Int: Int] = [:]
    @State private var cellCov: [Int: Int] = [:]
    @State private var done = false
    @State private var canvas: CGSize = .zero

    private var items: [String] {
        switch mode {
        case .upper: return c.letters.map(\.upper)
        case .lower: return c.letters.map(\.lower)
        case .digit: return (0...9).map(String.init)
        }
    }
    private var glyph: String { items.isEmpty ? "" : items[index % items.count] }
    private var ink: CGFloat { max(min(canvas.width, canvas.height) * 0.05, 8) }

    var body: some View {
        ZStack {
            Skin.current.appGround.ignoresSafeArea()
            VStack(spacing: 16) { card; controls }
                .padding(18)
        }
        .overlay(alignment: .topLeading) { BackChevron { dismiss() }.padding(.leading, 10).padding(.top, 6) }
        .overlay(alignment: .topTrailing) { modeToggle.padding(.trailing, 10).padding(.top, 6) }
        .toolbar(.hidden, for: .navigationBar)
        .noBackSwipe()
    }

    private var card: some View {
        GeometryReader { geo in
            ZStack {
                ghost.fill(Skin.live.cardInkSoft.opacity(0.13))
                if !done {
                    Canvas { ctx, _ in
                        let r: CGFloat = max(min(geo.size.width, geo.size.height) * 0.009, 3)
                        for p in guideDots {
                            ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                                     with: .color(Skin.live.cardInkSoft.opacity(0.75)))
                        }
                    }
                }
                ForEach(strokes.indices, id: \.self) { i in line(strokes[i]).stroke(accent, style: inkStyle) }
                line(current).stroke(accent, style: inkStyle)
                if done { ReadItCelebration(accent: accent).allowsHitTesting(false) }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(draw)
            .onAppear { canvas = geo.size; prepare(speak: true) }
            .onChange(of: geo.size) { _, s in canvas = s; prepare(speak: false) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(CardSurfaceStyle(skin: Skin.current))
    }

    private var controls: some View {
        HStack {
            glass("eraser") {
                strokes = []; current = []; done = false
                covered = Array(repeating: false, count: dots.count); cellCov = [:]
            }
            Spacer()
            Text("\(index % max(items.count, 1) + 1) / \(items.count)")
                .font(.andika(14, bold: true)).monospacedDigit().foregroundStyle(Skin.live.onSkySoft)
            Spacer()
            glass("arrow.right") { next() }
        }
        .padding(.horizontal, 4)
    }

    private var modeToggle: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { mode = mode.next; index = 0 }
            prepare(speak: false)
        } label: {
            Text(mode.badge).font(.andika(19, bold: true)).foregroundStyle(Skin.live.cardInk)
                .frame(width: 42, height: 42).contentShape(Circle())
        }
        .buttonStyle(.plain).modifier(GlassCircle())
        .accessibilityLabel("Capitals, small letters or numbers")
    }

    private func glass(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Skin.live.cardInk).frame(width: 42, height: 42).contentShape(Circle())
        }
        .buttonStyle(.plain).modifier(GlassCircle())
    }

    private var inkStyle: StrokeStyle { StrokeStyle(lineWidth: ink, lineCap: .round, lineJoin: .round) }

    /// Greedily thin a point cloud so no two kept points are closer than `minDist` —
    /// evenly spaced dots along the centre-line without needing them ordered.
    private static func spaced(_ pts: [CGPoint], minDist: CGFloat) -> [CGPoint] {
        let d2 = minDist * minDist
        var kept: [CGPoint] = []
        for p in pts {
            var ok = true
            for q in kept {
                let dx = p.x - q.x, dy = p.y - q.y
                if dx * dx + dy * dy < d2 { ok = false; break }
            }
            if ok { kept.append(p) }
        }
        return kept
    }

    private func line(_ pts: [CGPoint]) -> Path {
        var p = Path()
        guard let first = pts.first else { return p }
        p.move(to: first)
        for pt in pts.dropFirst() { p.addLine(to: pt) }
        if pts.count == 1 { p.addLine(to: CGPoint(x: first.x + 0.5, y: first.y)) }
        return p
    }

    private var draw: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in current.append(v.location); absorb(v.location) }
            .onEnded { _ in if !current.isEmpty { strokes.append(current); current = [] } }
    }

    /// Mark centre-line points the finger passes near; celebrate once the whole line
    /// is traced — region by region, so no part (an A crossbar) can be skipped.
    private func absorb(_ p: CGPoint) {
        guard !dots.isEmpty else { return }
        let r2 = pow(min(canvas.width, canvas.height) * 0.06, 2)
        for i in dots.indices where !covered[i] {
            let dx = dots[i].x - p.x, dy = dots[i].y - p.y
            if dx * dx + dy * dy <= r2 { covered[i] = true; cellCov[dotCell[i], default: 0] += 1 }
        }
        if !done, traced() { finish() }
    }

    private func traced() -> Bool {
        guard !dots.isEmpty else { return false }
        let hit = cellCov.values.reduce(0, +)
        guard Double(hit) / Double(dots.count) >= 0.75 else { return false }
        let minPts = max(2, dots.count / 40)
        for (cell, total) in cellTotal where total >= minPts {
            if Double(cellCov[cell] ?? 0) / Double(total) < 0.5 { return false }
        }
        return true
    }

    private func finish() {
        done = true
        Buzz.yes()
        Voice.shared.celebrate()
        if let ch = glyph.first, ch.isLetter { progress.wroteLetter(glyph.lowercased()) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { next() }
    }

    private func next() {
        index = (index + 1) % max(items.count, 1)
        prepare(speak: true)
    }

    private func prepare(speak: Bool) {
        strokes = []; current = []; done = false
        dots = []; guideDots = []; dotCell = []; covered = []; cellTotal = [:]; cellCov = [:]
        guard canvas.width > 1, let ch = glyph.first else { return }
        let target = CGRect(x: canvas.width * 0.22, y: canvas.height * 0.16,
                            width: canvas.width * 0.56, height: canvas.height * 0.68)
        guard let fitted = Glyph.fitted(ch, in: target) else { return }
        ghost = Path(fitted)

        let fb = fitted.boundingBoxOfPath
        let step = max(min(canvas.width, canvas.height) * 0.016, 4)
        dots = Glyph.skeleton(fitted, in: fb, step: step)
        covered = Array(repeating: false, count: dots.count)
        // A spaced subset for a clean dotted look — the full set still drives recognition.
        guideDots = Self.spaced(dots, minDist: step * 2.8)

        // Coarse regions for "every part traced".
        let cellSize = max(min(canvas.width, canvas.height) * 0.13, 10)
        let gcols = max(1, Int(ceil(fb.width / cellSize)))
        for p in dots {
            let cc = min(gcols - 1, max(0, Int((p.x - fb.minX) / cellSize)))
            let cr = max(0, Int((p.y - fb.minY) / cellSize))
            let cell = cr * gcols + cc
            dotCell.append(cell); cellTotal[cell, default: 0] += 1
        }

        if speak, ch.isLetter,
           let l = c.letters.first(where: { $0.lower == glyph.lowercased() }),
           Voice.shared.hasRecording(l.sound) {
            Voice.shared.say(l.sound)
        }
    }
}

