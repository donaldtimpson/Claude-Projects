import SwiftUI
import UIKit

// Themes escalate. The one a parent meets first is deliberately the plainest --
// an off-white classroom that looks like a tool rather than a toy -- and the
// playful ones are earned. Two things fall out of that: the App Store screenshots
// are the calm version, and unlocking is a real change rather than a palette
// swap nobody asked for.
//
// The card is themed too, not just the ground. We never see the back of a card, so
// the surface available is the paper itself, the band the word sits in, and the
// edge — which turns out to be plenty: a sand-coloured card on a warm ground reads
// as "beach" without a single decorative shell.
struct World: Identifiable, Hashable {
    let id: String
    let name: String
    let face: String

    let sky: [UInt]        // app ground, top to bottom
    /// The card's paper. Tinted towards the world rather than left white: a sheet
    /// of white paper in five different rooms is the same sheet of paper, and the
    /// theme stops at the edges. Everything that must be judged on its own colour
    /// — the colour swatches above all — draws its own white and is unaffected.
    let card: UInt
    let band: UInt         // the strip the word sits in
    let accent: UInt
    /// Text drawn ON the ground rather than on a card. Without this every theme
    /// had to stay pale enough for dark ink, which is why "space" came out pink.
    let onSky: UInt
    /// A soft light at the horizon, for the themes that want atmosphere. The plain
    /// one has none, which is most of what makes it plain.
    let glow: UInt?

    static let all: [World] = [
        // Free, and on purpose the quietest thing here.
        World(id: "classroom", name: "Classroom", face: "📋",
              sky: [0xF3F1EC, 0xE9E6DF], card: 0xFFFEFB, band: 0xF7F5F0,
              accent: 0x5E6B73, onSky: 0x1B2A33, glow: nil),
        // Each one further from the plain default than the last, so unlocking is
        // visibly a step rather than a shuffle.
        World(id: "meadow", name: "Meadow", face: "🌱",
              sky: [0xF2F8E4, 0xD3E7BC], card: 0xF7FCEC, band: 0xE4F2CD,
              accent: 0x4F9440, onSky: 0x1E2A18, glow: 0xC9E7A6),
        World(id: "beach", name: "Beach", face: "🏖️",
              sky: [0xFFF3D9, 0xF8D69B], card: 0xFFF7E6, band: 0xFCE4B8,
              accent: 0xDD7F1E, onSky: 0x33240F, glow: 0xFFC978),
        World(id: "snow", name: "Snow", face: "❄️",
              sky: [0xEFF8FE, 0xC9DFF2], card: 0xF6FBFF, band: 0xDCEAF8,
              accent: 0x2E79C0, onSky: 0x142430, glow: 0xD6EBFC),
        // Actually dark. A night sky is the whole idea, and the cards stay light
        // so the pictures and the words are unaffected by it.
        World(id: "space", name: "Space", face: "🚀",
              sky: [0x0B1030, 0x241A4A], card: 0xF5F1FE, band: 0xE4DAF8,
              accent: 0x8B6BE0, onSky: 0xEDE9FF, glow: 0x3A2C6E),
    ]
    static func find(_ id: String) -> World { all.first { $0.id == id } ?? all[0] }
    static var free: String { "classroom" }
}

/// The app's live look. Read everywhere, so unlocking a world changes every screen.
@Observable
final class Skin2 {
    var world: World = .find(World.free)

    private let key = "sound-it-out.world"
    init() {
        #if DEBUG
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-world"), i + 1 < a.count {
            world = .find(a[i + 1]); NavInk.apply(world); return
        }
        #endif
        if let s = UserDefaults.standard.string(forKey: key) { world = .find(s) }
        NavInk.apply(world)
    }
    func set(_ w: World) {
        world = w
        UserDefaults.standard.set(w.id, forKey: key)
        NavInk.apply(w)
    }

    /// The app ground. The glow sits low, like light off a surface just out of frame.
    @ViewBuilder
    var ground: some View {
        ZStack {
            LinearGradient(colors: world.sky.map { Color(hex: $0) },
                           startPoint: .top, endPoint: .bottom)
            if let g = world.glow {
                RadialGradient(colors: [Color(hex: g), Color(hex: g).opacity(0)],
                               center: .init(x: 0.5, y: 1.06),
                               startRadius: 4, endRadius: 460)
            }
        }
    }
    var card: Color { Color(hex: world.card) }
    var band: Color { Color(hex: world.band) }
    var accent: Color { Color(hex: world.accent) }
    /// For text and chrome drawn on the ground, not on a card.
    /// True when the sky is dark enough that the bar's own title has to flip to
    /// light. Derived from the ink the theme already declares rather than a
    /// separate flag, so the two can never disagree.
    var isDark: Bool {
        let c = world.onSky
        let r = Double((c >> 16) & 0xFF), g = Double((c >> 8) & 0xFF), b = Double(c & 0xFF)
        return (0.299 * r + 0.587 * g + 0.114 * b) > 140
    }
    var onSky: Color { Color(hex: world.onSky) }
    var onSkySoft: Color { Color(hex: world.onSky).opacity(0.65) }
}


/// The bar's title is drawn by UIKit, and `toolbarColorScheme` cannot reach it
/// while the app pins `.preferredColorScheme(.light)` — which is why "Sound It
/// Out" stayed near-black on the night sky. Set it on the bar itself instead.
enum NavInk {
    static func apply(_ w: World) {
        let ink = UIColor(Color(hex: w.onSky))
        let a = UINavigationBarAppearance()
        a.configureWithTransparentBackground()
        a.titleTextAttributes = [.foregroundColor: ink]
        a.largeTitleTextAttributes = [.foregroundColor: ink]
        let bar = UINavigationBar.appearance()
        bar.standardAppearance = a
        bar.scrollEdgeAppearance = a
        bar.compactAppearance = a
        // appearance() only reaches bars built from here on, and the world is
        // chosen on a screen pushed onto a bar that already exists — so the one
        // the child is looking at has to be told directly.
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            ws.windows.forEach { restyle($0, with: a) }
        }
    }

    private static func restyle(_ v: UIView, with a: UINavigationBarAppearance) {
        if let bar = v as? UINavigationBar {
            bar.standardAppearance = a
            bar.scrollEdgeAppearance = a
            bar.compactAppearance = a
        }
        v.subviews.forEach { restyle($0, with: a) }
    }
}
