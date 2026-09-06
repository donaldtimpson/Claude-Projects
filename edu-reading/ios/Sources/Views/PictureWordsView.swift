import SwiftUI
import UIKit

// Two decks, split on Donald's call after testing: photographs and drawings are
// separate rather than interleaved. The drawings are reliably legible; the
// photographs are not yet, and mixing them meant a bad photograph interrupted a
// good deck. Kept as one view because the only difference is which pictures it
// draws from.
//
// The word sits small at the bottom FOR THE ADULT, so they know which word the
// picture is prompting. The child is building spoken vocabulary, which is the
// strongest predictor of later comprehension — this is not step one of reading.
//
// Each picture is its own card, dealt in rounds so every word appears once before
// any word appears twice: meeting an unfamiliar dog thirty cards later asks the
// child to recognise the CATEGORY, which is the whole point of having several.
struct PictureWordsView: View {
    let drawings: Bool

    @Environment(Settings.self) private var settings
    private let c = ReadingContent.shared
    private var accent: Color { drawings ? Color(hex: 0xC77CB0) : Color(hex: 0xD9646E) }

    private struct Card: Hashable { let word: String; let variant: Int; let id: Int }

    @State private var pool: [Card] = []
    @State private var index = 0

    var body: some View {
        DeckScreen(title: drawings ? "Drawings" : "Photos", count: pool.count,
                   index: $index, accent: accent) { i in
            let card = pool[min(i, max(pool.count - 1, 0))]
            let p = c.pictureWords.first { $0.word == card.word }
            // Stacked in portrait, side-by-side in landscape — a short wide card
            // has no room for a big picture above a word.
            AdaptiveCard {
                if drawings {
                    if let p, !p.images.isEmpty {
                        // An emoji is a glyph, so it cannot be resized to fit a
                        // box — scale it down from a large size instead.
                        Text(p.images[card.variant % p.images.count])
                            .font(.system(size: 200))
                            .minimumScaleFactor(0.3)
                            .lineLimit(1)
                    }
                } else if let art = photo(card.word, card.variant) {
                    Image(uiImage: art)
                        .resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            } caption: {
                if settings.showWordOnPictures {
                    phonics(card.word, size: 34).opacity(0.75)
                }
            }
            .overlay(alignment: .topTrailing) { CardTag(id: card.id).padding(18) }
        } onTap: { i in
            guard i < pool.count else { return }
            Voice.shared.say(pool[i].word)
        }
        .onAppear { if pool.isEmpty { pool = makePool() } }
    }

    private func photoCount(_ word: String) -> Int {
        guard UIImage(named: word) != nil else { return 0 }
        var n = 1
        while UIImage(named: "\(word)-\(n + 1)") != nil, n < 6 { n += 1 }
        return n
    }

    private func photo(_ word: String, _ variant: Int) -> UIImage? {
        variant == 0 ? UIImage(named: word) : UIImage(named: "\(word)-\(variant + 1)")
    }

    /// Ids are assigned by walking the content in order, so a card's number is the
    /// same on every launch and every device no matter how the deck is shuffled.
    private func makePool() -> [Card] {
        var cards: [Card] = []
        var next = 0
        for p in c.pictureWords {
            let n = drawings ? p.images.count : photoCount(p.word)
            for v in 0..<n {
                let base = drawings ? CardIds.drawings : CardIds.photos
                cards.append(Card(word: p.word, variant: v, id: base + next)); next += 1
            }
        }
        // then dealt in rounds and shuffled within each round
        let deepest = cards.reduce(into: [String: Int]()) { $0[$1.word, default: 0] += 1 }
        let maxRounds = deepest.values.max() ?? 1
        var out: [Card] = []
        for round in 0..<maxRounds {
            out.append(contentsOf: cards.filter { $0.variant == round }.shuffled())
        }
        return out
    }
}
