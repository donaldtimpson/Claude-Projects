import SwiftUI

// MARK: - Wing: Library — the Bibliotheca (see VillaEstate.swift)
//
// A yellow-walled Pompeian library with a window onto the hills (Vitruvius wanted libraries to face
// the morning light) and a black-and-white mosaic floor. Along the back wall: the bust of Homer on his
// herm, the scroll cupboard with its pigeonholes, a wax tablet hung on a peg and a tall bronze
// lampstand with a flickering lamp. In front: the deluxe Aeneid on its stand, the scroll bucket, the
// reading couch and the writing desk. Everything is drawn in the garden's flat fresco style.

let libraryItems: [VillaItem] = [
    .init(id: "lib_tablet", name: "Wax Tablet", category: .garden, price: .denarii(45), blurb: "Write with a stylus, smooth the wax, write again.", place: "library"),
    .init(id: "lib_lamp", name: "Oil Lamp", category: .garden, price: .denarii(50), blurb: "Romans read at night by olive-oil lamps.", place: "library"),
    .init(id: "lib_shelf", name: "Scroll Shelf", category: .garden, price: .denarii(60), blurb: "Roman books were scrolls, kept in pigeonholes.", place: "library"),
    .init(id: "lib_capsa", name: "Scroll Bucket", category: .garden, price: .denarii(70), blurb: "A capsa: a round box for carrying scrolls.", place: "library"),
    .init(id: "lib_desk", name: "Writing Desk", category: .garden, price: .denarii(80), blurb: "Soot ink, a reed pen and a sheet of papyrus.", place: "library"),
    .init(id: "lib_couch", name: "Reading Couch", category: .garden, price: .denarii(120), blurb: "Romans often read lying down on a couch.", place: "library"),
    .init(id: "lib_homer", name: "Bust of Homer", category: .garden, price: .denarii(180), blurb: "The Greek poet who told of Odysseus and the Cyclops.", place: "library"),
    .init(id: "lib_virgil", name: "Virgil's Aeneid", category: .garden, price: .denarii(225), blurb: "Rome's great poem: Aeneas sails from Troy to Italy.", place: "library"),
]

/// Feet (canvas fractions) and box size of each thing; drawn back to front by `y`.
private let librarySpots: [String: (x: CGFloat, y: CGFloat, size: CGFloat)] = [
    "lib_tablet": (0.515, 0.44, 0.125),
    "lib_shelf": (0.29, 0.665, 0.40),
    "lib_homer": (0.095, 0.695, 0.27),
    "lib_lamp": (0.90, 0.72, 0.40),
    "lib_virgil": (0.68, 0.80, 0.28),
    "lib_capsa": (0.10, 0.945, 0.20),
    "lib_couch": (0.39, 0.965, 0.46),
    "lib_desk": (0.825, 0.995, 0.35),
]

// MARK: Palette and a small layout helper

private enum LibC {
    static let wood = LinearGradient(colors: [Color(hex: 0x9a5f2e), Color(hex: 0x683a18)], startPoint: .top, endPoint: .bottom)
    static let woodSide = LinearGradient(colors: [Color(hex: 0xa86a36), Color(hex: 0x6e3f1c)], startPoint: .leading, endPoint: .trailing)
    static let woodDark = Color(hex: 0x3f220e)
    static let woodMid = Color(hex: 0x7a4a22)
    static let bronze = LinearGradient(colors: [Color(hex: 0xd9a95a), Color(hex: 0x8a5a22)], startPoint: .leading, endPoint: .trailing)
    static let bronzeDark = Color(hex: 0x5e3c14)
    static let marble = LinearGradient(colors: [Fr.marble, Fr.marbleShade], startPoint: .leading, endPoint: .trailing)
    static let papyrus = Color(hex: 0xf1dfae)
    static let papyrusEdge = Color(hex: 0xc9ad6e)
    static let scrollEnd = Color(hex: 0xe9d29c)
}

private extension View {
    /// Frames a piece `bw × bh` (fractions of the box `w × h`) centred at (cx, cy).
    func lib(_ cx: CGFloat, _ cy: CGFloat, _ bw: CGFloat, _ bh: CGFloat, _ w: CGFloat, _ h: CGFloat) -> some View {
        frame(width: w * bw, height: h * bh).position(x: w * cx, y: h * cy)
    }
}

private struct LibPoly: Shape {
    let pts: [(CGFloat, CGFloat)]
    func path(in r: CGRect) -> Path {
        var p = Path()
        for (i, q) in pts.enumerated() {
            let pt = CGPoint(x: r.minX + q.0 * r.width, y: r.minY + q.1 * r.height)
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.closeSubpath()
        return p
    }
}

// MARK: The room

struct LibraryRoom: View {
    let s: WingState
    private var order: [VillaItem] {
        libraryItems.filter { s.has($0.id) }.sorted { (librarySpots[$0.id]?.y ?? 0) < (librarySpots[$1.id]?.y ?? 0) }
    }
    var body: some View {
        WingRoom(wall: Color(hex: 0xc98d36), panel: Color(hex: 0xe7c372), floor: Color(hex: 0xece0c4)) { w, h, t in
            ZStack(alignment: .topLeading) {
                LibFloor(w: w, h: h)
                LibGarlands(w: w, h: h)
                LibWindow(w: w, h: h, t: t)
                ForEach(order) { item in
                    if let p = librarySpots[item.id] {
                        WingSpot(x: p.x, y: p.y, size: p.size, w: w, h: h, lift: s.lift(item.id)) {
                            LibThing(id: item.id, t: t, room: true)
                        }
                        .onTapGesture { s.onTap(item.id) }
                    }
                }
            }
        }
    }
}

/// Which drawing an item is. `room` adds the floor shadow and the lamp's glow on the wall.
private struct LibThing: View {
    let id: String
    var t: Double = 0
    var room = false
    var body: some View {
        switch id {
        case "lib_tablet": LibTablet()
        case "lib_lamp": LibLampstand(t: t, glow: room)
        case "lib_shelf": LibShelf(shadow: room)
        case "lib_capsa": LibCapsa(shadow: room)
        case "lib_desk": LibDesk(shadow: room)
        case "lib_couch": LibCouch(shadow: room)
        case "lib_homer": LibHomer(shadow: room)
        case "lib_virgil": LibAeneid(shadow: room)
        default: Color.clear
        }
    }
}

private struct LibShadow: View {
    let w: CGFloat, h: CGFloat, width: CGFloat
    var body: some View {
        Ellipse().fill(Color.black.opacity(0.22)).frame(width: w * width, height: h * 0.07).position(x: w * 0.5, y: h * 0.985)
    }
}

/// The black-and-white mosaic floor: a wave border along the wall and a field of black crosslets.
private struct LibFloor: View {
    let w: CGFloat, h: CGFloat
    var body: some View {
        let y0 = h * 0.62, H = h * 1.0
        ZStack(alignment: .topLeading) {
            LibCrosslets().fill(Color(hex: 0x2b2622).opacity(0.75))
            // the border: two black bands with a running-wave between them
            Rectangle().fill(Color(hex: 0x2b2622)).frame(height: h * 0.008).offset(y: h * 0.022)
            LibWave().fill(Color(hex: 0x2b2622)).frame(height: h * 0.03).offset(y: h * 0.032)
            Rectangle().fill(Color(hex: 0x2b2622)).frame(height: h * 0.008).offset(y: h * 0.066)
            LinearGradient(colors: [Color.black.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom).frame(height: h * 0.05)
        }
        .frame(width: w * 3, height: H, alignment: .topLeading)
        .position(x: w * 0.5, y: y0 + H / 2)
        .allowsHitTesting(false)
    }
}

/// A "running dog" wave, the classic mosaic border.
private struct LibWave: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let s = r.height
        var x = r.minX
        p.move(to: CGPoint(x: x, y: r.maxY))
        while x < r.maxX {
            p.addLine(to: CGPoint(x: x, y: r.maxY))
            p.addQuadCurve(to: CGPoint(x: x + s * 0.9, y: r.minY + s * 0.15), control: CGPoint(x: x + s * 0.1, y: r.minY - s * 0.2))
            p.addQuadCurve(to: CGPoint(x: x + s * 0.7, y: r.midY + s * 0.1), control: CGPoint(x: x + s * 1.1, y: r.midY + s * 0.2))
            p.addQuadCurve(to: CGPoint(x: x + s * 1.4, y: r.maxY), control: CGPoint(x: x + s * 0.8, y: r.maxY))
            x += s * 1.4
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Small black crosses set in rows that shrink toward the wall (perspective).
private struct LibCrosslets: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let vx = r.midX, vy = r.minY - r.height * 1.4
        let rows = 9, cols = 40
        for i in 0..<rows {
            let v = (CGFloat(i) + 0.5) / CGFloat(rows)
            let y = r.minY + r.height * (0.12 + 0.88 * pow(v, 1.3))
            let s = (y - vy) / (r.maxY - vy)
            let k = r.width / CGFloat(cols) * 0.14 * s
            for j in 0..<cols {
                let u = (CGFloat(j) + (i % 2 == 0 ? 0.5 : 0)) / CGFloat(cols)
                let x = vx + (r.minX + r.width * u - vx) * s
                p.addRect(CGRect(x: x - k, y: y - k * 0.3, width: 2 * k, height: k * 0.6))
                p.addRect(CGRect(x: x - k * 0.3, y: y - k * 0.75, width: k * 0.6, height: k * 1.5))
            }
        }
        return p
    }
}

/// Painted garlands of laurel swagged along the top of the wall, tied with red ribbons.
private struct LibGarlands: View {
    let w: CGFloat, h: CGFloat
    var body: some View {
        let span = w * 0.26, y = h * 0.075
        ZStack(alignment: .topLeading) {
            ForEach(-6..<10, id: \.self) { i in
                let x0 = w * 0.07 + CGFloat(i) * span - w * 0.01
                LibSwag().stroke(Fr.leafDark, style: StrokeStyle(lineWidth: h * 0.022, lineCap: .round))
                    .frame(width: span, height: h * 0.05).position(x: x0 + span / 2, y: y + h * 0.025)
                LibSwag().stroke(Fr.leaf, style: StrokeStyle(lineWidth: h * 0.011, lineCap: .round, dash: [h * 0.012, h * 0.008]))
                    .frame(width: span, height: h * 0.05).position(x: x0 + span / 2, y: y + h * 0.023)
                // ribbon ends where two swags meet
                ForEach([-1.0, 1.0], id: \.self) { s in
                    Capsule().fill(Color(hex: 0xb8322a)).frame(width: h * 0.008, height: h * 0.04)
                        .rotationEffect(.degrees(s * 14)).position(x: x0 + CGFloat(s) * h * 0.006, y: y + h * 0.022)
                }
                Circle().fill(Color(hex: 0xb8322a)).frame(width: h * 0.014).position(x: x0, y: y)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct LibSwag: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY * 1.6 - r.minY * 0.6))
        return p
    }
}

/// An arched window in the back wall: open shutters, the hills and a drifting cloud.
private struct LibWindow: View {
    let w: CGFloat, h: CGFloat, t: Double
    var body: some View {
        let cx = w * 0.74, top = h * 0.11, ww = w * 0.19, wh = h * 0.36
        ZStack(alignment: .topLeading) {
            // shutters folded back against the wall
            ForEach([-1.0, 1.0], id: \.self) { s in
                LibShutter().fill(LibC.wood).overlay(LibShutter().stroke(LibC.woodDark, lineWidth: 1))
                    .frame(width: ww * 0.36, height: wh * 0.82)
                    .scaleEffect(x: CGFloat(-s), y: 1)
                    .position(x: cx + CGFloat(s) * (ww * 0.5 + ww * 0.2), y: top + wh * 0.56)
            }
            // marble surround
            LibArch().fill(LibC.marble).frame(width: ww * 1.16, height: wh * 1.06).position(x: cx, y: top + wh * 0.5)
            // the view
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [Color(hex: 0x8fbfd4), Color(hex: 0xf5e2b6)], startPoint: .top, endPoint: .bottom)
                LibCloud().fill(Color.white.opacity(0.9))
                    .frame(width: ww * 0.45, height: wh * 0.12)
                    .offset(x: CGFloat(((t * 0.015).truncatingRemainder(dividingBy: 1)) * 1.6 - 0.8) * ww, y: -wh * 0.62)
                LibHills(back: true).fill(Fr.hillBack).frame(height: wh * 0.42)
                LibHills(back: false).fill(Fr.hillFront).frame(height: wh * 0.3)
                ForEach([0.22, 0.32, 0.74], id: \.self) { fx in
                    Ellipse().fill(Fr.leafDark).frame(width: ww * 0.07, height: wh * 0.24)
                        .offset(x: ww * (CGFloat(fx) - 0.5), y: -wh * 0.2)
                }
            }
            .frame(width: ww, height: wh)
            .clipShape(LibArch())
            .position(x: cx, y: top + wh * 0.5)
            // mullion and transom, and a deep sill
            Rectangle().fill(LibC.woodMid).frame(width: ww * 0.03, height: wh * 0.98).position(x: cx, y: top + wh * 0.51)
            Rectangle().fill(LibC.woodMid).frame(width: ww, height: wh * 0.02).position(x: cx, y: top + wh * 0.42)
            Rectangle().fill(Fr.marbleShade).frame(width: ww * 1.34, height: h * 0.018).position(x: cx, y: top + wh + h * 0.006)
            Rectangle().fill(Color.black.opacity(0.18)).frame(width: ww * 1.3, height: h * 0.006).position(x: cx, y: top + wh + h * 0.018)
        }
        .allowsHitTesting(false)
    }
}

private struct LibArch: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let rad = r.width / 2
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + rad))
        p.addArc(center: CGPoint(x: r.midX, y: r.minY + rad), radius: rad, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// A shutter hinged on its right edge and folded back (drawn for the left side).
private struct LibShutter: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.05)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY - r.height * 0.05)); p.closeSubpath()
        for f in [0.33, 0.66] {
            let y = r.minY + r.height * CGFloat(f)
            p.move(to: CGPoint(x: r.minX, y: y)); p.addLine(to: CGPoint(x: r.maxX, y: y))
        }
        return p
    }
}

private struct LibHills: Shape {
    let back: Bool
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * (back ? 0.4 : 0.5)))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY + r.height * (back ? 0.2 : 0.6)), control: CGPoint(x: r.width * (back ? 0.25 : 0.2), y: r.minY - r.height * (back ? 0.1 : 0.1)))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + r.height * (back ? 0.05 : 0.3)), control: CGPoint(x: r.width * 0.8, y: r.minY + r.height * (back ? 0.5 : 0.5)))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct LibCloud: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: r.minX, y: r.midY - r.height * 0.1, width: r.width * 0.5, height: r.height * 0.6))
        p.addEllipse(in: CGRect(x: r.minX + r.width * 0.25, y: r.minY, width: r.width * 0.45, height: r.height * 0.9))
        p.addEllipse(in: CGRect(x: r.minX + r.width * 0.5, y: r.midY - r.height * 0.15, width: r.width * 0.5, height: r.height * 0.65))
        return p
    }
}

// MARK: The scroll shelf (armarium)

private struct LibScrollEnd: View {
    let tag: Color?
    var body: some View {
        GeometryReader { g in
            let d = min(g.size.width, g.size.height)
            ZStack {
                Circle().fill(RadialGradient(colors: [LibC.scrollEnd, LibC.papyrusEdge], center: .center, startRadius: 0, endRadius: d * 0.5))
                Circle().stroke(Color(hex: 0x9a7a3e).opacity(0.7), lineWidth: max(0.5, d * 0.06)).padding(d * 0.2)
                Circle().fill(Color(hex: 0x5e3c14)).frame(width: d * 0.22)
                if let tag {
                    Rectangle().fill(tag).frame(width: d * 0.28, height: d * 0.55).offset(x: d * 0.15, y: d * 0.5)
                }
            }
            .frame(width: g.size.width, height: g.size.height)
        }
    }
}

private struct LibShelf: View {
    var shadow = true
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let tags: [Color?] = [Color(hex: 0xb8322a), nil, nil, Color(hex: 0x3d6b8f), nil, Fr.gold, nil, nil, Color(hex: 0xb8322a), nil]
            ZStack(alignment: .topLeading) {
                if shadow { LibShadow(w: w, h: h, width: 0.95) }
                // pediment and cornice
                LibPoly(pts: [(0, 1), (0.5, 0), (1, 1)]).fill(LibC.wood).overlay(LibPoly(pts: [(0, 1), (0.5, 0), (1, 1)]).stroke(LibC.woodDark, lineWidth: 1))
                    .lib(0.5, 0.06, 0.86, 0.1, w, h)
                Circle().fill(Fr.gold).lib(0.5, 0.075, 0.05, 0.04, w, h)
                Rectangle().fill(LibC.woodSide).overlay(Rectangle().stroke(LibC.woodDark, lineWidth: 1)).lib(0.5, 0.125, 0.92, 0.035, w, h)
                // carcass
                Rectangle().fill(LibC.wood).overlay(Rectangle().stroke(LibC.woodDark, lineWidth: 1)).lib(0.5, 0.54, 0.82, 0.8, w, h)
                // pigeonholes: 3 across, 4 down, each full of scroll ends
                ForEach(0..<12, id: \.self) { i in
                    let c = i % 3, rr = i / 3
                    let cx = 0.5 + (CGFloat(c) - 1) * 0.25, cy = 0.24 + CGFloat(rr) * 0.155
                    Rectangle().fill(LinearGradient(colors: [Color(hex: 0x2a160a), Color(hex: 0x4a2a14)], startPoint: .top, endPoint: .bottom))
                        .lib(cx, cy, 0.22, 0.135, w, h)
                    // a pile of three, a fourth on top
                    ForEach(0..<4, id: \.self) { k in
                        let dx: CGFloat = k == 3 ? 0 : (CGFloat(k) - 1) * 0.068
                        let dy: CGFloat = k == 3 ? -0.03 : 0.03
                        LibScrollEnd(tag: (k == (i % 4)) ? tags[(i + k) % tags.count] : nil)
                            .lib(cx + dx + (k == 3 ? 0.034 * (i % 2 == 0 ? 1 : -1) : 0), cy + dy, 0.07, 0.07, w, h)
                    }
                }
                // a brass name plate and the plinth
                Rectangle().fill(LibC.woodSide).overlay(Rectangle().stroke(LibC.woodDark, lineWidth: 1)).lib(0.5, 0.88, 0.88, 0.05, w, h)
                Rectangle().fill(LibC.woodDark).lib(0.5, 0.94, 0.9, 0.07, w, h)
                ForEach([0.12, 0.88], id: \.self) { fx in
                    Rectangle().fill(LibC.woodMid).lib(CGFloat(fx), 0.975, 0.08, 0.04, w, h)
                }
            }
        }
    }
}

// MARK: Bust of Homer on a herm

private struct LibHomer: View {
    var shadow = true
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let stone = LibC.marble
            let line = Color(hex: 0x8f8778)
            ZStack(alignment: .topLeading) {
                if shadow { LibShadow(w: w, h: h, width: 0.62) }
                // the herm: a tapering pillar on a step
                Rectangle().fill(Fr.marbleShade).lib(0.5, 0.965, 0.6, 0.05, w, h)
                LibPoly(pts: [(0.08, 0), (0.92, 0), (1, 1), (0, 1)]).fill(stone).lib(0.5, 0.71, 0.4, 0.46, w, h)
                Text("ΟΜΗΡΟΣ").font(.system(size: w * 0.075, weight: .semibold, design: .serif)).foregroundStyle(Color(hex: 0x6f6758))
                    .lineLimit(1).minimumScaleFactor(0.5).lib(0.5, 0.6, 0.36, 0.08, w, h)
                // shoulders and drapery
                LibBust().fill(stone).overlay(LibBust().stroke(line.opacity(0.6), lineWidth: 0.6)).lib(0.5, 0.47, 0.6, 0.2, w, h)
                Path { p in
                    p.move(to: CGPoint(x: w * 0.3, y: h * 0.45)); p.addQuadCurve(to: CGPoint(x: w * 0.62, y: h * 0.55), control: CGPoint(x: w * 0.42, y: h * 0.54))
                    p.move(to: CGPoint(x: w * 0.36, y: h * 0.43)); p.addQuadCurve(to: CGPoint(x: w * 0.7, y: h * 0.5), control: CGPoint(x: w * 0.5, y: h * 0.5))
                }
                .stroke(line, lineWidth: max(0.6, w * 0.012))
                // head: the long beard first, then the face, a cap of curls and the fillet
                LibBeard().fill(LibC.marble).overlay(LibBeard().stroke(line, lineWidth: 0.6)).lib(0.5, 0.33, 0.36, 0.26, w, h)
                LibBeardStrands().stroke(line, style: StrokeStyle(lineWidth: max(0.5, w * 0.008), lineCap: .round)).lib(0.5, 0.33, 0.36, 0.26, w, h)
                Ellipse().fill(LinearGradient(colors: [Fr.marble, Color(hex: 0xe4ddcc)], startPoint: .leading, endPoint: .trailing)).lib(0.5, 0.24, 0.3, 0.25, w, h)
                ForEach(0..<9, id: \.self) { i in
                    let a = (195 + Double(i) * 18.75) * .pi / 180
                    Circle().fill(Fr.marble).overlay(Circle().stroke(line, lineWidth: 0.6))
                        .lib(0.5 + CGFloat(cos(a)) * 0.135, 0.245 + CGFloat(sin(a)) * 0.105, 0.075, 0.065, w, h)
                }
                Capsule().fill(Fr.marbleShade).overlay(Capsule().stroke(line, lineWidth: 0.6)).lib(0.5, 0.185, 0.29, 0.022, w, h)
                // features: blind, closed eyes, brows, nose and moustache
                Path { p in
                    for s in [-1.0, 1.0] {
                        let s = CGFloat(s)
                        p.move(to: CGPoint(x: w * (0.5 + s * 0.035), y: h * 0.235)); p.addQuadCurve(to: CGPoint(x: w * (0.5 + s * 0.11), y: h * 0.235), control: CGPoint(x: w * (0.5 + s * 0.07), y: h * 0.25))
                        p.move(to: CGPoint(x: w * (0.5 + s * 0.04), y: h * 0.222)); p.addQuadCurve(to: CGPoint(x: w * (0.5 + s * 0.12), y: h * 0.226), control: CGPoint(x: w * (0.5 + s * 0.08), y: h * 0.205))
                    }
                    p.move(to: CGPoint(x: w * 0.5, y: h * 0.235)); p.addLine(to: CGPoint(x: w * 0.485, y: h * 0.29)); p.addLine(to: CGPoint(x: w * 0.52, y: h * 0.29))
                    p.move(to: CGPoint(x: w * 0.42, y: h * 0.32)); p.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.32), control: CGPoint(x: w * 0.5, y: h * 0.295))
                }
                .stroke(line.opacity(0.85), style: StrokeStyle(lineWidth: max(0.6, w * 0.011), lineCap: .round))
            }
        }
    }
}

/// The bust's shoulders and chest, rounded on top and cut straight below.
private struct LibBust: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        var a = Path()
        a.move(to: p(0.12, 1.0))
        a.addQuadCurve(to: p(0.0, 0.62), control: p(0.0, 0.85))
        a.addQuadCurve(to: p(0.35, 0.05), control: p(0.02, 0.15))
        a.addLine(to: p(0.65, 0.05))
        a.addQuadCurve(to: p(1.0, 0.62), control: p(0.98, 0.15))
        a.addQuadCurve(to: p(0.88, 1.0), control: p(1.0, 0.85))
        a.closeSubpath()
        return a
    }
}

/// Homer's long beard, hanging from the cheeks to a rounded point.
private struct LibBeard: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        var a = Path()
        a.move(to: p(0.08, 0.05))
        a.addQuadCurve(to: p(0.5, 1.0), control: p(0.0, 0.85))
        a.addQuadCurve(to: p(0.92, 0.05), control: p(1.0, 0.85))
        a.addQuadCurve(to: p(0.08, 0.05), control: p(0.5, 0.35))
        a.closeSubpath()
        return a
    }
}

private struct LibBeardStrands: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        var a = Path()
        for x in [0.25, 0.4, 0.55, 0.7] {
            let x = CGFloat(x)
            a.move(to: p(x, 0.35)); a.addQuadCurve(to: p(x + (0.5 - x) * 0.4, 0.85), control: p(x + 0.06, 0.6))
        }
        return a
    }
}

// MARK: Bronze lampstand with an oil lamp

private struct LibLampstand: View {
    let t: Double
    var glow = true
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let f = 1 + 0.12 * sin(t * 13) + 0.07 * sin(t * 7.3 + 1)       // the flame flickers
            ZStack(alignment: .topLeading) {
                if glow {
                    Circle().fill(RadialGradient(colors: [Color(hex: 0xffd77a).opacity(0.38 * f), Color(hex: 0xffd77a).opacity(0)], center: .center, startRadius: 0, endRadius: w * 0.55))
                        .frame(width: w * 1.1, height: w * 1.1).position(x: w * 0.7, y: h * 0.12)
                        .blendMode(.screen)
                    Ellipse().fill(Color.black.opacity(0.2)).lib(0.5, 0.985, 0.5, 0.04, w, h)
                }
                // tripod of lion legs
                ForEach([-1.0, 1.0], id: \.self) { s in
                    LibPoly(pts: [(0.4, 0), (0.6, 0), (1, 0.85), (1, 1), (0.6, 1), (0.55, 0.85)])
                        .fill(LibC.bronze)
                        .frame(width: w * 0.16, height: h * 0.12)
                        .scaleEffect(x: CGFloat(s), y: 1)
                        .position(x: w * (0.5 + CGFloat(s) * 0.09), y: h * 0.93)
                }
                Ellipse().fill(Color(hex: 0x8a5a22)).lib(0.5, 0.875, 0.16, 0.025, w, h)
                // fluted shaft with two knops
                Rectangle().fill(LibC.bronze).lib(0.5, 0.52, 0.045, 0.7, w, h)
                ForEach([0.66, 0.36], id: \.self) { y in
                    Ellipse().fill(LibC.bronze).overlay(Ellipse().stroke(LibC.bronzeDark, lineWidth: 0.5)).lib(0.5, CGFloat(y), 0.1, 0.03, w, h)
                }
                // the dish on top
                LibPoly(pts: [(0, 0), (1, 0), (0.75, 1), (0.25, 1)]).fill(LibC.bronze).overlay(LibPoly(pts: [(0, 0), (1, 0), (0.75, 1), (0.25, 1)]).stroke(LibC.bronzeDark, lineWidth: 0.6))
                    .lib(0.5, 0.165, 0.32, 0.04, w, h)
                // the clay lamp: round body, nozzle to the right, ring handle at the back
                Circle().stroke(Color(hex: 0x9a4a26), lineWidth: max(1, w * 0.025)).lib(0.33, 0.12, 0.09, 0.05, w, h)
                LibPoly(pts: [(0, 0.2), (0.75, 0.35), (1, 0.15), (1, 0.85), (0.75, 0.85), (0, 1)])
                    .fill(LinearGradient(colors: [Color(hex: 0xd27a48), Color(hex: 0x9a4a26)], startPoint: .top, endPoint: .bottom))
                    .lib(0.62, 0.13, 0.2, 0.035, w, h)
                Ellipse().fill(LinearGradient(colors: [Color(hex: 0xe08c58), Color(hex: 0xa2522c)], startPoint: .top, endPoint: .bottom))
                    .lib(0.47, 0.128, 0.26, 0.055, w, h)
                Ellipse().stroke(Color(hex: 0x7a3a1c), lineWidth: 0.7).lib(0.47, 0.12, 0.13, 0.022, w, h)
                // flame
                LibFlame().fill(LinearGradient(colors: [Color(hex: 0xfff3b0), Color(hex: 0xffb43c), Color(hex: 0xe8602a)], startPoint: .bottom, endPoint: .top))
                    .frame(width: w * 0.07, height: h * 0.075 * f)
                    .position(x: w * 0.72, y: h * (0.112 - 0.0375 * f))
            }
        }
    }
}

private struct LibFlame: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY), control: CGPoint(x: r.maxX + r.width * 0.4, y: r.maxY - r.height * 0.1))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY), control: CGPoint(x: r.minX - r.width * 0.4, y: r.maxY - r.height * 0.1))
        return p
    }
}

// MARK: Wax tablet on a peg

private struct LibTablet: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                // peg and cord
                Circle().fill(LibC.woodDark).lib(0.5, 0.06, 0.08, 0.08, w, h)
                Path { p in
                    p.move(to: CGPoint(x: w * 0.5, y: h * 0.06)); p.addLine(to: CGPoint(x: w * 0.22, y: h * 0.32))
                    p.move(to: CGPoint(x: w * 0.5, y: h * 0.06)); p.addLine(to: CGPoint(x: w * 0.78, y: h * 0.32))
                }
                .stroke(Color(hex: 0x6e4a2c), lineWidth: max(0.7, w * 0.015))
                // two wooden leaves, black wax with letters scratched in
                ForEach([0.27, 0.73], id: \.self) { cx in
                    RoundedRectangle(cornerRadius: w * 0.02).fill(LibC.wood).overlay(RoundedRectangle(cornerRadius: w * 0.02).stroke(LibC.woodDark, lineWidth: 0.8))
                        .lib(CGFloat(cx), 0.6, 0.44, 0.58, w, h)
                    Rectangle().fill(Color(hex: 0x2e2a20)).lib(CGFloat(cx), 0.6, 0.34, 0.46, w, h)
                }
                Text("SALVE").font(luCinzel(w * 0.09, bold: true)).foregroundStyle(Color(hex: 0xd9c49a))
                    .lineLimit(1).minimumScaleFactor(0.5).lib(0.27, 0.48, 0.32, 0.12, w, h)
                Text("ABC").font(luCinzel(w * 0.09, bold: true)).foregroundStyle(Color(hex: 0xd9c49a))
                    .lineLimit(1).minimumScaleFactor(0.5).lib(0.73, 0.48, 0.32, 0.12, w, h)
                ForEach(0..<3, id: \.self) { i in
                    ForEach([0.27, 0.73], id: \.self) { cx in
                        Capsule().fill(Color(hex: 0xd9c49a).opacity(0.55)).lib(CGFloat(cx) - 0.02 * CGFloat(i % 2), 0.6 + CGFloat(i) * 0.09, 0.24 - CGFloat(i) * 0.04, 0.018, w, h)
                    }
                }
                // the stylus hanging on its string: sharp end writes, flat end rubs out
                Path { p in p.move(to: CGPoint(x: w * 0.5, y: h * 0.33)); p.addLine(to: CGPoint(x: w * 0.53, y: h * 0.62)) }
                    .stroke(Color(hex: 0x6e4a2c), lineWidth: 0.6)
                LibPoly(pts: [(0.3, 0), (0.7, 0), (0.6, 0.85), (0.5, 1), (0.4, 0.85)]).fill(LibC.bronze)
                    .lib(0.53, 0.82, 0.07, 0.4, w, h)
            }
        }
    }
}

// MARK: Capsa

private struct LibCapsa: View {
    var shadow = true
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let leather = LinearGradient(colors: [Color(hex: 0x9a4a2a), Color(hex: 0xc0663a), Color(hex: 0x7a3418)], startPoint: .leading, endPoint: .trailing)
            ZStack(alignment: .topLeading) {
                if shadow { LibShadow(w: w, h: h, width: 0.8) }
                // scrolls standing up inside, with tags
                ForEach(0..<5, id: \.self) { i in
                    let x = 0.26 + CGFloat(i) * 0.12
                    let y = 0.22 + CGFloat([0.04, -0.02, 0.01, -0.04, 0.05][i])
                    Rectangle().fill(LinearGradient(colors: [LibC.papyrus, LibC.papyrusEdge], startPoint: .leading, endPoint: .trailing))
                        .lib(x, y + 0.12, 0.11, 0.24, w, h)
                    Ellipse().fill(LibC.scrollEnd).overlay(Ellipse().stroke(Color(hex: 0x9a7a3e), lineWidth: 0.6)).lib(x, y, 0.11, 0.05, w, h)
                    if i % 2 == 0 {
                        Rectangle().fill(i == 2 ? Color(hex: 0x3d6b8f) : Color(hex: 0xb8322a)).lib(x + 0.03, y + 0.07, 0.035, 0.09, w, h)
                    }
                }
                // the leather drum with bronze bands
                Rectangle().fill(leather).lib(0.5, 0.68, 0.7, 0.56, w, h)
                Ellipse().fill(leather).lib(0.5, 0.96, 0.7, 0.07, w, h)
                Ellipse().stroke(Color(hex: 0x5a2410), lineWidth: max(1, w * 0.02)).lib(0.5, 0.4, 0.7, 0.07, w, h)
                ForEach([0.5, 0.86], id: \.self) { y in
                    Rectangle().fill(LibC.bronze).lib(0.5, CGFloat(y), 0.72, 0.045, w, h)
                }
                // carrying strap
                Path { p in
                    p.move(to: CGPoint(x: w * 0.16, y: h * 0.5)); p.addQuadCurve(to: CGPoint(x: w * 0.84, y: h * 0.5), control: CGPoint(x: w * 0.5, y: h * 0.0))
                }
                .stroke(Color(hex: 0x5a2410), style: StrokeStyle(lineWidth: max(1.2, w * 0.035), lineCap: .round))
                ForEach([0.16, 0.84], id: \.self) { x in Circle().fill(Fr.gold).lib(CGFloat(x), 0.5, 0.06, 0.06, w, h) }
            }
        }
    }
}

// MARK: Writing desk

private struct LibDesk: View {
    var shadow = true
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                if shadow { LibShadow(w: w, h: h, width: 0.95) }
                // turned legs with a stretcher
                ForEach([0.1, 0.9], id: \.self) { x in
                    LibTurnedLeg().fill(LibC.woodSide).lib(CGFloat(x), 0.79, 0.09, 0.4, w, h)
                }
                Rectangle().fill(LibC.woodMid).lib(0.5, 0.86, 0.78, 0.03, w, h)
                // apron and top
                Rectangle().fill(LibC.wood).overlay(Rectangle().stroke(LibC.woodDark, lineWidth: 1)).lib(0.5, 0.56, 0.96, 0.08, w, h)
                ForEach([0.3, 0.7], id: \.self) { x in
                    Circle().fill(Fr.gold).lib(CGFloat(x), 0.56, 0.035, 0.035, w, h)
                }
                LibPoly(pts: [(0.03, 0), (0.97, 0), (1, 1), (0, 1)]).fill(Color(hex: 0xb07440)).overlay(LibPoly(pts: [(0.03, 0), (0.97, 0), (1, 1), (0, 1)]).stroke(LibC.woodDark, lineWidth: 1))
                    .lib(0.5, 0.505, 1.02, 0.04, w, h)
                // a sheet of papyrus with lines of writing
                LibPoly(pts: [(0.1, 0), (0.95, 0.05), (0.9, 1), (0, 0.92)]).fill(LibC.papyrus).overlay(LibPoly(pts: [(0.1, 0), (0.95, 0.05), (0.9, 1), (0, 0.92)]).stroke(LibC.papyrusEdge, lineWidth: 0.7))
                    .lib(0.4, 0.44, 0.42, 0.1, w, h)
                ForEach(0..<3, id: \.self) { i in
                    Capsule().fill(Fr.ink.opacity(0.55)).lib(0.4, 0.415 + CGFloat(i) * 0.024, 0.28 - CGFloat(i) * 0.03, 0.009, w, h)
                }
                // a rolled scroll
                Capsule().fill(LinearGradient(colors: [LibC.papyrus, LibC.papyrusEdge], startPoint: .top, endPoint: .bottom))
                    .overlay(Capsule().stroke(Color(hex: 0x9a7a3e), lineWidth: 0.6)).lib(0.16, 0.465, 0.22, 0.05, w, h)
                Circle().fill(Color(hex: 0x5e3c14)).lib(0.06, 0.465, 0.03, 0.03, w, h)
                // bronze inkwell with its lid, and the reed pen
                Rectangle().fill(LibC.bronze).lib(0.78, 0.43, 0.12, 0.09, w, h)
                Ellipse().fill(Color(hex: 0xe6bd6e)).overlay(Ellipse().stroke(LibC.bronzeDark, lineWidth: 0.6)).lib(0.78, 0.387, 0.12, 0.03, w, h)
                Circle().fill(Color(hex: 0x1a1410)).lib(0.78, 0.387, 0.04, 0.015, w, h)
                Capsule().fill(Color(hex: 0xc7a35a)).overlay(Capsule().stroke(Color(hex: 0x8a6a22), lineWidth: 0.5))
                    .frame(width: w * 0.3, height: max(1.5, h * 0.016)).rotationEffect(.degrees(-38))
                    .position(x: w * 0.86, y: h * 0.33)
            }
        }
    }
}

private struct LibTurnedLeg: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let x = r.midX, w = r.width
        func band(_ y: CGFloat, _ k: CGFloat, _ hh: CGFloat) {
            p.addEllipse(in: CGRect(x: x - w * k / 2, y: r.minY + r.height * y, width: w * k, height: r.height * hh))
        }
        p.addRect(CGRect(x: x - w * 0.22, y: r.minY, width: w * 0.44, height: r.height * 0.95))
        band(0.04, 0.9, 0.1); band(0.3, 1.0, 0.16); band(0.6, 0.8, 0.12); band(0.88, 0.7, 0.12)
        return p
    }
}

// MARK: Reading couch (lectus)

private struct LibCouch: View {
    var shadow = true
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                if shadow { LibShadow(w: w, h: h, width: 0.98) }
                // turned legs
                ForEach([0.1, 0.9], id: \.self) { x in
                    LibTurnedLeg().fill(LibC.bronze).lib(CGFloat(x), 0.86, 0.07, 0.24, w, h)
                }
                // frame
                Rectangle().fill(LibC.wood).overlay(Rectangle().stroke(LibC.woodDark, lineWidth: 1)).lib(0.5, 0.73, 0.94, 0.06, w, h)
                Rectangle().fill(Fr.gold.opacity(0.8)).lib(0.5, 0.715, 0.9, 0.008, w, h)
                // striped mattress
                RoundedRectangle(cornerRadius: h * 0.03).fill(Color(hex: 0xf1e2c0)).lib(0.5, 0.655, 0.9, 0.09, w, h)
                ForEach(0..<6, id: \.self) { i in
                    Rectangle().fill(Color(hex: 0xb8322a).opacity(0.85)).lib(0.13 + CGFloat(i) * 0.148, 0.655, 0.045, 0.09, w, h)
                }
                // the curved headrest (fulcrum), trimmed in bronze, with a medallion at its foot
                LibFulcrumCurve().stroke(LibC.woodMid, style: StrokeStyle(lineWidth: w * 0.045, lineCap: .round))
                LibFulcrumCurve().stroke(Color(hex: 0xd9a95a), style: StrokeStyle(lineWidth: w * 0.012, lineCap: .round))
                Circle().fill(LibC.bronze).overlay(Circle().stroke(LibC.bronzeDark, lineWidth: 0.6)).lib(0.075, 0.665, 0.065, 0.065, w, h)
                // a soft cushion and an open scroll left on the couch
                Capsule().fill(LinearGradient(colors: [Color(hex: 0x4f7a3a), Color(hex: 0x355a29)], startPoint: .top, endPoint: .bottom))
                    .rotationEffect(.degrees(-8)).lib(0.25, 0.575, 0.24, 0.1, w, h)
                Rectangle().fill(LibC.papyrus).overlay(Rectangle().stroke(LibC.papyrusEdge, lineWidth: 0.6)).lib(0.62, 0.592, 0.2, 0.05, w, h)
                ForEach([0.51, 0.73], id: \.self) { x in
                    Capsule().fill(LinearGradient(colors: [LibC.papyrus, LibC.papyrusEdge], startPoint: .leading, endPoint: .trailing))
                        .overlay(Capsule().stroke(Color(hex: 0x9a7a3e), lineWidth: 0.6)).lib(CGFloat(x), 0.59, 0.05, 0.075, w, h)
                }
                ForEach(0..<2, id: \.self) { i in
                    Capsule().fill(Fr.ink.opacity(0.5)).lib(0.62, 0.58 + CGFloat(i) * 0.02, 0.13, 0.006, w, h)
                }
            }
        }
    }
}

private struct LibFulcrumCurve: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        var a = Path()
        a.move(to: p(0.075, 0.66))
        a.addQuadCurve(to: p(0.06, 0.47), control: p(0.02, 0.56))
        a.addQuadCurve(to: p(0.13, 0.46), control: p(0.08, 0.42))
        a.addQuadCurve(to: p(0.27, 0.61), control: p(0.17, 0.55))
        return a
    }
}

private struct LibFulcrum: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.15, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.1), control: CGPoint(x: r.minX - r.width * 0.05, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.15), control: CGPoint(x: r.minX + r.width * 0.15, y: r.minY - r.height * 0.1))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY - r.height * 0.35), control: CGPoint(x: r.minX + r.width * 0.4, y: r.maxY - r.height * 0.4))
        p.closeSubpath()
        return p
    }
}

// MARK: Virgil's Aeneid on its stand

private struct LibAeneid: View {
    var shadow = true
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                if shadow { LibShadow(w: w, h: h, width: 0.6) }
                // a slender bronze stand: three legs, a column, a sloping rest
                ForEach([-1.0, 1.0], id: \.self) { s in
                    LibPoly(pts: [(0.4, 0), (0.6, 0), (1, 0.9), (1, 1), (0.7, 1)]).fill(LibC.bronze)
                        .frame(width: w * 0.2, height: h * 0.16)
                        .scaleEffect(x: CGFloat(s), y: 1)
                        .position(x: w * (0.5 + CGFloat(s) * 0.09), y: h * 0.91)
                }
                Rectangle().fill(LibC.bronze).lib(0.5, 0.66, 0.05, 0.42, w, h)
                Ellipse().fill(LibC.bronze).overlay(Ellipse().stroke(LibC.bronzeDark, lineWidth: 0.5)).lib(0.5, 0.62, 0.12, 0.035, w, h)
                LibPoly(pts: [(0.06, 0), (0.94, 0), (1, 1), (0, 1)]).fill(LibC.wood).overlay(LibPoly(pts: [(0.06, 0), (0.94, 0), (1, 1), (0, 1)]).stroke(LibC.woodDark, lineWidth: 0.8))
                    .lib(0.5, 0.445, 0.96, 0.05, w, h)
                // the open scroll: papyrus sheet between two rolled ends with gilded knobs
                Rectangle().fill(LibC.papyrus).overlay(Rectangle().stroke(LibC.papyrusEdge, lineWidth: 0.6)).lib(0.5, 0.31, 0.66, 0.24, w, h)
                Text("ARMA VIRVMQVE CANO").font(luCinzel(w * 0.05, bold: true)).foregroundStyle(Fr.ink)
                    .lineLimit(1).minimumScaleFactor(0.3).lib(0.5, 0.235, 0.6, 0.05, w, h)
                ForEach(0..<4, id: \.self) { i in
                    Capsule().fill(Fr.ink.opacity(0.45)).lib(0.5 - CGFloat(i % 2) * 0.03, 0.29 + CGFloat(i) * 0.04, 0.52 - CGFloat(i % 2) * 0.06, 0.012, w, h)
                }
                ForEach([0.14, 0.86], id: \.self) { x in
                    Capsule().fill(LinearGradient(colors: [Color(hex: 0xd9c08a), LibC.papyrus, Color(hex: 0xb8995a)], startPoint: .leading, endPoint: .trailing))
                        .overlay(Capsule().stroke(Color(hex: 0x9a7a3e), lineWidth: 0.6)).lib(CGFloat(x), 0.31, 0.11, 0.3, w, h)
                    ForEach([0.145, 0.475], id: \.self) { y in
                        Circle().fill(RadialGradient(colors: [Color(hex: 0xfff0b0), Fr.gold, Color(hex: 0x8e6410)], center: UnitPoint(x: 0.35, y: 0.35), startRadius: 0, endRadius: w * 0.04))
                            .lib(CGFloat(x), CGFloat(y), 0.07, 0.07, w, h)
                    }
                }
                // the red title tag
                LibPoly(pts: [(0, 0), (1, 0), (1, 1), (0.5, 0.8), (0, 1)]).fill(Color(hex: 0xb8322a)).lib(0.86, 0.55, 0.07, 0.12, w, h)
            }
        }
    }
}

// MARK: Card thumbnails

/// The part of each drawing's box that holds the picture (x0, x1, y0, y1), so the card can frame it.
private let libraryThumbBox: [String: (CGFloat, CGFloat, CGFloat, CGFloat)] = [
    "lib_tablet": (0.03, 0.97, 0.02, 1.0),
    "lib_lamp": (0.22, 0.88, 0.04, 0.5),       // the lamp itself, on the top of its stand
    "lib_shelf": (0.05, 0.95, 0.0, 1.0),
    "lib_capsa": (0.08, 0.98, 0.08, 1.0),
    "lib_desk": (0.0, 1.0, 0.27, 1.0),
    "lib_couch": (0.0, 1.0, 0.42, 1.0),
    "lib_homer": (0.17, 0.83, 0.1, 1.0),
    "lib_virgil": (0.06, 0.94, 0.12, 1.0),
]

struct LibraryThumb: View {
    let id: String
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let b = libraryThumbBox[id] ?? (0, 1, 0, 1)
            let f = min(w * 0.9 / (b.1 - b.0), h * 0.86 / (b.3 - b.2))
            LibThing(id: id)
                .frame(width: f, height: f)
                .offset(x: (0.5 - (b.0 + b.1) / 2) * f, y: (0.5 - (b.2 + b.3) / 2) * f)
                .frame(width: w, height: h)
                .clipped()
        }
    }
}
