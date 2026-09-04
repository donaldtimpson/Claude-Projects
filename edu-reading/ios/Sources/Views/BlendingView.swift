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

    // Flattened so every family runs on into the next: one long swipe-through,
    // no picker.
    private var rimeCards: [(onset: String, rime: String, word: String)] {
        c.rimes.flatMap { fam in
            [(onset: "", rime: fam.rime, word: fam.rime)] +
            fam.words.map { (onset: String($0.dropLast(fam.rime.count)), rime: fam.rime, word: $0) }
        }
    }
    private var count: Int { settings.rimeBlending ? rimeCards.count : c.cvBlends.count }

    var body: some View {
        DeckScreen(title: "Blending", count: count, index: $index, accent: accent) { i in
            if settings.rimeBlending {
                let card = rimeCards[i]
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
                SayCard(text: c.cvBlends[i].text, size: 118, accent: accent,
                        caption: "Stretch the first sound into the second.")
            }
        } onTap: { i in
            let w = settings.rimeBlending ? rimeCards[i].word : c.cvBlends[i].text
            Voice.shared.say(w)
            if settings.rimeBlending { progress.learn(word: w) }
        }
        .onChange(of: settings.rimeBlending) { index = 0 }
    }
}
