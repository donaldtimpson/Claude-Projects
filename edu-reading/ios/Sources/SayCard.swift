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

    @Environment(Settings.self) private var settings
    @State private var listener = Listener()
    @State private var celebrate = false

    private let sight = ReadingContent.shared.sightSet

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                if settings.listenForVoice {
                    Circle()
                        .stroke(accent.opacity(listener.state == .off ? 0.12 : 0.34),
                                lineWidth: 3)
                        // Fixed footprint, grown by scaleEffect not by frame: a
                        // transform doesn't reflow, so a loud mic pulses the ring
                        // without pushing the card's edge off screen.
                        .frame(width: 250, height: 250)
                        .scaleEffect(1 + CGFloat(listener.level) * 0.32)
                        .animation(.easeOut(duration: 0.12), value: listener.level)
                }
                if celebrate { ReadItCelebration(accent: accent) }
                Group {
                    if sentence {
                        phonicsSentence(text, size: size, sight: sight)
                            .multilineTextAlignment(.center)
                    } else {
                        phonics(text, size: size)
                    }
                }
                .scaleEffect(celebrate ? 1.18 : 1)
                .padding(.horizontal, 10)
            }
            if let caption {
                Text(caption).font(.andika(15)).foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(24)
        .onAppear { start() }
        .onDisappear { listener.stop() }
        .onChange(of: text) { start() }
        .onChange(of: settings.listenForVoice) { start() }
    }

    private func start() {
        celebrate = false
        listener.stop()
        guard settings.listenForVoice, Listener.isAuthorized else { return }
        let target = text.split(separator: " ").count > 1
            ? text.split(separator: " ").map(String.init).last ?? text : text
        listener.listen(for: target) {
            // The whole reward, all at once: a felt yes (haptic), a heard yes
            // (chime), and a seen yes (the burst + word pop). Never a "no" — see
            // Listener: a non-match is silent, so this only ever congratulates.
            Buzz.yes()
            Voice.shared.celebrate()
            withAnimation(.spring(response: 0.34, dampingFraction: 0.45)) { celebrate = true }
            // Let it land. Progressing instantly (flipping to the picture) is what
            // made success feel like nothing happened; hold the moment, then move on.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { onSaid?() }
        }
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
