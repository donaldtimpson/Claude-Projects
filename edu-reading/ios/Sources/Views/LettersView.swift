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

    // Reshuffled on every open (see shuffledWithin). Sets stay in teaching order;
    // the order inside a set is arbitrary, so it is randomised.
    @State private var pool: [ReadingContent.Letter] = []

    /// Content order, so the number is stable however the deck is shuffled.
    private func letterId(_ l: ReadingContent.Letter) -> Int {
        (c.letters.firstIndex(of: l) ?? 0) + 1
    }

    private func makePool() -> [ReadingContent.Letter] {
        #if DEBUG
        // A fixed start index is only used by the screenshot router, and it needs a
        // stable deck to address.
        if start > 0 { return c.letters.sorted { ($0.set, $0.upper) < ($1.set, $1.upper) } }
        #endif
        return shuffledWithin(c.letters) { $0.set }
    }

    var body: some View {
        DeckScreen(title: "Letters", count: pool.count, index: $index, accent: accent) { i in
            let l = pool[min(i, pool.count - 1)]
            VStack(spacing: 20) {
                HStack { Spacer(); CardTag(id: CardIds.letters + letterId(l)) }
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
        } onTap: { i in
            guard i < pool.count else { return }
            if Voice.shared.hasRecording(pool[i].sound) { Voice.shared.say(pool[i].sound) }
            progress.learn(letter: pool[i].lower)
        }
        .onAppear {
            if pool.isEmpty { pool = makePool() }
            index = start
            if !pool.isEmpty { progress.learn(letter: pool[start % pool.count].lower) }
        }
    }
}
