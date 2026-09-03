import SwiftUI

// Not step one of reading — a parallel track. The word under the picture is for
// the ADULT, so they know which word the image is meant to prompt; the child is
// building spoken vocabulary, which is the strongest predictor of later
// comprehension. Reading mode hides the picture, so the very same deck becomes a
// victory lap a year later.
struct PictureWordsView: View {
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared

    @State private var category: String = ReadingContent.shared.pictureCategories.first ?? "Animals"
    @State private var index = 0
    @State private var readingMode = false

    private var pool: [ReadingContent.PictureWord] {
        c.pictureWords.filter { $0.category == category }
    }

    var body: some View {
        DeckShell(title: "Picture Words", count: pool.count, index: $index) {
            if !pool.isEmpty {
                let p = pool[index % pool.count]
                VStack(spacing: 18) {
                    Spacer()
                    if readingMode {
                        phonics(p.word, size: 68)
                        Text("Picture hidden — can they read it?")
                            .font(.andika(14)).foregroundStyle(Theme.inkSoft)
                    } else {
                        // Three images, never one. A child shown a single dog learns
                        // that picture; shown a beagle, a poodle and a lab, they learn
                        // the category. Emoji stand in until real photos are sourced.
                        HStack(spacing: 10) {
                            ForEach(Array(p.images.enumerated()), id: \.offset) { i, img in
                                Text(img).font(.system(size: i == 1 ? 84 : 46))
                                    .opacity(i == 1 ? 1 : 0.42)
                            }
                        }
                        phonics(p.word, size: 46)
                    }
                    SpeakButton(text: p.word)
                    Spacer()
                }
                .padding(20)
                .cardSurface()
            }
        } controls: {
            VStack(spacing: 8) {
                ChipRow(items: c.pictureCategories, label: { $0 }, selection: $category, tint: Theme.go)
                Toggle(isOn: $readingMode) {
                    Text("Reading mode — hide the picture")
                        .font(.andika(14)).foregroundStyle(Theme.inkSoft)
                }
                .tint(Theme.go)
            }
        }
        .onChange(of: category) { index = 0 }
        .onChange(of: readingMode) { _, on in
            if on, !pool.isEmpty { progress.learn(word: pool[index % pool.count].word) }
        }
    }
}
