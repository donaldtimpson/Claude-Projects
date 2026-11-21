import SwiftUI

// MARK: - Wing: Tablinum — the Coin Cabinet (see VillaEstate.swift)
//
// The tablinum was the master's study off the atrium, where the family's records and treasures were
// kept. Here it holds a collector's cabinet: a walnut case with two navy-velvet trays, one slot per
// coin, laid out oldest to newest (Republic on the top tray, Empire below). An empty slot shows as a
// faint ring with its name plate, so the child can see what is left to collect. Above the cabinet
// hang the family's ancestor masks in their little shrines, joined by a painted family tree.
// Coins are drawn as real coins: an irregular struck flan in gold, silver, bronze or brass, a
// beaded border, the portrait or type in relief and the real legend around the rim.

let tablinumItems: [VillaItem] = [
    .init(id: "coin_janus", name: "Janus As", category: .garden, price: .denarii(40), blurb: "A bronze coin with two-faced Janus, god of doorways.", place: "tablinum"),
    .init(id: "coin_wolf", name: "She-Wolf Coin", category: .garden, price: .denarii(45), blurb: "Silver: the wolf that fed the twins Romulus and Remus.", place: "tablinum"),
    .init(id: "coin_nero", name: "Nero Sestertius", category: .garden, price: .denarii(75), blurb: "A big brass coin of the emperor Nero.", place: "tablinum"),
    .init(id: "coin_caesar", name: "Caesar Denarius", category: .garden, price: .denarii(90), blurb: "Julius Caesar: the first living Roman on a coin, 44 BC.", place: "tablinum"),
    .init(id: "coin_trajan", name: "Trajan Denarius", category: .garden, price: .denarii(90), blurb: "Under Trajan the empire was at its largest.", place: "tablinum"),
    .init(id: "coin_augustus", name: "Augustus Aureus", category: .garden, price: .denarii(120), blurb: "Rome's first emperor, in gold.", place: "tablinum"),
    .init(id: "coin_hadrian", name: "Hadrian Aureus", category: .garden, price: .denarii(135), blurb: "The emperor who built a wall across Britain.", place: "tablinum"),
    .init(id: "coin_constantine", name: "Constantine Solidus", category: .garden, price: .denarii(180), blurb: "A gold coin that stayed in use for over 700 years.", place: "tablinum"),
    .init(id: "tab_masks", name: "Ancestor Masks", category: .garden, price: .denarii(150), blurb: "Roman families kept wax masks of their ancestors.", place: "tablinum"),
]

// MARK: The coins

private enum TabMetal {
    case gold, silver, bronze, brass
    var light: Color {
        switch self {
        case .gold: return Color(hex: 0xfff0b0)
        case .silver: return Color(hex: 0xfbfbf7)
        case .bronze: return Color(hex: 0xe0a877)
        case .brass: return Color(hex: 0xf2d692)
        }
    }
    var mid: Color {
        switch self {
        case .gold: return Color(hex: 0xe3b23e)
        case .silver: return Color(hex: 0xbfc2c2)
        case .bronze: return Color(hex: 0xa6683c)
        case .brass: return Color(hex: 0xc39a4a)
        }
    }
    var dark: Color {
        switch self {
        case .gold: return Color(hex: 0x8e6410)
        case .silver: return Color(hex: 0x6b7072)
        case .bronze: return Color(hex: 0x5a3519)
        case .brass: return Color(hex: 0x6e5020)
        }
    }
}

private enum TabDevice { case head(beard: Bool, diadem: Bool, plump: CGFloat), janus, wolf }

private struct TabCoinSpec {
    let id: String
    let label: String        // the name plate under its slot
    let metal: TabMetal
    let device: TabDevice
    let legend: String       // around the rim, clockwise from lower left
    var top: String = ""     // a mark above the type (the as's value mark "I")
    var exergue: String = "" // a line under the type
    var big = false          // the as and the sestertius are big coins
    let seed: Double         // the shape of the hand-struck flan
}

/// Oldest to newest: the Republic on the top tray, the Empire below.
private let tabCoins: [TabCoinSpec] = [
    .init(id: "coin_wolf", label: "She-Wolf", metal: .silver, device: .wolf, legend: "", exergue: "ROMANO", seed: 1.3),
    .init(id: "coin_janus", label: "Janus", metal: .bronze, device: .janus, legend: "", top: "I", big: true, seed: 4.1),
    .init(id: "coin_caesar", label: "Caesar", metal: .silver, device: .head(beard: false, diadem: false, plump: -0.4),
          legend: "CAESAR·DICT·PERPETVO", seed: 2.2),
    .init(id: "coin_augustus", label: "Augustus", metal: .gold, device: .head(beard: false, diadem: false, plump: 0),
          legend: "CAESAR AVGVSTVS DIVI F PATER PATRIAE", seed: 5.7),
    .init(id: "coin_nero", label: "Nero", metal: .brass, device: .head(beard: false, diadem: false, plump: 1),
          legend: "NERO CLAVD CAESAR AVG GER P M TR P IMP P P", big: true, seed: 0.6),
    .init(id: "coin_trajan", label: "Trajan", metal: .silver, device: .head(beard: false, diadem: false, plump: 0.3),
          legend: "IMP TRAIANO AVG GER DAC P M TR P", seed: 3.4),
    .init(id: "coin_hadrian", label: "Hadrian", metal: .gold, device: .head(beard: true, diadem: false, plump: 0.2),
          legend: "HADRIANVS AVGVSTVS", seed: 6.2),
    .init(id: "coin_constantine", label: "Constantine", metal: .gold, device: .head(beard: false, diadem: true, plump: 0.2),
          legend: "CONSTANTINVS P F AVG", seed: 2.9),
]

/// A hand-struck flan: round, but never perfectly.
private struct TabFlan: Shape {
    let seed: Double
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY), rad = min(r.width, r.height) / 2
        for i in 0...60 {
            let a = Double(i) / 60 * .pi * 2
            let k = 0.975 + 0.018 * sin(3 * a + seed) + 0.009 * sin(5 * a + seed * 2.3)
            let pt = CGPoint(x: c.x + CGFloat(cos(a) * k) * rad, y: c.y + CGFloat(sin(a) * k) * rad)
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.closeSubpath()
        return p
    }
}

/// The beaded border just inside the rim.
private struct TabBeads: Shape {
    var n = 44
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY), rad = min(r.width, r.height) / 2, b = rad * 0.045
        for i in 0..<n {
            let a = Double(i) / Double(n) * .pi * 2
            p.addEllipse(in: CGRect(x: c.x + CGFloat(cos(a)) * rad - b, y: c.y + CGFloat(sin(a)) * rad - b, width: 2 * b, height: 2 * b))
        }
        return p
    }
}

/// A Roman portrait head in profile, facing right, in a unit box (neck truncated at the bottom).
private struct TabHead: Shape {
    var plump: CGFloat = 0
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        let j = plump
        var a = Path()
        a.move(to: p(0.31, 0.97))
        a.addQuadCurve(to: p(0.28, 0.71), control: p(0.32 - j * 0.02, 0.83))
        a.addQuadCurve(to: p(0.19, 0.50), control: p(0.19, 0.63))
        a.addQuadCurve(to: p(0.47, 0.13), control: p(0.15, 0.17))
        a.addQuadCurve(to: p(0.71, 0.31), control: p(0.67, 0.13))
        a.addQuadCurve(to: p(0.715, 0.395), control: p(0.735, 0.36))
        a.addQuadCurve(to: p(0.805, 0.525), control: p(0.74, 0.45))
        a.addQuadCurve(to: p(0.745, 0.555), control: p(0.79, 0.56))
        a.addLine(to: p(0.765, 0.59))
        a.addLine(to: p(0.74, 0.61))
        a.addLine(to: p(0.755, 0.645))
        a.addQuadCurve(to: p(0.715 + j * 0.02, 0.745 + j * 0.02), control: p(0.76 + j * 0.01, 0.71))
        a.addQuadCurve(to: p(0.60, 0.80 + j * 0.03), control: p(0.67 + j * 0.06, 0.81 + j * 0.05))
        a.addQuadCurve(to: p(0.67, 0.97), control: p(0.585, 0.89))
        a.closeSubpath()
        return a
    }
}

/// The chased-in details of a head: eye, brow, ear, hair curls, mouth.
private struct TabHeadLines: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        var a = Path()
        // eye and brow
        a.move(to: p(0.60, 0.42)); a.addQuadCurve(to: p(0.67, 0.425), control: p(0.635, 0.395))
        a.move(to: p(0.60, 0.42)); a.addQuadCurve(to: p(0.67, 0.425), control: p(0.635, 0.45))
        a.move(to: p(0.57, 0.37)); a.addQuadCurve(to: p(0.70, 0.375), control: p(0.64, 0.34))
        // mouth
        a.move(to: p(0.745, 0.61)); a.addLine(to: p(0.70, 0.62))
        // ear
        a.move(to: p(0.42, 0.42)); a.addQuadCurve(to: p(0.43, 0.56), control: p(0.35, 0.48))
        a.move(to: p(0.42, 0.45)); a.addQuadCurve(to: p(0.425, 0.52), control: p(0.39, 0.485))
        // hair: rows of comma curls over the skull
        for (cx, cy) in [(0.30, 0.30), (0.40, 0.24), (0.52, 0.22), (0.27, 0.42), (0.36, 0.34), (0.47, 0.31), (0.58, 0.27), (0.30, 0.55), (0.25, 0.62)] {
            let c = p(CGFloat(cx), CGFloat(cy)), s = r.width * 0.045
            a.move(to: CGPoint(x: c.x - s, y: c.y + s * 0.4))
            a.addQuadCurve(to: CGPoint(x: c.x + s, y: c.y + s * 0.2), control: CGPoint(x: c.x, y: c.y - s * 1.3))
        }
        return a
    }
}

/// A laurel wreath over the crown, tied at the back with two ribbons.
private struct TabLaurel: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        var a = Path()
        let c = p(0.45, 0.50), rad = r.width * 0.30
        for i in 0..<9 {
            let ang = (188 + Double(i) * 13.5) * .pi / 180
            let base = CGPoint(x: c.x + CGFloat(cos(ang)) * rad, y: c.y + CGFloat(sin(ang)) * rad * 1.05)
            for side in [-1.0, 1.0] {
                let la = ang + .pi / 2 + side * 0.9 + .pi * 0.15
                let len = r.width * 0.085
                let tip = CGPoint(x: base.x + CGFloat(cos(la)) * len, y: base.y + CGFloat(sin(la)) * len)
                let n = CGPoint(x: -CGFloat(sin(la)) * len * 0.32, y: CGFloat(cos(la)) * len * 0.32)
                let mid = CGPoint(x: (base.x + tip.x) / 2, y: (base.y + tip.y) / 2)
                a.move(to: base)
                a.addQuadCurve(to: tip, control: CGPoint(x: mid.x + n.x, y: mid.y + n.y))
                a.addQuadCurve(to: base, control: CGPoint(x: mid.x - n.x, y: mid.y - n.y))
            }
        }
        // ties
        a.move(to: p(0.17, 0.48)); a.addQuadCurve(to: p(0.09, 0.66), control: p(0.10, 0.54)); a.addLine(to: p(0.12, 0.67))
        a.addQuadCurve(to: p(0.19, 0.50), control: p(0.14, 0.56))
        a.move(to: p(0.19, 0.50)); a.addQuadCurve(to: p(0.17, 0.72), control: p(0.15, 0.62)); a.addLine(to: p(0.20, 0.72))
        a.addQuadCurve(to: p(0.21, 0.51), control: p(0.19, 0.62))
        return a
    }
}

/// A pearl diadem (late emperors wore a jewelled band instead of the laurel).
private struct TabDiadem: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        var a = Path()
        let c = p(0.46, 0.53), rad = r.width * 0.29, b = r.width * 0.032
        for i in 0..<9 {
            let ang = (192 + Double(i) * 12.5) * .pi / 180
            let q = CGPoint(x: c.x + CGFloat(cos(ang)) * rad, y: c.y + CGFloat(sin(ang)) * rad * 1.02)
            a.addEllipse(in: CGRect(x: q.x - b, y: q.y - b, width: 2 * b, height: 2 * b))
        }
        a.addEllipse(in: CGRect(x: p(0.15, 0.49).x - b * 1.3, y: p(0.15, 0.49).y - b * 1.3, width: 2.6 * b, height: 2.6 * b))
        a.move(to: p(0.15, 0.50)); a.addQuadCurve(to: p(0.10, 0.68), control: p(0.10, 0.56)); a.addLine(to: p(0.13, 0.68))
        a.addQuadCurve(to: p(0.17, 0.51), control: p(0.14, 0.58))
        return a
    }
}

/// A short curly beard along the jaw (Hadrian, Janus).
private struct TabBeard: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        var a = Path()
        a.move(to: p(0.44, 0.53))
        a.addQuadCurve(to: p(0.56, 0.79), control: p(0.45, 0.72))
        a.addQuadCurve(to: p(0.74, 0.76), control: p(0.68, 0.84))
        a.addQuadCurve(to: p(0.755, 0.65), control: p(0.77, 0.70))
        a.addLine(to: p(0.69, 0.64))
        a.addQuadCurve(to: p(0.70, 0.575), control: p(0.66, 0.61))
        a.addLine(to: p(0.745, 0.565))
        a.addQuadCurve(to: p(0.60, 0.60), control: p(0.66, 0.54))
        a.addQuadCurve(to: p(0.44, 0.53), control: p(0.52, 0.62))
        a.closeSubpath()
        return a
    }
}

/// The she-wolf, standing right with her head turned back, the twins beneath her (didrachm, 269 BC).
private struct TabWolf: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        var a = Path()
        // body
        a.move(to: p(0.26, 0.40))
        a.addQuadCurve(to: p(0.70, 0.38), control: p(0.48, 0.32))
        a.addQuadCurve(to: p(0.72, 0.55), control: p(0.78, 0.46))
        a.addQuadCurve(to: p(0.27, 0.56), control: p(0.50, 0.60))
        a.addQuadCurve(to: p(0.26, 0.40), control: p(0.21, 0.48))
        // head bent back over the shoulder, muzzle down toward the twins
        a.move(to: p(0.70, 0.52))
        for (x, y) in [(0.655, 0.465), (0.59, 0.45), (0.53, 0.44), (0.525, 0.415), (0.62, 0.34), (0.655, 0.30),
                       (0.665, 0.195), (0.70, 0.27), (0.735, 0.20), (0.745, 0.29), (0.765, 0.35), (0.775, 0.45)] {
            a.addLine(to: p(CGFloat(x), CGFloat(y)))
        }
        a.closeSubpath()
        // legs
        for (x, lean) in [(0.30, -0.02), (0.36, 0.015), (0.63, -0.01), (0.69, 0.02)] {
            let x = CGFloat(x), l = CGFloat(lean)
            a.move(to: p(x - 0.032, 0.50)); a.addLine(to: p(x + 0.032, 0.50))
            a.addLine(to: p(x + 0.017 + l, 0.72)); a.addLine(to: p(x + 0.04 + l, 0.745))
            a.addLine(to: p(x - 0.022 + l, 0.745)); a.addLine(to: p(x - 0.017 + l, 0.70))
            a.closeSubpath()
        }
        // tail
        a.move(to: p(0.25, 0.41))
        a.addQuadCurve(to: p(0.12, 0.67), control: p(0.10, 0.47))
        a.addLine(to: p(0.19, 0.67))
        a.addQuadCurve(to: p(0.28, 0.48), control: p(0.20, 0.53))
        a.closeSubpath()
        return a
    }
}

/// The wolf's eye, ear and fur, chased into the relief.
private struct TabWolfLines: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        var a = Path()
        let e = r.width * 0.012
        a.addEllipse(in: CGRect(x: p(0.645, 0.35).x - e, y: p(0.645, 0.35).y - e, width: 2 * e, height: 2 * e))
        a.move(to: p(0.555, 0.44)); a.addLine(to: p(0.61, 0.425))
        // the shaggy ruff on her neck and the fur along her flank
        for i in 0..<4 { let y = 0.33 + CGFloat(i) * 0.04; a.move(to: p(0.70, y)); a.addLine(to: p(0.74, y + 0.03)) }
        for i in 0..<4 { let x = 0.36 + CGFloat(i) * 0.06; a.move(to: p(x, 0.43)); a.addQuadCurve(to: p(x + 0.03, 0.52), control: p(x + 0.03, 0.46)) }
        return a
    }
}

/// Romulus and Remus, kneeling under the wolf and looking up.
private struct TabTwins: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        var a = Path()
        for x in [0.43, 0.54] {
            let x = CGFloat(x), hr = r.width * 0.032
            a.addEllipse(in: CGRect(x: p(x, 0.60).x - hr, y: p(x, 0.60).y - hr, width: 2 * hr, height: 2 * hr))
            a.addEllipse(in: CGRect(x: p(x - 0.045, 0.62).x, y: p(x, 0.62).y, width: r.width * 0.075, height: r.height * 0.11))
            a.move(to: p(x - 0.01, 0.64)); a.addLine(to: p(x + 0.02, 0.585)); a.addLine(to: p(x + 0.035, 0.59)); a.addLine(to: p(x + 0.01, 0.65))
        }
        return a
    }
}

/// Raised relief on a coin: a cast shadow, a lit face and a dark edge.
private struct TabRelief<S: Shape>: View {
    let shape: S
    let metal: TabMetal
    let d: CGFloat
    var body: some View {
        ZStack {
            shape.fill(metal.dark.opacity(0.7)).offset(x: d * 0.012, y: d * 0.018)
            shape.fill(LinearGradient(colors: [metal.light, metal.mid], startPoint: .topLeading, endPoint: .bottomTrailing))
            shape.stroke(metal.dark.opacity(0.8), lineWidth: max(0.5, d * 0.009))
        }
    }
}

private struct TabPortrait: View {
    let beard: Bool, diadem: Bool, plump: CGFloat
    let metal: TabMetal
    let d: CGFloat
    var body: some View {
        ZStack {
            TabRelief(shape: TabHead(plump: plump), metal: metal, d: d)
            if beard { TabBeard().fill(metal.mid.opacity(0.9)).overlay(TabBeard().stroke(metal.dark.opacity(0.6), lineWidth: max(0.5, d * 0.008))) }
            TabHeadLines().stroke(metal.dark.opacity(0.75), style: StrokeStyle(lineWidth: max(0.5, d * 0.01), lineCap: .round))
            if diadem {
                TabRelief(shape: TabDiadem(), metal: metal, d: d)
            } else {
                TabRelief(shape: TabLaurel(), metal: metal, d: d)
            }
        }
    }
}

/// One Roman coin, face up, filling its frame.
private struct TabCoin: View, Equatable {
    let spec: TabCoinSpec
    static func == (a: TabCoin, b: TabCoin) -> Bool { a.spec.id == b.spec.id }

    var body: some View {
        GeometryReader { g in
            let d = min(g.size.width, g.size.height)
            let m = spec.metal
            ZStack {
                // the coin's thickness, then the face
                TabFlan(seed: spec.seed).fill(m.dark).offset(y: d * 0.022)
                TabFlan(seed: spec.seed)
                    .fill(RadialGradient(colors: [m.light, m.mid, m.dark], center: UnitPoint(x: 0.36, y: 0.30), startRadius: 0, endRadius: d * 0.78))
                // the struck field sits a little lower than the rim
                Circle().fill(RadialGradient(colors: [m.dark.opacity(0.16), m.dark.opacity(0.32)], center: UnitPoint(x: 0.4, y: 0.35), startRadius: 0, endRadius: d * 0.45))
                    .frame(width: d * 0.86, height: d * 0.86)
                TabBeads().fill(m.dark.opacity(0.55)).frame(width: d * 0.86, height: d * 0.86)
                device(d: d)
                legend(d: d)
                if !spec.top.isEmpty {
                    Text(spec.top).font(luCinzel(d * 0.15, bold: true)).foregroundStyle(m.dark.opacity(0.85))
                        .offset(y: -d * 0.31)
                }
                if !spec.exergue.isEmpty {
                    Rectangle().fill(m.dark.opacity(0.6)).frame(width: d * 0.56, height: max(0.6, d * 0.012)).offset(y: d * 0.215)
                    Text(spec.exergue).font(luCinzel(d * 0.105, bold: true)).foregroundStyle(m.dark.opacity(0.85))
                        .offset(y: d * 0.30)
                }
                // a soft shine on the upper left, and the worn rim
                Ellipse().fill(Color.white.opacity(0.30)).frame(width: d * 0.42, height: d * 0.22)
                    .rotationEffect(.degrees(-35)).offset(x: -d * 0.17, y: -d * 0.22).blur(radius: d * 0.03)
                TabFlan(seed: spec.seed).stroke(m.dark.opacity(0.7), lineWidth: max(0.6, d * 0.018))
            }
            .frame(width: d, height: d)
            .frame(width: g.size.width, height: g.size.height)
        }
    }

    @ViewBuilder private func device(d: CGFloat) -> some View {
        let m = spec.metal
        switch spec.device {
        case let .head(beard, diadem, plump):
            TabPortrait(beard: beard, diadem: diadem, plump: plump, metal: m, d: d)
                .frame(width: d * 0.66, height: d * 0.66).offset(x: -d * 0.02, y: d * 0.01)
        case .janus:
            let b = d * 0.54
            ZStack {
                TabPortrait(beard: true, diadem: false, plump: 0, metal: m, d: d).frame(width: b, height: b)
                    .scaleEffect(x: -1).offset(x: -b * 0.30)
                TabPortrait(beard: true, diadem: false, plump: 0, metal: m, d: d).frame(width: b, height: b)
                    .offset(x: b * 0.30)
            }
            .offset(y: d * 0.06)
        case .wolf:
            ZStack {
                TabRelief(shape: TabWolf(), metal: m, d: d)
                TabWolfLines().stroke(m.dark.opacity(0.8), style: StrokeStyle(lineWidth: max(0.5, d * 0.01), lineCap: .round))
                TabRelief(shape: TabTwins(), metal: m, d: d)
            }
            .frame(width: d * 0.74, height: d * 0.74).offset(y: -d * 0.07)
        }
    }

    /// The legend runs clockwise around the rim, starting at the lower left.
    @ViewBuilder private func legend(d: CGFloat) -> some View {
        let chars = Array(spec.legend)
        if !chars.isEmpty {
            let span = 290.0
            let step = min(span / Double(chars.count), 24)
            let start = -step * Double(chars.count - 1) / 2
            ZStack {
                ForEach(chars.indices, id: \.self) { i in
                    let a = (start + Double(i) * step) * .pi / 180
                    Text(String(chars[i])).font(luCinzel(d * 0.095, bold: true))
                        .foregroundStyle(spec.metal.dark.opacity(0.9))
                        .rotationEffect(.radians(a))
                        .offset(x: CGFloat(sin(a)) * d * 0.355, y: -CGFloat(cos(a)) * d * 0.355)
                }
            }
        }
    }
}

// MARK: The room

/// The cabinet's geometry on the canvas (fractions), shared by the drawing and the coin spots.
private enum TabCab {
    static let left: CGFloat = 0.17, right: CGFloat = 0.83
    static let top: CGFloat = 0.39, bottom: CGFloat = 0.955
    static let trayTop: CGFloat = 0.44, trayMid: CGFloat = 0.605, trayBottom: CGFloat = 0.775
    static let xs: [CGFloat] = [0.275, 0.425, 0.575, 0.725]
    static let rowY: [CGFloat] = [0.508, 0.675]
    static let labelDY: CGFloat = 0.068
    static func slot(_ i: Int) -> (x: CGFloat, y: CGFloat) { (xs[i % 4], rowY[i / 4]) }
    static func size(_ spec: TabCoinSpec) -> CGFloat { spec.big ? 0.122 : 0.106 }
}

private let tabWood = LinearGradient(colors: [Color(hex: 0x8a5428), Color(hex: 0x5e3416)], startPoint: .top, endPoint: .bottom)
private let tabWoodLight = Color(hex: 0xa86a36)
private let tabWoodDark = Color(hex: 0x3f220e)
private let tabVelvet = Color(hex: 0x1d2a4f)

struct TablinumRoom: View {
    let s: WingState
    var body: some View {
        WingRoom(floor: Color(hex: 0xd9c6a0), floorLine: 0.64) { w, h, t in
            ZStack(alignment: .topLeading) {
                TabFloor(w: w, h: h)
                TabCurtains(w: w, h: h)
                TabCabinet(w: w, h: h)
                ForEach(Array(tabCoins.enumerated()), id: \.element.id) { i, spec in
                    let slot = TabCab.slot(i), size = TabCab.size(spec)
                    let p = (x: slot.x, y: slot.y - (spec.big ? 0.01 : 0))      // big coins sit a little higher, clear of their plates
                    TabSlot(label: spec.label, w: w, d: w * size, drop: spec.big ? 0.01 * h : 0)
                        .position(x: p.x * w, y: p.y * h)
                    if s.has(spec.id) {
                        WingSpot(x: p.x, y: p.y + size * w / 2 / h, size: size, w: w, h: h, lift: s.lift(spec.id)) {
                            TabCoin(spec: spec).equatable()
                                .overlay(TabGlint(t: t, phase: Double(i) * 0.83, gold: spec.metal == .gold))
                                .shadow(color: .black.opacity(0.45), radius: 1.5, x: 0.5, y: 1.5)
                        }
                        .onTapGesture { s.onTap(spec.id) }
                    }
                }
                if s.has("tab_masks") {
                    WingSpot(x: 0.5, y: 0.355, size: 0.72, w: w, h: h, lift: s.lift("tab_masks")) {
                        TabMasks()
                    }
                    .onTapGesture { s.onTap("tab_masks") }
                }
            }
        }
    }
}

/// Every few seconds a glint of light runs across a coin.
private struct TabGlint: View {
    let t: Double, phase: Double, gold: Bool
    var body: some View {
        GeometryReader { g in
            let d = g.size.width
            let cyc = (t / 6.5 + phase).truncatingRemainder(dividingBy: 1)
            let u = CGFloat(min(1, cyc / 0.14))       // runs during the first 14% of each cycle
            Capsule().fill(LinearGradient(colors: [.clear, Color.white.opacity(gold ? 0.6 : 0.45), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(width: d * 0.3, height: d * 1.4)
                .rotationEffect(.degrees(28))
                .offset(x: -d * 0.9 + u * d * 1.8)
                .frame(width: d, height: d)
                .opacity(cyc < 0.14 ? 1 : 0)
                .mask(Circle())
        }
        .allowsHitTesting(false)
    }
}

/// An empty velvet slot (a faint ring to fill) with a little brass name plate below it.
private struct TabSlot: View {
    let label: String
    let w: CGFloat, d: CGFloat
    var drop: CGFloat = 0     // keeps every plate on one line when the coin above sits higher
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [Color.black.opacity(0.42), Color.black.opacity(0.18)], center: UnitPoint(x: 0.45, y: 0.4), startRadius: 0, endRadius: d * 0.55))
                .frame(width: d * 1.04, height: d * 1.04)
            Circle().stroke(Fr.gold.opacity(0.4), style: StrokeStyle(lineWidth: max(0.6, w * 0.0025), dash: [w * 0.008, w * 0.006]))
                .frame(width: d * 0.92, height: d * 0.92)
            Circle().trim(from: 0.05, to: 0.45).stroke(Color.white.opacity(0.12), lineWidth: max(0.6, w * 0.003))
                .frame(width: d * 1.04, height: d * 1.04)
            Text(label.uppercased()).font(luCinzel(w * 0.017, bold: true)).foregroundStyle(Color(hex: 0x4a3510))
                .lineLimit(1).minimumScaleFactor(0.5)
                .padding(.horizontal, w * 0.008).padding(.vertical, w * 0.002)
                .frame(maxWidth: w * 0.13)
                .background(RoundedRectangle(cornerRadius: 1).fill(LinearGradient(colors: [Color(hex: 0xf3d27a), Color(hex: 0xb98a2e)], startPoint: .top, endPoint: .bottom)))
                .offset(y: w * 0.074 + drop)
        }
        .allowsHitTesting(false)
    }
}

/// A floor of opus sectile: cream and red marble squares set on the diagonal, in perspective.
private struct TabFloor: View {
    let w: CGFloat, h: CGFloat
    var body: some View {
        let y0 = h * 0.64
        ZStack(alignment: .topLeading) {
            TabFloorTiles(odd: false).fill(Color(hex: 0xeadcbc))
            TabFloorTiles(odd: true).fill(Color(hex: 0xc0714f))
            TabFloorTiles(odd: true).stroke(Color(hex: 0x7c3a22).opacity(0.25), lineWidth: 0.6)
            LinearGradient(colors: [Color.black.opacity(0.28), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: h * 0.12)
        }
        .frame(width: w * 3, height: h * 1.2 - y0 + h * 0.6)
        .position(x: w * 0.5, y: y0 + (h * 1.2 - y0 + h * 0.6) / 2)
        .allowsHitTesting(false)
    }
}

/// Perspective checker cells; `odd` picks one colour of the checker.
private struct TabFloorTiles: Shape {
    let odd: Bool
    func path(in r: CGRect) -> Path {
        var p = Path()
        let vx = r.midX, vy = r.minY - r.height * 1.6      // vanishing point far above the floor
        let rows = 11, cols = 40
        func pt(_ u: CGFloat, _ v: CGFloat) -> CGPoint {
            // v: 0 at the wall, 1 at the bottom; rows grow nearer the viewer
            let y = r.minY + r.height * pow(v, 1.35)
            let s = (y - vy) / (r.maxY - vy)
            return CGPoint(x: vx + (r.minX + r.width * u - vx) * s, y: y)
        }
        for i in 0..<rows {
            for j in 0..<cols where (i + j) % 2 == (odd ? 1 : 0) {
                let v0 = CGFloat(i) / CGFloat(rows), v1 = CGFloat(i + 1) / CGFloat(rows)
                let u0 = CGFloat(j) / CGFloat(cols), u1 = CGFloat(j + 1) / CGFloat(cols)
                let um = (u0 + u1) / 2, vm = (v0 + v1) / 2
                // a diamond inside each cell, and the four corner triangles of the other colour
                if odd {
                    p.move(to: pt(um, v0)); p.addLine(to: pt(u1, vm)); p.addLine(to: pt(um, v1)); p.addLine(to: pt(u0, vm)); p.closeSubpath()
                } else {
                    p.move(to: pt(u0, v0)); p.addLine(to: pt(u1, v0)); p.addLine(to: pt(u1, v1)); p.addLine(to: pt(u0, v1)); p.closeSubpath()
                }
            }
        }
        return p
    }
}

/// Saffron curtains tied back at both sides: the tablinum opened onto the atrium.
private struct TabCurtains: View {
    let w: CGFloat, h: CGFloat
    var body: some View {
        ZStack(alignment: .topLeading) {
            // the rod across the top
            Capsule().fill(LinearGradient(colors: [Color(hex: 0xf3d27a), Color(hex: 0x9c7420)], startPoint: .top, endPoint: .bottom))
                .frame(width: w * 3, height: h * 0.016).position(x: w * 0.5, y: h * 0.045)
            ForEach([-1.0, 1.0], id: \.self) { side in
                TabDrape()
                    .fill(LinearGradient(colors: [Color(hex: 0xd99a3a), Color(hex: 0xb06e22), Color(hex: 0xe2a948), Color(hex: 0xa5631c), Color(hex: 0xd99a3a)],
                                         startPoint: .leading, endPoint: .trailing))
                    .overlay(TabDrapeFolds().stroke(Color(hex: 0x7a4512).opacity(0.35), lineWidth: 1))
                    .overlay(alignment: .bottom) {
                        // a red band along the hem
                        Rectangle().fill(Fr.frame).frame(height: h * 0.025).offset(y: -h * 0.0)
                            .mask(TabDrape())
                    }
                    .frame(width: w * 0.22, height: h * 0.62)
                    .scaleEffect(x: -side, y: 1)
                    .position(x: side < 0 ? w * 0.06 : w * 0.94, y: h * 0.045 + h * 0.31)
                // the gold tie-back cord and tassel
                Capsule().fill(Fr.gold).frame(width: w * 0.08, height: h * 0.012)
                    .rotationEffect(.degrees(side * 12))
                    .position(x: side < 0 ? w * 0.075 : w * 0.925, y: h * 0.40)
                TabTassel().frame(width: w * 0.02, height: h * 0.05)
                    .position(x: side < 0 ? w * 0.11 : w * 0.89, y: h * 0.43)
            }
        }
        .allowsHitTesting(false)
    }
}

/// A curtain hanging on the left, gathered in at the tie-back and flaring to the floor.
private struct TabDrape: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        var a = Path()
        a.move(to: p(-1.5, 0))
        a.addLine(to: p(1.0, 0))
        a.addQuadCurve(to: p(0.45, 0.58), control: p(0.85, 0.4))
        a.addQuadCurve(to: p(0.75, 1.0), control: p(0.5, 0.8))
        a.addLine(to: p(-1.5, 1.0))
        a.closeSubpath()
        return a
    }
}

private struct TabDrapeFolds: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        var a = Path()
        for f in [0.15, 0.35, 0.55, 0.75] {
            let f = CGFloat(f)
            a.move(to: p(f * 1.0, 0.0))
            a.addQuadCurve(to: p(f * 0.4, 0.58), control: p(f * 0.9, 0.4))
            a.addQuadCurve(to: p(f * 0.7, 1.0), control: p(f * 0.45, 0.8))
        }
        return a
    }
}

private struct TabTassel: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .top) {
                Circle().fill(Fr.gold).frame(width: w * 0.8)
                Trapezoid2().fill(LinearGradient(colors: [Fr.gold, Color(hex: 0x9c7420)], startPoint: .top, endPoint: .bottom))
                    .frame(width: w, height: h * 0.7).offset(y: h * 0.3)
            }
        }
    }
}

private struct Trapezoid2: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX - r.width * 0.2, y: r.minY)); p.addLine(to: CGPoint(x: r.midX + r.width * 0.2, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.closeSubpath()
        return p
    }
}

/// The walnut coin cabinet: cornice, open glazed doors, two velvet trays, drawers and lion feet.
private struct TabCabinet: View {
    let w: CGFloat, h: CGFloat
    var body: some View {
        let L = TabCab.left * w, R = TabCab.right * w, T = TabCab.top * h, B = TabCab.bottom * h
        let cw = R - L
        let line = max(0.8, w * 0.004)
        ZStack(alignment: .topLeading) {
            // shadow on the floor
            Ellipse().fill(Color.black.opacity(0.28)).frame(width: cw * 1.12, height: h * 0.04)
                .position(x: w * 0.5, y: B - h * 0.005)
            // open doors, swung out toward us
            ForEach([-1.0, 1.0], id: \.self) { side in
                TabDoor()
                    .frame(width: w * 0.075, height: (TabCab.trayBottom - TabCab.trayTop + 0.04) * h)
                    .scaleEffect(x: -side, y: 1)
                    .position(x: side < 0 ? L - w * 0.03 : R + w * 0.03, y: (TabCab.trayTop + TabCab.trayBottom) / 2 * h)
            }
            // carcass
            Rectangle().fill(tabWood)
                .overlay(Rectangle().stroke(tabWoodDark, lineWidth: line))
                .frame(width: cw, height: B - T - h * 0.03).position(x: w * 0.5, y: (T + B - h * 0.03) / 2)
            // pilasters with fluting
            ForEach([L + cw * 0.025, R - cw * 0.025], id: \.self) { x in
                Rectangle().fill(LinearGradient(colors: [tabWoodLight, Color(hex: 0x6e3f1c)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: cw * 0.045, height: (TabCab.trayBottom - TabCab.trayTop + 0.02) * h)
                    .overlay(HStack(spacing: cw * 0.008) { ForEach(0..<3, id: \.self) { _ in Rectangle().fill(tabWoodDark.opacity(0.35)).frame(width: max(0.6, cw * 0.004)) } })
                    .position(x: x, y: (TabCab.trayTop + TabCab.trayBottom) / 2 * h)
            }
            // velvet trays with a wooden shelf between and gilt beading round them
            ForEach(0..<2, id: \.self) { row in
                let y0 = (row == 0 ? TabCab.trayTop : TabCab.trayMid + 0.008) * h
                let y1 = (row == 0 ? TabCab.trayMid - 0.008 : TabCab.trayBottom) * h
                Rectangle()
                    .fill(LinearGradient(colors: [Color(hex: 0x111a36), tabVelvet, Color(hex: 0x24345e)], startPoint: .top, endPoint: .bottom))
                    .overlay(Rectangle().stroke(Fr.gold.opacity(0.85), lineWidth: line))
                    .frame(width: cw * 0.86, height: y1 - y0).position(x: w * 0.5, y: (y0 + y1) / 2)
                // the shade under the shelf above
                LinearGradient(colors: [Color.black.opacity(0.45), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(width: cw * 0.86, height: h * 0.025).position(x: w * 0.5, y: y0 + h * 0.0125)
            }
            // cornice: frieze with a plaque, dentils, and a moulded top
            Rectangle().fill(LinearGradient(colors: [tabWoodLight, Color(hex: 0x6e3f1c)], startPoint: .top, endPoint: .bottom))
                .overlay(Rectangle().stroke(tabWoodDark, lineWidth: line))
                .frame(width: cw * 1.1, height: h * 0.022).position(x: w * 0.5, y: T)
            HStack(spacing: cw * 0.012) {
                ForEach(0..<26, id: \.self) { _ in Rectangle().fill(tabWoodDark.opacity(0.55)).frame(width: cw * 0.022, height: h * 0.01) }
            }
            .position(x: w * 0.5, y: T + h * 0.016)
            Text("NVMMI").font(luCinzel(w * 0.026, bold: true)).tracking(w * 0.006).foregroundStyle(Color(hex: 0x4a3510))
                .padding(.horizontal, w * 0.02).padding(.vertical, w * 0.002)
                .background(RoundedRectangle(cornerRadius: 1.5).fill(LinearGradient(colors: [Color(hex: 0xf6dc8c), Color(hex: 0xb98a2e)], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 1.5).stroke(Color(hex: 0x7a5a18), lineWidth: 0.6)))
                .position(x: w * 0.5, y: T + h * 0.034)
            // drawers with bronze ring pulls
            ForEach(0..<2, id: \.self) { row in
                let y = (TabCab.trayBottom + 0.035 + CGFloat(row) * 0.06) * h
                ForEach([0.36, 0.64], id: \.self) { fx in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(LinearGradient(colors: [Color(hex: 0x95602f), Color(hex: 0x6a3b19)], startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: 1.5).stroke(tabWoodDark, lineWidth: line * 0.8))
                        .overlay(RoundedRectangle(cornerRadius: 1).stroke(tabWoodLight.opacity(0.6), lineWidth: 0.6).padding(w * 0.006))
                        .frame(width: cw * 0.42, height: h * 0.05)
                        .position(x: L + cw * CGFloat(fx), y: y)
                    Circle().stroke(Fr.gold, lineWidth: max(0.8, w * 0.004)).frame(width: w * 0.018, height: w * 0.018)
                        .position(x: L + cw * CGFloat(fx), y: y + h * 0.006)
                    Circle().fill(Color(hex: 0x9c7420)).frame(width: w * 0.008).position(x: L + cw * CGFloat(fx), y: y - h * 0.004)
                }
            }
            // plinth and lion feet
            Rectangle().fill(tabWoodDark).frame(width: cw * 1.04, height: h * 0.014)
                .position(x: w * 0.5, y: B - h * 0.035)
            ForEach([L + cw * 0.06, R - cw * 0.06], id: \.self) { x in
                TabPaw().fill(LinearGradient(colors: [Color(hex: 0x7a4a22), tabWoodDark], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.06, height: h * 0.034).position(x: x, y: B - h * 0.012)
            }
        }
        .allowsHitTesting(false)
    }
}

/// An open glazed door, seen edge-on as it swings toward the viewer (drawn for the left side).
private struct TabDoor: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                TabSkew().fill(tabWood)
                TabSkew().fill(LinearGradient(colors: [Color.white.opacity(0.28), Color(hex: 0x9cc3cf).opacity(0.18), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .padding(.horizontal, w * 0.18).padding(.vertical, h * 0.05)
                TabSkew().stroke(tabWoodDark, lineWidth: 1)
                Circle().fill(Fr.gold).frame(width: w * 0.12).offset(x: -w * 0.3)
            }
        }
    }
}

private struct TabSkew: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY - r.height * 0.04)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY + r.height * 0.04)); p.closeSubpath()
        return p
    }
}

private struct TabPaw: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.25, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.25, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.maxX - r.width * 0.1, y: r.midY))
        for i in 0..<3 {
            let x0 = r.maxX - r.width * CGFloat(i) / 3, x1 = r.maxX - r.width * CGFloat(i + 1) / 3
            p.addQuadCurve(to: CGPoint(x: x1, y: r.maxY), control: CGPoint(x: (x0 + x1) / 2, y: r.maxY - r.height * 0.35))
        }
        p.addQuadCurve(to: CGPoint(x: r.minX + r.width * 0.25, y: r.minY), control: CGPoint(x: r.minX + r.width * 0.1, y: r.midY))
        p.closeSubpath()
        return p
    }
}

// MARK: Ancestor masks

private struct TabMaskSpec { let title: String; let hair: Color; let beard: Bool; let bald: Bool; let curls: Bool }
private let tabMaskSpecs: [TabMaskSpec] = [
    .init(title: "ABAVVS", hair: Color(hex: 0xe8e2d4), beard: true, bald: true, curls: false),     // great-great-grandfather
    .init(title: "PROAVVS", hair: Color(hex: 0x9a8f80), beard: false, bald: true, curls: false),   // great-grandfather
    .init(title: "AVVS", hair: Color(hex: 0x6e5236), beard: false, bald: false, curls: true),      // grandfather
    .init(title: "PATER", hair: Color(hex: 0x3e2a18), beard: false, bald: false, curls: false),    // father
]

/// Four wax masks in their wooden shrines, joined by the painted family tree, oldest on the left.
private struct TabMasks: View {
    var body: some View {
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            let sw = W * 0.19, sh = W * 0.27
            let base = H - W * 0.02
            ZStack(alignment: .topLeading) {
                // the stemma: the family tree painted on the wall, a red line of descent from shrine to shrine
                ForEach(0..<3, id: \.self) { i in
                    let x0 = W * (0.14 + CGFloat(i) * 0.24), x1 = W * (0.14 + CGFloat(i + 1) * 0.24)
                    let y = base - W * 0.011 - sh - W * 0.004
                    Path { p in
                        p.move(to: CGPoint(x: x0, y: y)); p.addQuadCurve(to: CGPoint(x: x1, y: y), control: CGPoint(x: (x0 + x1) / 2, y: y - sh * 0.42))
                    }
                    .stroke(Color(hex: 0x5c120c).opacity(0.9), style: StrokeStyle(lineWidth: max(1, W * 0.007), lineCap: .round))
                    // a little laurel leaf at the top of each arc
                    ForEach([-1.0, 1.0], id: \.self) { s in
                        Ellipse().fill(Fr.leaf).frame(width: W * 0.026, height: W * 0.011)
                            .rotationEffect(.degrees(s * 30))
                            .position(x: (x0 + x1) / 2 + CGFloat(s) * W * 0.012, y: y - sh * 0.21 - W * 0.004)
                    }
                    Circle().fill(Color(hex: 0xb8322a)).frame(width: W * 0.012).position(x: (x0 + x1) / 2, y: y - sh * 0.21)
                }
                // the wall shelf
                Rectangle().fill(tabWood).overlay(Rectangle().stroke(tabWoodDark, lineWidth: 1))
                    .frame(width: W * 0.86, height: W * 0.022).position(x: W * 0.5, y: base)
                ForEach([0.12, 0.88], id: \.self) { fx in
                    TabBracket().fill(Color(hex: 0x5e3416)).frame(width: W * 0.03, height: W * 0.045)
                        .scaleEffect(x: fx < 0.5 ? 1 : -1).position(x: W * CGFloat(fx), y: base + W * 0.032)
                }
                ForEach(tabMaskSpecs.indices, id: \.self) { i in
                    TabShrine(spec: tabMaskSpecs[i])
                        .frame(width: sw, height: sh)
                        .position(x: W * (0.14 + CGFloat(i) * 0.24), y: base - W * 0.011 - sh / 2)
                }
            }
        }
    }
}

private struct TabBracket: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY), control: CGPoint(x: r.maxX * 0.9, y: r.maxY * 0.7))
        p.closeSubpath()
        return p
    }
}

/// A little gabled cupboard holding one wax mask, its doors open and a name plate under it.
private struct TabShrine: View {
    let spec: TabMaskSpec
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .top) {
                // gable
                TabGable().fill(LinearGradient(colors: [tabWoodLight, Color(hex: 0x6e3f1c)], startPoint: .top, endPoint: .bottom))
                    .overlay(TabGable().stroke(tabWoodDark, lineWidth: 1))
                    .frame(width: w * 1.04, height: h * 0.2)
                Circle().fill(Fr.gold).frame(width: w * 0.08).offset(y: h * 0.09)
                // box with a dark interior
                Rectangle().fill(tabWood).overlay(Rectangle().stroke(tabWoodDark, lineWidth: 1))
                    .frame(width: w * 0.9, height: h * 0.62).offset(y: h * 0.2)
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0x2a160a), Color(hex: 0x4a2a14)], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.72, height: h * 0.52).offset(y: h * 0.25)
                // open doors
                ForEach([-1.0, 1.0], id: \.self) { s in
                    TabSkew().fill(Color(hex: 0x7a4a22)).overlay(TabSkew().stroke(tabWoodDark, lineWidth: 0.8))
                        .frame(width: w * 0.14, height: h * 0.56)
                        .scaleEffect(x: s, y: 1)
                        .offset(x: s * w * 0.52, y: h * 0.23)
                }
                TabMaskFace(spec: spec).frame(width: w * 0.56, height: h * 0.48).offset(y: h * 0.27)
                // titulus
                Text(spec.title).font(luCinzel(w * 0.13, bold: true)).foregroundStyle(Fr.ink)
                    .lineLimit(1).minimumScaleFactor(0.4)
                    .frame(width: w * 0.86, height: h * 0.11)
                    .background(Rectangle().fill(Fr.parchment).overlay(Rectangle().stroke(Fr.trunk, lineWidth: 0.6)))
                    .offset(y: h * 0.85)
            }
            .frame(width: w, height: h, alignment: .top)
        }
    }
}

private struct TabGable: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY)); p.addLine(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.closeSubpath()
        return p
    }
}

/// A wax portrait mask, front view: warm wax skin, closed calm features, painted hair.
private struct TabMaskFace: View {
    let spec: TabMaskSpec
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let wax = LinearGradient(colors: [Color(hex: 0xf6e7c8), Color(hex: 0xd8bf92)], startPoint: .topLeading, endPoint: .bottomTrailing)
            let line = Color(hex: 0x7a5a36)
            ZStack {
                // ears
                ForEach([-1.0, 1.0], id: \.self) { s in
                    Ellipse().fill(Color(hex: 0xe2cba0)).frame(width: w * 0.16, height: h * 0.24).offset(x: s * w * 0.38, y: h * 0.0)
                }
                Ellipse().fill(wax).frame(width: w * 0.78, height: h * 0.94)
                // hair cap
                if spec.bald {
                    Ellipse().trim(from: 0.55, to: 0.95).stroke(spec.hair, lineWidth: h * 0.06)
                        .frame(width: w * 0.78, height: h * 0.9).rotationEffect(.degrees(-0))
                        .opacity(0.9)
                } else {
                    Ellipse().trim(from: 0.5, to: 1.0).fill(spec.hair).frame(width: w * 0.82, height: h * 0.6).offset(y: -h * 0.18)
                    if spec.curls {
                        HStack(spacing: 0) { ForEach(0..<5, id: \.self) { _ in Circle().fill(spec.hair).frame(width: w * 0.15) } }
                            .offset(y: -h * 0.2)
                    }
                }
                // brows, closed eyes, nose, mouth
                Path { p in
                    for s in [-1.0, 1.0] {
                        let s = CGFloat(s)
                        p.move(to: CGPoint(x: w * (0.5 + s * 0.08), y: h * 0.36))
                        p.addQuadCurve(to: CGPoint(x: w * (0.5 + s * 0.27), y: h * 0.37), control: CGPoint(x: w * (0.5 + s * 0.18), y: h * 0.31))
                        p.move(to: CGPoint(x: w * (0.5 + s * 0.1), y: h * 0.44))
                        p.addQuadCurve(to: CGPoint(x: w * (0.5 + s * 0.25), y: h * 0.44), control: CGPoint(x: w * (0.5 + s * 0.175), y: h * 0.48))
                    }
                    p.move(to: CGPoint(x: w * 0.49, y: h * 0.42)); p.addLine(to: CGPoint(x: w * 0.46, y: h * 0.6))
                    p.addQuadCurve(to: CGPoint(x: w * 0.56, y: h * 0.6), control: CGPoint(x: w * 0.5, y: h * 0.64))
                    p.move(to: CGPoint(x: w * 0.40, y: h * 0.725)); p.addQuadCurve(to: CGPoint(x: w * 0.60, y: h * 0.725), control: CGPoint(x: w * 0.5, y: h * 0.735))
                    // age lines
                    if spec.bald {
                        p.move(to: CGPoint(x: w * 0.36, y: h * 0.25)); p.addQuadCurve(to: CGPoint(x: w * 0.64, y: h * 0.25), control: CGPoint(x: w * 0.5, y: h * 0.22))
                        p.move(to: CGPoint(x: w * 0.31, y: h * 0.58)); p.addQuadCurve(to: CGPoint(x: w * 0.36, y: h * 0.76), control: CGPoint(x: w * 0.3, y: h * 0.68))
                        p.move(to: CGPoint(x: w * 0.69, y: h * 0.58)); p.addQuadCurve(to: CGPoint(x: w * 0.64, y: h * 0.76), control: CGPoint(x: w * 0.7, y: h * 0.68))
                    }
                }
                .stroke(line, style: StrokeStyle(lineWidth: max(0.6, w * 0.035), lineCap: .round))
                if spec.beard {
                    Ellipse().trim(from: 0.0, to: 0.5).fill(spec.hair).frame(width: w * 0.74, height: h * 0.5).offset(y: h * 0.2)
                        .mask(Ellipse().frame(width: w * 0.78, height: h * 0.94))
                    Path { p in p.move(to: CGPoint(x: w * 0.4, y: h * 0.72)); p.addQuadCurve(to: CGPoint(x: w * 0.6, y: h * 0.72), control: CGPoint(x: w * 0.5, y: h * 0.75)) }
                        .stroke(line, lineWidth: max(0.6, w * 0.035))
                }
            }
            .frame(width: w, height: h)
        }
    }
}

// MARK: Card thumbnails

struct TablinumThumb: View {
    let id: String
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            Group {
                if let spec = tabCoins.first(where: { $0.id == id }) {
                    let d = min(w, h) * (spec.big ? 0.86 : 0.78)
                    TabCoin(spec: spec).frame(width: d, height: d)
                        .shadow(color: .black.opacity(0.35), radius: 2, x: 1, y: 2)
                } else if id == "tab_masks" {
                    // two of the shrines, joined by the family-tree line
                    let sh = min(h * 0.76, w * 0.42 / 0.7), sw = sh * 0.7
                    ZStack {
                        Path { p in
                            p.move(to: CGPoint(x: w / 2 - sw * 0.55, y: h / 2 - sh * 0.5))
                            p.addQuadCurve(to: CGPoint(x: w / 2 + sw * 0.55, y: h / 2 - sh * 0.5), control: CGPoint(x: w / 2, y: h / 2 - sh * 0.75))
                        }
                        .stroke(Color(hex: 0x5c120c), lineWidth: 1.2)
                        HStack(spacing: sw * 0.1) {
                            TabShrine(spec: tabMaskSpecs[0]).frame(width: sw, height: sh)
                            TabShrine(spec: tabMaskSpecs[3]).frame(width: sw, height: sh)
                        }
                    }
                } else {
                    Color.clear
                }
            }
            .frame(width: w, height: h)
        }
    }
}
