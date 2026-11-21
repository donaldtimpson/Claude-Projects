import SwiftUI

// MARK: - Exercise Yard art
//
// An open courtyard: a shady colonnade (portico) along the back under a tiled roof, a herm of Hermes —
// the god of athletes — at the steps, and raked sand. Items are drawn in unit coordinates of their own
// boxes (see HPPath / HPBox in WingHarborArt.swift).

enum Pl {
    static let sand = Color(hex: 0xe3c58f)
    static let sandDeep = Color(hex: 0xcfac70)
    static let sandFine = Color(hex: 0xf1ddb0)
    static let portico = Color(hex: 0x7a2c20)
    static let porticoDeep = Color(hex: 0x4e1c14)
    static let wood = Color(hex: 0x9a6a3e)
    static let woodDeep = Color(hex: 0x65411f)
    static let bronze = Color(hex: 0xc99a52)
    static let bronzeDeep = Color(hex: 0x86592a)
    static let stone = Color(hex: 0x9b958a)
    static let stoneDeep = Color(hex: 0x6f6a61)
    static let bone = Color(hex: 0xf3ead2)
    static let boneShade = Color(hex: 0xc9b98f)
    static let ink = Color(hex: 0x2b2420)
}

// MARK: The backdrop

struct PalaestraBackdrop: View {
    let w: CGFloat, h: CGFloat, t: Double
    static let floorLine: CGFloat = 0.54
    private let roofTop: CGFloat = 0.1, eave: CGFloat = 0.17, beam: CGFloat = 0.235, step: CGFloat = 0.5

    var body: some View {
        let wide = w * 3, cx = w / 2
        ZStack(alignment: .topLeading) {
            // sky: clouds, and cypresses showing over the roof
            ForEach(0..<2, id: \.self) { i in
                let drift = CGFloat((t * 0.006 + Double(i) * 0.55).truncatingRemainder(dividingBy: 1.4)) - 0.2
                HPCloud().fill(.white.opacity(0.78))
                    .frame(width: w * (0.22 - CGFloat(i) * 0.04), height: w * 0.07)
                    .position(x: drift * w * 1.2, y: h * (0.035 + CGFloat(i) * 0.03))
            }
            ForEach([0.07, 0.17, 0.83, 0.94], id: \.self) { x in
                Ellipse().fill(LinearGradient(colors: [Fr.leaf, Fr.leafDark], startPoint: .leading, endPoint: .trailing))
                    .frame(width: w * 0.07, height: h * (x == 0.17 || x == 0.83 ? 0.16 : 0.2))
                    .position(x: w * x, y: h * (roofTop + 0.01))
            }
            // the back wall of the portico, in shade, with painted panels
            Rectangle().fill(LinearGradient(colors: [Pl.porticoDeep, Pl.portico], startPoint: .top, endPoint: .bottom))
                .frame(width: wide, height: h * (step - beam)).position(x: cx, y: h * (beam + step) / 2)
            ForEach(-8..<16, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1).stroke(Fr.ochre.opacity(0.55), lineWidth: max(0.8, w * 0.003))
                    .frame(width: w * 0.06, height: h * 0.13)
                    .position(x: w * (0.0625 + CGFloat(i) * 0.125), y: h * 0.36)
            }
            // wreaths painted in the panels either side of the middle
            ForEach([0.3125, 0.6875], id: \.self) { x in
                Circle().stroke(Fr.leaf.opacity(0.9), style: StrokeStyle(lineWidth: w * 0.008, dash: [w * 0.008, w * 0.004]))
                    .frame(width: w * 0.035).position(x: w * x, y: h * 0.355)
            }
            // dado band along the foot of the wall
            Rectangle().fill(Color.black.opacity(0.2)).frame(width: wide, height: h * 0.05).position(x: cx, y: h * (step - 0.025))
            // columns
            ForEach(-8..<17, id: \.self) { i in
                PlColumn().frame(width: w * 0.05, height: h * (step - beam + 0.005))
                    .position(x: w * CGFloat(i) * 0.125, y: h * (beam + step) / 2)
            }
            // entablature with the yard's name carved in it
            Rectangle().fill(LinearGradient(colors: [Fr.stucco, Fr.stuccoShade], startPoint: .top, endPoint: .bottom))
                .frame(width: wide, height: h * (beam - eave)).position(x: cx, y: h * (eave + beam) / 2)
            Rectangle().fill(Fr.stuccoShade).frame(width: wide, height: max(1, h * 0.006)).position(x: cx, y: h * (eave + 0.022))
            Rectangle().fill(Color.black.opacity(0.18)).frame(width: wide, height: max(1, h * 0.004)).position(x: cx, y: h * beam)
            Text("PALAESTRA").font(luCinzel(w * 0.042, bold: true)).tracking(w * 0.012)
                .foregroundStyle(Fr.trunk.opacity(0.8)).position(x: w * 0.5, y: h * (eave + beam + 0.02) / 2 + h * 0.008)
            // tiled roof with antefixes along the eave
            PlRoof(w: w).frame(width: wide, height: h * (eave - roofTop)).position(x: cx, y: h * (roofTop + eave) / 2)
            // the steps (stylobate)
            Rectangle().fill(Fr.stucco).frame(width: wide, height: h * 0.018).position(x: cx, y: h * (step + 0.009))
            Rectangle().fill(Fr.stuccoShade).frame(width: wide, height: h * 0.022).position(x: cx, y: h * (step + 0.029))
            // the sand: the portico's shadow, raking marks and a few pebbles
            Rectangle().fill(LinearGradient(colors: [Color.black.opacity(0.12), .clear], startPoint: .top, endPoint: .bottom))
                .frame(width: wide, height: h * 0.04).position(x: cx, y: h * (Self.floorLine + 0.02))
            PlRakeMarks(w: w, h: h).stroke(Pl.sandDeep.opacity(0.6), style: StrokeStyle(lineWidth: max(0.6, w * 0.0025), lineCap: .round))
                .frame(width: w, height: h)
            ForEach(0..<12, id: \.self) { i in
                let u = CGFloat((i * 37) % 100) / 100, v = 0.6 + CGFloat((i * 53) % 40) / 100
                Ellipse().fill(Pl.stone.opacity(0.5)).frame(width: w * 0.012, height: w * 0.007).position(x: w * u, y: h * v)
            }
            // a herm of Hermes, guardian of the palaestra, at the foot of the steps
            PlHerm().frame(width: w * 0.08, height: w * 0.2).position(x: w * 0.5, y: h * 0.54 - w * 0.1)
        }
    }
}

private struct PlColumn: View {
    var body: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                Rectangle().fill(LinearGradient(colors: [Fr.marble, Fr.marbleShade], startPoint: .leading, endPoint: .trailing))
                    .hp(W, H, x: 0.5, y: 0.5, w: 0.62, h: 0.92)
                HPPath { p, P in for x in [0.35, 0.5, 0.65] as [CGFloat] { p.move(to: P(x, 0.06)); p.addLine(to: P(x, 0.94)) } }
                    .stroke(Fr.marbleShade.opacity(0.8), lineWidth: max(0.5, W * 0.03))
                Rectangle().fill(Fr.marble).hp(W, H, x: 0.5, y: 0.03, w: 1, h: 0.06)
                Rectangle().fill(Fr.marbleShade).hp(W, H, x: 0.5, y: 0.07, w: 0.8, h: 0.025)
                Rectangle().fill(Fr.marble).hp(W, H, x: 0.5, y: 0.965, w: 0.9, h: 0.07)
            }
        }
    }
}

private struct PlRoof: View {
    let w: CGFloat
    var body: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                Rectangle().fill(LinearGradient(colors: [Fr.tileDeep, Fr.tile], startPoint: .top, endPoint: .bottom))
                HPPath { p, P in
                    let n = Int(W / max(1, w * 0.03))
                    for i in 0...n { let x = CGFloat(i) / CGFloat(max(1, n)); p.move(to: P(x, 0)); p.addLine(to: P(x, 1)) }
                }
                .stroke(Fr.tileDeep.opacity(0.7), lineWidth: max(0.8, w * 0.006))
                // antefixes: little palmette-topped tiles along the eave
                HPPath { p, P in
                    let n = Int(W / max(1, w * 0.06))
                    for i in 0...n {
                        let x = CGFloat(i) / CGFloat(max(1, n))
                        p.addEllipse(in: CGRect(origin: P(x - 0.004, 0.72), size: CGSize(width: w * 0.024, height: H * 0.34)))
                    }
                }
                .fill(Fr.tileDeep)
            }
        }
    }
}

/// Raking marks across the sand: shallow arcs, wider apart toward us.
private struct PlRakeMarks: Shape {
    let w: CGFloat, h: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path()
        for (i, v) in [0.58, 0.63, 0.7, 0.79, 0.9].enumerated() {
            let y = h * CGFloat(v)
            for j in 0..<4 {
                let x0 = w * (CGFloat(j) * 0.27 - 0.06 + (i % 2 == 0 ? 0 : 0.12))
                p.move(to: CGPoint(x: x0, y: y))
                p.addQuadCurve(to: CGPoint(x: x0 + w * 0.16, y: y), control: CGPoint(x: x0 + w * 0.08, y: y - h * 0.008 * CGFloat(i + 1)))
            }
        }
        return p
    }
}

/// A herm: a square marble pillar topped with the bearded head of Hermes.
private struct PlHerm: View {
    var body: some View {
        HPBox { W, H in
            let stone = LinearGradient(colors: [Fr.marble, Fr.marbleShade], startPoint: .leading, endPoint: .trailing)
            ZStack(alignment: .topLeading) {
                Rectangle().fill(Fr.marbleShade).hp(W, H, x: 0.5, y: 0.96, w: 0.9, h: 0.08)
                HPPoly(pts: [(0.3, 0.3), (0.7, 0.3), (0.74, 0.92), (0.26, 0.92)]).fill(stone)
                Rectangle().fill(Fr.marbleShade).hp(W, H, x: 0.5, y: 0.32, w: 0.7, h: 0.04)   // shoulders
                // the bearded head: hair, face, eyes and a long pointed beard
                Ellipse().fill(Fr.marbleShade).hp(W, H, x: 0.5, y: 0.12, w: 0.62, h: 0.15)
                Ellipse().fill(stone).hp(W, H, x: 0.5, y: 0.155, w: 0.46, h: 0.16)
                HPPoly(pts: [(0.27, 0.16), (0.73, 0.16), (0.68, 0.25), (0.5, 0.34), (0.32, 0.25)]).fill(Fr.marbleShade)
                HPPath { p, P in for x in [0.42, 0.5, 0.58] as [CGFloat] { p.move(to: P(x, 0.2)); p.addLine(to: P(x + (0.5 - x) * 0.4, 0.3)) } }
                    .stroke(Color(hex: 0xa99f88), lineWidth: max(0.5, W * 0.025))
                Circle().fill(Fr.ink.opacity(0.7)).hp(W, H, x: 0.41, y: 0.15, w: 0.07, h: 0.025)
                Circle().fill(Fr.ink.opacity(0.7)).hp(W, H, x: 0.59, y: 0.15, w: 0.07, h: 0.025)
                Capsule().fill(Fr.marble).hp(W, H, x: 0.5, y: 0.205, w: 0.2, h: 0.02)
                // a victor's ribbon tied on the pillar
                Capsule().fill(Fr.frame).hp(W, H, x: 0.5, y: 0.45, w: 0.48, h: 0.03)
                HPPoly(pts: [(0.5, 0.45), (0.62, 0.6), (0.56, 0.61)]).fill(Fr.frame)
            }
        }
    }
}

// MARK: Items

/// The labyrinth mosaic: a square maze in black and white tesserae inside a red border, laid flat in the sand.
struct PlMaze: View {
    var tilt: Double = 64           // how far it is tipped back to lie on the ground (degrees)
    var body: some View {
        HPBox { W, H in
            PlMazeFace().frame(width: W, height: W)
                .rotation3DEffect(.degrees(tilt), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.45)
                .frame(width: W, height: H, alignment: .bottom)
        }
    }
}

struct PlMazeFace: View {
    var body: some View {
        HPBox { W, H in
            let wall = max(1, W * 0.026)
            ZStack(alignment: .topLeading) {
                Rectangle().fill(Color(hex: 0x8e3526))
                Rectangle().fill(Fr.ochre).hp(W, H, x: 0.5, y: 0.5, w: 0.92, h: 0.92)
                Rectangle().fill(Color(hex: 0xf3e9d0)).hp(W, H, x: 0.5, y: 0.5, w: 0.88, h: 0.88)
                // a running wave pattern in the border
                HPPath { p, P in
                    let n = 12
                    for i in 0..<n {
                        let a = CGFloat(i) / CGFloat(n), b = CGFloat(i + 1) / CGFloat(n)
                        p.move(to: P(0.02 + a * 0.96, 0.035)); p.addQuadCurve(to: P(0.02 + b * 0.96, 0.035), control: P(0.02 + (a + b) / 2 * 0.96, 0.0))
                        p.move(to: P(0.02 + a * 0.96, 0.975)); p.addQuadCurve(to: P(0.02 + b * 0.96, 0.975), control: P(0.02 + (a + b) / 2 * 0.96, 1.0))
                    }
                }
                .stroke(Fr.marble.opacity(0.8), lineWidth: max(0.5, W * 0.008))
                // the maze walls: nested squares, each with a doorway, and cross walls to make you turn
                PlMazeWalls().stroke(Pl.ink, style: StrokeStyle(lineWidth: wall, lineCap: .square))
                // the middle: where the Minotaur waited
                Rectangle().fill(Color(hex: 0x8e3526)).hp(W, H, x: 0.5, y: 0.5, w: 0.1, h: 0.1)
                Rectangle().fill(Fr.gold).hp(W, H, x: 0.5, y: 0.5, w: 0.045, h: 0.045)
            }
        }
    }
}

private struct PlMazeWalls: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        let radii: [CGFloat] = [0.4, 0.32, 0.24, 0.16, 0.09]
        let g: CGFloat = 0.05
        for (k, rr) in radii.enumerated() {
            let a = 0.5 - rr, b = 0.5 + rr
            // doorway: bottom for even rings, top for odd, shifted left/right so the way winds
            let shift: CGFloat = k % 2 == 0 ? -0.12 : 0.12
            let doorY = k % 2 == 0 ? b : a
            let d0 = 0.5 + shift - g / 2, d1 = 0.5 + shift + g / 2
            if k == 0 {
                // the entrance in the middle of the bottom
                p.move(to: P(0.5 + g / 2, b)); p.addLine(to: P(b, b)); p.addLine(to: P(b, a)); p.addLine(to: P(a, a))
                p.addLine(to: P(a, b)); p.addLine(to: P(0.5 - g / 2, b))
                continue
            }
            if doorY == b {
                p.move(to: P(d1, b)); p.addLine(to: P(b, b)); p.addLine(to: P(b, a)); p.addLine(to: P(a, a)); p.addLine(to: P(a, b)); p.addLine(to: P(d0, b))
            } else {
                p.move(to: P(d1, a)); p.addLine(to: P(b, a)); p.addLine(to: P(b, b)); p.addLine(to: P(a, b)); p.addLine(to: P(a, a)); p.addLine(to: P(d0, a))
            }
        }
        // cross walls between rings, so each corridor is a dead end one way
        let cross: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0.5, 0.9, 0.5, 0.82), (0.1, 0.5, 0.18, 0.5), (0.9, 0.42, 0.82, 0.42),
            (0.5, 0.18, 0.5, 0.26), (0.26, 0.6, 0.34, 0.6), (0.74, 0.5, 0.66, 0.5),
            (0.6, 0.66, 0.6, 0.74), (0.42, 0.34, 0.42, 0.41),
        ]
        for c in cross { p.move(to: P(c.0, c.1)); p.addLine(to: P(c.2, c.3)) }
        return p
    }
}

/// The wrestling pit: a wooden-edged bed of fine, dug-over sand with a rake laid across it.
struct PlSandPit: View {
    var body: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                HPPoly(pts: [(0.12, 0.5), (0.88, 0.5), (1, 0.97), (0, 0.97)]).fill(Pl.woodDeep)
                HPPoly(pts: [(0.15, 0.53), (0.85, 0.53), (0.95, 0.93), (0.05, 0.93)])
                    .fill(LinearGradient(colors: [Pl.sandFine, Color(hex: 0xe9cf9a)], startPoint: .top, endPoint: .bottom))
                HPPath { p, P in
                    for i in 1..<6 {
                        let y = 0.53 + CGFloat(i) * 0.066
                        let inset = 0.15 - 0.1 * (y - 0.53) / 0.4
                        p.move(to: P(inset + 0.04, y)); p.addLine(to: P(1 - inset - 0.04, y))
                    }
                }
                .stroke(Pl.sandDeep.opacity(0.55), style: StrokeStyle(lineWidth: max(0.5, W * 0.006), lineCap: .round, dash: [W * 0.05, W * 0.025]))
                // footprints of the last bout
                ForEach(0..<4, id: \.self) { i in
                    Ellipse().fill(Pl.sandDeep.opacity(0.55))
                        .frame(width: W * 0.035, height: H * 0.05)
                        .rotationEffect(.degrees(i % 2 == 0 ? -15 : 15))
                        .position(x: W * (0.3 + CGFloat(i) * 0.08), y: H * (0.8 - CGFloat(i % 2) * 0.05 - CGFloat(i) * 0.03))
                }
                // the near rim plank
                Rectangle().fill(LinearGradient(colors: [Pl.wood, Pl.woodDeep], startPoint: .top, endPoint: .bottom))
                    .hp(W, H, x: 0.5, y: 0.955, w: 1, h: 0.05)
                // a rake laid across the corner
                HPPath { p, P in p.move(to: P(0.56, 0.62)); p.addLine(to: P(0.96, 0.9)) }
                    .stroke(Pl.wood, style: StrokeStyle(lineWidth: max(1, W * 0.022), lineCap: .round))
                HPPath { p, P in
                    p.move(to: P(0.48, 0.66)); p.addLine(to: P(0.62, 0.55))
                    for i in 0..<6 { let u = CGFloat(i) / 5; let x = 0.48 + 0.14 * u, y = 0.66 - 0.11 * u; p.move(to: P(x, y)); p.addLine(to: P(x - 0.015, y + 0.04)) }
                }
                .stroke(Pl.woodDeep, style: StrokeStyle(lineWidth: max(1, W * 0.016), lineCap: .round))
            }
        }
    }
}

/// Two bronze discuses: one leaning on a stone block, one lying in the sand.
struct PlDiscus: View {
    var body: some View {
        HPBox { W, H in
            let bronze = RadialGradient(colors: [Color(hex: 0xf0cf86), Pl.bronze, Pl.bronzeDeep], center: .init(x: 0.38, y: 0.35),
                                        startRadius: 0, endRadius: W * 0.4)
            ZStack(alignment: .topLeading) {
                // stone block
                Rectangle().fill(LinearGradient(colors: [Pl.stone, Pl.stoneDeep], startPoint: .top, endPoint: .bottom))
                    .hp(W, H, x: 0.68, y: 0.7, w: 0.5, h: 0.42)
                Rectangle().fill(Color(hex: 0xb3ada2)).hp(W, H, x: 0.68, y: 0.48, w: 0.5, h: 0.06)
                // leaning disc
                Ellipse().fill(bronze).overlay(Ellipse().stroke(Pl.bronzeDeep, lineWidth: max(0.8, W * 0.02)))
                    .overlay(Ellipse().stroke(Pl.bronzeDeep.opacity(0.6), lineWidth: max(0.5, W * 0.01)).padding(W * 0.12))
                    .frame(width: W * 0.56, height: W * 0.62).rotationEffect(.degrees(12))
                    .position(x: W * 0.4, y: H * 0.6)
                // lying disc
                Ellipse().fill(Pl.bronzeDeep).hp(W, H, x: 0.62, y: 0.93, w: 0.62, h: 0.15)
                Ellipse().fill(bronze).hp(W, H, x: 0.62, y: 0.91, w: 0.62, h: 0.14)
                Ellipse().stroke(Pl.bronzeDeep.opacity(0.6), lineWidth: max(0.5, W * 0.01)).hp(W, H, x: 0.62, y: 0.91, w: 0.36, h: 0.07)
            }
        }
    }
}

/// The palus: a stout training post planted in the sand, nicked by practice blows, with a wooden
/// practice sword (rudis) and a wicker shield leaning on it.
struct PlPost: View {
    var body: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                Ellipse().fill(Pl.sandDeep).hp(W, H, x: 0.5, y: 0.93, w: 0.62, h: 0.1)
                // post
                PlTopRound(r: W * 0.09).fill(LinearGradient(colors: [Color(hex: 0xa87648), Pl.woodDeep], startPoint: .leading, endPoint: .trailing))
                    .hp(W, H, x: 0.5, y: 0.52, w: 0.22, h: 0.82)
                // grain and nicks
                HPPath { p, P in
                    p.move(to: P(0.44, 0.18)); p.addLine(to: P(0.45, 0.9))
                    p.move(to: P(0.55, 0.15)); p.addLine(to: P(0.54, 0.9))
                }
                .stroke(Color.black.opacity(0.18), lineWidth: max(0.5, W * 0.008))
                HPPath { p, P in
                    for (x, y) in [(0.42, 0.3), (0.5, 0.36), (0.44, 0.44), (0.54, 0.27), (0.48, 0.52)] as [(CGFloat, CGFloat)] {
                        p.move(to: P(x, y)); p.addLine(to: P(x + 0.07, y - 0.025))
                    }
                }
                .stroke(Color(hex: 0xe8c99a), style: StrokeStyle(lineWidth: max(0.8, W * 0.012), lineCap: .round))
                // iron bands
                Rectangle().fill(Hb.iron).hp(W, H, x: 0.5, y: 0.2, w: 0.23, h: 0.03)
                Rectangle().fill(Hb.iron).hp(W, H, x: 0.5, y: 0.66, w: 0.23, h: 0.03)
                // wicker shield leaning on the left
                ZStack {
                    Ellipse().fill(Color(hex: 0xc9a062))
                    ForEach(1..<4, id: \.self) { i in
                        Ellipse().stroke(Color(hex: 0x8e6a32), lineWidth: max(0.6, W * 0.012)).padding(W * 0.035 * CGFloat(i))
                    }
                    Circle().fill(Pl.woodDeep).frame(width: W * 0.08)
                }
                .frame(width: W * 0.38, height: W * 0.46).rotationEffect(.degrees(-10))
                .position(x: W * 0.26, y: H * 0.72)
                // wooden sword leaning on the right
                ZStack(alignment: .top) {
                    Capsule().fill(LinearGradient(colors: [Color(hex: 0xd2a876), Color(hex: 0xa87a48)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: W * 0.07, height: H * 0.42).offset(y: H * 0.1)
                    Capsule().fill(Pl.woodDeep).frame(width: W * 0.2, height: H * 0.03).offset(y: H * 0.09)
                    Capsule().fill(Pl.woodDeep).frame(width: W * 0.045, height: H * 0.1)
                }
                .frame(width: W * 0.2, height: H * 0.55, alignment: .top)
                .rotationEffect(.degrees(14))
                .position(x: W * 0.74, y: H * 0.66)
            }
        }
    }
}

/// A rectangle with rounded top corners only (iOS 16 has no UnevenRoundedRectangle).
struct PlTopRound: Shape {
    let r: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(self.r, rect.width / 2, rect.height / 2)
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r), control: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// One halter: a heavy stone jumping weight, rounded at the bottom, with a hand-hole cut through the top.
private struct PlHalter: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        p.move(to: P(0.3, 0.04))
        p.addLine(to: P(0.7, 0.04))
        p.addQuadCurve(to: P(0.84, 0.3), control: P(0.86, 0.06))
        p.addQuadCurve(to: P(0.5, 1), control: P(1.08, 0.94))
        p.addQuadCurve(to: P(0.16, 0.3), control: P(-0.08, 0.94))
        p.addQuadCurve(to: P(0.3, 0.04), control: P(0.14, 0.06))
        p.closeSubpath()
        // the grip
        p.addRoundedRect(in: CGRect(origin: P(0.3, 0.16), size: CGSize(width: r.width * 0.4, height: r.height * 0.2)),
                         cornerSize: CGSize(width: r.width * 0.12, height: r.height * 0.1))
        return p
    }
}

/// A pair of halteres, the jumping weights.
struct PlWeights: View {
    var body: some View {
        HPBox { W, H in
            let stone = LinearGradient(colors: [Color(hex: 0xb4aea2), Pl.stoneDeep], startPoint: .top, endPoint: .bottom)
            ZStack(alignment: .topLeading) {
                Ellipse().fill(Color.black.opacity(0.14)).hp(W, H, x: 0.5, y: 0.93, w: 0.95, h: 0.1)
                PlHalter().fill(stone, style: FillStyle(eoFill: true))
                    .overlay(PlHalter().stroke(Pl.stoneDeep, lineWidth: max(0.6, W * 0.014)))
                    .frame(width: W * 0.48, height: H * 0.56).rotationEffect(.degrees(-10)).position(x: W * 0.32, y: H * 0.62)
                PlHalter().fill(stone, style: FillStyle(eoFill: true))
                    .overlay(PlHalter().stroke(Pl.stoneDeep, lineWidth: max(0.6, W * 0.014)))
                    .frame(width: W * 0.48, height: H * 0.56).rotationEffect(.degrees(8)).position(x: W * 0.68, y: H * 0.66)
            }
        }
    }
}

/// A latrunculi board scratched on a stone table, with black and white pieces mid-game.
struct PlBoard: View {
    var body: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                Ellipse().fill(Color.black.opacity(0.14)).hp(W, H, x: 0.5, y: 0.95, w: 0.9, h: 0.08)
                // stone block: front face, then top
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0xd9cdb3), Color(hex: 0xa99d84)], startPoint: .top, endPoint: .bottom))
                    .hp(W, H, x: 0.5, y: 0.78, w: 0.76, h: 0.34)
                HPPoly(pts: [(0.17, 0.33), (0.83, 0.33), (0.95, 0.6), (0.05, 0.6)]).fill(Fr.marble)
                Rectangle().fill(Fr.marbleShade).hp(W, H, x: 0.5, y: 0.615, w: 0.92, h: 0.04)
                PlGrid().frame(width: W * 0.66, height: W * 0.66)
                    .rotation3DEffect(.degrees(58), axis: (x: 1, y: 0, z: 0), anchor: .center, perspective: 0.6)
                    .position(x: W * 0.5, y: H * 0.465)
            }
        }
    }
}

struct PlGrid: View {
    var body: some View {
        HPBox { W, H in
            let n = 8
            ZStack(alignment: .topLeading) {
                Rectangle().fill(Color(hex: 0xb07a46))
                HPPath { p, P in
                    for i in 0...n {
                        let f = CGFloat(i) / CGFloat(n)
                        p.move(to: P(f, 0)); p.addLine(to: P(f, 1)); p.move(to: P(0, f)); p.addLine(to: P(1, f))
                    }
                }
                .stroke(Color(hex: 0x5a3a1c), lineWidth: max(0.6, W * 0.012))
                ForEach(0..<14, id: \.self) { i in
                    let cx = (i * 3 + (i / 4)) % n, cy = i < 7 ? (i * 5) % 3 : n - 1 - (i * 5) % 3
                    Circle().fill(i < 7 ? Pl.ink : Fr.marble)
                        .overlay(Circle().stroke(i < 7 ? Color.black : Fr.marbleShade, lineWidth: max(0.5, W * 0.01)))
                        .hp(W, H, x: (CGFloat(cx) + 0.5) / CGFloat(n), y: (CGFloat(cy) + 0.5) / CGFloat(n), w: 0.09, h: 0.09)
                }
            }
        }
    }
}

/// Tali: knucklebones on a little red cloth, ready to toss.
struct PlTali: View {
    var body: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                Ellipse().fill(Fr.frame).hp(W, H, x: 0.5, y: 0.8, w: 1, h: 0.36)
                Ellipse().stroke(Fr.gold.opacity(0.8), lineWidth: max(0.6, W * 0.015)).hp(W, H, x: 0.5, y: 0.8, w: 0.88, h: 0.28)
                ForEach(0..<4, id: \.self) { i in
                    PlTalus().fill(LinearGradient(colors: [Pl.bone, Pl.boneShade], startPoint: .top, endPoint: .bottom))
                        .overlay(PlTalus().stroke(Color(hex: 0xa8966a), lineWidth: max(0.5, W * 0.012)))
                        .frame(width: W * 0.3, height: W * 0.2)
                        .rotationEffect(.degrees([-20, 15, 70, -5][i]))
                        .position(x: W * [0.28, 0.6, 0.78, 0.45][i], y: H * [0.74, 0.7, 0.82, 0.88][i])
                }
            }
        }
    }
}

/// One knucklebone: a squarish bone pinched in at the middle.
private struct PlTalus: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        p.move(to: P(0.15, 0.1))
        p.addQuadCurve(to: P(0.85, 0.1), control: P(0.5, 0.35))
        p.addQuadCurve(to: P(0.85, 0.9), control: P(1.05, 0.5))
        p.addQuadCurve(to: P(0.15, 0.9), control: P(0.5, 0.65))
        p.addQuadCurve(to: P(0.15, 0.1), control: P(-0.05, 0.5))
        p.closeSubpath()
        return p
    }
}

/// The racehorse at its hitching rail, with the victor's wreath and palm branch hung on the posts.
struct PlHorse: View {
    var t: Double = 0
    var body: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                Ellipse().fill(Color.black.opacity(0.14)).hp(W, H, x: 0.5, y: 0.95, w: 0.9, h: 0.07)
                // rail
                Rectangle().fill(Pl.woodDeep).hp(W, H, x: 0.1, y: 0.68, w: 0.05, h: 0.56)
                Rectangle().fill(Pl.woodDeep).hp(W, H, x: 0.9, y: 0.68, w: 0.05, h: 0.56)
                Rectangle().fill(LinearGradient(colors: [Pl.wood, Pl.woodDeep], startPoint: .top, endPoint: .bottom))
                    .hp(W, H, x: 0.5, y: 0.5, w: 0.92, h: 0.045)
                // a palm branch, the winner's prize, tied to the right post behind the horse
                PlPalm().frame(width: W * 0.16, height: H * 0.32).rotationEffect(.degrees(10 + 3 * sin(t * 1.3)), anchor: .bottom).position(x: W * 0.92, y: H * 0.38)
                PlStandingHorse(t: t).hp(W, H, x: 0.57, y: 0.6, w: 0.84, h: 0.7)
                // the victor's laurel wreath, hung on the left post
                Circle().stroke(Fr.leaf, style: StrokeStyle(lineWidth: max(1, W * 0.035), dash: [W * 0.03, W * 0.012]))
                    .hp(W, H, x: 0.09, y: 0.39, w: 0.14, h: 0.14)
                Capsule().fill(Fr.frame).hp(W, H, x: 0.09, y: 0.485, w: 0.03, h: 0.07)
                // the reins, tied to the left post
                HPPath { p, P in p.move(to: P(0.2, 0.46)); p.addQuadCurve(to: P(0.11, 0.51), control: P(0.14, 0.53)) }
                    .stroke(Fr.gold, style: StrokeStyle(lineWidth: max(0.8, W * 0.01), lineCap: .round))
            }
        }
    }
}

/// A groomed chestnut racehorse in profile (facing left), dressed in the colours of the Greens: a
/// green plume on its head, green ribbons in its mane and tail, and a green breastband with gold discs.
private struct PlStandingHorse: View {
    var t: Double = 0
    var body: some View {
        HPBox { W, H in
            let coat = LinearGradient(colors: [Color(hex: 0xa85e30), Color(hex: 0x7a3f1d)], startPoint: .top, endPoint: .bottom)
            let far = Color(hex: 0x5a2e15)
            let hair = Color(hex: 0x2e1a10)
            let green = Color(hex: 0x2f8a3c)
            let swish = CGFloat(sin(t * 1.6)) * 0.02
            ZStack(alignment: .topLeading) {
                // far legs (darker, behind)
                HPPoly(pts: [(0.38, 0.5), (0.44, 0.5), (0.43, 0.92), (0.4, 0.92)]).fill(far)
                HPPoly(pts: [(0.68, 0.48), (0.76, 0.5), (0.73, 0.7), (0.72, 0.92), (0.69, 0.92), (0.69, 0.7)]).fill(far)
                Rectangle().fill(hair).hp(W, H, x: 0.415, y: 0.94, w: 0.045, h: 0.04)
                Rectangle().fill(hair).hp(W, H, x: 0.705, y: 0.94, w: 0.045, h: 0.04)
                // tail, with a green ribbon bound round its top
                HPPath { p, P in
                    p.move(to: P(0.87, 0.36))
                    p.addQuadCurve(to: P(0.93 + swish, 0.8), control: P(0.97, 0.5))
                    p.addQuadCurve(to: P(0.86, 0.5), control: P(0.86 + swish, 0.7))
                    p.closeSubpath()
                }
                .fill(hair)
                Capsule().fill(green).frame(width: W * 0.06, height: H * 0.035).rotationEffect(.degrees(50)).position(x: W * 0.895, y: H * 0.42)
                // body: shoulder, barrel and quarters
                Ellipse().fill(coat).hp(W, H, x: 0.56, y: 0.47, w: 0.5, h: 0.28)
                Ellipse().fill(coat).hp(W, H, x: 0.35, y: 0.46, w: 0.21, h: 0.29)
                Ellipse().fill(coat).hp(W, H, x: 0.77, y: 0.44, w: 0.23, h: 0.29)
                Ellipse().fill(Color.white.opacity(0.12)).hp(W, H, x: 0.6, y: 0.39, w: 0.36, h: 0.07)
                // near legs
                HPPoly(pts: [(0.29, 0.52), (0.39, 0.52), (0.36, 0.92), (0.31, 0.92)]).fill(Color(hex: 0x8a4a24))
                HPPoly(pts: [(0.73, 0.48), (0.87, 0.5), (0.82, 0.7), (0.81, 0.92), (0.76, 0.92), (0.76, 0.7)]).fill(Color(hex: 0x8a4a24))
                // a white sock and the hooves
                Rectangle().fill(Fr.marble).hp(W, H, x: 0.333, y: 0.895, w: 0.04, h: 0.05)
                Rectangle().fill(hair).hp(W, H, x: 0.333, y: 0.94, w: 0.05, h: 0.04)
                Rectangle().fill(hair).hp(W, H, x: 0.783, y: 0.94, w: 0.05, h: 0.04)
                // neck, arched
                HPPath { p, P in
                    p.move(to: P(0.26, 0.5))
                    p.addQuadCurve(to: P(0.15, 0.15), control: P(0.16, 0.34))
                    p.addLine(to: P(0.25, 0.08))
                    p.addQuadCurve(to: P(0.43, 0.4), control: P(0.35, 0.14))
                    p.closeSubpath()
                }
                .fill(coat)
                // head: broad at the jaw, tapering to a soft muzzle, nose down a little
                HPPath { p, P in
                    p.move(to: P(0.15, 0.06))
                    p.addLine(to: P(0.27, 0.1))
                    p.addQuadCurve(to: P(0.13, 0.33), control: P(0.24, 0.26))
                    p.addQuadCurve(to: P(0.03, 0.29), control: P(0.05, 0.37))
                    p.addQuadCurve(to: P(0.15, 0.06), control: P(0.06, 0.15))
                    p.closeSubpath()
                }
                .fill(Color(hex: 0x9a5329))
                HPPoly(pts: [(0.18, 0.07), (0.2, -0.02), (0.23, 0.08)]).fill(Color(hex: 0x7a3f1d))     // ear
                HPPoly(pts: [(0.12, 0.11), (0.155, 0.1), (0.065, 0.27), (0.045, 0.26)]).fill(Fr.marble.opacity(0.85))  // blaze
                Circle().fill(hair).hp(W, H, x: 0.18, y: 0.14, w: 0.028, h: 0.034)                    // eye
                Circle().fill(hair.opacity(0.7)).hp(W, H, x: 0.05, y: 0.285, w: 0.02, h: 0.024)       // nostril
                // mane, with green ribbons plaited in
                HPPath { p, P in p.move(to: P(0.22, 0.08)); p.addQuadCurve(to: P(0.41, 0.36), control: P(0.35, 0.12)) }
                    .stroke(hair, style: StrokeStyle(lineWidth: max(1, W * 0.035), lineCap: .round))
                ForEach(0..<4, id: \.self) { i in
                    let u = CGFloat(i) / 3
                    Circle().fill(green)
                        .hp(W, H, x: 0.25 + 0.14 * u + 0.02 * u * u, y: 0.1 + 0.07 * u + 0.18 * u * u, w: 0.03, h: 0.04)
                }
                // bridle in gold
                HPPath { p, P in
                    p.move(to: P(0.22, 0.09)); p.addLine(to: P(0.1, 0.29))
                    p.move(to: P(0.055, 0.23)); p.addLine(to: P(0.15, 0.27))
                    p.move(to: P(0.15, 0.1)); p.addLine(to: P(0.25, 0.115))
                }
                .stroke(Fr.gold, style: StrokeStyle(lineWidth: max(0.8, W * 0.012), lineCap: .round))
                // the green plume of the faction, standing up from the poll
                ForEach(0..<3, id: \.self) { i in
                    Capsule().fill(i == 1 ? Color(hex: 0x3fa64e) : green)
                        .frame(width: W * 0.03, height: H * 0.13)
                        .rotationEffect(.degrees(Double(i - 1) * 22 + 6 * sin(t * 2 + Double(i))), anchor: .bottom)
                        .position(x: W * 0.205, y: H * 0.02)
                }
                Circle().fill(Fr.gold).hp(W, H, x: 0.205, y: 0.085, w: 0.03, h: 0.035)
                // green breastband with gold discs (phalerae)
                HPPath { p, P in p.move(to: P(0.25, 0.42)); p.addQuadCurve(to: P(0.43, 0.46), control: P(0.32, 0.52)) }
                    .stroke(green, style: StrokeStyle(lineWidth: max(1, W * 0.03), lineCap: .round))
                ForEach(0..<3, id: \.self) { i in
                    Circle().fill(Fr.gold).overlay(Circle().stroke(Color(hex: 0xa87a1f), lineWidth: 0.6))
                        .hp(W, H, x: 0.28 + CGFloat(i) * 0.055, y: 0.455 + (i == 1 ? 0.015 : 0), w: 0.035, h: 0.045)
                }
            }
        }
    }
}

private struct PlPalm: View {
    var body: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                HPPath { p, P in p.move(to: P(0.5, 1)); p.addQuadCurve(to: P(0.45, 0.02), control: P(0.6, 0.5)) }
                    .stroke(Fr.leafDark, lineWidth: max(1, W * 0.06))
                HPPath { p, P in
                    for i in 0..<9 {
                        let y = 0.1 + CGFloat(i) * 0.09, x = 0.5 + 0.05 * (1 - y)
                        p.move(to: P(x, y)); p.addQuadCurve(to: P(0.05, y + 0.12), control: P(0.2, y - 0.02))
                        p.move(to: P(x, y)); p.addQuadCurve(to: P(0.95, y + 0.12), control: P(0.8, y - 0.02))
                    }
                }
                .stroke(Fr.leaf, style: StrokeStyle(lineWidth: max(1, W * 0.045), lineCap: .round))
            }
        }
    }
}
