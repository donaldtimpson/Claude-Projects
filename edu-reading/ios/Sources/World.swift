import SwiftUI

// Themes are the reward, and they apply APP-WIDE rather than to one screen. A
// place that only changes the sky on one tab is decoration wearing a progress
// bar's clothes; a place that changes the whole app is somewhere you have moved to.
//
// This replaces the old Skin (flat / paper / sunroom), which was an aesthetic
// preference a child had no reason to care about. The paper card treatment that
// came out of that work stays as the fixed house style — it was the good one —
// and the theme now varies colour, which is what a child actually notices.
struct World: Identifiable, Hashable {
    let id: String
    let name: String
    let face: String
    let sky: [UInt]        // the app ground, top to bottom
    let ink: UInt
    let accent: UInt
    let card: UInt

    static let all: [World] = [
        World(id: "meadow", name: "Meadow", face: "🌱",
              sky: [0xFAF6EC, 0xEDF0E2], ink: 0x1F2A22, accent: 0x6FA368, card: 0xFFFDF8),
        World(id: "beach", name: "Beach", face: "🏖️",
              sky: [0xFFF6E6, 0xFCE7C8], ink: 0x2C2519, accent: 0xE0954E, card: 0xFFFCF4),
        World(id: "snow", name: "Snow", face: "❄️",
              sky: [0xF4F9FC, 0xE2ECF4], ink: 0x1D2731, accent: 0x4E8FBF, card: 0xFFFFFF),
        World(id: "night", name: "Night", face: "🌙",
              sky: [0xEDEBF7, 0xDCD9EE], ink: 0x211E33, accent: 0x6C5BA8, card: 0xFFFDFF),
        World(id: "space", name: "Space", face: "🚀",
              sky: [0xF1ECF8, 0xE2D9F0], ink: 0x241C33, accent: 0x8B5BC7, card: 0xFFFCFF),
    ]
    static func find(_ id: String) -> World { all.first { $0.id == id } ?? all[0] }

    /// Meadow is open from the start; everything else is earned.
    static var free: String { "meadow" }
}

/// The app's live look. Read everywhere instead of a fixed palette, so unlocking a
/// world changes every screen at once.
@Observable
final class Skin2 {
    var world: World = .find(World.free)
    func set(_ w: World) { world = w }

    var ground: LinearGradient {
        LinearGradient(colors: world.sky.map { Color(hex: $0) },
                       startPoint: .top, endPoint: .bottom)
    }
    var card: Color { Color(hex: world.card) }
    var accent: Color { Color(hex: world.accent) }
}
