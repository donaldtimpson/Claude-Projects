import SwiftUI

// A memory game that also teaches: every pair is a PICTURE and its WORD, so matching
// them is reading practice wearing a game's clothes. Turn two cards; a pair stays up
// and the word is spoken, a mismatch turns back. Clear the board to win. No timer, no
// score — just the quiet satisfaction of the board emptying.
struct MatchView: View {
    @Environment(Progress.self) private var progress
    @Environment(Settings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    private let accent = Color(hex: 0x3E8FA8)

    struct Card: Identifiable { let id = UUID(); let word: String; let picture: Bool }

    @State private var cards: [Card] = []
    @State private var up: Set<UUID> = []
    @State private var matched: Set<UUID> = []
    @State private var busy = false
    @State private var won = false

    var body: some View {
        GeometryReader { geo in
            // Size the cards to fill the space, so the board grows on an iPad instead
            // of being a short line of small cards up top.
            let count = max(cards.count, 2)
            let cols = count <= 6 ? 3 : 4
            let rows = Int(ceil(Double(count) / Double(cols)))
            let spacing: CGFloat = 14
            let availW = geo.size.width - 40
            let availH = geo.size.height - 40
            let side = max(60, min((availW - CGFloat(cols - 1) * spacing) / CGFloat(cols),
                                   (availH - CGFloat(rows - 1) * spacing) / CGFloat(rows)))
            let grid = Array(repeating: GridItem(.fixed(side), spacing: spacing), count: cols)
            VStack {
                Spacer(minLength: 0)
                LazyVGrid(columns: grid, alignment: .center, spacing: spacing) {
                    ForEach(cards) { cardView($0, side: side) }
                }
                Spacer(minLength: 0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Skin.current.appGround.ignoresSafeArea())
        .overlay { if won { ReadItCelebration(accent: accent).allowsHitTesting(false) } }
        .overlay(alignment: .topLeading) {
            BackChevron { dismiss() }.padding(.leading, 10).padding(.top, 6)
        }
        .toolbar(.hidden, for: .navigationBar)
        .noBackSwipe()
        .onAppear { if cards.isEmpty { setup() } }
        .onChange(of: settings.matchPairs) { setup() }
    }

    private func cardView(_ card: Card, side: CGFloat) -> some View {
        let isMatched = matched.contains(card.id)
        let isUp = isMatched || up.contains(card.id)
        return Button { tap(card) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accent.mixed(with: Skin.live.card, amount: 0.18))
                    .overlay(Image(systemName: "questionmark")
                        .font(.system(size: side * 0.28, weight: .bold)).foregroundStyle(accent.opacity(0.7)))
                    .opacity(isUp ? 0 : 1)

                Group {
                    if card.picture { WordPicture(word: card.word).padding(side * 0.1) }
                    else { phonics(card.word, size: side * 0.28).minimumScaleFactor(0.5).lineLimit(1).padding(4) }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Skin.live.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .opacity(isUp ? 1 : 0)
            }
            .frame(width: side, height: side)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isMatched ? Color(hex: 0x3E9B4F) : Skin.live.cardInk.opacity(0.12),
                        lineWidth: isMatched ? 3 : 1))
            .opacity(isMatched ? 0.5 : 1)
            .scaleEffect(isMatched ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isUp)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isMatched)
        }
        .buttonStyle(.plain)
        // No .disabled(): SwiftUI dims a disabled button, which made face-up cards look
        // faded. tap() already ignores taps on busy / face-up / matched cards.
    }

    private func tap(_ card: Card) {
        guard !busy, !matched.contains(card.id), !up.contains(card.id) else { return }
        up.insert(card.id)
        guard up.count == 2 else { return }
        let ids = Array(up)
        guard let a = cards.first(where: { $0.id == ids[0] }),
              let b = cards.first(where: { $0.id == ids[1] }) else { up = []; return }
        if a.word == b.word {
            Buzz.yes()
            Voice.shared.say(a.word)
            matched.formUnion(up); up = []
            if matched.count == cards.count { win() }
        } else {
            busy = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { up = []; busy = false }
        }
    }

    private func win() {
        won = true
        Voice.shared.celebrate()
        progress.matchWon()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) { setup() }
    }

    private func setup() {
        up = []; matched = []; busy = false; won = false
        // Distinct words only — pairs are matched by word, so a word appearing twice
        // (e.g. the same noun in two picture categories) would let cards match across
        // pairs and the board could never be cleared.
        var seen = Set<String>()
        let words = Pictures.showable.filter { !$0.images.isEmpty }
            .map(\.word).shuffled().filter { seen.insert($0).inserted }.prefix(settings.matchPairs)
        cards = words.flatMap { [Card(word: $0, picture: true), Card(word: $0, picture: false)] }
            .shuffled()
    }
}
