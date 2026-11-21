import SwiftUI

// Two decks live here, one teaching step apart.
//
//   • BLENDING (step 2) glues a single consonant to a single vowel — ba, be, bi,
//     bo, bu — for all 19 consonants, 95 cards. They are nonsense syllables on
//     purpose: the child practises the MECHANICS of pushing two sounds together
//     before any of them has to add up to a real word. The card shows a sound-dot
//     under each unit and a sweep arrow beneath, the way the paper drill does.
//   • WORD BLENDING (step 3) is the next rung: a rime — a unit English keeps stable
//     — hands over a whole family of real words from one card (at → cat, hat, sat).
//
// This used to be one deck with a grown-up toggle between the two. Splitting them
// makes the progression visible on the home screen and retires the toggle.

// MARK: - step 2 · Blending (consonant + vowel)

struct BlendingView: View {
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0x2E7D6E)
    @State private var index = 0
    // Ordered: consonant by consonant, vowels a-e-i-o-u — a lesson. Shuffled: practice.
    @State private var ordered = true
    @State private var cards: [(consonant: String, vowel: String)] = []
    /// Which sound-dot is lit while the syllable plays: 0, 1, or 2 for "both".
    @State private var active: Int?

    private func makePool() {
        let pairs = c.syllableConsonants.flatMap { con in
            c.blendVowels.map { (consonant: con, vowel: $0) }
        }
        cards = ordered ? pairs : pairs.shuffled()
    }

    var body: some View {
        // Text-to-speech reads a syllable as a whole word ("do" → "doo"), the
        // opposite of the d-/o/ blend we want, so this deck plays recorded phoneme
        // clips: the consonant, the vowel, then the two pushed together. With no
        // clips bundled it stays silent and a tap simply turns the card.
        DeckScreen(title: "Blending", count: cards.count, index: $index, accent: accent,
                   ordered: $ordered, speaks: Voice.shared.hasAnyLetterAudio) { i in
            let card = cards[min(i, cards.count - 1)]
            VStack {
                Spacer()
                SyllableCard(consonant: card.consonant, vowel: card.vowel, active: active)
                Spacer()
            }
        } onTap: { i in
            guard i < cards.count else { return }
            let con = cards[i].consonant == "qu" ? "kw" : (c.phonemeDefaults?[cards[i].consonant] ?? cards[i].consonant)
            let vow = cards[i].vowel
            let v = Voice.shared
            func lit(_ n: Int?) { withAnimation(.easeOut(duration: 0.12)) { active = n } }
            lit(0)
            v.phoneme(con) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    lit(1)
                    v.phoneme(vow) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                            lit(2)
                            v.phoneme(con) { v.phoneme(vow) { lit(nil) } }
                        }
                    }
                }
            }
        } onAdvance: { active = nil }
        .onAppear { if cards.isEmpty { makePool() } }
        .onChange(of: ordered) { index = 0; makePool() }
    }
}

/// One blending card: consonant in ink, vowel in red (the app's phonics convention),
/// a sound-dot centred under each unit — a SINGLE dot under "qu", since two letters
/// make one sound — and a left-to-right sweep arrow beneath, the "push them together"
/// gesture.
struct SyllableCard: View {
    let consonant: String
    let vowel: String
    /// Lit sound-dot while it plays: 0 consonant, 1 vowel, 2 both.
    var active: Int? = nil
    var size: CGFloat = 132

    var body: some View {
        VStack(spacing: size * 0.09) {
            // Equal-height Text columns share a baseline, so the dots line up under
            // their letters without any manual measuring.
            HStack(alignment: .center, spacing: size * 0.04) {
                column(consonant, Skin.live.cardInk, lit: active == 0 || active == 2)
                column(vowel, Skin.live.vowel, lit: active == 1 || active == 2)
            }
            BlendArrow()
                .stroke(Skin.live.cardInkSoft,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .frame(width: size * 1.25, height: size * 0.15)
        }
    }

    private func column(_ s: String, _ colour: Color, lit: Bool = false) -> some View {
        VStack(spacing: size * 0.06) {
            Text(s).font(.andika(size, bold: true)).foregroundStyle(colour)
            Circle().fill(lit ? Theme.go : Skin.live.cardInkSoft)
                .frame(width: size * 0.11, height: size * 0.11)
                .scaleEffect(lit ? 1.5 : 1)
        }
    }
}

/// A horizontal line with a right-pointing head — the blend sweep read left to right.
struct BlendArrow: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let y = r.midY, head = r.height * 0.5
        p.move(to: CGPoint(x: r.minX, y: y))
        p.addLine(to: CGPoint(x: r.maxX, y: y))
        p.move(to: CGPoint(x: r.maxX - head, y: y - head))
        p.addLine(to: CGPoint(x: r.maxX, y: y))
        p.addLine(to: CGPoint(x: r.maxX - head, y: y + head))
        return p
    }
}

// MARK: - step 3 · Word Blending (rime → word family)

struct WordBlendingView: View {
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0x3E9077)
    @State private var index = 0
    // Families build: the bare rime, then the words made from it. In order it reads
    // as a lesson; shuffled it is practice.
    @State private var ordered = true
    @State private var rimeCards: [(onset: String, rime: String, word: String)] = []

    private func makePool() {
        let fams = ordered ? c.rimes : c.rimes.shuffled()
        rimeCards = fams.flatMap { fam in
            let ws = ordered ? fam.words : fam.words.shuffled()
            // The bare rime always leads its own family — it is what the family is
            // built from — so only the words after it are ever shuffled.
            return [(onset: "", rime: fam.rime, word: fam.rime)] +
                ws.map { (onset: String($0.dropLast(fam.rime.count)), rime: fam.rime, word: $0) }
        }
    }

    var body: some View {
        DeckScreen(title: "Word Blending", count: rimeCards.count, index: $index, accent: accent,
                   ordered: $ordered) { i in
            let card = rimeCards[min(i, rimeCards.count - 1)]
            VStack(spacing: 26) {
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    if !card.onset.isEmpty { phonics(card.onset, size: 44).opacity(0.6) }
                    phonics(card.rime, size: 44).opacity(0.6)
                }
                SayCard(text: card.word, size: 106, accent: accent) {
                    progress.readWord(card.word)
                }
                .frame(maxHeight: 250)
                Spacer()
            }
        } onTap: { i in
            guard i < rimeCards.count else { return }
            Voice.shared.say(rimeCards[i].word)
        } onHold: { i in
            guard i < rimeCards.count else { return }
            markRead(rimeCards[i].word, progress)
        }
        .onAppear { if rimeCards.isEmpty { makePool() } }
        .onChange(of: ordered) { index = 0; makePool() }
    }
}
