import SwiftUI
import UIKit

// Look and Say — the gentlest thing in the app, and the entry point for a child
// far too young for the rest of it. Big picture, tap to hear it, and on again.
//
// The word sits small at the bottom FOR THE ADULT, so they know which word the
// image is prompting; a grown-up can hide it. The child is building spoken
// vocabulary, which is the strongest predictor of later comprehension — this is
// not step one of reading, it runs alongside.
//
// Each photograph is its OWN card, and the three pictures of a pig are spread
// across the deck rather than stacked on one card. That matters: cycling three
// pigs in place is a slideshow, but meeting an unfamiliar pig twenty cards later
// asks the child to recognise the CATEGORY from a picture they have not seen.
// That is the whole point of having three.
struct PictureWordsView: View {
    @Environment(Settings.self) private var settings
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0xD9646E)

    private struct Card: Hashable { let word: String; let variant: Int; let drawing: Bool }

    @State private var pool: [Card] = []
    @State private var index = 0

    var body: some View {
        DeckScreen(title: "Look and Say", count: pool.count,
                   index: $index, accent: accent) { i in
            let card = pool[min(i, max(pool.count - 1, 0))]
            let p = c.pictureWords.first { $0.word == card.word }
            VStack(spacing: 24) {
                Spacer()
                if !card.drawing, let art = photo(card.word, card.variant) {
                    Image(uiImage: art)
                        .resizable().scaledToFit()
                        .frame(maxHeight: 330)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else if let p, !p.images.isEmpty {
                    Text(p.images[card.variant % p.images.count])
                        .font(.system(size: 190))
                }
                Spacer()
                if settings.showWordOnPictures {
                    phonics(card.word, size: 34).opacity(0.75)
                }
            }
            .padding(24)
        } onTap: { i in
            guard i < pool.count else { return }
            Voice.shared.say(pool[i].word)
        }
        .onAppear { if pool.isEmpty { pool = makePool() } }
        .onChange(of: settings.pictureStyle) { index = 0; pool = makePool() }
    }

    /// Photographs bundled for a word, in order.
    private func photoCount(_ word: String) -> Int {
        guard UIImage(named: word) != nil else { return 0 }
        var n = 1
        while UIImage(named: "\(word)-\(n + 1)") != nil, n < 6 { n += 1 }
        return n
    }

    private func photo(_ word: String, _ variant: Int) -> UIImage? {
        variant == 0 ? UIImage(named: word) : UIImage(named: "\(word)-\(variant + 1)")
    }

    /// How many cards a word contributes, and of which kind. Drawings come last so
    /// that in a mixed deck the photograph is met first and the icon later — the
    /// order that asks the child to generalise rather than to match.
    private func variants(_ p: ReadingContent.PictureWord) -> (photos: Int, drawings: Int) {
        switch settings.pictureStyle {
        case .photos:   return (photoCount(p.word), 0)
        case .drawings: return (0, p.images.count)
        case .both:     return (photoCount(p.word), p.images.count)
        }
    }

    /// Dealt in rounds, not shuffled flat: every word appears once before any word
    /// appears a second time. That spreads a word's pictures about a full deck
    /// apart, so no two pigs ever land near each other, and the deck still opens
    /// differently every time because each round is shuffled independently.
    private func makePool() -> [Card] {
        let counts = c.pictureWords.map { (p: $0, v: variants($0)) }
        let deepest = counts.map { max($0.v.photos, 0) + max($0.v.drawings, 0) }.max() ?? 1
        var out: [Card] = []
        for round in 0..<deepest {
            let thisRound: [Card] = counts.compactMap { entry in
                let (ph, dr) = entry.v
                if round < ph { return Card(word: entry.p.word, variant: round, drawing: false) }
                let d = round - ph
                if d < dr { return Card(word: entry.p.word, variant: d, drawing: true) }
                return nil
            }.shuffled()
            out.append(contentsOf: thisRound)
        }
        return out
    }
}
