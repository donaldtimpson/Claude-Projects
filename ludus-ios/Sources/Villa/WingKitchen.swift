import SwiftUI

// MARK: - Wing: Kitchen (see VillaEstate.swift)
//
// The culina: whitewashed walls over a red dado, a herringbone brick floor (opus spicatum), a beam
// hung with garlic and onions, a little barred window, and — as in many Pompeian kitchens — the
// household shrine (lararium) painted with its guardian serpent, its lamp always lit. A plank shelf
// waits for the honey and the garum; the bread oven and the cooking hearth stand against the back
// wall, the oil jars, grain mill, market table and fig basket on the floor in front. Smoke rises
// from the oven, pots steam, the mill handle turns. Drawn in unit space like the Workshop.

let kitchenItems: [VillaItem] = [
    .init(id: "kit_figs", name: "Fig Basket", category: .garden, price: .denarii(40), blurb: "Fresh figs from the villa's own trees.", place: "kitchen"),
    .init(id: "kit_honey", name: "Honey Pots", category: .garden, price: .denarii(45), blurb: "Romans sweetened food with honey; sugar was a rare medicine from India.", place: "kitchen"),
    .init(id: "kit_garum", name: "Garum Jar", category: .garden, price: .denarii(50), blurb: "A salty fish sauce Romans put on almost everything.", place: "kitchen"),
    .init(id: "kit_amphorae", name: "Olive Oil Jars", category: .garden, price: .denarii(60), blurb: "Olive oil for cooking, for lamps, and for washing: Romans oiled their skin and scraped it clean.", place: "kitchen"),
    .init(id: "kit_hearth", name: "Cooking Hearth", category: .garden, price: .denarii(80), blurb: "Pots bubbled on a raised stone hearth.", place: "kitchen"),
    .init(id: "kit_quern", name: "Grain Mill", category: .garden, price: .denarii(90), blurb: "Two stones grind wheat into flour.", place: "kitchen"),
    .init(id: "kit_oven", name: "Bread Oven", category: .garden, price: .denarii(105), blurb: "Round loaves were marked in eight slices before baking.", place: "kitchen"),
    .init(id: "kit_table", name: "Market Table", category: .garden, price: .denarii(120), blurb: "Fruit, cheese and eggs, ready to sell.", place: "kitchen"),
]

/// Feet at canvas fractions (x, y), box `size` canvas-widths; `shadow` = width of its floor shadow.
private let kitchenSpots: [String: (x: CGFloat, y: CGFloat, size: CGFloat, shadow: CGFloat)] = [
    "kit_oven": (0.17, 0.69, 0.34, 0.9),
    "kit_hearth": (0.81, 0.68, 0.33, 0.9),
    "kit_honey": (0.425, 0.475, 0.13, 0.0),
    "kit_garum": (0.575, 0.475, 0.12, 0.0),
    "kit_amphorae": (0.11, 0.965, 0.24, 0.8),
    "kit_quern": (0.335, 0.935, 0.22, 0.8),
    "kit_table": (0.625, 0.975, 0.36, 0.9),
    "kit_figs": (0.895, 0.975, 0.17, 0.75),
]

struct KitchenRoom: View {
    let s: WingState
    var body: some View {
        WingRoom(floor: Color(hex: 0xb8714a), floorLine: 0.62) { w, h, t in
            ZStack(alignment: .topLeading) {
                KitchenBackdrop(w: w, h: h, t: t)
                ForEach(kitchenItems.filter { s.has($0.id) }) { item in
                    if let p = kitchenSpots[item.id] {
                        WingSpot(x: p.x, y: p.y, size: p.size, w: w, h: h, lift: s.lift(item.id)) {
                            ZStack(alignment: .bottom) {
                                if p.shadow > 0 {
                                    Ellipse().fill(Color.black.opacity(0.2))
                                        .frame(width: w * p.size * p.shadow, height: w * p.size * 0.09)
                                        .offset(y: w * p.size * 0.035)
                                }
                                kitchenArt(item.id, t: t)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { s.onTap(item.id) }
                        .zIndex(Double(p.y))
                    }
                }
            }
        }
    }
}

struct KitchenThumb: View {
    let id: String
    var body: some View {
        GeometryReader { g in
            let side = min(g.size.width, g.size.height) * 0.92
            kitchenArt(id, t: 0)
                .frame(width: side, height: side)
                .position(x: g.size.width / 2, y: g.size.height - side / 2 - g.size.height * 0.03)
        }
        .clipped()   // smoke and steam stay inside the card's picture
    }
}

@ViewBuilder
private func kitchenArt(_ id: String, t: Double) -> some View {
    switch id {
    case "kit_oven": BreadOven(t: t)
    case "kit_hearth": CookingHearth(t: t)
    case "kit_honey": HoneyPots(t: t)
    case "kit_garum": GarumJar()
    case "kit_amphorae": OilJars()
    case "kit_quern": Quern(t: t)
    case "kit_table": MarketTable()
    case "kit_figs": FigBasket()
    default: EmptyView()
    }
}

// MARK: - Palette and drawing helpers

private enum K {
    static let bronze = Color(hex: 0xb7803d), bronzeHi = Color(hex: 0xebbd6a), bronzeDeep = Color(hex: 0x7a4e20)
    static let wood = Color(hex: 0x94623a), woodHi = Color(hex: 0xbb8653), woodDeep = Color(hex: 0x5e3b1e)
    static let brick = Color(hex: 0xae5b3e), brickDeep = Color(hex: 0x7e3b25), mortar = Color(hex: 0xd9b88f)
    static let stone = Color(hex: 0xb9ab90), stoneDeep = Color(hex: 0x8d7e65)
    static let basalt = Color(hex: 0x77706a), basaltDeep = Color(hex: 0x4c4642)
    static let clay = Color(hex: 0xb5552f), clayHi = Color(hex: 0xd9824f), clayDeep = Color(hex: 0x8a3b1f)
    static let plaster = Color(hex: 0xeee0c0), plasterShade = Color(hex: 0xd9c49a)
    static let fireCore = Color(hex: 0xfff2b0), fireMid = Color(hex: 0xffb440), fireEdge = Color(hex: 0xe2512a)
    static let soot = Color(hex: 0x3a2a22)
    static let crust = Color(hex: 0xc98a45), crustDeep = Color(hex: 0x95592a)
    static let fig = Color(hex: 0x5e2d5a), figHi = Color(hex: 0x8d5384)
    static let honey = Color(hex: 0xeaa82e)
    static let linen = Color(hex: 0xf1e6cc)
}

private func vg(_ a: Color, _ b: Color) -> LinearGradient { LinearGradient(colors: [a, b], startPoint: .top, endPoint: .bottom) }
private func hg(_ a: Color, _ b: Color) -> LinearGradient { LinearGradient(colors: [a, b], startPoint: .leading, endPoint: .trailing) }

/// A shape drawn in unit coordinates: `u(x, y)` maps 0…1 onto the frame.
private struct Pth: Shape {
    let d: (inout Path, (CGFloat, CGFloat) -> CGPoint) -> Void
    init(_ d: @escaping (inout Path, (CGFloat, CGFloat) -> CGPoint) -> Void) { self.d = d }
    func path(in r: CGRect) -> Path {
        var p = Path()
        d(&p, { x, y in CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) })
        return p
    }
    static func poly(_ pts: [(CGFloat, CGFloat)]) -> Pth {
        Pth { p, u in
            p.move(to: u(pts[0].0, pts[0].1))
            for q in pts.dropFirst() { p.addLine(to: u(q.0, q.1)) }
            p.closeSubpath()
        }
    }
}

/// A rectangle with a round top.
private struct ArchShape: Shape {
    func path(in r: CGRect) -> Path {
        let rad = r.width / 2, k: CGFloat = 0.5523
        let cy = r.minY + min(rad, r.height)
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: cy))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY), control1: CGPoint(x: r.minX, y: cy - k * (cy - r.minY)), control2: CGPoint(x: r.midX - k * rad, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: cy), control1: CGPoint(x: r.midX + k * rad, y: r.minY), control2: CGPoint(x: r.maxX, y: cy - k * (cy - r.minY)))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct BrickLines: Shape {
    let rows: Int, cols: Int
    func path(in r: CGRect) -> Path {
        var p = Path()
        let rh = r.height / CGFloat(rows), cw = r.width / CGFloat(cols)
        for i in 0...rows { let y = r.minY + CGFloat(i) * rh; p.move(to: CGPoint(x: r.minX, y: y)); p.addLine(to: CGPoint(x: r.maxX, y: y)) }
        for i in 0..<rows {
            let y0 = r.minY + CGFloat(i) * rh
            var x = r.minX + (i % 2 == 0 ? 0 : cw / 2)
            while x < r.maxX { if x > r.minX { p.move(to: CGPoint(x: x, y: y0)); p.addLine(to: CGPoint(x: x, y: y0 + rh)) }; x += cw }
        }
        return p
    }
}

private struct FlameShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let u = { (x: CGFloat, y: CGFloat) in CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        p.move(to: u(0.5, 0))
        p.addCurve(to: u(1, 0.72), control1: u(0.62, 0.28), control2: u(1, 0.42))
        p.addQuadCurve(to: u(0, 0.72), control: u(0.5, 1.12))
        p.addCurve(to: u(0.5, 0), control1: u(0, 0.42), control2: u(0.38, 0.28))
        p.closeSubpath()
        return p
    }
}

private struct Fire: View {
    let t: Double
    var n = 3
    var body: some View {
        Art { s in
            ForEach(0..<n, id: \.self) { i in
                let fi = Double(i)
                let f = 0.82 + 0.12 * sin(t * 9 + fi * 2.1) + 0.06 * sin(t * 23 + fi * 4)
                let wide: CGFloat = n == 1 ? 0.8 : 0.5
                let x = n == 1 ? 0.1 : CGFloat(fi) / CGFloat(n - 1) * (1 - wide)
                let tall = (i == n / 2 ? 1.0 : 0.72) * f
                FlameShape().fill(LinearGradient(colors: [K.fireEdge, K.fireMid, K.fireCore], startPoint: .top, endPoint: .bottom))
                    .at(x, 1 - tall, wide, tall, s)
                FlameShape().fill(K.fireCore.opacity(0.9))
                    .at(x + wide * 0.3, 1 - tall * 0.5, wide * 0.4, tall * 0.5, s)
            }
        }
    }
}

private struct Art<C: View>: View {
    @ViewBuilder let c: (CGSize) -> C
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .topLeading) { c(g.size) }
                .frame(width: g.size.width, height: g.size.height, alignment: .topLeading)
        }
    }
}

private extension View {
    /// Frames the view to the unit rect (x, y, w, h) of a size-`s` surface and places it there.
    func at(_ x: CGFloat, _ y: CGFloat, _ bw: CGFloat, _ bh: CGFloat, _ s: CGSize) -> some View {
        frame(width: max(0.1, bw * s.width), height: max(0.1, bh * s.height))
            .position(x: (x + bw / 2) * s.width, y: (y + bh / 2) * s.height)
    }
}

// MARK: - The empty room

private struct KitchenBackdrop: View {
    let w: CGFloat, h: CGFloat, t: Double
    var body: some View {
        let fy = h * 0.62
        ZStack(alignment: .topLeading) {
            Rectangle().fill(vg(Color(hex: 0xe6d3ad), K.plaster))
                .frame(width: w * 3, height: fy + h).position(x: w / 2, y: (fy - h) / 2)
            // red dado with an ochre line
            Rectangle().fill(vg(Color(hex: 0xa8432f), Color(hex: 0x8a3324)))
                .frame(width: w * 3, height: h * 0.16).position(x: w / 2, y: fy - h * 0.08)
            Rectangle().fill(Fr.ochre).frame(width: w * 3, height: max(1, h * 0.01)).position(x: w / 2, y: fy - h * 0.16)
            // beam, with garlic and onions hanging from it
            Rectangle().fill(vg(K.woodHi, K.woodDeep)).frame(width: w * 3, height: h * 0.045).position(x: w / 2, y: h * 0.0225)
            ForEach(-4..<13, id: \.self) { i in
                Rectangle().fill(K.woodDeep).frame(width: w * 0.035, height: h * 0.03)
                    .position(x: w * (0.06 + CGFloat(i) * 0.125), y: h * 0.06)
            }
            HangingString(bulb: Color(hex: 0xf3ead8), shade: Color(hex: 0xcbb99a), n: 5)
                .frame(width: w * 0.07, height: h * 0.2).position(x: w * 0.765, y: h * 0.14)
            HangingString(bulb: Color(hex: 0xc9803a), shade: Color(hex: 0x8a4a1c), n: 4)
                .frame(width: w * 0.07, height: h * 0.17).position(x: w * 0.675, y: h * 0.125)
            HerbBunch().frame(width: w * 0.06, height: h * 0.13).position(x: w * 0.33, y: h * 0.1)
            // a small barred window, high on the wall
            KitchenWindow().frame(width: w * 0.12, height: h * 0.13).position(x: w * 0.88, y: h * 0.17)
            // the household shrine
            Lararium(t: t).frame(width: w * 0.2, height: h * 0.28).position(x: w * 0.5, y: h * 0.2)
            // a plank shelf with utensils hanging below
            Shelf().frame(width: w * 0.36, height: h * 0.13).position(x: w * 0.5, y: h * 0.535)
            // herringbone brick floor
            Herringbone().stroke(Color(hex: 0x7e4428).opacity(0.38), lineWidth: 1)
                .frame(width: w * 3, height: h * 1.4).position(x: w / 2, y: fy + h * 0.7)
        }
    }
}

private struct Herringbone: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let cw = r.width / 60, step = cw * 0.9
        var c = 0, x = r.minX
        while x < r.maxX {
            p.move(to: CGPoint(x: x, y: r.minY)); p.addLine(to: CGPoint(x: x, y: r.maxY))
            var y = r.minY
            while y < r.maxY {
                if c % 2 == 0 { p.move(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: x + cw, y: y + cw * 0.6)) }
                else { p.move(to: CGPoint(x: x, y: y + cw * 0.6)); p.addLine(to: CGPoint(x: x + cw, y: y)) }
                y += step
            }
            x += cw; c += 1
        }
        return p
    }
}

private struct HangingString: View {
    let bulb: Color, shade: Color, n: Int
    var body: some View {
        Art { s in
            Rectangle().fill(Color(hex: 0x9c8460)).at(0.48, 0, 0.04, 0.95, s)
            ForEach(0..<n, id: \.self) { i in
                let y = 0.2 + CGFloat(i) * (0.72 / CGFloat(n))
                let x: CGFloat = i % 2 == 0 ? 0.1 : 0.4
                Circle().fill(RadialGradient(colors: [bulb, shade], center: UnitPoint(x: 0.35, y: 0.35), startRadius: 0, endRadius: s.width * 0.3))
                    .at(x, y, 0.55, 0.55 * s.width / s.height, s)
                Pth.poly([(0.4, 1), (0.5, 0), (0.6, 1)]).fill(shade).at(x + 0.2, y - 0.04, 0.15, 0.05, s)
            }
        }
    }
}

private struct HerbBunch: View {
    var body: some View {
        Art { s in
            Rectangle().fill(Color(hex: 0x9c8460)).at(0.47, 0, 0.06, 0.3, s)
            Rectangle().fill(Fr.frame).at(0.3, 0.28, 0.4, 0.06, s)
            ForEach(0..<7, id: \.self) { i in
                let a = -40.0 + Double(i) * 13
                Capsule().fill(i % 2 == 0 ? Fr.leaf : Color(hex: 0x6f9a4e))
                    .frame(width: s.width * 0.22, height: s.height * 0.62)
                    .rotationEffect(.degrees(a), anchor: .top)
                    .position(x: s.width * 0.5, y: s.height * 0.62)
            }
        }
    }
}

private struct KitchenWindow: View {
    var body: some View {
        Art { s in
            Rectangle().fill(vg(K.stone, K.stoneDeep)).at(0, 0, 1, 1, s)
            Rectangle().fill(vg(Color(hex: 0x9cc3cf), Color(hex: 0xf1ddb0))).at(0.12, 0.12, 0.76, 0.72, s)
            Ellipse().fill(Fr.hillBack).at(-0.1, 0.6, 1.0, 0.5, s).mask(Rectangle().at(0.12, 0.12, 0.76, 0.72, s))
            ForEach(0..<3, id: \.self) { i in Rectangle().fill(Color(hex: 0x3d3a3a)).at(0.27 + CGFloat(i) * 0.21, 0.12, 0.05, 0.72, s) }
            Rectangle().fill(Color(hex: 0xe2d4b6)).at(-0.06, 0.84, 1.12, 0.12, s)
        }
    }
}

private struct Lararium: View {
    let t: Double
    var body: some View {
        Art { s in
            // pediment and cornice
            Pth.poly([(0.0, 0.2), (0.5, 0.0), (1.0, 0.2)]).fill(vg(Color(hex: 0xf7ecd4), K.plasterShade)).at(0, 0, 1, 1, s)
            Pth.poly([(0.0, 0.2), (0.5, 0.0), (1.0, 0.2)]).stroke(Fr.ochre, lineWidth: 1.5).at(0, 0, 1, 1, s)
            Circle().fill(Fr.frame).at(0.46, 0.08, 0.08, 0.055, s)
            Rectangle().fill(Fr.ochre).at(-0.02, 0.2, 1.04, 0.05, s)
            // niche
            ArchShape().fill(vg(Color(hex: 0x6b1d14), Color(hex: 0x8f2a1e))).at(0.18, 0.27, 0.64, 0.45, s)
            // columns
            ForEach([0.05, 0.83] as [CGFloat], id: \.self) { x in
                Rectangle().fill(hg(Fr.marble, Fr.marbleShade)).at(x, 0.25, 0.12, 0.48, s)
                Rectangle().fill(Fr.marbleShade).at(x - 0.02, 0.25, 0.16, 0.03, s)
            }
            // the Lar: a little bronze dancer raising a drinking horn
            Circle().fill(K.bronzeHi).at(0.455, 0.36, 0.09, 0.065, s)
            Pth.poly([(0.44, 0.43), (0.56, 0.43), (0.62, 0.66), (0.38, 0.66)]).fill(vg(K.bronzeHi, K.bronzeDeep)).at(0, 0, 1, 1, s)
            Pth { p, u in p.move(to: u(0.55, 0.45)); p.addLine(to: u(0.62, 0.39)) ; p.move(to: u(0.45, 0.46)); p.addLine(to: u(0.38, 0.55)) }
                .stroke(K.bronze, style: StrokeStyle(lineWidth: 1.6, lineCap: .round)).at(0, 0, 1, 1, s)
            Pth { p, u in p.move(to: u(0.58, 0.36)); p.addLine(to: u(0.68, 0.33)); p.addQuadCurve(to: u(0.64, 0.45), control: u(0.7, 0.42)); p.addQuadCurve(to: u(0.58, 0.36), control: u(0.63, 0.38)); p.closeSubpath() }
                .fill(K.bronzeHi).at(0, 0, 1, 1, s)
            Circle().fill(K.bronzeHi).at(0.37, 0.53, 0.05, 0.035, s)
            // ledge with a lamp, always alight
            Rectangle().fill(vg(Fr.marble, Fr.marbleShade)).at(0.0, 0.72, 1.0, 0.05, s)
            let f = 0.85 + 0.15 * sin(t * 10) * sin(t * 2.7)
            Circle().fill(RadialGradient(colors: [K.fireMid.opacity(0.4), .clear], center: .center, startRadius: 0, endRadius: s.width * 0.14)).at(0.08, 0.58, 0.3, 0.2, s)
            FlameShape().fill(LinearGradient(colors: [K.fireEdge, K.fireMid, K.fireCore], startPoint: .top, endPoint: .bottom))
                .at(0.27, 0.70 - 0.06 * f, 0.05, 0.06 * f, s)
            Pth { p, u in p.move(to: u(0.12, 0.69)); p.addQuadCurve(to: u(0.3, 0.7), control: u(0.2, 0.66)); p.addQuadCurve(to: u(0.12, 0.69), control: u(0.16, 0.75)) }
                .fill(vg(K.clayHi, K.clayDeep)).at(0, 0, 1, 1, s)
            // the guardian serpent painted below, slithering toward an altar
            Pth { p, u in
                p.move(to: u(0.02, 0.88))
                p.addCurve(to: u(0.4, 0.88), control1: u(0.12, 0.78), control2: u(0.3, 0.98))
                p.addCurve(to: u(0.72, 0.86), control1: u(0.5, 0.78), control2: u(0.62, 0.96))
            }.stroke(Color(hex: 0x5c7a3a), style: StrokeStyle(lineWidth: 3, lineCap: .round)).at(0, 0, 1, 1, s)
            Pth { p, u in
                p.move(to: u(0.02, 0.88))
                p.addCurve(to: u(0.4, 0.88), control1: u(0.12, 0.78), control2: u(0.3, 0.98))
                p.addCurve(to: u(0.72, 0.86), control1: u(0.5, 0.78), control2: u(0.62, 0.96))
            }.stroke(Color(hex: 0xd9c25a), style: StrokeStyle(lineWidth: 0.8, lineCap: .round, dash: [2, 3])).at(0, 0, 1, 1, s)
            Ellipse().fill(Color(hex: 0x5c7a3a)).at(0.7, 0.84, 0.07, 0.04, s)
            Rectangle().fill(Fr.ochre).at(0.82, 0.83, 0.12, 0.12, s)
            Rectangle().fill(Fr.frame).at(0.8, 0.82, 0.16, 0.02, s)
        }
    }
}

private struct Shelf: View {
    var body: some View {
        Art { s in
            // brackets and plank (plank top sits at y 0.0)
            ForEach([0.1, 0.84] as [CGFloat], id: \.self) { x in
                Pth.poly([(0, 0), (1, 0), (0, 1)]).fill(K.woodDeep).at(x, 0.05, 0.06, 0.2, s)
            }
            Rectangle().fill(vg(K.woodHi, K.wood)).at(0, -0.02, 1, 0.08, s)
            Rectangle().fill(K.woodDeep).at(0, 0.06, 1, 0.015, s)
            // hooks with a ladle, a strainer and a little pan
            Pth { p, u in for x in [0.3, 0.5, 0.7] as [CGFloat] { p.move(to: u(x, 0.07)); p.addLine(to: u(x, 0.16)) } }
                .stroke(Color(hex: 0x3d3a3a), lineWidth: 1).at(0, 0, 1, 1, s)
            Rectangle().fill(K.bronze).at(0.29, 0.15, 0.02, 0.55, s)
            Ellipse().fill(vg(K.bronzeHi, K.bronzeDeep)).at(0.255, 0.66, 0.09, 0.22, s)
            Rectangle().fill(K.bronze).at(0.49, 0.15, 0.02, 0.25, s)
            Circle().fill(vg(K.bronzeHi, K.bronzeDeep)).at(0.44, 0.38, 0.12, 0.36, s)
            ForEach(0..<5, id: \.self) { i in
                Circle().fill(K.bronzeDeep).at(0.47 + CGFloat(i % 3) * 0.025, 0.48 + CGFloat(i / 3) * 0.1, 0.012, 0.035, s)
            }
            Rectangle().fill(K.bronzeDeep).at(0.69, 0.15, 0.02, 0.3, s)
            Circle().fill(RadialGradient(colors: [K.bronzeHi, K.bronzeDeep], center: .center, startRadius: 0, endRadius: s.width * 0.07)).at(0.63, 0.44, 0.14, 0.42, s)
        }
    }
}

// MARK: - The items

private struct BreadOven: View {
    let t: Double
    var body: some View {
        Art { s in
            let glow = 0.8 + 0.2 * sin(t * 2.2) * sin(t * 1.3 + 1)
            // smoke from the flue, rising and fading
            ForEach(0..<4, id: \.self) { i in
                let ph = (t * 0.22 + Double(i) * 0.25).truncatingRemainder(dividingBy: 1)
                let sz = 0.1 + 0.16 * ph
                Circle().fill(Color(hex: 0x9a9088).opacity(0.5 * (1 - ph)))
                    .at(0.5 - sz / 2 + 0.12 * ph + 0.03 * sin(ph * 9), 0.04 - 0.62 * ph, sz, sz, s)
            }
            Rectangle().fill(vg(Color(hex: 0xa86140), K.brickDeep)).at(0.43, 0.02, 0.14, 0.18, s)
            Rectangle().fill(K.brickDeep).at(0.41, 0.01, 0.18, 0.03, s)
            // brick base with a wood store
            Rectangle().fill(vg(K.brick, K.brickDeep)).at(0.02, 0.62, 0.96, 0.38, s)
            BrickLines(rows: 4, cols: 6).stroke(K.mortar.opacity(0.5), lineWidth: 1).at(0.02, 0.62, 0.96, 0.38, s)
            ArchShape().fill(K.soot).at(0.3, 0.75, 0.4, 0.25, s)
            ForEach(0..<5, id: \.self) { i in
                let x = 0.33 + CGFloat(i % 3) * 0.11, y = 0.9 - CGFloat(i / 3) * 0.08
                Circle().fill(K.woodHi).overlay(Circle().stroke(K.woodDeep, lineWidth: 1).padding(2)).at(x, y, 0.11, 0.09, s)
            }
            // the dome
            Pth { p, u in p.move(to: u(0.05, 0.64)); p.addCurve(to: u(0.5, 0.14), control1: u(0.05, 0.3), control2: u(0.25, 0.14)); p.addCurve(to: u(0.95, 0.64), control1: u(0.75, 0.14), control2: u(0.95, 0.3)); p.closeSubpath() }
                .fill(LinearGradient(colors: [Color(hex: 0xe8c79a), Color(hex: 0xcf9f6c), Color(hex: 0xa8714a)], startPoint: .topLeading, endPoint: .bottomTrailing)).at(0, 0, 1, 1, s)
            Pth { p, u in for y in [0.3, 0.42, 0.53] as [CGFloat] { p.move(to: u(0.06, y + 0.04)); p.addQuadCurve(to: u(0.94, y + 0.04), control: u(0.5, y - 0.05)) } }
                .stroke(Color(hex: 0x9a6a44).opacity(0.35), lineWidth: 1).at(0, 0, 1, 1, s)
                .mask(Pth { p, u in p.move(to: u(0.05, 0.64)); p.addCurve(to: u(0.5, 0.14), control1: u(0.05, 0.3), control2: u(0.25, 0.14)); p.addCurve(to: u(0.95, 0.64), control1: u(0.75, 0.14), control2: u(0.95, 0.3)); p.closeSubpath() }.at(0, 0, 1, 1, s))
            // mouth, glowing, a loaf inside
            ArchShape().fill(Color(hex: 0xc9a67a)).at(0.27, 0.32, 0.46, 0.32, s)
            ArchShape().fill(K.soot).at(0.31, 0.36, 0.38, 0.28, s)
            ArchShape().fill(RadialGradient(colors: [K.fireMid.opacity(0.85 * glow), K.fireEdge.opacity(0.3), .clear], center: .bottom, startRadius: 0, endRadius: s.width * 0.22)).at(0.31, 0.36, 0.38, 0.28, s)
            Ellipse().fill(K.crustDeep).at(0.4, 0.54, 0.2, 0.07, s)
            // stone ledge and a finished loaf, marked in eight
            RoundedRectangle(cornerRadius: 1.5).fill(vg(Color(hex: 0xd6caae), K.stoneDeep)).at(0.18, 0.62, 0.64, 0.05, s)
            Loaf().at(0.6, 0.5, 0.3, 0.13, s)
        }
    }
}

/// A Roman round loaf (panis quadratus), scored into eight wedges, tied round with a cord.
private struct Loaf: View {
    var body: some View {
        Art { s in
            Ellipse().fill(K.crustDeep).at(0, 0.18, 1, 0.82, s)
            Ellipse().fill(RadialGradient(colors: [Color(hex: 0xe0a85e), K.crust], center: UnitPoint(x: 0.4, y: 0.35), startRadius: 0, endRadius: s.width * 0.5)).at(0, 0, 1, 0.82, s)
            Pth { p, u in
                for k in 0..<4 {
                    let a = Double(k) * .pi / 4
                    p.move(to: u(0.5 + 0.46 * CGFloat(cos(a)), 0.41 + 0.38 * CGFloat(sin(a))))
                    p.addLine(to: u(0.5 - 0.46 * CGFloat(cos(a)), 0.41 - 0.38 * CGFloat(sin(a))))
                }
            }.stroke(K.crustDeep, lineWidth: 1).at(0, 0, 1, 1, s)
            Ellipse().stroke(K.crustDeep.opacity(0.8), lineWidth: 1).at(0.2, 0.17, 0.6, 0.48, s)
        }
    }
}

private struct CookingHearth: View {
    let t: Double
    var body: some View {
        Art { s in
            // steam from the cauldron
            ForEach(0..<4, id: \.self) { i in
                let ph = (t * 0.35 + Double(i) * 0.25).truncatingRemainder(dividingBy: 1)
                let sz = 0.07 + 0.1 * ph
                Circle().fill(Color.white.opacity(0.6 * (1 - ph)))
                    .at(0.3 - sz / 2 + 0.05 * sin(ph * 7 + Double(i)), 0.16 - 0.32 * ph, sz, sz, s)
            }
            // plastered masonry body, two arches stacked with firewood
            Rectangle().fill(vg(Color(hex: 0xeadbb8), Color(hex: 0xcdb48a))).at(0.04, 0.5, 0.92, 0.5, s)
            ForEach([0.12, 0.56] as [CGFloat], id: \.self) { x in
                ArchShape().fill(K.soot).at(x, 0.66, 0.32, 0.34, s)
                ForEach(0..<5, id: \.self) { i in
                    let lx = x + 0.02 + CGFloat(i % 3) * 0.095, ly = 0.9 - CGFloat(i / 3) * 0.085
                    Circle().fill(K.woodHi).overlay(Circle().stroke(K.woodDeep, lineWidth: 1).padding(2)).at(lx, ly, 0.095, 0.085, s)
                }
            }
            Rectangle().fill(Color(hex: 0xa8432f)).at(0.04, 0.54, 0.92, 0.03, s)
            // stone top with embers
            RoundedRectangle(cornerRadius: 2).fill(vg(Color(hex: 0xd6caae), K.stoneDeep)).at(0.0, 0.46, 1.0, 0.07, s)
            Ellipse().fill(K.soot).at(0.1, 0.41, 0.8, 0.08, s)
            ForEach(0..<6, id: \.self) { i in
                Ellipse().fill(K.fireEdge).opacity(0.5 + 0.4 * sin(t * 3 + Double(i)))
                    .at(0.14 + CGFloat(i) * 0.12, 0.43, 0.08, 0.035, s)
            }
            Fire(t: t, n: 3).at(0.16, 0.3, 0.26, 0.15, s)
            Fire(t: t + 1.3, n: 2).at(0.62, 0.34, 0.2, 0.11, s)
            // tripod and bronze cauldron, bubbling, a ladle in it
            Pth { p, u in p.move(to: u(0.16, 0.46)); p.addLine(to: u(0.22, 0.32)); p.move(to: u(0.44, 0.46)); p.addLine(to: u(0.38, 0.32)) }
                .stroke(Color(hex: 0x3d3a3a), style: StrokeStyle(lineWidth: 2, lineCap: .round)).at(0, 0, 1, 1, s)
            Rectangle().fill(K.bronzeDeep).at(0.37, 0.06, 0.02, 0.2, s)
            Pth { p, u in p.move(to: u(0.12, 0.17)); p.addLine(to: u(0.48, 0.17)); p.addQuadCurve(to: u(0.3, 0.38), control: u(0.5, 0.38)); p.addQuadCurve(to: u(0.12, 0.17), control: u(0.1, 0.38)) }
                .fill(LinearGradient(colors: [K.bronzeHi, K.bronze, K.bronzeDeep], startPoint: .topLeading, endPoint: .bottomTrailing)).at(0, 0, 1, 1, s)
            Ellipse().fill(Color(hex: 0x9a6a3a)).at(0.12, 0.15, 0.36, 0.05, s)
            ForEach(0..<3, id: \.self) { i in
                let ph = (t * 1.3 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
                Circle().stroke(Color(hex: 0xd9b48a), lineWidth: 1).opacity(1 - ph)
                    .at(0.18 + CGFloat(i) * 0.09, 0.15 - 0.02 * ph, 0.03 + 0.02 * ph, 0.03 + 0.02 * ph, s)
            }
            Ellipse().stroke(K.bronzeDeep, lineWidth: 1).at(0.12, 0.15, 0.36, 0.05, s)
            // frying pan (patella) with two eggs, handle out to the right
            Capsule().fill(K.bronzeDeep).frame(width: s.width * 0.24, height: s.width * 0.03)
                .rotationEffect(.degrees(-8)).position(x: s.width * 0.9, y: s.height * 0.33)
            Ellipse().fill(vg(K.bronze, K.bronzeDeep)).at(0.52, 0.31, 0.32, 0.08, s)
            Ellipse().fill(Color(hex: 0x3d2e22)).at(0.54, 0.31, 0.28, 0.055, s)
            ForEach([0.57, 0.68] as [CGFloat], id: \.self) { x in
                Ellipse().fill(Color(hex: 0xfaf4e6)).at(x, 0.315, 0.12, 0.045, s)
                Circle().fill(Color(hex: 0xf5b62e)).at(x + 0.04, 0.322, 0.04, 0.03, s)
            }
        }
    }
}

private struct HoneyPots: View {
    let t: Double
    var body: some View {
        Art { s in
            // covered pot, left
            Pot(color: K.clay).at(0.0, 0.42, 0.34, 0.58, s)
            Pth { p, u in p.move(to: u(0.03, 0.5)); p.addQuadCurve(to: u(0.31, 0.5), control: u(0.17, 0.36)); p.addLine(to: u(0.28, 0.6)); p.addQuadCurve(to: u(0.06, 0.6), control: u(0.17, 0.64)); p.closeSubpath() }
                .fill(vg(K.linen, Color(hex: 0xd8c8a4))).at(0, 0, 1, 1, s)
            Rectangle().fill(Fr.frame).at(0.06, 0.56, 0.22, 0.025, s)
            // big open pot, honey brimming over, a wooden dipper
            Pot(color: Color(hex: 0xc56a38)).at(0.28, 0.24, 0.46, 0.76, s)
            Ellipse().fill(vg(Color(hex: 0xf7c650), K.honey)).at(0.38, 0.26, 0.26, 0.07, s)
            Pth { p, u in p.move(to: u(0.43, 0.29)); p.addLine(to: u(0.5, 0.29)); p.addQuadCurve(to: u(0.47, 0.46), control: u(0.5, 0.42)); p.addQuadCurve(to: u(0.43, 0.29), control: u(0.44, 0.4)) }
                .fill(K.honey).at(0, 0, 1, 1, s)
            Capsule().fill(K.woodHi).frame(width: s.width * 0.05, height: s.height * 0.42)
                .rotationEffect(.degrees(28)).position(x: s.width * 0.62, y: s.height * 0.16)
            Ellipse().fill(K.honey).frame(width: s.width * 0.11, height: s.height * 0.08)
                .rotationEffect(.degrees(28)).position(x: s.width * 0.55, y: s.height * 0.31)
            // small covered pot, right
            Pot(color: K.clayDeep).at(0.7, 0.56, 0.28, 0.44, s)
            Pth { p, u in p.move(to: u(0.72, 0.62)); p.addQuadCurve(to: u(0.96, 0.62), control: u(0.84, 0.5)); p.addLine(to: u(0.94, 0.7)); p.addQuadCurve(to: u(0.74, 0.7), control: u(0.84, 0.73)); p.closeSubpath() }
                .fill(vg(K.linen, Color(hex: 0xd8c8a4))).at(0, 0, 1, 1, s)
            Rectangle().fill(Fr.frame).at(0.75, 0.67, 0.18, 0.022, s)
            // a bee who found it
            let a = t * 1.8
            KBee(t: t, facing: sin(a) > 0 ? -1 : 1).frame(width: s.width * 0.12, height: s.width * 0.09)
                .position(x: s.width * (0.6 + 0.22 * CGFloat(cos(a))), y: s.height * (0.1 + 0.06 * CGFloat(sin(a * 2))))
        }
    }
}

/// A little honeybee: striped ochre body, a dark head and two fluttering wings.
private struct KBee: View {
    let t: Double
    let facing: CGFloat
    var body: some View {
        let flap = 0.55 + 0.45 * abs(sin(t * 38))
        Art { s in
            ForEach([0.0, 1.0], id: \.self) { k in
                Ellipse().fill(Color.white.opacity(0.75)).overlay(Ellipse().stroke(Color(hex: 0x8a7a66).opacity(0.6), lineWidth: 0.4))
                    .frame(width: s.width * 0.36, height: s.height * 0.42 * flap)
                    .rotationEffect(.degrees(k == 0 ? -25 : 15))
                    .position(x: s.width * (0.42 + 0.14 * k), y: s.height * 0.3)
            }
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0xf2c24a), Color(hex: 0xc98a1c)], startPoint: .top, endPoint: .bottom))
                .at(0.22, 0.4, 0.6, 0.48, s)
            ForEach([0.4, 0.56] as [CGFloat], id: \.self) { x in
                Capsule().fill(Color(hex: 0x3a2814)).at(x, 0.42, 0.07, 0.44, s)
            }
            Circle().fill(Color(hex: 0x3a2814)).at(0.06, 0.44, 0.24, 0.32, s)
            Pth.poly([(0.8, 0.6), (0.98, 0.66), (0.8, 0.72)]).fill(Color(hex: 0x3a2814)).at(0, 0, 1, 1, s)
        }
        .scaleEffect(x: facing, y: 1)
    }
}

/// An apple: a dimpled round fruit with a stem and one leaf.
private struct KApple: View {
    let hi: Color, lo: Color
    var body: some View {
        Art { s in
            Pth { p, u in
                p.move(to: u(0.5, 0.22))
                p.addCurve(to: u(0.5, 0.98), control1: u(1.06, -0.02), control2: u(1.02, 0.98))
                p.addCurve(to: u(0.5, 0.22), control1: u(-0.02, 0.98), control2: u(-0.06, -0.02))
                p.closeSubpath()
            }
            .fill(RadialGradient(colors: [hi, lo], center: UnitPoint(x: 0.35, y: 0.4), startRadius: 0, endRadius: s.width * 0.6))
            .at(0, 0, 1, 1, s)
            Ellipse().fill(Color.white.opacity(0.35)).at(0.22, 0.34, 0.14, 0.18, s)
            Pth { p, u in p.move(to: u(0.5, 0.28)); p.addQuadCurve(to: u(0.58, 0.02), control: u(0.5, 0.1)) }
                .stroke(Color(hex: 0x5a3a1c), style: StrokeStyle(lineWidth: max(0.8, s.width * 0.08), lineCap: .round)).at(0, 0, 1, 1, s)
            Ellipse().fill(Fr.leaf).frame(width: s.width * 0.34, height: s.height * 0.15)
                .rotationEffect(.degrees(-20)).position(x: s.width * 0.74, y: s.height * 0.1)
        }
    }
}

/// A pomegranate: a deep red globe topped with its little spiky crown.
private struct KPomegranate: View {
    var body: some View {
        Art { s in
            Pth.poly([(0.36, 0.26), (0.32, 0.02), (0.43, 0.12), (0.5, -0.02), (0.57, 0.12), (0.68, 0.02), (0.64, 0.26)])
                .fill(Color(hex: 0x8e2230)).at(0, 0, 1, 1, s)
            Ellipse().fill(RadialGradient(colors: [Color(hex: 0xd2485a), Color(hex: 0x7c1828)], center: UnitPoint(x: 0.36, y: 0.38), startRadius: 0, endRadius: s.width * 0.6))
                .at(0.02, 0.18, 0.96, 0.82, s)
            Pth.poly([(0.38, 0.24), (0.42, 0.12), (0.5, 0.2), (0.58, 0.12), (0.62, 0.24)]).fill(Color(hex: 0xa52a3a)).at(0, 0, 1, 1, s)
            Ellipse().fill(Color.white.opacity(0.3)).at(0.2, 0.34, 0.16, 0.16, s)
        }
    }
}

/// A round-bellied terracotta pot with a lip, filling its frame.
private struct Pot: View {
    let color: Color
    var body: some View {
        Art { s in
            PotShape().fill(color).at(0, 0, 1, 1, s)
            PotShape().fill(LinearGradient(colors: [Color.white.opacity(0.22), .clear, Color.black.opacity(0.28)], startPoint: .leading, endPoint: .trailing)).at(0, 0, 1, 1, s)
            Capsule().fill(color).brightness(0.08).at(0.14, 0.02, 0.72, 0.08, s)
        }
    }
}

private struct PotShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let u = { (x: CGFloat, y: CGFloat) in CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        p.move(to: u(0.2, 0.06)); p.addLine(to: u(0.8, 0.06))
        p.addQuadCurve(to: u(0.72, 0.2), control: u(0.72, 0.1))
        p.addCurve(to: u(0.66, 1), control1: u(1.08, 0.38), control2: u(0.98, 0.94))
        p.addLine(to: u(0.34, 1))
        p.addCurve(to: u(0.28, 0.2), control1: u(0.02, 0.94), control2: u(-0.08, 0.38))
        p.addQuadCurve(to: u(0.2, 0.06), control: u(0.28, 0.1))
        p.closeSubpath()
        return p
    }
}

private struct GarumJar: View {
    var body: some View {
        Art { s in
            // the handle, behind the neck
            Pth { p, u in p.move(to: u(0.6, 0.14)); p.addQuadCurve(to: u(0.74, 0.44), control: u(0.88, 0.14)) }
                .stroke(K.clayDeep, style: StrokeStyle(lineWidth: s.width * 0.06, lineCap: .round)).at(0, 0, 1, 1, s)
            // a tall one-handled jug (urceus)
            Pth { p, u in
                p.move(to: u(0.38, 0.04)); p.addLine(to: u(0.62, 0.04))
                p.addLine(to: u(0.58, 0.28))
                p.addCurve(to: u(0.66, 0.98), control1: u(0.86, 0.42), control2: u(0.84, 0.86))
                p.addLine(to: u(0.34, 0.98))
                p.addCurve(to: u(0.42, 0.28), control1: u(0.16, 0.86), control2: u(0.14, 0.42))
                p.closeSubpath()
            }.fill(LinearGradient(colors: [Color(hex: 0xe0a070), Color(hex: 0xc07a4a), Color(hex: 0x8a5030)], startPoint: .leading, endPoint: .trailing)).at(0, 0, 1, 1, s)
            Capsule().fill(Color(hex: 0xd99a6a)).at(0.34, 0.02, 0.32, 0.05, s)
            Capsule().fill(Color.white.opacity(0.25)).at(0.3, 0.44, 0.05, 0.36, s)
            // a painted label: a fish, and the word for what's inside
            Pth { p, u in
                p.move(to: u(0.36, 0.55)); p.addQuadCurve(to: u(0.6, 0.55), control: u(0.48, 0.47))
                p.addLine(to: u(0.68, 0.5)); p.addLine(to: u(0.68, 0.6)); p.addLine(to: u(0.6, 0.55))
                p.addQuadCurve(to: u(0.36, 0.55), control: u(0.48, 0.63))
                p.closeSubpath()
            }.fill(Color(hex: 0x2f5f78)).at(0, 0, 1, 1, s)
            Circle().fill(Color.white).at(0.4, 0.535, 0.03, 0.03, s)
            Text("GARVM").font(.system(size: max(4, s.width * 0.11), weight: .heavy, design: .serif)).foregroundStyle(Color(hex: 0x3a1d10))
                .minimumScaleFactor(0.5).lineLimit(1)
                .at(0.24, 0.66, 0.52, 0.1, s)
        }
    }
}

private struct Amphora: View {
    let color: Color
    var body: some View {
        Art { s in
            Pth { p, u in
                p.move(to: u(0.42, 0.08)); p.addQuadCurve(to: u(0.18, 0.3), control: u(0.12, 0.08))
                p.move(to: u(0.58, 0.08)); p.addQuadCurve(to: u(0.82, 0.3), control: u(0.88, 0.08))
            }.stroke(color.opacity(0.85), style: StrokeStyle(lineWidth: s.width * 0.07, lineCap: .round)).at(0, 0, 1, 1, s)
            Pth { p, u in
                p.move(to: u(0.4, 0.03)); p.addLine(to: u(0.6, 0.03)); p.addLine(to: u(0.58, 0.2))
                p.addCurve(to: u(0.52, 0.94), control1: u(1.05, 0.28), control2: u(0.86, 0.66))
                p.addLine(to: u(0.5, 1.0)); p.addLine(to: u(0.48, 0.94))
                p.addCurve(to: u(0.42, 0.2), control1: u(0.14, 0.66), control2: u(-0.05, 0.28))
                p.closeSubpath()
            }.fill(LinearGradient(colors: [color.opacity(0.8), color, Color.black.opacity(0.0)], startPoint: .leading, endPoint: .trailing))
            .background(
                Pth { p, u in
                    p.move(to: u(0.4, 0.03)); p.addLine(to: u(0.6, 0.03)); p.addLine(to: u(0.58, 0.2))
                    p.addCurve(to: u(0.52, 0.94), control1: u(1.05, 0.28), control2: u(0.86, 0.66))
                    p.addLine(to: u(0.5, 1.0)); p.addLine(to: u(0.48, 0.94))
                    p.addCurve(to: u(0.42, 0.2), control1: u(0.14, 0.66), control2: u(-0.05, 0.28))
                    p.closeSubpath()
                }.fill(color.opacity(0.7)).brightness(-0.15)
            )
            .at(0, 0, 1, 1, s)
            Capsule().fill(color).brightness(0.08).at(0.36, 0.0, 0.28, 0.05, s)
            Capsule().fill(Color.white.opacity(0.22)).at(0.26, 0.3, 0.06, 0.3, s)
            // painted note of the contents (titulus pictus)
            Pth { p, u in for i in 0..<3 { let y = 0.36 + CGFloat(i) * 0.05; p.move(to: u(0.42, y)); p.addLine(to: u(0.6 - CGFloat(i) * 0.04, y)) } }
                .stroke(Color(hex: 0x2a1a10).opacity(0.75), lineWidth: 1).at(0, 0, 1, 1, s)
        }
    }
}

private struct OilJars: View {
    var body: some View {
        Art { s in
            // two amphorae in a wooden rack, a small oil jug at their feet
            Rectangle().fill(K.woodDeep).at(0.04, 0.42, 0.05, 0.58, s)
            Rectangle().fill(K.woodDeep).at(0.9, 0.42, 0.05, 0.58, s)
            Amphora(color: Color(hex: 0xc9764a)).at(0.03, 0.0, 0.48, 0.98, s)
            Amphora(color: Color(hex: 0xb5603a)).rotationEffect(.degrees(6)).at(0.46, 0.06, 0.46, 0.92, s)
            Rectangle().fill(vg(K.woodHi, K.wood)).at(0.0, 0.5, 1.0, 0.07, s)
            Rectangle().fill(K.woodDeep).at(0.0, 0.565, 1.0, 0.015, s)
            // an oil jug
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0xe0a070), Color(hex: 0x9a5a34)], startPoint: .leading, endPoint: .trailing)).at(0.66, 0.82, 0.22, 0.18, s)
            Rectangle().fill(Color(hex: 0xb77548)).at(0.73, 0.76, 0.08, 0.08, s)
            Capsule().fill(Color(hex: 0xd0905e)).at(0.71, 0.74, 0.12, 0.03, s)
            Ellipse().fill(Color(hex: 0xb9a23a)).at(0.735, 0.738, 0.07, 0.02, s)
        }
    }
}

private struct Quern: View {
    let t: Double
    var body: some View {
        Art { s in
            let a = t * 1.1
            let hx = 0.36 + 0.22 * CGFloat(cos(a)), hy = 0.47 + 0.05 * CGFloat(sin(a))
            let front = sin(a) > 0
            // a sack of grain, ears of wheat poking out
            Pth { p, u in
                p.move(to: u(0.66, 0.5)); p.addQuadCurve(to: u(0.94, 0.5), control: u(0.8, 0.58))
                p.addQuadCurve(to: u(0.96, 0.98), control: u(1.04, 0.8))
                p.addLine(to: u(0.62, 0.98)); p.addQuadCurve(to: u(0.66, 0.5), control: u(0.56, 0.8)); p.closeSubpath()
            }.fill(LinearGradient(colors: [Color(hex: 0xd8c08e), Color(hex: 0xa88a58)], startPoint: .leading, endPoint: .trailing)).at(0, 0, 1, 1, s)
            Rectangle().fill(Color(hex: 0x8a6a3a)).at(0.68, 0.5, 0.24, 0.03, s)
            ForEach(0..<4, id: \.self) { i in
                Capsule().fill(Color(hex: 0xd9a944)).frame(width: s.width * 0.024, height: s.height * 0.14)
                    .rotationEffect(.degrees(-24 + Double(i) * 16))
                    .position(x: s.width * (0.74 + CGFloat(i) * 0.045), y: s.height * 0.43)
            }
            // flour spilled on the board
            Ellipse().fill(vg(K.woodHi, K.woodDeep)).at(0.0, 0.84, 0.72, 0.14, s)
            Ellipse().fill(Color(hex: 0xf6eedb)).at(0.04, 0.82, 0.64, 0.1, s)
            // lower stone
            Rectangle().fill(hg(K.basalt, K.basaltDeep)).at(0.1, 0.66, 0.52, 0.2, s)
            Ellipse().fill(hg(K.basalt, K.basaltDeep)).at(0.1, 0.8, 0.52, 0.1, s)
            if !front { Handle().at(hx - 0.03, hy - 0.3, 0.06, 0.32, s) }
            // upper stone with its grain hole
            Rectangle().fill(hg(Color(hex: 0x8a837c), K.basaltDeep)).at(0.12, 0.5, 0.48, 0.16, s)
            Ellipse().fill(hg(Color(hex: 0x8a837c), K.basaltDeep)).at(0.12, 0.61, 0.48, 0.1, s)
            Ellipse().stroke(Color(hex: 0xf6eedb), lineWidth: 1.2).at(0.11, 0.62, 0.5, 0.1, s)
                .mask(Rectangle().at(0.0, 0.67, 1, 0.1, s))
            Ellipse().fill(vg(Color(hex: 0xa29b93), K.basalt)).at(0.12, 0.42, 0.48, 0.12, s)
            ForEach(0..<10, id: \.self) { i in
                Circle().fill(Color.black.opacity(0.18)).at(0.15 + CGFloat((i * 37) % 40) / 100, 0.53 + CGFloat((i * 13) % 20) / 100, 0.015, 0.015, s)
            }
            Ellipse().fill(K.basaltDeep).at(0.29, 0.455, 0.14, 0.05, s)
            ForEach(0..<4, id: \.self) { i in Circle().fill(Color(hex: 0xd9a944)).at(0.31 + CGFloat(i) * 0.025, 0.46 + CGFloat(i % 2) * 0.012, 0.02, 0.02, s) }
            if front { Handle().at(hx - 0.03, hy - 0.3, 0.06, 0.32, s) }
            // a little flour heap in front
            Ellipse().fill(Color(hex: 0xfbf6ea)).at(0.24, 0.86, 0.22, 0.07, s)
        }
    }
}

private struct Handle: View {
    var body: some View {
        Capsule().fill(hg(K.woodHi, K.woodDeep))
    }
}

private struct MarketTable: View {
    var body: some View {
        Art { s in
            // a crate of cabbages beneath
            Rectangle().fill(hg(K.woodHi, K.wood)).at(0.3, 0.8, 0.4, 0.18, s)
            Pth { p, u in p.move(to: u(0.3, 0.86)); p.addLine(to: u(0.7, 0.86)); p.move(to: u(0.3, 0.92)); p.addLine(to: u(0.7, 0.92)) }
                .stroke(K.woodDeep.opacity(0.6), lineWidth: 1).at(0, 0, 1, 1, s)
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(RadialGradient(colors: [Color(hex: 0xa8cf7a), Color(hex: 0x5f8f3e)], center: .center, startRadius: 0, endRadius: s.width * 0.06))
                    .at(0.33 + CGFloat(i) * 0.115, 0.73, 0.12, 0.12, s)
            }
            // legs and stretcher
            ForEach([0.07, 0.87] as [CGFloat], id: \.self) { x in Rectangle().fill(hg(K.wood, K.woodDeep)).at(x, 0.52, 0.05, 0.48, s) }
            Rectangle().fill(K.woodDeep).at(0.07, 0.86, 0.85, 0.025, s)
            // top and apron
            Rectangle().fill(vg(K.woodHi, K.wood)).at(0.02, 0.44, 0.96, 0.06, s)
            Rectangle().fill(K.woodDeep).at(0.04, 0.5, 0.92, 0.04, s)
            // a wheel of cheese with a wedge cut away
            Rectangle().fill(vg(Color(hex: 0xe9b850), Color(hex: 0xc9952e))).at(0.05, 0.33, 0.26, 0.11, s)
            Ellipse().fill(Color(hex: 0xc9952e)).at(0.05, 0.4, 0.26, 0.06, s)
            Ellipse().fill(Color(hex: 0xf6d78a)).at(0.05, 0.3, 0.26, 0.06, s)
            Pth.poly([(0.18, 0.33), (0.31, 0.33), (0.31, 0.44), (0.18, 0.44)]).fill(Color(hex: 0xf8e2a0)).at(0, 0, 1, 1, s)
                .mask(Pth.poly([(0.18, 0.3), (0.32, 0.31), (0.32, 0.45), (0.18, 0.45)]).at(0, 0, 1, 1, s))
            // a bowl of eggs
            ForEach(0..<4, id: \.self) { i in
                Ellipse().fill(vg(Color(hex: 0xfbf3e2), Color(hex: 0xe6d6b6))).at(0.36 + CGFloat(i) * 0.045, 0.29 + (i % 2 == 0 ? 0.02 : 0), 0.055, 0.07, s)
            }
            Pth { p, u in p.move(to: u(0.33, 0.35)); p.addLine(to: u(0.57, 0.35)); p.addQuadCurve(to: u(0.45, 0.44), control: u(0.56, 0.44)); p.addQuadCurve(to: u(0.33, 0.35), control: u(0.34, 0.44)) }
                .fill(vg(K.clayHi, K.clayDeep)).at(0, 0, 1, 1, s)
            // apples piled in a pyramid, a pomegranate (crowned) on top
            ForEach(0..<4, id: \.self) { i in
                let P: [(CGFloat, CGFloat)] = [(0.592, 0.372), (0.658, 0.372), (0.724, 0.372), (0.69, 0.312)]
                let c: [(Color, Color)] = [(Color(hex: 0xd8473a), Color(hex: 0x9c2a22)), (Color(hex: 0xb9cf5a), Color(hex: 0x7a9a36)),
                                           (Color(hex: 0xd8473a), Color(hex: 0x9c2a22)), (Color(hex: 0xe8b84a), Color(hex: 0xc0582c))]
                KApple(hi: c[i].0, lo: c[i].1).at(P[i].0, P[i].1, 0.072, 0.072, s)
            }
            KPomegranate().at(0.618, 0.296, 0.078, 0.086, s)
            // grapes with a leaf
            Pth.poly([(0.78, 0.3), (0.94, 0.27), (0.9, 0.36)]).fill(Fr.leaf).at(0, 0, 1, 1, s)
            ForEach(0..<9, id: \.self) { i in
                let row = i < 4 ? 0 : (i < 7 ? 1 : 2)
                let col = i < 4 ? i : (i < 7 ? i - 4 : i - 7)
                let n = [4, 3, 2][row]
                Circle().fill(RadialGradient(colors: [Color(hex: 0x8a4a8a), Color(hex: 0x4a2050)], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: s.width * 0.02))
                    .at(0.79 + CGFloat(col) * 0.04 + CGFloat(4 - n) * 0.02, 0.31 + CGFloat(row) * 0.035, 0.042, 0.042, s)
            }
            // a few coins for the day's sales
            ForEach(0..<3, id: \.self) { i in
                Ellipse().fill(i == 2 ? Fr.gold : Color(hex: 0xd8d8d0)).overlay(Ellipse().stroke(Color.black.opacity(0.25), lineWidth: 0.5))
                    .at(0.48 + CGFloat(i) * 0.005, 0.425 - CGFloat(i) * 0.012, 0.06, 0.02, s)
            }
        }
    }
}

private struct FigBasket: View {
    var body: some View {
        Art { s in
            // fig leaf tucked behind
            FigLeaf().fill(vg(Color(hex: 0x6f9a4e), Fr.leafDark)).frame(width: s.width * 0.42, height: s.width * 0.42)
                .rotationEffect(.degrees(-30)).position(x: s.width * 0.26, y: s.height * 0.38)
            // figs piled
            ForEach(0..<6, id: \.self) { i in
                let P: [(CGFloat, CGFloat, Double)] = [(0.12, 0.3, -25), (0.32, 0.27, 8), (0.52, 0.29, -8), (0.22, 0.14, 15), (0.42, 0.12, -12), (0.6, 0.2, 22)]
                FigShape().fill(RadialGradient(colors: [K.figHi, K.fig], center: UnitPoint(x: 0.38, y: 0.62), startRadius: 0, endRadius: s.width * 0.17))
                    .overlay(FigShape().stroke(Color(hex: 0x3e1a3c).opacity(0.5), lineWidth: 0.7))
                    .frame(width: s.width * 0.3, height: s.width * 0.3)
                    .rotationEffect(.degrees(P[i].2)).position(x: s.width * (P[i].0 + 0.15), y: s.height * (P[i].1 + 0.15))
            }
            // one fig cut open
            Ellipse().fill(Color(hex: 0x5e2d5a)).at(0.58, 0.3, 0.28, 0.22, s)
            Ellipse().fill(RadialGradient(colors: [Color(hex: 0xf3d8b0), Color(hex: 0xd9506a)], center: .center, startRadius: 0, endRadius: s.width * 0.1)).at(0.6, 0.315, 0.24, 0.19, s)
            ForEach(0..<6, id: \.self) { i in
                Circle().fill(Color(hex: 0xf6e8c8)).at(0.66 + CGFloat(i % 3) * 0.04, 0.36 + CGFloat(i / 3) * 0.05, 0.018, 0.018, s)
            }
            // the wicker basket
            Pth.poly([(0.06, 0.52), (0.94, 0.52), (0.84, 1.0), (0.16, 1.0)]).fill(vg(Color(hex: 0xd8a860), Color(hex: 0xa8783a))).at(0, 0, 1, 1, s)
            Pth { p, u in
                for i in 0..<5 { let y = 0.6 + CGFloat(i) * 0.08; p.move(to: u(0.06 + (y - 0.52) * 0.2, y)); p.addLine(to: u(0.94 - (y - 0.52) * 0.2, y)) }
                for i in 0..<8 { let x = 0.12 + CGFloat(i) * 0.108; p.move(to: u(x, 0.53)); p.addLine(to: u(0.5 + (x - 0.5) * 0.78, 1.0)) }
            }.stroke(Color(hex: 0x8a5e2a).opacity(0.7), lineWidth: 1).at(0, 0, 1, 1, s)
            Capsule().fill(vg(Color(hex: 0xe2b670), Color(hex: 0xb07f3e))).at(0.02, 0.48, 0.96, 0.08, s)
        }
    }
}

private struct FigShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let u = { (x: CGFloat, y: CGFloat) in CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        p.move(to: u(0.45, 0.0)); p.addLine(to: u(0.55, 0.0)); p.addLine(to: u(0.56, 0.12))
        p.addCurve(to: u(0.5, 1), control1: u(0.95, 0.3), control2: u(1.12, 1.0))
        p.addCurve(to: u(0.44, 0.12), control1: u(-0.12, 1.0), control2: u(0.05, 0.3))
        p.closeSubpath()
        return p
    }
}

/// A three-lobed fig leaf.
private struct FigLeaf: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let u = { (x: CGFloat, y: CGFloat) in CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        p.move(to: u(0.5, 1))
        p.addQuadCurve(to: u(0.05, 0.45), control: u(0.1, 0.85))
        p.addQuadCurve(to: u(0.32, 0.4), control: u(0.2, 0.3))
        p.addQuadCurve(to: u(0.5, 0.0), control: u(0.25, 0.1))
        p.addQuadCurve(to: u(0.68, 0.4), control: u(0.75, 0.1))
        p.addQuadCurve(to: u(0.95, 0.45), control: u(0.8, 0.3))
        p.addQuadCurve(to: u(0.5, 1), control: u(0.9, 0.85))
        p.closeSubpath()
        return p
    }
}
