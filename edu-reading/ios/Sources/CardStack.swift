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

    @Environment(Settings.self) private var settings
    @State private var drag: CGSize = .zero
    @State private var pop = false
    @State private var spoke = false      // has this card been tapped once yet
    @State private var hinted = false
    @State private var turnTask: DispatchWorkItem?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                accent.opacity(0.16).ignoresSafeArea()

                // The card is visibly a DECK: two more behind it, peeking below and
                // to the right. A child who taps and taps has usually just not been
                // told there is anything else — a stack says so without words.
                ForEach([2, 1], id: \.self) { back in
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(Theme.paper.opacity(back == 1 ? 0.92 : 0.75))
                        .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(accent.opacity(0.30), lineWidth: 1.5))
                        .scaleEffect(x: 1 - CGFloat(back) * 0.05, y: 1, anchor: .top)
                        .offset(y: CGFloat(back) * 16)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                }

                if count > 0 {
                    content(index % count)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
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
                                        if far { step(v.translation.width < 0 ? 1 : -1) }
                                    }
                                }
                        )
                        .onTapGesture { tapped() }
                }
            }
            .onAppear { hintOnce(geo.size.width) }
            .onChange(of: index) { spoke = false; turnTask?.cancel() }
            .onDisappear { turnTask?.cancel() }
        }
    }

    // First tap speaks the card, second tap turns it. Every tap does something, so
    // the app never reads as broken — and a child never has to discover the swipe
    // to keep going.
    private func tapped() {
        turnTask?.cancel()
        if spoke && !settings.autoTurn {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.8)) { step(1) }
            return
        }
        onTap()
        spoke = true
        withAnimation(.spring(response: 0.2, dampingFraction: 0.45)) { pop = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pop = false }
        }
        if settings.autoTurn {
            // For a younger child: the card turns itself once the word has finished.
            // Tapping again just replays it and resets the wait, so hammering the
            // card is rewarded rather than punished.
            let t = DispatchWorkItem {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.8)) { step(1) }
            }
            turnTask = t
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: t)
        }
    }

    private func step(_ d: Int) {
        guard count > 0 else { return }
        index = (index + d + count) % count
        onAdvance?()
    }

    /// One small slide-and-return when a deck opens: a wordless demonstration that
    /// the card moves sideways. Shown once, never repeated.
    private func hintOnce(_ width: CGFloat) {
        guard !hinted, count > 1 else { return }
        hinted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeInOut(duration: 0.42)) { drag = CGSize(width: -46, height: 0) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.62)) { drag = .zero }
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .noBackSwipe()
    }
}

/// Card numbers are plain integers, but each deck owns a range, so a bare number
/// still says which deck it came from without anyone having to type a letter.
enum CardIds {
    static let photos    = 1        // 1–999
    static let drawings  = 1000     // 1000–1999
    static let words     = 2000     // 2000–2999
    static let sentences = 3000     // 3000–3999
    static let letters   = 4000     // 4000–4099
    static let heart     = 4100     // 4100–4199
    static let blending  = 5000     // 5000–5999
}

/// A small stable label so a specific card can be named out loud — "142" rather
/// than "the one that says sit with two children in it". The number comes from the
/// CONTENT order, never the shuffled order, so it means the same thing on every
/// launch and on every device. Toggleable in the grown-ups' area.
struct CardTag: View {
    let id: Int
    @Environment(Settings.self) private var settings
    var body: some View {
        if settings.showCardIds {
            Text("\(id)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.inkSoft.opacity(0.55))
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Theme.ground.opacity(0.6))
                .clipShape(Capsule())
        }
    }
}

/// One card face for every screen shape. The picture takes all the room that is
/// left after the caption, and scales to fit it — so a tall portrait card gives a
/// tall picture and a short landscape card gives a short one, with no branch and
/// nothing to get the wrong way round. Portrait is never compromised to serve
/// landscape, because there is only one layout.
struct AdaptiveCard<Art: View, Caption: View>: View {
    @ViewBuilder var art: () -> Art
    @ViewBuilder var caption: () -> Caption

    var body: some View {
        VStack(spacing: 18) {
            art()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            caption()
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
    }
}
