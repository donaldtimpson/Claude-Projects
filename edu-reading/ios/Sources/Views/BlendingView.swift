import SwiftUI

// Variant chosen in the grown-ups' area, not here.
//
// A (fa/fe/fi) works beautifully in Spanish, where vowels say one thing; English
// open syllables are unstable, so the "fa" in fat is not the "fa" in fable.
// B builds on the rime — a unit English keeps stable — and hands over a whole word
// family from one card. B is the default.
struct BlendingView: View {
    @Environment(Progress.self) private var progress
    @Environment(Settings.self) private var settings
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0x2E7D6E)
    @State private var index = 0

    // One long swipe-through, no picker. Families come up in a different order each
    // time, and so do the words inside them — but the bare rime always leads its own
    // family, since "at" is what the family is built from.
    @State private var rimeCards: [(onset: String, rime: String, word: String)] = []
    @State private var cvCards: [String] = []

    private func makePools() {
        rimeCards = c.rimes.shuffled().flatMap { fam in
            [(onset: "", rime: fam.rime, word: fam.rime)] +
            fam.words.shuffled().map {
                (onset: String($0.dropLast(fam.rime.count)), rime: fam.rime, word: $0)
            }
        }
        cvCards = c.cvBlends.map(\.text).shuffled()
    }
    private var count: Int { settings.rimeBlending ? rimeCards.count : cvCards.count }

    var body: some View {
        DeckScreen(title: "Blending", count: count, index: $index, accent: accent) { i in
            if settings.rimeBlending {
                let card = rimeCards[min(i, rimeCards.count - 1)]
                VStack(spacing: 26) {
                    Spacer()
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        if !card.onset.isEmpty { phonics(card.onset, size: 44).opacity(0.6) }
                        phonics(card.rime, size: 44).opacity(0.6)
                    }
                    SayCard(text: card.word, size: 106, accent: accent) {
                        progress.learn(word: card.word)
                    }
                    .frame(maxHeight: 250)
                    Spacer()
                }
            } else {
                SayCard(text: cvCards[min(i, cvCards.count - 1)], size: 118, accent: accent,
                        caption: "Stretch the first sound into the second.")
            }
        } onTap: { i in
            guard i < count else { return }
            let w = settings.rimeBlending ? rimeCards[i].word : cvCards[i]
            Voice.shared.say(w)
            if settings.rimeBlending { progress.learn(word: w) }
        }
        .onAppear { if rimeCards.isEmpty { makePools() } }
        .onChange(of: settings.rimeBlending) { index = 0; makePools() }
    }
}
