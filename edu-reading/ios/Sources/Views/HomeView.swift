import SwiftUI

struct HomeView: View {
    @Environment(Progress.self) private var progress
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

                        DeckTile(step: "1", name: "Letters",
                                 blurb: "\(c.letters.count) sounds, in the order that helps") { LettersView() }
                        DeckTile(step: "2", name: "Blending",
                                 blurb: "Glue two sounds into one") { BlendingView() }
                        DeckTile(step: "3", name: "Words",
                                 blurb: "\(c.words.count) words, getting harder") { WordsView() }
                        DeckTile(step: "4", name: "Sentences",
                                 blurb: "\(c.sentences.count) sentences you can sound out") { SentencesView() }
                        DeckTile(step: "5", name: "By Heart",
                                 blurb: "The rule-breakers") { HeartWordsView() }
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        Text("ANY TIME")
                            .font(.andika(12, bold: true)).kerning(1.4)
                            .foregroundStyle(Theme.inkSoft)
                        DeckTile(step: "•", name: "Photos",
                                 blurb: "Real pictures of \(c.pictureWords.count) words",
                                 dashed: true) { PictureWordsView(drawings: false) }
                        DeckTile(step: "•", name: "Drawings",
                                 blurb: "Simple pictures — easiest for the youngest",
                                 dashed: true) { PictureWordsView(drawings: true) }
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
            .background(Theme.ground)
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
    let name: String
    let blurb: String
    var dashed: Bool = false
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink { destination() } label: {
            HStack(spacing: 14) {
                Text(step)
                    .font(.andika(19, bold: true))
                    .foregroundStyle(Theme.paper)
                    .frame(width: 38, height: 38)
                    .background(Theme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 1) {
                    Text(name).font(.andika(20, bold: true)).foregroundStyle(Theme.ink)
                    Text(blurb).font(.andika(13)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
            }
            .padding(14)
            .background(Theme.paper)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.line, style: StrokeStyle(lineWidth: 1.5,
                                                           dash: dashed ? [6, 4] : []))
            )
        }
        .buttonStyle(.plain)
    }
}
