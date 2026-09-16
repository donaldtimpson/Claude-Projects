import SwiftUI

// Hearing that two words end the same is the root skill under decoding — a child who
// can hear "cat / hat" is ready to see that -at is a unit. This is that ear-training
// as a game: a target word, and three words to pick the rhyme from. It reuses the
// rime families the Word Blending deck is built on, so the answer genuinely rhymes
// and the decoys genuinely do not. Like Find It, a wrong tap is only ruled out — the
// game never scolds.
struct RhymeView: View {
    @Environment(Progress.self) private var progress
    @Environment(Settings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0x7A5EA8)

    struct Round: Equatable { let target: String; let answer: String; let choices: [String] }

    @State private var round: Round?
    @State private var right: String?
    @State private var flash: String?
    @State private var ruledOut: Set<String> = []
    @State private var armed = false
    @State private var armFallback: DispatchWorkItem?

    var body: some View {
        VStack(spacing: 0) {
            prompt.padding(.top, 10).padding(.bottom, 22)
            if let round {
                VStack(spacing: 12) {
                    ForEach(round.choices, id: \.self) { choice($0, in: round) }
                }
                .padding(.horizontal, 22)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Skin.current.ground(accent).ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            BackChevron { dismiss() }.padding(.leading, 10).padding(.top, 6)
        }
        .toolbar(.hidden, for: .navigationBar)
        .noBackSwipe()
        .onAppear { if round == nil { deal() } }
    }

    @ViewBuilder
    private var prompt: some View {
        if let round {
            VStack(spacing: 12) {
                Text("Which word rhymes?")
                    .font(.andika(15)).foregroundStyle(Skin.live.onSkySoft)
                Button { Voice.shared.say(round.target) } label: {
                    HStack(spacing: 12) {
                        phonics(round.target, size: 46)
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 22)).foregroundStyle(accent)
                    }
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(Skin.live.card, in: Capsule())
                    .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func choice(_ w: String, in round: Round) -> some View {
        let isRight = right == w, isWrong = flash == w, out = ruledOut.contains(w)
        return Button { pick(w, in: round) } label: {
            phonics(w, size: 40)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(isRight ? Color(hex: 0x3E9B4F).opacity(0.22)
                            : (isWrong ? Color(hex: 0xD62828).opacity(0.20) : Skin.live.card))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isRight ? Color(hex: 0x3E9B4F)
                            : (isWrong ? Color(hex: 0xD62828) : Skin.live.cardInk.opacity(0.12)),
                            lineWidth: (isRight || isWrong) ? 4 : 1))
                .opacity(out && !isWrong ? 0.35 : (armed ? 1 : 0.55))
                .offset(x: isWrong ? -7 : 0)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!armed || out || right != nil)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: armed)
    }

    private func pick(_ w: String, in round: Round) {
        guard armed, right == nil, !ruledOut.contains(w) else { return }
        Voice.shared.say(w)
        if w == round.answer {
            armed = false
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { right = w }
            Buzz.yes()
            progress.rhymeGot()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                withAnimation(.easeInOut(duration: 0.25)) { right = nil; deal() }
            }
        } else {
            Buzz.no()
            withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) { flash = w }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeOut(duration: 0.25)) { flash = nil; _ = ruledOut.insert(w) }
            }
        }
    }

    private func deal() {
        let fams = c.rimes.filter { $0.words.count >= 2 }
        guard let fam = fams.randomElement() else { return }
        let pair = fam.words.shuffled().prefix(2)
        guard let target = pair.first, let answer = pair.last, target != answer else { return }
        // Decoys from OTHER families, so they share no rime with the target.
        let others = c.rimes.filter { $0.rime != fam.rime }.flatMap { $0.words }
        let decoys = Array(others.shuffled().prefix(max(1, settings.rhymeChoices - 1)))
        round = Round(target: target, answer: answer, choices: (decoys + [answer]).shuffled())
        ruledOut = []; armed = false; flash = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            Voice.shared.say(target) { withAnimation { armed = true } }
        }
        // Belt-and-braces arm, if the utterance never reports back. Cancel any prior
        // one so a previous round's timer can't arm the next round early.
        armFallback?.cancel()
        let fb = DispatchWorkItem { if !armed { withAnimation { armed = true } } }
        armFallback = fb
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: fb)
    }
}
