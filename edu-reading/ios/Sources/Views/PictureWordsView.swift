import SwiftUI
import UIKit

// Look and Say — the gentlest thing in the app, and the entry point for a child
// far too young for the rest of it. Big picture, tap to hear it, swipe on.
//
// The word sits small at the bottom FOR THE ADULT, so they know which word the
// image is prompting; a grown-up can hide it entirely. The child is building
// spoken vocabulary, which is the strongest predictor of later comprehension —
// this is not step one of reading, it runs alongside.
//
// Tapping cycles the three images: a child shown one dog learns that picture,
// while a beagle, a poodle and a labrador teach the category.
struct PictureWordsView: View {
    @Environment(Settings.self) private var settings
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0xD9646E)
    // No teaching order to protect here, so it is a straight reshuffle each open.
    @State private var pool: [ReadingContent.PictureWord] = []
    @State private var index = 0
    @State private var variant = 0

    /// Looks for "dog", then "dog-2", "dog-3" so a word can still have several
    /// pictures — the point of the deck is the category, not one photo.
    private func photo(for p: ReadingContent.PictureWord, variant: Int) -> UIImage? {
        var found: [UIImage] = []
        if let first = UIImage(named: p.word) { found.append(first) }
        var n = 2
        while let more = UIImage(named: "\(p.word)-\(n)"), n <= 6 { found.append(more); n += 1 }
        guard !found.isEmpty else { return nil }
        return found[variant % found.count]
    }

    var body: some View {
        DeckScreen(title: "Look and Say", count: pool.count,
                   index: $index, accent: accent) { i in
            let p = pool[min(i, pool.count - 1)]
            VStack(spacing: 24) {
                Spacer()
                // Real photo if one is bundled, emoji otherwise. Dropping
                // "dog.jpg" into Assets.xcassets is the whole integration — no
                // content edit, no code change. Emoji were never the plan; they
                // are a stand-in that keeps the deck testable until photos exist.
                if let art = photo(for: p, variant: variant) {
                    Image(uiImage: art)
                        .resizable().scaledToFit()
                        .frame(maxHeight: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .id(variant)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text(p.images[variant % p.images.count])
                        .font(.system(size: 190))
                        .id(variant)
                        .transition(.scale.combined(with: .opacity))
                }
                Spacer()
                if settings.showWordOnPictures {
                    phonics(p.word, size: 34).opacity(0.75)
                }
            }
            .padding(24)
        } onTap: { i in
            Voice.shared.say(pool[min(i, pool.count - 1)].word)
            withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) { variant += 1 }
        } onAdvance: {
            variant = 0
        }
        .onAppear { if pool.isEmpty { pool = c.pictureWords.shuffled() } }
    }
}
