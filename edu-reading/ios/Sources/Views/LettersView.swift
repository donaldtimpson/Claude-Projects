import SwiftUI

// No pictures on purpose: "A is for Apple" builds a letter -> picture -> NAME link
// and trains guessing from images. This teaches the sound.
//
// The teaching order is s a t p i n first, so after six letters a child can read
// sat, pat, tap, nap, pin, tin, sit. Sets follow on automatically — there is
// nothing here for a child to choose, and so nothing to tap uselessly.
struct LettersView: View {
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0xF0A93B)
    var start: Int = 0
    @State private var index = 0

    private var pool: [ReadingContent.Letter] {
        c.letters.sorted { ($0.set, $0.upper) < ($1.set, $1.upper) }
    }

    var body: some View {
        DeckScreen(title: "Letters", count: pool.count, index: $index, accent: accent) { i in
            let l = pool[i]
            VStack(spacing: 20) {
                Spacer()
                (phonics(l.upper, size: 108) + phonics(l.lower, size: 132)).kerning(6)
                Text("\(l.sound)  as in \(l.asIn)")
                    .font(.andika(20, bold: true)).foregroundStyle(accent)
                Spacer()
                // Aimed at the adult holding the phone: "buh-a-tuh" never blends
                // into "bat", and that one habit stalls more readers than anything.
                Text("say \(l.sound), not “\(l.avoid)”")
                    .font(.andika(13)).foregroundStyle(Theme.inkSoft)
            }
            .padding(24)
        } onTap: { i in
            if Voice.shared.hasRecording(pool[i].sound) { Voice.shared.say(pool[i].sound) }
            progress.learn(letter: pool[i].lower)
        }
        .onAppear { index = start; progress.learn(letter: pool[start % pool.count].lower) }
    }
}
