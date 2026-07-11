import SwiftUI

// Category/tier metadata for badges (mirrors the web gamification catalog). The
// Badge model only carries `category`/`tier` as strings; this maps them to
// labels, glyphs, and the metal palette used to mint each medallion.
enum BadgeMeta {
    static let categoryOrder = ["milestones", "mastery", "completion", "consistency", "exploration", "special"]

    static func categoryLabel(_ key: String) -> String {
        switch key {
        case "milestones": return "Milestones"
        case "mastery": return "Mastery"
        case "completion": return "Completion"
        case "consistency": return "Consistency"
        case "exploration": return "Exploration"
        case "special": return "Special"
        default: return key.prefix(1).uppercased() + key.dropFirst()
        }
    }

    // SF Symbol engraved on the medallion for each category.
    static func categorySymbol(_ key: String) -> String {
        switch key {
        case "milestones": return "figure.run"
        case "mastery": return "target"
        case "completion": return "building.columns.fill"
        case "consistency": return "flame.fill"
        case "exploration": return "safari.fill"
        case "special": return "sparkles"
        default: return "star.fill"
        }
    }

    static func categoryBlurb(_ key: String) -> String {
        switch key {
        case "milestones": return "Volume — the steady climb."
        case "mastery": return "Quality — proof you learned it."
        case "completion": return "Finishing what you start."
        case "consistency": return "Showing up, day after day."
        case "exploration": return "Breadth across subjects."
        case "special": return "Seasonal, rare, and just for fun."
        default: return ""
        }
    }

    static let tierRank: [String: Int] = ["bronze": 0, "silver": 1, "gold": 2, "platinum": 3, "omniscient": 4]

    static func tierLabel(_ t: String) -> String {
        t == "omniscient" ? "Omniscient" : t.prefix(1).uppercased() + t.dropFirst()
    }

    // Metal face gradient (highlight → shadow) per tier.
    static func tierMetal(_ t: String) -> [Color] {
        switch t {
        case "bronze":     return [Color(hex: 0xe6b877), Color(hex: 0x8f5f2c)]
        case "silver":     return [Color(hex: 0xf2f2f6), Color(hex: 0x96969f)]
        case "gold":       return [Color(hex: 0xf4da8a), Color(hex: 0xb8860b)]
        case "platinum":   return [Color(hex: 0xeaf5ff), Color(hex: 0x9dc6e6)]
        case "omniscient": return [Color(hex: 0xf8ecb8), Color(hex: 0xddb954)]
        default:           return [Color(hex: 0xf4da8a), Color(hex: 0xb8860b)]
        }
    }

    static func tierGlow(_ t: String) -> Color {
        switch t {
        case "gold", "omniscient": return Color(hex: 0xddb954)
        case "platinum":           return Color(hex: 0x9dc6e6)
        default:                   return Color(hex: 0xb8860b)
        }
    }
}

// A procedurally-minted medallion: a metal face (tier gradient) inside a shimmering
// gold rim, with the category symbol engraved in the center. Locked badges become a
// dark disc with a padlock. No image assets.
struct BadgeMedallion: View {
    let badge: Badge
    var size: CGFloat = 68

    var body: some View {
        let unlocked = badge.unlocked
        let face = unlocked
            ? BadgeMeta.tierMetal(badge.tier)
            : [Color(hex: 0x3a2c2c), Color(hex: 0x201414)]
        let rim = unlocked
            ? [Color(hex: 0xf8ecb8), Color(hex: 0xb8860b), Color(hex: 0xf8ecb8), Color(hex: 0x9a7209), Color(hex: 0xf8ecb8)]
            : [Theme.line, Theme.crimson800, Theme.line]

        ZStack {
            Circle()
                .fill(RadialGradient(colors: face, center: UnitPoint(x: 0.35, y: 0.3),
                                     startRadius: 1, endRadius: size * 0.78))
            Circle()
                .strokeBorder(AngularGradient(colors: rim, center: .center),
                              lineWidth: size * 0.075)
            Image(systemName: unlocked ? BadgeMeta.categorySymbol(badge.category) : "lock.fill")
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(unlocked ? Color(hex: 0x2a1a0e).opacity(0.82) : Theme.inkSoft)
        }
        .frame(width: size, height: size)
        .shadow(color: BadgeMeta.tierGlow(badge.tier).opacity(unlocked ? 0.5 : 0),
                radius: unlocked ? size * 0.13 : 0)
        .opacity(unlocked ? 1 : 0.5)
    }
}
