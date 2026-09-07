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
    /// False on decks with nothing to play. Two taps only make sense when the
    /// first one DOES something: with no audio the first tap is silently dead and
    /// the card feels broken, so a single tap moves on instead.
    var speaks: Bool = true
    @ViewBuilder var content: (Int) -> Content

    @Environment(Settings.self) private var settings
    private let skin = Skin.current
    @State private var drag: CGSize = .zero
    @State private var pop = false
    @State private var spoke = false      // has this card been tapped once yet
    /// Taps land during the word and are simply thrown away, so a fast tapper
    /// spends half of them replaying the card instead of moving on — which reads
    /// as the card refusing to advance. Ignored until the word has finished.
    @State private var armed = true
    /// Which way the last move went, so the card turns in from the side it came
    /// from: advance and it swings in from the right, go back and from the left.
    @State private var lastDir: Int = 1
    @State private var hinted = false
    @State private var turnTask: DispatchWorkItem?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                skin.ground(accent).ignoresSafeArea()

                // The card is visibly a DECK: two more behind it, peeking below and
                // to the right. A child who taps and taps has usually just not been
                // told there is anything else — a stack says so without words.
                ForEach([2, 1], id: \.self) { back in
                    // Face down, so the theme is on screen the whole time. This is
                    // the biggest themeable surface in the app and it was blank.
                    // Fanned rather than stacked square, so the patterned backs are
                    // actually SEEN. Squared up they sat entirely behind the top
                    // card and the theme they carry was invisible.
                    CardBack(radius: skin.cardRadius)
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .scaleEffect(1 - CGFloat(back) * 0.02)
                        .rotationEffect(.degrees(Double(back) * (back == 1 ? 3.4 : -3.4)),
                                        anchor: .bottom)
                        .offset(y: CGFloat(back) * 5)
                }

                if count > 0 {
                    // The flip is a TRANSITION, not a state machine I drive myself.
                    // Two hand-rolled attempts failed silently: step() is called
                    // inside a withAnimation and the manual "snap face down" kept
                    // being swallowed by that transaction. Letting SwiftUI own the
                    // animation removes the whole class of problem.
                    //
                    // Edge-on the card is invisible, and what shows through is the
                    // fanned card BACK behind it — so the back is revealed by the
                    // turn without needing to be drawn twice.
                    content(index % count)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .modifier(CardSurfaceStyle(skin: skin))
                        .id(index)
                        .transition(.asymmetric(
                            // In: swings up from edge-on, on the side it travelled
                            // from. Out: turns AND leaves. Rotating the outgoing
                            // card edge-on in place made it vanish where it stood
                            // rather than go anywhere, which read as a card simply
                            // disappearing — the deal had no sense of direction.
                            insertion: .modifier(active: Flip(angle: Double(lastDir) * 88),
                                                 identity: Flip(angle: 0)),
                            removal: .modifier(active: Flip(angle: Double(-lastDir) * 70),
                                               identity: Flip(angle: 0))
                                .combined(with: .offset(x: CGFloat(-lastDir) * 420))
                                .combined(with: .opacity)))
                        .padding(.horizontal, 26)
                        .padding(.vertical, 24)
                        .offset(x: drag.width, y: drag.height * 0.2)
                        .rotationEffect(.degrees(Double(drag.width / 30)))
                        .scaleEffect(pop ? 1.03 : 1)
                        .gesture(
                            DragGesture(minimumDistance: 14)
                                .onChanged { drag = $0.translation }
                                .onEnded { v in
                                    let far = abs(v.translation.width) > geo.size.width * 0.2
                                    let dir = v.translation.width < 0 ? 1 : -1
                                    if far { lastDir = dir }
                                    withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                                        drag = .zero
                                        if far { step(dir) }
                                    }
                                }
                        )
                        .onTapGesture { tapped() }
                }
            }
            .onAppear {
                hintOnce(geo.size.width)
                #if DEBUG
                // Screenshot only: advance on a timer so the flip can be caught
                // mid-turn instead of taken on trust.
                if ProcessInfo.processInfo.arguments.contains("-autoflip") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { step(1) }
                }
                #endif
            }
            .onChange(of: index) { spoke = false; armed = true; turnTask?.cancel() }
            .onDisappear { turnTask?.cancel() }
        }
    }

    // First tap speaks the card, second tap turns it. Every tap does something, so
    // the app never reads as broken — and a child never has to discover the swipe
    // to keep going.
    /// One place for the turn's timing, and slowed right down for screenshots so a
    /// transient animation can actually be looked at rather than taken on trust.
    static var turn: Animation {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-slowflip") {
            return .easeInOut(duration: 2.5)
        }
        #endif
        return .easeInOut(duration: 0.42)
    }

    private func tapped() {
        turnTask?.cancel()
        guard armed else { return }
        guard speaks else {
            onTap()
            withAnimation(Self.turn) { step(1) }
            return
        }
        if spoke && !settings.autoTurn {
            withAnimation(Self.turn) { step(1) }
            return
        }
        onTap()
        spoke = true
        armed = false
        // Re-armed when the word finishes, or after a beat if nothing was spoken.
        Voice.shared.whenIdle { armed = true }
        withAnimation(.spring(response: 0.2, dampingFraction: 0.45)) { pop = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pop = false }
        }
        if settings.autoTurn {
            // For a younger child: the card turns itself once the word has finished.
            // Tapping again just replays it and resets the wait, so hammering the
            // card is rewarded rather than punished.
            let t = DispatchWorkItem {
                withAnimation(Self.turn) { step(1) }
            }
            turnTask = t
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: t)
        }
    }

    private func step(_ d: Int) {
        guard count > 0 else { return }
        lastDir = d
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
                    .fill(active ? accent : accent.mixed(with: Theme.ground, amount: 0.62))
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
    /// Present only on decks where the order carries meaning — counting, and the
    /// teaching order of the letters. Everywhere else there is nothing to be in
    /// order OF, and a control that does nothing is worse than no control.
    var ordered: Binding<Bool>? = nil
    /// See CardStack.speaks — decks with no audio advance on a single tap.
    var speaks: Bool = true
    @ViewBuilder var content: (Int) -> Content
    var onTap: (Int) -> Void
    var onAdvance: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    private let skin = Skin.current

    /// Present only on decks where the order carries meaning — counting, and the
    /// teaching order of the letters. Everywhere else there is nothing to be in
    /// order OF, and a control that does nothing is worse than no control.


    var body: some View {
        VStack(spacing: 0) {
            CardStack(count: count, index: $index, accent: accent,
                      onTap: { if count > 0 { onTap(index % count) } },
                      onAdvance: onAdvance, speaks: speaks) { i in
                content(i)
            }
            Dots(count: count, index: count > 0 ? index % count : 0, accent: accent)
                .padding(.bottom, 10)
        }
        .background(skin.ground(accent).ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            BackChevron { dismiss() }
                .padding(.leading, 10)
                .padding(.top, 6)
        }
        .overlay(alignment: .topTrailing) {
            if let ordered {
                // Mirrors the back button rather than adding a segmented control:
                // one adult-sized tap target, and the icon says which mode you are
                // in rather than which you would switch to.
                OrderToggle(ordered: ordered)
                    .padding(.trailing, 10)
                    .padding(.top, 6)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
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
    static let colors    = 6000     // 6000–6099
    static let shapes    = 6100     // 6100–6199
    static let numbers   = 6200     // 6200–6299
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
                .background(Theme.ground)
                .clipShape(Capsule())
        }
    }
}

/// One card face for every screen shape: the picture fills everything above a
/// fixed band, and the word sits in the band. One layout, so it cannot render the
/// wrong way round, and a tall card simply yields a taller picture.
///
/// The picture BLEEDS to the card's edges. The earlier version floated a small
/// picture inside a large white card, and that dead white space is what read as
/// flat — not the colours. A flashcard is a picture with a word under it.
struct AdaptiveCard<Art: View, Caption: View>: View {
    /// The picture's width-over-height, when the caller knows it. Given one, the
    /// card takes the full width and its HEIGHT hugs the picture — so a wide photo
    /// makes a short card and there is almost no mat, without cropping anything.
    var aspect: CGFloat? = nil
    @ViewBuilder var art: () -> Art
    @ViewBuilder var caption: () -> Caption

    private let skin = Skin.current

    var body: some View {
        GeometryReader { geo in
            let band = min(max(geo.size.height * 0.21, 66), 118)
            let maxArt = geo.size.height - band
            let artHeight: CGFloat = {
                guard let aspect, aspect > 0 else { return maxArt }
                return min(geo.size.width / aspect, maxArt)
            }()
            VStack(spacing: 0) {
                art()
                    .frame(width: geo.size.width, height: artHeight)
                    .clipped()
                Rectangle().fill(skin.cardEdge).frame(height: 1)
                caption()
                    .frame(width: geo.size.width, height: band)
                    .background(Skin.live.band)
            }
            // Centred, so a short card sits in the middle rather than at the top.
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
    }
}


/// The way out of a deck. Translucent on purpose: the card fills most of the
/// screen, so a solid disc would punch a hole in the picture.
struct BackChevron: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 42, height: 42)      // a full touch target
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .modifier(GlassCircle())
    }
}

struct GlassCircle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: .circle)
        } else {
            content
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Theme.ink.opacity(0.10), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
        }
    }
}


/// In-order or shuffled. Deliberately the same shape and glass as the back button,
/// so the two adult controls read as a pair sitting above the child's card.
struct OrderToggle: View {
    @Binding var ordered: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { ordered.toggle() }
        } label: {
            Image(systemName: ordered ? "list.number" : "shuffle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 42, height: 42)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .modifier(GlassCircle())
        .accessibilityLabel(ordered ? "In order" : "Shuffled")
    }
}


/// Half a turn about the vertical axis. Used as a transition, so SwiftUI animates
/// it: at ninety degrees the card is edge-on and invisible, and the fanned card
/// BACK behind it shows through — which is how the back gets revealed by the turn.
struct Flip: ViewModifier {
    let angle: Double
    func body(content: Content) -> some View {
        content.rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
    }
}
