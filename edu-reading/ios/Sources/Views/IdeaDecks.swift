import SwiftUI

// Colours, shapes and numbers are DRAWN, not sourced — no photographs to hunt,
// nothing to audit, no licences, and every card correct by construction.
//
// Each teaches a PROPERTY rather than a thing, so each needs the app's rule
// applied twice over: vary everything except what is being taught. Three
// different dogs teach "dog"; a single red circle labelled "red" teaches
// "circle" just as readily.
//
// ONE card per item. An earlier version gave each item several layouts, which
// made the decks longer without making them broader — twelve ways to look at a
// square is not the same as knowing twelve shapes. The decks grew by adding
// items instead.

// MARK: - Colours

struct ColorsView: View {
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0x4E8FBF)
    @State private var pool: [Int] = []
    @State private var index = 0

    var body: some View {
        DeckScreen(title: "Colours", count: pool.count, index: $index, accent: accent) { i in
            let idx = pool[min(i, max(pool.count - 1, 0))]
            let swatch = c.colors[idx]
            let tint = Color(hexString: swatch.hex)
            AdaptiveCard {
                ZStack {
                    Theme.paper
                    GeometryReader { geo in
                        FourShapes(tint: tint, size: geo.size)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
            } caption: {
                phonics(swatch.word, size: 40)
            }
            .overlay(alignment: .bottomTrailing) {
                CardTag(id: CardIds.colors + idx + 1).padding(14)
            }
        } onTap: { i in
            Voice.shared.say(c.colors[pool[min(i, pool.count - 1)]].word)
        }
        .onAppear { if pool.isEmpty { rebuild() } }
    }

    private func rebuild() { pool = Array(c.colors.indices).shuffled() }

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

}

// MARK: - Shapes

struct ShapesView: View {
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0x6FA368)
    @State private var pool: [Int] = []
    @State private var index = 0
    private let palette: [Color] = [Color(hex: 0xD93A32), Color(hex: 0x2F6FD0),
                                    Color(hex: 0xF0B429), Color(hex: 0x7A4FA3)]

    var body: some View {
        DeckScreen(title: "Shapes", count: pool.count, index: $index, accent: accent) { i in
            let idx = pool[min(i, max(pool.count - 1, 0))]
            let name = c.shapes[idx].word
            AdaptiveCard {
                ZStack {
                    Theme.paper
                    GeometryReader { geo in
                        let s = min(geo.size.width, geo.size.height)
                        // One shape, four colours — the mirror of a colour card.
                        VStack(spacing: s * 0.06) {
                            HStack(spacing: s * 0.06) {
                                AnyShapeProxy(named: name).fill(palette[0])
                                    .frame(width: s * 0.3, height: s * 0.3)
                                AnyShapeProxy(named: name).fill(palette[1])
                                    .frame(width: s * 0.3, height: s * 0.3)
                            }
                            HStack(spacing: s * 0.06) {
                                AnyShapeProxy(named: name).fill(palette[2])
                                    .frame(width: s * 0.3, height: s * 0.3)
                                AnyShapeProxy(named: name).fill(palette[3])
                                    .frame(width: s * 0.3, height: s * 0.3)
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
            } caption: {
                phonics(name, size: 40)
            }
            .overlay(alignment: .bottomTrailing) {
                CardTag(id: CardIds.shapes + idx + 1).padding(14)
            }
        } onTap: { i in
            Voice.shared.say(c.shapes[pool[min(i, pool.count - 1)]].word)
        }
        .onAppear { if pool.isEmpty { rebuild() } }
    }

    private func rebuild() { pool = Array(c.shapes.indices).shuffled() }
}

// MARK: - Numbers

struct NumbersView: View {
    /// Screenshot router only: open at a given card so the dice and row layouts
    /// can be looked at without tapping through.
    var start: Int = 0
    @Environment(Settings.self) private var settings
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0xC98A3E)
    @State private var pool: [Int] = []
    @State private var index = 0
    @State private var ordered = true

    private let tokens = ["🔵","🟠","🟣","🟢","🔴","🟡","⭐️","🍎","🐟","🌸"]

    var body: some View {
        DeckScreen(title: "Numbers", count: pool.count, index: $index, accent: accent,
                   ordered: $ordered) { i in
            let n = pool[min(i, max(pool.count - 1, 0))]
            AdaptiveCard {
                ZStack {
                    Theme.paper
                    GeometryReader { geo in
                        // The numeral means nothing to a pre-reader, so the count
                        // leads and the numeral supports it.
                        VStack(spacing: geo.size.height * 0.05) {
                            Grouped(n: n, token: tokens[n % tokens.count], size: geo.size)
                                .frame(height: geo.size.height * 0.62)
                            Text("\(n)")
                                .font(.andika(min(geo.size.height * 0.26, 84), bold: true))
                                .foregroundStyle(accent)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
            } caption: {
                phonics(c.numbers.words[n - 1], size: 40)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 16)
            }
            .overlay(alignment: .bottomTrailing) {
                CardTag(id: CardIds.numbers + n).padding(14)
            }
        } onTap: { i in
            Voice.shared.say(c.numbers.words[pool[min(i, pool.count - 1)] - 1])
        }
        .onAppear { rebuild(); index = start }
        .onChange(of: settings.numberLevel) { index = 0; rebuild() }
        .onChange(of: ordered) { index = 0; rebuild() }
    }

    private func rebuild() {
        #if DEBUG
        let a = ProcessInfo.processInfo.arguments
        let override = a.firstIndex(of: "-level").flatMap { i in
            i + 1 < a.count ? Int(a[i + 1]) : nil
        }
        #else
        let override: Int? = nil
        #endif
        let top = max(override ?? settings.numberLevel, 1)
        let cards = Array(1...top)
        pool = ordered ? cards : cards.shuffled()
    }

    /// Rows of five up to twenty, because a row of seventeen cannot be counted by
    /// eye. Past twenty it switches to rows of TEN, which is the hundred-square a
    /// child meets later — and the only arrangement in which forty-two is legible.
    private struct Grouped: View {
        let n: Int; let token: String; let size: CGSize
        var body: some View {
            let cols = n <= 5 ? n : (n <= 20 ? 5 : 10)
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
        case "diamond":    return diamond(in: r)
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

    /// Point at the top, not a square on its corner. polygon(4) cannot be used:
    /// the flat-bottom rotation that makes a hexagon and an octagon sit correctly
    /// turns a four-sided one into an axis-aligned square, so "diamond" and
    /// "square" came out as the same card. It is also narrower than it is tall,
    /// which is what distinguishes a diamond from a tilted square.
    private func diamond(in r: CGRect) -> Path {
        let inset = r.width * 0.12
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - inset, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + inset, y: r.midY))
        p.closeSubpath()
        return p
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

    /// Two arcs meeting at the same two points: the outer left half of a circle,
    /// then a shallower curve back. Subtracting an offset circle by winding was
    /// tried twice and is fragile — this is one closed contour with no holes.
    private func crescent(in r: CGRect) -> Path {
        let rad = min(r.width, r.height) / 2
        let cx = r.midX - rad * 0.10, cy = r.midY
        let top = CGPoint(x: cx, y: cy - rad), bottom = CGPoint(x: cx, y: cy + rad)
        var p = Path()
        p.move(to: top)
        // SwiftUI's y axis points down, so `clockwise: false` is the sweep that
        // goes round the LEFT. Getting this backwards gave a pointed lens.
        p.addArc(center: CGPoint(x: cx, y: cy), radius: rad,
                 startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
        p.addQuadCurve(to: top, control: CGPoint(x: cx + rad * 0.62, y: cy))
        p.closeSubpath()
        _ = bottom
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
        let rad = min(r.width, r.height) / 2
        var p = Path()
        p.move(to: CGPoint(x: r.midX + rad, y: r.midY))
        p.addArc(center: CGPoint(x: r.midX, y: r.midY), radius: rad,
                 startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        p.closeSubpath()
        p.move(to: CGPoint(x: r.midX + rad * 0.52, y: r.midY))
        p.addArc(center: CGPoint(x: r.midX, y: r.midY), radius: rad * 0.52,
                 startAngle: .degrees(360), endAngle: .degrees(0), clockwise: true)
        p.closeSubpath()
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


#if DEBUG
/// Every colour at once. Looking at one card at a time is how "peach" and "brown"
/// both survived three passes: apart they each look fine, together they are the
/// same card twice.
struct ColourSheet: View {
    private let c = ReadingContent.shared
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 10)], spacing: 14) {
                ForEach(c.colors, id: \.word) { s in
                    VStack(spacing: 4) {
                        Swatch(shape: AnyShapeProxy(named: "circle"),
                               tint: Color(hexString: s.hex), side: 70)
                        Text(s.word).font(.andika(12)).foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.paper)
    }
}

/// Every shape at once, so the whole set can be checked in one look rather than
/// paged through sixteen cards. The diamond bug survived because I only ever saw
/// one shape at a time.
struct ShapeSheet: View {
    private let c = ReadingContent.shared
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 10)], spacing: 14) {
                ForEach(c.shapes, id: \.word) { sh in
                    VStack(spacing: 4) {
                        AnyShapeProxy(named: sh.word)
                            .fill(Color(hex: 0x2F6FD0))
                            .frame(width: 70, height: 70)
                        Text(sh.word).font(.andika(12)).foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.paper)
    }
}
#endif
