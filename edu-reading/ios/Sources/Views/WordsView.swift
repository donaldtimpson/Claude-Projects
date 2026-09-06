import SwiftUI

// The levels run CVC -> digraphs -> blends -> silent e in one continuous deck.
// A child does not choose a phonics level, so there is no picker; the deck simply
// gets harder as it goes.
//
// Tap flips the card. On the ~4 words in 5 that can be drawn, the picture confirms.
// On sat, chat, mud it speaks instead — a recording works for every word, a picture
// does not, and that is the honest limit of picture-based self-check.
struct WordsView: View {
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0x3B7EA1)
    @State private var index = 0
    @State private var flipped = false

    // Levels keep their order — a child who has done "cat" is not ready for
    // "strength" — but the words inside a level are shuffled on every open.
    @State private var pool: [ReadingContent.Word] = []

    private func wordId(_ w: ReadingContent.Word) -> Int {
        (c.words.firstIndex(of: w) ?? 0) + 1
    }

    private func makePool() -> [ReadingContent.Word] {
        let order = c.wordLevels
        return shuffledWithin(c.words) { order.firstIndex(of: $0.level) ?? 9 }
    }

    var body: some View {
        DeckScreen(title: "Words", count: pool.count, index: $index, accent: accent) { i in
            let w = pool[min(i, pool.count - 1)]
            ZStack {
                if flipped {
                    VStack(spacing: 16) {
                        Spacer()
                        if let img = w.image {
                            Text(img).font(.system(size: 160))
                        } else {
                            Image(systemName: "speaker.wave.2.circle.fill")
                                .font(.system(size: 96)).foregroundStyle(accent)
                        }
                        phonics(w.word, size: 52)
                        Spacer()
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    SayCard(text: w.word, size: 118, accent: accent) {
                        progress.readWord( w.word)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { flipped = true }
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                CardTag(id: CardIds.words + wordId(w)).padding(14)
            }
        } onTap: { i in
            // First tap reveals and speaks; CardStack turns the card on the second.
            guard i < pool.count else { return }
            let w = pool[i]
            Voice.shared.say(w.word)
            progress.readWord( w.word)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { flipped = true }
        } onAdvance: {
            flipped = false
        }
        .onAppear { if pool.isEmpty { pool = makePool() } }
    }
}
