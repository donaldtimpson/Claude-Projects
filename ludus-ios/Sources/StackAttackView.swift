import SwiftUI

// MARK: - Stack Attack — an addition/times-table drill wrapped in a block-stacker.
//
// Solve the problem at the top, tap the right answer, and a stone block drops onto a
// growing tower. Wrong answers wobble the tower and cost a heart. Difficulty ramps:
// tiny sums first, then bigger sums, then small multiplication. Score = tower height.
//
// Input-driven: no per-frame loop. All state lives in an @MainActor engine; the
// block-drop and tower growth are pure SwiftUI withAnimation. One ambient shimmer
// (the "next block" preview) is driven by Timer.publish + .onReceive.

// MARK: - Model

private struct SAProblem {
    let question: String
    let options: [Int]
    let correct: Int   // index into options
}

private struct SABlock: Identifiable {
    let id: Int
    let colorHex: UInt
    let offset: CGFloat   // small horizontal jitter for a hand-stacked look
}

// MARK: - Engine

@MainActor
private final class SAEngine: ObservableObject {
    enum Phase { case playing, over }

    @Published var phase: Phase = .playing
    @Published var problem = SAProblem(question: "", options: [], correct: 0)
    @Published var score = 0
    @Published var hearts = 3
    @Published var combo = 0
    @Published var den = 0
    @Published var blocks: [SABlock] = []
    @Published var revealed = false
    @Published var chosen: Int?
    @Published var wobble = false

    // game-over payload
    @Published var lastScore = 0
    @Published var lastDen = 0
    @Published var best = 0
    @Published var newBest = false
    @Published var reason = ""

    private let key = "stackAttack"
    private var blockCounter = 0

    func start() {
        score = 0; hearts = 3; combo = 0; den = 0
        blocks = []; blockCounter = 0
        revealed = false; chosen = nil; wobble = false
        reason = ""; newBest = false
        problem = makeProblem(0)
        phase = .playing
        Haptics.prime()
    }

    /// Difficulty ramp keyed on the number of blocks already stacked.
    private func makeProblem(_ stacked: Int) -> SAProblem {
        let a: Int, b: Int, answer: Int, sign: String

        if stacked < 5 {
            // very easy addition, small sums
            a = Int.random(in: 1...5); b = Int.random(in: 1...5)
            answer = a + b; sign = "+"
        } else if stacked < 12 {
            a = Int.random(in: 3...9); b = Int.random(in: 2...9)
            answer = a + b; sign = "+"
        } else if stacked < 20 {
            a = Int.random(in: 6...14); b = Int.random(in: 4...12)
            answer = a + b; sign = "+"
        } else if stacked < 28 {
            // introduce small multiplication mixed with addition
            if Bool.random() {
                a = Int.random(in: 2...6); b = Int.random(in: 2...6)
                answer = a * b; sign = "×"
            } else {
                a = Int.random(in: 8...18); b = Int.random(in: 6...15)
                answer = a + b; sign = "+"
            }
        } else {
            // larger times tables
            if Int.random(in: 0..<3) == 0 {
                a = Int.random(in: 10...22); b = Int.random(in: 8...19)
                answer = a + b; sign = "+"
            } else {
                a = Int.random(in: 2...9); b = Int.random(in: 3...9)
                answer = a * b; sign = "×"
            }
        }

        // Build two plausible wrong answers near the correct one.
        var opts: Set<Int> = [answer]
        var guardCount = 0
        while opts.count < 3 && guardCount < 200 {
            let delta = [-3, -2, -1, 1, 2, 3, answer >= 10 ? 10 : 4].randomElement()!
            let wrong = answer + delta
            if wrong > 0 && wrong != answer { opts.insert(wrong) }
            guardCount += 1
        }
        // Fallback padding if the loop somehow starved.
        var list = Array(opts)
        while list.count < 3 { list.append(answer + list.count + 1) }
        list.shuffle()

        return SAProblem(question: "\(a) \(sign) \(b) = ?",
                         options: list,
                         correct: list.firstIndex(of: answer) ?? 0)
    }

    func choose(_ i: Int) {
        guard phase == .playing, !revealed else { return }
        revealed = true; chosen = i

        if i == problem.correct {
            combo += 1
            let pts = combo   // combo multiplier: each correct in a streak is worth more
            score += pts; den += pts
            blockCounter += 1
            let hex = Lu.bubbleHexes[blockCounter % Lu.bubbleHexes.count]
            let jitter = CGFloat.random(in: -10...10)
            Haptics.tap(0.75)
            withAnimation(.spring(response: 0.34, dampingFraction: 0.62)) {
                blocks.append(SABlock(id: blockCounter, colorHex: hex, offset: jitter))
            }
        } else {
            combo = 0
            hearts -= 1
            Haptics.error()
            withAnimation(.spring(response: 0.16, dampingFraction: 0.28)) { wobble = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { self?.wobble = false }
            }
        }

        let correctAnswer = (i == problem.correct)
        let delay = correctAnswer ? 0.42 : 0.7
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            if self.hearts <= 0 { self.gameOver("The tower toppled!") }
            else { self.nextProblem() }
        }
    }

    private func nextProblem() {
        problem = makeProblem(blocks.count)
        revealed = false; chosen = nil
    }

    private func gameOver(_ why: String) {
        LudusStore.award(den)
        newBest = LudusStore.recordBest(key, score)
        best = LudusStore.best(key)
        lastScore = score; lastDen = den
        reason = why
        phase = .over
    }
}

// MARK: - Option button

private struct SAOptionButton: View {
    let value: Int
    let index: Int
    let revealed: Bool
    let chosen: Int?
    let correct: Int
    let action: () -> Void

    private var fillHex: UInt {
        guard revealed else { return Lu.panel }
        if index == correct { return Lu.mint }
        if index == chosen { return Lu.coral }
        return Lu.panel
    }
    private var textHex: UInt {
        (revealed && (index == correct || index == chosen)) ? Lu.inkDark : Lu.ink
    }

    var body: some View {
        Button(action: action) {
            Text("\(value)")
                .font(luFont(30))
                .foregroundStyle(Color(hex: textHex))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 78)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(hex: fillHex))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: Lu.line), lineWidth: 2))
                )
                .opacity(revealed && index != correct && index != chosen ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(revealed)
    }
}

// MARK: - Tower

private struct SATowerView: View {
    let blocks: [SABlock]
    let wobble: Bool

    private let blockH: CGFloat = 26
    private let blockW: CGFloat = 118
    private let gap: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            // Show only what fits; the tower "scrolls" so the top block stays visible.
            let capacity = max(4, Int((geo.size.height - 8) / (blockH + gap)))
            let visible = Array(blocks.suffix(capacity))
            let baseX = geo.size.width / 2

            ZStack(alignment: .bottom) {
                // ground plate
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: Lu.ground2))
                    .frame(width: blockW + 26, height: 12)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: Lu.line), lineWidth: 2))
                    .frame(maxHeight: .infinity, alignment: .bottom)

                ForEach(Array(visible.enumerated()), id: \.element.id) { row, block in
                    let isTop = block.id == visible.last?.id
                    SAStoneBlock(hex: block.colorHex, width: blockW, height: blockH)
                        .position(
                            x: baseX + block.offset + (wobble ? CGFloat(row) * 1.6 : 0),
                            y: geo.size.height - 14 - blockH / 2 - CGFloat(row) * (blockH + gap)
                        )
                        .rotationEffect(.degrees(wobble ? Double(row) * 0.7 : 0), anchor: .bottom)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity))
                        .zIndex(isTop ? 1 : 0)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: wobble)
        }
    }
}

private struct SAStoneBlock: View {
    let hex: UInt
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                LinearGradient(
                    colors: [luShade(hex, 14), Color(hex: hex), luShade(hex, -12)],
                    startPoint: .top, endPoint: .bottom)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(luShade(hex, -30), lineWidth: 2)
            )
            .overlay(
                // mortar highlight line
                RoundedRectangle(cornerRadius: 2)
                    .fill(luShade(hex, 26).opacity(0.5))
                    .frame(height: 2)
                    .padding(.horizontal, 8)
                    .offset(y: -height * 0.28)
            )
            .frame(width: width, height: height)
            .shadow(color: Color(hex: Lu.inkDark).opacity(0.18), radius: 1.5, x: 0, y: 1.5)
    }
}

// MARK: - Root view

struct StackAttackView: View {
    let onClose: () -> Void

    @StateObject private var engine = SAEngine()
    @State private var shimmer = false

    private let shimmerTick = Timer.publish(every: 1.1, on: .main, in: .common).autoconnect()
    private let cols = [GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            LudusBackground().ignoresSafeArea()

            VStack(spacing: 14) {
                // HUD
                HStack(alignment: .top, spacing: 8) {
                    LudusCloseButton(action: onClose)
                    StatPill(label: "SCORE", value: "\(engine.score)", valueHex: Lu.gold)
                    Spacer(minLength: 4)
                    HeartsRow(hearts: engine.hearts)
                    Spacer(minLength: 4)
                    StatPill(label: "DENARII", value: "\(engine.den)", valueHex: Lu.silver)
                }

                // Problem card
                VStack(spacing: 6) {
                    Text("SOLVE IT")
                        .font(luSerif(14, .bold)).textCase(.uppercase).tracking(2)
                        .foregroundStyle(Color(hex: Lu.inkDim))
                    Text(engine.problem.question)
                        .font(luFont(46))
                        .foregroundStyle(Color(hex: Lu.ink))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, minHeight: 96)
                .padding(.vertical, 14)
                .background(luPanelShape(20))

                if engine.combo >= 2 {
                    Text("COMBO ×\(engine.combo)")
                        .font(luFont(18)).foregroundStyle(Color(hex: Lu.mint))
                        .id(engine.combo)
                        .transition(.scale(scale: 1.25).combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: engine.combo)
                } else {
                    // reserve the line so the layout doesn't jump
                    Color.clear.frame(height: 22)
                }

                // The growing tower
                SATowerView(blocks: engine.blocks, wobble: engine.wobble)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .topTrailing) {
                        Text("HEIGHT \(engine.blocks.count)")
                            .font(luSerif(13, .bold)).tracking(1.5)
                            .foregroundStyle(Color(hex: Lu.inkDim))
                            .opacity(shimmer ? 1 : 0.72)
                            .padding(.trailing, 4)
                    }

                // Answer choices
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(Array(engine.problem.options.enumerated()), id: \.offset) { idx, val in
                        SAOptionButton(value: val, index: idx,
                                       revealed: engine.revealed, chosen: engine.chosen,
                                       correct: engine.problem.correct,
                                       action: { engine.choose(idx) })
                    }
                }
                .padding(.bottom, 6)
            }
            .padding(.horizontal, 14).padding(.top, 4)

            if engine.phase == .over {
                LudusGameOverView(reason: engine.reason, score: engine.lastScore,
                                  best: engine.best, denRun: engine.lastDen,
                                  newBest: engine.newBest,
                                  onAgain: { engine.start() }, onClose: onClose)
                    .transition(.opacity)
            }
        }
        .statusBarHidden(true)
        .onReceive(shimmerTick) { _ in
            withAnimation(.easeInOut(duration: 0.9)) { shimmer.toggle() }
        }
        .onAppear { engine.start() }
    }
}
