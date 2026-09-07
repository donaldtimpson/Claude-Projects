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
    @State private var right: String?
    /// Choices already ruled out this round. A wrong pick is not punished — it is
    /// taken off the table, which is definite feedback AND narrows the question.
    @State private var ruledOut: Set<String> = []
    @State private var flash: String?
    /// Taps are ignored until the word has finished being spoken. A child who is
    /// enjoying it taps fast, and without this the next question arrives under a
    /// finger already on its way down and is answered by accident.
    @State private var armed = false
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
        #if DEBUG
        // Screenshot only: answer the first question automatically so the right
        // and wrong states can be looked at rather than assumed.
        .onChange(of: armed) { _, on in
            guard on, let r = round else { return }
            let a = ProcessInfo.processInfo.arguments
            if a.contains("-autoright") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { pick(r.answer, in: r) }
            } else if a.contains("-autowrong"),
                      let w = r.choices.first(where: { $0 != r.answer }) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { pick(w, in: r) }
            }
        }
        #endif
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
        let isWrong = flash == w
        let out = ruledOut.contains(w)
        return Button { pick(w, in: round) } label: {
            WordPicture(word: w)
                .frame(maxWidth: .infinity)
                .frame(height: max(height - 20, 80))
                .padding(10)
                .background(
                    // The whole card turns green or red for a moment. A child needs
                    // the answer to be unmissable, and colour carries further than
                    // a border.
                    isRight ? Color(hex: 0x3E9B4F).opacity(0.22)
                            : (isWrong ? Color(hex: 0xD62828).opacity(0.20) : Skin.live.card)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isRight ? Color(hex: 0x3E9B4F)
                                    : (isWrong ? Color(hex: 0xD62828) : Theme.ink.opacity(0.10)),
                            lineWidth: (isRight || isWrong) ? 4 : 1))
                .overlay(alignment: .topTrailing) {
                    if isRight {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(Color(hex: 0x3E9B4F), .white)
                            .padding(10)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .scaleEffect(isRight ? 1.05 : (out ? 0.94 : 1))
                // Ruled out: dimmed and left on screen, so the child can see what
                // they tried without it looking like a mistake to feel bad about.
                .opacity(out && !isWrong ? 0.35 : (armed ? 1 : 0.55))
                .grayscale(out && !isWrong ? 0.9 : 0)
                .offset(x: isWrong ? -7 : 0)
                .shadow(color: .black.opacity(0.07), radius: 5, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(!armed || out || right != nil)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: armed)
    }

    private func pick(_ w: String, in round: Round) {
        guard armed, right == nil, !ruledOut.contains(w) else { return }
        if w == round.answer {
            armed = false
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { right = w }
            Buzz.yes()
            Voice.shared.chime()
            progress.readWord(w)
            progress.answeredQuiz()
            asked += 1
            // Long enough to see the green and the tick before the next question.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                withAnimation(.easeInOut(duration: 0.25)) { right = nil; deal() }
            }
        } else {
            Buzz.no()
            withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) { flash = w }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeOut(duration: 0.25)) {
                    flash = nil
                    _ = ruledOut.insert(w)
                }
            }
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
        ruledOut = []
        armed = false
        if reads {
            // Nothing to wait for, but still a beat so a fast tapper cannot answer
            // the next question with the tap that answered the last one.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation { armed = true }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                Voice.shared.say(answer.word) {
                    withAnimation { armed = true }
                }
            }
            // Belt and braces: if the utterance never reports back, do not leave
            // the child tapping a dead screen.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if !armed { withAnimation { armed = true } }
            }
        }
    }
}
