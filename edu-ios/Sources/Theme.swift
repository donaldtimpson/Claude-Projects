import SwiftUI

// The "lyceum" palette, echoing the web app: crimson + gold on parchment.
enum Theme {
    static let crimson = Color(red: 0.482, green: 0.067, blue: 0.075)
    static let gold = Color(red: 0.722, green: 0.525, blue: 0.043)
    static let parchment = Color(red: 0.961, green: 0.937, blue: 0.878)
    static let parchmentDeep = Color(red: 0.925, green: 0.890, blue: 0.812)
    static let card = Color(red: 1.0, green: 0.992, blue: 0.969)
    static let ink = Color(red: 0.169, green: 0.137, blue: 0.125)
    static let inkSoft = Color(red: 0.42, green: 0.38, blue: 0.34)
    static let line = Color(red: 0.886, green: 0.847, blue: 0.761)
    static let danger = Color(red: 0.627, green: 0.071, blue: 0.071)
    static let success = Color(red: 0.18, green: 0.49, blue: 0.196)
}

extension View {
    /// Standard card surface used throughout the app.
    func lyceumCard() -> some View {
        self
            .padding(16)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1)
            )
    }
}
