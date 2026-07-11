import SwiftUI

struct DrillRunnerView: View {
    let slug: String
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var queue: WriteQueueManager

    @State private var level: Int?
    @State private var problem: DrillProblem?
    @State private var answered = 0
    @State private var correctCount = 0
    @State private var streak = 0
    @State private var bestStreak = 0
    @State private var startedAt = Date()

    @State private var numericEntry = ""
    @State private var choice: Int?
    @State private var revealed = false
    @State private var wasCorrect = false
    @State private var finished = false

    private let count = 10
    private var def: DrillDef? { DrillCatalog.drill(slug: slug) }

    var body: some View {
        Group {
            if let def {
                if finished {
                    summaryView
                } else if let level, let problem {
                    runner(def: def, level: level, problem: problem)
                } else {
                    setup(def)
                }
            } else {
                Text("Unknown drill.").foregroundStyle(Theme.inkSoft)
            }
        }
        .navigationTitle(def?.title ?? "Drill")
        .navigationBarTitleDisplayMode(.inline)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.parchment)
    }

    // MARK: setup
    @ViewBuilder private func setup(_ def: DrillDef) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                Text(def.icon).font(.system(size: 64))
                Text(def.blurb).foregroundStyle(Theme.ink).multilineTextAlignment(.center)
                Text("Choose a difficulty")
                    .font(.display(13)).kerning(1).foregroundStyle(Theme.gold400)
                ForEach([(1, "Easy"), (2, "Medium"), (3, "Hard")], id: \.0) { value, label in
                    SecondaryButton(title: label) { start(def: def, level: value) }
                }
            }
            .padding()
        }
    }

    // MARK: runner
    @ViewBuilder private func runner(def: DrillDef, level: Int, problem: DrillProblem) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                QuizProgressBar(fraction: Double(answered) / Double(count))
                HStack {
                    Text("\(min(answered + 1, count)) / \(count)")
                        .font(.footnote).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    StreakPill(streak: streak)
                }
            }
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(problem.prompt)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)

                    inputWidget(problem)

                    if revealed {
                        feedback(problem)
                        Text(answered >= count ? "Tap to finish" : "Tap to continue")
                            .font(.footnote).foregroundStyle(Theme.inkSoft)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding()
            }

            // Multiple choice answers on tap; only numeric needs an explicit submit.
            if !revealed, isNumeric(problem) {
                VStack {
                    PrimaryButton(title: "Check", enabled: Int(numericEntry) != nil) { submitNumeric(problem) }
                }
                .padding()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { if revealed { next(def: def, level: level) } }
    }

    @ViewBuilder private func inputWidget(_ problem: DrillProblem) -> some View {
        switch problem.input {
        case let .choice(options, correctIndex):
            // Tapping a tile answers immediately (no Check button); 2×2 grid.
            OptionButtons(options: options, correctIndex: correctIndex, selected: choice, revealed: revealed, grid: true) { i in
                guard !revealed else { return }
                choice = i
                reveal(correct: i == correctIndex)
            }
        case let .numeric(_, unit):
            NumericKeypad(entry: $numericEntry, unit: unit, disabled: revealed)
        }
    }

    @ViewBuilder private func feedback(_ problem: DrillProblem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(wasCorrect ? "Correct ✓" : "Not quite ✗")
                .font(.headline)
                .foregroundStyle(wasCorrect ? Theme.success : Theme.danger)
            if let explanation = problem.explanation {
                Text(explanation).font(.callout).foregroundStyle(Theme.ink)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.parchmentDeep)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .transition(.opacity)
    }

    // MARK: summary
    @ViewBuilder private var summaryView: some View {
        let pct = count > 0 ? Int((Double(correctCount) / Double(count) * 100).rounded()) : 0
        VStack(spacing: 18) {
            Text(pct == 100 ? "✦" : "✓").font(.system(size: 52)).foregroundStyle(Theme.gold400)
            Text(pct == 100 ? "Flawless" : "Nice work").font(.title.weight(.bold)).foregroundStyle(Theme.crimson)
            Text("\(correctCount) / \(count) correct · \(pct)%").foregroundStyle(Theme.ink)
            HStack(spacing: 6) {
                Text("Best streak").font(.footnote).foregroundStyle(Theme.inkSoft)
                StreakPill(streak: bestStreak)
            }
            if !auth.isSignedIn {
                Text("Sign in to save drill progress and earn badges.")
                    .font(.footnote).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.center)
            }
            PrimaryButton(title: "Practice again") {
                finished = false; level = nil; problem = nil
            }
        }
        .padding(32)
    }

    // MARK: logic
    private func start(def: DrillDef, level value: Int) {
        level = value
        startedAt = Date()
        answered = 0; correctCount = 0; streak = 0; bestStreak = 0
        generate(def: def, level: value)
    }

    private func generate(def: DrillDef, level value: Int) {
        problem = def.generate(value)
        numericEntry = ""
        choice = nil
        revealed = false
    }

    private func isNumeric(_ problem: DrillProblem) -> Bool {
        if case .numeric = problem.input { return true }
        return false
    }

    private func submitNumeric(_ problem: DrillProblem) {
        guard case let .numeric(answer, _) = problem.input else { return }
        reveal(correct: Int(numericEntry) == answer)
    }

    private func reveal(correct: Bool) {
        wasCorrect = correct
        withAnimation(.easeInOut(duration: 0.2)) { revealed = true }
        answered += 1
        if correct {
            correctCount += 1; streak += 1; bestStreak = max(bestStreak, streak)
            Haptics.success()
        } else {
            streak = 0
            Haptics.error()
        }
    }

    private func next(def: DrillDef, level value: Int) {
        if answered >= count {
            record(level: value)
            finished = true
        } else {
            generate(def: def, level: value)
        }
    }

    private func record(level value: Int) {
        guard auth.isSignedIn else { return }
        let body = DrillSessionBody(
            slug: slug, level: value, total: answered, correct: correctCount,
            bestStreak: bestStreak, mode: "count",
            durationSec: Int(Date().timeIntervalSince(startedAt)), clientId: makeClientId()
        )
        Task { _ = await queue.submit(path: "/drills/session", body: body, clientId: makeClientId()) }
    }
}
