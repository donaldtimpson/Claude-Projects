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
    /// A short mixed session across every deck instead of one deck — see makeMix.
    var mix: Bool = false

    @Environment(Settings.self) private var settings
    private let c = ReadingContent.shared
    private var accent: Color { DeckStyle.accent(for: deck) }

    private struct Card: Hashable { let word: String; let variant: Int; let id: Int; let drawing: Bool }

    @State private var pool: [Card] = []
    @State private var index = 0

    var body: some View {
        DeckScreen(title: deck ?? (mix ? "Mix" : "Look and Say"), count: pool.count,
                   index: $index, accent: accent) { i in
            let card = pool[min(i, max(pool.count - 1, 0))]
            let p = c.pictureWords.first { $0.word == card.word }
            // Stacked in portrait, side-by-side in landscape — a short wide card
            // has no room for a big picture above a word.
            let art = card.drawing ? nil : photo(card.word, card.variant)
            AdaptiveCard(aspect: art.map { $0.size.width / max($0.size.height, 1) } ?? 1) {
                if card.drawing {
                    if let p, !p.images.isEmpty {
                        // A glyph cannot be resized like an image, so measure the
                        // space and pick a point size that fills it. It sits on a
                        // faint wash of the deck's colour rather than bare white,
                        // so a drawing card has the same weight as a photo card.
                        GeometryReader { geo in
                            ZStack {
                                Skin.live.card.mixed(with: accent, amount: 0.10)
                                Text(p.images[card.variant % p.images.count])
                                    .font(.system(size: min(geo.size.width, geo.size.height) * 0.62))
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
                        }
                    }
                } else if let art {
                    // The WHOLE photograph, never cropped. Filling the card was an
                    // over-correction: dead white space was the complaint, but
                    // cropping to remove it throws away the context a child reads
                    // the picture by, and a visibly cut-off image feels wrong on
                    // its own. The remaining space is a MAT — tinted like the
                    // drawing cards, so it reads as a mount rather than emptiness.
                    Image(uiImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
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
        .onAppear {
            if pool.isEmpty { pool = mix ? makeMix() : makePool() }
            if mix, let first = pool.first { MixMemory.saw(first.word) }
        }
        .onChange(of: index) { if mix, index < pool.count { MixMemory.saw(pool[index].word) } }
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

    /// Twenty cards, one per word, spread across the decks, the words met longest
    /// ago first (never-met words count as oldest, in random order). Each word shows
    /// its next picture each time it comes round, so a word with four photos cycles
    /// through all four over successive sessions instead of always leading with one.
    private func makeMix(size: Int = 20) -> [Card] {
        let all = makePool(words: c.pictureWords)
        let byWord = Dictionary(grouping: all, by: \.word)
        let decks = c.pictureCategories
        // Freshest-first queue within each deck, then deal round-robin across decks.
        var queues: [[String]] = decks.map { d in
            c.words(in: d).map(\.word).filter { byWord[$0] != nil }
                .shuffled().sorted { MixMemory.last($0) < MixMemory.last($1) }
        }
        var picked: [String] = []
        let deckOrder = Array(queues.indices).sorted {
            MixMemory.last(queues[$0].first ?? "") < MixMemory.last(queues[$1].first ?? "")
        }
        while picked.count < size, queues.contains(where: { !$0.isEmpty }) {
            for q in deckOrder where !queues[q].isEmpty && picked.count < size {
                picked.append(queues[q].removeFirst())
            }
        }
        return picked.shuffled().compactMap { w in
            guard let cards = byWord[w], !cards.isEmpty else { return nil }
            return cards[MixMemory.nextVariant(w) % cards.count]
        }
    }

    /// Ids are assigned by walking the content in order, so a card's number is the
    /// same on every launch and every device no matter how the deck is shuffled.
    private func makePool(words override: [ReadingContent.PictureWord]? = nil) -> [Card] {
        let words = override ?? deck.map { c.words(in: $0) } ?? c.pictureWords
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

/// When each picture word was last shown in Mix, and which of its pictures comes
/// next. Device-wide rather than per child: it only decides what is fresh, and a
/// sibling seeing the same dog yesterday doesn't make it stale for anyone.
enum MixMemory {
    private static let seenKey = "sound-it-out.mix.seen"
    private static let variantKey = "sound-it-out.mix.variant"
    static func last(_ word: String) -> Double {
        (UserDefaults.standard.dictionary(forKey: seenKey)?[word] as? Double) ?? 0
    }
    static func saw(_ word: String) {
        var d = UserDefaults.standard.dictionary(forKey: seenKey) ?? [:]
        d[word] = Date().timeIntervalSince1970
        UserDefaults.standard.set(d, forKey: seenKey)
    }
    /// Returns this word's picture index for now, and moves it on for next time.
    static func nextVariant(_ word: String) -> Int {
        var d = UserDefaults.standard.dictionary(forKey: variantKey) ?? [:]
        let n = (d[word] as? Int) ?? 0
        d[word] = n + 1
        UserDefaults.standard.set(d, forKey: variantKey)
        return n
    }
}
