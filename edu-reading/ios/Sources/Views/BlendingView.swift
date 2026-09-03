import SwiftUI

// Two versions on purpose, so they can be tried on real children.
//
// A (consonant + vowel: fa, fe, fi) is the original idea. It works beautifully in
// Spanish, where vowels say one thing — but English open syllables are unstable:
// the "fa" in fat is not the "fa" in fable, and "fi" could be fit or fine.
//
// B (onset + rime: at -> fat -> sat) uses a unit English keeps stable, and hands
// the child a whole word family from one card.
struct BlendingView: View {
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared

    enum Variant: String, CaseIterable { case cv = "A · fa fe fi", rime = "B · at → fat" }
    @State private var variant: Variant = .rime
    @State private var index = 0
    @State private var family = 0

    private var count: Int {
        variant == .cv ? c.cvBlends.count : c.rimes[family].words.count + 1
    }

    var body: some View {
        DeckShell(title: "Blending", count: count, index: $index) {
            Group {
                if variant == .cv { cvCard } else { rimeCard }
            }
            .cardSurface()
        } controls: {
            VStack(spacing: 8) {
                ChipRow(items: Variant.allCases, label: \.rawValue, selection: $variant)
                if variant == .rime {
                    ChipRow(items: Array(c.rimes.indices), label: { "-\(c.rimes[$0].rime)" },
                            selection: $family, tint: Theme.go)
                }
            }
        }
        .onChange(of: variant) { index = 0 }
        .onChange(of: family) { index = 0 }
    }

    private var cvCard: some View {
        let s = c.cvBlends[index % c.cvBlends.count].text
        return VStack(spacing: 16) {
            Spacer()
            phonics(s, size: 88)
            SpeakButton(text: s)
            Text("Stretch the first sound into the second.")
                .font(.andika(14)).foregroundStyle(Theme.inkSoft)
            Spacer()
        }.padding(20)
    }

    private var rimeCard: some View {
        let fam = c.rimes[family]
        let showingRimeAlone = index == 0
        let word = showingRimeAlone ? fam.rime : fam.words[(index - 1) % fam.words.count]
        let onset = showingRimeAlone ? "" : String(word.dropLast(fam.rime.count))
        return VStack(spacing: 18) {
            Spacer()
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                if !onset.isEmpty {
                    VStack(spacing: 2) {
                        phonics(onset, size: 62)
                        Text("onset").font(.andika(10)).kerning(1).foregroundStyle(Theme.inkSoft)
                    }
                }
                VStack(spacing: 2) {
                    phonics(fam.rime, size: 62)
                    Text("rime").font(.andika(10)).kerning(1).foregroundStyle(Theme.inkSoft)
                }
            }
            phonics(word, size: 68)
            SpeakButton(text: word)
            Text("One rime, a whole family of words.")
                .font(.andika(14)).foregroundStyle(Theme.inkSoft)
            Spacer()
        }
        .padding(20)
        .onAppear { if !showingRimeAlone { progress.learn(word: word) } }
    }
}
