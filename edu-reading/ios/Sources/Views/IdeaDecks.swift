import SwiftUI

// Colours, shapes and numbers are DRAWN, not sourced — no photographs to hunt,
// nothing to audit, no licences, and every card correct by construction.
//
// Each teaches a PROPERTY rather than a thing, so each needs the app's rule
// applied twice over: vary everything except what is being taught. Three
// different dogs teach "dog"; a single red circle labelled "red" teaches
// "circle" just as readily.
//
// That is also where the extra cards come from. Every item appears several times
// in genuinely different arrangements, and each variation carries its own lesson:
//   • colour, across unlike shapes and across many small scattered pieces
//   • shape, across colours and across SIZES — size does not change identity
//   • number, across arrangements — five in a row is still five, which is
//     conservation of number and a real milestone rather than padding

// MARK: - Colours

struct ColorsView: View {
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0x4E8FBF)
    private struct Card: Hashable { let idx: Int; let layout: Int }
    @State private var pool: [Card] = []
    @State private var index = 0

    var body: some View {
        DeckScreen(title: "Colours", count: pool.count, index: $index, accent: accent) { i in
            let card = pool[min(i, max(pool.count - 1, 0))]
            let swatch = c.colors[card.idx]
            let tint = Color(hexString: swatch.hex)
            AdaptiveCard {
                ZStack {
                    Theme.paper
                    GeometryReader { geo in
                        Group {
                            if card.layout == 0 {
                                FourShapes(tint: tint, size: geo.size)
                            } else {
                                Scatter(tint: tint, size: geo.size)
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
            } caption: {
                phonics(swatch.word, size: 40)
            }
            .overlay(alignment: .bottomTrailing) {
                CardTag(id: CardIds.colors + card.idx + 1).padding(14)
            }
        } onTap: { i in
            Voice.shared.say(c.colors[pool[min(i, pool.count - 1)].idx].word)
        }
        .onAppear { if pool.isEmpty { rebuild() } }
    }

    private func rebuild() {
        pool = c.colors.indices.flatMap { i in (0..<2).map { Card(idx: i, layout: $0) } }.shuffled()
    }

    /// Four unlike shapes, one colour: the colour is all they share.
    private struct FourShapes: View {
        let tint: Color; let size: CGSize
        var body: some View {
            let s = min(size.width, size.height)
            VStack(spacing: s * 0.06) {
                HStack(spacing: s * 0.06) {
                    Swatch(shape: AnyShapeProxy(named: "circle"), tint: tint, side: s * 0.3)
                    Swatch(shape: AnyShapeProxy(named: "square"), tint: tint, side: s * 0.3)
                }
                HStack(spacing: s * 0.06) {
                    Swatch(shape: AnyShapeProxy(named: "triangle"), tint: tint, side: s * 0.3)
                    Swatch(shape: AnyShapeProxy(named: "star"), tint: tint, side: s * 0.3)
                }
            }
        }
    }

    /// Many small pieces at different sizes — the colour survives scale and count.
    private struct Scatter: View {
        let tint: Color; let size: CGSize
        var body: some View {
            let s = min(size.width, size.height)
            Canvas { ctx, sz in
                var rng = SeededRandom(seed: 7)
                for _ in 0..<26 {
                    let d = s * (0.05 + rng.next() * 0.09)
                    let x = rng.next() * (sz.width - d)
                    let y = rng.next() * (sz.height - d)
                    let r = CGRect(x: x, y: y, width: d, height: d)
                    let path = rng.next() < 0.5 ? Path(ellipseIn: r)
                        : Path(roundedRect: r, cornerRadius: d * 0.22)
                    ctx.fill(path, with: .color(tint))
                    // Pale colours need the outline or they disappear on white.
                    ctx.stroke(path, with: .color(Theme.ink.opacity(0.22)), lineWidth: 1)
                }
            }
        }
    }
}

// MARK: - Shapes

struct ShapesView: View {
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0x6FA368)
    private struct Card: Hashable { let idx: Int; let layout: Int }
    @State private var pool: [Card] = []
    @State private var index = 0
    private let palette: [Color] = [Color(hex: 0xD93A32), Color(hex: 0x2F6FD0),
                                    Color(hex: 0xF0B429), Color(hex: 0x7A4FA3)]

    var body: some View {
        DeckScreen(title: "Shapes", count: pool.count, index: $index, accent: accent) { i in
            let card = pool[min(i, max(pool.count - 1, 0))]
            let name = c.shapes[card.idx].word
            AdaptiveCard {
                ZStack {
                    Theme.paper
                    GeometryReader { geo in
                        let s = min(geo.size.width, geo.size.height)
                        Group {
                            if card.layout == 0 {
                                // One shape, four colours — the mirror of a colour card.
                                VStack(spacing: s * 0.06) {
                                    HStack(spacing: s * 0.06) {
                                        AnyShapeProxy(named: name).fill(palette[0]).frame(width: s * 0.3, height: s * 0.3)
                                        AnyShapeProxy(named: name).fill(palette[1]).frame(width: s * 0.3, height: s * 0.3)
                                    }
                                    HStack(spacing: s * 0.06) {
                                        AnyShapeProxy(named: name).fill(palette[2]).frame(width: s * 0.3, height: s * 0.3)
                                        AnyShapeProxy(named: name).fill(palette[3]).frame(width: s * 0.3, height: s * 0.3)
                                    }
                                }
                            } else {
                                // One shape, one colour, four SIZES: a small circle
                                // is still a circle, which is not obvious at three.
                                HStack(alignment: .center, spacing: s * 0.05) {
                                    ForEach([0.40, 0.26, 0.15], id: \.self) { f in
                                        AnyShapeProxy(named: name)
                                            .fill(palette[1])
                                            .frame(width: s * f, height: s * f)
                                    }
                                }
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
            } caption: {
                phonics(name, size: 40)
            }
            .overlay(alignment: .bottomTrailing) {
                CardTag(id: CardIds.shapes + card.idx + 1).padding(14)
            }
        } onTap: { i in
            Voice.shared.say(c.shapes[pool[min(i, pool.count - 1)].idx].word)
        }
        .onAppear { if pool.isEmpty { rebuild() } }
    }

    private func rebuild() {
        pool = c.shapes.indices.flatMap { i in (0..<2).map { Card(idx: i, layout: $0) } }.shuffled()
    }
}

// MARK: - Numbers

struct NumbersView: View {
    /// Screenshot router only: open at a given card so the dice and row layouts
    /// can be looked at without tapping through.
    var start: Int = 0
    @Environment(Settings.self) private var settings
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0xC98A3E)
    private struct Card: Hashable { let n: Int; let layout: Int }
    @State private var pool: [Card] = []
    @State private var index = 0
    @State private var ordered = true

    private let tokens = ["🔵","🟠","🟣","🟢","🔴","🟡","⭐️","🍎","🐟","🌸"]

    var body: some View {
        DeckScreen(title: "Numbers", count: pool.count, index: $index, accent: accent,
                   ordered: $ordered) { i in
            let card = pool[min(i, max(pool.count - 1, 0))]
            AdaptiveCard {
                ZStack {
                    Theme.paper
                    GeometryReader { geo in
                        // The numeral means nothing to a pre-reader, so the count
                        // leads and the numeral supports it.
                        VStack(spacing: geo.size.height * 0.05) {
                            Group {
                                switch card.layout {
                                case 0: Grouped(n: card.n, token: tokens[card.n % tokens.count], size: geo.size)
                                case 1: Dice(n: card.n, tint: accent, size: geo.size)
                                default: Line(n: card.n, token: tokens[(card.n + 4) % tokens.count], size: geo.size)
                                }
                            }
                            .frame(height: geo.size.height * 0.62)
                            Text("\(card.n)")
                                .font(.andika(min(geo.size.height * 0.26, 84), bold: true))
                                .foregroundStyle(accent)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
            } caption: {
                phonics(c.numbers.words[card.n - 1], size: 40)
            }
            .overlay(alignment: .bottomTrailing) {
                CardTag(id: CardIds.numbers + card.n).padding(14)
            }
        } onTap: { i in
            Voice.shared.say(c.numbers.words[pool[min(i, pool.count - 1)].n - 1])
        }
        .onAppear { rebuild(); index = start }
        .onChange(of: settings.numberLevel) { index = 0; rebuild() }
        .onChange(of: ordered) { index = 0; rebuild() }
    }

    private func rebuild() {
        let top = max(settings.numberLevel, 1)
        let cards = (1...top).flatMap { n in (0..<3).map { Card(n: n, layout: $0) } }
        // In order means 1,1,1,2,2,2… so a child meets each number's three
        // arrangements together, which is where the point lands: the count is the
        // same however it is laid out.
        pool = ordered ? cards : cards.shuffled()
    }

    /// Rows of five, because a row of seventeen cannot be counted by eye.
    private struct Grouped: View {
        let n: Int; let token: String; let size: CGSize
        var body: some View {
            let cols = n <= 5 ? n : 5
            let rows = Int(ceil(Double(n) / Double(cols)))
            let cell = min(size.width / CGFloat(cols + 1), size.height / CGFloat(rows + 1))
            VStack(spacing: cell * 0.16) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: cell * 0.16) {
                        ForEach(0..<min(cols, n - r * cols), id: \.self) { _ in
                            Text(token).font(.system(size: cell * 0.78))
                        }
                    }
                }
            }
        }
    }

    /// A dice face, which is the arrangement a child learns to read WITHOUT
    /// counting. Above six it becomes stacked dice, which is still the same trick.
    private struct Dice: View {
        let n: Int; let tint: Color; let size: CGSize
        private static let faces: [[(Int, Int)]] = [
            [], [(1,1)], [(0,0),(2,2)], [(0,0),(1,1),(2,2)],
            [(0,0),(2,0),(0,2),(2,2)], [(0,0),(2,0),(1,1),(0,2),(2,2)],
            [(0,0),(2,0),(0,1),(2,1),(0,2),(2,2)],
        ]
        var body: some View {
            let groups = stride(from: n, to: 0, by: -6).map { min($0, 6) }
            let side = min(size.width / CGFloat(groups.count + 1), size.height * 0.8)
            HStack(spacing: side * 0.14) {
                ForEach(Array(groups.enumerated()), id: \.offset) { _, k in
                    ZStack {
                        RoundedRectangle(cornerRadius: side * 0.16)
                            .fill(Theme.paper)
                            .overlay(RoundedRectangle(cornerRadius: side * 0.16)
                                .strokeBorder(tint.opacity(0.55), lineWidth: 2))
                        let pips = Self.faces[k]
                        ForEach(Array(pips.enumerated()), id: \.offset) { _, p in
                            Circle().fill(tint)
                                .frame(width: side * 0.17, height: side * 0.17)
                                .offset(x: CGFloat(p.0 - 1) * side * 0.27,
                                        y: CGFloat(p.1 - 1) * side * 0.27)
                        }
                    }
                    .frame(width: side, height: side)
                }
            }
        }
    }

    /// One long row. Same count, a shape that looks nothing like the other two.
    private struct Line: View {
        let n: Int; let token: String; let size: CGSize
        var body: some View {
            let cell = min(size.width / CGFloat(n + 1), size.height * 0.5)
            HStack(spacing: cell * 0.14) {
                ForEach(0..<n, id: \.self) { _ in
                    Text(token).font(.system(size: cell * 0.8))
                }
            }
        }
    }
}

// MARK: - drawing helpers

private struct SeededRandom {
    var state: UInt64
    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((state >> 33) % 10_000) / 10_000
    }
}

/// Fills and strokes the SAME path, so a white or cream swatch still has an edge.
/// Drawing a shadow instead was the earlier mistake: a shadow is not a boundary.
struct Swatch: View {
    let shape: AnyShapeProxy
    let tint: Color
    let side: CGFloat
    var body: some View {
        shape.fill(tint)
            .overlay(shape.stroke(Theme.ink.opacity(0.28), lineWidth: 1.2))
            .frame(width: side, height: side)
    }
}

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath(); return p
    }
}

struct Star: Shape {
    var points: Int = 5
    func path(in r: CGRect) -> Path {
        let c = CGPoint(x: r.midX, y: r.midY)
        let outer = min(r.width, r.height) / 2, inner = outer * 0.42
        var p = Path()
        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outer : inner
            let a = -CGFloat.pi / 2 + CGFloat(i) * .pi / CGFloat(points)
            let pt = CGPoint(x: c.x + cos(a) * radius, y: c.y + sin(a) * radius)
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.closeSubpath(); return p
    }
}

/// A regular polygon with a flat bottom, which is how a child is shown them.
private func polygon(_ sides: Int, in r: CGRect) -> Path {
    let c = CGPoint(x: r.midX, y: r.midY)
    let rad = min(r.width, r.height) / 2
    var p = Path()
    for i in 0..<sides {
        let a = -CGFloat.pi / 2 + CGFloat(i) * 2 * .pi / CGFloat(sides)
            + (sides % 2 == 0 ? .pi / CGFloat(sides) : 0)
        let pt = CGPoint(x: c.x + cos(a) * rad, y: c.y + sin(a) * rad)
        i == 0 ? p.move(to: pt) : p.addLine(to: pt)
    }
    p.closeSubpath(); return p
}

/// Chooses a shape by name, so content names a shape and the drawing follows.
struct AnyShapeProxy: Shape {
    let named: String
    func path(in r: CGRect) -> Path {
        let s = min(r.width, r.height)
        switch named {
        case "square":     return RoundedRectangle(cornerRadius: s * 0.07).path(in: r)
        case "rectangle":  return RoundedRectangle(cornerRadius: s * 0.06)
                                    .path(in: CGRect(x: r.minX, y: r.midY - s * 0.32,
                                                     width: r.width, height: s * 0.64))
        case "triangle":   return Triangle().path(in: r)
        case "star":       return Star().path(in: r)
        case "heart":      return heart(in: r)
        case "oval":       return Ellipse().path(in: CGRect(x: r.minX, y: r.midY - s * 0.35,
                                                            width: r.width, height: s * 0.7))
        case "diamond":    return polygon(4, in: r)
        case "pentagon":   return polygon(5, in: r)
        case "hexagon":    return polygon(6, in: r)
        case "octagon":    return polygon(8, in: r)
        case "crescent":   return crescent(in: r)
        case "cross":      return cross(in: r)
        case "arrow":      return arrow(in: r)
        case "ring":       return ring(in: r)
        case "semicircle": return semicircle(in: r)
        default:           return Circle().path(in: r)
        }
    }

    private func heart(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.minX + w / 2, y: r.minY + h * 0.95))
        p.addCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.3),
                   control1: CGPoint(x: r.minX + w * 0.1, y: r.minY + h * 0.74),
                   control2: CGPoint(x: r.minX, y: r.minY + h * 0.52))
        p.addArc(center: CGPoint(x: r.minX + w * 0.25, y: r.minY + h * 0.3), radius: w * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addArc(center: CGPoint(x: r.minX + w * 0.75, y: r.minY + h * 0.3), radius: w * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: CGPoint(x: r.minX + w / 2, y: r.minY + h * 0.95),
                   control1: CGPoint(x: r.maxX, y: r.minY + h * 0.52),
                   control2: CGPoint(x: r.minX + w * 0.9, y: r.minY + h * 0.74))
        p.closeSubpath(); return p
    }

    private func crescent(in r: CGRect) -> Path {
        var p = Path(ellipseIn: r)
        p.addPath(Path(ellipseIn: CGRect(x: r.minX + r.width * 0.28, y: r.minY - r.height * 0.04,
                                         width: r.width * 0.86, height: r.height * 1.02)))
        return p
    }

    private func cross(in r: CGRect) -> Path {
        let t = min(r.width, r.height) * 0.34
        var p = Path()
        p.addRoundedRect(in: CGRect(x: r.midX - t / 2, y: r.minY, width: t, height: r.height),
                         cornerSize: CGSize(width: t * 0.18, height: t * 0.18))
        p.addRoundedRect(in: CGRect(x: r.minX, y: r.midY - t / 2, width: r.width, height: t),
                         cornerSize: CGSize(width: t * 0.18, height: t * 0.18))
        return p
    }

    private func arrow(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY - h * 0.14))
        p.addLine(to: CGPoint(x: r.minX + w * 0.55, y: r.midY - h * 0.14))
        p.addLine(to: CGPoint(x: r.minX + w * 0.55, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.minX + w * 0.55, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + w * 0.55, y: r.midY + h * 0.14))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY + h * 0.14))
        p.closeSubpath(); return p
    }

    private func ring(in r: CGRect) -> Path {
        var p = Path(ellipseIn: r)
        p.addPath(Path(ellipseIn: r.insetBy(dx: r.width * 0.26, dy: r.height * 0.26)))
        return p
    }

    private func semicircle(in r: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: r.midX, y: r.midY + r.height * 0.22),
                 radius: min(r.width, r.height) * 0.48,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.closeSubpath(); return p
    }
}

extension Color {
    init(hexString: String) { self.init(hex: UInt(hexString, radix: 16) ?? 0) }
}
