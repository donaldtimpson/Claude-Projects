import SwiftUI

// MARK: - Wing: the Music Room (see VillaEstate.swift)
//
// A little odeum: black Third-Style panels with gold candelabra on a red wall, a marble stage
// (pulpitum) with its row of niches along the back, and a cream mosaic floor with a black wave band
// and a laurel roundel for Apollo. The household band's instruments hang on the wall or stand about,
// and tapping one plays a short note on the Theatre's synth (silent when the sound switch is off).
// Drawings use the unit-square kit in WingCountingArt.swift.

let odeumItems: [VillaItem] = [
    .init(id: "ode_cymbals", name: "Cymbals", category: .garden, price: .denarii(45), blurb: "Little bronze cymbals clashed in parades.", place: "odeum"),
    .init(id: "ode_pipes", name: "Pan Pipes", category: .garden, price: .denarii(50), blurb: "Reeds of different lengths: short ones sing high.", place: "odeum"),
    .init(id: "ode_drum", name: "Tympanum", category: .garden, price: .denarii(60), blurb: "A Roman hand drum, beaten with the palm.", place: "odeum"),
    .init(id: "ode_aulos", name: "Aulos", category: .garden, price: .denarii(75), blurb: "Two pipes played at once, one in each hand.", place: "odeum"),
    .init(id: "ode_lyre", name: "Lyre", category: .garden, price: .denarii(90), blurb: "Strings over a tortoise-shell sound box.", place: "odeum"),
    .init(id: "ode_masks", name: "Theatre Masks", category: .garden, price: .denarii(105), blurb: "Actors wore masks: smiling for comedy, sad for tragedy.", place: "odeum"),
    .init(id: "ode_cornu", name: "Cornu", category: .garden, price: .denarii(135), blurb: "A great G-shaped bronze horn that signalled the legions.", place: "odeum"),
    .init(id: "ode_organ", name: "Water Organ", category: .garden, price: .denarii(300), blurb: "The hydraulis: water pressure pushed air through its pipes.", place: "odeum"),
]

/// Where each thing stands (feet at canvas fractions; wall pieces hang with their feet on the wall).
private let odeumSpots: [String: (x: CGFloat, y: CGFloat, size: CGFloat)] = [
    "ode_masks": (0.18, 0.46, 0.21),
    "ode_pipes": (0.70, 0.45, 0.15),
    "ode_cornu": (0.905, 0.47, 0.25),
    "ode_organ": (0.44, 0.665, 0.42),
    "ode_aulos": (0.24, 0.83, 0.22),
    "ode_lyre": (0.75, 0.86, 0.23),
    "ode_drum": (0.13, 0.975, 0.19),
    "ode_cymbals": (0.89, 0.975, 0.16),
]

private let odeumThumbBox: [String: CGRect] = [
    "ode_cymbals": CGRect(x: 0.04, y: 0.34, width: 0.92, height: 0.64),
    "ode_pipes": CGRect(x: 0.12, y: 0.0, width: 0.76, height: 1.0),
    "ode_drum": CGRect(x: 0.0, y: 0.08, width: 1.0, height: 0.92),
    "ode_aulos": CGRect(x: 0.04, y: 0.36, width: 0.94, height: 0.64),
    "ode_lyre": CGRect(x: 0.1, y: 0.08, width: 0.8, height: 0.92),
    "ode_masks": CGRect(x: 0.15, y: 0.0, width: 0.7, height: 0.96),
    "ode_cornu": CGRect(x: 0.1, y: 0.0, width: 0.88, height: 0.92),
    "ode_organ": CGRect(x: 0.02, y: 0.06, width: 0.96, height: 0.94),
]

struct OdeumRoom: View {
    let s: WingState
    @State private var synthOn = false
    var body: some View {
        WingRoom(panel: Color(hex: 0x241b18), floor: Color(hex: 0xe4d3ae)) { w, h, t in
            ZStack(alignment: .topLeading) {
                OdeumCandelabra(skip: candelabraHidden).fill(Fr.gold.opacity(0.85)).frame(width: w, height: h)
                OdeumStage(w: w, h: h).frame(width: w, height: h, alignment: .topLeading)
                OdeumWaveBand().fill(Color(hex: 0x2f2622)).frame(width: w, height: h)
                LaurelRoundel().frame(width: w * 0.3, height: w * 0.3).position(x: w * 0.5, y: h * 0.885)
                ForEach(odeumItems.filter { s.has($0.id) }.sorted { (odeumSpots[$0.id]?.y ?? 0) < (odeumSpots[$1.id]?.y ?? 0) }) { item in
                    if let p = odeumSpots[item.id] {
                        WingSpot(x: p.x, y: p.y, size: p.size, w: w, h: h, lift: s.lift(item.id)) {
                            OdeumArt(id: item.id, t: t, playing: s.lift(item.id) > 1)
                        }
                        .onTapGesture { s.onTap(item.id); sound(item.id) }
                    }
                }
            }
        }
        .onDisappear { if synthOn { ToneSynth.shared.stop(); synthOn = false } }
    }

    /// Panels (by index in OdeumCandelabra) whose painted candelabrum an instrument now covers.
    private var candelabraHidden: Set<Int> {
        var h: Set<Int> = []
        if s.has("ode_masks") { h.insert(1) }
        if s.has("ode_organ") { h.insert(2) }
        if s.has("ode_pipes") { h.insert(3) }
        if s.has("ode_cornu") { h.insert(4) }
        return h
    }

    /// A short phrase on the Theatre's synth for each instrument (nothing when the sound is off).
    private func sound(_ id: String) {
        guard !Sfx.muted else { return }
        let ts = ToneSynth.shared
        if !synthOn { ts.start(); synthOn = true }
        func run(_ notes: [Int], gap: Double, vel: Float = 0.55, dur: Double = 0.4, voice: ToneVoice = .piano) -> [ToneEvent] {
            notes.enumerated().map { ToneEvent(at: Double($0.offset) * gap, midi: $0.element, vel: vel, dur: dur, voice: voice) }
        }
        switch id {
        case "ode_lyre": ts.chord([55, 60, 64, 67, 72], vel: 0.5, dur: 1.4, roll: 0.05)
        case "ode_pipes": ts.play(run([74, 76, 79, 81, 84], gap: 0.09, vel: 0.45, dur: 0.3, voice: .chime))
        case "ode_drum": ts.play(run([45, 45, 50], gap: 0.18, vel: 0.8, dur: 0.25, voice: .tom))
        case "ode_cymbals": ts.play([ToneEvent(midi: 96, vel: 0.45, dur: 0.7, voice: .chime), ToneEvent(midi: 101, vel: 0.35, dur: 0.7, voice: .chime)])
        case "ode_aulos": ts.play(run([69, 71, 72, 71, 69], gap: 0.14, vel: 0.45, dur: 0.18) + [ToneEvent(midi: 57, vel: 0.35, dur: 0.75)])
        case "ode_cornu": ts.play(run([43, 50, 55], gap: 0.2, vel: 0.65, dur: 0.35))
        case "ode_organ": ts.chord([48, 55, 60, 64, 67], vel: 0.5, dur: 1.8)
        default: break        // the masks are quiet
        }
    }
}

struct OdeumThumb: View {
    let id: String
    var body: some View {
        COThumb(box: odeumThumbBox[id] ?? CGRect(x: 0, y: 0, width: 1, height: 1)) {
            OdeumArt(id: id, t: 0, playing: false)
        }
    }
}

private struct OdeumArt: View {
    let id: String
    let t: Double
    let playing: Bool
    var body: some View {
        switch id {
        case "ode_cymbals": Cymbals(t: t, playing: playing)
        case "ode_pipes": PanPipes()
        case "ode_drum": Tympanum(t: t, playing: playing)
        case "ode_aulos": AulosTable()
        case "ode_lyre": Lyre(t: t, playing: playing)
        case "ode_masks": TheatreMasks()
        case "ode_cornu": Cornu()
        case "ode_organ": WaterOrgan(t: t)
        default: EmptyView()
        }
    }
}

// MARK: - The room itself

/// A slender gold candelabrum painted down the middle of each black panel.
private struct OdeumCandelabra: Shape {
    var skip: Set<Int> = []         // panels with an instrument hung in front of them
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        let top = h * 0.62 * 0.2, bottom = h * 0.62 * 0.68
        let lw = max(1, w * 0.0045)
        for (i, f) in ([-0.08, 0.18, 0.44, 0.70, 0.96, 1.22] as [CGFloat]).enumerated() {
            let x = w * f
            // garland swags between the panels
            let gx = x + w * 0.13
            p.move(to: CGPoint(x: gx - w * 0.1, y: top - w * 0.02))
            p.addQuadCurve(to: CGPoint(x: gx + w * 0.1, y: top - w * 0.02), control: CGPoint(x: gx, y: top + w * 0.05))
            p.addQuadCurve(to: CGPoint(x: gx - w * 0.1, y: top - w * 0.02), control: CGPoint(x: gx, y: top + w * 0.035))
            if skip.contains(i) { continue }
            p.addRect(CGRect(x: x - lw / 2, y: top, width: lw, height: bottom - top))
            for k in [0.3, 0.55, 0.78] as [CGFloat] {
                let y = top + (bottom - top) * k
                p.addEllipse(in: CGRect(x: x - w * 0.018, y: y - w * 0.004, width: w * 0.036, height: w * 0.008))
            }
            // a little bowl and flame on top, a tripod foot below
            p.move(to: CGPoint(x: x - w * 0.026, y: top))
            p.addQuadCurve(to: CGPoint(x: x + w * 0.026, y: top), control: CGPoint(x: x, y: top + w * 0.03))
            p.closeSubpath()
            p.move(to: CGPoint(x: x, y: top - w * 0.035))
            p.addQuadCurve(to: CGPoint(x: x, y: top - w * 0.002), control: CGPoint(x: x + w * 0.016, y: top - w * 0.01))
            p.addQuadCurve(to: CGPoint(x: x, y: top - w * 0.035), control: CGPoint(x: x - w * 0.016, y: top - w * 0.01))
            p.move(to: CGPoint(x: x - w * 0.03, y: bottom)); p.addLine(to: CGPoint(x: x, y: bottom - w * 0.03))
            p.addLine(to: CGPoint(x: x + w * 0.03, y: bottom)); p.addLine(to: CGPoint(x: x + w * 0.02, y: bottom))
            p.addLine(to: CGPoint(x: x, y: bottom - w * 0.015)); p.addLine(to: CGPoint(x: x - w * 0.02, y: bottom)); p.closeSubpath()
        }
        return p
    }
}

/// The marble stage front along the back wall, with its row of round and square niches.
private struct OdeumStage: View {
    let w: CGFloat, h: CGFloat
    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(LinearGradient(colors: [Fr.marble, Color(hex: 0xe2d8c2)], startPoint: .top, endPoint: .bottom))
                .frame(width: w * 3, height: h * 0.06).offset(x: -w, y: h * 0.62)
            Rectangle().fill(Fr.marbleShade).frame(width: w * 3, height: max(1, h * 0.006)).offset(x: -w, y: h * 0.62 + h * 0.008)
            Rectangle().fill(Color.black.opacity(0.18)).frame(width: w * 3, height: max(1, h * 0.004)).offset(x: -w, y: h * 0.68)
            StageNiches().fill(Color(hex: 0xc4b89e)).frame(width: w, height: h)
        }
    }
}

private struct StageNiches: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        let top = h * 0.638, bottom = h * 0.672, nw = w * 0.032
        var i = 0
        var x = -w + w * 0.02
        while x < 2 * w {
            if i % 2 == 0 {
                p.move(to: CGPoint(x: x, y: bottom))
                p.addLine(to: CGPoint(x: x, y: top + nw / 2))
                p.addArc(center: CGPoint(x: x + nw / 2, y: top + nw / 2), radius: nw / 2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                p.addLine(to: CGPoint(x: x + nw, y: bottom)); p.closeSubpath()
            } else {
                p.addRect(CGRect(x: x, y: top + h * 0.004, width: nw * 1.4, height: bottom - top - h * 0.004))
            }
            x += w * 0.075
            i += 1
        }
        return p
    }
}

/// A black running-wave band in the mosaic floor.
private struct OdeumWaveBand: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        let y0 = h * 0.716, amp = h * 0.0075, period = w * 0.06
        p.move(to: CGPoint(x: -w, y: y0 + amp * 2.4))
        var x = -w
        while x <= 2 * w {
            let ph = (x / period) * .pi * 2
            p.addLine(to: CGPoint(x: x, y: y0 + amp * CGFloat(sin(ph)) + amp * 0.6 * CGFloat(sin(ph * 2 + 0.6))))
            x += period / 14
        }
        p.addLine(to: CGPoint(x: 2 * w, y: y0 + amp * 2.4))
        p.closeSubpath()
        p.addRect(CGRect(x: -w, y: y0 - amp * 2.6, width: w * 3, height: max(1, h * 0.004)))
        p.addRect(CGRect(x: -w, y: y0 + amp * 3.4, width: w * 3, height: max(1, h * 0.004)))
        return p
    }
}

/// A laurel wreath for Apollo, set into the floor.
private struct LaurelRoundel: View {
    var body: some View {
        ZStack {
            COPath { p in p.coRing(0.5, 0.5, 0.48, 0.13, 0.02) }.fill(Color(hex: 0x2f2622))
            COPath { p in p.coRing(0.5, 0.5, 0.42, 0.105, 0.008) }.fill(Fr.frame)
            COPath { p in
                for i in 0..<22 {
                    let a = Double(i) / 22 * .pi * 2
                    let c = CGPoint(x: 0.5 + 0.33 * CGFloat(cos(a)), y: 0.5 + 0.08 * CGFloat(sin(a)))
                    var leaf = Path(ellipseIn: CGRect(x: -0.035, y: -0.011, width: 0.07, height: 0.022))
                    leaf = leaf.applying(CGAffineTransform(rotationAngle: CGFloat(a + .pi / 2 + 0.5)).scaledBy(x: 1, y: 1))
                    p.addPath(leaf.applying(CGAffineTransform(a: 1, b: 0, c: 0, d: 0.45, tx: c.x, ty: c.y)))
                }
            }
            .fill(Fr.leaf)
            COPath { p in p.coDot(0.5, 0.5, 0.035, 0.012) }.fill(Fr.frame)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - The instruments

private struct Cymbals: View {
    let t: Double
    let playing: Bool
    var body: some View {
        let glint = playing ? 1 : pow(max(0, sin(t * 0.8)), 14)
        ZStack {
            COPath { $0.coOval(0.04, 0.89, 0.92, 0.09) }.fill(COC.shadow)
            // one lying flat …
            COPath { $0.coOval(0.05, 0.8, 0.52, 0.14) }.fill(COC.bronzeFill(.top, .bottom))
            COPath { p in p.coRing(0.31, 0.87, 0.2, 0.05, 0.008) }.fill(COC.bronzeDk.opacity(0.5))
            COPath { $0.coOval(0.24, 0.83, 0.14, 0.055) }.fill(COC.bronzeDk)
            // … one leaning up against it
            COPath { $0.coOval(0.38, 0.34, 0.54, 0.56) }.fill(COC.bronzeFill())
            COPath { p in p.coRing(0.65, 0.62, 0.19, 0.195, 0.01); p.coRing(0.65, 0.62, 0.25, 0.26, 0.006) }.fill(COC.bronzeDk.opacity(0.45))
            COPath { $0.coDot(0.65, 0.62, 0.075) }.fill(COC.bronzeFill(.bottomTrailing, .topLeading))
            COPath { $0.coDot(0.63, 0.6, 0.025) }.fill(Color.white.opacity(0.5))
            COPath { p in p.coQuad(coPt(0.31, 0.855), coPt(0.4, 0.6), coPt(0.6, 0.6), 0.022) }.fill(COC.red)
            COGlint().fill(Color.white.opacity(0.95))
                .frame(width: 26, height: 26).scaleEffect(0.2 + 0.8 * glint).opacity(glint)
                .modifier(UnitPlace(x: 0.52, y: 0.47))
        }
    }
}

/// Centres a small fixed-size view at a unit-square point of the bottom-centred square.
private struct UnitPlace: ViewModifier {
    let x: CGFloat, y: CGFloat
    func body(content: Content) -> some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            content
                .scaleEffect(s / 100)
                .position(x: (g.size.width - s) / 2 + x * s, y: g.size.height - s + y * s)
        }
    }
}

private struct PanPipes: View {
    private static let n = 7
    private static func x(_ i: Int) -> CGFloat { 0.2 + CGFloat(i) * 0.088 }
    private static func bottom(_ i: Int) -> CGFloat { 0.97 - CGFloat(i) * 0.055 }
    var body: some View {
        ZStack {
            COPath { p in      // peg and hanging cord
                p.coLine([coPt(0.24, 0.36), coPt(0.5, 0.05), coPt(0.76, 0.36)], 0.014)
            }
            .fill(COC.red)
            COPath { $0.coDot(0.5, 0.05, 0.035) }.fill(COC.woodDk)
            COPath { p in for i in 0..<Self.n { p.coBox(Self.x(i), 0.34, 0.08, Self.bottom(i) - 0.34, r: 0.02) } }
                .fill(LinearGradient(colors: [Color(hex: 0xead08a), COC.cane, COC.caneDk], startPoint: .leading, endPoint: .trailing))
            COPath { p in for i in 0..<Self.n { p.coBox(Self.x(i) + 0.055, 0.35, 0.02, Self.bottom(i) - 0.36, r: 0.01) } }
                .fill(Color.black.opacity(0.13))
            COPath { p in
                for i in 0..<Self.n {
                    p.coDot(Self.x(i) + 0.04, 0.35, 0.026, 0.012)
                    let node = 0.34 + (Self.bottom(i) - 0.34) * 0.72
                    p.coLine([coPt(Self.x(i) + 0.005, node), coPt(Self.x(i) + 0.075, node)], 0.008)
                }
            }
            .fill(Color(hex: 0x6e5222))
            // two wrapped cords binding the reeds
            COPath { p in p.coBox(0.18, 0.42, 0.64, 0.035, r: 0.01); p.coBox(0.18, 0.53, 0.6, 0.035, r: 0.01) }.fill(COC.red)
            COPath { p in
                for i in 0..<14 { let x = 0.19 + CGFloat(i) * 0.045; p.coLine([coPt(x, 0.422), coPt(x + 0.02, 0.453)], 0.006) }
                for i in 0..<13 { let x = 0.19 + CGFloat(i) * 0.045; p.coLine([coPt(x, 0.532), coPt(x + 0.02, 0.563)], 0.006) }
            }
            .fill(Color(hex: 0x7a1d17))
        }
    }
}

private struct Tympanum: View {
    let t: Double
    let playing: Bool
    var body: some View {
        let wob = playing ? 3 * sin(t * 40) : 0
        ZStack {
            COPath { $0.coOval(0.08, 0.91, 0.84, 0.08) }.fill(COC.shadow)
            ZStack {
                COPath { p in      // ribbons tied at the rim
                    p.coCurve(coPt(0.14, 0.58), coPt(0.0, 0.66), coPt(0.12, 0.8), coPt(0.02, 0.94), 0.03)
                }
                .fill(COC.blue)
                COPath { p in p.coCurve(coPt(0.16, 0.62), coPt(0.06, 0.74), coPt(0.18, 0.84), coPt(0.1, 0.96), 0.03) }.fill(COC.red)
                COPath { $0.coOval(0.1, 0.1, 0.8, 0.84) }
                    .fill(LinearGradient(colors: [Color(hex: 0xc23a2c), Color(hex: 0x7d1c16)], startPoint: .top, endPoint: .bottom))
                COPath { p in
                    let pts = (0...36).map { i -> CGPoint in
                        let a = Double(i) / 36 * .pi * 2
                        let r: CGFloat = i % 2 == 0 ? 1 : 0.91
                        return coPt(0.5 + 0.37 * r * CGFloat(cos(a)), 0.52 + 0.39 * r * CGFloat(sin(a)))
                    }
                    p.coLine(pts, 0.012)
                }
                .fill(Fr.gold)
                COPath { $0.coOval(0.18, 0.19, 0.64, 0.66) }
                    .fill(LinearGradient(colors: [Color(hex: 0xf8ecd0), Color(hex: 0xd8bf8e)], startPoint: .topLeading, endPoint: .bottomTrailing))
                COPath { p in
                    for i in 0..<8 {
                        let a = Double(i) / 8 * .pi * 2
                        var leaf = Path(ellipseIn: CGRect(x: 0.03, y: -0.026, width: 0.12, height: 0.052))
                        leaf = leaf.applying(CGAffineTransform(rotationAngle: CGFloat(a)))
                        p.addPath(leaf.applying(CGAffineTransform(translationX: 0.5, y: 0.52)))
                    }
                    p.coRing(0.5, 0.52, 0.22, 0.225, 0.01)
                }
                .fill(Fr.frame.opacity(0.8))
                COPath { $0.coDot(0.5, 0.52, 0.035) }.fill(Fr.gold)
                if playing {
                    let k = CGFloat((t * 3).truncatingRemainder(dividingBy: 1))
                    COPath { p in p.coRing(0.5, 0.52, 0.06 + 0.24 * k, 0.06 + 0.25 * k, 0.012) }.fill(Fr.ink.opacity(Double(0.5 * (1 - k))))
                }
            }
            .rotationEffect(.degrees(wob), anchor: .bottom)
        }
    }
}

private struct AulosTable: View {
    var body: some View {
        ZStack {
            COPath { $0.coOval(0.1, 0.93, 0.8, 0.07) }.fill(COC.shadow)
            // a bronze tripod table with lion's-paw feet
            COPath { p in
                p.coQuad(coPt(0.28, 0.6), coPt(0.16, 0.76), coPt(0.19, 0.975), 0.032)
                p.coQuad(coPt(0.72, 0.6), coPt(0.84, 0.76), coPt(0.81, 0.975), 0.032)
                p.coLine([coPt(0.5, 0.62), coPt(0.5, 0.955)], 0.03)
                p.coDot(0.19, 0.975, 0.04, 0.022); p.coDot(0.81, 0.975, 0.04, 0.022); p.coDot(0.5, 0.955, 0.036, 0.02)
                p.coQuad(coPt(0.22, 0.82), coPt(0.5, 0.86), coPt(0.78, 0.82), 0.014)
            }
            .fill(COC.bronzeFill(.leading, .trailing))
            COPath { $0.coOval(0.1, 0.56, 0.8, 0.09) }.fill(COC.bronzeDk)
            COPath { $0.coOval(0.1, 0.535, 0.8, 0.09) }.fill(COC.bronzeFill(.top, .bottom))
            // the pair of pipes, mouthpieces together, bells apart
            AulosPipe(a: coPt(0.1, 0.52), b: coPt(0.86, 0.45))
            AulosPipe(a: coPt(0.1, 0.545), b: coPt(0.9, 0.6))
        }
    }
}

private struct AulosPipe: View {
    let a: CGPoint, b: CGPoint
    private func at(_ f: CGFloat) -> CGPoint { coPt(a.x + (b.x - a.x) * f, a.y + (b.y - a.y) * f) }
    var body: some View {
        let dx = b.x - a.x, dy = b.y - a.y
        let len = sqrt(dx * dx + dy * dy)
        let nx = -dy / len, ny = dx / len
        ZStack {
            COPath { p in p.coLine([a, b], 0.034, cap: .round) }
                .fill(LinearGradient(colors: [COC.ivory, Color(hex: 0xcdb98c)], startPoint: .top, endPoint: .bottom))
            COPath { p in      // flared bell
                let w0: CGFloat = 0.018, w1: CGFloat = 0.05
                let e = coPt(b.x + dx / len * 0.06, b.y + dy / len * 0.06)
                p.coPoly([coPt(b.x + nx * w0, b.y + ny * w0), coPt(e.x + nx * w1, e.y + ny * w1),
                          coPt(e.x - nx * w1, e.y - ny * w1), coPt(b.x - nx * w0, b.y - ny * w0)])
            }
            .fill(COC.bronzeFill())
            COPath { p in
                for f in [0.12, 0.45, 0.78] as [CGFloat] {
                    let c = at(f)
                    p.coLine([coPt(c.x + nx * 0.02, c.y + ny * 0.02), coPt(c.x - nx * 0.02, c.y - ny * 0.02)], 0.016, cap: .butt)
                }
                p.coDot(a.x - dx / len * 0.02, a.y - dy / len * 0.02, 0.026, 0.024)    // the bulb at the mouthpiece
            }
            .fill(COC.bronze)
            COPath { p in for f in [0.53, 0.6, 0.67, 0.86] as [CGFloat] { let c = at(f); p.coDot(c.x, c.y, 0.009) } }
                .fill(Color(hex: 0x3a2a1a))
        }
    }
}

private struct Lyre: View {
    let t: Double
    let playing: Bool
    var body: some View {
        ZStack {
            COPath { $0.coOval(0.2, 0.94, 0.6, 0.06) }.fill(COC.shadow)
            COPath { $0.coBox(0.32, 0.925, 0.36, 0.05, r: 0.012) }.fill(COC.woodDk)
            // the two arms
            COPath { p in
                p.coCurve(coPt(0.38, 0.72), coPt(0.18, 0.6), coPt(0.1, 0.3), coPt(0.25, 0.1), 0.055)
                p.coCurve(coPt(0.62, 0.72), coPt(0.82, 0.6), coPt(0.9, 0.3), coPt(0.75, 0.1), 0.055)
            }
            .fill(LinearGradient(colors: [Color(hex: 0x8a5a30), Color(hex: 0x5a3519)], startPoint: .leading, endPoint: .trailing))
            COPath { p in
                p.coCurve(coPt(0.36, 0.7), coPt(0.19, 0.6), coPt(0.12, 0.32), coPt(0.24, 0.12), 0.012)
                p.coCurve(coPt(0.64, 0.7), coPt(0.81, 0.6), coPt(0.88, 0.32), coPt(0.76, 0.12), 0.012)
            }
            .fill(Color(hex: 0xc08b55).opacity(0.7))
            // yoke with tuning pegs
            COPath { p in p.coLine([coPt(0.19, 0.17), coPt(0.81, 0.17)], 0.045) }.fill(COC.wood)
            COPath { p in
                p.coDot(0.19, 0.17, 0.032); p.coDot(0.81, 0.17, 0.032)
            }
            .fill(COC.bronzeFill())
            COPath { p in for i in 0..<7 { p.coDot(0.32 + CGFloat(i) * 0.06, 0.17, 0.012, 0.02) } }.fill(COC.woodDk)
            // the tortoise-shell sound box
            COPath { $0.coOval(0.23, 0.6, 0.54, 0.36) }
                .fill(LinearGradient(colors: [Color(hex: 0xa8743d), Color(hex: 0x5e3b1e)], startPoint: .topLeading, endPoint: .bottomTrailing))
            COPath { p in
                let c = coPt(0.5, 0.775)
                let hex = (0..<6).map { i -> CGPoint in
                    let a = Double(i) / 6 * .pi * 2 + .pi / 6
                    return coPt(c.x + 0.085 * CGFloat(cos(a)), c.y + 0.065 * CGFloat(sin(a)))
                }
                p.coLine(hex + [hex[0]], 0.01)
                for (i, q) in hex.enumerated() {
                    let a = Double(i) / 6 * .pi * 2 + .pi / 6
                    p.coLine([q, coPt(c.x + 0.26 * CGFloat(cos(a)), c.y + 0.17 * CGFloat(sin(a)))], 0.01)
                }
                p.coRing(0.5, 0.78, 0.27, 0.18, 0.014)
            }
            .fill(Color(hex: 0x3b2413))
            COPath { $0.coOval(0.3, 0.63, 0.16, 0.06) }.fill(Color.white.opacity(0.14))
            COPath { p in p.coBox(0.4, 0.82, 0.2, 0.026, r: 0.006); p.coBox(0.45, 0.9, 0.1, 0.03, r: 0.008) }.fill(COC.ivory)
            // strings (they shiver when played)
            COPath { p in
                for i in 0..<7 {
                    let top = coPt(0.32 + CGFloat(i) * 0.06, 0.18), bot = coPt(0.42 + CGFloat(i) * 0.0267, 0.905)
                    let amp: CGFloat = playing ? 0.012 * CGFloat(sin(t * 70 + Double(i) * 1.3)) : 0
                    p.coQuad(top, coPt((top.x + bot.x) / 2 + amp, (top.y + bot.y) / 2), bot, 0.008)
                }
            }
            .fill(Color(hex: 0xfaf0d4))
            // a red ribbon tied to one arm
            COPath { p in
                p.coCurve(coPt(0.18, 0.4), coPt(0.1, 0.48), coPt(0.18, 0.56), coPt(0.12, 0.64), 0.022)
                p.coCurve(coPt(0.19, 0.41), coPt(0.24, 0.5), coPt(0.17, 0.56), coPt(0.22, 0.62), 0.022)
            }
            .fill(COC.red)
        }
    }
}

private struct TheatreMasks: View {
    var body: some View {
        let hole = Color(hex: 0x2a1d16)
        ZStack {
            COPath { p in p.coLine([coPt(0.36, 0.3), coPt(0.5, 0.05), coPt(0.66, 0.24)], 0.014) }.fill(COC.red)
            COPath { $0.coDot(0.5, 0.05, 0.035) }.fill(COC.woodDk)
            // tragedy: tall hair, pale face, sad brows, a downturned open mouth
            COPath { $0.coOval(0.5, 0.18, 0.3, 0.28) }.fill(Color(hex: 0x4f3322))
            COPath { $0.coOval(0.47, 0.3, 0.36, 0.62) }
                .fill(LinearGradient(colors: [Color(hex: 0xefe9dc), Color(hex: 0xc9c0ad)], startPoint: .leading, endPoint: .trailing))
            COPath { p in
                p.coDot(0.585, 0.56, 0.032, 0.02); p.coDot(0.715, 0.56, 0.032, 0.02)
                p.move(to: coPt(0.58, 0.82)); p.addQuadCurve(to: coPt(0.72, 0.82), control: coPt(0.65, 0.68))
                p.addQuadCurve(to: coPt(0.58, 0.82), control: coPt(0.65, 0.77))
            }
            .fill(hole)
            COPath { p in
                p.coLine([coPt(0.545, 0.53), coPt(0.625, 0.49)], 0.016)
                p.coLine([coPt(0.675, 0.49), coPt(0.755, 0.53)], 0.016)
                p.coLine([coPt(0.65, 0.58), coPt(0.64, 0.66), coPt(0.66, 0.67)], 0.01)
            }
            .fill(Color(hex: 0x7a6a58))
            // comedy: curly hair, golden face, raised brows and a wide grin
            COPath { $0.coOval(0.17, 0.3, 0.38, 0.56) }
                .fill(LinearGradient(colors: [Color(hex: 0xf6d791), Color(hex: 0xd9a74e)], startPoint: .topLeading, endPoint: .bottomTrailing))
            COPath { p in for i in 0..<6 { p.coDot(0.2 + CGFloat(i) * 0.064, 0.34 + (i == 0 || i == 5 ? 0.04 : 0), 0.04) } }
                .fill(Color(hex: 0x7a4a24))
            COPath { p in p.coDot(0.24, 0.66, 0.035, 0.025); p.coDot(0.48, 0.66, 0.035, 0.025) }.fill(Color(hex: 0xe0806a).opacity(0.55))
            COPath { p in
                p.coDot(0.295, 0.53, 0.032, 0.022); p.coDot(0.425, 0.53, 0.032, 0.022)
                p.move(to: coPt(0.25, 0.68)); p.addQuadCurve(to: coPt(0.47, 0.68), control: coPt(0.36, 0.88))
                p.addQuadCurve(to: coPt(0.25, 0.68), control: coPt(0.36, 0.73))
            }
            .fill(hole)
            COPath { p in
                p.coQuad(coPt(0.255, 0.49), coPt(0.295, 0.445), coPt(0.335, 0.48), 0.014)
                p.coQuad(coPt(0.385, 0.48), coPt(0.425, 0.445), coPt(0.465, 0.49), 0.014)
                p.coLine([coPt(0.36, 0.56), coPt(0.35, 0.63), coPt(0.37, 0.64)], 0.01)
            }
            .fill(Color(hex: 0x8a5a2a))
        }
    }
}

private struct Cornu: View {
    private static let c = coPt(0.5, 0.54), r: CGFloat = 0.33
    private static func on(_ deg: Double, _ rr: CGFloat = r) -> CGPoint {
        coPt(c.x + rr * CGFloat(cos(deg * .pi / 180)), c.y + rr * CGFloat(sin(deg * .pi / 180)))
    }
    var body: some View {
        let top = Self.on(270)
        ZStack {
            COPath { p in p.coLine([Self.on(225), coPt(0.42, 0.03), coPt(0.52, 0.2)], 0.012) }.fill(COC.red)
            COPath { $0.coDot(0.42, 0.03, 0.03) }.fill(COC.woodDk)
            // the crossbar the player rests on his shoulder
            COPath { p in p.coLine([Self.on(155, 0.36), Self.on(335, 0.36)], 0.04) }.fill(COC.wood)
            COPath { p in p.coDot(Self.on(155, 0.36).x, Self.on(155, 0.36).y, 0.028); p.coDot(Self.on(335, 0.36).x, Self.on(335, 0.36).y, 0.028) }
                .fill(COC.bronzeDk)
            // the great round tube, then out to the bell
            COPath { p in
                p.coRing(Self.c.x, Self.c.y, Self.r, Self.r, 0.062)
                p.coBox(0.5, top.y - 0.031, 0.24, 0.062)
            }
            .fill(COC.bronzeFill())
            COPath { p in
                let arc = stride(from: 150.0, through: 250.0, by: 5).map { Self.on($0, Self.r - 0.012) }
                p.coLine(arc, 0.014)
                p.coLine([coPt(0.52, top.y - 0.014), coPt(0.72, top.y - 0.014)], 0.012)
            }
            .fill(COC.bronzeLt.opacity(0.85))
            COPath { p in
                p.coPoly([coPt(0.72, top.y - 0.032), coPt(0.94, top.y - 0.115), coPt(0.94, top.y + 0.115), coPt(0.72, top.y + 0.032)])
            }
            .fill(COC.bronzeFill(.top, .bottom))
            COPath { p in p.coOval(0.915, top.y - 0.12, 0.05, 0.24) }.fill(COC.bronzeDk)
            COPath { p in p.coOval(0.925, top.y - 0.1, 0.03, 0.2) }.fill(Color(hex: 0x4a3015))
            // mouthpiece at the start of the tube
            COPath { p in
                let s = Self.on(325)
                p.coLine([s, coPt(s.x - 0.07, s.y + 0.03)], 0.026)
                p.coDot(s.x - 0.075, s.y + 0.032, 0.026, 0.02)
            }
            .fill(COC.bronzeDk)
        }
    }
}

private struct WaterOrgan: View {
    let t: Double
    var body: some View {
        ZStack {
            WaterOrganBody()
            // a glint on the water in the cistern's window
            COPath { p in
                let k = CGFloat((t * 0.35).truncatingRemainder(dividingBy: 1))
                p.coDot(0.44 + 0.12 * k, 0.775, 0.018, 0.006)
            }
            .fill(Color.white.opacity(0.7))
        }
    }
}

private struct WaterOrganBody: View {
    private static let pipes = 13
    private static func px(_ i: Int) -> CGFloat { 0.215 + CGFloat(i) * 0.0465 }
    private static func ptop(_ i: Int) -> CGFloat { 0.05 + CGFloat(i) * 0.022 }
    var body: some View {
        ZStack {
            COPath { $0.coOval(0.04, 0.94, 0.92, 0.06) }.fill(COC.shadow)
            // two pump cylinders with their rocking levers
            COPath { p in
                p.coBox(0.1, 0.68, 0.1, 0.29, r: 0.01); p.coBox(0.8, 0.68, 0.1, 0.29, r: 0.01)
            }
            .fill(COC.bronzeFill(.leading, .trailing))
            COPath { p in
                p.coBox(0.085, 0.66, 0.13, 0.03, r: 0.008); p.coBox(0.785, 0.66, 0.13, 0.03, r: 0.008)
                p.coBox(0.085, 0.95, 0.13, 0.03, r: 0.008); p.coBox(0.785, 0.95, 0.13, 0.03, r: 0.008)
                p.coLine([coPt(0.15, 0.66), coPt(0.15, 0.6)], 0.016); p.coLine([coPt(0.85, 0.66), coPt(0.85, 0.6)], 0.016)
            }
            .fill(COC.bronzeDk)
            COPath { p in
                p.coLine([coPt(0.03, 0.62), coPt(0.27, 0.56)], 0.022); p.coLine([coPt(0.97, 0.62), coPt(0.73, 0.56)], 0.022)
            }
            .fill(COC.wood)
            // the cistern pedestal: dark sides, a lit front, a window onto the water
            COPath { $0.coBox(0.27, 0.62, 0.46, 0.34) }.fill(COC.bronzeDk)
            COPath { $0.coBox(0.34, 0.62, 0.32, 0.34) }.fill(COC.bronzeFill(.top, .bottom))
            COPath { p in p.coBox(0.24, 0.6, 0.52, 0.03, r: 0.006); p.coBox(0.24, 0.95, 0.52, 0.035, r: 0.006) }.fill(COC.bronzeDk)
            COPath { p in p.coBox(0.4, 0.71, 0.2, 0.12, r: 0.06) }.fill(Color(hex: 0x3a2a14))
            COPath { p in p.coBox(0.41, 0.765, 0.18, 0.055, r: 0.027) }
                .fill(LinearGradient(colors: [Fr.water, Color(hex: 0x3f7f9a)], startPoint: .top, endPoint: .bottom))
            COPath { p in p.coLine([coPt(0.36, 0.67), coPt(0.64, 0.67)], 0.01); p.coLine([coPt(0.36, 0.89), coPt(0.64, 0.89)], 0.01) }
                .fill(COC.bronzeLt.opacity(0.8))
            // the wind chest and its keys
            COPath { $0.coBox(0.17, 0.5, 0.66, 0.11, r: 0.01) }
                .fill(LinearGradient(colors: [COC.woodLt, COC.wood], startPoint: .top, endPoint: .bottom))
            COPath { p in for i in 0..<14 { p.coBox(0.205 + CGFloat(i) * 0.042, 0.565, 0.034, 0.04, r: 0.006) } }.fill(COC.ivory)
            COPath { p in for i in 0..<14 { p.coBox(0.205 + CGFloat(i) * 0.042, 0.595, 0.034, 0.01) } }.fill(Color.black.opacity(0.15))
            // the rank of pipes, tall to short
            COPath { p in for i in 0..<Self.pipes { p.coBox(Self.px(i), Self.ptop(i), 0.034, 0.5 - Self.ptop(i)) } }
                .fill(LinearGradient(colors: [COC.bronzeLt, COC.bronze], startPoint: .top, endPoint: .bottom))
            COPath { p in for i in 0..<Self.pipes { p.coBox(Self.px(i) + 0.024, Self.ptop(i), 0.01, 0.5 - Self.ptop(i)) } }
                .fill(COC.bronzeDk.opacity(0.55))
            COPath { p in for i in 0..<Self.pipes { p.coBox(Self.px(i) + 0.005, Self.ptop(i), 0.007, 0.5 - Self.ptop(i)) } }
                .fill(Color.white.opacity(0.3))
            COPath { p in
                for i in 0..<Self.pipes {
                    p.coDot(Self.px(i) + 0.017, Self.ptop(i), 0.017, 0.006)
                    p.coBox(Self.px(i) + 0.008, 0.415, 0.018, 0.02, r: 0.006)
                }
            }
            .fill(Color(hex: 0x3a2412))
            COPath { p in p.coBox(0.195, 0.455, 0.61, 0.018, r: 0.004) }.fill(COC.bronzeDk)
        }
    }
}
