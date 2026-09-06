import SwiftUI

// Colours, shapes and numbers are DRAWN rather than photographed, which is why
// they can exist at all without another sourcing pass — and drawing them is also
// the right answer pedagogically, because each teaches a PROPERTY rather than a
// thing, and a property has to be shown varying.
//
// The whole app rests on one rule: vary everything except what is being taught.
// Three different dogs teach "dog". So:
//   • a colour card shows several DIFFERENT shapes in one colour
//   • a shape card shows one shape in several DIFFERENT colours
//   • a number card shows a count made of DIFFERENT things
// Otherwise a red circle labelled "red" teaches "circle" just as readily.

// MARK: - Colours

struct ColorsView: View {
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0x4E8FBF)
    @State private var pool: [Int] = []
    @State private var index = 0

    var body: some View {
        DeckScreen(title: "Colours", count: pool.count, index: $index, accent: accent) { i in
            let swatch = c.colors[pool[min(i, pool.count - 1)]]
            AdaptiveCard {
                // Four unlike shapes, one colour: the colour is the only thing
                // they share, so the colour is what the word can attach to.
                GeometryReader { geo in
                    let s = min(geo.size.width, geo.size.height)
                    let tint = Color(hexString: swatch.hex)
                    VStack(spacing: s * 0.07) {
                        HStack(spacing: s * 0.07) {
                            // White would vanish on a white card, so every swatch
                            // carries a faint edge rather than special-casing one.
                            Circle().fill(tint).stroked()
                                .frame(width: s * 0.33, height: s * 0.33)
                            RoundedRectangle(cornerRadius: s * 0.03).fill(tint).stroked()
                                .frame(width: s * 0.33, height: s * 0.33)
                        }
                        HStack(spacing: s * 0.07) {
                            Triangle().fill(tint).stroked().frame(width: s * 0.33, height: s * 0.33)
                            Star(points: 5).fill(tint).stroked().frame(width: s * 0.33, height: s * 0.33)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            } caption: {
                phonics(swatch.word, size: 34).opacity(0.75)
            }
            .overlay(alignment: .topTrailing) {
                CardTag(id: CardIds.colors + pool[min(i, pool.count - 1)] + 1).padding(18)
            }
        } onTap: { i in
            Voice.shared.say(c.colors[pool[min(i, pool.count - 1)]].word)
        }
        .onAppear { if pool.isEmpty { pool = Array(c.colors.indices).shuffled() } }
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
            let shape = c.shapes[pool[min(i, pool.count - 1)]]
            AdaptiveCard {
                // One shape, four colours — the mirror of the colour card.
                GeometryReader { geo in
                    let s = min(geo.size.width, geo.size.height)
                    VStack(spacing: s * 0.07) {
                        HStack(spacing: s * 0.07) {
                            AnyShapeProxy(named: shape.word).fill(palette[0]).frame(width: s * 0.33, height: s * 0.33)
                            AnyShapeProxy(named: shape.word).fill(palette[1]).frame(width: s * 0.33, height: s * 0.33)
                        }
                        HStack(spacing: s * 0.07) {
                            AnyShapeProxy(named: shape.word).fill(palette[2]).frame(width: s * 0.33, height: s * 0.33)
                            AnyShapeProxy(named: shape.word).fill(palette[3]).frame(width: s * 0.33, height: s * 0.33)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            } caption: {
                phonics(shape.word, size: 34).opacity(0.75)
            }
            .overlay(alignment: .topTrailing) {
                CardTag(id: CardIds.shapes + pool[min(i, pool.count - 1)] + 1).padding(18)
            }
        } onTap: { i in
            Voice.shared.say(c.shapes[pool[min(i, pool.count - 1)]].word)
        }
        .onAppear { if pool.isEmpty { pool = Array(c.shapes.indices).shuffled() } }
    }
}

// MARK: - Numbers

struct NumbersView: View {
    @Environment(Settings.self) private var settings
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0xC98A3E)
    @State private var pool: [Int] = []
    @State private var index = 0

    private let tokens = ["🔵", "🟠", "🟣", "🟢", "🔴", "⭐️", "🍎", "🐟"]

    var body: some View {
        DeckScreen(title: "Numbers", count: pool.count, index: $index, accent: accent) { i in
            let n = pool[min(i, pool.count - 1)]
            AdaptiveCard {
                GeometryReader { geo in
                    // The numeral means nothing to a pre-reader; the COUNT is the
                    // lesson, so the objects lead and the numeral supports them.
                    // Grouped in fives, because a row of seventeen is uncountable
                    // by eye and the point is to be able to see the quantity.
                    let cols = n <= 5 ? n : 5
                    let rows = Int(ceil(Double(n) / Double(cols)))
                    let cell = min(geo.size.width / CGFloat(cols + 1),
                                   geo.size.height / CGFloat(rows + 1))
                    VStack(spacing: cell * 0.18) {
                        ForEach(0..<rows, id: \.self) { r in
                            HStack(spacing: cell * 0.18) {
                                ForEach(0..<min(cols, n - r * cols), id: \.self) { _ in
                                    Text(tokens[n % tokens.count])
                                        .font(.system(size: cell * 0.8))
                                }
                            }
                        }
                        Text("\(n)")
                            .font(.andika(cell * 0.9, bold: true))
                            .foregroundStyle(accent)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            } caption: {
                phonics(c.numbers.words[n - 1], size: 34).opacity(0.75)
            }
            .overlay(alignment: .topTrailing) {
                CardTag(id: CardIds.numbers + n).padding(18)
            }
        } onTap: { i in
            Voice.shared.say(c.numbers.words[pool[min(i, pool.count - 1)] - 1])
        }
        .onAppear { rebuild() }
        .onChange(of: settings.numberLevel) { index = 0; rebuild() }
    }

    private func rebuild() {
        pool = Array(1...max(settings.numberLevel, 1)).shuffled()
    }
}

// MARK: - drawing helpers

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

struct Diamond: Shape {
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

struct Star: Shape {
    var points: Int = 5
    func path(in r: CGRect) -> Path {
        let c = CGPoint(x: r.midX, y: r.midY)
        let outer = min(r.width, r.height) / 2
        let inner = outer * 0.42
        var p = Path()
        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outer : inner
            let a = -CGFloat.pi / 2 + CGFloat(i) * .pi / CGFloat(points)
            let pt = CGPoint(x: c.x + cos(a) * radius, y: c.y + sin(a) * radius)
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.closeSubpath()
        return p
    }
}

struct Heart: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: w / 2, y: h))
        p.addCurve(to: CGPoint(x: 0, y: h * 0.3),
                   control1: CGPoint(x: w * 0.1, y: h * 0.78),
                   control2: CGPoint(x: 0, y: h * 0.55))
        p.addArc(center: CGPoint(x: w * 0.25, y: h * 0.3), radius: w * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addArc(center: CGPoint(x: w * 0.75, y: h * 0.3), radius: w * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: CGPoint(x: w / 2, y: h),
                   control1: CGPoint(x: w, y: h * 0.55),
                   control2: CGPoint(x: w * 0.9, y: h * 0.78))
        p.closeSubpath()
        return p
    }
}

/// Lets a shape be chosen by name from content without a switch at every use.
struct AnyShapeProxy: Shape {
    let named: String
    func path(in r: CGRect) -> Path {
        switch named {
        case "square":    return RoundedRectangle(cornerRadius: r.width * 0.08).path(in: r)
        case "rectangle": return RoundedRectangle(cornerRadius: r.width * 0.06)
                                    .path(in: CGRect(x: r.minX, y: r.midY - r.height * 0.32,
                                                     width: r.width, height: r.height * 0.64))
        case "triangle":  return Triangle().path(in: r)
        case "star":      return Star().path(in: r)
        case "heart":     return Heart().path(in: r)
        case "oval":      return Ellipse().path(in: CGRect(x: r.minX, y: r.midY - r.height * 0.35,
                                                           width: r.width, height: r.height * 0.7))
        case "diamond":   return Diamond().path(in: r)
        default:          return Circle().path(in: r)
        }
    }
}

extension Color {
    init(hexString: String) {
        let v = UInt(hexString, radix: 16) ?? 0
        self.init(hex: v)
    }
}

private extension View {
    /// A hairline edge so a pale swatch still has a boundary on a white card.
    func stroked() -> some View {
        overlay(Rectangle().strokeBorder(Theme.ink.opacity(0.10), lineWidth: 0.5)
            .allowsHitTesting(false).opacity(0))
            .compositingGroup()
            .shadow(color: Theme.ink.opacity(0.16), radius: 0.6)
    }
}
