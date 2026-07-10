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

    @State private var numericText = ""
    @State private var fieldTexts: [String] = []
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
            VStack(spacing: 16) {
                Text(def.icon).font(.system(size: 56))
                Text(def.blurb).foregroundStyle(Theme.ink).multilineTextAlignment(.center)
                Text("Choose a difficulty").font(.subheadline).foregroundStyle(Theme.inkSoft)
                ForEach([(1, "Easy"), (2, "Medium"), (3, "Hard")], id: \.0) { value, label in
                    SecondaryButton(title: label) { start(def: def, level: value) }
                }
            }
            .padding()
        }
    }

    // MARK: runner
    @ViewBuilder private func runner(def: DrillDef, level: Int, problem: DrillProblem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(min(answered + (revealed ? 0 : 1), count)) / \(count)  ·  streak \(streak)")
                    .font(.footnote).foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text(problem.prompt).font(.title3).fontWeight(.semibold).foregroundStyle(Theme.ink)

                inputWidget(problem)

                if revealed {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(wasCorrect ? "Correct ✓" : "Not quite ✗")
                            .fontWeight(.bold)
                            .foregroundStyle(wasCorrect ? Theme.success : Theme.danger)
                        if let explanation = problem.explanation {
                            Text(explanation).font(.callout).foregroundStyle(Theme.ink)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.parchmentDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if !revealed {
                    PrimaryButton(title: "Check", enabled: canCheck(problem)) { check(problem) }
                } else {
                    PrimaryButton(title: answered >= count ? "Finish" : "Next") { next(def: def, level: level) }
                }
            }
            .padding()
        }
    }

    @ViewBuilder private func inputWidget(_ problem: DrillProblem) -> some View {
        switch problem.input {
        case let .choice(options, correctIndex):
            VStack(spacing: 8) {
                ForEach(options.indices, id: \.self) { i in
                    Button { if !revealed { choice = i } } label: {
                        Text(options[i]).foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading).padding()
                            .background(choiceBg(i, correctIndex))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(choiceBorder(i, correctIndex), lineWidth: 1.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain).disabled(revealed)
                }
            }
        case let .numeric(_, _, unit):
            HStack {
                TextField("answer", text: $numericText)
                    .keyboardType(.numbersAndPunctuation)
                    .textFieldStyle(.roundedBorder)
                    .disabled(revealed)
                if let unit { Text(unit).foregroundStyle(Theme.ink) }
            }
        case let .fields(fields):
            VStack(spacing: 8) {
                ForEach(fields.indices, id: \.self) { i in
                    HStack {
                        Text(fields[i].label).foregroundStyle(Theme.ink).frame(minWidth: 44, alignment: .leading)
                        TextField("?", text: binding(for: i, count: fields.count))
                            .keyboardType(.numbersAndPunctuation)
                            .textFieldStyle(.roundedBorder)
                            .disabled(revealed)
                        if let unit = fields[i].unit { Text(unit).foregroundStyle(Theme.ink) }
                    }
                }
            }
        }
    }

    // MARK: summary
    @ViewBuilder private var summaryView: some View {
        VStack(spacing: 16) {
            Text("Nice work").font(.title.weight(.bold)).foregroundStyle(Theme.crimson)
            Text("\(correctCount) / \(count) correct").foregroundStyle(Theme.ink)
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
    private func binding(for i: Int, count: Int) -> Binding<String> {
        Binding(
            get: { i < fieldTexts.count ? fieldTexts[i] : "" },
            set: { newValue in
                if fieldTexts.count != count { fieldTexts = Array(repeating: "", count: count) }
                fieldTexts[i] = newValue
            }
        )
    }

    private func start(def: DrillDef, level value: Int) {
        level = value
        startedAt = Date()
        answered = 0; correctCount = 0; streak = 0; bestStreak = 0
        generate(def: def, level: value)
    }

    private func generate(def: DrillDef, level value: Int) {
        let p = def.generate(value)
        problem = p
        numericText = ""
        choice = nil
        revealed = false
        if case let .fields(fields) = p.input {
            fieldTexts = Array(repeating: "", count: fields.count)
        } else {
            fieldTexts = []
        }
    }

    private func canCheck(_ problem: DrillProblem) -> Bool {
        switch problem.input {
        case .choice: return choice != nil
        case .numeric: return !numericText.trimmingCharacters(in: .whitespaces).isEmpty
        case let .fields(fields):
            return fields.indices.allSatisfy { i in
                i < fieldTexts.count && !fieldTexts[i].trimmingCharacters(in: .whitespaces).isEmpty
            }
        }
    }

    private func check(_ problem: DrillProblem) {
        let correct = grade(problem)
        wasCorrect = correct
        revealed = true
        answered += 1
        if correct { correctCount += 1; streak += 1; bestStreak = max(bestStreak, streak) } else { streak = 0 }
    }

    private func grade(_ problem: DrillProblem) -> Bool {
        switch problem.input {
        case let .numeric(answer, tolerance, _):
            return numericMatch(numericText, answer, tolerance)
        case let .choice(_, correctIndex):
            return choice == correctIndex
        case let .fields(fields):
            return fields.enumerated().allSatisfy { idx, field in
                numericMatch(idx < fieldTexts.count ? fieldTexts[idx] : "", field.answer, field.tolerance)
            }
        }
    }

    private func numericMatch(_ text: String, _ answer: Double, _ tolerance: Double) -> Bool {
        let cleaned = text.filter { "0123456789.-".contains($0) }
        guard let value = Double(cleaned) else { return false }
        return abs(value - answer) <= max(tolerance, 1e-9)
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

    private func choiceBg(_ i: Int, _ correctIndex: Int) -> Color {
        guard revealed else { return i == choice ? Theme.parchmentDeep : Theme.card }
        if i == correctIndex { return Color(red: 0.906, green: 0.953, blue: 0.910) }
        if i == choice { return Color(red: 0.965, green: 0.890, blue: 0.890) }
        return Theme.card
    }

    private func choiceBorder(_ i: Int, _ correctIndex: Int) -> Color {
        guard revealed else { return i == choice ? Theme.crimson : Theme.line }
        if i == correctIndex { return Theme.success }
        if i == choice { return Theme.danger }
        return Theme.line
    }
}
