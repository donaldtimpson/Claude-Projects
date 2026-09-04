import SwiftUI

// Heart words, not sight words. The old approach memorises the whole shape; this
// teaches the part that DOES follow the rules and flags only the rogue grapheme —
// in "said", the s and d are regular and only the "ai" misbehaves. One thing to
// remember instead of four, and decoding stays the default habit.
struct HeartWordsView: View {
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0xE0A038)
    @State private var index = 0

    var body: some View {
        DeckScreen(title: "By Heart", count: c.heartWords.count, index: $index, accent: accent) { i in
            let h = c.heartWords[i]
            VStack(spacing: 26) {
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    ForEach(Array(h.parts.enumerated()), id: \.offset) { _, p in
                        if p.regular {
                            phonics(p.grapheme, size: 62)
                        } else {
                            Text(p.grapheme)
                                .font(.andika(62, bold: true))
                                .foregroundStyle(accent)
                                .padding(.horizontal, 5)
                                .background(Theme.heartSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                Text("♥").font(.system(size: 22)).foregroundStyle(accent)
                phonicsSentence(h.sentence, size: 26, sight: c.sightSet)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(24)
        } onTap: { i in
            Voice.shared.say(c.heartWords[i].word)
        }
    }
}
