import SwiftUI

// The levels run CVC -> digraphs -> blends -> silent e in one continuous deck.
// A child does not choose a phonics level, so there is no picker; the deck simply
// gets harder as it goes.
//
// Tap flips the card. On the ~4 words in 5 that can be drawn, the picture confirms.
// On sat, chat, mud it speaks instead — a recording works for every word, a picture
// does not, and that is the honest limit of picture-based self-check.
struct WordsView: View {
    /// In a Play session: one level, optionally only words made of these graphemes,
    /// and a short deck.
    var level: String? = nil
    var allowed: [String]? = nil
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0x3B7EA1)
    @State private var index = 0
    @State private var flipped = false
    // Bumped to move the deck on by itself after a read word's picture has shown.
    @State private var advanceReq = 0
    @State private var pictureHold: DispatchWorkItem?
    /// The grapheme being sounded out right now, for the underline.
    @State private var active: Int?

    // Levels keep their order — a child who has done "cat" is not ready for
    // "strength" — but the words inside a level are shuffled on every open.
    @State private var pool: [ReadingContent.Word] = []

    private func wordId(_ w: ReadingContent.Word) -> Int {
        (c.words.firstIndex(of: w) ?? 0) + 1
    }

    private func makePool() -> [ReadingContent.Word] {
        let order = c.wordLevels
        if let level {
            let ok = Set(allowed ?? [])
            let pick = c.words.filter { w in
                w.level == level && (allowed == nil || c.sounds(of: w).allSatisfy { ok.contains($0.grapheme.lowercased()) })
            }
            return Array(pick.shuffled().prefix(8))
        }
        return shuffledWithin(c.words) { order.firstIndex(of: $0.level) ?? 9 }
    }

    var body: some View {
        DeckScreen(title: "Words", count: pool.count, index: $index, accent: accent,
                   advance: advanceReq) { i in
            let w = pool[min(i, pool.count - 1)]
            ZStack {
                if flipped {
                    VStack(spacing: 16) {
                        Spacer()
                        if let img = w.image {
                            Text(img).font(.system(size: 160))
                        } else {
                            Image(systemName: "speaker.wave.2.circle.fill")
                                .font(.system(size: 96)).foregroundStyle(accent)
                        }
                        phonics(w.word, size: 52)
                        Spacer()
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    SayCard(text: w.word, size: 118, accent: accent,
                            sounds: c.sounds(of: w), active: active) {
                        progress.readWord( w.word)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { flipped = true }
                        // Show the picture of what they read — the word/image link is
                        // the point — but don't strand them on it: a card that just
                        // sits there reads as "read it again". Move on after a beat,
                        // unless they swipe first (onAdvance cancels this).
                        let hold = DispatchWorkItem { advanceReq += 1 }
                        pictureHold = hold
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: hold)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                CardTag(id: CardIds.words + wordId(w)).padding(14)
            }
        } onTap: { i in
            // First tap reveals and speaks; CardStack turns the card on the second.
            guard i < pool.count else { return }
            let w = pool[i]
            let reveal = { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { flipped = true } }
            if Voice.shared.hasAnyLetterAudio {
                // Sound it out — each grapheme lit as it's heard — THEN the word,
                // then the picture. The child blends along instead of being told.
                Voice.shared.soundOut(c.sounds(of: w), word: w.word,
                                      onStep: { i in withAnimation(.easeOut(duration: 0.12)) { active = i } },
                                      then: reveal)
            } else {
                Voice.shared.say(w.word)
                reveal()
            }
        } onAdvance: {
            pictureHold?.cancel()
            Voice.shared.cancelSoundOut()
            active = nil
            flipped = false
        } onHold: { i in
            guard i < pool.count else { return }
            markRead(pool[i].word, progress)
        }
        .onAppear { if pool.isEmpty { pool = makePool() } }
    }
}
