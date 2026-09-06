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
    /// Which deck this is. Nil means every word, which is only used by the
    /// screenshot router.
    var deck: String? = nil

    @Environment(Settings.self) private var settings
    private let c = ReadingContent.shared
    private var accent: Color { DeckStyle.accent(for: deck) }

    private struct Card: Hashable { let word: String; let variant: Int; let id: Int; let drawing: Bool }

    @State private var pool: [Card] = []
    @State private var index = 0

    var body: some View {
        DeckScreen(title: deck ?? "Look and Say", count: pool.count,
                   index: $index, accent: accent) { i in
            let card = pool[min(i, max(pool.count - 1, 0))]
            let p = c.pictureWords.first { $0.word == card.word }
            // Stacked in portrait, side-by-side in landscape — a short wide card
            // has no room for a big picture above a word.
            AdaptiveCard {
                if card.drawing {
                    if let p, !p.images.isEmpty {
                        // A glyph cannot be resized like an image, so measure the
                        // space and pick a point size that fills it. It sits on a
                        // faint wash of the deck's colour rather than bare white,
                        // so a drawing card has the same weight as a photo card.
                        GeometryReader { geo in
                            ZStack {
                                Theme.paper.mixed(with: accent, amount: 0.10)
                                Text(p.images[card.variant % p.images.count])
                                    .font(.system(size: min(geo.size.width, geo.size.height) * 0.62))
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
                        }
                    }
                } else if let art = photo(card.word, card.variant) {
                    // Fills the card edge to edge. A photograph floating in white
                    // was the dead space that made the deck feel flat.
                    Image(uiImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            } caption: {
                if settings.showWordOnPictures {
                    phonics(card.word, size: 40)
                }
            }
            .overlay(alignment: .bottomTrailing) { CardTag(id: card.id).padding(18) }
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
        let words = deck.map { c.words(in: $0) } ?? c.pictureWords
        // Ids stay tied to overall content order, so a number means the same card
        // whichever deck it was met in.
        var photoId: [String: Int] = [:], drawId: [String: Int] = [:]
        var pn = 0, dn = 0
        for p in c.pictureWords {
            photoId[p.word] = pn; pn += photoCount(p.word)
            drawId[p.word] = dn; dn += p.images.count
        }
        var cards: [Card] = []
        for p in words {
            let style = settings.pictureStyle
            if style != .drawings {
                for v in 0..<photoCount(p.word) {
                    cards.append(Card(word: p.word, variant: v,
                                      id: CardIds.photos + (photoId[p.word] ?? 0) + v, drawing: false))
                }
            }
            if style != .photos {
                for v in 0..<p.images.count {
                    cards.append(Card(word: p.word, variant: v,
                                      id: CardIds.drawings + (drawId[p.word] ?? 0) + v, drawing: true))
                }
            }
        }
        // Dealt in rounds so every word appears once before any word appears twice.
        let byWord = Dictionary(grouping: cards, by: \.word)
        let deepest = byWord.values.map(\.count).max() ?? 1
        var out: [Card] = []
        for r in 0..<deepest {
            out.append(contentsOf: byWord.values.compactMap { r < $0.count ? $0[r] : nil }.shuffled())
        }
        return out
    }
}
