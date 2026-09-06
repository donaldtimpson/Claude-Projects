import SwiftUI

// The only place in the app that gets an UNAMBIGUOUS answer out of a child.
// Everything else is self-assessed: a card is tapped, a word is said, a grown-up
// decides. Tapping the right picture out of several is a real signal, and it is
// the one input a pre-literate child can give cleanly.
//
// Two modes, one engine, and the easier one needs no reading at all:
//   • Listen — the app says a word, the child finds the picture. Works from about
//     two, and tests vocabulary rather than decoding.
//   • Read   — the word is printed, the child finds the picture. The same screen
//     with the prompt swapped, available the moment they can decode.
//
// Nothing here punishes. A wrong tap shakes gently and stays put; there is no red
// cross, no buzzer, no score to lose. The child simply has not finished yet.
struct QuizView: View {
    @Environment(Progress.self) private var progress
    @Environment(Settings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0x3E8FA8)

    struct Round: Equatable {
        let answer: String
        let choices: [String]
    }

    @State private var round: Round?
    @State private var wrong: String?
    @State private var right: String?
    @State private var asked = 0

    /// Screenshot router only: force the printed-word mode.
    private var reads: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-quizread") { return true }
        #endif
        return settings.quizReads
    }

    var body: some View {
        VStack(spacing: 0) {
            prompt
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .padding(.bottom, 14)

            if let round {
                // The pictures should own the screen. Two choices go one above the
                // other so each is as large as possible — a bigger picture is an
                // easier question, which is the point at this age. Three or four
                // fall back to a grid.
                GeometryReader { geo in
                    let two = round.choices.count <= 2
                    let cols = two ? 1 : 2
                    let rows = two ? 2 : Int(ceil(Double(round.choices.count) / 2))
                    let h = (geo.size.height - CGFloat(rows + 1) * 12) / CGFloat(rows)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12),
                                             count: cols), spacing: 12) {
                        ForEach(round.choices, id: \.self) { w in
                            choice(w, in: round, height: h)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Skin.current.ground(accent).ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            BackChevron { dismiss() }.padding(.leading, 10).padding(.top, 6)
        }
        .toolbar(.hidden, for: .navigationBar)
        .noBackSwipe()
        .onAppear { if round == nil { deal() } }
    }

    // MARK: prompt

    @ViewBuilder
    private var prompt: some View {
        if let round {
            VStack(spacing: 8) {
                if reads {
                    // The printed word: this is the reading test.
                    phonics(round.answer, size: 48)
                } else {
                    // No text at all, so a child who cannot read can still play.
                    Button { Voice.shared.say(round.answer) } label: {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(accent)
                            .frame(width: 96, height: 96)
                            .background(Skin.live.card)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.10), radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                }
                Text(reads ? "Find the picture" : "Tap to hear it again")
                    .font(.andika(13)).foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: a choice

    private func choice(_ w: String, in round: Round, height: CGFloat) -> some View {
        let isRight = right == w
        let isWrong = wrong == w
        return Button { pick(w, in: round) } label: {
            WordPicture(word: w)
                .frame(maxWidth: .infinity)
                .frame(height: max(height - 20, 80))
                .padding(10)
                .background(Skin.live.card)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isRight ? accent : Theme.ink.opacity(0.10),
                            lineWidth: isRight ? 3 : 1))
                .scaleEffect(isRight ? 1.06 : 1)
                .offset(x: isWrong ? -7 : 0)
                .shadow(color: .black.opacity(0.07), radius: 5, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func pick(_ w: String, in round: Round) {
        guard right == nil else { return }
        if w == round.answer {
            right = w
            Voice.shared.chime()
            Voice.shared.say(w)
            progress.readWord(w)
            progress.answeredQuiz()
            asked += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                withAnimation(.easeInOut(duration: 0.25)) { right = nil; deal() }
            }
        } else {
            // A shake and nothing else. No cross, no buzzer, no score lost.
            withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) { wrong = w }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { wrong = nil }
        }
    }

    // MARK: dealing

    private func deal() {
        let pool = Pictures.showable
        guard pool.count > settings.quizChoices else { return }
        let answer = pool.randomElement()!
        // Distractors come from the SAME deck where possible: a child choosing
        // between a dog and a rocket has learned nothing, and choosing between a
        // dog and a fox has.
        var others = pool.filter { $0.category == answer.category && $0.word != answer.word }
        if others.count < settings.quizChoices - 1 {
            others += pool.filter { $0.word != answer.word && !others.contains($0) }
        }
        let picks = Array(others.shuffled().prefix(settings.quizChoices - 1)).map(\.word)
        round = Round(answer: answer.word, choices: (picks + [answer.word]).shuffled())
        if !reads {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { Voice.shared.say(answer.word) }
        }
    }
}
