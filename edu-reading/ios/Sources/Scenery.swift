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

    /// Emoji as the motif rather than abstract paths. It is the illustration
    /// language the app already speaks — the drawings deck is entirely emoji — it
    /// costs nothing, and a tiny shell reads as "beach" in a way a wavy line does
    /// not. Faint and staggered, so it stays wallpaper rather than becoming a
    /// picture that competes with the card in front of it.
    static func pattern(_ w: World, _ ctx: inout GraphicsContext, _ size: CGSize) {
        let motifs: [String]
        let step: CGFloat
        switch w.id {
        case "meadow": motifs = ["🌿", "🌼", "🍃", "🌱"];      step = 46
        case "beach":  motifs = ["🐚", "🌴", "⛱️", "🦀"];      step = 48
        case "snow":   motifs = ["❄️", "⛄", "🌨️", "❄️"];      step = 46
        case "space":  motifs = ["⭐️", "🪐", "🚀", "✨"];      step = 48
        default:
            // Classroom keeps a plain dotted rule: being the quiet one is its job.
            let tint = Color(hex: w.accent)
            grid(size, 26) { p, _ in
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 1.2, y: p.y - 1.2,
                                                width: 2.4, height: 2.4)),
                         with: .color(tint.opacity(0.22)))
            }
            return
        }
        grid(size, step) { p, i in
            var g = ctx
            g.opacity = 0.26
            g.translateBy(x: p.x, y: p.y)
            // A little turn each, so a grid of stamps reads as a scattering.
            g.rotate(by: .degrees(Double((i % 5) - 2) * 9))
            g.draw(Text(motifs[i % motifs.count]).font(.system(size: step * 0.52)),
                   at: .zero, anchor: .center)
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

    /// A composed SCENE rather than a texture: things placed where they belong —
    /// a palm low on the left, a sun high on the right, a crab on the sand. Emoji
    /// again, because it is the app's illustration language and because a drawn
    /// palm at eight percent still says "beach" where an abstract curve does not.
    ///
    /// Each entry is (emoji, x, y, size, opacity) in fractions of the screen, so
    /// the scene composes the same on any device.
    private var scene: [(String, CGFloat, CGFloat, CGFloat, Double)] {
        switch world.id {
        case "beach":
            return [("☀️", 0.82, 0.07, 0.30, 0.20),
                    ("🌴", 0.10, 0.10, 0.26, 0.15),
                    ("🌴", 0.09, 0.96, 0.30, 0.16),
                    ("⛱️", 0.80, 0.96, 0.24, 0.15),
                    ("🐚", 0.45, 0.985, 0.13, 0.15),
                    ("🦀", 0.62, 0.99, 0.12, 0.13)]
        case "meadow":
            return [("☁️", 0.20, 0.07, 0.26, 0.16),
                    ("☁️", 0.78, 0.13, 0.20, 0.12),
                    ("🌳", 0.11, 0.96, 0.30, 0.16),
                    ("🌷", 0.42, 0.985, 0.14, 0.15),
                    ("🌼", 0.60, 0.99, 0.13, 0.14),
                    ("🦋", 0.86, 0.95, 0.14, 0.13)]
        case "snow":
            return [("⛄", 0.14, 0.96, 0.30, 0.17),
                    ("🌲", 0.84, 0.95, 0.28, 0.15),
                    ("🌲", 0.68, 0.99, 0.18, 0.12),
                    ("❄️", 0.26, 0.07, 0.16, 0.17),
                    ("❄️", 0.76, 0.12, 0.12, 0.14),
                    ("❄️", 0.52, 0.05, 0.09, 0.12)]
        case "space":
            return [("🪐", 0.80, 0.09, 0.32, 0.20),
                    ("🚀", 0.14, 0.09, 0.22, 0.17),
                    ("⭐️", 0.45, 0.05, 0.12, 0.15),
                    ("🌙", 0.16, 0.96, 0.24, 0.17),
                    ("✨", 0.55, 0.99, 0.14, 0.14),
                    ("⭐️", 0.86, 0.97, 0.11, 0.14)]
        default:
            return []           // Classroom has no scenery. That is what makes it plain.
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                // A starfield behind the objects, for the two themes that want one.
                if world.id == "space" || world.id == "snow" {
                    Canvas { ctx, _ in
                        var rng = SeededRandom2(seed: world.id == "space" ? 5 : 11)
                        let tint = Color(hex: world.accent)
                        for _ in 0..<52 {
                            let x = rng.next() * w, y = rng.next() * h
                            let r = 0.9 + rng.next() * 2.0
                            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                                     with: .color(tint.opacity(0.10 + rng.next() * 0.14)))
                        }
                    }
                }
                ForEach(Array(scene.enumerated()), id: \.offset) { _, item in
                    let (glyph, fx, fy, fs, op) = item
                    Text(glyph)
                        .font(.system(size: min(w, h) * fs))
                        .opacity(op)
                        .position(x: w * fx, y: h * fy)
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
