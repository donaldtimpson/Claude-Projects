import SwiftUI

// The card treatment that came out of the aesthetic work — a warm card resting on
// a lit table — is now the fixed house style rather than one of three options. A
// child has no reason to care whether the shadow is soft or tight; the thing they
// notice is COLOUR, and colour is now the reward (see World.swift).
//
// This stays as a small value type so every existing call site keeps working, but
// it reads its colours from the live world.
struct Skin {
    static var live: Skin2 = Skin2()
    static var current: Skin { Skin() }

    var cardFill: Color { Skin.live.card }
    var cardRadius: CGFloat { 30 }
    var contact: (Color, CGFloat, CGFloat) { (.black.opacity(0.16), 5, 2) }
    var ambient: (Color, CGFloat, CGFloat) { (.black.opacity(0.11), 26, 14) }
    var cardEdge: Color { Color(hex: 0x2B2018).opacity(0.10) }
    var stackTilt: Double { 1.6 }
    var stackDrop: CGFloat { 11 }
    func stackFill(_ accent: Color) -> Color {
        cardFill.mixed(with: Color(hex: 0x8A7A62), amount: 0.10)
    }

    /// A deck's own ground: the world's sky, tinted toward that deck's colour so
    /// each deck still feels like a different room inside the same world.
    @ViewBuilder
    func ground(_ accent: Color) -> some View {
        LinearGradient(colors: Skin.live.world.sky.map {
            Color(hex: $0).mixed(with: accent, amount: 0.14)
        }, startPoint: .top, endPoint: .bottom)
    }

    /// Home and hub ground — the world itself, untinted.
    @ViewBuilder
    var appGround: some View { Skin.live.ground }
    var tileFill: Color { Skin.live.card }
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
