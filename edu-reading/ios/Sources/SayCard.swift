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
                        .frame(width: 250 + CGFloat(listener.level) * 80,
                               height: 250 + CGFloat(listener.level) * 80)
                        .animation(.easeOut(duration: 0.12), value: listener.level)
                }
                if celebrate { Sparkle(accent: accent) }
                Group {
                    if sentence {
                        phonicsSentence(text, size: size, sight: sight)
                            .multilineTextAlignment(.center)
                    } else {
                        phonics(text, size: size)
                    }
                }
                .scaleEffect(celebrate ? 1.12 : 1)
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
            withAnimation(.spring(response: 0.32, dampingFraction: 0.5)) { celebrate = true }
            Voice.shared.chime()
            onSaid?()
        }
    }
}
