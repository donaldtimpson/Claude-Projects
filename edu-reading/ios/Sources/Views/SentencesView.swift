import SwiftUI

// The rung most reading apps skip: words, then straight to a real book.
// "the" and "a" appear here rather than waiting for the sight-word deck, because
// without them a decodable sentence can only ever be "Sam sat."
struct SentencesView: View {
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0x7A5EA8)
    // No teaching order to protect here, so it is a straight reshuffle each open.
    @State private var pool: [ReadingContent.Sentence] = []
    @State private var index = 0

    var body: some View {
        DeckScreen(title: "Sentences", count: pool.count, index: $index, accent: accent) { i in
            let s = pool[min(i, pool.count - 1)]
            SayCard(text: s.text, size: 44, sentence: true, accent: accent) {
                collect(i)
            }
            .overlay(alignment: .topTrailing) {
                CardTag(id: CardIds.sentences + (c.sentences.firstIndex(of: s) ?? 0) + 1).padding(18)
            }
        } onTap: { i in
            Voice.shared.say(pool[min(i, pool.count - 1)].text)
            collect(i)
        }
        .onAppear { if pool.isEmpty { pool = c.sentences.shuffled() } }
    }

    private func collect(_ i: Int) {
        // Reading a sentence collects every decodable word in it, so the world
        // fills fastest exactly when things get exciting.
        for t in pool[min(i, pool.count - 1)].text.split(separator: " ") {
            let bare = t.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".!?,"))
            if !bare.isEmpty && !c.sightSet.contains(bare) { progress.learn(word: bare) }
        }
    }
}
