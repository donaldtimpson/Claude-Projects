import SwiftUI
import UIKit

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255
        )
    }

    /// A color that follows the app's appearance: `dark` in dark mode, `light` in light.
    init(light: UInt, dark: UInt) {
        self.init(UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}

// The design system, mirroring edu-web's app/globals.css (see "Design system &
// theming" in edu-web/CLAUDE.md). Colors are roles, not hues, and every role has a
// dark and a light value:
//
//   dark  = near-black crimson page, crimson cards, gold accents, parchment text
//   light = warm paper page, white cards, crimson accents, gold only as ornament
//
// "Gold" names the ACCENT role (links, primary fills, focus, selection): gold in
// dark mode, crimson in light, because gold text on a light surface is unreadable.
// `ornament` is the decorative gold that stays gold in both (heading bars, rules).
enum Theme {
    // Surfaces
    static let page = Color(light: 0xf6f2ec, dark: 0x0f0404)
    static let card = Color(light: 0xffffff, dark: 0x1a0909)
    static let tint = Color(light: 0xf0eae1, dark: 0x2d1212) // tracks, table heads, quiet fills
    static let line = Color(light: 0xddd2c3, dark: 0x4a1a1a) // borders, dividers
    static let strongLine = Color(light: 0xc2b29d, dark: 0x6e2020)
    static let field = Color(light: 0xffffff, dark: 0x2d1212) // text fields, unanswered choices
    static let button = Color(light: 0xffffff, dark: 0x4a1a1a) // secondary button fill

    // Text
    static let ink = Color(light: 0x1d1814, dark: 0xf5ecd8)
    static let inkSoft = Color(light: 0x5a4f46, dark: 0xc9b596)

    // Accent (gold in dark, crimson in light)
    static let accent = Color(light: 0x7c1d1d, dark: 0xb8860b) // primary fill
    static let accentPressed = Color(light: 0x5e1414, dark: 0xcfa135)
    static let link = Color(light: 0x8f2222, dark: 0xcfa135) // links, chevrons, icons
    static let accentText = Color(light: 0x8a1f1f, dark: 0xddb954) // emphasised accent text
    static let onAccent = Color(light: 0xf6f2ec, dark: 0x0f0404) // text on an accent fill
    static let ornament = Color(light: 0xb8860b, dark: 0xcfa135) // decorative gold, both themes

    // Status (brand-tuned, both themes)
    static let success = Color(light: 0x1b7a43, dark: 0x86c595)
    static let successLine = Color(light: 0x2f8f55, dark: 0x5fa872)
    static let successFill = Color(light: 0xe3f4e8, dark: 0x16301e)
    static let warning = Color(light: 0x8a4b00, dark: 0xeda25a) // mid-tier grades; orange-amber, clear of the gold accent
    static let warningFill = Color(light: 0xfdf3e1, dark: 0x3a2a0c)
    static let danger = Color(light: 0xb42318, dark: 0xe58a8a)
    static let dangerLine = Color(light: 0xc8341f, dark: 0xd06464)
    static let dangerFill = Color(light: 0xfdebe8, dark: 0x3a1414)

    // Fixed brand colors for artwork (Coming Soon art, medals) that must not flip.
    static let brandCrimson950 = Color(hex: 0x0f0404)
    static let brandCrimson900 = Color(hex: 0x1a0909)
    static let brandCrimson800 = Color(hex: 0x2d1212)
    static let brandGold = Color(hex: 0xddb954)

    // Older names, kept so every screen reads the same roles.
    static let parchment = page
    static let parchmentDeep = tint
    static let gold = accent
    static let gold500 = accent
    static let gold400 = link
    static let gold300 = accentText
    static let crimson = accentText
    static let crimson950 = page
    static let crimson900 = card
    static let crimson800 = tint
    static let crimson700 = line
    static let white = Color.white

    /// Grade tiers, same as the web: green ≥ 90, amber 70–89, red below, soft when there's no score.
    static func grade(_ pct: Double?) -> Color {
        guard let pct else { return inkSoft }
        if pct >= 90 { return success }
        if pct >= 70 { return warning }
        return danger
    }
}

// Type, mirroring the web:
//   serif   = Source Serif 4, reading text and titles
//   ui      = Inter, labels, metadata, buttons, chips, numbers
//   display = Cinzel, section titles and the wordmark only (never small, never on buttons)
// All scale with Dynamic Type.
extension Font {
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("Source Serif 4", size: size, relativeTo: style).weight(weight)
    }
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .subheadline) -> Font {
        .custom("Inter", size: size, relativeTo: style).weight(weight)
    }
    static func display(_ size: CGFloat) -> Font {
        .custom("Cinzel", size: size, relativeTo: .headline).weight(.bold)
    }
}

extension View {
    /// Standard card surface: card fill, hairline border, and in light mode a soft lift.
    func lyceumCard(padding: CGFloat = 16) -> some View {
        modifier(CardSurface(padding: padding))
    }
}

private struct CardSurface: ViewModifier {
    let padding: CGFloat
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
            .shadow(color: scheme == .light ? Color(hex: 0x3c2814).opacity(0.06) : .clear, radius: 6, y: 2)
    }
}

// Press feedback for tappable cells/rows: an accent border, a faint wash, and a tiny
// press-in. Identical to `.plain` at rest, lit only while the finger is down.
struct LyceumPressStyle: ButtonStyle {
    var cornerRadius: CGFloat = 12
    func makeBody(configuration: Configuration) -> some View {
        let down = configuration.isPressed
        return configuration.label
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).fill(Theme.accentText.opacity(down ? 0.06 : 0)))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(Theme.accentText, lineWidth: 1.5).opacity(down ? 1 : 0))
            .scaleEffect(down ? 0.985 : 1)
            // Light instantly on touch-down so it registers before a quick tap navigates.
            .animation(down ? nil : .easeOut(duration: 0.22), value: down)
    }
}

extension ButtonStyle where Self == LyceumPressStyle {
    /// Press feedback for tappable cards/rows (drop-in replacement for `.plain`).
    static var lyceumPress: LyceumPressStyle { LyceumPressStyle() }
    static func lyceumPress(cornerRadius: CGFloat) -> LyceumPressStyle { LyceumPressStyle(cornerRadius: cornerRadius) }
}

// MARK: - Appearance

/// The reader's appearance choice. System follows the device; Light suits a bright
/// room or a projector.
enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
    static let storageKey = "appearance"
}
