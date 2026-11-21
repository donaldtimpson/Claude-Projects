import SwiftUI

// Building a word, the mirror of reading it — and the bridge to writing. A picture
// (or, for a word with no picture, just its sound), one slot per GRAPHEME, and a
// tray of grapheme tiles: "sh" and "ck" are one tile each, because they are one
// sound each. Every tile says its sound when touched, so the child spells by ear
// rather than from memorised letter strings. Only the right tile for the next slot
// locks in; a wrong one says its sound and stays in the tray. Tapping the glowing
// slot plays the sound it wants — help, never a telling-off.
//
// Words come only from the decodable list, in level order (cat before ship before
// cake), so a beginner never meets "knife".

struct SpellView: View {
    /// In a Play session: only this level's words.
    var level: String? = nil
    @Environment(Progress.self) private var progress
    @Environment(Settings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.session) private var session
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0xC98A3E)
    typealias Sound = (grapheme: String, phoneme: String)

    @State private var pool: [ReadingContent.Word] = []
    @State private var index = 0
    @State private var placed = 0
    @State private var tray: [Tile] = []
    @State private var done = false
    @State private var wrongTile: UUID?
    @State private var shake: CGFloat = 0
    @State private var active: Int?

    struct Tile: Identifiable { let id = UUID(); let grapheme: String; let phoneme: String }

    private var round: ReadingContent.Word? { pool.isEmpty ? nil : pool[index % pool.count] }
    private var sounds: [Sound] { round.map { c.sounds(of: $0) } ?? [] }

    var body: some View {
        ZStack {
            Skin.current.appGround.ignoresSafeArea()
            if let round {
                VStack(spacing: 26) {
                    Spacer(minLength: 0)
                    Button { say() } label: {
                        if let img = round.image {
                            Text(img).font(.system(size: 116))
                        } else {
                            Image(systemName: "speaker.wave.2.circle.fill")
                                .font(.system(size: 96)).foregroundStyle(accent)
                        }
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
        .onDisappear { Voice.shared.cancelSoundOut() }
    }

    private var slots: some View {
        HStack(spacing: 8) {
            ForEach(Array(sounds.enumerated()), id: \.offset) { i, s in
                let next = i == placed && !done
                let wide = s.grapheme.count > 1
                Button { if next { Voice.shared.phoneme(s.phoneme) } } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(i == active ? Theme.go.opacity(0.18) : Skin.live.card)
                            .frame(width: wide ? 78 : 56, height: 64)
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(next ? accent : (i == active ? Theme.go : Skin.live.cardEdge),
                                        lineWidth: next || i == active ? 2.5 : 1.5))
                        if i < placed {
                            phonicsParts([s], active: nil, size: 34)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(!next)
            }
        }
    }

    private var trayView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 12)], spacing: 12) {
            ForEach(tray) { tile in
                Button { tap(tile) } label: {
                    phonics(tile.grapheme, size: 32)
                        .frame(width: 72, height: 66)
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
        guard !done, placed < sounds.count else { return }
        let want = sounds[placed]
        // A silent letter has no sound of its own; its tile says nothing.
        if tile.phoneme != "_" { Voice.shared.phoneme(tile.phoneme) }
        if tile.grapheme.lowercased() == want.grapheme.lowercased() {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                placed += 1
                tray.removeAll { $0.id == tile.id }
            }
            Buzz.pick()
            if placed == sounds.count { finish() }
        } else {
            Buzz.no()
            wrongTile = tile.id; shake = 0
            withAnimation(.linear(duration: 0.45)) { shake = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { wrongTile = nil; shake = 0 }
        }
    }

    private func finish() {
        done = true
        guard let w = round else { return }
        progress.spelledWord(w.word)
        session?.scored()
        // Read back what was built — each sound lit in its slot, then the word.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let cheer = {
                Buzz.yes()
                Voice.shared.celebrate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { index += 1; setupRound() }
            }
            if Voice.shared.hasAnyLetterAudio {
                Voice.shared.soundOut(sounds, word: w.word,
                                      onStep: { i in withAnimation { active = i } }, then: cheer)
            } else {
                Voice.shared.say(w.word); cheer()
            }
        }
    }

    private func skip() { Voice.shared.cancelSoundOut(); index += 1; setupRound() }
    private func say() { if let w = round?.word { Voice.shared.say(w) } }

    private func makePool() {
        // Level order (CVC, digraphs, blends …), shuffled within a level; inflected
        // endings are left out — "jumping" is a reading word, not a spelling one.
        let order = c.wordLevels
        let spellable = c.words.filter { $0.level != "Endings" && $0.parts != nil && (level == nil || $0.level == level) }
        pool = shuffledWithin(spellable) { order.firstIndex(of: $0.level) ?? 9 }
        setupRound()
    }

    private func setupRound() {
        placed = 0; done = false; wrongTile = nil; active = nil
        guard let round else { return }
        let mine = sounds
        let own = Set(mine.map { $0.grapheme.lowercased() })
        // Decoys from graphemes already met at this level or before, the same kind
        // as the word's own (a digraph word gets a digraph decoy), and always one
        // vowel when there's room so a vowel slot isn't a giveaway.
        let lv = c.wordLevels.firstIndex(of: round.level) ?? 0
        var bank: [Sound] = []
        var seen = Set<String>()
        for w in c.words where (c.wordLevels.firstIndex(of: w.level) ?? 9) <= lv {
            for s in c.sounds(of: w) where s.phoneme != "_" {
                let g = s.grapheme.lowercased()
                if !own.contains(g), seen.insert(g).inserted { bank.append((g, s.phoneme)) }
            }
        }
        let vowels = Set("aeiou")
        let isVowel: (Sound) -> Bool = { $0.grapheme.allSatisfy { vowels.contains($0) } }
        var decoys: [Sound] = []
        let n = settings.spellDecoys
        if n > 0, let v = bank.filter(isVowel).randomElement() { decoys.append(v) }
        if mine.contains(where: { $0.grapheme.count > 1 }),
           let d = bank.filter({ $0.grapheme.count > 1 && !isVowel($0) }).randomElement() {
            decoys.append(d)
        }
        for s in bank.shuffled() where decoys.count < n && !decoys.contains(where: { $0.grapheme == s.grapheme }) {
            decoys.append(s)
        }
        tray = (mine + decoys.prefix(max(n, decoys.count > n ? n : decoys.count)))
            .map { Tile(grapheme: $0.grapheme, phoneme: $0.phoneme) }.shuffled()
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
