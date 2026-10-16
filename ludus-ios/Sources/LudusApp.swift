import SwiftUI

// Ludus — the kids' arcade. A standalone app: the middle rung between "Sound It Out"
// (learning to read, ages 5–7) and the Timpson Lyceum (real courses, 13+). School
// subjects, arcade rules; earned Roman coinage (denarii/aurei) and a rank you climb.
//
// This build is a single prototype game — Bubble Evens — used to dial in touch feel on
// a real device. The launch screen becomes the arcade hub (worlds, shop, profile) as
// more mechanics land.

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

@main
struct LudusApp: App {
    init() { luRegisterFonts() }

    var body: some Scene {
        WindowGroup {
            root.preferredColorScheme(.dark)
        }
    }

    @ViewBuilder private var root: some View {
        #if DEBUG
        // LUDUS_GAME=<GameID raw value> opens straight into that game (for checks and screenshots);
        // LUDUS_WORLD=<subject> opens straight onto that world's landing page.
        let env = ProcessInfo.processInfo.environment
        if let g = env["LUDUS_GAME"], let id = GameID(rawValue: g) {
            ludusGame(id, onClose: {})
        } else if let sub = env["LUDUS_WORLD"], let w = ludusWorlds.first(where: { $0.subject == sub }) {
            NavigationStack { WorldView(world: w) }
        } else {
            HomeView()
        }
        #else
        HomeView()
        #endif
    }
}
