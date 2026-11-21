import SwiftUI

// MARK: - Harbor art (and the small drawing kit the Exercise Yard shares)
//
// Every piece is drawn in UNIT coordinates of its own box (0…1 across, 0…1 down), so the same drawing
// serves the room (sized by WingSpot) and the shop card's thumbnail.

/// A path written in unit coordinates of whatever rect it is drawn in.
struct HPPath: Shape {
    let draw: (inout Path, (CGFloat, CGFloat) -> CGPoint) -> Void
    init(_ draw: @escaping (inout Path, (CGFloat, CGFloat) -> CGPoint) -> Void) { self.draw = draw }
    func path(in r: CGRect) -> Path {
        var p = Path()
        draw(&p) { x, y in CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        return p
    }
}

/// A closed polygon through unit points.
struct HPPoly: Shape {
    let pts: [(CGFloat, CGFloat)]
    var closed = true
    func path(in r: CGRect) -> Path {
        var p = Path()
        guard let f = pts.first else { return p }
        p.move(to: CGPoint(x: r.minX + f.0 * r.width, y: r.minY + f.1 * r.height))
        for q in pts.dropFirst() { p.addLine(to: CGPoint(x: r.minX + q.0 * r.width, y: r.minY + q.1 * r.height)) }
        if closed { p.closeSubpath() }
        return p
    }
}

/// Lays a drawing (in unit coordinates) over a box of the given size — the common frame for art.
struct HPBox<Art: View>: View {
    @ViewBuilder let art: (_ W: CGFloat, _ H: CGFloat) -> Art
    var body: some View {
        GeometryReader { g in
            art(g.size.width, g.size.height)
                .frame(width: g.size.width, height: g.size.height, alignment: .topLeading)
        }
    }
}

extension View {
    /// Places a view of size (uw, uh) — in units of the box — centered at unit point (ux, uy).
    func hp(_ W: CGFloat, _ H: CGFloat, x ux: CGFloat, y uy: CGFloat, w uw: CGFloat, h uh: CGFloat) -> some View {
        self.frame(width: max(0.1, W * uw), height: max(0.1, H * uh)).position(x: W * ux, y: H * uy)
    }
}

/// A soft fresco cloud.
struct HPCloud: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: r.minX, y: r.midY - r.height * 0.1, width: r.width * 0.5, height: r.height * 0.6))
        p.addEllipse(in: CGRect(x: r.minX + r.width * 0.25, y: r.minY, width: r.width * 0.45, height: r.height * 0.9))
        p.addEllipse(in: CGRect(x: r.minX + r.width * 0.5, y: r.midY - r.height * 0.15, width: r.width * 0.5, height: r.height * 0.65))
        return p
    }
}

enum Hb {
    static let seaFar = Color(hex: 0x8cc0cc)
    static let sea = Color(hex: 0x5f9fba)
    static let seaNear = Color(hex: 0x3f7f9e)
    static let foam = Color.white.opacity(0.85)
    static let hull = Color(hex: 0x5a3a22)
    static let hullDeep = Color(hex: 0x3a2414)
    static let quay = Color(hex: 0xcfb98f)
    static let quayCap = Color(hex: 0xe3d2ac)
    static let quayJoint = Color(hex: 0x9c8661)
    static let rope = Color(hex: 0xb89a62)
    static let iron = Color(hex: 0x56524b)
    static let lead = Color(hex: 0x7c7f84)
    static let terracotta = Color(hex: 0xc0663a)
    static let terracottaDeep = Color(hex: 0x8e4220)
    static let sail = Color(hex: 0xf3e6c6)
    static let sailShade = Color(hex: 0xd9c49a)
}

// MARK: The backdrop: sky, a headland, the sea, a stone mole and the quay

/// A sine band of the sea's surface broken into short wave strokes — the fresco painter's ripples.
private struct HbRipples: Shape {
    let y: CGFloat, amp: CGFloat, wave: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path()
        var x = r.minX
        p.move(to: CGPoint(x: x, y: y))
        while x <= r.maxX {
            x += 3
            p.addLine(to: CGPoint(x: x, y: y + amp * sin(x / wave * .pi * 2)))
        }
        return p
    }
}

/// Distant hills on the horizon, defined by canvas fractions so they run on past the canvas edges.
private struct HbHeadland: Shape {
    let ox: CGFloat, w: CGFloat, base: CGFloat, height: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: base))
        var x = r.minX
        while x <= r.maxX + 4 {
            let u = Double((x - ox) / w)
            // a headland on the left, low far coast on the right
            let hill = 0.75 * exp(-pow((u - 0.08) / 0.2, 2)) + 0.18 + 0.1 * sin(u * 11) + 0.25 * exp(-pow((u - 1.1) / 0.25, 2))
            p.addLine(to: CGPoint(x: x, y: base - height * CGFloat(max(0, hill))))
            x += 4
        }
        p.addLine(to: CGPoint(x: r.maxX + 4, y: base))
        p.closeSubpath()
        return p
    }
}

struct HarborBackdrop: View {
    let w: CGFloat, h: CGFloat, t: Double
    static let horizon: CGFloat = 0.36
    static let quayEdge: CGFloat = 0.66

    var body: some View {
        let hz = h * Self.horizon, qe = h * Self.quayEdge
        let wide = w * 3, cx = w / 2
        ZStack(alignment: .topLeading) {
            // sun and drifting clouds
            Circle().fill(RadialGradient(colors: [Color(hex: 0xfff4cf), Color(hex: 0xf6d27a).opacity(0)], center: .center,
                                         startRadius: w * 0.03, endRadius: w * 0.13))
                .frame(width: w * 0.26, height: w * 0.26).position(x: w * 0.8, y: h * 0.1)
            Circle().fill(Color(hex: 0xfff1c4)).frame(width: w * 0.075).position(x: w * 0.8, y: h * 0.1)
            ForEach(0..<3, id: \.self) { i in
                let drift = CGFloat((t * 0.006 + Double(i) * 0.37).truncatingRemainder(dividingBy: 1.4)) - 0.2
                HPCloud().fill(.white.opacity(0.78))
                    .frame(width: w * (0.24 - CGFloat(i) * 0.04), height: w * 0.075)
                    .position(x: drift * w * 1.2, y: h * (0.07 + CGFloat(i % 2) * 0.07))
            }
            // gulls
            ForEach(0..<2, id: \.self) { i in
                let gx = CGFloat((t * 0.018 + Double(i) * 0.45).truncatingRemainder(dividingBy: 1.3)) - 0.15
                let flap = CGFloat(sin(t * 5 + Double(i) * 2)) * 0.25
                HPPath { p, P in
                    p.move(to: P(0, 0.5 + flap)); p.addQuadCurve(to: P(0.5, 0.55), control: P(0.25, 0))
                    p.addQuadCurve(to: P(1, 0.5 + flap), control: P(0.75, 0))
                }
                .stroke(Fr.ink.opacity(0.55), style: StrokeStyle(lineWidth: max(1, w * 0.005), lineCap: .round))
                .frame(width: w * 0.045, height: w * 0.02)
                .position(x: gx * w, y: h * (0.2 + CGFloat(i) * 0.05) + CGFloat(sin(t * 0.7 + Double(i))) * h * 0.01)
            }
            // a far headland with a little white temple
            HbHeadland(ox: w, w: w, base: hz + 1, height: h * 0.07)
                .fill(LinearGradient(colors: [Color(hex: 0xa7b696), Color(hex: 0x8fa486)], startPoint: .top, endPoint: .bottom))
                .frame(width: wide, height: hz + 2).position(x: cx, y: (hz + 2) / 2)
            HbTemple().frame(width: w * 0.06, height: w * 0.04).position(x: w * 0.075, y: hz - h * 0.058)
            // the sea, deepening toward the quay
            Rectangle().fill(LinearGradient(colors: [Hb.seaFar, Hb.sea, Hb.seaNear], startPoint: .top, endPoint: .bottom))
                .frame(width: wide, height: qe - hz + 2).position(x: cx, y: (hz + qe) / 2)
            Rectangle().fill(Color.white.opacity(0.5)).frame(width: wide, height: 1).position(x: cx, y: hz + 0.5)
            // a far sail on the horizon
            HPPoly(pts: [(0.5, 0), (0.95, 0.75), (0.1, 0.75)]).fill(Hb.sail.opacity(0.9))
                .overlay(Rectangle().fill(Hb.hullDeep.opacity(0.7)).frame(height: w * 0.006).frame(maxHeight: .infinity, alignment: .bottom))
                .frame(width: w * 0.025, height: w * 0.03)
                .position(x: w * (0.6 + 0.02 * CGFloat(sin(t * 0.05))), y: hz - w * 0.01)
            // the swell: rows of ripples, larger and slower toward us
            ForEach(0..<6, id: \.self) { i in
                let f = CGFloat(i) / 5
                let y = hz + (qe - hz) * (0.1 + 0.82 * f * f * 0.6 + 0.3 * f)
                HbRipples(y: y, amp: h * (0.002 + 0.004 * f), wave: w * (0.05 + 0.06 * f))
                    .stroke(Color.white.opacity(0.32 + 0.2 * Double(f)),
                            style: StrokeStyle(lineWidth: max(0.7, w * (0.002 + 0.003 * f)), lineCap: .round,
                                               dash: [w * (0.03 + 0.05 * f), w * (0.05 + 0.07 * f)],
                                               dashPhase: CGFloat(t * Double(4 + 6 * f)) + CGFloat(i * 17)))
                    .frame(width: wide, height: h).position(x: cx, y: h / 2)
            }
            // sun glints on the water
            ForEach(0..<5, id: \.self) { i in
                let a = 0.5 + 0.5 * sin(t * 1.7 + Double(i) * 1.9)
                Capsule().fill(Color.white.opacity(0.75 * a))
                    .frame(width: w * 0.03, height: max(1, w * 0.004))
                    .position(x: w * (0.7 + 0.05 * CGFloat(i % 3) - 0.04 * CGFloat(i / 3)), y: h * (0.4 + 0.035 * CGFloat(i)))
            }
            // the stone mole running out to the lighthouse's spot
            HbMole().frame(width: w * 0.5, height: h * 0.07).position(x: w * 0.96, y: h * 0.505)
            // the quay: capstones along the edge, then the paving
            HbPaving(ox: w, w: w, top: qe, h: h).stroke(Hb.quayJoint.opacity(0.55), lineWidth: max(0.6, w * 0.0025))
                .frame(width: wide, height: h * 1.6).position(x: cx, y: h * 0.8)
            HbCapstones(ox: -w, w: w, top: qe, depth: h * 0.032).frame(width: wide, height: h).position(x: cx, y: h / 2)
            Rectangle().fill(Hb.seaNear.opacity(0.9)).frame(width: wide, height: max(1, h * 0.006)).position(x: cx, y: qe - h * 0.003)
            // mooring bollards and a coil of rope
            HbBollard().frame(width: w * 0.05, height: w * 0.06).position(x: w * 0.72, y: qe + h * 0.03)
            HbBollard().frame(width: w * 0.05, height: w * 0.06).position(x: w * 0.5, y: qe + h * 0.03)
            HbRopeCoil().frame(width: w * 0.08, height: w * 0.04).position(x: w * 0.6, y: qe + h * 0.07)
        }
    }
}

private struct HbTemple: View {
    var body: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                HPPoly(pts: [(0.05, 0.38), (0.5, 0), (0.95, 0.38)]).fill(Fr.marble)
                ForEach(0..<4, id: \.self) { i in
                    Rectangle().fill(Fr.marble).hp(W, H, x: 0.15 + CGFloat(i) * 0.233, y: 0.68, w: 0.1, h: 0.5)
                }
                Rectangle().fill(Fr.marbleShade).hp(W, H, x: 0.5, y: 0.96, w: 1, h: 0.08)
            }
        }
    }
}

private struct HbMole: View {
    var body: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                // top surface and the sea-facing side
                HPPoly(pts: [(0.04, 0.2), (1, 0.2), (1, 0.55), (0, 0.55)]).fill(Hb.quayCap)
                HPPoly(pts: [(0, 0.55), (1, 0.55), (1, 1), (0.02, 1)]).fill(Color(hex: 0xa9946c))
                HPPath { p, P in
                    for i in 0..<9 { let x = 0.03 + CGFloat(i) * 0.12; p.move(to: P(x, 0.55)); p.addLine(to: P(x + 0.01, 1)) }
                    for i in 0..<9 { let x = 0.09 + CGFloat(i) * 0.12; p.move(to: P(x, 0.2)); p.addLine(to: P(x, 0.55)) }
                    p.move(to: P(0, 0.55)); p.addLine(to: P(1, 0.55))
                }
                .stroke(Hb.quayJoint.opacity(0.8), lineWidth: max(0.5, W * 0.005))
                Rectangle().fill(Color.white.opacity(0.6)).hp(W, H, x: 0.5, y: 1, w: 1, h: 0.06)
            }
        }
    }
}

/// The quay paving: courses getting deeper toward us, joints running back to a vanishing point.
private struct HbPaving: Shape {
    let ox: CGFloat, w: CGFloat, top: CGFloat, h: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path()
        let rows: [CGFloat] = [0.035, 0.1, 0.19, 0.3, 0.45, 0.65]
        let vx = ox + w * 0.5, vy = top - h * 0.5
        var prev = top + h * 0.032
        for (k, d) in rows.enumerated() {
            let y = top + h * d
            p.move(to: CGPoint(x: r.minX, y: y)); p.addLine(to: CGPoint(x: r.maxX, y: y))
            // staggered joints between prev and y, aimed at the vanishing point
            let n = 26
            for i in 0..<n {
                let u = (CGFloat(i) + (k % 2 == 0 ? 0 : 0.5)) / CGFloat(n) * 3 - 1
                let xb = ox + u * w
                let t0 = (prev - vy) / (y - vy)
                p.move(to: CGPoint(x: vx + (xb - vx) * t0, y: prev)); p.addLine(to: CGPoint(x: xb, y: y))
            }
            prev = y
        }
        return p
    }
}

private struct HbCapstones: View {
    let ox: CGFloat, w: CGFloat, top: CGFloat, depth: CGFloat
    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(LinearGradient(colors: [Hb.quayCap, Color(hex: 0xd6c39c)], startPoint: .top, endPoint: .bottom))
                .frame(width: w * 3, height: depth).offset(y: top)
            ForEach(0..<30, id: \.self) { i in
                Rectangle().fill(Hb.quayJoint.opacity(0.7)).frame(width: max(0.6, w * 0.003), height: depth)
                    .offset(x: CGFloat(i) * w * 0.1 + w * 0.03, y: top)
            }
            Rectangle().fill(Hb.quayJoint.opacity(0.6)).frame(width: w * 3, height: max(0.6, w * 0.003)).offset(y: top + depth)
        }
    }
}

private struct HbBollard: View {
    var body: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                Ellipse().fill(Color.black.opacity(0.15)).hp(W, H, x: 0.55, y: 0.92, w: 1, h: 0.18)
                Capsule().fill(LinearGradient(colors: [Color(hex: 0x8a7b62), Color(hex: 0x5d5140)], startPoint: .leading, endPoint: .trailing))
                    .hp(W, H, x: 0.5, y: 0.55, w: 0.55, h: 0.8)
                Ellipse().fill(Color(hex: 0xa3937a)).hp(W, H, x: 0.5, y: 0.2, w: 0.7, h: 0.22)
                Rectangle().fill(Hb.rope).hp(W, H, x: 0.5, y: 0.55, w: 0.6, h: 0.1)
            }
        }
    }
}

private struct HbRopeCoil: View {
    var body: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                ForEach(0..<3, id: \.self) { i in
                    Ellipse().stroke(i % 2 == 0 ? Hb.rope : Color(hex: 0x9c7f4c), lineWidth: max(1, W * 0.09))
                        .hp(W, H, x: 0.5, y: 0.6 - CGFloat(i) * 0.12, w: 0.9 - CGFloat(i) * 0.2, h: 0.6 - CGFloat(i) * 0.1)
                }
            }
        }
    }
}

/// Where a floating thing meets the sea: its drawing is cut off at the waterline and a foam lip with
/// a little translucent swell sits over the cut, so it reads as afloat on any part of the sea.
struct HbAfloat<Art: View>: View {
    let t: Double
    var top: CGFloat = 0.86
    @ViewBuilder let art: Art
    var body: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                art.mask(VStack(spacing: 0) { Rectangle().frame(height: H * (top + 0.012)); Spacer(minLength: 0) })
                HPPath { p, P in
                    p.move(to: P(0.02, top + 0.012))
                    var x: CGFloat = 0.02
                    while x <= 0.98 { p.addLine(to: P(x, top + 0.012 * CGFloat(sin(Double(x) * 18 + t * 2)))); x += 0.02 }
                    p.addLine(to: P(0.98, top + 0.04)); p.addQuadCurve(to: P(0.02, top + 0.04), control: P(0.5, top + 0.06))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [Hb.sea.opacity(0.8), Hb.sea.opacity(0)], startPoint: .top, endPoint: .bottom))
                HPPath { p, P in
                    p.move(to: P(0.06, top))
                    var x: CGFloat = 0.06
                    while x <= 0.94 { p.addLine(to: P(x, top + 0.012 * CGFloat(sin(Double(x) * 18 + t * 2)))); x += 0.02 }
                }
                .stroke(Hb.foam, style: StrokeStyle(lineWidth: max(1, W * 0.012), lineCap: .round))
            }
        }
    }
}

// MARK: Items

/// A Roman merchant ship (corbita): a round-bellied hull, the swan-neck sternpost, a big square sail,
/// a little foresail (artemon) leaning over the bow and a painted eye to see the way.
struct HbShip: View {
    let t: Double
    var body: some View { HbAfloat(t: t, top: 0.9) { hull } }
    private var hull: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                // stays
                HPPath { p, P in
                    p.move(to: P(0.52, 0.07)); p.addLine(to: P(0.95, 0.47))
                    p.move(to: P(0.52, 0.07)); p.addLine(to: P(0.12, 0.5))
                    p.move(to: P(0.52, 0.1)); p.addLine(to: P(0.3, 0.66))
                    p.move(to: P(0.52, 0.1)); p.addLine(to: P(0.74, 0.66))
                }
                .stroke(Fr.ink.opacity(0.45), lineWidth: max(0.5, W * 0.004))
                // mast and pennant
                Rectangle().fill(Hb.hullDeep).hp(W, H, x: 0.52, y: 0.39, w: 0.022, h: 0.64)
                let flap = CGFloat(sin(t * 3.1)) * 0.012
                HPPoly(pts: [(0, 0), (1, 0.5 + flap * 20), (0, 1)]).fill(Fr.frame)
                    .hp(W, H, x: 0.56 + flap, y: 0.06, w: 0.08, h: 0.035)
                // the main sail
                let belly = 0.012 * CGFloat(sin(t * 0.8))
                HPPath { p, P in
                    p.move(to: P(0.25, 0.13))
                    p.addQuadCurve(to: P(0.79, 0.13), control: P(0.52, 0.10))
                    p.addQuadCurve(to: P(0.76, 0.56), control: P(0.84 + belly, 0.34))
                    p.addQuadCurve(to: P(0.28, 0.56), control: P(0.52, 0.62 + belly))
                    p.addQuadCurve(to: P(0.25, 0.13), control: P(0.2 - belly, 0.34))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [Hb.sail, Hb.sailShade], startPoint: .leading, endPoint: .trailing))
                // brail lines and a red band
                HPPath { p, P in
                    for i in 1..<6 { let x = 0.25 + CGFloat(i) * 0.09; p.move(to: P(x, 0.13)); p.addQuadCurve(to: P(x + 0.005, 0.57), control: P(x + 0.015, 0.36)) }
                }
                .stroke(Fr.ochre.opacity(0.6), lineWidth: max(0.5, W * 0.004))
                HPPath { p, P in
                    p.move(to: P(0.265, 0.47)); p.addQuadCurve(to: P(0.775, 0.47), control: P(0.52, 0.52 + belly))
                }
                .stroke(Fr.frame.opacity(0.85), lineWidth: max(1, W * 0.025))
                // yard
                HPPath { p, P in p.move(to: P(0.22, 0.135)); p.addQuadCurve(to: P(0.82, 0.135), control: P(0.52, 0.1)) }
                    .stroke(Hb.hullDeep, style: StrokeStyle(lineWidth: max(1, W * 0.016), lineCap: .round))
                // artemon: the foremast leaning over the bow, with its small sail
                HPPath { p, P in p.move(to: P(0.84, 0.7)); p.addLine(to: P(0.97, 0.42)) }
                    .stroke(Hb.hullDeep, style: StrokeStyle(lineWidth: max(1, W * 0.014), lineCap: .round))
                HPPoly(pts: [(0.86, 0.46), (0.99, 0.43), (0.97, 0.58), (0.86, 0.6)]).fill(Hb.sail)
                    .overlay(HPPoly(pts: [(0.86, 0.46), (0.99, 0.43), (0.97, 0.58), (0.86, 0.6)]).stroke(Hb.sailShade, lineWidth: 0.8))
                // stern cabin with a tiled roof
                Rectangle().fill(Fr.stucco).hp(W, H, x: 0.24, y: 0.665, w: 0.15, h: 0.07)
                HPPoly(pts: [(0.15, 0.635), (0.33, 0.635), (0.31, 0.6), (0.17, 0.6)]).fill(Fr.tile)
                // hull
                HPPath { p, P in
                    p.move(to: P(0.12, 0.69))
                    p.addQuadCurve(to: P(0.9, 0.67), control: P(0.5, 0.77))
                    p.addQuadCurve(to: P(0.88, 0.86), control: P(0.84, 0.76))
                    p.addLine(to: P(0.95, 0.89))
                    p.addLine(to: P(0.82, 0.93))
                    p.addQuadCurve(to: P(0.2, 0.93), control: P(0.5, 1.0))
                    p.addQuadCurve(to: P(0.12, 0.69), control: P(0.07, 0.86))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [Hb.hull, Hb.hullDeep], startPoint: .top, endPoint: .bottom))
                // planking and the painted wale
                HPPath { p, P in
                    p.move(to: P(0.15, 0.8)); p.addQuadCurve(to: P(0.86, 0.79), control: P(0.5, 0.88))
                    p.move(to: P(0.18, 0.87)); p.addQuadCurve(to: P(0.86, 0.87), control: P(0.5, 0.94))
                }
                .stroke(Color.black.opacity(0.25), lineWidth: max(0.5, W * 0.004))
                HPPath { p, P in p.move(to: P(0.13, 0.725)); p.addQuadCurve(to: P(0.88, 0.705), control: P(0.5, 0.81)) }
                    .stroke(Fr.ochre, lineWidth: max(1, W * 0.02))
                HPPath { p, P in p.move(to: P(0.14, 0.755)); p.addQuadCurve(to: P(0.87, 0.74), control: P(0.5, 0.84)) }
                    .stroke(Fr.frame, lineWidth: max(1, W * 0.012))
                // the eye on the bow
                Ellipse().fill(Color.white).hp(W, H, x: 0.835, y: 0.785, w: 0.05, h: 0.03)
                Circle().fill(Fr.ink).hp(W, H, x: 0.84, y: 0.785, w: 0.022, h: 0.022)
                // swan-neck sternpost
                HPPath { p, P in
                    p.move(to: P(0.14, 0.72)); p.addQuadCurve(to: P(0.06, 0.53), control: P(0.04, 0.68))
                    p.addQuadCurve(to: P(0.15, 0.47), control: P(0.07, 0.42))
                }
                .stroke(Fr.ochre, style: StrokeStyle(lineWidth: max(1, W * 0.028), lineCap: .round))
                Circle().fill(Fr.ochre).hp(W, H, x: 0.155, y: 0.475, w: 0.04, h: 0.04)
                HPPoly(pts: [(0.168, 0.462), (0.21, 0.478), (0.168, 0.49)]).fill(Fr.gold)
                Circle().fill(Fr.ink).hp(W, H, x: 0.158, y: 0.47, w: 0.012, h: 0.012)
                // steering oar
                HPPath { p, P in p.move(to: P(0.23, 0.72)); p.addLine(to: P(0.15, 0.93)) }
                    .stroke(Fr.trunk, style: StrokeStyle(lineWidth: max(1, W * 0.014), lineCap: .round))
                Capsule().fill(Fr.trunk).frame(width: W * 0.035, height: H * 0.09).rotationEffect(.degrees(12)).position(x: W * 0.145, y: H * 0.92)
            }
        }
    }
}

/// A small rowing boat with its oars shipped, moored at the quay.
struct HbBoat: View {
    let t: Double
    var body: some View { HbAfloat(t: t + 1, top: 0.8) { boat } }
    private var boat: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                // oars resting across the boat
                HPPath { p, P in
                    p.move(to: P(0.22, 0.42)); p.addLine(to: P(0.72, 0.66))
                    p.move(to: P(0.8, 0.44)); p.addLine(to: P(0.3, 0.66))
                }
                .stroke(Color(hex: 0xb08850), style: StrokeStyle(lineWidth: max(1, W * 0.025), lineCap: .round))
                Capsule().fill(Color(hex: 0xb08850)).frame(width: W * 0.12, height: H * 0.05).rotationEffect(.degrees(26)).position(x: W * 0.21, y: H * 0.42)
                Capsule().fill(Color(hex: 0xb08850)).frame(width: W * 0.12, height: H * 0.05).rotationEffect(.degrees(-26)).position(x: W * 0.81, y: H * 0.43)
                // hull, rising at both ends
                HPPath { p, P in
                    p.move(to: P(0.04, 0.52))
                    p.addQuadCurve(to: P(0.96, 0.5), control: P(0.5, 0.7))
                    p.addQuadCurve(to: P(0.8, 0.84), control: P(0.92, 0.76))
                    p.addQuadCurve(to: P(0.2, 0.84), control: P(0.5, 0.9))
                    p.addQuadCurve(to: P(0.04, 0.52), control: P(0.08, 0.76))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [Color(hex: 0x4d8590), Color(hex: 0x2f5c66)], startPoint: .top, endPoint: .bottom))
                HPPath { p, P in p.move(to: P(0.05, 0.54)); p.addQuadCurve(to: P(0.95, 0.52), control: P(0.5, 0.72)) }
                    .stroke(Fr.ochre, lineWidth: max(1, W * 0.03))
                HPPath { p, P in p.move(to: P(0.12, 0.7)); p.addQuadCurve(to: P(0.88, 0.69), control: P(0.5, 0.82)) }
                    .stroke(Color.black.opacity(0.22), lineWidth: max(0.5, W * 0.008))
                // an eye at the bow, as on the big ships
                Circle().fill(Color.white).hp(W, H, x: 0.86, y: 0.6, w: 0.05, h: 0.05)
                Circle().fill(Fr.ink).hp(W, H, x: 0.865, y: 0.6, w: 0.025, h: 0.025)
            }
        }
    }
}

/// Two dolphins taking turns to leap out of the swell.
struct HbDolphins: View {
    let t: Double
    var still = false
    var body: some View { HbAfloat(t: t + 2, top: 0.84) { pod } }
    private var pod: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                ForEach(0..<2, id: \.self) { i in
                    let p = (t * 0.22 + Double(i) * 0.5).truncatingRemainder(dividingBy: 1)
                    let q = min(1, p / 0.42)                    // the leap takes the first 42% of the cycle
                    let up = still || p < 0.42
                    let x0: CGFloat = i == 0 ? 0.12 : 0.42
                    let x = still ? (i == 0 ? 0.3 : 0.7) : x0 + 0.42 * CGFloat(q)
                    let y = still ? (i == 0 ? 0.5 : 0.6) : 0.82 - 0.55 * CGFloat(sin(Double.pi * q))
                    let tilt = still ? (i == 0 ? -20.0 : 25.0) : -35 + 70 * q
                    Text("🐬").font(.system(size: W * 0.4))
                        .scaleEffect(x: -1, y: 1)
                        .rotationEffect(.degrees(tilt))
                        .position(x: W * x, y: H * y)
                        .opacity(up ? 1 : 0)
                    // splash rings where it dives in
                    let r = up ? 0 : CGFloat((p - 0.42) / 0.58)
                    Ellipse().stroke(Color.white.opacity(up ? 0 : 0.8 * Double(1 - r)), lineWidth: max(0.8, W * 0.012))
                        .frame(width: W * (0.1 + 0.25 * r), height: H * (0.03 + 0.05 * r))
                        .position(x: W * (x0 + 0.42), y: H * 0.86)
                }
            }
        }
    }
}

/// A little Pharos: square tower, octagonal storey, round lantern and the fire on top.
struct HbLighthouse: View {
    let t: Double
    var body: some View {
        HPBox { W, H in
            let stone = LinearGradient(colors: [Fr.marble, Fr.marbleShade], startPoint: .leading, endPoint: .trailing)
            let flick = CGFloat(sin(t * 11) * 0.5 + sin(t * 17) * 0.5)
            ZStack(alignment: .topLeading) {
                // glow
                Circle().fill(RadialGradient(colors: [Color(hex: 0xffd27a).opacity(0.75), Color(hex: 0xffb347).opacity(0)],
                                             center: .center, startRadius: 0, endRadius: W * (0.2 + 0.02 * flick)))
                    .hp(W, H, x: 0.5, y: 0.08, w: 0.5, h: 0.5)
                // plinth and the square tower
                Rectangle().fill(Fr.marbleShade).hp(W, H, x: 0.5, y: 0.955, w: 0.78, h: 0.09)
                Rectangle().fill(stone).hp(W, H, x: 0.5, y: 0.89, w: 0.66, h: 0.05)
                HPPoly(pts: [(0.27, 0.87), (0.73, 0.87), (0.67, 0.45), (0.33, 0.45)]).fill(stone)
                ForEach(0..<3, id: \.self) { r in
                    ForEach(0..<2, id: \.self) { c in
                        RoundedRectangle(cornerRadius: W * 0.01).fill(Fr.ink.opacity(0.7))
                            .hp(W, H, x: 0.43 + CGFloat(c) * 0.14, y: 0.53 + CGFloat(r) * 0.12, w: 0.05, h: 0.06)
                    }
                }
                Rectangle().fill(Fr.ochre).hp(W, H, x: 0.5, y: 0.445, w: 0.42, h: 0.025)
                // octagonal storey (three faces show)
                HPPoly(pts: [(0.37, 0.43), (0.63, 0.43), (0.61, 0.26), (0.39, 0.26)]).fill(stone)
                HPPath { p, P in p.move(to: P(0.45, 0.26)); p.addLine(to: P(0.445, 0.43)); p.move(to: P(0.55, 0.26)); p.addLine(to: P(0.555, 0.43)) }
                    .stroke(Fr.marbleShade, lineWidth: max(0.5, W * 0.008))
                RoundedRectangle(cornerRadius: W * 0.01).fill(Fr.ink.opacity(0.7)).hp(W, H, x: 0.5, y: 0.34, w: 0.04, h: 0.06)
                Rectangle().fill(Fr.ochre).hp(W, H, x: 0.5, y: 0.255, w: 0.3, h: 0.02)
                // round lantern on little columns
                Rectangle().fill(Fr.marbleShade).hp(W, H, x: 0.5, y: 0.2, w: 0.18, h: 0.1)
                ForEach(0..<3, id: \.self) { i in
                    Rectangle().fill(Fr.marble).hp(W, H, x: 0.43 + CGFloat(i) * 0.07, y: 0.2, w: 0.025, h: 0.1)
                }
                Rectangle().fill(Fr.ochre).hp(W, H, x: 0.5, y: 0.145, w: 0.22, h: 0.018)
                // the fire
                Ellipse().fill(Color(hex: 0xe8562a)).hp(W, H, x: 0.5, y: 0.1, w: 0.14 + 0.01 * flick, h: 0.1 + 0.015 * flick)
                Ellipse().fill(Color(hex: 0xffc94a)).hp(W, H, x: 0.5, y: 0.11, w: 0.08, h: 0.07 + 0.01 * flick)
                Ellipse().fill(Color(hex: 0xfff3c0)).hp(W, H, x: 0.5, y: 0.12, w: 0.035, h: 0.035)
            }
        }
    }
}

/// A map table: a parchment map of Mare Nostrum (the Mediterranean) on a wooden table, with a scroll.
struct HbMapTable: View {
    var body: some View {
        HPBox { W, H in
            let wood = LinearGradient(colors: [Color(hex: 0x8a5a34), Color(hex: 0x5e3a1f)], startPoint: .top, endPoint: .bottom)
            ZStack(alignment: .topLeading) {
                Ellipse().fill(Color.black.opacity(0.14)).hp(W, H, x: 0.5, y: 0.97, w: 0.9, h: 0.07)
                // legs (back pair, then front)
                Rectangle().fill(Color(hex: 0x4e3019)).hp(W, H, x: 0.2, y: 0.76, w: 0.04, h: 0.3)
                Rectangle().fill(Color(hex: 0x4e3019)).hp(W, H, x: 0.8, y: 0.76, w: 0.04, h: 0.3)
                HPPoly(pts: [(0.09, 0.62), (0.16, 0.62), (0.14, 0.97), (0.1, 0.97)]).fill(wood)
                HPPoly(pts: [(0.84, 0.62), (0.91, 0.62), (0.9, 0.97), (0.86, 0.97)]).fill(wood)
                // table top: surface and front edge
                HPPoly(pts: [(0.12, 0.34), (0.88, 0.34), (0.98, 0.58), (0.02, 0.58)]).fill(Color(hex: 0x9a6a3e))
                Rectangle().fill(wood).hp(W, H, x: 0.5, y: 0.61, w: 0.96, h: 0.06)
                // the map, lying on the table
                HbMedMap()
                    .frame(width: W * 0.8, height: H * 0.34)
                    .rotation3DEffect(.degrees(32), axis: (x: 1, y: 0, z: 0), anchor: .center, perspective: 0.7)
                    .position(x: W * 0.5, y: H * 0.46)
                // a rolled scroll
                Capsule().fill(Fr.parchment).overlay(Capsule().stroke(Fr.stuccoShade, lineWidth: 0.8))
                    .frame(width: W * 0.3, height: H * 0.045).rotationEffect(.degrees(-4)).position(x: W * 0.24, y: H * 0.59)
                Circle().fill(Fr.stuccoShade).frame(width: H * 0.045).position(x: W * 0.385, y: H * 0.58)
            }
        }
    }
}

/// The map itself: Mare Nostrum, with Italy's boot in the middle and Rome marked in red.
struct HbMedMap: View {
    var body: some View {
        HPBox { W, H in
            let land = Color(hex: 0xdcc58e)
            ZStack(alignment: .topLeading) {
                Rectangle().fill(Color(hex: 0x76aec4))
                HPPoly(pts: [(0, 0), (1, 0), (1, 0.24), (0.88, 0.3), (0.82, 0.255), (0.77, 0.27), (0.74, 0.405), (0.7, 0.33),
                             (0.68, 0.27), (0.64, 0.195), (0.58, 0.105), (0.56, 0.135), (0.6, 0.225), (0.65, 0.285), (0.63, 0.323),
                             (0.6, 0.292), (0.585, 0.367), (0.555, 0.352), (0.55, 0.285), (0.48, 0.203), (0.44, 0.143), (0.38, 0.143),
                             (0.32, 0.188), (0.24, 0.203), (0.2, 0.277), (0.16, 0.338), (0.08, 0.367), (0, 0.352)])
                    .fill(land)
                HPPoly(pts: [(0, 0.656), (0.08, 0.624), (0.2, 0.656), (0.4, 0.672), (0.5, 0.632), (0.52, 0.688), (0.58, 0.736),
                             (0.66, 0.808), (0.72, 0.752), (0.82, 0.768), (0.9, 0.784), (0.95, 0.744), (1, 0.64), (1, 1), (0, 1)])
                    .fill(land)
                HPPoly(pts: [(0.545, 0.41), (0.6, 0.39), (0.585, 0.45)]).fill(land)                // Sicily
                Ellipse().fill(land).hp(W, H, x: 0.455, y: 0.26, w: 0.03, h: 0.14)                 // Corsica & Sardinia
                Capsule().fill(land).hp(W, H, x: 0.78, y: 0.53, w: 0.07, h: 0.035)                  // Crete
                Rectangle().stroke(Fr.ink.opacity(0.7), lineWidth: max(0.8, W * 0.012))
                Circle().fill(Fr.frame).hp(W, H, x: 0.5, y: 0.22, w: 0.04, h: 0.1)                // Rome
                // a tiny ship on the sea lane
                HPPoly(pts: [(0.3, 0.5), (0.37, 0.5), (0.355, 0.55), (0.315, 0.55)]).fill(Hb.hullDeep)
                HPPoly(pts: [(0.32, 0.39), (0.35, 0.39), (0.35, 0.49), (0.32, 0.49)]).fill(Color.white)
            }
            .background(Fr.parchment)
        }
    }
}

/// Fishing nets hung to dry between two poles, cork floats along the top, and a basket of the catch.
struct HbNets: View {
    var body: some View {
        HPBox { W, H in
            let net = HPPath { p, P in
                p.move(to: P(0.12, 0.16))
                p.addQuadCurve(to: P(0.88, 0.16), control: P(0.5, 0.34))
                p.addLine(to: P(0.84, 0.66))
                p.addQuadCurve(to: P(0.62, 0.7), control: P(0.74, 0.62))
                p.addQuadCurve(to: P(0.38, 0.72), control: P(0.5, 0.8))
                p.addQuadCurve(to: P(0.16, 0.68), control: P(0.26, 0.64))
                p.closeSubpath()
            }
            ZStack(alignment: .topLeading) {
                // poles
                Rectangle().fill(Fr.trunk).hp(W, H, x: 0.1, y: 0.55, w: 0.04, h: 0.88)
                Rectangle().fill(Fr.trunk).hp(W, H, x: 0.9, y: 0.55, w: 0.04, h: 0.88)
                // the net: a mesh of crossing cords
                net.fill(Hb.rope.opacity(0.18))
                HPPath { p, P in
                    for i in -8..<14 { let x = CGFloat(i) * 0.07; p.move(to: P(x, 0.1)); p.addLine(to: P(x + 0.6, 0.8)) }
                    for i in -8..<20 { let x = CGFloat(i) * 0.07; p.move(to: P(x, 0.1)); p.addLine(to: P(x - 0.6, 0.8)) }
                }
                .stroke(Hb.rope, lineWidth: max(0.6, W * 0.008))
                .mask(net)
                net.stroke(Color(hex: 0x8a6d3f), lineWidth: max(0.8, W * 0.012))
                // cork floats along the head rope, lead sinkers along the foot
                ForEach(0..<6, id: \.self) { i in
                    let u = 0.2 + CGFloat(i) * 0.12
                    let y = 0.16 + 0.18 * 4 * u * (1 - u) * 0.5
                    Ellipse().fill(Fr.ochre).overlay(Ellipse().stroke(Fr.trunk, lineWidth: 0.6))
                        .hp(W, H, x: u, y: y + 0.005, w: 0.07, h: 0.045)
                }
                ForEach(0..<4, id: \.self) { i in
                    Circle().fill(Hb.lead).hp(W, H, x: 0.24 + CGFloat(i) * 0.17, y: 0.7 + (i == 1 || i == 2 ? 0.035 : 0), w: 0.035, h: 0.035)
                }
                // a basket of fish
                HbFishBasket().hp(W, H, x: 0.68, y: 0.85, w: 0.42, h: 0.3)
            }
        }
    }
}

private struct HbFishBasket: View {
    var body: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                // fish heads and tails poking out
                ForEach(0..<3, id: \.self) { i in
                    let x = 0.3 + CGFloat(i) * 0.2
                    Ellipse().fill(LinearGradient(colors: [Color(hex: 0xdfe6ea), Color(hex: 0x8fa4b0)], startPoint: .top, endPoint: .bottom))
                        .frame(width: W * 0.34, height: H * 0.16).rotationEffect(.degrees(Double(i - 1) * -28))
                        .position(x: W * x, y: H * 0.26)
                }
                Circle().fill(Fr.ink).hp(W, H, x: 0.18, y: 0.24, w: 0.03, h: 0.04)
                HPPoly(pts: [(0.86, 0.06), (0.96, 0.0), (0.93, 0.14)]).fill(Color(hex: 0x8fa4b0))
                // basket
                HPPoly(pts: [(0.06, 0.3), (0.94, 0.3), (0.82, 0.98), (0.18, 0.98)])
                    .fill(LinearGradient(colors: [Color(hex: 0xc9a062), Color(hex: 0x9a7038)], startPoint: .top, endPoint: .bottom))
                HPPath { p, P in
                    for i in 1..<4 { let y = 0.3 + CGFloat(i) * 0.17; p.move(to: P(0.06 + 0.12 * (y - 0.3) / 0.68 * 1.0, y)); p.addLine(to: P(0.94 - 0.12 * (y - 0.3) / 0.68, y)) }
                    for i in 1..<7 { let x = 0.06 + CGFloat(i) * 0.126; p.move(to: P(x, 0.3)); p.addLine(to: P(0.18 + (x - 0.06) * 0.64 / 0.88, 0.98)) }
                }
                .stroke(Color(hex: 0x7a5426).opacity(0.7), lineWidth: max(0.5, W * 0.012))
                Capsule().fill(Color(hex: 0xb08850)).hp(W, H, x: 0.5, y: 0.3, w: 0.94, h: 0.08)
            }
        }
    }
}

/// A Roman anchor: an iron shank and curved arms, with the heavy lead stock across the top.
struct HbAnchor: View {
    var body: some View {
        HPBox { W, H in
            let iron = LinearGradient(colors: [Color(hex: 0x77736a), Hb.iron], startPoint: .leading, endPoint: .trailing)
            ZStack(alignment: .topLeading) {
                Ellipse().fill(Color.black.opacity(0.15)).hp(W, H, x: 0.5, y: 0.95, w: 0.8, h: 0.08)
                ZStack(alignment: .topLeading) {
                    // ring
                    Circle().stroke(Hb.iron, lineWidth: max(1, W * 0.04)).hp(W, H, x: 0.5, y: 0.1, w: 0.14, h: 0.14)
                    // shank
                    Rectangle().fill(iron).hp(W, H, x: 0.5, y: 0.5, w: 0.08, h: 0.76)
                    // arms
                    HPPath { p, P in
                        p.move(to: P(0.14, 0.58)); p.addQuadCurve(to: P(0.86, 0.58), control: P(0.5, 1.12))
                    }
                    .stroke(Hb.iron, style: StrokeStyle(lineWidth: max(1, W * 0.075), lineCap: .round))
                    // flukes
                    HPPoly(pts: [(0.06, 0.5), (0.24, 0.6), (0.1, 0.68)]).fill(Hb.iron)
                    HPPoly(pts: [(0.94, 0.5), (0.76, 0.6), (0.9, 0.68)]).fill(Hb.iron)
                    // lead stock
                    RoundedRectangle(cornerRadius: W * 0.02)
                        .fill(LinearGradient(colors: [Color(hex: 0x9a9ea3), Hb.lead], startPoint: .top, endPoint: .bottom))
                        .hp(W, H, x: 0.5, y: 0.24, w: 0.84, h: 0.08)
                    // rope through the ring
                    HPPath { p, P in
                        p.move(to: P(0.5, 0.05)); p.addQuadCurve(to: P(0.2, 0.3), control: P(0.2, 0.0))
                        p.addQuadCurve(to: P(0.3, 0.92), control: P(0.0, 0.7))
                    }
                    .stroke(Hb.rope, style: StrokeStyle(lineWidth: max(1, W * 0.035), lineCap: .round))
                }
                .rotationEffect(.degrees(-8), anchor: .bottom)
            }
        }
    }
}

/// One amphora: a narrow neck, two handles and a pointed toe (for packing upright in sand or a rack).
struct HbAmphora: View {
    var tint = Hb.terracotta
    var body: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                HPPath { p, P in
                    p.move(to: P(0.42, 0.18)); p.addQuadCurve(to: P(0.22, 0.3), control: P(0.18, 0.12))
                    p.move(to: P(0.58, 0.18)); p.addQuadCurve(to: P(0.78, 0.3), control: P(0.82, 0.12))
                }
                .stroke(Hb.terracottaDeep, style: StrokeStyle(lineWidth: max(1, W * 0.07), lineCap: .round))
                HPPath { p, P in
                    p.move(to: P(0.4, 0.04)); p.addLine(to: P(0.6, 0.04))
                    p.addLine(to: P(0.58, 0.24))
                    p.addQuadCurve(to: P(0.82, 0.38), control: P(0.82, 0.26))
                    p.addQuadCurve(to: P(0.54, 0.9), control: P(0.8, 0.7))
                    p.addLine(to: P(0.5, 1)); p.addLine(to: P(0.46, 0.9))
                    p.addQuadCurve(to: P(0.18, 0.38), control: P(0.2, 0.7))
                    p.addQuadCurve(to: P(0.42, 0.24), control: P(0.18, 0.26))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [tint.opacity(0.85), tint, Hb.terracottaDeep], startPoint: .leading, endPoint: .trailing))
                Capsule().fill(Hb.terracottaDeep).hp(W, H, x: 0.5, y: 0.04, w: 0.28, h: 0.05)
                Capsule().fill(Color.white.opacity(0.25)).hp(W, H, x: 0.36, y: 0.48, w: 0.06, h: 0.3)
            }
        }
    }
}

/// Cargo jars: two amphorae in a wooden rack, one lying in front.
struct HbAmphorae: View {
    var body: some View {
        HPBox { W, H in
            ZStack(alignment: .topLeading) {
                Ellipse().fill(Color.black.opacity(0.14)).hp(W, H, x: 0.5, y: 0.95, w: 0.95, h: 0.09)
                // rack posts
                Rectangle().fill(Fr.trunk).hp(W, H, x: 0.1, y: 0.6, w: 0.05, h: 0.72)
                Rectangle().fill(Fr.trunk).hp(W, H, x: 0.9, y: 0.6, w: 0.05, h: 0.72)
                HbAmphora().hp(W, H, x: 0.32, y: 0.47, w: 0.4, h: 0.74)
                HbAmphora(tint: Color(hex: 0xcf7c4a)).hp(W, H, x: 0.66, y: 0.43, w: 0.4, h: 0.74)
                // rack rail in front of them
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0x8a5a34), Fr.trunk], startPoint: .top, endPoint: .bottom))
                    .hp(W, H, x: 0.5, y: 0.5, w: 0.9, h: 0.05)
                // one lying on its side
                HbAmphora(tint: Color(hex: 0xb85f36)).frame(width: W * 0.26, height: W * 0.6)
                    .rotationEffect(.degrees(-80)).position(x: W * 0.5, y: H * 0.85)
            }
        }
    }
}
