import SwiftUI

// MARK: - Wing: Workshop (see VillaEstate.swift)
//
// The officina: a plastered workroom with a stone dado, a ceiling beam, a hanging oil lamp, a tool
// board (tongs, saw, dividers, set square) and an arched window onto the hills and an aqueduct. The
// back row stands against the wall (forge, water clock, Archimedes' screw, glass furnace); the front
// row stands on the flagstones (steam ball, anvil, potter's wheel, herb trough). Fire flickers,
// water drips and climbs, the steam ball spins. Every piece is drawn from Shapes in unit space
// (`Art` + `.at(x, y, w, h, s)`), so the same drawing serves the room and the shop card.

let workshopItems: [VillaItem] = [
    .init(id: "wrk_herbs", name: "Herb Garden", category: .garden, price: .denarii(50), blurb: "Mint, rosemary and thyme, for cooking and medicine.", place: "workshop"),
    .init(id: "wrk_anvil", name: "Anvil and Hammer", category: .garden, price: .denarii(60), blurb: "Beat hot iron into shape.", place: "workshop"),
    .init(id: "wrk_wheel", name: "Potter's Wheel", category: .garden, price: .denarii(80), blurb: "Spin wet clay into pots.", place: "workshop"),
    .init(id: "wrk_forge", name: "Forge", category: .garden, price: .denarii(105), blurb: "Hot enough to soften iron for the smith.", place: "workshop"),
    .init(id: "wrk_glass", name: "Glass Furnace", category: .garden, price: .denarii(120), blurb: "Romans blew glass into cups and bottles.", place: "workshop"),
    .init(id: "wrk_clock", name: "Water Clock", category: .garden, price: .denarii(135), blurb: "A clepsydra: dripping water tells the time.", place: "workshop"),
    .init(id: "wrk_screw", name: "Archimedes' Screw", category: .garden, price: .denarii(165), blurb: "Turn the handle and water climbs uphill.", place: "workshop"),
    .init(id: "wrk_steam", name: "Steam Ball", category: .garden, price: .denarii(240), blurb: "Hero of Alexandria's aeolipile, spun by steam.", place: "workshop"),
]

/// Feet at canvas fractions (x, y), box `size` canvas-widths; `shadow` = stands on the floor.
private let workshopSpots: [String: (x: CGFloat, y: CGFloat, size: CGFloat, shadow: CGFloat)] = [
    "wrk_forge": (0.155, 0.68, 0.31, 0.9),
    "wrk_clock": (0.405, 0.665, 0.22, 0.6),
    "wrk_screw": (0.61, 0.70, 0.27, 0.0),
    "wrk_glass": (0.87, 0.68, 0.26, 0.85),
    "wrk_steam": (0.15, 0.965, 0.27, 0.75),
    "wrk_anvil": (0.385, 0.935, 0.2, 0.6),
    "wrk_wheel": (0.62, 0.95, 0.23, 0.8),
    "wrk_herbs": (0.865, 0.975, 0.22, 0.85),
]

struct WorkshopRoom: View {
    let s: WingState
    var body: some View {
        WingRoom(floor: Color(hex: 0xb79c76), floorLine: 0.62) { w, h, t in
            ZStack(alignment: .topLeading) {
                WorkshopBackdrop(w: w, h: h, t: t, soot: s.has("wrk_forge"))
                ForEach(workshopItems.filter { s.has($0.id) }) { item in
                    if let p = workshopSpots[item.id] {
                        WingSpot(x: p.x, y: p.y, size: p.size, w: w, h: h, lift: s.lift(item.id)) {
                            ZStack(alignment: .bottom) {
                                if p.shadow > 0 {
                                    Ellipse().fill(Color.black.opacity(0.18))
                                        .frame(width: w * p.size * p.shadow, height: w * p.size * 0.09)
                                        .offset(y: w * p.size * 0.035)
                                }
                                workshopArt(item.id, t: t)
                                    // the clock stands mirrored, its pillar beside the forge
                                    .scaleEffect(x: item.id == "wrk_clock" ? -1 : 1)
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

struct WorkshopThumb: View {
    let id: String
    var body: some View {
        GeometryReader { g in
            let side = min(g.size.width, g.size.height) * 0.92
            workshopArt(id, t: 0, thumb: true)
                .frame(width: side, height: side)
                .position(x: g.size.width / 2, y: g.size.height - side / 2 - g.size.height * 0.03)
        }
        .clipped()   // smoke and steam stay inside the card's picture
    }
}

@ViewBuilder
private func workshopArt(_ id: String, t: Double, thumb: Bool = false) -> some View {
    switch id {
    case "wrk_forge": Forge(t: t, chimney: !thumb)
    case "wrk_clock": WaterClock(t: t)
    case "wrk_screw": ArchimedesScrew(t: t)
    case "wrk_glass": GlassFurnace(t: t)
    case "wrk_steam": SteamBall(t: t)
    case "wrk_anvil": Anvil(t: t)
    case "wrk_wheel": PottersWheel(t: t)
    case "wrk_herbs": HerbTrough()
    default: EmptyView()
    }
}

// MARK: - Palette and drawing helpers

private enum K {
    static let iron = Color(hex: 0x4d4846), ironHi = Color(hex: 0x8f8882), ironDeep = Color(hex: 0x2b2826)
    static let bronze = Color(hex: 0xb7803d), bronzeHi = Color(hex: 0xebbd6a), bronzeDeep = Color(hex: 0x7a4e20)
    static let wood = Color(hex: 0x94623a), woodHi = Color(hex: 0xbb8653), woodDeep = Color(hex: 0x5e3b1e)
    static let brick = Color(hex: 0xae5b3e), brickDeep = Color(hex: 0x7e3b25), mortar = Color(hex: 0xd9b88f)
    static let stone = Color(hex: 0xb9ab90), stoneDeep = Color(hex: 0x8d7e65)
    static let clay = Color(hex: 0xb5552f), clayHi = Color(hex: 0xd9824f), clayDeep = Color(hex: 0x8a3b1f)
    static let fireCore = Color(hex: 0xfff2b0), fireMid = Color(hex: 0xffb440), fireEdge = Color(hex: 0xe2512a)
    static let glass = Color(hex: 0x6fc0b2), glassDeep = Color(hex: 0x3f8f86)
    static let water = Color(hex: 0x5fa6c4), waterDeep = Color(hex: 0x3f7f9a)
    static let soot = Color(hex: 0x3a2a22)
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

/// A rectangle with a round top (doorways, oven mouths, windows).
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

/// Mortar joints: `rows` courses, `cols` blocks per course, every other course staggered.
private struct BrickLines: Shape {
    let rows: Int, cols: Int
    func path(in r: CGRect) -> Path {
        var p = Path()
        let rh = r.height / CGFloat(rows), cw = r.width / CGFloat(cols)
        for i in 0...rows { let y = r.minY + CGFloat(i) * rh; p.move(to: CGPoint(x: r.minX, y: y)); p.addLine(to: CGPoint(x: r.maxX, y: y)) }
        for i in 0..<rows {
            let y0 = r.minY + CGFloat(i) * rh
            let shift = i % 2 == 0 ? 0 : cw / 2
            var x = r.minX + shift
            while x < r.maxX { if x > r.minX { p.move(to: CGPoint(x: x, y: y0)); p.addLine(to: CGPoint(x: x, y: y0 + rh)) }; x += cw }
        }
        return p
    }
}

/// A teardrop flame, point up.
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

/// A small fire: `n` flickering tongues, a hot core in each.
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

/// A drawing surface: content places its parts with `.at(…)` in unit coordinates of its size.
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

private struct WorkshopBackdrop: View {
    let w: CGFloat, h: CGFloat, t: Double
    var soot = false
    var body: some View {
        let fy = h * 0.62
        ZStack(alignment: .topLeading) {
            // warm plaster, a little darker toward the ceiling
            Rectangle().fill(vg(Color(hex: 0xc4a578), Color(hex: 0xdcc398)))
                .frame(width: w * 3, height: fy + h).position(x: w / 2, y: (fy - h) / 2)
            // soot breathed up the wall by years of fires (left, behind the forge)
            if soot {
                Ellipse().fill(RadialGradient(colors: [Color(hex: 0x6b5440).opacity(0.3), .clear], center: .center, startRadius: 0, endRadius: w * 0.2))
                    .frame(width: w * 0.45, height: h * 0.55).position(x: w * 0.155, y: h * 0.2)
            }
            // stone dado
            Rectangle().fill(vg(K.stone, K.stoneDeep))
                .frame(width: w * 3, height: h * 0.15).position(x: w / 2, y: fy - h * 0.075)
            BrickLines(rows: 2, cols: 27).stroke(K.stoneDeep.opacity(0.9), lineWidth: 1)
                .frame(width: w * 3, height: h * 0.15).position(x: w / 2, y: fy - h * 0.075)
            Rectangle().fill(Color(hex: 0xe6d3ad)).frame(width: w * 3, height: max(1, h * 0.008)).position(x: w / 2, y: fy - h * 0.15)
            // ceiling beam with joist ends
            Rectangle().fill(vg(K.woodHi, K.woodDeep)).frame(width: w * 3, height: h * 0.045).position(x: w / 2, y: h * 0.0225)
            ForEach(-4..<13, id: \.self) { i in
                Rectangle().fill(K.woodDeep).frame(width: w * 0.035, height: h * 0.03)
                    .position(x: w * (0.06 + CGFloat(i) * 0.125), y: h * 0.06)
            }
            // sunlight from the window, falling across the floor
            Pth.poly([(0.415, 0.40), (0.585, 0.40), (0.84, 0.88), (0.5, 0.88)])
                .fill(LinearGradient(colors: [Color(hex: 0xfff4d6).opacity(0.22), Color(hex: 0xfff4d6).opacity(0)], startPoint: .top, endPoint: .bottom))
                .frame(width: w, height: h).position(x: w / 2, y: h / 2)
            WorkshopWindow(t: t).frame(width: w * 0.2, height: h * 0.3).position(x: w * 0.5, y: h * 0.25)
            ToolBoard().frame(width: w * 0.25, height: h * 0.15).position(x: w * 0.845, y: h * 0.2)
            HangingLamp(t: t).frame(width: w * 0.08, height: h * 0.2).position(x: w * 0.3, y: h * 0.145)
            // flagstones
            Flagstones().stroke(Color(hex: 0x6b5638).opacity(0.28), lineWidth: 1)
                .frame(width: w * 3, height: h * 1.4).position(x: w / 2, y: fy + h * 0.7)
        }
    }
}

private struct Flagstones: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        var y = r.minY, rowH = r.height * 0.045, row = 0
        while y < r.maxY {
            p.move(to: CGPoint(x: r.minX, y: y)); p.addLine(to: CGPoint(x: r.maxX, y: y))
            let cw = rowH * 2.6
            var x = r.minX + (row % 2 == 0 ? 0 : cw * 0.5) + CGFloat(row % 3) * cw * 0.2
            while x < r.maxX { p.move(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: x, y: y + rowH)); x += cw }
            y += rowH; rowH *= 1.18; row += 1
        }
        return p
    }
}

private struct WorkshopWindow: View {
    let t: Double
    var body: some View {
        Art { s in
            // stone surround and sill
            ArchShape().fill(vg(K.stone, K.stoneDeep)).at(0, 0, 1, 0.94, s)
            Art { s in
                Rectangle().fill(vg(Color(hex: 0x9cc3cf), Color(hex: 0xf1ddb0))).at(0, 0, 1, 1, s)
                // a drifting cloud
                let cx = CGFloat((t * 0.01).truncatingRemainder(dividingBy: 1.6)) - 0.4
                Capsule().fill(Color.white.opacity(0.85)).at(cx, 0.24, 0.4, 0.07, s)
                Capsule().fill(Color.white.opacity(0.85)).at(cx + 0.1, 0.2, 0.22, 0.07, s)
                // hills and an aqueduct striding across them
                Ellipse().fill(Fr.hillBack).at(-0.4, 0.62, 1.3, 0.5, s)
                Ellipse().fill(Fr.hillFront).at(0.3, 0.7, 1.2, 0.5, s)
                Rectangle().fill(Color(hex: 0xd8c39a)).at(-0.1, 0.5, 1.2, 0.04, s)
                ForEach(0..<4, id: \.self) { i in
                    ArchShape().fill(Color(hex: 0x86a35a)).at(-0.06 + CGFloat(i) * 0.3, 0.56, 0.2, 0.2, s)
                    Rectangle().fill(Color(hex: 0xc9ae80)).at(0.14 + CGFloat(i) * 0.3 - 0.3, 0.54, 0.1, 0.22, s)
                }
                Rectangle().fill(Color(hex: 0xc9ae80)).at(-0.1, 0.54, 1.2, 0.025, s)
                Ellipse().fill(Fr.leafDark).at(0.68, 0.48, 0.1, 0.3, s)
            }
            .clipShape(ArchShape())
            .at(0.12, 0.08, 0.76, 0.8, s)
            // the sill
            RoundedRectangle(cornerRadius: 1).fill(vg(Color(hex: 0xe2d4b6), K.stoneDeep)).at(-0.06, 0.88, 1.12, 0.08, s)
        }
    }
}

private struct ToolBoard: View {
    var body: some View {
        Art { s in
            RoundedRectangle(cornerRadius: 2).fill(vg(K.woodHi, K.wood)).at(0, 0, 1, 1, s)
            RoundedRectangle(cornerRadius: 2).stroke(K.woodDeep, lineWidth: 1).at(0, 0, 1, 1, s)
            ForEach(0..<4, id: \.self) { i in
                Circle().fill(K.woodDeep).at(0.1 + CGFloat(i) * 0.25, 0.1, 0.05, 0.08, s)
            }
            // tongs
            Pth { p, u in p.move(to: u(0.12, 0.14)); p.addLine(to: u(0.07, 0.9)); p.move(to: u(0.12, 0.14)); p.addLine(to: u(0.2, 0.9)) }
                .stroke(K.iron, style: StrokeStyle(lineWidth: 2, lineCap: .round)).at(0, 0, 1, 1, s)
            // saw: wooden handle, toothed iron blade
            RoundedRectangle(cornerRadius: 2).fill(K.woodDeep).at(0.28, 0.16, 0.08, 0.2, s)
            Pth { p, u in
                p.move(to: u(0.3, 0.36)); p.addLine(to: u(0.36, 0.36))
                var y: CGFloat = 0.36
                while y < 0.86 { p.addLine(to: u(0.38, y + 0.04)); p.addLine(to: u(0.36, y + 0.08)); y += 0.08 }
                p.addLine(to: u(0.3, 0.9)); p.closeSubpath()
            }.fill(K.ironHi).at(0, 0, 1, 1, s)
            // dividers (a compass) for laying out circles
            Pth { p, u in p.move(to: u(0.6, 0.18)); p.addLine(to: u(0.52, 0.88)); p.move(to: u(0.6, 0.18)); p.addLine(to: u(0.7, 0.88)) }
                .stroke(K.bronze, style: StrokeStyle(lineWidth: 2.2, lineCap: .round)).at(0, 0, 1, 1, s)
            Circle().fill(K.bronzeHi).at(0.575, 0.13, 0.05, 0.1, s)
            // set square
            Pth.poly([(0.8, 0.2), (0.8, 0.86), (0.96, 0.86)]).stroke(K.bronze, lineWidth: 2).at(0, 0, 1, 1, s)
        }
    }
}

private struct HangingLamp: View {
    let t: Double
    var body: some View {
        Art { s in
            // three chains to a bronze lamp
            Pth { p, u in p.move(to: u(0.5, 0)); p.addLine(to: u(0.5, 0.55)); p.addLine(to: u(0.15, 0.78)); p.move(to: u(0.5, 0.55)); p.addLine(to: u(0.85, 0.78)) }
                .stroke(K.bronzeDeep, lineWidth: 1).at(0, 0, 1, 1, s)
            let f = 0.85 + 0.15 * sin(t * 11) * sin(t * 3.3)
            Circle().fill(RadialGradient(colors: [K.fireMid.opacity(0.35), .clear], center: .center, startRadius: 0, endRadius: s.width * 0.9))
                .at(-0.5, 0.48, 2, 0.5, s)
            FlameShape().fill(LinearGradient(colors: [K.fireEdge, K.fireMid, K.fireCore], startPoint: .top, endPoint: .bottom))
                .at(0.78, 0.84 - 0.12 * f, 0.18, 0.12 * f, s)
            // lamp body: a boat-shaped bowl with a spout
            Pth { p, u in
                p.move(to: u(0.05, 0.8)); p.addQuadCurve(to: u(0.95, 0.84), control: u(0.5, 0.74))
                p.addQuadCurve(to: u(0.05, 0.8), control: u(0.4, 1.02))
            }.fill(vg(K.bronzeHi, K.bronzeDeep)).at(0, 0, 1, 1, s)
        }
    }
}

// MARK: - The items

private struct Forge: View {
    let t: Double
    var chimney = true
    var body: some View {
        Art { s in
            let glow = 0.78 + 0.22 * sin(t * 3.1) * sin(t * 1.7 + 1)
            if chimney {
                Rectangle().fill(vg(Color(hex: 0x7a6248), Color(hex: 0xb79b75))).at(0.37, -1.42, 0.26, 1.5, s)
            } else {
                Rectangle().fill(vg(Color(hex: 0x9a8060), Color(hex: 0xb79b75))).at(0.37, -0.02, 0.26, 0.1, s)
            }
            // hood
            Pth.poly([(0.06, 0.3), (0.94, 0.3), (0.64, 0.06), (0.36, 0.06)]).fill(vg(Color(hex: 0xa48764), Color(hex: 0xc7ab84))).at(0, 0, 1, 1, s)
            RoundedRectangle(cornerRadius: 1).fill(K.stoneDeep).at(0.03, 0.28, 0.94, 0.04, s)
            Ellipse().fill(RadialGradient(colors: [K.fireMid.opacity(0.5 * glow), .clear], center: .center, startRadius: 0, endRadius: s.width * 0.34))
                .at(0.08, 0.18, 0.84, 0.36, s)
            // brick hearth with a glowing ash pit
            Rectangle().fill(vg(K.brick, K.brickDeep)).at(0.05, 0.5, 0.9, 0.5, s)
            BrickLines(rows: 5, cols: 5).stroke(K.mortar.opacity(0.55), lineWidth: 1).at(0.05, 0.5, 0.9, 0.5, s)
            ArchShape().fill(K.soot).at(0.34, 0.7, 0.32, 0.3, s)
            ArchShape().fill(RadialGradient(colors: [K.fireMid.opacity(0.75 * glow), .clear], center: .bottom, startRadius: 0, endRadius: s.width * 0.18))
                .at(0.34, 0.7, 0.32, 0.3, s)
            // stone top, coal bed, fire
            RoundedRectangle(cornerRadius: 2).fill(vg(Color(hex: 0xcfc2a6), K.stoneDeep)).at(0.02, 0.46, 0.96, 0.07, s)
            Ellipse().fill(K.soot).at(0.18, 0.41, 0.56, 0.09, s)
            ForEach(0..<7, id: \.self) { i in
                let fi = Double(i)
                Circle().fill(RadialGradient(colors: [K.fireMid, Color(hex: 0x8a2e14)], center: .top, startRadius: 0, endRadius: s.width * 0.04))
                    .opacity(0.55 + 0.45 * sin(t * 4 + fi * 1.3))
                    .at(0.22 + CGFloat(i) * 0.065, 0.425 + (i % 2 == 0 ? 0 : 0.02), 0.06, 0.045, s)
            }
            Fire(t: t, n: 3).at(0.26, 0.15, 0.4, 0.3, s)
            // sparks
            ForEach(0..<4, id: \.self) { i in
                let ph = (t * 0.8 + Double(i) * 0.25).truncatingRemainder(dividingBy: 1)
                Circle().fill(K.fireCore).opacity(1 - ph)
                    .at(0.45 + 0.14 * sin(Double(i) * 2.3 + ph * 4), 0.3 - 0.22 * ph, 0.025, 0.025, s)
            }
            // bellows, nozzle into the fire
            let sq = CGFloat(0.06 * (1 + sin(t * 2.2)))
            Pth.poly([(0.97, 0.06 + sq), (0.28, 0.4), (0.28, 0.6), (0.97, 0.94 - sq)]).fill(vg(Color(hex: 0x8a5a36), Color(hex: 0x5e3b22))).at(0.68, 0.3, 0.32, 0.17, s)
            Pth { p, u in p.move(to: u(0.97, 0.06 + sq)); p.addLine(to: u(0.28, 0.4)); p.move(to: u(0.97, 0.94 - sq)); p.addLine(to: u(0.28, 0.6)) }
                .stroke(K.woodHi, style: StrokeStyle(lineWidth: 2, lineCap: .round)).at(0.68, 0.3, 0.32, 0.17, s)
            Pth.poly([(0.3, 0.4), (0, 0.5), (0.3, 0.6)]).fill(K.iron).at(0.6, 0.3, 0.14, 0.17, s)
        }
    }
}

private struct Anvil: View {
    let t: Double
    var body: some View {
        Art { s in
            // the stump, rings on its top
            Rectangle().fill(hg(K.woodHi, K.woodDeep)).at(0.28, 0.66, 0.44, 0.32, s)
            Ellipse().fill(vg(K.woodHi, K.wood)).at(0.28, 0.62, 0.44, 0.08, s)
            Ellipse().fill(K.woodDeep.opacity(0.9)).at(0.27, 0.94, 0.46, 0.06, s)
            Pth { p, u in p.move(to: u(0.36, 0.7)); p.addLine(to: u(0.38, 0.96)); p.move(to: u(0.6, 0.72)); p.addLine(to: u(0.62, 0.95)) }
                .stroke(K.woodDeep.opacity(0.6), lineWidth: 1).at(0, 0, 1, 1, s)
            // the anvil: horn to the left, a heavy waist and foot
            Pth { p, u in
                p.move(to: u(0.06, 0.42))
                p.addQuadCurve(to: u(0.32, 0.36), control: u(0.16, 0.36))
                p.addLine(to: u(0.88, 0.36)); p.addLine(to: u(0.88, 0.46)); p.addLine(to: u(0.65, 0.48))
                p.addLine(to: u(0.6, 0.56)); p.addLine(to: u(0.72, 0.6)); p.addLine(to: u(0.72, 0.65))
                p.addLine(to: u(0.28, 0.65)); p.addLine(to: u(0.28, 0.6)); p.addLine(to: u(0.4, 0.56))
                p.addLine(to: u(0.36, 0.48))
                p.addQuadCurve(to: u(0.06, 0.42), control: u(0.2, 0.47))
                p.closeSubpath()
            }.fill(vg(K.ironHi, K.ironDeep)).at(0, 0, 1, 1, s)
            Rectangle().fill(Color.white.opacity(0.35)).at(0.32, 0.36, 0.56, 0.015, s)
            // a red-hot bar on the horn, cooling and glowing
            let g = 0.75 + 0.25 * sin(t * 2)
            Capsule().fill(hg(K.fireEdge, K.fireCore)).opacity(g).at(0.12, 0.31, 0.34, 0.05, s)
            Capsule().fill(K.fireMid.opacity(0.3 * g)).blur(radius: 2).at(0.1, 0.27, 0.38, 0.12, s)
            // the hammer resting on the face
            Capsule().fill(hg(K.woodHi, K.wood)).frame(width: s.width * 0.46, height: s.width * 0.045)
                .rotationEffect(.degrees(-24)).position(x: s.width * 0.8, y: s.height * 0.24)
            RoundedRectangle(cornerRadius: 1.5).fill(hg(K.ironHi, K.iron)).frame(width: s.width * 0.1, height: s.width * 0.2)
                .rotationEffect(.degrees(-24)).position(x: s.width * 0.6, y: s.height * 0.3)
        }
    }
}

private struct PottersWheel: View {
    let t: Double
    var body: some View {
        Art { s in
            // a finished jug waiting beside the wheel
            Rectangle().fill(hg(K.clayHi, K.clayDeep)).at(0.065, 0.72, 0.07, 0.12, s)
            Ellipse().fill(hg(K.clayHi, K.clayDeep)).at(0.0, 0.8, 0.2, 0.2, s)
            Capsule().fill(K.clayHi).at(0.05, 0.71, 0.1, 0.03, s)
            // heavy kick wheel below, turning
            Ellipse().fill(vg(K.woodHi, K.woodDeep)).at(0.16, 0.8, 0.7, 0.18, s)
            Rectangle().fill(K.woodDeep).at(0.16, 0.88, 0.7, 0.04, s)
            ForEach(0..<4, id: \.self) { i in
                let a = t * 2.4 + Double(i) * .pi / 2
                let x = 0.51 + 0.3 * cos(a)
                Rectangle().fill(K.woodDeep.opacity(sin(a) > 0 ? 0.8 : 0.25)).at(x - 0.01, 0.82, 0.02, 0.07, s)
            }
            // shaft and wheel head
            Rectangle().fill(hg(K.woodHi, K.woodDeep)).at(0.47, 0.52, 0.08, 0.32, s)
            Ellipse().fill(vg(K.woodHi, K.wood)).at(0.24, 0.48, 0.54, 0.09, s)
            Rectangle().fill(K.woodDeep).at(0.24, 0.52, 0.54, 0.03, s)
            // the wet clay pot, spinning (a sheen sliding round it)
            Pth { p, u in
                p.move(to: u(0.4, 0.2)); p.addLine(to: u(0.62, 0.2))
                p.addQuadCurve(to: u(0.6, 0.31), control: u(0.58, 0.25))
                p.addQuadCurve(to: u(0.6, 0.52), control: u(0.76, 0.44))
                p.addLine(to: u(0.42, 0.52))
                p.addQuadCurve(to: u(0.42, 0.31), control: u(0.26, 0.44))
                p.addQuadCurve(to: u(0.4, 0.2), control: u(0.44, 0.25))
                p.closeSubpath()
            }.fill(hg(Color(hex: 0xb8775a), Color(hex: 0x8a4e38))).at(0, 0, 1, 1, s)
            let sx = 0.38 + 0.22 * (0.5 + 0.5 * sin(t * 5))
            Capsule().fill(Color.white.opacity(0.28)).at(sx, 0.3, 0.03, 0.2, s)
            Ellipse().fill(Color(hex: 0x6e3a28)).at(0.415, 0.19, 0.19, 0.035, s)
            Pth { p, u in for y in [0.36, 0.42, 0.47] as [CGFloat] { p.move(to: u(0.33, y)); p.addLine(to: u(0.69, y)) } }
                .stroke(Color(hex: 0x6e3a28).opacity(0.35), lineWidth: 0.8).at(0, 0, 1, 1, s)
                .mask(Rectangle().at(0.3, 0.3, 0.42, 0.22, s))
            // a bowl of water for wetting the hands
            Ellipse().fill(vg(K.clayHi, K.clayDeep)).at(0.8, 0.88, 0.2, 0.1, s)
            Ellipse().fill(K.water).at(0.82, 0.885, 0.16, 0.04, s)
        }
    }
}

private struct GlassFurnace: View {
    let t: Double
    var body: some View {
        Art { s in
            let glow = 0.8 + 0.2 * sin(t * 2.6) * sin(t * 1.3 + 2)
            // flue with a shimmer of heat
            Rectangle().fill(vg(K.brickDeep, K.brick)).at(0.43, 0.02, 0.14, 0.16, s)
            ForEach(0..<2, id: \.self) { i in
                let ph = (t * 0.4 + Double(i) * 0.5).truncatingRemainder(dividingBy: 1)
                Circle().fill(Color(hex: 0x8a7a6a).opacity(0.35 * (1 - ph))).at(0.42 + 0.06 * ph, -0.08 - 0.35 * ph, 0.16 + 0.1 * ph, 0.12 + 0.08 * ph, s)
            }
            // beehive dome of brick and clay
            Pth { p, u in
                p.move(to: u(0.08, 1.0)); p.addCurve(to: u(0.5, 0.14), control1: u(0.04, 0.5), control2: u(0.22, 0.14))
                p.addCurve(to: u(0.92, 1.0), control1: u(0.78, 0.14), control2: u(0.96, 0.5))
                p.closeSubpath()
            }.fill(LinearGradient(colors: [Color(hex: 0xc98a5e), K.brick, K.brickDeep], startPoint: .topLeading, endPoint: .bottomTrailing)).at(0, 0, 1, 1, s)
            Pth { p, u in for y in [0.34, 0.5, 0.66, 0.82] as [CGFloat] { p.move(to: u(0.05, y)); p.addQuadCurve(to: u(0.95, y), control: u(0.5, y - 0.06)) } }
                .stroke(K.mortar.opacity(0.4), lineWidth: 1).at(0, 0, 1, 1, s)
                .mask(Pth { p, u in
                    p.move(to: u(0.08, 1.0)); p.addCurve(to: u(0.5, 0.14), control1: u(0.04, 0.5), control2: u(0.22, 0.14))
                    p.addCurve(to: u(0.92, 1.0), control1: u(0.78, 0.14), control2: u(0.96, 0.5)); p.closeSubpath()
                }.at(0, 0, 1, 1, s))
            // the glory hole, white-hot
            Circle().fill(RadialGradient(colors: [K.fireMid.opacity(0.55 * glow), .clear], center: .center, startRadius: 0, endRadius: s.width * 0.3)).at(0.2, 0.3, 0.6, 0.6, s)
            Circle().fill(K.soot).at(0.33, 0.46, 0.34, 0.3, s)
            Circle().fill(RadialGradient(colors: [K.fireCore, K.fireMid, K.fireEdge], center: .center, startRadius: 0, endRadius: s.width * 0.14))
                .opacity(glow).at(0.36, 0.49, 0.28, 0.24, s)
            Rectangle().fill(vg(K.stone, K.stoneDeep)).at(0.04, 0.92, 0.92, 0.08, s)
            // a blowpipe with a glowing gather of glass
            Capsule().fill(K.iron).frame(width: s.width * 0.6, height: s.width * 0.025)
                .rotationEffect(.degrees(-32)).position(x: s.width * 0.76, y: s.height * 0.43)
            Circle().fill(RadialGradient(colors: [K.fireCore, K.fireMid], center: .center, startRadius: 0, endRadius: s.width * 0.05)).at(0.47, 0.54, 0.1, 0.1, s)
            // finished glass at the foot: a flask and a beaker
            GlassFlask().at(0.0, 0.66, 0.2, 0.34, s)
            GlassBeaker().at(0.8, 0.76, 0.18, 0.24, s)
        }
    }
}

private struct GlassFlask: View {
    var body: some View {
        Art { s in
            Pth { p, u in
                p.move(to: u(0.4, 0)); p.addLine(to: u(0.6, 0)); p.addLine(to: u(0.6, 0.4))
                p.addQuadCurve(to: u(0.5, 1), control: u(1.15, 0.85)); p.addQuadCurve(to: u(0.4, 0.4), control: u(-0.15, 0.85))
                p.closeSubpath()
            }.fill(LinearGradient(colors: [K.glass.opacity(0.9), K.glassDeep.opacity(0.85)], startPoint: .leading, endPoint: .trailing)).at(0, 0, 1, 1, s)
            Capsule().fill(Color.white.opacity(0.55)).at(0.24, 0.55, 0.08, 0.25, s)
        }
    }
}

private struct GlassBeaker: View {
    var body: some View {
        Art { s in
            Pth.poly([(0.05, 0), (0.95, 0), (0.8, 1), (0.2, 1)]).fill(LinearGradient(colors: [Color(hex: 0x8fd3e6).opacity(0.85), Color(hex: 0x4b98b5).opacity(0.85)], startPoint: .leading, endPoint: .trailing)).at(0, 0, 1, 1, s)
            Ellipse().fill(Color.white.opacity(0.5)).at(0.05, -0.08, 0.9, 0.16, s)
            Capsule().fill(Color.white.opacity(0.55)).at(0.24, 0.2, 0.1, 0.6, s)
        }
    }
}

private struct WaterClock: View {
    let t: Double
    var body: some View {
        Art { s in
            // one fill every 40 seconds: water rises, the float lifts the pointer up the hours
            let ph = CGFloat((t / 40).truncatingRemainder(dividingBy: 1))
            let level: CGFloat = 0.86 - 0.34 * ph
            // marble pillar ruled with the hours
            Rectangle().fill(hg(Fr.marble, Fr.marbleShade)).at(0.56, 0.1, 0.24, 0.84, s)
            Rectangle().fill(Fr.marbleShade).at(0.53, 0.07, 0.3, 0.04, s)
            Pth { p, u in for i in 0...11 { let y = 0.2 + CGFloat(i) * 0.05; p.move(to: u(0.6, y)); p.addLine(to: u(i % 3 == 0 ? 0.76 : 0.7, y)) } }
                .stroke(Color(hex: 0x8a6a22), lineWidth: 1).at(0, 0, 1, 1, s)
            // the receiving vessel, cut away to show its water
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xe8f1f0).opacity(0.75)).at(0.15, 0.42, 0.36, 0.5, s)
            Rectangle().fill(vg(K.water, K.waterDeep)).at(0.15, level, 0.36, 0.92 - level, s)
            Rectangle().fill(Color.white.opacity(0.5)).at(0.15, level, 0.36, 0.012, s)
            RoundedRectangle(cornerRadius: 2).stroke(K.bronze, lineWidth: 2).at(0.15, 0.42, 0.36, 0.5, s)
            Rectangle().fill(K.bronze).at(0.13, 0.42, 0.4, 0.025, s)
            // float, rod and gold pointer
            Capsule().fill(K.woodHi).at(0.22, level - 0.035, 0.22, 0.04, s)
            Rectangle().fill(K.bronzeDeep).at(0.32, level - 0.37, 0.02, 0.34, s)
            Pth.poly([(0, 0.2), (0.75, 0.2), (1, 0.5), (0.75, 0.8), (0, 0.8)]).fill(Fr.gold).at(0.32, level - 0.4, 0.27, 0.06, s)
            // the upper tank on its bracket, dripping
            Rectangle().fill(K.bronzeDeep).at(0.4, 0.17, 0.18, 0.025, s)
            Pth { p, u in p.move(to: u(0, 0)); p.addLine(to: u(1, 0)); p.addQuadCurve(to: u(0.5, 1), control: u(0.98, 0.95)); p.addQuadCurve(to: u(0, 0), control: u(0.02, 0.95)) }
                .fill(vg(K.bronzeHi, K.bronzeDeep)).at(0.06, 0.1, 0.34, 0.16, s)
            Ellipse().fill(K.water).at(0.08, 0.09, 0.3, 0.035, s)
            Rectangle().fill(K.bronzeDeep).at(0.215, 0.25, 0.03, 0.03, s)
            let d = CGFloat((t * 1.4).truncatingRemainder(dividingBy: 1))
            FlameShape().fill(K.water).at(0.21, 0.28 + (level - 0.3) * d * d, 0.04, 0.05, s)
            // plinth
            Rectangle().fill(vg(Fr.marble, Fr.marbleShade)).at(0.1, 0.92, 0.76, 0.08, s)
        }
    }
}

private struct ArchimedesScrew: View {
    let t: Double
    var body: some View {
        Art { s in
            // tub of water at the low end
            Rectangle().fill(hg(K.woodHi, K.woodDeep)).at(0.0, 0.8, 0.3, 0.2, s)
            Pth { p, u in for x in [0.25, 0.5, 0.75] as [CGFloat] { p.move(to: u(x, 0)); p.addLine(to: u(x, 1)) } }
                .stroke(K.woodDeep.opacity(0.6), lineWidth: 1).at(0.0, 0.8, 0.3, 0.2, s)
            Rectangle().fill(K.iron).at(0.0, 0.86, 0.3, 0.02, s)
            Ellipse().fill(vg(K.water, K.waterDeep)).at(0.0, 0.77, 0.3, 0.07, s)
            // trestle under the middle
            Pth { p, u in p.move(to: u(0.38, 1)); p.addLine(to: u(0.49, 0.58)); p.addLine(to: u(0.6, 1)) }
                .stroke(K.woodDeep, style: StrokeStyle(lineWidth: 3, lineCap: .round)).at(0, 0, 1, 1, s)
            // trough and post at the high end, water pouring in and running off
            Rectangle().fill(K.woodDeep).at(0.9, 0.36, 0.05, 0.64, s)
            Pth.poly([(0.74, 0.3), (1.0, 0.33), (1.0, 0.39), (0.76, 0.36)]).fill(vg(K.woodHi, K.wood)).at(0, 0, 1, 1, s)
            let sh = 0.7 + 0.3 * sin(t * 6)
            Capsule().fill(K.water.opacity(sh)).at(0.835, 0.27, 0.035, 0.08, s)
            Rectangle().fill(K.water.opacity(0.8)).at(0.78, 0.315, 0.22, 0.02, s)
            // the screw itself: a wooden drum wound with a helix, turning so the water climbs
            ScrewDrum(t: t).frame(width: s.width * 0.92, height: s.width * 0.2)
                .rotationEffect(.degrees(-36)).position(x: s.width * 0.47, y: s.height * 0.56)
            // crank at the top
            Pth { p, u in p.move(to: u(0.84, 0.29)); p.addLine(to: u(0.9, 0.2)); p.addLine(to: u(0.96, 0.22)) }
                .stroke(K.iron, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)).at(0, 0, 1, 1, s)
            Capsule().fill(K.woodHi).at(0.94, 0.16, 0.035, 0.08, s)
        }
    }
}

private struct ScrewDrum: View {
    let t: Double
    var body: some View {
        let ph = CGFloat((t * 0.45).truncatingRemainder(dividingBy: 1))
        ZStack {
            Capsule().fill(vg(K.woodHi, K.woodDeep))
            Pth { p, u in
                for i in -2..<10 { let x = (CGFloat(i) + ph) / 7; p.move(to: u(x + 0.06, 0)); p.addLine(to: u(x - 0.06, 1)) }
            }.stroke(K.water, lineWidth: 5)
            Pth { p, u in
                for i in -2..<10 { let x = (CGFloat(i) + ph + 0.5) / 7; p.move(to: u(x + 0.06, 0)); p.addLine(to: u(x - 0.06, 1)) }
            }.stroke(K.woodDeep, lineWidth: 3)
            HStack {
                ForEach(0..<3, id: \.self) { _ in Rectangle().fill(K.iron).frame(width: 3) }.frame(maxWidth: .infinity)
            }.padding(.horizontal, 14)
            Capsule().stroke(K.woodDeep, lineWidth: 1)
            VStack { Capsule().fill(Color.white.opacity(0.18)).frame(height: 3).padding(.horizontal, 10).padding(.top, 2); Spacer() }
        }
        .clipShape(Capsule())
    }
}

private struct SteamBall: View {
    let t: Double
    var body: some View {
        Art { s in
            let a = t * 2.6       // spin
            let cx: CGFloat = 0.5, cy: CGFloat = 0.3, r: CGFloat = 0.15
            // stone hearth with a fire under the boiler
            Rectangle().fill(vg(K.stone, K.stoneDeep)).at(0.12, 0.88, 0.76, 0.12, s)
            BrickLines(rows: 1, cols: 4).stroke(K.stoneDeep, lineWidth: 1).at(0.12, 0.88, 0.76, 0.12, s)
            Fire(t: t, n: 3).at(0.28, 0.7, 0.44, 0.2, s)
            // the bronze boiler on short legs
            Pth { p, u in p.move(to: u(0.3, 0.72)); p.addLine(to: u(0.26, 0.88)); p.move(to: u(0.7, 0.72)); p.addLine(to: u(0.74, 0.88)) }
                .stroke(K.bronzeDeep, style: StrokeStyle(lineWidth: 2.5, lineCap: .round)).at(0, 0, 1, 1, s)
            Pth { p, u in p.move(to: u(0.2, 0.52)); p.addLine(to: u(0.8, 0.52)); p.addQuadCurve(to: u(0.5, 0.8), control: u(0.84, 0.8)); p.addQuadCurve(to: u(0.2, 0.52), control: u(0.16, 0.8)) }
                .fill(LinearGradient(colors: [K.bronzeHi, K.bronze, K.bronzeDeep], startPoint: .topLeading, endPoint: .bottomTrailing)).at(0, 0, 1, 1, s)
            Capsule().fill(vg(K.bronzeHi, K.bronze)).at(0.17, 0.5, 0.66, 0.05, s)
            // the steam pipe up to the ball's pivot
            Rectangle().fill(hg(K.bronzeHi, K.bronzeDeep)).at(0.47, cy, 0.06, 0.21, s)
            // the ball
            Circle().fill(RadialGradient(colors: [K.bronzeHi, K.bronze, K.bronzeDeep], center: UnitPoint(x: 0.35, y: 0.32), startRadius: 0, endRadius: s.width * 0.18))
                .at(cx - r, cy - r, 2 * r, 2 * r, s)
            // seams turning with it
            Pth { p, u in
                for k in 0..<2 {
                    let b = a + Double(k) * .pi / 2
                    p.move(to: u(cx + r * 0.95 * CGFloat(cos(b)), cy + r * 0.95 * CGFloat(sin(b))))
                    p.addLine(to: u(cx - r * 0.95 * CGFloat(cos(b)), cy - r * 0.95 * CGFloat(sin(b))))
                }
            }.stroke(K.bronzeDeep.opacity(0.45), lineWidth: 1).at(0, 0, 1, 1, s)
            // two bent nozzles, puffing steam backward as it spins
            ForEach(0..<2, id: \.self) { k in
                let b = a + Double(k) * .pi
                let ux = CGFloat(cos(b)), uy = CGFloat(sin(b))
                let tx = CGFloat(-sin(b)), ty = CGFloat(cos(b))   // direction of travel
                let base = (cx + ux * r * 0.9, cy + uy * r * 0.9)
                let elbow = (cx + ux * r * 1.4, cy + uy * r * 1.4)
                let tip = (elbow.0 - tx * 0.07, elbow.1 - ty * 0.07)
                Pth { p, u in p.move(to: u(base.0, base.1)); p.addLine(to: u(elbow.0, elbow.1)); p.addLine(to: u(tip.0, tip.1)) }
                    .stroke(K.bronzeDeep, style: StrokeStyle(lineWidth: s.width * 0.04, lineCap: .round, lineJoin: .round)).at(0, 0, 1, 1, s)
                Pth { p, u in p.move(to: u(base.0, base.1)); p.addLine(to: u(elbow.0, elbow.1)); p.addLine(to: u(tip.0, tip.1)) }
                    .stroke(K.bronzeHi, style: StrokeStyle(lineWidth: s.width * 0.015, lineCap: .round, lineJoin: .round)).at(0, 0, 1, 1, s)
                ForEach(0..<4, id: \.self) { j in
                    let fj = CGFloat(j)
                    let back = b - Double(j) * 0.45 - 0.25
                    let rr = r * (1.55 + fj * 0.14)
                    let sz = 0.07 + fj * 0.03
                    Circle().fill(Color.white.opacity(0.75 - Double(j) * 0.17))
                        .at(cx + rr * CGFloat(cos(back)) - sz / 2, cy + rr * CGFloat(sin(back)) - sz / 2, sz, sz, s)
                }
            }
            Circle().fill(K.bronzeDeep).at(cx - 0.025, cy - 0.025, 0.05, 0.05, s)
        }
    }
}

private struct HerbTrough: View {
    var body: some View {
        Art { s in
            // soil
            Ellipse().fill(Color(hex: 0x5a3e28)).at(0.06, 0.6, 0.88, 0.08, s)
            // mint: broad bright leaves
            ForEach(0..<16, id: \.self) { i in
                let ang = Double(i) * 2.39996, rr = sqrt(Double(i) / 16)
                let x = 0.22 + 0.15 * CGFloat(rr * cos(ang)), y = 0.47 + 0.14 * CGFloat(rr * sin(ang))
                Ellipse().fill(vg(i % 3 == 0 ? Color(hex: 0x9fd06a) : Color(hex: 0x79b44e), Color(hex: 0x4f8a34)))
                    .overlay(Capsule().fill(Color(hex: 0x3f7a2c).opacity(0.55)).frame(width: 0.8).padding(.vertical, 1))
                    .frame(width: s.width * 0.075, height: s.width * 0.1)
                    .rotationEffect(.degrees(Double(i) * 47))
                    .position(x: x * s.width, y: y * s.height)
            }
            // rosemary: tall needled stems with pale blue flowers
            Pth { p, u in
                for i in 0..<5 {
                    let x0: CGFloat = 0.5, top = 0.08 + CGFloat(i % 2) * 0.08
                    let x1 = 0.38 + CGFloat(i) * 0.06
                    p.move(to: u(x0, 0.64)); p.addLine(to: u(x1, top))
                    var k: CGFloat = 0.1
                    while k < 0.95 {
                        let x = x0 + (x1 - x0) * k, y = 0.64 + (top - 0.64) * k
                        p.move(to: u(x, y)); p.addLine(to: u(x - 0.035, y - 0.03))
                        p.move(to: u(x, y)); p.addLine(to: u(x + 0.035, y - 0.03))
                        k += 0.1
                    }
                }
            }.stroke(Color(hex: 0x3f6a44), style: StrokeStyle(lineWidth: 1.4, lineCap: .round)).at(0, 0, 1, 1, s)
            ForEach(0..<5, id: \.self) { i in
                Circle().fill(Color(hex: 0xa9c4ee)).at(0.4 + CGFloat(i) * 0.05, 0.2 + CGFloat((i * 7) % 5) * 0.06, 0.035, 0.035, s)
            }
            // thyme: a low cushion of tiny leaves and pink-purple flowers
            ForEach(0..<30, id: \.self) { i in
                let ang = Double(i) * 2.39996, rr = sqrt(Double(i) / 30)
                let x = 0.79 + 0.14 * CGFloat(rr * cos(ang)), y = 0.5 + 0.12 * CGFloat(rr * sin(ang))
                Circle().fill(i % 3 == 0 ? Color(hex: 0x5f7d3d) : Color(hex: 0x7f9d56)).at(x - 0.03, y - 0.03, 0.06, 0.06, s)
            }
            ForEach(0..<8, id: \.self) { i in
                let ang = Double(i) * 2.2 + 0.5
                Circle().fill(Color(hex: 0xc996d6)).at(0.775 + 0.11 * CGFloat(cos(ang)), 0.46 + 0.08 * CGFloat(sin(ang)), 0.035, 0.035, s)
            }
            // terracotta trough with a raised garland
            Pth.poly([(0.04, 0.66), (0.96, 0.66), (0.9, 1), (0.1, 1)]).fill(vg(K.clayHi, K.clay)).at(0, 0, 1, 1, s)
            RoundedRectangle(cornerRadius: 1.5).fill(vg(Color(hex: 0xe39563), K.clayHi)).at(0.02, 0.62, 0.96, 0.07, s)
            Pth { p, u in
                p.move(to: u(0.14, 0.76))
                for i in 0..<4 { let x = 0.14 + CGFloat(i) * 0.18; p.addQuadCurve(to: u(x + 0.18, 0.76), control: u(x + 0.09, 0.9)) }
            }.stroke(Color(hex: 0xe8a070), lineWidth: 1.5).at(0, 0, 1, 1, s)
            ForEach(0..<5, id: \.self) { i in Circle().fill(Color(hex: 0xe8a070)).at(0.125 + CGFloat(i) * 0.18, 0.745, 0.03, 0.03, s) }
        }
    }
}
