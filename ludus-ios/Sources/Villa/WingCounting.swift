import SwiftUI

// MARK: - Wing: the Counting Room (see VillaEstate.swift)
//
// A steward's office: Pompeian-yellow panels painted with Euclid's figures, a terracotta floor set
// with white tesserae (opus signinum) and a bronze lamp hanging on its chain. The child fills it with
// the tools Romans counted, weighed and measured with. Drawings use the unit-square kit in
// WingCountingArt.swift.

let countingItems: [VillaItem] = [
    .init(id: "cnt_pebbles", name: "Counting Pebbles", category: .garden, price: .denarii(40), blurb: "Calculi: our word \"calculate\" comes from them.", place: "counting"),
    .init(id: "cnt_rods", name: "Measuring Rods", category: .garden, price: .denarii(60), blurb: "A Roman foot was a little shorter than ours.", place: "counting"),
    .init(id: "cnt_abacus", name: "Abacus", category: .garden, price: .denarii(70), blurb: "Romans counted with beads that slid in grooves.", place: "counting"),
    .init(id: "cnt_scale", name: "Steelyard Scale", category: .garden, price: .denarii(90), blurb: "Slide the weight along the arm until it balances.", place: "counting"),
    .init(id: "cnt_chest", name: "Strongbox", category: .garden, price: .denarii(105), blurb: "An iron-bound chest for the family's coins.", place: "counting"),
    .init(id: "cnt_groma", name: "Groma", category: .garden, price: .denarii(135), blurb: "A surveyor's cross for laying out straight roads.", place: "counting"),
    .init(id: "cnt_mosaic", name: "Numeral Mosaic", category: .garden, price: .denarii(150), blurb: "I, V, X, L, C, D and M in tiny tiles.", place: "counting"),
    .init(id: "cnt_archimedes", name: "Bust of Archimedes", category: .garden, price: .denarii(180), blurb: "The genius of Syracuse: levers, circles, \"Eureka!\"", place: "counting"),
]

/// Where each thing stands: feet at canvas fractions, box `size` canvas-widths square.
private let countingSpots: [String: (x: CGFloat, y: CGFloat, size: CGFloat)] = [
    "cnt_groma": (0.09, 0.74, 0.37),
    "cnt_rods": (0.36, 0.665, 0.35),
    "cnt_archimedes": (0.59, 0.675, 0.31),
    "cnt_scale": (0.83, 0.71, 0.35),
    "cnt_abacus": (0.23, 0.885, 0.33),
    "cnt_chest": (0.79, 0.935, 0.27),
    "cnt_pebbles": (0.1, 0.98, 0.23),
    "cnt_mosaic": (0.5, 0.99, 0.48),
]

/// Unit-space bounds of each drawing, for framing its shop card.
private let countingThumbBox: [String: CGRect] = [
    "cnt_pebbles": CGRect(x: 0.0, y: 0.56, width: 1.0, height: 0.42),
    "cnt_rods": CGRect(x: 0.22, y: 0.0, width: 0.76, height: 1.0),
    "cnt_abacus": CGRect(x: 0.03, y: 0.08, width: 0.94, height: 0.92),
    "cnt_scale": CGRect(x: 0.0, y: 0.06, width: 1.0, height: 0.94),
    "cnt_chest": CGRect(x: 0.02, y: 0.26, width: 0.98, height: 0.72),
    "cnt_groma": CGRect(x: 0.2, y: 0.06, width: 0.78, height: 0.94),
    "cnt_mosaic": CGRect(x: 0.0, y: 0.42, width: 1.0, height: 0.58),
    "cnt_archimedes": CGRect(x: 0.2, y: 0.08, width: 0.6, height: 0.92),
]

struct CountingRoom: View {
    let s: WingState
    var body: some View {
        WingRoom(panel: Color(hex: 0xd2a04a), floor: Color(hex: 0xbf7650)) { w, h, t in
            ZStack(alignment: .topLeading) {
                CountingFloor().fill(Fr.stucco.opacity(0.55)).frame(width: w, height: h)
                CountingWallFigures().stroke(Fr.frameDeep.opacity(0.6), style: StrokeStyle(lineWidth: max(1, w * 0.004), lineJoin: .round))
                    .frame(width: w, height: h)
                // the hanging lamp, on a chain from the ceiling
                Rectangle().fill(COC.iron).frame(width: max(1, w * 0.004), height: h)
                    .position(x: w * 0.57, y: h * 0.17 - h / 2)
                CountingLamp(t: t).frame(width: w * 0.15, height: w * 0.15)
                    .position(x: w * 0.57, y: h * 0.17 + w * 0.075)
                ForEach(countingItems.filter { s.has($0.id) }.sorted { (countingSpots[$0.id]?.y ?? 0) < (countingSpots[$1.id]?.y ?? 0) }) { item in
                    if let p = countingSpots[item.id] {
                        WingSpot(x: p.x, y: p.y, size: p.size, w: w, h: h, lift: s.lift(item.id)) {
                            CountingArt(id: item.id, t: t)
                        }
                        .zIndex(item.id == "cnt_mosaic" ? -1 : Double(p.y))
                        .onTapGesture { s.onTap(item.id) }
                    }
                }
            }
        }
    }
}

struct CountingThumb: View {
    let id: String
    var body: some View {
        COThumb(box: countingThumbBox[id] ?? CGRect(x: 0, y: 0, width: 1, height: 1)) {
            if id == "cnt_mosaic" { NumeralMosaic(tilt: 38) } else { CountingArt(id: id, t: 0) }
        }
    }
}

private struct CountingArt: View {
    let id: String
    let t: Double
    var body: some View {
        switch id {
        case "cnt_pebbles": CountingPebbles()
        case "cnt_rods": MeasuringRods()
        case "cnt_abacus": AbacusTable()
        case "cnt_scale": Steelyard(t: t)
        case "cnt_chest": Strongbox()
        case "cnt_groma": Groma(t: t)
        case "cnt_mosaic": NumeralMosaic()
        case "cnt_archimedes": ArchimedesBust()
        default: EmptyView()
        }
    }
}

// MARK: - The room itself

/// White tesserae set in a terracotta floor, rows spreading as they come nearer.
private struct CountingFloor: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        var y: CGFloat = 0.645
        var row = 0
        while y < 1.6 {
            let near = (y - 0.62) / 0.38
            let dx = w * 0.055 * (1 + near * 0.55)
            let d = w * 0.0055 * (1 + near * 0.8)
            var x = -w + (row % 2 == 0 ? 0 : dx / 2)
            while x < 2 * w {
                let c = CGPoint(x: x, y: y * h)
                p.move(to: CGPoint(x: c.x, y: c.y - d * 0.7))
                p.addLine(to: CGPoint(x: c.x + d, y: c.y))
                p.addLine(to: CGPoint(x: c.x, y: c.y + d * 0.7))
                p.addLine(to: CGPoint(x: c.x - d, y: c.y))
                p.closeSubpath()
                x += dx
            }
            y += 0.034 * (1 + near * 0.7)
            row += 1
        }
        return p
    }
}

/// Euclid's figures painted in the middle of each yellow panel.
private struct CountingWallFigures: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        let cy = h * 0.62 * 0.44
        let rad = w * 0.052
        func poly(_ cx: CGFloat, _ n: Int, _ rot: Double) {
            let pts = (0..<n).map { i -> CGPoint in
                let a = rot + Double(i) / Double(n) * .pi * 2
                return CGPoint(x: cx + rad * CGFloat(cos(a)), y: cy + rad * CGFloat(sin(a)))
            }
            p.addLines(pts); p.closeSubpath()
        }
        for (i, f) in [-0.08, 0.18, 0.44, 0.70, 0.96, 1.22].enumerated() {
            let cx = w * CGFloat(f)
            switch i % 6 {
            case 0: poly(cx, 6, 0)                                 // hexagon
            case 1: poly(cx, 3, -.pi / 2)                          // triangle
                p.move(to: CGPoint(x: cx, y: cy - rad)); p.addLine(to: CGPoint(x: cx, y: cy + rad * 0.5))
            case 2:                                                // circle with its radius
                p.addEllipse(in: CGRect(x: cx - rad, y: cy - rad, width: rad * 2, height: rad * 2))
                p.move(to: CGPoint(x: cx, y: cy)); p.addLine(to: CGPoint(x: cx + rad, y: cy))
                p.addEllipse(in: CGRect(x: cx - 1.5, y: cy - 1.5, width: 3, height: 3))
            case 3:                                                // square and its diagonal
                let a = rad * 0.82
                p.addRect(CGRect(x: cx - a, y: cy - a, width: a * 2, height: a * 2))
                p.move(to: CGPoint(x: cx - a, y: cy + a)); p.addLine(to: CGPoint(x: cx + a, y: cy - a))
            case 4: poly(cx, 5, -.pi / 2)                          // pentagon
            default: poly(cx, 4, 0)                                // rhombus
            }
            // a little ruled line under each figure, like a label
            p.move(to: CGPoint(x: cx - rad * 0.7, y: cy + rad * 1.45)); p.addLine(to: CGPoint(x: cx + rad * 0.7, y: cy + rad * 1.45))
        }
        return p
    }
}

/// A bronze oil lamp with a flickering flame.
private struct CountingLamp: View {
    let t: Double
    var body: some View {
        let f = 1 + 0.12 * sin(t * 9) + 0.07 * sin(t * 23 + 1)
        ZStack {
            COPath { p in p.coDot(0.92, 0.5, 0.3 * f) }.fill(Color(hex: 0xffd77a).opacity(0.08))
            COPath { p in p.coDot(0.92, 0.5, 0.16 * f) }.fill(Color(hex: 0xffd77a).opacity(0.14))
            LampBody()
            COPath { p in
                let hgt = 0.26 * f
                p.move(to: coPt(0.92, 0.6 - hgt))
                p.addQuadCurve(to: coPt(0.96, 0.6), control: coPt(1.0, 0.6 - hgt * 0.4))
                p.addQuadCurve(to: coPt(0.88, 0.6), control: coPt(0.92, 0.64))
                p.addQuadCurve(to: coPt(0.92, 0.6 - hgt), control: coPt(0.86, 0.6 - hgt * 0.45))
            }
            .fill(LinearGradient(colors: [Color(hex: 0xfff2b0), Color(hex: 0xf39a2b)], startPoint: .top, endPoint: .bottom))
        }
    }
}

private struct LampBody: View {
    var body: some View {
        ZStack {
            COPath { p in      // three chains to the ring
                p.coLine([coPt(0.5, 0.02), coPt(0.24, 0.56)], 0.018)
                p.coLine([coPt(0.5, 0.02), coPt(0.5, 0.52)], 0.018)
                p.coLine([coPt(0.5, 0.02), coPt(0.76, 0.56)], 0.018)
                p.coRing(0.5, 0.04, 0.035, 0.035, 0.02)
            }
            .fill(COC.iron)
            COPath { p in      // body, nozzle and ring handle
                p.coOval(0.14, 0.52, 0.64, 0.2)
                p.coPoly([coPt(0.66, 0.56), coPt(0.95, 0.6), coPt(0.95, 0.65), coPt(0.66, 0.7)])
                p.coRing(0.1, 0.6, 0.06, 0.05, 0.035)
            }
            .fill(COC.bronzeFill(.top, .bottom))
            COPath { p in
                p.coDot(0.46, 0.565, 0.1, 0.03)       // filling hole
                p.coDot(0.93, 0.62, 0.025, 0.02)      // wick hole
            }
            .fill(COC.bronzeDk)
            COPath { p in p.coLine([coPt(0.24, 0.66), coPt(0.66, 0.66)], 0.015) }.fill(COC.bronzeDk.opacity(0.6))
        }
    }
}

// MARK: - The things

private struct CountingPebbles: View {
    // pebble centres: a heap in the bowl, and ten laid out as a triangle (1 + 2 + 3 + 4)
    private static let heap: [CGPoint] = [coPt(0.12, 0.7), coPt(0.21, 0.68), coPt(0.3, 0.685), coPt(0.39, 0.705),
                                          coPt(0.17, 0.635), coPt(0.26, 0.625), coPt(0.35, 0.645), coPt(0.22, 0.585)]
    private static let tri: [CGPoint] = [coPt(0.6, 0.93), coPt(0.69, 0.93), coPt(0.78, 0.93), coPt(0.87, 0.93),
                                         coPt(0.645, 0.86), coPt(0.735, 0.86), coPt(0.825, 0.86),
                                         coPt(0.69, 0.79), coPt(0.78, 0.79),
                                         coPt(0.735, 0.72)]
    private static let colors: [Color] = [Fr.marble, Color(hex: 0x3b3431), Fr.tile, Color(hex: 0xd9bf86)]
    var body: some View {
        let all = Self.heap + Self.tri
        ZStack {
            COPath { $0.coOval(0.0, 0.86, 1.0, 0.13) }.fill(COC.shadow)
            // the bowl
            COPath { p in
                p.move(to: coPt(0.02, 0.72)); p.addQuadCurve(to: coPt(0.5, 0.72), control: coPt(0.26, 1.05)); p.closeSubpath()
            }
            .fill(LinearGradient(colors: [Color(hex: 0xc8683d), Color(hex: 0x8a3b1f)], startPoint: .top, endPoint: .bottom))
            COPath { $0.coOval(0.02, 0.675, 0.48, 0.09) }.fill(Color(hex: 0x6e2e17))
            ForEach(0..<4, id: \.self) { c in
                COPath { p in
                    for (i, q) in all.enumerated() where i % 4 == c { p.coDot(q.x, q.y, 0.045, 0.034) }
                }
                .fill(Self.colors[c])
            }
            COPath { p in for q in all { p.coDot(q.x - 0.012, q.y - 0.012, 0.016, 0.009) } }.fill(Color.white.opacity(0.45))
            COPath { p in for q in all { p.coRing(q.x, q.y, 0.045, 0.034, 0.006) } }.fill(Color.black.opacity(0.25))
            // bowl rim in front of the heap
            COPath { p in p.coQuad(coPt(0.02, 0.72), coPt(0.26, 0.775), coPt(0.5, 0.72), 0.02) }.fill(Color(hex: 0xd98a5c))
        }
    }
}

private struct MeasuringRods: View {
    private struct Rod { let a: CGPoint, b: CGPoint, wd: CGFloat, n: Int }
    private static let rods: [Rod] = [
        Rod(a: coPt(0.3, 0.985), b: coPt(0.42, 0.03), wd: 0.06, n: 10),
        Rod(a: coPt(0.47, 0.985), b: coPt(0.53, 0.1), wd: 0.055, n: 10),
        Rod(a: coPt(0.64, 0.985), b: coPt(0.6, 0.3), wd: 0.05, n: 6),
    ]
    private static func seg(_ r: Rod, _ f0: CGFloat, _ f1: CGFloat) -> [CGPoint] {
        [coPt(r.a.x + (r.b.x - r.a.x) * f0, r.a.y + (r.b.y - r.a.y) * f0),
         coPt(r.a.x + (r.b.x - r.a.x) * f1, r.a.y + (r.b.y - r.a.y) * f1)]
    }
    var body: some View {
        ZStack {
            COPath { $0.coOval(0.2, 0.94, 0.62, 0.08) }.fill(COC.shadow)
            COPath { p in for r in Self.rods { p.coLine([r.a, r.b], r.wd, cap: .butt) } }.fill(Color(hex: 0xf0e2bf))
            COPath { p in
                for r in Self.rods { for i in stride(from: 1, to: r.n, by: 2) {
                    p.coLine(Self.seg(r, CGFloat(i) / CGFloat(r.n), CGFloat(i + 1) / CGFloat(r.n)), r.wd, cap: .butt)
                } }
            }
            .fill(Fr.frame)
            COPath { p in for r in Self.rods { p.coLine(Self.seg(r, 0, 0.035), r.wd * 1.15, cap: .butt); p.coLine(Self.seg(r, 0.965, 1), r.wd * 1.15, cap: .butt) } }
                .fill(COC.bronzeFill(.leading, .trailing))
            // shading down the right side of each rod
            COPath { p in
                for r in Self.rods {
                    let o = r.wd * 0.3
                    p.coLine([coPt(r.a.x + o, r.a.y), coPt(r.b.x + o, r.b.y)], r.wd * 0.35, cap: .butt)
                }
            }
            .fill(Color.black.opacity(0.13))
            // a bronze folding foot-rule, open on the floor
            COPath { p in
                p.coLine([coPt(0.66, 0.965), coPt(0.97, 0.985)], 0.035, cap: .butt)
                p.coLine([coPt(0.66, 0.965), coPt(0.93, 0.87)], 0.035, cap: .butt)
            }
            .fill(COC.bronzeLt)
            COPath { p in
                for i in 1..<6 {
                    let f = CGFloat(i) / 6
                    p.coLine([coPt(0.66 + 0.31 * f, 0.958 + 0.02 * f), coPt(0.66 + 0.31 * f, 0.972 + 0.02 * f)], 0.006)
                    p.coLine([coPt(0.66 + 0.27 * f, 0.958 - 0.095 * f), coPt(0.663 + 0.27 * f, 0.972 - 0.095 * f)], 0.006)
                }
                p.coDot(0.66, 0.965, 0.018)
            }
            .fill(COC.bronzeDk)
        }
    }
}

private struct AbacusTable: View {
    private static let digits = [3, 1, 4, 1, 5, 9, 2]          // a little easter egg: π
    var body: some View {
        ZStack {
            COPath { $0.coOval(0.04, 0.92, 0.92, 0.1) }.fill(COC.shadow)
            // turned legs and a stretcher
            COPath { p in
                for x in [0.17, 0.83] as [CGFloat] {
                    p.coLine([coPt(x, 0.64), coPt(x, 0.985)], 0.045)
                    p.coDot(x, 0.72, 0.04, 0.02); p.coDot(x, 0.9, 0.035, 0.018)
                }
                p.coLine([coPt(0.17, 0.85), coPt(0.83, 0.85)], 0.025)
            }
            .fill(COC.woodDk)
            COPath { $0.coBox(0.05, 0.58, 0.9, 0.045, r: 0.01) }.fill(COC.woodLt)
            COPath { $0.coBox(0.05, 0.615, 0.9, 0.035, r: 0.008) }.fill(COC.wood)
            // the bronze hand-abacus standing on the table
            COPath { p in p.coBox(0.25, 0.55, 0.09, 0.04, r: 0.01); p.coBox(0.66, 0.55, 0.09, 0.04, r: 0.01) }.fill(COC.bronzeDk)
            COPath { $0.coBox(0.2, 0.1, 0.6, 0.46, r: 0.035) }.fill(COC.bronzeFill())
            COPath { p in
                var q = Path(); q.addRoundedRect(in: CGRect(x: 0.225, y: 0.125, width: 0.55, height: 0.41), cornerSize: CGSize(width: 0.025, height: 0.025))
                p.addPath(q.strokedPath(StrokeStyle(lineWidth: 0.012)))
                p.coLine([coPt(0.23, 0.31), coPt(0.77, 0.31)], 0.012)
                for i in 0..<7 {
                    let x = 0.26 + CGFloat(i) * 0.08
                    p.coLine([coPt(x, 0.155), coPt(x, 0.285)], 0.024)
                    p.coLine([coPt(x, 0.335), coPt(x, 0.515)], 0.024)
                }
            }
            .fill(Color(hex: 0x4a2f15))
            COPath { p in
                for (i, d) in Self.digits.enumerated() {
                    let x = 0.26 + CGFloat(i) * 0.08
                    p.coDot(x, d >= 5 ? 0.262 : 0.178, 0.024)
                    let k = d % 5
                    for j in 0..<4 {
                        let y = j < k ? 0.36 + CGFloat(j) * 0.042 : 0.49 - CGFloat(3 - j) * 0.042
                        p.coDot(x, y, 0.024)
                    }
                }
            }
            .fill(COC.ivory)
            COPath { p in
                for (i, d) in Self.digits.enumerated() {
                    let x = 0.26 + CGFloat(i) * 0.08
                    p.coRing(x, d >= 5 ? 0.262 : 0.178, 0.024, 0.024, 0.006)
                    let k = d % 5
                    for j in 0..<4 {
                        let y = j < k ? 0.36 + CGFloat(j) * 0.042 : 0.49 - CGFloat(3 - j) * 0.042
                        p.coRing(x, y, 0.024, 0.024, 0.006)
                    }
                }
            }
            .fill(Color(hex: 0x6b4a22))
        }
    }
}

private struct Steelyard: View {
    let t: Double
    var body: some View {
        ZStack {
            SteelyardStand()
            SteelyardBeam()
                .rotationEffect(.degrees(1.6 * sin(t * 0.9)), anchor: UnitPoint(x: 0.58, y: 0.2))
        }
    }
}

private struct SteelyardStand: View {
    var body: some View {
        ZStack {
            COPath { $0.coOval(0.0, 0.93, 1.0, 0.07) }.fill(COC.shadow)
            COPath { p in
                p.coBox(0.09, 0.08, 0.055, 0.87)
                p.coBox(0.09, 0.075, 0.53, 0.045, r: 0.01)
                p.coLine([coPt(0.12, 0.33), coPt(0.33, 0.11)], 0.032)
            }
            .fill(LinearGradient(colors: [COC.woodLt, COC.wood], startPoint: .leading, endPoint: .trailing))
            COPath { $0.coBox(0.02, 0.93, 0.2, 0.06, r: 0.01) }.fill(COC.woodDk)
            COPath { p in
                p.coLine([coPt(0.58, 0.115), coPt(0.58, 0.17)], 0.016)
                p.coRing(0.58, 0.185, 0.018, 0.018, 0.012)
            }
            .fill(COC.iron)
        }
    }
}

private struct SteelyardBeam: View {
    var body: some View {
        ZStack {
            // chains and the pan, with three apples on it
            COPath { p in
                p.coLine([coPt(0.8, 0.215), coPt(0.66, 0.6)], 0.009)
                p.coLine([coPt(0.8, 0.215), coPt(0.94, 0.6)], 0.009)
                p.coLine([coPt(0.8, 0.215), coPt(0.8, 0.57)], 0.009)
            }
            .fill(COC.iron)
            COPath { p in
                p.coDot(0.72, 0.555, 0.05); p.coDot(0.8, 0.545, 0.05); p.coDot(0.88, 0.56, 0.048)
            }
            .fill(LinearGradient(colors: [Color(hex: 0xd9473a), Color(hex: 0x92231c)], startPoint: .topLeading, endPoint: .bottomTrailing))
            COPath { p in
                p.coLine([coPt(0.72, 0.51), coPt(0.725, 0.49)], 0.008); p.coLine([coPt(0.8, 0.5), coPt(0.805, 0.48)], 0.008)
                p.coLine([coPt(0.88, 0.515), coPt(0.885, 0.495)], 0.008)
            }
            .fill(COC.woodDk)
            COPath { p in
                p.move(to: coPt(0.63, 0.59)); p.addQuadCurve(to: coPt(0.97, 0.59), control: coPt(0.8, 0.7)); p.closeSubpath()
            }
            .fill(COC.bronzeFill(.top, .bottom))
            COPath { p in p.coLine([coPt(0.63, 0.59), coPt(0.97, 0.59)], 0.018) }.fill(COC.bronzeLt)
            // the beam, its scale of marks, and the sliding weight
            COPath { p in
                p.coLine([coPt(0.17, 0.2), coPt(0.84, 0.2)], 0.03)
                p.coDot(0.17, 0.2, 0.024)
                p.coRing(0.58, 0.2, 0.022, 0.022, 0.01)
            }
            .fill(COC.bronzeDk)
            COPath { p in
                for i in 0..<9 { let x = 0.22 + CGFloat(i) * 0.038; p.coLine([coPt(x, 0.19), coPt(x, 0.21)], 0.006) }
            }
            .fill(COC.ivory)
            COPath { p in
                p.coRing(0.32, 0.235, 0.016, 0.022, 0.009)
                p.coLine([coPt(0.32, 0.255), coPt(0.32, 0.28)], 0.01)
            }
            .fill(COC.iron)
            COPath { p in      // an acorn-shaped weight
                p.move(to: coPt(0.32, 0.28))
                p.addCurve(to: coPt(0.32, 0.43), control1: coPt(0.25, 0.3), control2: coPt(0.27, 0.4))
                p.addCurve(to: coPt(0.32, 0.28), control1: coPt(0.37, 0.4), control2: coPt(0.39, 0.3))
            }
            .fill(COC.bronzeFill())
            COPath { $0.coBox(0.285, 0.275, 0.07, 0.03, r: 0.01) }.fill(COC.bronzeDk)
        }
    }
}

private struct Strongbox: View {
    private static func lidTop(_ x: CGFloat) -> CGFloat { 0.36 - 0.06 * (1 - pow((x - 0.41) / 0.37, 2)) }
    private static let straps: [CGFloat] = [0.15, 0.41, 0.67]
    var body: some View {
        ZStack {
            COPath { $0.coOval(0.0, 0.89, 1.0, 0.1) }.fill(COC.shadow)
            COPath { p in p.coBox(0.09, 0.88, 0.09, 0.06, r: 0.01); p.coBox(0.64, 0.88, 0.09, 0.06, r: 0.01) }.fill(COC.iron)
            COPath { $0.coBox(0.06, 0.44, 0.7, 0.46, r: 0.01) }
                .fill(LinearGradient(colors: [Color(hex: 0x8a4526), Color(hex: 0x5c2a16)], startPoint: .top, endPoint: .bottom))
            COPath { p in
                p.move(to: coPt(0.04, 0.46)); p.addLine(to: coPt(0.04, 0.36))
                p.addQuadCurve(to: coPt(0.78, 0.36), control: coPt(0.41, 0.24))
                p.addLine(to: coPt(0.78, 0.46)); p.closeSubpath()
            }
            .fill(LinearGradient(colors: [Color(hex: 0xa1562f), Color(hex: 0x74361c)], startPoint: .top, endPoint: .bottom))
            // planks
            COPath { p in p.coLine([coPt(0.07, 0.6), coPt(0.75, 0.6)], 0.006); p.coLine([coPt(0.07, 0.75), coPt(0.75, 0.75)], 0.006) }
                .fill(Color.black.opacity(0.22))
            // iron bands and straps
            COPath { p in
                p.coBox(0.03, 0.44, 0.76, 0.035)
                p.coBox(0.06, 0.85, 0.7, 0.03)
                for x in Self.straps { p.coLine([coPt(x, Self.lidTop(x) + 0.008), coPt(x, 0.9)], 0.05, cap: .butt) }
            }
            .fill(LinearGradient(colors: [COC.ironLt, COC.iron], startPoint: .top, endPoint: .bottom))
            COPath { p in
                for x in Self.straps { for y in stride(from: 0.5, to: 0.86, by: 0.09) as StrideTo<CGFloat> where abs(x - 0.41) > 0.01 || y > 0.62 {
                    p.coDot(x, y, 0.011)
                } }
                for x in stride(from: 0.08, to: 0.76, by: 0.08) as StrideTo<CGFloat> { p.coDot(x, 0.4575, 0.008) }
            }
            .fill(Color(hex: 0x9a8f84))
            // bronze lock plate
            COPath { $0.coBox(0.345, 0.48, 0.13, 0.13, r: 0.022) }.fill(COC.bronzeFill())
            COPath { p in p.coDot(0.41, 0.525, 0.017); p.coPoly([coPt(0.4, 0.53), coPt(0.42, 0.53), coPt(0.428, 0.585), coPt(0.392, 0.585)]) }
                .fill(Color(hex: 0x2a1a10))
            // a stack of gold coins beside it
            COPath { p in for i in 0..<6 { p.coOval(0.78, 0.9 - CGFloat(i) * 0.03, 0.2, 0.055) } ; p.coOval(0.64, 0.935, 0.16, 0.045) }
                .fill(Fr.gold)
            COPath { p in for i in 0..<6 { p.coRing(0.88, 0.9275 - CGFloat(i) * 0.03, 0.1, 0.0275, 0.007) }; p.coRing(0.72, 0.9575, 0.08, 0.0225, 0.007) }
                .fill(COC.bronzeDk)
            COPath { p in p.coDot(0.88, 0.7775, 0.045, 0.012) }.fill(Color(hex: 0xf7dc8a))
        }
    }
}

private struct Groma: View {
    let t: Double
    private static let ends: [(CGPoint, CGFloat)] = [(coPt(0.27, 0.145), 0.5), (coPt(0.93, 0.145), 0.52), (coPt(0.53, 0.095), 0.45), (coPt(0.67, 0.195), 0.57)]
    var body: some View {
        ZStack {
            GromaFrame()
            ForEach(0..<4, id: \.self) { i in
                let (e, len) = Self.ends[i]
                let sway = CGFloat(sin(t * 1.1 + Double(i) * 1.7)) * 0.008
                COPath { p in p.coLine([e, coPt(e.x + sway, len)], 0.006) }.fill(Color(hex: 0x3a2a1a))
                COPath { p in
                    let c = coPt(e.x + sway, len + 0.03)
                    p.coDot(c.x, c.y, 0.022)
                    p.coPoly([coPt(c.x - 0.019, c.y - 0.01), coPt(c.x, c.y - 0.045), coPt(c.x + 0.019, c.y - 0.01)])
                }
                .fill(LinearGradient(colors: [Color(hex: 0x8a8d92), Color(hex: 0x4d5054)], startPoint: .top, endPoint: .bottom))
            }
        }
    }
}

private struct GromaFrame: View {
    var body: some View {
        ZStack {
            COPath { $0.coOval(0.24, 0.95, 0.36, 0.05) }.fill(COC.shadow)
            COPath { p in p.coBox(0.402, 0.13, 0.036, 0.825) }.fill(COC.wood)
            COPath { p in p.coBox(0.406, 0.13, 0.01, 0.825) }.fill(COC.woodLt)
            COPath { p in
                p.coPoly([coPt(0.402, 0.95), coPt(0.438, 0.95), coPt(0.42, 0.995)])
                p.coLine([coPt(0.42, 0.155), coPt(0.6, 0.155)], 0.028, cap: .butt)
            }
            .fill(COC.iron)
            COPath { p in
                p.coBox(0.4, 0.5, 0.04, 0.025); p.coBox(0.4, 0.22, 0.04, 0.025)
                p.coDot(0.6, 0.15, 0.022)
            }
            .fill(COC.bronze)
            // the cross: one arm across, one coming toward us
            COPath { p in p.coLine([coPt(0.53, 0.095), coPt(0.67, 0.195)], 0.026) }.fill(COC.woodDk)
            COPath { p in p.coBox(0.26, 0.131, 0.68, 0.028, r: 0.01) }.fill(COC.wood)
            COPath { p in p.coBox(0.27, 0.133, 0.66, 0.008) }.fill(COC.woodLt)
            COPath { p in
                for e in [coPt(0.27, 0.145), coPt(0.93, 0.145), coPt(0.53, 0.095), coPt(0.67, 0.195)] { p.coDot(e.x, e.y, 0.017) }
                p.coDot(0.6, 0.145, 0.02)
            }
            .fill(COC.bronzeFill())
        }
    }
}

private struct NumeralMosaic: View {
    var tilt: Double = 58
    var body: some View {
        GeometryReader { g in
            let w = min(g.size.width, g.size.height)
            MosaicPanel()
                .frame(width: w, height: w * 0.62)
                .rotation3DEffect(.degrees(tilt), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.45)
                .frame(width: g.size.width, height: g.size.height, alignment: .bottom)
        }
    }
}

private struct MosaicPanel: View {
    var body: some View {
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            let ink = Color(hex: 0x2b2421)
            ZStack {
                Rectangle().fill(ink)
                Rectangle().fill(Fr.marble).padding(W * 0.035)
                MosaicTeeth().fill(Fr.frame).padding(W * 0.035)
                Rectangle().fill(ink).padding(W * 0.085)
                Rectangle().fill(Color(hex: 0xf3e8cf)).padding(W * 0.1)
                // corner rosettes
                ForEach(0..<4, id: \.self) { i in
                    Rectangle().fill(Fr.ochre).frame(width: W * 0.045, height: W * 0.045).rotationEffect(.degrees(45))
                        .position(x: i % 2 == 0 ? W * 0.16 : W * 0.84, y: i < 2 ? H * 0.24 : H * 0.76)
                }
                VStack(spacing: H * 0.0) {
                    numerals(["I", "V", "X", "L"], W)
                    numerals(["C", "D", "M"], W)
                }
                MosaicGrid().stroke(Color.black.opacity(0.16), lineWidth: max(0.4, W * 0.003))
            }
        }
    }
    private func numerals(_ s: [String], _ W: CGFloat) -> some View {
        HStack(spacing: W * 0.075) {
            ForEach(Array(s.enumerated()), id: \.offset) { i, c in
                Text(c).font(luCinzel(W * 0.15, bold: true))
                    .foregroundStyle(i % 2 == 0 ? Color(hex: 0x2b2421) : Fr.frame)
            }
        }
    }
}

/// A band of little red squares (a "running tooth" border).
private struct MosaicTeeth: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let band = r.width * 0.05, s = band * 0.5
        var x = r.minX + s * 0.5
        while x < r.maxX - s {
            p.addRect(CGRect(x: x, y: r.minY + s * 0.5, width: s, height: s))
            p.addRect(CGRect(x: x, y: r.maxY - s * 1.5, width: s, height: s))
            x += s * 2
        }
        var y = r.minY + s * 2.5
        while y < r.maxY - s * 2 {
            p.addRect(CGRect(x: r.minX + s * 0.5, y: y, width: s, height: s))
            p.addRect(CGRect(x: r.maxX - s * 1.5, y: y, width: s, height: s))
            y += s * 2
        }
        return p
    }
}

/// The tesserae: a fine grid over the whole panel.
private struct MosaicGrid: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let n = 46, step = r.width / CGFloat(n)
        for i in 1..<n { let x = r.minX + CGFloat(i) * step; p.move(to: CGPoint(x: x, y: r.minY)); p.addLine(to: CGPoint(x: x, y: r.maxY)) }
        var y = r.minY + step
        while y < r.maxY { p.move(to: CGPoint(x: r.minX, y: y)); p.addLine(to: CGPoint(x: r.maxX, y: y)); y += step }
        return p
    }
}

private struct ArchimedesBust: View {
    var body: some View {
        let shade = Color(hex: 0xa59c88)
        let curl = Color(hex: 0xddd4c0)
        ZStack {
            COPath { $0.coOval(0.2, 0.95, 0.6, 0.05) }.fill(COC.shadow)
            // the pedestal, carved with a sphere in a cylinder (the figure on his tomb)
            COPath { p in p.coBox(0.27, 0.92, 0.46, 0.07, r: 0.008); p.coBox(0.29, 0.56, 0.42, 0.04, r: 0.008) }.fill(Fr.marbleShade)
            COPath { $0.coBox(0.33, 0.6, 0.34, 0.32) }.fill(COC.marbleFill)
            COPath { p in
                var q = Path(); q.addRect(CGRect(x: 0.43, y: 0.68, width: 0.14, height: 0.15))
                q.addEllipse(in: CGRect(x: 0.43, y: 0.685, width: 0.14, height: 0.14))
                q.addEllipse(in: CGRect(x: 0.43, y: 0.67, width: 0.14, height: 0.025))
                p.addPath(q.strokedPath(StrokeStyle(lineWidth: 0.008)))
            }
            .fill(shade)
            // shoulders and draped cloak
            COPath { p in
                p.move(to: coPt(0.24, 0.565))
                p.addQuadCurve(to: coPt(0.43, 0.395), control: coPt(0.25, 0.41))
                p.addLine(to: coPt(0.57, 0.395))
                p.addQuadCurve(to: coPt(0.76, 0.565), control: coPt(0.75, 0.41))
                p.closeSubpath()
            }
            .fill(COC.marbleFill)
            COPath { p in
                p.coQuad(coPt(0.62, 0.41), coPt(0.5, 0.47), coPt(0.38, 0.56), 0.01)
                p.coQuad(coPt(0.66, 0.44), coPt(0.58, 0.5), coPt(0.5, 0.56), 0.008)
                p.coQuad(coPt(0.31, 0.47), coPt(0.33, 0.52), coPt(0.32, 0.56), 0.008)
            }
            .fill(shade.opacity(0.8))
            COPath { $0.coBox(0.455, 0.33, 0.09, 0.08) }.fill(Fr.marbleShade)
            // head
            COPath { $0.coOval(0.385, 0.115, 0.23, 0.25) }.fill(COC.marbleFill)
            COPath { p in
                for c in [coPt(0.405, 0.15), coPt(0.44, 0.122), coPt(0.48, 0.108), coPt(0.52, 0.108), coPt(0.56, 0.122), coPt(0.595, 0.15),
                          coPt(0.39, 0.195), coPt(0.61, 0.195)] { p.coDot(c.x, c.y, 0.032) }
            }
            .fill(curl)
            COPath { p in
                p.move(to: coPt(0.392, 0.25))
                p.addQuadCurve(to: coPt(0.5, 0.425), control: coPt(0.39, 0.41))
                p.addQuadCurve(to: coPt(0.608, 0.25), control: coPt(0.61, 0.41))
                p.addQuadCurve(to: coPt(0.392, 0.25), control: coPt(0.5, 0.34))
            }
            .fill(curl)
            COPath { p in
                // curls in the beard, eyes, brows, nose and mouth
                p.coQuad(coPt(0.43, 0.33), coPt(0.45, 0.37), coPt(0.44, 0.39), 0.007)
                p.coQuad(coPt(0.5, 0.35), coPt(0.51, 0.39), coPt(0.5, 0.41), 0.007)
                p.coQuad(coPt(0.57, 0.33), coPt(0.55, 0.37), coPt(0.56, 0.39), 0.007)
                p.coLine([coPt(0.44, 0.215), coPt(0.475, 0.21)], 0.008)
                p.coLine([coPt(0.525, 0.21), coPt(0.56, 0.215)], 0.008)
                p.coLine([coPt(0.44, 0.235), coPt(0.47, 0.235)], 0.009)
                p.coLine([coPt(0.53, 0.235), coPt(0.56, 0.235)], 0.009)
                p.coLine([coPt(0.5, 0.235), coPt(0.492, 0.28), coPt(0.505, 0.285)], 0.008)
                p.coQuad(coPt(0.47, 0.31), coPt(0.5, 0.295), coPt(0.53, 0.31), 0.008)
            }
            .fill(shade)
        }
    }
}

