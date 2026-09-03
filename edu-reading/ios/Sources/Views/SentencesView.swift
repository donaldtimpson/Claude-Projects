import SwiftUI

// The rung almost every reading app skips: words, then straight to a real book.
// Sentences built only from patterns already taught are the bridge between.
//
// "the" and "a" appear here rather than waiting for the sight-word deck, because
// without them a decodable sentence can only ever be "Sam sat." — the two
// commonest words in English are what make natural sentences possible at all.
struct SentencesView: View {
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared

    @State private var index = 0
    @State private var showPicture = false

    var body: some View {
        DeckShell(title: "Sentences", count: c.sentences.count, index: $index) {
            let s = c.sentences[index % c.sentences.count].text
            VStack(spacing: 20) {
                Spacer()
                phonicsSentence(s, size: 34, sight: c.sightSet)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                SpeakButton(text: s)
                Text("Underlined words are learned, not sounded out.")
                    .font(.andika(13)).foregroundStyle(Theme.inkSoft)
                Spacer()
            }
            .padding(20)
            .cardSurface()
        } controls: {
            EmptyView()
        }
        .onChange(of: index) { record() }
        .onAppear { record() }
    }

    private func record() {
        // Reading a sentence collects every decodable word in it, which is what
        // makes the world fill fastest at exactly the moment it gets exciting.
        let s = c.sentences[index % c.sentences.count].text
        for token in s.split(separator: " ") {
            let bare = token.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".!?,"))
            if !bare.isEmpty && !c.sightSet.contains(bare) { progress.learn(word: bare) }
        }
    }
}
