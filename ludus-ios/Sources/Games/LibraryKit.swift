import SwiftUI

// MARK: - Library kit — small pieces the Word Wizards games share
//
// (Kept apart from LibraryVoice.swift, which QuickFire also calls.)

/// Text with *starred* parts in a mark colour, underlined — for "why" lessons after a miss.
func libMarked(_ s: String, base: UInt, mark: UInt) -> Text {
    var out = Text("")
    for (i, part) in s.components(separatedBy: "*").enumerated() where !part.isEmpty {
        out = out + (i % 2 == 1 ? Text(part).foregroundColor(Color(hex: mark)).underline(true, color: Color(hex: mark))
                                : Text(part).foregroundColor(Color(hex: base)))
    }
    return out
}

/// A one-shot burst of glyphs flying out from a point (insert it, remove it ~1 s later).
struct LibraryBurst: View {
    var glyphs = ["✨", "⭐️", "✨", "🌟", "✨", "⭐️"]
    var radius: CGFloat = 60
    @State private var go = false
    var body: some View {
        ZStack {
            ForEach(glyphs.indices, id: \.self) { i in
                let a = Double(i) / Double(glyphs.count) * 2 * .pi - .pi / 2
                Text(glyphs[i]).font(.system(size: 22))
                    .offset(x: go ? cos(a) * radius : 0, y: go ? sin(a) * radius * 0.85 - 16 : 0)
                    .scaleEffect(go ? 1.1 : 0.4)
                    .opacity(go ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .onAppear { withAnimation(.easeOut(duration: 0.75)) { go = true } }
    }
}

/// A warm parchment card (the Library's "panel"): cream paper, a darker edge, a soft shadow.
struct Parchment: View {
    var radius: CGFloat = 18
    var tint: UInt = 0xf3e2b8
    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: tint), luShade(tint, -26)], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color(hex: 0x8a5a2b).opacity(0.55), lineWidth: 2))
            .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
    }
}

/// A deterministic pseudo-random number in 0..<1 for scenery (stable across redraws).
func libHash(_ i: Int, _ salt: Int = 0) -> CGFloat {
    var x = UInt64(truncatingIfNeeded: i &* 2654435761 &+ salt &* 40503 &+ 12345)
    x ^= x >> 13; x = x &* 0x5bd1e995; x ^= x >> 15
    return CGFloat(x % 10_000) / 10_000
}
