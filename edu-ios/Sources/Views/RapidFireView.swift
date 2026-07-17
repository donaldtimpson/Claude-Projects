import SwiftUI

// EXPERIMENT — arcade "Rapid Fire" mode for any drill. A countdown, a combo
// multiplier, snappy full-screen feedback, and a high score. How many can you
// nail before the clock runs out?
struct RapidFireView: View {
    let def: DrillDef
    let level: Int
    let seconds: Int
    let onExit: () -> Void

    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var queue: WriteQueueManager

    @State private var problem: DrillProblem?
    @State private var timeLeft: Double
    @State private var score = 0
    @State private var combo = 0
    @State private var bestCombo = 0
    @State private var answered = 0
    @State private var correctCount = 0
    @State private var numericEntry = ""
    @State private var flash: Bool?          // true = correct, false = wrong, nil = none
    @State private var locked = false
    @State private var finished = false
    @State private var previousBest = 0
    @State private var startedAt = Date()
    @State private var recent: [String] = []

    @AppStorage private var best: Int

    private let tick = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    init(def: DrillDef, level: Int, seconds: Int = 60, onExit: @escaping () -> Void) {
        self.def = def
        self.level = level
        self.seconds = seconds
        self.onExit = onExit
        _timeLeft = State(initialValue: Double(seconds))
        _best = AppStorage(wrappedValue: 0, "rapidbest_\(def.slug)_L\(level)_\(seconds)")
    }

    private var currentAnswer: Int? {
        if case let .numeric(answer, _) = problem?.input { return answer }
        return nil
    }

    var body: some View {
        ZStack {
            Theme.parchment.ignoresSafeArea()
            flashColor.ignoresSafeArea().animation(.easeOut(duration: 0.15), value: flash)
            if finished { results } else { play }
        }
        .navigationTitle("Rapid Fire")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(tick) { _ in step() }
        .onAppear { startedAt = Date(); nextProblem() }
    }

    private var flashColor: Color {
        guard let flash else { return .clear }
        return (flash ? Theme.success : Theme.danger).opacity(0.22)
    }

    // MARK: play
    @ViewBuilder private var play: some View {
        VStack(spacing: 0) {
            topBar.padding()
            if let problem {
                switch problem.input {
                case let .choice(options, correctIndex):
                    ScrollView {
                        VStack(spacing: 20) {
                            Text(problem.prompt)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                                .frame(maxWidth: .infinity).padding(.top, 12)
                            if let diagram = problem.diagram {
                                DrillDiagram(spec: diagram).frame(maxWidth: .infinity)
                            }
                            OptionButtons(options: options, correctIndex: correctIndex,
                                          selected: nil, revealed: false, grid: true,
                                          optionImages: problem.optionImages) { i in
                                submit(correct: i == correctIndex)
                            }
                        }
                        .padding()
                    }
                case let .numeric(_, unit):
                    VStack(spacing: 16) {
                        Spacer(minLength: 0)
                        Text(problem.prompt)
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink).frame(maxWidth: .infinity)
                        Spacer(minLength: 0)
                        NumericKeypad(entry: $numericEntry, unit: unit, disabled: locked)
                            .onChange(of: numericEntry) { _, newValue in
                                // Auto-submit at the answer's digit count (right or wrong).
                                guard !locked, let a = currentAnswer else { return }
                                if newValue.count >= String(a).count { submit(correct: Int(newValue) == a) }
                            }
                        PrimaryButton(title: "Skip", enabled: !locked) { submit(correct: false) }
                    }
                    .padding()
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            timerRing
            Spacer()
            VStack(spacing: 0) {
                Text("\(score)").font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.crimson).contentTransition(.numericText())
                Text("score").font(.caption2).foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            comboPill
        }
    }

    private var timerRing: some View {
        ZStack {
            Circle().stroke(Theme.parchmentDeep, lineWidth: 6)
            Circle().trim(from: 0, to: max(0, timeLeft / Double(seconds)))
                .stroke(ringColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: timeLeft)
            Text("\(Int(ceil(timeLeft)))")
                .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(Theme.ink)
        }
        .frame(width: 56, height: 56)
    }

    private var ringColor: Color {
        timeLeft <= 5 ? Theme.danger : timeLeft <= 10 ? Theme.gold500 : Theme.success
    }

    private var comboPill: some View {
        VStack(spacing: 0) {
            Text(combo > 1 ? "×\(combo)" : "—")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(combo > 1 ? Theme.gold300 : Theme.inkSoft)
            Text("combo").font(.caption2).foregroundStyle(Theme.inkSoft)
        }
        .frame(minWidth: 52)
        .scaleEffect(combo > 1 ? 1.0 : 0.9)
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: combo)
    }

    // MARK: results
    @ViewBuilder private var results: some View {
        let acc = answered > 0 ? Int((Double(correctCount) / Double(answered) * 100).rounded()) : 0
        VStack(spacing: 16) {
            Text("Time!").font(.system(size: 40, weight: .heavy, design: .rounded)).foregroundStyle(Theme.crimson)
            if score > previousBest && score > 0 {
                Text("★ New personal best").font(.headline).foregroundStyle(Theme.gold300)
            }
            Text("\(score)").font(.system(size: 64, weight: .bold, design: .rounded)).foregroundStyle(Theme.ink)
            HStack(spacing: 22) {
                stat("\(correctCount)/\(answered)", "correct")
                stat("\(acc)%", "accuracy")
                stat("×\(bestCombo)", "best combo")
            }
            Text("Best: \(best)").font(.footnote).foregroundStyle(Theme.inkSoft)
            if !auth.isSignedIn {
                Text("Sign in to save progress and earn badges.")
                    .font(.footnote).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.center)
            }
            PrimaryButton(title: "Play again") { restart() }
            SecondaryButton(title: "Done") { onExit() }
        }
        .padding(28)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(Theme.ink)
            Text(label).font(.caption2).foregroundStyle(Theme.inkSoft)
        }
    }

    // MARK: logic
    private func step() {
        guard !finished else { return }
        timeLeft = max(0, timeLeft - 0.1)
        if timeLeft <= 0 { finish() }
    }

    private func nextProblem() {
        // De-dupe on identity, not prompt: map drills have an empty prompt, so keying on
        // prompt made every draw "match" and retry up to 8×, burning the shuffle bag ~9×
        // per question and reshuffling it constantly (clustered repeats). identity is the
        // region id, so the bag now advances one per question and cycles through all first.
        var p = def.generate(level)
        var tries = 0
        while recent.contains(p.identity) && tries < 8 { p = def.generate(level); tries += 1 }
        recent.append(p.identity)
        if recent.count > 3 { recent.removeFirst() }
        problem = p
        numericEntry = ""
    }

    private func submit(correct: Bool) {
        guard !locked, !finished else { return }
        locked = true
        answered += 1
        if correct {
            correctCount += 1
            combo += 1
            bestCombo = max(bestCombo, combo)
            score += 10 + (combo - 1) * 2   // combo bonus rewards streaks
            withAnimation { flash = true }
            Haptics.success()
        } else {
            combo = 0
            withAnimation { flash = false }
            Haptics.error()
        }
        Task {
            try? await Task.sleep(nanoseconds: correct ? 140_000_000 : 420_000_000)
            withAnimation { flash = nil }
            locked = false
            if !finished { nextProblem() }
        }
    }

    private func finish() {
        finished = true
        previousBest = best
        if score > best { best = score }
        guard auth.isSignedIn else { return }
        let body = DrillSessionBody(
            slug: def.slug, level: level, total: answered, correct: correctCount,
            bestStreak: bestCombo, mode: "timed",
            durationSec: seconds, score: score, clientId: makeClientId()
        )
        Task { _ = await queue.submit(path: "/drills/session", body: body, clientId: makeClientId()) }
    }

    private func restart() {
        finished = false
        timeLeft = Double(seconds)
        score = 0; combo = 0; bestCombo = 0; answered = 0; correctCount = 0
        locked = false; flash = nil
        startedAt = Date()
        nextProblem()
    }
}
