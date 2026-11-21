import CoreGraphics
import Foundation

// How each letter, digit and picture is DRAWN: its strokes, in order, each with a
// start and a direction. Tracing used to check only that ink covered the shape, so a
// backwards or scribbled letter passed — and correct formation is the whole point of
// handwriting practice. These are hand-authored in a simple school model ("start at
// the top"): ball-and-stick lowercase, straight capitals.
//
// Coordinates: x right, y DOWN. Letters sit on three-line paper — y 0 is the top
// line, 0.5 the dashed midline, 1 the baseline, 1.5 the bottom of a descender.
// Pictures use a 0–1 square.
//
// A tiny path language, one stroke per `|`:
//   M x y        move (starts the stroke)      L x y   line to
//   A cx cy r a0 a1        arc, degrees, 0 = right, 90 = DOWN; a0 → a1 in that
//                          direction (decreasing = anticlockwise on screen)
//   E cx cy rx ry a0 a1    the same, for an ellipse
//   W x0 y x1 amp n        a wave of n periods      S cx cy r turns   a spiral, inward
//   D x y        a dot (one tap)
enum Strokes {
    struct Stroke { let points: [CGPoint]; let isDot: Bool }

    static let lower: [String: String] = [
        "a": "A .25 .75 .25 -30 -390 | M .5 .5 L .5 1",
        "b": "M 0 0 L 0 1 | A .25 .75 .25 180 540",
        "c": "A .25 .75 .25 -40 -320",
        "d": "A .25 .75 .25 -30 -390 | M .5 0 L .5 1",
        "e": "M 0 .75 L .5 .75 A .25 .75 .25 0 -310",
        "f": "A .38 .18 .14 -20 -180 L .24 1 | M .05 .5 L .45 .5",
        "g": "A .25 .75 .25 -30 -390 | M .5 .5 L .5 1.28 A .3 1.28 .2 0 160",
        "h": "M 0 0 L 0 1 | A .25 .75 .25 180 360 L .5 1",
        "i": "M .1 .5 L .1 1 | D .1 .3",
        "j": "M .35 .5 L .35 1.3 A .18 1.3 .17 0 170 | D .35 .3",
        "k": "M 0 0 L 0 1 | M .45 .5 L .03 .76 L .48 1",
        "l": "M .1 0 L .1 1",
        "m": "M 0 .5 L 0 1 | A .16 .72 .16 180 360 L .32 1 L .32 .72 A .48 .72 .16 180 360 L .64 1",
        "n": "M 0 .5 L 0 1 | A .25 .75 .25 180 360 L .5 1",
        "o": "A .25 .75 .25 -90 -450",
        "p": "M 0 .5 L 0 1.5 | A .25 .75 .25 180 540",
        "q": "A .25 .75 .25 -30 -390 | M .5 .5 L .5 1.5",
        "r": "M 0 .5 L 0 1 | A .22 .75 .22 180 300",
        "s": "A .22 .625 .125 -20 -270 A .22 .875 .125 -90 150",
        "t": "M .2 .15 L .2 1 | M 0 .5 L .4 .5",
        "u": "M 0 .5 L 0 .75 A .25 .75 .25 180 0 L .5 .5 | M .5 .5 L .5 1",
        "v": "M 0 .5 L .25 1 L .5 .5",
        "w": "M 0 .5 L .16 1 L .32 .62 L .48 1 L .64 .5",
        "x": "M 0 .5 L .5 1 | M .5 .5 L 0 1",
        "y": "M 0 .5 L .25 1 | M .5 .5 L .08 1.5",
        "z": "M 0 .5 L .5 .5 L 0 1 L .5 1",
    ]

    static let upper: [String: String] = [
        "A": "M .35 0 L 0 1 | M .35 0 L .7 1 | M .13 .62 L .57 .62",
        "B": "M 0 0 L 0 1 | M 0 0 L .25 0 A .25 .24 .24 -90 90 L 0 .48 | M 0 .48 L .3 .48 A .3 .74 .26 -90 90 L 0 1",
        "C": "A .5 .5 .5 -40 -320",
        "D": "M 0 0 L 0 1 | M 0 0 L .2 0 A .2 .5 .5 -90 90 L 0 1",
        "E": "M 0 0 L 0 1 | M 0 0 L .55 0 | M 0 .5 L .45 .5 | M 0 1 L .55 1",
        "F": "M 0 0 L 0 1 | M 0 0 L .55 0 | M 0 .5 L .45 .5",
        "G": "A .5 .5 .5 -40 -360 L .55 .5",
        "H": "M 0 0 L 0 1 | M .65 0 L .65 1 | M 0 .5 L .65 .5",
        "I": "M .25 0 L .25 1 | M 0 0 L .5 0 | M 0 1 L .5 1",
        "J": "M .45 0 L .45 .72 A .22 .72 .23 0 170",
        "K": "M 0 0 L 0 1 | M .6 0 L .04 .55 L .6 1",
        "L": "M 0 0 L 0 1 L .55 1",
        "M": "M 0 0 L 0 1 | M 0 0 L .38 .62 L .76 0 L .76 1",
        "N": "M 0 0 L 0 1 | M 0 0 L .65 1 L .65 0",
        "O": "A .5 .5 .5 -90 -450",
        "P": "M 0 0 L 0 1 | M 0 0 L .28 0 A .28 .26 .26 -90 90 L 0 .52",
        "Q": "A .5 .5 .5 -90 -450 | M .62 .72 L .98 1.05",
        "R": "M 0 0 L 0 1 | M 0 0 L .28 0 A .28 .26 .26 -90 90 L 0 .52 | M .25 .52 L .62 1",
        "S": "A .32 .25 .25 -20 -270 A .32 .75 .25 -90 150",
        "T": "M 0 0 L .7 0 | M .35 0 L .35 1",
        "U": "M 0 0 L 0 .68 A .32 .68 .32 180 0 L .64 0",
        "V": "M 0 0 L .35 1 L .7 0",
        "W": "M 0 0 L .22 1 L .45 .35 L .68 1 L .9 0",
        "X": "M 0 0 L .65 1 | M .65 0 L 0 1",
        "Y": "M 0 0 L .33 .5 | M .66 0 L .33 .5 L .33 1",
        "Z": "M 0 0 L .65 0 L 0 1 L .65 1",
    ]

    static let digits: [String: String] = [
        "0": "E .3 .5 .3 .5 -90 -450",
        "1": "M .1 .2 L .35 0 L .35 1",
        "2": "A .27 .27 .25 -160 20 L 0 1 L .55 1",
        "3": "A .25 .25 .23 -150 90 A .25 .74 .26 -90 150",
        "4": "M .38 0 L 0 .66 L .58 .66 | M .42 .3 L .42 1",
        "5": "M .5 0 L .08 0 L .04 .44 A .25 .7 .28 -130 150",
        "6": "M .45 0 L .06 .58 A .3 .72 .28 -150 -510",
        "7": "M 0 0 L .58 0 L .15 1",
        "8": "A .28 .25 .22 -20 -270 A .28 .72 .27 -90 270 A .28 .25 .22 90 -20",
        "9": "A .27 .3 .27 0 -360 L .5 1",
    ]

    /// Pictures for the Draw lane, in the order pre-writing skills develop: a
    /// straight line down, then across, a circle, circles with lines, crossing
    /// diagonals, a triangle, a square, zigzags, waves, arcs, a spiral — and then
    /// pictures that combine them. Each finishes as its emoji, so the reward is
    /// the thing the child drew coming to life.
    struct Picture { let name: String; let emoji: String; let path: String }
    static let pictures: [Picture] = [
        Picture(name: "rain", emoji: "🌧️", path: "M .25 .15 L .25 .55 | M .5 .3 L .5 .7 | M .75 .45 L .75 .85"),
        Picture(name: "ladder", emoji: "🪜", path: "M .3 .05 L .3 .95 | M .7 .05 L .7 .95 | M .3 .27 L .7 .27 | M .3 .5 L .7 .5 | M .3 .73 L .7 .73"),
        Picture(name: "ball", emoji: "⚽", path: "A .5 .5 .38 -90 -450"),
        Picture(name: "apple", emoji: "🍎", path: "A .5 .58 .33 -90 -450 | M .5 .25 L .53 .07"),
        Picture(name: "sun", emoji: "☀️", path: "A .5 .5 .2 -90 -450 | M .5 .2 L .5 .04 | M .5 .8 L .5 .96 | M .2 .5 L .04 .5 | M .8 .5 L .96 .5"),
        Picture(name: "balloon", emoji: "🎈", path: "E .5 .35 .25 .3 -90 -450 | M .5 .65 L .44 .75 L .56 .85 L .5 .96"),
        Picture(name: "snowman", emoji: "⛄", path: "A .5 .27 .15 -90 -450 | A .5 .67 .25 -90 -450"),
        Picture(name: "kite", emoji: "🪁", path: "M .5 .05 L .8 .4 L .5 .8 L .2 .4 L .5 .05 | M .5 .8 L .44 .89 L .56 .96"),
        Picture(name: "tent", emoji: "⛺", path: "M .5 .15 L .1 .85 L .9 .85 L .5 .15"),
        Picture(name: "house", emoji: "🏠", path: "M .2 .45 L .2 .9 L .8 .9 L .8 .45 L .2 .45 | M .12 .48 L .5 .12 L .88 .48"),
        Picture(name: "mountains", emoji: "⛰️", path: "M .05 .8 L .25 .35 L .45 .8 L .65 .25 L .95 .8"),
        Picture(name: "waves", emoji: "🌊", path: "W .05 .45 .95 .12 2 | W .05 .7 .95 .12 2"),
        Picture(name: "rainbow", emoji: "🌈", path: "A .5 .8 .4 180 360 | A .5 .8 .28 180 360 | A .5 .8 .16 180 360"),
        Picture(name: "snail", emoji: "🐌", path: "S .5 .5 .38 2.5"),
        Picture(name: "fish", emoji: "🐟", path: "E .42 .5 .3 .2 -180 180 | M .72 .5 L .93 .32 L .93 .68 L .72 .5"),
        Picture(name: "star", emoji: "⭐", path: "M .5 .07 L .76 .88 L .07 .38 L .93 .38 L .24 .88 L .5 .07"),
        Picture(name: "moon", emoji: "🌙", path: "A .5 .5 .38 -60 -300 A .8 .5 .348 108 252"),
        Picture(name: "tree", emoji: "🌳", path: "M .5 .95 L .5 .58 | A .5 .35 .24 90 -270"),
        Picture(name: "car", emoji: "🚗", path: "M .1 .65 L .1 .45 L .3 .45 L .4 .25 L .65 .25 L .75 .45 L .9 .45 L .9 .65 L .1 .65 | A .3 .72 .1 -90 -450 | A .72 .72 .1 -90 -450"),
        Picture(name: "cat", emoji: "🐱", path: "A .5 .58 .32 -90 -450 | M .25 .38 L .22 .1 L .42 .28 | M .58 .28 L .78 .1 L .75 .38"),
    ]

    static func strokes(for glyph: String) -> [Stroke]? {
        guard let src = lower[glyph] ?? upper[glyph] ?? digits[glyph] else { return nil }
        return parse(src)
    }

    /// Parse the path language into strokes of evenly spaced points (~0.02 apart).
    static func parse(_ src: String) -> [Stroke] {
        src.split(separator: "|").map { part in
            var pts: [CGPoint] = []
            var dot = false
            let t = part.split(separator: " ").map(String.init)
            var i = 0
            func num(_ k: Int) -> CGFloat { CGFloat(Double(t[i + k]) ?? 0) }
            func lineTo(_ p: CGPoint) {
                guard let last = pts.last else { pts.append(p); return }
                let n = max(1, Int((hypot(p.x - last.x, p.y - last.y) / 0.02).rounded(.up)))
                for k in 1...n {
                    let f = CGFloat(k) / CGFloat(n)
                    pts.append(CGPoint(x: last.x + (p.x - last.x) * f, y: last.y + (p.y - last.y) * f))
                }
            }
            func arc(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat,
                     _ a0: CGFloat, _ a1: CGFloat) {
                let sweep = (a1 - a0) * .pi / 180
                let n = max(2, Int((abs(sweep) * max(rx, ry) / 0.02).rounded(.up)))
                for k in 0...n {
                    let a = a0 * .pi / 180 + sweep * CGFloat(k) / CGFloat(n)
                    let p = CGPoint(x: cx + rx * cos(a), y: cy + ry * sin(a))
                    if k == 0, pts.last != nil { lineTo(p) } else { pts.append(p) }
                }
            }
            while i < t.count {
                switch t[i] {
                case "M": pts.append(CGPoint(x: num(1), y: num(2))); i += 3
                case "L": lineTo(CGPoint(x: num(1), y: num(2))); i += 3
                case "A": arc(num(1), num(2), num(3), num(3), num(4), num(5)); i += 6
                case "E": arc(num(1), num(2), num(3), num(4), num(5), num(6)); i += 7
                case "D": pts = [CGPoint(x: num(1), y: num(2))]; dot = true; i += 3
                case "W":
                    let x0 = num(1), y = num(2), x1 = num(3), amp = num(4), n = num(5)
                    let steps = Int(((x1 - x0) / 0.015).rounded(.up))
                    for k in 0...steps {
                        let f = CGFloat(k) / CGFloat(steps)
                        let p = CGPoint(x: x0 + (x1 - x0) * f, y: y - amp * sin(f * n * 2 * .pi))
                        if k == 0, pts.last != nil { lineTo(p) } else { pts.append(p) }
                    }
                    i += 6
                case "S":
                    let cx = num(1), cy = num(2), r = num(3), turns = num(4)
                    let total = turns * 2 * .pi
                    let steps = Int((total * r / 0.02).rounded(.up))
                    for k in 0...steps {
                        let f = CGFloat(k) / CGFloat(steps)
                        let a = -CGFloat.pi / 2 - f * total
                        let rr = r * (1 - f * 0.92)
                        pts.append(CGPoint(x: cx + rr * cos(a), y: cy + rr * sin(a)))
                    }
                    i += 5
                default: i += 1
                }
            }
            return Stroke(points: pts, isDot: dot)
        }
    }
}

#if DEBUG
import SwiftUI

/// Debug only (`-screen strokesheet [lower|upper|digits|pictures]`): every item's
/// strokes at once, start dots numbered, so a wrong stroke is seen, not trusted.
struct StrokeSheet: View {
    let set: String
    private var items: [(String, [Strokes.Stroke], Bool)] {
        switch set {
        case "upper": return Strokes.upper.keys.sorted().map { ($0, Strokes.parse(Strokes.upper[$0]!), true) }
        case "digits": return Strokes.digits.keys.sorted().map { ($0, Strokes.parse(Strokes.digits[$0]!), true) }
        case "pictures": return Strokes.pictures.map { ($0.emoji, Strokes.parse($0.path), false) }
        default: return Strokes.lower.keys.sorted().map { ($0, Strokes.parse(Strokes.lower[$0]!), true) }
        }
    }
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 6) {
                ForEach(items, id: \.0) { key, strokes, ruled in
                    Canvas { ctx, size in
                        let s = ruled ? size.height / 1.6 : size.width * 0.9
                        let xs = strokes.flatMap { $0.points.map(\.x) }
                        let ox = ruled ? size.width / 2 - ((xs.min() ?? 0) + (xs.max() ?? 1)) / 2 * s : size.width * 0.05
                        let oy = ruled ? size.height * 0.05 : size.height * 0.05
                        func v(_ p: CGPoint) -> CGPoint { CGPoint(x: ox + p.x * s, y: oy + p.y * s) }
                        if ruled {
                            for y in [0.0, 0.5, 1.0] {
                                var l = Path(); l.move(to: CGPoint(x: 0, y: v(CGPoint(x: 0, y: y)).y))
                                l.addLine(to: CGPoint(x: size.width, y: v(CGPoint(x: 0, y: y)).y))
                                ctx.stroke(l, with: .color(.gray.opacity(0.4)), lineWidth: 0.5)
                            }
                        }
                        let colors: [Color] = [.blue, .orange, .purple, .pink, .brown]
                        for (i, st) in strokes.enumerated() {
                            var p = Path()
                            if let f = st.points.first { p.move(to: v(f)) }
                            for q in st.points.dropFirst() { p.addLine(to: v(q)) }
                            ctx.stroke(p, with: .color(colors[i % 5]), lineWidth: 3)
                            if let f = st.points.first {
                                ctx.fill(Path(ellipseIn: CGRect(x: v(f).x - 5, y: v(f).y - 5, width: 10, height: 10)), with: .color(.green))
                                ctx.draw(Text("\(i + 1)").font(.system(size: 9, weight: .bold)), at: CGPoint(x: v(f).x + 8, y: v(f).y - 6))
                            }
                            if st.points.count > 3 {
                                let a = v(st.points[st.points.count - 3]), b = v(st.points.last!)
                                ctx.fill(Path(ellipseIn: CGRect(x: b.x - 3, y: b.y - 3, width: 6, height: 6)), with: .color(.red))
                                _ = a
                            }
                        }
                        ctx.draw(Text(key).font(.system(size: 10)), at: CGPoint(x: 8, y: size.height - 8))
                    }
                    .frame(height: 120)
                    .background(Color.white)
                }
            }
            .padding(6)
        }
        .background(Color(white: 0.9))
    }
}
#endif
