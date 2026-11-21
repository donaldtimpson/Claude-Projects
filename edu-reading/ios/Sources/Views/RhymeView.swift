import SwiftUI

// Hearing that two words end the same is an EAR skill, and it comes before reading —
// so nothing here is printed. The first version showed written choices, which the
// child who needs this game can't read and the child who can read doesn't need.
//
// A round: a picture is named ("cat"), then each choice is named in turn as it
// lights up, so a picture that could be called two things is pinned to one word.
// Then the child taps the one that rhymes. Like Find It, a wrong tap is only ruled
// out — the game never scolds.
struct RhymeView: View {
    @Environment(Progress.self) private var progress
    @Environment(Settings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    private let c = ReadingContent.shared
    private let accent = Color(hex: 0x7A5EA8)
    typealias Pic = ReadingContent.Pic

    struct Round: Equatable { let target: Pic; let answer: Pic; let choices: [Pic] }

    @State private var round: Round?
    @State private var right: String?
    @State private var flash: String?
    @State private var ruledOut: Set<String> = []
    @State private var armed = false
    @State private var naming: String?     // the choice being named right now
    @State private var generation = 0      // so a stale naming chain stops

    var body: some View {
        VStack(spacing: 0) {
            if let round {
                target(round).padding(.top, 54)
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
        .onDisappear { generation += 1 }
    }

    private func target(_ round: Round) -> some View {
        Button { if armed { Voice.shared.say(round.target.word) } } label: {
            VStack(spacing: 4) {
                Text(round.target.image).font(.system(size: 110))
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 20)).foregroundStyle(accent)
            }
            .padding(.horizontal, 34).padding(.vertical, 16)
            .background(Skin.live.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func choice(_ p: Pic, in round: Round) -> some View {
        let isRight = right == p.word, isWrong = flash == p.word, out = ruledOut.contains(p.word)
        let lit = naming == p.word
        return Button { pick(p, in: round) } label: {
            Text(p.image).font(.system(size: 72))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(isRight ? Color(hex: 0x3E9B4F).opacity(0.22)
                            : (isWrong ? Color(hex: 0xD62828).opacity(0.20)
                               : (lit ? accent.opacity(0.18) : Skin.live.card)))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isRight ? Color(hex: 0x3E9B4F)
                            : (isWrong ? Color(hex: 0xD62828)
                               : (lit ? accent : Skin.live.cardInk.opacity(0.12))),
                            lineWidth: (isRight || isWrong || lit) ? 4 : 1))
                .scaleEffect(lit || isRight ? 1.06 : 1)
                .opacity(out && !isWrong ? 0.35 : (armed || lit ? 1 : 0.6))
                .grayscale(out && !isWrong ? 0.9 : 0)
                .offset(x: isWrong ? -7 : 0)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!armed || out || right != nil)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: lit)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: armed)
    }

    private func pick(_ p: Pic, in round: Round) {
        guard armed, right == nil, !ruledOut.contains(p.word) else { return }
        if p == round.answer {
            armed = false
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { right = p.word }
            Buzz.yes()
            Voice.shared.chime()
            progress.rhymeGot()
            // Say the pair together — "cat, bat" — so the rhyme itself is the reward.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                Voice.shared.say("\(round.target.word), \(p.word)")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeInOut(duration: 0.25)) { right = nil; deal() }
            }
        } else {
            Voice.shared.say(p.word)
            Buzz.no()
            withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) { flash = p.word }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeOut(duration: 0.25)) { flash = nil; _ = ruledOut.insert(p.word) }
            }
        }
    }

    private func deal() {
        let sets = c.rhymeSets ?? []
        guard let fam = sets.filter({ $0.words.count >= 2 }).randomElement() else { return }
        let pair = Array(fam.words.shuffled().prefix(2))
        // Decoys from OTHER families, so they share no rime with the target.
        let others = sets.filter { $0 != fam }.flatMap(\.words)
        let n = min(max(settings.rhymeChoices, 2), 3)
        let decoys = Array(others.shuffled().prefix(n - 1))
        let r = Round(target: pair[0], answer: pair[1], choices: (decoys + [pair[1]]).shuffled())
        round = r
        ruledOut = []; armed = false; flash = nil; naming = nil
        generation += 1
        let gen = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            Voice.shared.say(r.target.word) { name(r.choices, 0, gen) }
        }
    }

    /// Name each choice in turn as it lights up, then hand over to the child.
    private func name(_ choices: [Pic], _ i: Int, _ gen: Int) {
        guard gen == generation else { return }
        guard i < choices.count else {
            withAnimation { naming = nil; armed = true }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (i == 0 ? 0.5 : 0.25)) {
            guard gen == generation else { return }
            withAnimation { naming = choices[i].word }
            Voice.shared.say(choices[i].word) { name(choices, i + 1, gen) }
        }
    }
}
