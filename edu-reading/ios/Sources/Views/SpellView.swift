import SwiftUI

// Building a word, the mirror of reading it: a picture, a row of empty slots, and a
// tray of letters. The child taps letters to fill the slots. Only the correct NEXT
// letter locks in; a wrong tap gives a little shake and nothing else — the game, like
// the rest of the app, can only ever say yes. A couple of decoy letters make it a
// real choice rather than an ordering drill.

struct SpellView: View {
    @Environment(Progress.self) private var progress
    @Environment(Settings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0xC98A3E)

    @State private var pool: [ReadingContent.PictureWord] = []
    @State private var index = 0
    @State private var placed: [Character] = []
    @State private var tray: [Tile] = []
    @State private var done = false
    @State private var wrongTile: UUID?
    @State private var shake: CGFloat = 0

    struct Tile: Identifiable { let id = UUID(); let ch: Character }

    private var round: ReadingContent.PictureWord? {
        pool.isEmpty ? nil : pool[index % pool.count]
    }
    private var word: [Character] { Array(round?.word ?? "") }

    var body: some View {
        ZStack {
            Skin.current.appGround.ignoresSafeArea()
            if let round {
                VStack(spacing: 26) {
                    Spacer(minLength: 0)
                    Button { say() } label: {
                        Text(round.images.first ?? "🔤").font(.system(size: 116))
                    }
                    .buttonStyle(.plain)

                    slots
                    Spacer(minLength: 0)
                    trayView
                }
                .padding(20)
                .overlay { if done { ReadItCelebration(accent: accent).allowsHitTesting(false) } }
            }
        }
        .overlay(alignment: .topLeading) {
            BackChevron { dismiss() }.padding(.leading, 10).padding(.top, 6)
        }
        .overlay(alignment: .topTrailing) {
            Button { skip() } label: {
                Image(systemName: "arrow.right").font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Skin.live.cardInk).frame(width: 42, height: 42).contentShape(Circle())
            }
            .buttonStyle(.plain).modifier(GlassCircle()).padding(.trailing, 10).padding(.top, 6)
        }
        .toolbar(.hidden, for: .navigationBar)
        .noBackSwipe()
        .onAppear { if pool.isEmpty { makePool() } }
    }

    private var slots: some View {
        HStack(spacing: 10) {
            ForEach(0..<word.count, id: \.self) { i in
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Skin.live.card)
                        .frame(width: 56, height: 64)
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(i == placed.count ? accent : Skin.live.cardEdge,
                                    lineWidth: i == placed.count ? 2.5 : 1.5))
                    if i < placed.count { phonics(String(placed[i]), size: 34) }
                }
            }
        }
    }

    private var trayView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 12)], spacing: 12) {
            ForEach(tray) { tile in
                Button { tap(tile) } label: {
                    phonics(String(tile.ch), size: 32)
                        .frame(width: 60, height: 66)
                        .background(Skin.live.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(accent.opacity(0.45), lineWidth: 1.5))
                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .modifier(Shake(animatableData: wrongTile == tile.id ? shake : 0))
            }
        }
        .padding(.horizontal, 6)
    }

    private func tap(_ tile: Tile) {
        guard !done, placed.count < word.count else { return }
        if tile.ch == word[placed.count] {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                placed.append(tile.ch)
                tray.removeAll { $0.id == tile.id }
            }
            Buzz.pick()
            if placed.count == word.count { finish() }
        } else {
            Buzz.no()
            wrongTile = tile.id; shake = 0
            withAnimation(.linear(duration: 0.45)) { shake = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { wrongTile = nil; shake = 0 }
        }
    }

    private func finish() {
        done = true
        Buzz.yes()
        Voice.shared.celebrate()
        if let w = round?.word { progress.spelledWord(w) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            index += 1; setupRound()
        }
    }

    private func skip() { index += 1; setupRound() }
    private func say() { if let w = round?.word { Voice.shared.say(w) } }

    private func makePool() {
        // Ramp by length: three-letter words (cat, dog, sun) first, longer ones
        // later — so a beginner never opens on "onion". Shuffled within a length so
        // it is not the same order every time.
        let showable = c.pictureWords
            .filter { (3...6).contains($0.word.count) && $0.word.allSatisfy(\.isLetter) }
        pool = shuffledWithin(showable) { $0.word.count }
        setupRound()
    }

    private func setupRound() {
        placed = []; done = false; wrongTile = nil
        guard let round else { return }
        let letters = Array(round.word)
        // Two decoys the word does not use, so the tray is a choice. Drawn from the
        // whole alphabet, and we force one vowel when we can so a vowel slot isn't a
        // giveaway (the only vowel tile otherwise being the word's own).
        let vowels = Set("aeiou")
        let bank = Array("abcdefghijklmnopqrstuvwxyz").filter { !letters.contains($0) }
        var decoys = Array(bank.shuffled().prefix(settings.spellDecoys))
        // Force one vowel decoy when there is room, so a vowel slot isn't a giveaway.
        if settings.spellDecoys > 0, !decoys.contains(where: { vowels.contains($0) }),
           let v = bank.filter({ vowels.contains($0) }).randomElement() {
            if decoys.isEmpty { decoys = [v] } else { decoys[0] = v }
        }
        tray = (letters + decoys).map { Tile(ch: $0) }.shuffled()
        say()
    }
}

/// A short side-to-side shake, for a tile tapped out of turn.
struct Shake: GeometryEffect {
    var travel: CGFloat = 8
    var shakes: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: travel * sin(animatableData * .pi * shakes), y: 0))
    }
}
