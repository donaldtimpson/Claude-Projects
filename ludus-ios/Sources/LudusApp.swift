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
    @StateObject private var profiles = LudusProfiles.shared

    var body: some Scene {
        WindowGroup {
            root
                // A new player = a fresh tree, so every screen re-reads that player's save.
                .id(profiles.currentID)
                .fullScreenCover(isPresented: $profiles.showPicker) { LudusStage { ProfilePickerView() } }
                .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder private var root: some View {
        #if DEBUG
        // LUDUS_GAME=<GameID raw value> opens straight into that game (for checks and screenshots);
        // LUDUS_WORLD=<subject> opens straight onto that world's landing page.
        let env = ProcessInfo.processInfo.environment
        // LUDUS_GRANT=n sets the denarii bank; LUDUS_OWN=id,id… marks villa items owned;
        // LUDUS_SCREEN=villa|records opens those pages.
        let _ = {
            if let n = Int(env["LUDUS_GRANT"] ?? "") { LudusStore.defaults.set(n, forKey: LudusStore.denariiKey) }
            if let o = env["LUDUS_OWN"] {
                LudusStore.defaults.set(o == "all" ? villaCatalog.map(\.id) : o.split(separator: ",").map(String.init),
                                          forKey: LudusEconomy.ownedKey)
            }
        }()
        if env["LUDUS_SCREEN"] == "villa" {
            LudusStage { VillaView(onClose: {}) }
        } else if env["LUDUS_SCREEN"] == "records" {
            LudusStage { TabulariumView(onClose: {}) }
        } else if let g = env["LUDUS_GAME"], let id = GameID(rawValue: g) {
            ludusGame(id, onClose: {})                    // games stage themselves (ArcadeShell)
        } else if let sub = env["LUDUS_WORLD"], let w = ludusWorlds.first(where: { $0.subject == sub }) {
            LudusStage { NavigationStack { WorldView(world: w) } }
        } else {
            LudusStage { HomeView() }
        }
        #else
        LudusStage { HomeView() }
        #endif
    }
}
