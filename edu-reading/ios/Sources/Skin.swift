import SwiftUI

// "Flat" is the right word for the old look: a white rectangle on a grey wash,
// with nothing to say the card is an OBJECT. These are three directions for
// fixing that without adding noise — the failure mode Donald warned about, where
// a children's app buries the content under decoration.
//
// The move in all three is the same: this app is a deck of cards, so make the
// card feel like a card and the ground feel like a surface it is lying on. Depth
// costs nothing in legibility; pattern and colour would.
enum Skin: String, CaseIterable {
    /// What shipped: flat white card, flat tinted ground.
    case flat
    /// A card on a table. Warm paper, a tight contact shadow under a soft ambient
    /// one, a hairline edge, and a stack that is genuinely stacked.
    case paper
    /// Brighter and warmer. The deck's own colour becomes a soft wash of light
    /// behind the card, so each deck feels like a different room.
    case sunroom

    /// Chosen in the grown-ups' area, so the look can be compared on a real device
    /// with a real child rather than argued about from screenshots. A launch
    /// argument overrides it for screenshot runs.
    static var current: Skin {
        #if DEBUG
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-skin"), i + 1 < a.count,
           let s = Skin(rawValue: a[i + 1]) { return s }
        #endif
        return Skin(rawValue: UserDefaults.standard.string(forKey: "sound-it-out.skin") ?? "") ?? .paper
    }

    static func choose(_ s: Skin) {
        UserDefaults.standard.set(s.rawValue, forKey: "sound-it-out.skin")
    }

    var label: String {
        switch self {
        case .flat: return "Plain"
        case .paper: return "Paper"
        case .sunroom: return "Sunroom"
        }
    }
    var blurb: String {
        switch self {
        case .flat:    return "Flat white cards on a flat tint."
        case .paper:   return "Warm card resting on a lit table."
        case .sunroom: return "Bright and warm; each deck feels like its own room."
        }
    }

    /// The home screen and hub ground, so the whole app agrees rather than only
    /// the decks changing.
    @ViewBuilder
    var appGround: some View {
        switch self {
        case .flat:    Theme.ground
        case .paper:   LinearGradient(colors: [Color(hex: 0xFAF4EA), Color(hex: 0xEFE7DA)],
                                      startPoint: .top, endPoint: .bottom)
        case .sunroom: Color(hex: 0xFFFBF4)
        }
    }
    var tileFill: Color {
        switch self {
        case .flat:    return Color(hex: 0xFFFFFF)
        case .paper:   return Color(hex: 0xFFFCF6)
        case .sunroom: return Color(hex: 0xFFFFFF)
        }
    }

    // MARK: surfaces

    var cardFill: Color {
        switch self {
        case .flat:    return Color(hex: 0xFFFFFF)
        case .paper:   return Color(hex: 0xFEFCF8)   // warm white, not paper-blue
        case .sunroom: return Color(hex: 0xFFFFFF)
        }
    }

    var cardRadius: CGFloat { self == .flat ? 34 : 30 }

    /// A single soft shadow reads as a sticker. A tight dark one plus a wide faint
    /// one is what an object resting on a surface actually casts.
    var contact: (Color, CGFloat, CGFloat) {
        switch self {
        case .flat:    return (.black.opacity(0.10), 22, 10)
        case .paper:   return (.black.opacity(0.16), 5, 2)
        case .sunroom: return (.black.opacity(0.10), 4, 2)
        }
    }
    var ambient: (Color, CGFloat, CGFloat) {
        switch self {
        case .flat:    return (.clear, 0, 0)
        case .paper:   return (.black.opacity(0.11), 26, 14)
        case .sunroom: return (.black.opacity(0.09), 30, 16)
        }
    }

    var cardEdge: Color {
        switch self {
        case .flat:    return .clear
        case .paper:   return Color(hex: 0x2B2018).opacity(0.10)
        case .sunroom: return Color(hex: 0x2B2018).opacity(0.06)
        }
    }

    /// The ground the card rests on.
    @ViewBuilder
    func ground(_ accent: Color) -> some View {
        switch self {
        case .flat:
            Theme.ground.mixed(with: accent, amount: 0.22)
        case .paper:
            // Light falling on a table: warmer and slightly brighter at the top,
            // sinking toward the bottom, so the card has somewhere to sit.
            LinearGradient(colors: [Theme.ground.mixed(with: accent, amount: 0.16)
                                        .mixed(with: Color(hex: 0xFFF6E8), amount: 0.35),
                                    Theme.ground.mixed(with: accent, amount: 0.30)],
                           startPoint: .top, endPoint: .bottom)
        case .sunroom:
            ZStack {
                Color(hex: 0xFFFBF4)
                RadialGradient(colors: [accent.mixed(with: Color(hex: 0xFFFBF4), amount: 0.55),
                                        Color(hex: 0xFFFBF4)],
                               center: .init(x: 0.5, y: 0.32),
                               startRadius: 10, endRadius: 520)
            }
        }
    }

    /// How the cards behind the top one are drawn.
    var stackTilt: Double { self == .paper ? 1.6 : 0 }
    var stackDrop: CGFloat {
        switch self {
        case .flat: return 16
        case .paper: return 11
        case .sunroom: return 13
        }
    }
    func stackFill(_ accent: Color) -> Color {
        switch self {
        case .flat:    return Theme.paper.mixed(with: accent, amount: 0.10)
        case .paper:   return cardFill.mixed(with: Color(hex: 0x8A7A62), amount: 0.10)
        case .sunroom: return Theme.paper.mixed(with: accent, amount: 0.13)
        }
    }
}

/// The card surface, in one place so every deck gets the same object.
struct CardSurfaceStyle: ViewModifier {
    let skin: Skin
    func body(content: Content) -> some View {
        let (cc, cr, cy) = skin.contact
        let (ac, ar, ay) = skin.ambient
        content
            .background(skin.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: skin.cardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: skin.cardRadius, style: .continuous)
                .strokeBorder(skin.cardEdge, lineWidth: 1))
            .shadow(color: cc, radius: cr, y: cy)
            .shadow(color: ac, radius: ar, y: ay)
    }
}
