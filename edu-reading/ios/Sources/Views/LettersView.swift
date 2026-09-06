import SwiftUI

// No pictures on purpose: "A is for Apple" builds a letter -> picture -> NAME link
// and trains guessing from images. This teaches the sound.
//
// A to Z in order, or shuffled — chosen with the toggle. Nothing here for a child
// to choose, and so nothing to tap uselessly.
struct LettersView: View {
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0xF0A93B)
    var start: Int = 0
    @State private var index = 0
    @State private var ordered = true

    // Rebuilt on every open, and whenever the toggle changes.
    @State private var pool: [ReadingContent.Letter] = []

    /// Content order, so the number is stable however the deck is shuffled.
    private func letterId(_ l: ReadingContent.Letter) -> Int {
        (c.letters.firstIndex(of: l) ?? 0) + 1
    }

    /// In order means A to Z. It was previously the phonics teaching order
    /// (s a t p i n first), which is defensible on paper and unreadable as a
    /// button: a parent presses "in order" and expects the alphabet. Shuffle is
    /// there for when they want something else.
    private func makePool() -> [ReadingContent.Letter] {
        let alphabetical = c.letters.sorted { $0.upper < $1.upper }
        #if DEBUG
        if start > 0 { return alphabetical }
        #endif
        return ordered ? alphabetical : c.letters.shuffled()
    }

    var body: some View {
        DeckScreen(title: "Letters", count: pool.count, index: $index, accent: accent,
                   ordered: $ordered) { i in
            let l = pool[min(i, pool.count - 1)]
            VStack(spacing: 20) {
                Spacer()
                // Both letters at one nominal size, on a shared baseline. The
                // lowercase is trimmed only when its ascender would overshoot the
                // capital (see LetterFit) — separate Texts, because per-segment
                // sizes inside a Text concatenation are not reliably honoured.
                HStack(alignment: .lastTextBaseline, spacing: 12) {
                    phonics(l.upper, size: 132)
                    phonics(l.lower, size: 132 * LetterFit.lowerScale(upper: l.upper,
                                                                     lower: l.lower))
                }
                Text("\(l.sound)  as in \(l.asIn)")
                    .font(.andika(20, bold: true)).foregroundStyle(accent)
                Spacer()
                // Aimed at the adult holding the phone: "buh-a-tuh" never blends
                // into "bat", and that one habit stalls more readers than anything.
                Text("say \(l.sound), not “\(l.avoid)”")
                    .font(.andika(13)).foregroundStyle(Theme.inkSoft)
            }
            .padding(24)
            .overlay(alignment: .bottomTrailing) {
                CardTag(id: CardIds.letters + letterId(l)).padding(14)
            }
        } onTap: { i in
            guard i < pool.count else { return }
            if Voice.shared.hasRecording(pool[i].sound) { Voice.shared.say(pool[i].sound) }
            progress.learn(letter: pool[i].lower)
        }
        .onChange(of: ordered) { index = 0; pool = makePool() }
        .onAppear {
            if pool.isEmpty { pool = makePool() }
            index = start
            if !pool.isEmpty { progress.learn(letter: pool[start % pool.count].lower) }
        }
    }
}
