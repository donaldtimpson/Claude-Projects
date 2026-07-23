import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255
        )
    }
}

// Palette mirrors edu-web's globals.css: a dark, classical "lyceum" look —
// near-black crimson field, crimson surfaces, gold accents, parchment text.
enum Theme {
    // Raw palette
    static let crimson950 = Color(hex: 0x0f0404)
    static let crimson900 = Color(hex: 0x190808)
    static let crimson800 = Color(hex: 0x2d1212)
    static let crimson700 = Color(hex: 0x4a1a1a)
    static let gold500 = Color(hex: 0xb8860b)
    static let gold400 = Color(hex: 0xcfa135)
    static let gold300 = Color(hex: 0xddb954)

    // Semantic aliases (names kept stable across the app)
    static let parchment = crimson950 // screen background
    static let card = crimson900 // surfaces / cards
    static let parchmentDeep = crimson800 // secondary surfaces / selection
    static let line = crimson700 // borders / dividers
    static let ink = Color(hex: 0xf5ecd8) // primary text (parchment)
    static let inkSoft = Color(hex: 0xc4af8e) // secondary text (parchment-dim)
    static let crimson = gold300 // brand accent: titles, tints, selection
    static let gold = gold500 // gold accents (numbers, badges)
    static let accent = gold500 // primary-button fill
    static let onAccent = crimson950 // text on a gold fill
    static let success = Color(hex: 0x5cb85c)
    static let danger = Color(hex: 0xe06666)
    static let white = Color.white
}

// Brand fonts (bundled TTFs): Cinzel for display, EB Garamond for body — same as web.
extension Font {
    static func display(_ size: CGFloat) -> Font { .custom("Cinzel", size: size) }
    static func serif(_ size: CGFloat) -> Font { .custom("EB Garamond", size: size) }
}

extension View {
    /// Standard card surface used throughout the app.
    func lyceumCard() -> some View {
        self
            .padding(16)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
    }
}

// Press feedback for tappable cells/rows: a warm gold glow — a gold border, a faint gold
// wash, a soft outer glow, and a tiny press-in — so a selection reads clearly. Identical to
// `.plain` at rest (no chrome), lit only while the finger is down.
struct LyceumPressStyle: ButtonStyle {
    var cornerRadius: CGFloat = 12
    func makeBody(configuration: Configuration) -> some View {
        let down = configuration.isPressed
        return configuration.label
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).fill(Theme.gold300.opacity(down ? 0.07 : 0)))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(Theme.gold300, lineWidth: 1.5).opacity(down ? 1 : 0))
            .scaleEffect(down ? 0.985 : 1)
            .shadow(color: Theme.gold300.opacity(down ? 0.5 : 0), radius: down ? 12 : 0)
            // Snap to lit almost instantly on touch-down so the glow registers before a
            // quick tap triggers navigation; ease the fade-out a touch longer on release.
            .animation(down ? .easeOut(duration: 0.05) : .easeOut(duration: 0.22), value: down)
    }
}

extension ButtonStyle where Self == LyceumPressStyle {
    /// Gold press-glow for tappable cards/rows (drop-in replacement for `.plain`).
    static var lyceumPress: LyceumPressStyle { LyceumPressStyle() }
    static func lyceumPress(cornerRadius: CGFloat) -> LyceumPressStyle { LyceumPressStyle(cornerRadius: cornerRadius) }
}
