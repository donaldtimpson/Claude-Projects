import SwiftUI

// A theme was only ever a palette, which is why "beach" had nothing beach-like
// about it. A BACKDROP fixes that — once a faint still-life, now a living scene:
// snow that falls, stars that twinkle, a sea that moves. Drawn rather than sourced
// (no assets, no licences, correct at every size), it stays behind the card, which
// keeps its own fill and shadow — so a photograph of a dog is still the loudest
// thing on screen, but the world around it is finally alive.
//
// (A patterned card-back used to be the other themed surface, shown on two fanned
// cards behind the top one. The living backdrop made those redundant, so both the
// backs and their pattern were removed.)
//
// Classroom has none of this beyond a plain rule — being the plainest is its whole
// job.

// MARK: - backdrop (a living scene)

/// Behind everything. Each unlocked world runs its own particle scene, driven by a
/// single Canvas that redraws off a timeline — so snow actually falls and stars
/// actually twinkle, at any screen size, with no image assets. Cheap on purpose
/// (one Canvas, ~30fps, counts kept low) and honest about motion: when the system
/// asks for reduced motion the timeline pauses and the scene freezes into a still.
struct Backdrop: View {
    var world: World = Skin.live.world
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            // A still world — classroom — has nothing to animate, so driving a 30fps
            // timeline over it just repaints an unchanging picture 30 times a second
            // (idle CPU for no reward). Draw it once instead. Reduced motion makes
            // every world still, so it takes the same quiet path.
            if reduceMotion || !LivingScene.isAnimated(world) {
                Canvas { ctx, size in LivingScene.draw(world, 0, size, &ctx) }
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    Canvas { ctx, size in LivingScene.draw(world, t, size, &ctx) }
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

/// The per-world scenes. All time-driven and stateless: every particle's position
/// is a pure function of the timeline value and a seeded base, so nothing has to be
/// stored between frames and the whole thing survives being rebuilt at any moment.
enum LivingScene {
    /// Classroom is deliberately still (a plain dotted rule), so it needs no
    /// timeline. Every other world moves. Keep this in step with `draw`.
    static func isAnimated(_ w: World) -> Bool { w.id != "classroom" }

    static func draw(_ w: World, _ t: Double, _ size: CGSize, _ ctx: inout GraphicsContext) {
        switch w.id {
        case "snow":   snow(t, size, &ctx)
        case "space":  space(t, size, &ctx)
        case "meadow": meadow(t, size, &ctx)
        case "beach":  beach(t, size, &ctx)
        case "reef":   reef(t, size, &ctx)
        default:       classroom(w, size, &ctx)
        }
    }

    // MARK: shared

    /// Draw an emoji at a point, with opacity and an optional turn about its centre.
    private static func emoji(_ ctx: inout GraphicsContext, _ glyph: String, at p: CGPoint,
                              size: CGFloat, opacity: Double, rotation: Double = 0) {
        var g = ctx
        g.opacity = opacity
        g.translateBy(x: p.x, y: p.y)
        if rotation != 0 { g.rotate(by: .degrees(rotation)) }
        g.draw(Text(glyph).font(.system(size: size)), at: .zero, anchor: .center)
    }

    private static func dot(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat,
                            r: CGFloat, _ color: Color) {
        ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                 with: .color(color))
    }

    /// A bright star with a four-point glint, for the few that should sparkle.
    private static func starFlare(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat,
                                  r: CGFloat, _ color: Color) {
        dot(&ctx, x: x, y: y, r: r, color)
        var p = Path()
        p.move(to: CGPoint(x: x - r * 3.4, y: y)); p.addLine(to: CGPoint(x: x + r * 3.4, y: y))
        p.move(to: CGPoint(x: x, y: y - r * 3.4)); p.addLine(to: CGPoint(x: x, y: y + r * 3.4))
        ctx.stroke(p, with: .color(color.opacity(0.7)), lineWidth: 0.8)
    }

    /// A soft radial glow — a sun, a nebula bloom, a moon halo.
    private static func glow(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat,
                             radius: CGFloat, _ color: Color, _ opacity: Double) {
        ctx.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                 with: .radialGradient(Gradient(colors: [color.opacity(opacity), .clear]),
                                       center: CGPoint(x: x, y: y), startRadius: 0, endRadius: radius))
    }

    /// A rolling hill with a wavy top, filling to the bottom of the screen. Used to
    /// give the daytime scenes a foreground and a horizon, the way snow has its hills.
    private static func hill(_ ctx: inout GraphicsContext, _ s: CGSize, baseFrac: CGFloat,
                             amp: CGFloat, wavelength: Double, phase: Double, _ color: Color) {
        let W = s.width, H = s.height
        let y0 = H * baseFrac
        var p = Path()
        p.move(to: CGPoint(x: 0, y: H))
        p.addLine(to: CGPoint(x: 0, y: y0))
        var x: CGFloat = 0
        while x <= W {
            p.addLine(to: CGPoint(x: x, y: y0 + amp * CGFloat(sin(Double(x / W) * wavelength + phase))))
            x += 12
        }
        p.addLine(to: CGPoint(x: W, y: H)); p.closeSubpath()
        ctx.fill(p, with: .color(color))
    }

    // MARK: snow

    private static func snow(_ t: Double, _ s: CGSize, _ ctx: inout GraphicsContext) {
        let W = s.width, H = s.height

        // Aurora ribbons, undulating high in the night.
        let bands: [(UInt, CGFloat, Double, Double)] = [(0x5FE0C0, 0.16, 0.5, 0.0),
                                                        (0x86D46B, 0.25, 0.35, 1.4)]
        for b in bands {
            let cy = b.1 * H, amp: CGFloat = 26, thick: CGFloat = 64
            var band = Path()
            band.move(to: CGPoint(x: 0, y: cy))
            var x: CGFloat = 0
            while x <= W {
                band.addLine(to: CGPoint(x: x, y: cy + amp * CGFloat(sin(Double(x / W) * 4 + t * b.2 + b.3))))
                x += 10
            }
            x = W
            while x >= 0 {
                band.addLine(to: CGPoint(x: x, y: cy + thick + amp * CGFloat(sin(Double(x / W) * 4 + t * b.2 + b.3))))
                x -= 10
            }
            band.closeSubpath()
            ctx.fill(band, with: .linearGradient(
                Gradient(colors: [Color(hex: b.0).opacity(0.18), Color(hex: b.0).opacity(0)]),
                startPoint: CGPoint(x: W / 2, y: cy - amp), endPoint: CGPoint(x: W / 2, y: cy + thick + amp)))
        }

        // The moon and its halo.
        let mx = W * 0.8, my = H * 0.12
        ctx.fill(Path(ellipseIn: CGRect(x: mx - 90, y: my - 90, width: 180, height: 180)),
                 with: .radialGradient(Gradient(colors: [.white.opacity(0.32), .clear]),
                                       center: CGPoint(x: mx, y: my), startRadius: 0, endRadius: 95))
        dot(&ctx, x: mx, y: my, r: 27, .white.opacity(0.95))

        // A scatter of faint stars across the upper sky.
        var sky = SeededRandom2(seed: 3)
        for _ in 0..<46 {
            let x = sky.next() * W, y = sky.next() * H * 0.62
            let ph = Double(sky.next()) * 6.28
            let sp = 1 + Double(sky.next()) * 2
            dot(&ctx, x: x, y: y, r: 0.8 + sky.next() * 1.2,
                .white.opacity(0.2 + 0.3 * (0.5 + 0.5 * sin(t * sp + ph))))
        }

        // Three parallax layers of falling snow — bright now, against the dark.
        struct Layer { let n: Int; let rMin: CGFloat; let rMax: CGFloat
                       let speed: CGFloat; let sway: CGFloat; let op: Double; let soft: Bool }
        let layers = [
            Layer(n: 46, rMin: 1,  rMax: 2,   speed: 14, sway: 10, op: 0.75, soft: false),
            Layer(n: 28, rMin: 2,  rMax: 3.5, speed: 26, sway: 16, op: 0.95, soft: false),
            Layer(n: 11, rMin: 5,  rMax: 9,   speed: 46, sway: 26, op: 0.6,  soft: true),
        ]
        var seed: UInt64 = 20
        for layer in layers {
            var rng = SeededRandom2(seed: seed); seed &+= 7
            for _ in 0..<layer.n {
                let baseX = rng.next() * W
                let r = layer.rMin + rng.next() * (layer.rMax - layer.rMin)
                let phase = Double(rng.next()) * 6.28
                let sf = 0.4 + Double(rng.next()) * 0.8
                let y0 = rng.next() * (H + 40)
                let y = (y0 + CGFloat(t) * layer.speed).truncatingRemainder(dividingBy: H + 40) - 20
                let x = baseX + layer.sway * CGFloat(sin(t * sf + phase))
                if layer.soft {
                    let R = r * 2
                    ctx.fill(Path(ellipseIn: CGRect(x: x - R, y: y - R, width: R * 2, height: R * 2)),
                             with: .radialGradient(Gradient(colors: [.white.opacity(layer.op), .clear]),
                                                   center: CGPoint(x: x, y: y),
                                                   startRadius: 0, endRadius: R))
                } else {
                    dot(&ctx, x: x, y: y, r: r, .white.opacity(layer.op))
                }
            }
        }

        // A handful of crisp, tumbling flakes for character.
        var rng = SeededRandom2(seed: 99)
        for _ in 0..<8 {
            let baseX = rng.next() * W
            let sz = 12 + rng.next() * 10
            let phase = Double(rng.next()) * 6.28
            let y0 = rng.next() * (H + 40)
            let y = (y0 + CGFloat(t) * 20).truncatingRemainder(dividingBy: H + 40) - 20
            let x = baseX + 22 * CGFloat(sin(t * 0.5 + phase))
            emoji(&ctx, "❄️", at: CGPoint(x: x, y: y), size: sz, opacity: 0.85,
                  rotation: t * 30 + phase * 20)
        }

        // Moonlit snow on the ground, with a small winter landscape on it.
        var ground = Path()
        let gy = H * 0.9
        ground.move(to: CGPoint(x: 0, y: H))
        ground.addLine(to: CGPoint(x: 0, y: gy))
        ground.addQuadCurve(to: CGPoint(x: W, y: gy - 12), control: CGPoint(x: W * 0.5, y: gy - 34))
        ground.addLine(to: CGPoint(x: W, y: H))
        ground.closeSubpath()
        ctx.fill(ground, with: .linearGradient(
            Gradient(colors: [.white.opacity(0.9), Color(hex: 0xBFD6EE).opacity(0.75)]),
            startPoint: CGPoint(x: W / 2, y: gy - 30), endPoint: CGPoint(x: W / 2, y: H)))
        emoji(&ctx, "🌲", at: CGPoint(x: W * 0.87, y: H * 0.86), size: min(W, H) * 0.26, opacity: 0.92)
        emoji(&ctx, "🌲", at: CGPoint(x: W * 0.72, y: H * 0.9),  size: min(W, H) * 0.17, opacity: 0.8)
        emoji(&ctx, "⛄", at: CGPoint(x: W * 0.15, y: H * 0.87), size: min(W, H) * 0.22, opacity: 0.95)
    }

    // MARK: space

    private static func space(_ t: Double, _ s: CGSize, _ ctx: inout GraphicsContext) {
        let W = s.width, H = s.height
        let m = min(W, H)

        // Nebula — layered colour blooms with slow drift and breathing.
        let nebula: [(CGFloat, CGFloat, UInt, CGFloat)] = [
            (0.22, 0.34, 0x7A3CD0, 1.0),
            (0.82, 0.48, 0x3C6ABC, 1.2),
            (0.58, 0.20, 0xC23C8E, 0.8),
            (0.40, 0.60, 0x2E8C9E, 0.7),
        ]
        for (i, n) in nebula.enumerated() {
            let pulse = 0.10 + 0.05 * sin(t * 0.3 + Double(i))
            let cx = n.0 * W + 20 * CGFloat(sin(t * 0.05 + Double(i)))
            let cy = n.1 * H + 16 * CGFloat(cos(t * 0.04 + Double(i)))
            glow(&ctx, x: cx, y: cy, radius: m * 0.6 * n.3, Color(hex: n.2), pulse)
        }

        // The Milky Way: a river of dense stars arcing from lower-left to upper-right,
        // brightest along its spine. This is what turns a dot-field into a galaxy.
        let a = CGPoint(x: -0.1 * W, y: 0.92 * H), b = CGPoint(x: 1.15 * W, y: 0.06 * H)
        let dx = b.x - a.x, dy = b.y - a.y
        let px = -dy / hypot(dx, dy), py = dx / hypot(dx, dy)   // unit perpendicular
        let spread = m * 0.28
        var mw = SeededRandom2(seed: 71)
        for _ in 0..<240 {
            let along = mw.next()
            let g1 = mw.next(), g2 = mw.next(), g3 = mw.next()
            let perp = ((g1 + g2 + g3) / 3 - 0.5) * 2 * spread      // clustered near the spine
            let x = a.x + dx * along + px * perp
            let y = a.y + dy * along + py * perp
            let bright = max(0, 1 - abs(perp) / spread)
            let ph = Double(g1) * 6.28
            let tw = 0.6 + 0.4 * sin(t * 1.5 + ph)
            dot(&ctx, x: x, y: y, r: 0.5 + g2 * 1.2,
                .white.opacity((0.06 + 0.5 * Double(bright)) * tw))
        }

        // Scattered stars across the whole sky, a few bright enough to flare.
        var rng = SeededRandom2(seed: 5)
        let tints: [Color] = [.white, Color(hex: 0xBFD3FF), Color(hex: 0xFFE6C2)]
        for i in 0..<90 {
            let x = rng.next() * W
            let y = (rng.next() * H + CGFloat(t) * 2).truncatingRemainder(dividingBy: H)
            let r = 0.5 + rng.next() * 1.8
            let ph = Double(rng.next()) * 6.28
            let sp = 1.0 + Double(rng.next()) * 2.5
            let tw = 0.3 + 0.5 * (0.5 + 0.5 * sin(t * sp + ph))
            let c = tints[i % tints.count].opacity(tw)
            if r > 1.7 && i % 7 == 0 { starFlare(&ctx, x: x, y: y, r: r, c) }
            else { dot(&ctx, x: x, y: y, r: r, c) }
        }

        // Two shooting stars on different clocks, so the sky is never quite still.
        for (k, period) in [4.3, 6.7].enumerated() {
            let cycle = floor(t / period)
            let p = t / period - cycle
            guard p < 0.14 else { continue }
            var r2 = SeededRandom2(seed: UInt64(bitPattern: Int64(cycle) &* 97 &+ Int64(k)) &* 2654435761 &+ 1)
            let sx = r2.next() * W * 0.7
            let sy = r2.next() * H * 0.35
            let prog = CGFloat(p / 0.14)
            let hx = sx + prog * (W * 0.55), hy = sy + prog * (H * 0.4)
            var line = Path()
            line.move(to: CGPoint(x: hx - 110, y: hy - 80)); line.addLine(to: CGPoint(x: hx, y: hy))
            let fade = Double(1 - prog)
            ctx.stroke(line, with: .linearGradient(
                Gradient(colors: [.clear, .white.opacity(0.95 * fade)]),
                startPoint: CGPoint(x: hx - 110, y: hy - 80), endPoint: CGPoint(x: hx, y: hy)),
                       lineWidth: 2)
            dot(&ctx, x: hx, y: hy, r: 2.2, .white.opacity(fade))
        }

        // A small distant moon, high and pale.
        let mox = W * 0.2, moy = H * 0.14
        glow(&ctx, x: mox, y: moy, radius: 46, .white, 0.18)
        dot(&ctx, x: mox, y: moy, r: 15, Color(hex: 0xE8ECF6).opacity(0.9))

        // The planet you're standing on: a great curved horizon across the bottom,
        // rimmed with a glowing atmosphere. The scene's foreground and its anchor.
        let horizonY = H * 0.86
        let pr = W * 2.6
        let pc = CGPoint(x: W * 0.5, y: horizonY + pr)
        let planet = Path(ellipseIn: CGRect(x: pc.x - pr, y: pc.y - pr, width: pr * 2, height: pr * 2))
        glow(&ctx, x: W * 0.5, y: horizonY, radius: W * 0.7, Color(hex: 0x6FA8FF), 0.16)
        ctx.fill(planet, with: .linearGradient(
            Gradient(colors: [Color(hex: 0x1B2450), Color(hex: 0x090C1A)]),
            startPoint: CGPoint(x: W / 2, y: horizonY), endPoint: CGPoint(x: W / 2, y: H)))
        ctx.stroke(planet, with: .color(Color(hex: 0x8FC0FF).opacity(0.55)), lineWidth: 2.5)

        // A planet, simply placed. It drifts a little but does not spin — an emoji
        // rotating in-plane can't turn about its own tilted axis, and read as wrong.
        emoji(&ctx, "🪐", at: CGPoint(x: W * 0.8, y: H * 0.14 + 8 * CGFloat(sin(t * 0.4))),
              size: m * 0.26, opacity: 0.95)
    }

    // MARK: meadow

    private static func meadow(_ t: Double, _ s: CGSize, _ ctx: inout GraphicsContext) {
        let W = s.width, H = s.height, m = min(W, H)
        let sun = CGPoint(x: W * 0.84, y: H * 0.08)

        // The sun and its god-rays, fanning down into the field.
        for k in 0..<6 {
            let baseAng = 1.95 + Double(k) * 0.17 + 0.03 * sin(t * 0.2 + Double(k))
            let a1 = baseAng - 0.02, a2 = baseAng + 0.02
            var p = Path(); p.move(to: sun)
            p.addLine(to: CGPoint(x: sun.x + CGFloat(cos(a1)) * H, y: sun.y + CGFloat(sin(a1)) * H))
            p.addLine(to: CGPoint(x: sun.x + CGFloat(cos(a2)) * H, y: sun.y + CGFloat(sin(a2)) * H))
            p.closeSubpath()
            ctx.fill(p, with: .color(Color(hex: 0xFFF0A8).opacity(0.06)))
        }
        glow(&ctx, x: sun.x, y: sun.y, radius: m * 0.5, Color(hex: 0xFFE79A), 0.5)
        dot(&ctx, x: sun.x, y: sun.y, r: m * 0.09, Color(hex: 0xFFE38A).opacity(0.9))

        // Clouds drifting, bright against the blue.
        let clouds: [(CGFloat, CGFloat, CGFloat)] = [(0.20, 0.16, 0.24), (0.70, 0.10, 0.18), (0.45, 0.26, 0.14)]
        for (i, cl) in clouds.enumerated() {
            let x = (cl.0 * W + CGFloat(t) * (6 + CGFloat(i) * 3)).truncatingRemainder(dividingBy: W + 160) - 80
            emoji(&ctx, "☁️", at: CGPoint(x: x, y: cl.1 * H), size: m * cl.2, opacity: 0.85)
        }

        // Pollen drifting up on the breeze.
        var rng = SeededRandom2(seed: 33)
        for _ in 0..<30 {
            let bx = rng.next() * W
            let y0 = rng.next() * H
            let y = H - (y0 + CGFloat(t) * 10).truncatingRemainder(dividingBy: H)
            let ph = Double(rng.next()) * 6.28
            let x = bx + 18 * CGFloat(sin(t * 0.6 + ph))
            dot(&ctx, x: x, y: y, r: 1 + rng.next() * 2, Color(hex: 0xFCEFA0).opacity(0.6))
        }

        // Blossom petals falling.
        var rp = SeededRandom2(seed: 77)
        for _ in 0..<12 {
            let bx = rp.next() * W
            let y0 = rp.next() * (H + 40)
            let y = (y0 + CGFloat(t) * 24).truncatingRemainder(dividingBy: H + 40) - 20
            let ph = Double(rp.next()) * 6.28
            let x = bx + 30 * CGFloat(sin(t * 0.7 + ph))
            emoji(&ctx, "🌸", at: CGPoint(x: x, y: y), size: 14 + rp.next() * 8, opacity: 0.7,
                  rotation: t * 40 + ph * 20)
        }

        // Rolling hills — the horizon and foreground, the way snow has its hills.
        hill(&ctx, s, baseFrac: 0.78, amp: 20, wavelength: 3.0, phase: 0.6, Color(hex: 0x9FC97F))
        hill(&ctx, s, baseFrac: 0.87, amp: 26, wavelength: 2.2, phase: 2.2, Color(hex: 0x6DAB50))

        // A tree and a run of flowers along the near hill.
        emoji(&ctx, "🌳", at: CGPoint(x: W * 0.12, y: H * 0.80), size: m * 0.26, opacity: 0.95)
        let flowers = ["🌷", "🌼", "🌻", "🌷", "🌸", "🌼"]
        for (i, f) in flowers.enumerated() {
            emoji(&ctx, f, at: CGPoint(x: W * (0.30 + CGFloat(i) * 0.12), y: H * (0.86 + 0.01 * CGFloat(i % 2))),
                  size: m * 0.085, opacity: 0.9)
        }

        // A butterfly and a bee over the field.
        emoji(&ctx, "🦋", at: CGPoint(x: W * 0.5 + W * 0.34 * CGFloat(sin(t * 0.5)),
                                      y: H * 0.42 + H * 0.16 * CGFloat(sin(t * 0.8 + 1))),
              size: m * 0.1, opacity: 0.85, rotation: 10 * sin(t * 3))
        emoji(&ctx, "🐝", at: CGPoint(x: W * 0.4 + W * 0.30 * CGFloat(sin(t * 0.4 + 2)),
                                      y: H * 0.58 + H * 0.12 * CGFloat(cos(t * 0.7))),
              size: m * 0.07, opacity: 0.8, rotation: 6 * sin(t * 4))
    }

    // MARK: beach

    private static func beach(_ t: Double, _ s: CGSize, _ ctx: inout GraphicsContext) {
        let W = s.width, H = s.height

        // Sun with a slow, warm pulse.
        let pulse = 0.30 + 0.06 * sin(t * 0.8)
        ctx.fill(Path(ellipseIn: CGRect(x: W * 0.82 - W * 0.4, y: H * 0.12 - W * 0.4,
                                        width: W * 0.8, height: W * 0.8)),
                 with: .radialGradient(Gradient(colors: [Color(hex: 0xFFD27A).opacity(pulse), .clear]),
                                       center: CGPoint(x: W * 0.82, y: H * 0.12),
                                       startRadius: 0, endRadius: W * 0.42))
        emoji(&ctx, "☀️", at: CGPoint(x: W * 0.82, y: H * 0.12), size: min(W, H) * 0.2, opacity: 0.5)

        // Clouds.
        let clouds: [(CGFloat, CGFloat, CGFloat)] = [(0.15, 0.14, 0.18), (0.60, 0.09, 0.14)]
        for (i, cl) in clouds.enumerated() {
            let x = (cl.0 * W + CGFloat(t) * (7 + CGFloat(i) * 4)).truncatingRemainder(dividingBy: W + 160) - 80
            emoji(&ctx, "☁️", at: CGPoint(x: x, y: cl.1 * H), size: min(W, H) * cl.2, opacity: 0.4)
        }

        // The sea: layered sine waves that roll along the bottom.
        let base = H * 0.80
        let waves: [(UInt, Double, CGFloat, Double, Double)] = [
            (0x8FD3E8, 0.50, 10, 0.9, 0.0),
            (0x5FB6D6, 0.55, 14, 1.3, 1.0),
            (0x3E93BE, 0.60,  9, 1.8, 2.0),
        ]
        for (idx, wv) in waves.enumerated() {
            let (hex, op, amp, freq, phase) = wv
            let y0 = base + CGFloat(idx) * H * 0.06
            var path = Path()
            path.move(to: CGPoint(x: 0, y: H))
            path.addLine(to: CGPoint(x: 0, y: y0))
            var x: CGFloat = 0
            while x <= W {
                let y = y0 + amp * CGFloat(sin(freq * Double(x / W) * 6.28 + t * 1.2 + phase))
                path.addLine(to: CGPoint(x: x, y: y))
                x += 8
            }
            path.addLine(to: CGPoint(x: W, y: H)); path.closeSubpath()
            ctx.fill(path, with: .color(Color(hex: hex).opacity(op)))
        }

        // A sailboat crossing, riding the swell.
        let sbx = (CGFloat(t) * 20).truncatingRemainder(dividingBy: W + 120) - 60
        let sby = base - 6 + 5 * CGFloat(sin(t * 1.2))
        emoji(&ctx, "⛵️", at: CGPoint(x: sbx, y: sby), size: min(W, H) * 0.12, opacity: 0.85,
              rotation: 3 * sin(t * 1.2))

        // Glints on the water.
        var rng = SeededRandom2(seed: 61)
        for _ in 0..<24 {
            let x = rng.next() * W
            let y = base + rng.next() * (H * 0.2)
            let ph = Double(rng.next()) * 6.28
            let tw = max(0.0, sin(t * 3 + ph))
            dot(&ctx, x: x, y: y, r: 1.2, .white.opacity(0.5 * tw))
        }

        // A sandy island in the near corner — a tall mound whose crest rises right
        // under the palm, so the trunk plunges into sand rather than hanging in air.
        // Sea shows ABOVE it, which reads as distance.
        let crestX = W * 0.17
        let crestY = H * 0.89          // a low, half-height mound
        let edgeY = H * 0.94
        let toeX = W * 0.55
        func islandY(_ x: CGFloat) -> CGFloat {
            if x <= crestX {
                let u = x / crestX                       // edge -> crest
                return edgeY + (crestY - edgeY) * (2 * u - u * u)
            } else {
                let u = (x - crestX) / (toeX - crestX)   // crest -> H
                return crestY + (H - crestY) * (u * u)
            }
        }
        var island = Path()
        island.move(to: CGPoint(x: 0, y: H))
        island.addLine(to: CGPoint(x: 0, y: edgeY))
        var ix: CGFloat = 0
        while ix <= toeX { island.addLine(to: CGPoint(x: ix, y: islandY(ix))); ix += 8 }
        island.addLine(to: CGPoint(x: toeX, y: H))
        island.closeSubpath()
        ctx.fill(island, with: .linearGradient(
            Gradient(colors: [Color(hex: 0xF2DEAC), Color(hex: 0xD8B877)]),
            startPoint: CGPoint(x: W * 0.2, y: crestY), endPoint: CGPoint(x: W * 0.2, y: H)))
        // A pale line of foam where the sand meets the sea.
        var foam = Path()
        foam.move(to: CGPoint(x: 0, y: edgeY))
        ix = 0
        while ix <= toeX { foam.addLine(to: CGPoint(x: ix, y: islandY(ix))); ix += 8 }
        ctx.stroke(foam, with: .color(.white.opacity(0.5)), lineWidth: 2)

        // The palm, resting on the mound — its base just meets the sand line.
        emoji(&ctx, "🌴", at: CGPoint(x: crestX, y: crestY - H * 0.03), size: min(W, H) * 0.3, opacity: 0.95)
    }

    // MARK: reef

    private static func reef(_ t: Double, _ s: CGSize, _ ctx: inout GraphicsContext) {
        let W = s.width, H = s.height, m = min(W, H)

        // Sunlight shafts slanting down from the surface, swaying slowly.
        for k in 0..<5 {
            let baseX = W * (0.1 + 0.2 * CGFloat(k)) + 24 * CGFloat(sin(t * 0.15 + Double(k)))
            var p = Path()
            let topW = m * 0.06, botW = m * 0.14
            p.move(to: CGPoint(x: baseX - topW, y: 0))
            p.addLine(to: CGPoint(x: baseX + topW, y: 0))
            p.addLine(to: CGPoint(x: baseX + botW + 40, y: H))
            p.addLine(to: CGPoint(x: baseX - botW + 40, y: H))
            p.closeSubpath()
            ctx.fill(p, with: .linearGradient(
                Gradient(colors: [Color.white.opacity(0.10), Color.white.opacity(0)]),
                startPoint: CGPoint(x: baseX, y: 0), endPoint: CGPoint(x: baseX, y: H * 0.9)))
        }

        // The sandy floor, with a soft crest.
        var floor = Path()
        let fy = H * 0.9
        floor.move(to: CGPoint(x: 0, y: H))
        floor.addLine(to: CGPoint(x: 0, y: fy))
        floor.addQuadCurve(to: CGPoint(x: W, y: fy - 10), control: CGPoint(x: W * 0.5, y: fy - 40))
        floor.addLine(to: CGPoint(x: W, y: H))
        floor.closeSubpath()
        ctx.fill(floor, with: .linearGradient(
            Gradient(colors: [Color(hex: 0xE9D9A6), Color(hex: 0xCDB679)]),
            startPoint: CGPoint(x: W / 2, y: fy - 30), endPoint: CGPoint(x: W / 2, y: H)))

        // Seaweed swaying up from the floor.
        for (i, bx) in [0.08, 0.2, 0.9, 0.78].enumerated() {
            let x = W * CGFloat(bx)
            var blade = Path()
            blade.move(to: CGPoint(x: x, y: H))
            let hgt = m * (0.24 + 0.06 * CGFloat(i % 2))
            for seg in stride(from: 0.0, through: 1.0, by: 0.1) {
                let yy = H - CGFloat(seg) * hgt
                let sway = 18 * CGFloat(sin(t * 0.8 + Double(seg) * 3 + Double(i)))
                blade.addLine(to: CGPoint(x: x + sway * CGFloat(seg), y: yy))
            }
            ctx.stroke(blade, with: .color(Color(hex: 0x2E8B6E).opacity(0.8)),
                       style: StrokeStyle(lineWidth: m * 0.03, lineCap: .round))
        }

        // Coral clumps on the floor.
        emoji(&ctx, "🪸", at: CGPoint(x: W * 0.3, y: H * 0.9), size: m * 0.16, opacity: 0.95)
        emoji(&ctx, "🪸", at: CGPoint(x: W * 0.62, y: H * 0.92), size: m * 0.12, opacity: 0.85)

        // Fish drifting across on their own clocks, facing the way they swim.
        let fish: [(String, CGFloat, Double, Double)] = [
            ("🐠", 0.30, 0.10, 0.0), ("🐟", 0.55, 0.07, 2.0),
            ("🐡", 0.70, 0.05, 4.0), ("🐠", 0.44, 0.08, 1.0),
        ]
        // The fish emoji all face LEFT, so they swim right→left; going the other way
        // reads as swimming backwards.
        for (glyph, yFrac, speed, phase) in fish {
            let span = W + m * 0.5
            let x = (W + m * 0.25) - CGFloat((t * speed + phase).truncatingRemainder(dividingBy: 1)) * span
            let y = H * yFrac + m * 0.05 * CGFloat(sin(t * 0.9 + phase))
            emoji(&ctx, glyph, at: CGPoint(x: x, y: y), size: m * 0.11, opacity: 0.95)
        }

        // Bubbles rising and wobbling toward the surface.
        var rng = SeededRandom2(seed: 42)
        for _ in 0..<26 {
            let bx = rng.next() * W
            let r = 2 + rng.next() * 5
            let ph = Double(rng.next()) * 6.28
            let sp = 24 + Double(rng.next()) * 30
            let y = H - CGFloat((t * sp).truncatingRemainder(dividingBy: Double(H + 40)))
            let x = bx + 10 * CGFloat(sin(t * 1.2 + ph))
            ctx.stroke(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                       with: .color(.white.opacity(0.35)), lineWidth: 1)
        }
    }

    // MARK: classroom

    /// Deliberately still. A plain dotted rule and nothing else — being the calm
    /// baseline is what makes the earned worlds feel like a step up.
    private static func classroom(_ w: World, _ s: CGSize, _ ctx: inout GraphicsContext) {
        let tint = Color(hex: w.accent)
        let step: CGFloat = 26
        var i = 0, y: CGFloat = step / 2
        while y < s.height {
            var x: CGFloat = i.isMultiple(of: 2) ? step / 2 : step
            while x < s.width {
                dot(&ctx, x: x, y: y, r: 1.2, tint.opacity(0.18))
                x += step
            }
            y += step; i += 1
        }
    }
}

struct SeededRandom2 {
    var state: UInt64
    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((state >> 33) % 10_000) / 10_000
    }
}
