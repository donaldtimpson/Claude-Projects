import SwiftUI

// The ear before the eye. Hearing the separate sounds inside a spoken word is the
// skill that predicts reading best of all, and it comes BEFORE letters — so nothing
// here is printed. Two games on one engine:
//
//   • Sound Hunt: the app says a word one sound at a time — /d/ … /o/ … /g/ — and
//     the child taps the dog. That is oral blending, the exact move reading needs,
//     with the letters taken away.
//   • First Sound: "/m/ … which one starts with /m/?" — the child taps the moon.
//
// Like Find It, a wrong tap is only ruled out, never scolded. Both need the phoneme
// clips, so home only offers them once the clips are bundled.
struct SoundGameView: View {
    enum Mode { case blend, first }
    let mode: Mode

    @Environment(Progress.self) private var progress
    @Environment(Settings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    private let c = ReadingContent.shared
    private var accent: Color { mode == .blend ? Color(hex: 0x2E7D6E) : Color(hex: 0xC8433A) }
    typealias Word = ReadingContent.Word

    struct Round: Equatable { let answer: Word; let choices: [Word] }

    @State private var round: Round?
    @State private var right: String?
    @State private var flash: String?
    @State private var ruledOut: Set<String> = []
    @State private var armed = false
    @State private var lit = false
    @State private var generation = 0

    /// Words with a picture, from the early levels — short enough to hold in the
    /// ear, and every one is a thing a child can point at.
    private var bank: [Word] {
        c.words.filter { $0.image != nil && ["CVC", "Digraphs", "Blends"].contains($0.level) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let round {
                prompt(round).padding(.top, 60)
                Spacer(minLength: 18)
                let cols = round.choices.count > 2 ? 3 : 2
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: cols),
                          spacing: 12) {
                    ForEach(round.choices, id: \.word) { choice($0, in: round) }
                }
                .padding(.horizontal, 18)
                Spacer(minLength: 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Skin.current.ground(accent).ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            BackChevron { dismiss() }.padding(.leading, 10).padding(.top, 6)
        }
        .toolbar(.hidden, for: .navigationBar)
        .noBackSwipe()
        .onAppear { if round == nil { deal() } }
        .onDisappear { generation += 1; Voice.shared.cancelSoundOut() }
    }

    /// An ear, not a word: tap it to hear the prompt again.
    private func prompt(_ round: Round) -> some View {
        Button { if armed { play(round, generation) } } label: {
            Image(systemName: mode == .blend ? "ear.fill" : "waveform")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 150, height: 150)
                .background(Skin.live.card, in: Circle())
                .overlay(Circle().stroke(accent.opacity(lit ? 0.9 : 0.15), lineWidth: lit ? 6 : 2))
                .scaleEffect(lit ? 1.08 : 1)
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: lit)
        }
        .buttonStyle(.plain)
    }

    private func choice(_ w: Word, in round: Round) -> some View {
        let isRight = right == w.word, isWrong = flash == w.word, out = ruledOut.contains(w.word)
        return Button { pick(w, in: round) } label: {
            Text(w.image ?? "").font(.system(size: 72))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(isRight ? Color(hex: 0x3E9B4F).opacity(0.22)
                            : (isWrong ? Color(hex: 0xD62828).opacity(0.20) : Skin.live.card))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isRight ? Color(hex: 0x3E9B4F)
                            : (isWrong ? Color(hex: 0xD62828) : Skin.live.cardInk.opacity(0.12)),
                            lineWidth: (isRight || isWrong) ? 4 : 1))
                .scaleEffect(isRight ? 1.06 : 1)
                .opacity(out && !isWrong ? 0.35 : (armed ? 1 : 0.6))
                .grayscale(out && !isWrong ? 0.9 : 0)
                .offset(x: isWrong ? -7 : 0)
        }
        .buttonStyle(.plain)
        .disabled(!armed || out || right != nil)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: armed)
    }

    private func pick(_ w: Word, in round: Round) {
        guard armed, right == nil, !ruledOut.contains(w.word) else { return }
        if w == round.answer {
            armed = false
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { right = w.word }
            Buzz.yes()
            Voice.shared.chime()
            progress.knewWord(w.word)
            progress.answeredQuiz()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { Voice.shared.say(w.word) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeInOut(duration: 0.25)) { right = nil; deal() }
            }
        } else {
            Voice.shared.say(w.word)
            Buzz.no()
            withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) { flash = w.word }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeOut(duration: 0.25)) { flash = nil; _ = ruledOut.insert(w.word) }
            }
        }
    }

    private func first(_ w: Word) -> String { c.sounds(of: w).first?.phoneme ?? "" }

    private func deal() {
        guard let answer = bank.randomElement() else { return }
        let n = min(max(settings.quizChoices, 2), 3)
        // Decoys that start with a different sound, so exactly one choice is right.
        let aSounds = c.sounds(of: answer).map(\.phoneme)
        let decoys = bank.filter { w in
            guard w != answer, w.image != answer.image else { return false }
            let s = c.sounds(of: w).map(\.phoneme)
            return s.first != aSounds.first
        }.shuffled().prefix(n - 1)
        let r = Round(answer: answer, choices: (Array(decoys) + [answer]).shuffled())
        round = r
        ruledOut = []; armed = false; flash = nil
        generation += 1
        let gen = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { play(r, gen) }
    }

    /// The prompt: each sound with a clear gap (blend), or the first sound twice.
    private func play(_ r: Round, _ gen: Int) {
        armed = false
        let ids: [String] = mode == .blend
            ? c.sounds(of: r.answer).map(\.phoneme).filter { $0 != "_" }
            : [first(r.answer), first(r.answer)]
        func step(_ i: Int) {
            guard gen == generation else { return }
            guard i < ids.count else {
                lit = false
                withAnimation { armed = true }
                return
            }
            lit = true
            Voice.shared.phoneme(ids[i]) {
                lit = false
                DispatchQueue.main.asyncAfter(deadline: .now() + (mode == .blend ? 0.45 : 0.6)) { step(i + 1) }
            }
        }
        step(0)
    }
}
