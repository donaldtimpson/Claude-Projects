import SwiftUI
import UIKit

// MARK: - Ludus design system
//
// The kids'-arcade brand: rounded system type, candy colours on a grape-indigo field,
// chunky pill/panel chrome, hard drop-shadows. Deliberately NOT the Lyceum look
// (Cinzel / crimson / parchment). One faint thread ties them together — Roman coinage
// (denarii / aurei) and Latin ranks — but everything here is loud on purpose.

// Imperial-mosaic palette: a Tyrian-purple night (Tyrian purple was THE Roman imperial
// colour), aureate gold, terracotta, laurel green, marble ivory. Names are kept stable so
// game code doesn't churn — only the hues shifted from "candy" toward "Rome".
enum Lu {
    // Grounds & chrome
    static let ground: UInt   = 0x1a1038
    static let ground2: UInt  = 0x241246
    static let panel: UInt    = 0x2c1c52
    static let panel2: UInt   = 0x372560
    static let line: UInt      = 0x4a3576
    static let goldLine: UInt  = 0x9c7b33   // aged-gold border for imperial framing
    // Text
    static let ink: UInt      = 0xf6ecd4   // marble ivory
    static let inkDim: UInt   = 0xccbd9a   // warm parchment-dim
    static let inkDark: UInt  = 0x241533   // dark text on bright tiles
    // Accents (Roman-flavoured)
    static let coral: UInt     = 0xe0684f  // terracotta
    static let tangerine: UInt = 0xe8973a  // amber
    static let mint: UInt      = 0x63b96b  // laurel green
    static let sky: UInt       = 0x4fa6cf  // mosaic blue
    static let grape: UInt     = 0xa96fd6  // Tyrian violet
    static let gold: UInt      = 0xf5c542  // aureate
    static let silver: UInt    = 0xd7d2c0  // pewter

    static let bubbleHexes: [UInt] = [0xf5c542, 0xe0684f, 0x63b96b, 0x4fa6cf, 0xa96fd6]
}

/// A rounded, heavy display font — the playful in-game voice (scores, buttons, tiles).
func luFont(_ size: CGFloat, _ weight: Font.Weight = .black) -> Font {
    .system(size: size, weight: weight, design: .rounded)
}

/// Chiseled serif in Roman capitals — the imperial branding voice (wordmark, world
/// titles, banners). Pair with `.textCase(.uppercase)` + tracking for the inscription feel.
func luSerif(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
    .system(size: size, weight: weight, design: .serif)
}

/// Roman numerals for small counts (I, II, III …). Digits above 39.
func romanNumeral(_ n: Int) -> String {
    guard n > 0 && n < 40 else { return "\(n)" }
    let table: [(Int, String)] = [(10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
    var v = n, s = ""
    for (val, sym) in table { while v >= val { s += sym; v -= val } }
    return s
}

/// Flanks its content with gold laurel branches — the house frame for a title or rank.
struct LaurelFrame<Content: View>: View {
    var color: UInt = Lu.gold
    var size: CGFloat = 24
    var spacing: CGFloat = 8
    @ViewBuilder let content: Content
    var body: some View {
        HStack(spacing: spacing) {
            Image(systemName: "laurel.leading").font(.system(size: size, weight: .semibold))
                .foregroundStyle(Color(hex: color))
            content
            Image(systemName: "laurel.trailing").font(.system(size: size, weight: .semibold))
                .foregroundStyle(Color(hex: color))
        }
    }
}

/// A thin gold Greek-key-flavoured rule with a center pip — an imperial divider.
struct MeanderRule: View {
    var color: UInt = Lu.goldLine
    var body: some View {
        HStack(spacing: 6) {
            Rectangle().fill(Color(hex: color).opacity(0.6)).frame(height: 2)
            Image(systemName: "diamond.fill").font(.system(size: 7)).foregroundStyle(Color(hex: color))
            Rectangle().fill(Color(hex: color).opacity(0.6)).frame(height: 2)
        }
    }
}

/// Lighten/darken a packed-hex colour by an amount per channel.
func luShade(_ hex: UInt, _ amt: Int) -> Color {
    func ch(_ shift: UInt) -> Double { Double(max(0, min(255, Int((hex >> shift) & 0xff) + amt))) / 255 }
    return Color(.sRGB, red: ch(16), green: ch(8), blue: ch(0))
}

/// Roman rank from total banked denarii — the app-wide progression marker.
func ludusRank(forDenarii den: Int) -> String {
    if den >= 750 { return "Consul" }
    if den >= 300 { return "Centurion" }
    if den >= 100 { return "Legionary" }
    return "Tiro"
}

// MARK: Shared keys (one economy across every game)

enum LudusStore {
    static let denariiKey = "ludus_denarii"   // global soft-currency bank
    static func bestKey(_ game: String) -> String { "ludus_best_\(game)" }

    static var denarii: Int { UserDefaults.standard.integer(forKey: denariiKey) }
    static func award(_ n: Int) {
        UserDefaults.standard.set(denarii + n, forKey: denariiKey)
    }
    static func recordBest(_ game: String, _ score: Int) -> Bool {
        let key = bestKey(game)
        if score > UserDefaults.standard.integer(forKey: key) {
            UserDefaults.standard.set(score, forKey: key); return true
        }
        return false
    }
    static func best(_ game: String) -> Int { UserDefaults.standard.integer(forKey: LudusStore.bestKey(game)) }
}

// MARK: Haptics

enum Haptics {
    private static let impact = UIImpactFeedbackGenerator(style: .medium)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let notify = UINotificationFeedbackGenerator()
    static func prime() { impact.prepare(); soft.prepare(); notify.prepare() }
    static func tap(_ intensity: Double = 0.7) { impact.impactOccurred(intensity: min(1, max(0.1, intensity))); impact.prepare() }
    static func light() { soft.impactOccurred(); soft.prepare() }
    static func success() { notify.notificationOccurred(.success); notify.prepare() }
    static func error() { notify.notificationOccurred(.error); notify.prepare() }
}

// MARK: - Reusable views

struct LudusBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: Lu.ground), Color(hex: Lu.ground2)],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color(hex: Lu.grape).opacity(0.22), .clear],
                           center: UnitPoint(x: 0.85, y: -0.05), startRadius: 0, endRadius: 460)
            RadialGradient(colors: [Color(hex: Lu.sky).opacity(0.15), .clear],
                           center: UnitPoint(x: 0.05, y: 1.05), startRadius: 0, endRadius: 460)
        }
    }
}

struct LudusButton: View {
    let title: String
    var fill: [UInt] = [Lu.gold, Lu.tangerine]
    var shadow: UInt = 0xb96b1e
    var fullWidth: Bool = false
    let action: () -> Void

    @State private var pressed = false
    private let radius: CGFloat = 16
    private let ledge: CGFloat = 5   // 3D base depth

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(luSerif(20, .black))
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(Color(hex: 0x3a2708))
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .padding(.vertical, 15).padding(.horizontal, 40)
                .background(buttonFace)
                .offset(y: pressed ? ledge : 0)                     // press sinks onto its base
                .background(alignment: .bottom) {                    // the darker 3D base ledge
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(Color(hex: shadow))
                        .padding(.top, ledge)
                }
                .shadow(color: .black.opacity(0.28), radius: 10, x: 0, y: 7)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in withAnimation(.easeOut(duration: 0.06)) { pressed = true } }
            .onEnded { _ in withAnimation(.easeOut(duration: 0.12)) { pressed = false } })
    }

    // Gold face with a soft top sheen — no clashing hard outline.
    private var buttonFace: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(LinearGradient(colors: fill.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(.white.opacity(0.55), lineWidth: 1)
                    .blur(radius: 0.5)
                    .mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom))
            )
    }
}

/// The stat pills used in every game HUD (SCORE / DENARII / etc.).
struct StatPill: View {
    let label: String
    let value: String
    var valueHex: UInt = Lu.ink
    var body: some View {
        VStack(spacing: 1) {
            Text(label).font(luFont(9, .heavy)).tracking(1.4).foregroundStyle(Color(hex: Lu.inkDim))
            Text(value).font(luFont(20)).monospacedDigit().foregroundStyle(Color(hex: valueHex))
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(luPanelShape(14))
    }
}

/// A rounded panel fill + border — the standard Ludus surface.
func luPanelShape(_ radius: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: radius)
        .fill(LinearGradient(colors: [Color(hex: Lu.panel2), Color(hex: Lu.panel)],
                             startPoint: .top, endPoint: .bottom))
        .overlay(RoundedRectangle(cornerRadius: radius).stroke(Color(hex: Lu.line), lineWidth: 2))
}

/// Close (✕) button shared by every full-screen game.
struct LudusCloseButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(Color(hex: Lu.inkDim))
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: Lu.panel))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: Lu.line), lineWidth: 2)))
        }
        .buttonStyle(.plain)
    }
}

/// Lives display — 3 hearts filling/emptying, in a panel pill.
struct HeartsRow: View {
    let hearts: Int
    var maxHearts: Int = 3
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<maxHearts, id: \.self) { i in
                Image(systemName: i < hearts ? "heart.fill" : "heart")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(hex: i < hearts ? Lu.coral : Lu.line))
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(luPanelShape(14))
    }
}

/// A stat block used on the game-over screen.
struct ResultCard: View {
    let label: String
    let value: String
    var hex: UInt = Lu.ink
    var body: some View {
        VStack(spacing: 2) {
            Text(label).font(luFont(10, .heavy)).tracking(1.2).foregroundStyle(Color(hex: Lu.inkDim))
            Text(value).font(luFont(30)).monospacedDigit().foregroundStyle(Color(hex: hex))
        }
        .frame(minWidth: 92)
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(luPanelShape(16))
    }
}

/// Shared full-screen game-over overlay. Every game shows the same summary so scores,
/// the banked-denarii rank, and the replay flow read identically across the arcade.
struct LudusGameOverView: View {
    let reason: String
    let score: Int
    let best: Int
    let denRun: Int
    var newBest: Bool = false
    let onAgain: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.58).ignoresSafeArea()
            VStack(spacing: 10) {
                Text(reason.uppercased()).font(luFont(12, .heavy)).tracking(3)
                    .foregroundStyle(Color(hex: Lu.grape))
                LaurelFrame(size: 30) {
                    Text("Finis").font(luSerif(50, .black)).textCase(.uppercase).tracking(2)
                        .foregroundStyle(LinearGradient(colors: [.white, Color(hex: Lu.gold), Color(hex: Lu.tangerine)],
                                                        startPoint: .top, endPoint: .bottom))
                }
                if newBest {
                    Text("★ NEW BEST! ★").font(luFont(15)).foregroundStyle(Color(hex: Lu.mint))
                }
                HStack(spacing: 12) {
                    ResultCard(label: "SCORE", value: "\(score)", hex: Lu.gold)
                    ResultCard(label: "BEST", value: "\(best)", hex: Lu.mint)
                    ResultCard(label: "DENARII", value: "🪙\(denRun)", hex: Lu.silver)
                }
                .padding(.top, 4)
                LaurelFrame(size: 18) {
                    Text(ludusRank(forDenarii: LudusStore.denarii)).font(luSerif(18, .black))
                        .textCase(.uppercase).tracking(1.5).foregroundStyle(Color(hex: Lu.gold))
                }
                .padding(.top, 2)
                LudusButton(title: "Play Again", action: onAgain).padding(.top, 12)
                Button("Done", action: onClose)
                    .font(luFont(15, .bold)).foregroundStyle(Color(hex: Lu.inkDim)).padding(.top, 4)
                Text("Banked denarii: \(LudusStore.denarii)")
                    .font(luFont(12, .semibold)).foregroundStyle(Color(hex: Lu.inkDim).opacity(0.8))
                    .padding(.top, 10)
            }
            .padding(28)
        }
    }
}
