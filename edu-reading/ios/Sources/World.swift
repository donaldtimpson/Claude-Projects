import SwiftUI

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
    let card: UInt         // the card's paper
    let band: UInt         // the strip the word sits in
    let accent: UInt
    /// A soft light at the horizon, for the themes that want atmosphere. The plain
    /// one has none, which is most of what makes it plain.
    let glow: UInt?

    static let all: [World] = [
        // Free, and on purpose the quietest thing here.
        World(id: "classroom", name: "Classroom", face: "📋",
              sky: [0xF3F1EC, 0xE9E6DF], card: 0xFFFDF9, band: 0xFAF8F3,
              accent: 0x5E6B73, glow: nil),
        // Each one further from the plain default than the last, so unlocking is
        // visibly a step rather than a shuffle.
        World(id: "meadow", name: "Meadow", face: "🌱",
              sky: [0xF2F8E4, 0xD3E7BC], card: 0xFFFEF6, band: 0xE9F4D5,
              accent: 0x4F9440, glow: 0xC9E7A6),
        World(id: "beach", name: "Beach", face: "🏖️",
              sky: [0xFFF3D9, 0xF8D69B], card: 0xFFFBEE, band: 0xFDE9C4,
              accent: 0xDD7F1E, glow: 0xFFC978),
        World(id: "snow", name: "Snow", face: "❄️",
              sky: [0xEFF8FE, 0xC9DFF2], card: 0xFFFFFF, band: 0xE2EFFA,
              accent: 0x2E79C0, glow: 0xD6EBFC),
        World(id: "space", name: "Space", face: "🚀",
              sky: [0xEDE1FB, 0xCBB6EC], card: 0xFFFBFF, band: 0xE9DAFA,
              accent: 0x6C36C4, glow: 0xD3B8F7),
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
            world = .find(a[i + 1]); return
        }
        #endif
        if let s = UserDefaults.standard.string(forKey: key) { world = .find(s) }
    }
    func set(_ w: World) {
        world = w
        UserDefaults.standard.set(w.id, forKey: key)
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
}
