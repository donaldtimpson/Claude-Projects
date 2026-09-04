import SwiftUI

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
    @State private var index = 0
    @State private var variant = 0

    var body: some View {
        DeckScreen(title: "Look and Say", count: c.pictureWords.count,
                   index: $index, accent: accent) { i in
            let p = c.pictureWords[i]
            VStack(spacing: 24) {
                Spacer()
                Text(p.images[variant % p.images.count])
                    .font(.system(size: 190))
                    .id(variant)
                    .transition(.scale.combined(with: .opacity))
                Spacer()
                if settings.showWordOnPictures {
                    phonics(p.word, size: 34).opacity(0.75)
                }
            }
            .padding(24)
        } onTap: { i in
            Voice.shared.say(c.pictureWords[i].word)
            withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) { variant += 1 }
        } onAdvance: {
            variant = 0
        }
    }
}
