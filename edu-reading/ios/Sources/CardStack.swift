import SwiftUI

// One card, filling the screen. Tap it, or swipe it away. No Next button, no Back
// button, no chips — a child taps whatever is on screen expecting something to
// happen, so anything that isn't the card is a trap.
//
// Everything that used to be a chip (level, variant, category) now either advances
// on its own or lives in the grown-ups' area.
struct CardStack<Content: View>: View {
    let count: Int
    @Binding var index: Int
    var accent: Color
    var onTap: () -> Void
    var onAdvance: (() -> Void)? = nil
    @ViewBuilder var content: (Int) -> Content

    @State private var drag: CGSize = .zero
    @State private var pop = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                accent.opacity(0.16).ignoresSafeArea()

                if count > 0 {
                    content(index % count)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                        .shadow(color: .black.opacity(0.10), radius: 22, y: 10)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .id(index)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)))
                        .offset(x: drag.width, y: drag.height * 0.2)
                        .rotationEffect(.degrees(Double(drag.width / 30)))
                        .scaleEffect(pop ? 1.03 : 1)
                        .gesture(
                            DragGesture(minimumDistance: 14)
                                .onChanged { drag = $0.translation }
                                .onEnded { v in
                                    let far = abs(v.translation.width) > geo.size.width * 0.2
                                    withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                                        drag = .zero
                                        if far { index = (index + (v.translation.width < 0 ? 1 : -1) + count) % count }
                                    }
                                    if far { onAdvance?() }
                                }
                        )
                        .onTapGesture {
                            onTap()
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.45)) { pop = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pop = false }
                            }
                        }
                }
            }
        }
    }
}

/// A quiet page indicator. Kids don't read "7 / 22", but a row of dots shows there
/// is more, and shows it shrinking.
struct Dots: View {
    let count: Int, index: Int, accent: Color
    var body: some View {
        let shown = min(count, 14)
        HStack(spacing: 5) {
            ForEach(0..<shown, id: \.self) { i in
                let active = count <= 14 ? i == index : i == index * shown / max(count, 1)
                Circle()
                    .fill(active ? accent : accent.opacity(0.24))
                    .frame(width: active ? 8 : 6, height: active ? 8 : 6)
            }
        }
        .animation(.spring(response: 0.3), value: index)
    }
}

/// The celebration. Deliberately small: a pop and a rising glow, no confetti storm,
/// no sound effects layered over the word itself.
struct Sparkle: View {
    let accent: Color
    @State private var go = false
    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { i in
                Circle()
                    .fill(accent)
                    .frame(width: 9, height: 9)
                    .offset(y: go ? -76 : 0)
                    .rotationEffect(.degrees(Double(i) / 7 * 360))
                    .opacity(go ? 0 : 1)
                    .scaleEffect(go ? 0.3 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.75)) { go = true }
        }
        .allowsHitTesting(false)
    }
}

/// A whole deck screen: a tinted ground, one card, and a row of dots. No buttons.
struct DeckScreen<Content: View>: View {
    let title: String
    let count: Int
    @Binding var index: Int
    var accent: Color
    @ViewBuilder var content: (Int) -> Content
    var onTap: (Int) -> Void
    var onAdvance: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            CardStack(count: count, index: $index, accent: accent,
                      onTap: { if count > 0 { onTap(index % count) } },
                      onAdvance: onAdvance) { i in
                content(i)
            }
            Dots(count: count, index: count > 0 ? index % count : 0, accent: accent)
                .padding(.bottom, 14)
        }
        .background(accent.opacity(0.16).ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
