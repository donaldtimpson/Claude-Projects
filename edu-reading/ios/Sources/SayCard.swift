import SwiftUI

/// The shared face for any card whose job is "read this out loud".
///
/// When voice is on it listens the whole time the card is up. The ring around the
/// word breathes with the microphone so the child can see they are being heard —
/// and, crucially, nothing on this card can ever report a failure.
struct SayCard: View {
    let text: String
    var size: CGFloat = 118
    var sentence: Bool = false
    var accent: Color = Theme.go
    var caption: String? = nil
    var onSaid: (() -> Void)? = nil

    private let sight = ReadingContent.shared.sightSet

    /// A sentence is matched on its last word — that's the one being sounded out.
    private var target: String {
        let parts = text.split(separator: " ").map(String.init)
        return parts.count > 1 ? (parts.last ?? text) : text
    }

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Group {
                if sentence {
                    phonicsSentence(text, size: size, sight: sight)
                        .multilineTextAlignment(.center)
                } else {
                    // A word is always one line — a longer word (grape, jumping)
                    // shrinks to fit rather than breaking across two lines.
                    phonics(text, size: size)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(.horizontal, 10)
            .listensToSay(target, accent: accent, pop: 1.18) { onSaid?() }
            if let caption {
                Text(caption).font(.andika(15)).foregroundStyle(Skin.live.cardInkSoft)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(24)
    }
}

/// Listen-and-celebrate, factored out of SayCard so ANY card can adopt it: the
/// pulsing mic ring, the "you read it!" burst and sound, the success haptic, and
/// the safe start/stop of the recogniser. Attach with `.listensToSay(word) { … }`.
///
/// It stays true to Listener's one rule — it can only ever say yes. A match
/// celebrates and, after a beat for the moment to land, calls onMatch (turn a card,
/// advance a deck). A non-match does nothing at all. Silent and inert when voice is
/// off or unauthorised, so a card that adopts it is unchanged for anyone not using it.
struct ListenToSay: ViewModifier {
    let word: String
    var accent: Color = Theme.go
    /// How much the hosted content pops on a match — a big word wants more than a
    /// whole card does.
    var pop: CGFloat = 1.06
    /// Draw the ring and celebration OVER the content rather than behind it. A bare
    /// word (SayCard) reads best with them behind; an opaque picture card would hide
    /// them entirely, so those decks put the indicator in front.
    var inFront: Bool = false
    let onMatch: () -> Void

    @Environment(Settings.self) private var settings
    @State private var listener = Listener()
    @State private var celebrate = false
    @State private var hold: DispatchWorkItem?

    func body(content: Content) -> some View {
        Group {
            if inFront {
                // Opaque picture cards can't show a ring behind them, and a ring
                // drawn across the art looks wrong — so they get a compact listening
                // pill at the top, with the celebration over the card on a match.
                content.scaleEffect(celebrate ? pop : 1)
                    .overlay(alignment: .top) {
                        if settings.listenForVoice {
                            ListeningPill(level: listener.level,
                                          active: listener.state != .off, accent: accent)
                                .padding(.top, 16)
                        }
                    }
                    .overlay { if celebrate { ReadItCelebration(accent: accent).allowsHitTesting(false) } }
            } else {
                // A bare word reads best with the ring breathing around it, behind.
                ZStack {
                    if settings.listenForVoice { ring }
                    if celebrate { ReadItCelebration(accent: accent) }
                    content.scaleEffect(celebrate ? pop : 1)
                }
            }
        }
        .onAppear { start() }
        .onDisappear { stop() }
        .onChange(of: word) { start() }
        .onChange(of: settings.listenForVoice) { start() }
    }

    private var ring: some View {
        Circle()
            .stroke(accent.opacity(listener.state == .off ? 0.12 : 0.34), lineWidth: 3)
            // Fixed footprint, grown by scaleEffect not by frame: a transform doesn't
            // reflow, so a loud mic pulses the ring without pushing the card off screen.
            .frame(width: 250, height: 250)
            .scaleEffect(1 + CGFloat(listener.level) * 0.32)
            .animation(.easeOut(duration: 0.12), value: listener.level)
            .allowsHitTesting(false)
    }

    private func start() {
        stop()
        celebrate = false
        guard settings.listenForVoice, Listener.isAuthorized, !word.isEmpty else { return }
        listener.listen(for: word) {
            DispatchQueue.main.async {
                // The whole reward at once: a felt yes (haptic), a heard yes (the
                // fanfare), a seen yes (the burst + pop).
                Buzz.yes()
                Voice.shared.celebrate()
                withAnimation(.spring(response: 0.34, dampingFraction: 0.45)) { celebrate = true }
                // Hold the moment before the caller moves on — progressing instantly
                // is what made success feel like nothing happened.
                let h = DispatchWorkItem { onMatch() }
                hold = h
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9, execute: h)
            }
        }
    }

    private func stop() {
        hold?.cancel(); hold = nil
        listener.stop()
    }
}

extension View {
    /// Listen for the child to say `word`, and celebrate + call `onMatch` when they
    /// do. See ListenToSay.
    func listensToSay(_ word: String, accent: Color = Theme.go, pop: CGFloat = 1.06,
                      inFront: Bool = false, onMatch: @escaping () -> Void) -> some View {
        modifier(ListenToSay(word: word, accent: accent, pop: pop, inFront: inFront, onMatch: onMatch))
    }
}

/// A quiet "I'm listening" badge — a mic and three little bars that rise with the
/// input level. Sits at the top of a picture card, where a ring drawn across the art
/// looked wrong, and gives the same "the mic hears you" feedback the ring gives words.
struct ListeningPill: View {
    let level: Double
    let active: Bool
    let accent: Color

    var body: some View {
        HStack(spacing: 3.5) {
            Image(systemName: "mic.fill").font(.system(size: 12, weight: .bold))
            ForEach(0..<3, id: \.self) { i in
                Capsule().frame(width: 3, height: bar(i))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(accent.opacity(active ? 0.9 : 0.5), in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
        .animation(.easeOut(duration: 0.12), value: level)
        .allowsHitTesting(false)
    }

    private func bar(_ i: Int) -> CGFloat {
        let mult: [CGFloat] = [0.7, 1.0, 0.55]
        return 5 + CGFloat(level) * 15 * mult[i]
    }
}

/// The "you read it!" moment, shown only on a match. A warm glow blooms behind the
/// word, a ring rides outward like a dropped-pebble ripple, and confetti — dots and
/// little stars in the phonics palette — flings out in every direction. It says
/// yes without words, so it never talks over the child or goes stale as praise does.
struct ReadItCelebration: View {
    let accent: Color
    @State private var go = false

    private var palette: [Color] { [Theme.vowel, Theme.go, Theme.heart, accent] }

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.heart)
                .frame(width: 200, height: 200)
                .blur(radius: 45)
                .scaleEffect(go ? 1.5 : 0.6)
                .opacity(go ? 0 : 0.55)

            Circle()
                .stroke(Theme.heart, lineWidth: 4)
                .frame(width: 150, height: 150)
                .scaleEffect(go ? 2.3 : 0.5)
                .opacity(go ? 0 : 0.85)

            ForEach(0..<16, id: \.self) { i in confetto(i) }
        }
        .allowsHitTesting(false)
        .onAppear { withAnimation(.easeOut(duration: 0.9)) { go = true } }
    }

    @ViewBuilder private func confetto(_ i: Int) -> some View {
        let angle = (Double(i) / 16 * 360 + (i.isMultiple(of: 2) ? 0 : 11)) * .pi / 180
        let dist: CGFloat = i % 3 == 0 ? 138 : (i % 3 == 1 ? 104 : 122)
        let sz: CGFloat = i % 4 == 0 ? 15 : 10
        let color = palette[i % palette.count]
        Group {
            if i % 3 == 0 {
                Image(systemName: "star.fill").font(.system(size: sz + 3)).foregroundStyle(color)
            } else {
                Circle().fill(color).frame(width: sz, height: sz)
            }
        }
        .offset(x: go ? cos(angle) * dist : 0, y: go ? sin(angle) * dist : 0)
        .rotationEffect(.degrees(go ? Double(i) * 40 : 0))
        .scaleEffect(go ? 0.4 : 1)
        .opacity(go ? 0 : 1)
    }
}
