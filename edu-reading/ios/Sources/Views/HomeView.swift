import SwiftUI

struct HomeView: View {
    @Environment(Progress.self) private var progress
    @Environment(Settings.self) private var settings
    private let c = ReadingContent.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {

                    // The world doubles as the progress bar: how full it is IS the score.
                    NavigationLink { WorldView() } label: { WorldTile() }
                        .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 9) {
                        Text("LEARNING TO READ")
                            .font(.andika(12, bold: true)).kerning(1.4)
                            .foregroundStyle(Theme.inkSoft)

                        DeckTile(step: "1", tint: 0xE0A038, name: "Letters",
                                 blurb: "\(c.letters.count) sounds, A to Z or shuffled") { LettersView() }
                        DeckTile(step: "2", tint: 0x2E7D6E, name: "Blending",
                                 blurb: "Glue two sounds into one") { BlendingView() }
                        DeckTile(step: "3", tint: 0x3B7EA1, name: "Words",
                                 blurb: "\(c.words.count) words, getting harder") { WordsView() }
                        DeckTile(step: "4", tint: 0x7A5EA8, name: "Sentences",
                                 blurb: "\(c.sentences.count) sentences you can sound out") { SentencesView() }
                        DeckTile(step: "5", tint: 0xC8433A, name: "By Heart",
                                 blurb: "The rule-breakers") { HeartWordsView() }
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        Text("FIRST WORDS")
                            .font(.andika(12, bold: true)).kerning(1.4)
                            .foregroundStyle(Theme.inkSoft)
                        // One tile into sixteen small decks, rather than sixteen
                        // rows here — the home screen stays scannable.
                        DeckTile(step: "•", tint: 0xD9646E, name: "Look and Say",
                                 blurb: "\(c.pictureCategories.count) sets of picture cards",
                                 dashed: true) { PictureDecksHub() }
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        Text("FIRST IDEAS")
                            .font(.andika(12, bold: true)).kerning(1.4)
                            .foregroundStyle(Theme.inkSoft)
                        DeckTile(step: "•", tint: 0x4E8FBF, name: "Colours",
                                 blurb: "\(c.colors.count) colours", dashed: true) { ColorsView() }
                        DeckTile(step: "•", tint: 0x6FA368, name: "Shapes",
                                 blurb: "\(c.shapes.count) shapes", dashed: true) { ShapesView() }
                        DeckTile(step: "•", tint: 0xC98A3E, name: "Numbers",
                                 blurb: "Counting, one to \(c.numbers.words[settings.numberLevel - 1])",
                                 dashed: true) { NumbersView() }
                    }

                    NavigationLink { ParentGateView() } label: {
                        Text("For grown-ups")
                            .font(.andika(15))
                            .foregroundStyle(Theme.inkSoft)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(18)
            }
            .background(Skin.current.appGround.ignoresSafeArea())
            .navigationTitle("Sound It Out")
        }
        .tint(Theme.go)
    }
}

private struct WorldTile: View {
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared

    var body: some View {
        let got = progress.knownWords.count
        let total = c.collectibles.count
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("My World").font(.andika(26, bold: true)).foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
            }
            // The reward for reading a word is the word itself, as a thing you keep.
            HStack(spacing: 4) {
                ForEach(c.collectibles.prefix(9), id: \.word) { w in
                    Text(w.image ?? "")
                        .font(.system(size: 26))
                        .grayscale(progress.knows(word: w.word) ? 0 : 1)
                        .opacity(progress.knows(word: w.word) ? 1 : 0.28)
                }
                if total > 9 { Text("…").foregroundStyle(Theme.inkSoft) }
            }
            Text(got == 0 ? "Read a word and it comes to live here."
                          : "\(got) collected")
                .font(.andika(14)).foregroundStyle(Theme.inkSoft)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(hex: 0xCFE7F2), Color(hex: 0xEAF4F8)],
                                   startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.line, lineWidth: 1.5))
    }
}

private struct DeckTile<Destination: View>: View {
    let step: String
    var tint: UInt = 0x63777F
    let name: String
    let blurb: String
    var dashed: Bool = false
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        let skin = Skin.current
        let colour = Color(hex: tint)
        NavigationLink { destination() } label: {
            HStack(spacing: 14) {
                // The step marker carries the deck's own colour, so the home screen
                // is a row of distinguishable places rather than a grey list.
                Text(step)
                    .font(.andika(19, bold: true))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(colour)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .shadow(color: colour.opacity(0.35), radius: 4, y: 2)
                VStack(alignment: .leading, spacing: 1) {
                    Text(name).font(.andika(20, bold: true)).foregroundStyle(Theme.ink)
                    Text(blurb).font(.andika(13)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(colour.opacity(0.55))
            }
            .padding(14)
            .background(skin.tileFill)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(colour.mixed(with: skin.tileFill, amount: 0.68),
                            style: StrokeStyle(lineWidth: 1.5, dash: dashed ? [6, 4] : []))
            )
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}
