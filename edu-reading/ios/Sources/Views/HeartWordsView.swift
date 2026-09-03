import SwiftUI

// Heart words, not sight words. The old approach memorises the whole shape; the
// better one teaches the part that DOES follow the rules and flags only the rogue
// grapheme. In "said" the s and d are perfectly regular — only the "ai" misbehaves,
// so there is one thing to learn by heart instead of four.
//
// This matters beyond tidiness: whole-word memorising teaches a child that some
// words are looked at rather than read, which competes with everything the first
// four decks built.
struct HeartWordsView: View {
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared

    enum Mode: String, CaseIterable { case parts = "By heart", sentence = "In a sentence" }
    @State private var mode: Mode = .parts
    @State private var index = 0

    var body: some View {
        DeckShell(title: "Sight Words", count: c.heartWords.count, index: $index) {
            let h = c.heartWords[index % c.heartWords.count]
            VStack(spacing: 20) {
                Spacer()
                if mode == .parts {
                    HStack(alignment: .lastTextBaseline, spacing: 7) {
                        ForEach(Array(h.parts.enumerated()), id: \.offset) { _, p in
                            VStack(spacing: 3) {
                                if p.regular {
                                    phonics(p.grapheme, size: 54)
                                } else {
                                    Text(p.grapheme)
                                        .font(.andika(54, bold: true))
                                        .foregroundStyle(Theme.heart)
                                        .padding(.horizontal, 4)
                                        .background(Theme.heartSoft)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                Text(p.regular ? "sounds out" : "by heart ♥")
                                    .font(.andika(10)).kerning(0.6)
                                    .foregroundStyle(p.regular ? Theme.inkSoft : Theme.heart)
                            }
                        }
                    }
                    phonics(h.word, size: 62)
                    Text("Only the amber part has to be remembered.")
                        .font(.andika(13)).foregroundStyle(Theme.inkSoft)
                } else {
                    phonicsSentence(h.sentence, size: 30, sight: c.sightSet)
                        .multilineTextAlignment(.center)
                }
                SpeakButton(text: mode == .parts ? h.word : h.sentence)
                Spacer()
            }
            .padding(20)
            .cardSurface()
        } controls: {
            ChipRow(items: Mode.allCases, label: \.rawValue, selection: $mode)
        }
    }
}
