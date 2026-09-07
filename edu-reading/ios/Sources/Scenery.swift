import SwiftUI

// A theme was only ever a palette, which is why "beach" had nothing beach-like
// about it. Two surfaces fix that, and both are drawn rather than sourced — no
// assets, no licences, correct at every size.
//
//   • THE BACK OF THE CARD. The best surface in the app and it was blank: the two
//     cards behind the top one are on screen the whole time, so a patterned back
//     puts the theme in front of the child permanently. Playing cards have always
//     carried their identity on the back.
//   • A BACKDROP, kept very faint. Enough to say where you are, far too quiet to
//     compete with a photograph of a dog.
//
// Classroom has neither beyond a plain rule — being the plainest is its whole job.

// MARK: - card backs

struct CardBack: View {
    var world: World = Skin.live.world
    var radius: CGFloat = 30

    var body: some View {
        ZStack {
            Color(hex: world.card)
            Canvas { ctx, size in Self.pattern(world, &ctx, size) }
            // The double rule every playing card has.
            RoundedRectangle(cornerRadius: radius - 8, style: .continuous)
                .strokeBorder(Color(hex: world.accent).opacity(0.45), lineWidth: 1.5)
                .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(Color(hex: 0x2B2018).opacity(0.10), lineWidth: 1))
    }

    static func pattern(_ w: World, _ ctx: inout GraphicsContext, _ size: CGSize) {
        let tint = Color(hex: w.accent)
        switch w.id {
        case "meadow":
            // Leaves, each turned about ITS OWN centre — rotating the path
            // directly spins it around the canvas origin and flings them about.
            grid(size, 32) { p, i in
                var leaf = Path()
                leaf.move(to: CGPoint(x: 0, y: -8))
                leaf.addQuadCurve(to: CGPoint(x: 0, y: 8), control: CGPoint(x: 9, y: 0))
                leaf.addQuadCurve(to: CGPoint(x: 0, y: -8), control: CGPoint(x: -9, y: 0))
                let t = CGAffineTransform(rotationAngle: Double(i % 7) * 0.45)
                    .concatenating(.init(translationX: p.x, y: p.y))
                ctx.fill(leaf.applying(t), with: .color(tint.opacity(0.26)))
            }
        case "beach":
            // Waves, running the width of the card.
            var y: CGFloat = 14
            while y < size.height {
                var wave = Path()
                wave.move(to: CGPoint(x: -10, y: y))
                var x: CGFloat = -10
                while x < size.width + 20 {
                    wave.addQuadCurve(to: CGPoint(x: x + 22, y: y),
                                      control: CGPoint(x: x + 11, y: y - 7))
                    x += 22
                }
                ctx.stroke(wave, with: .color(tint.opacity(0.30)), lineWidth: 2)
                y += 22
            }
        case "snow":
            grid(size, 30) { p, i in
                let r: CGFloat = i.isMultiple(of: 3) ? 5 : 3
                for k in 0..<3 {
                    let a = Double(k) * .pi / 3
                    var arm = Path()
                    arm.move(to: CGPoint(x: p.x - cos(a) * r, y: p.y - sin(a) * r))
                    arm.addLine(to: CGPoint(x: p.x + cos(a) * r, y: p.y + sin(a) * r))
                    ctx.stroke(arm, with: .color(tint.opacity(0.34)), lineWidth: 1.5)
                }
            }
        case "space":
            grid(size, 26) { p, i in
                let r: CGFloat = [1.2, 2.2, 1.6, 3.0][i % 4]
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r,
                                                width: r * 2, height: r * 2)),
                         with: .color(tint.opacity(i % 4 == 3 ? 0.48 : 0.28)))
            }
        default:
            // Classroom: a fine dotted grid and nothing else.
            grid(size, 26) { p, _ in
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 1, y: p.y - 1, width: 2, height: 2)),
                         with: .color(tint.opacity(0.16)))
            }
        }
    }

    /// A staggered grid, so patterns do not read as rows and columns.
    private static func grid(_ size: CGSize, _ step: CGFloat,
                             _ draw: (CGPoint, Int) -> Void) {
        var i = 0, y: CGFloat = step / 2
        while y < size.height {
            var x: CGFloat = (i.isMultiple(of: 2) ? step / 2 : step)
            while x < size.width {
                draw(CGPoint(x: x, y: y), i &+ Int(x))
                x += step
            }
            y += step; i += 1
        }
    }
}

// MARK: - backdrop

/// Behind everything, and deliberately almost invisible. This is the difference
/// between a beach theme and a beige theme, but a photograph of a dog has to stay
/// the loudest thing on screen.
struct Backdrop: View {
    var world: World = Skin.live.world

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Canvas { ctx, _ in
                let tint = Color(hex: world.accent)
                switch world.id {
                case "beach":
                    // Sun low, a horizon, and a few long swells.
                    ctx.fill(Path(ellipseIn: CGRect(x: w * 0.60, y: h * 0.10,
                                                    width: w * 0.30, height: w * 0.30)),
                             with: .color(tint.opacity(0.10)))
                    var sea = Path()
                    sea.addRect(CGRect(x: 0, y: h * 0.72, width: w, height: h * 0.28))
                    ctx.fill(sea, with: .color(tint.opacity(0.06)))
                    for k in 0..<4 {
                        let y = h * 0.74 + CGFloat(k) * h * 0.055
                        var s = Path(); s.move(to: CGPoint(x: -10, y: y))
                        var x: CGFloat = -10
                        while x < w + 20 {
                            s.addQuadCurve(to: CGPoint(x: x + 46, y: y),
                                           control: CGPoint(x: x + 23, y: y - 9))
                            x += 46
                        }
                        ctx.stroke(s, with: .color(tint.opacity(0.10)), lineWidth: 2)
                    }
                case "meadow":
                    for (i, f) in [0.80, 0.87].enumerated() {
                        var hill = Path()
                        hill.move(to: CGPoint(x: -20, y: h))
                        hill.addQuadCurve(to: CGPoint(x: w + 20, y: h * f),
                                          control: CGPoint(x: w * (i == 0 ? 0.3 : 0.7),
                                                           y: h * (f - 0.14)))
                        hill.addLine(to: CGPoint(x: w + 20, y: h))
                        hill.closeSubpath()
                        ctx.fill(hill, with: .color(tint.opacity(i == 0 ? 0.09 : 0.06)))
                    }
                case "snow":
                    var drift = Path()
                    drift.move(to: CGPoint(x: -20, y: h))
                    drift.addQuadCurve(to: CGPoint(x: w + 20, y: h * 0.86),
                                       control: CGPoint(x: w * 0.5, y: h * 0.74))
                    drift.addLine(to: CGPoint(x: w + 20, y: h)); drift.closeSubpath()
                    ctx.fill(drift, with: .color(tint.opacity(0.08)))
                    var rng = SeededRandom2(seed: 11)
                    for _ in 0..<40 {
                        let x = rng.next() * w, y = rng.next() * h * 0.8
                        let r = 1.5 + rng.next() * 2.5
                        ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                                 with: .color(tint.opacity(0.16)))
                    }
                case "space":
                    var rng = SeededRandom2(seed: 5)
                    for _ in 0..<70 {
                        let x = rng.next() * w, y = rng.next() * h
                        let r = 0.8 + rng.next() * 2.2
                        ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                                 with: .color(tint.opacity(0.10 + rng.next() * 0.18)))
                    }
                    ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.55, y: h * 0.78,
                                                      width: w * 0.7, height: w * 0.7)),
                               with: .color(tint.opacity(0.12)), lineWidth: 2)
                default:
                    break   // Classroom has no scenery, which is the point of it.
                }
            }
        }
        .allowsHitTesting(false)
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
