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
            HomeView()
                .preferredColorScheme(.dark)
        }
    }
}
