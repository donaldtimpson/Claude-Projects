import SwiftUI

// Learn mode — adaptive practice-to-mastery over a finite drill's items (on-device SRS,
// prototype v1). Weakest/newest items come up first; a miss re-queues the item to
// reappear a few cards later; a correct answer retires it for this session and raises its
// mastery box (DrillMastery). Mastery persists on-device across sessions.
struct LearnDrillView: View {
    let def: DrillDef
    let level: Int
    let userId: String
    let onExit: () -> Void

    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var queue: WriteQueueManager

    @State private var items: [String] = []       // full pool at this difficulty
    @State private var queueIds: [String] = []     // working in-session queue
    @State private var currentId: String?
    @State private var problem: DrillProblem?
    @State private var choice: Int?
    @State private var revealed = false
    @State private var wasCorrect = false
    @State private var answered = 0
    @State private var correctCount = 0
    @State private var masteredNow = 0
    @State private var startedAt = Date()
    @State private var finished = false

    private let store = DrillMastery.shared

    var body: some View {
        Group {
            if finished {
                summary
            } else if let problem, case let .choice(options, correctIndex) = problem.input {
                play(problem: problem, options: options, correctIndex: correctIndex)
            } else {
                ProgressView().tint(Theme.gold300)
            }
        }
        .navigationTitle("Learn").navigationBarTitleDisplayMode(.inline)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.parchment)
        .onAppear(perform: setup)
    }

    // MARK: play
    @ViewBuilder private func play(problem: DrillProblem, options: [String], correctIndex: Int) -> some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if let diagram = problem.diagram {
                        DrillDiagram(spec: diagram).frame(maxWidth: .infinity)
                    }
                    let useGrid = problem.forceGrid || options.allSatisfy { $0.count <= 12 }
                    OptionButtons(options: options, correctIndex: correctIndex, selected: choice,
                                  revealed: revealed, grid: useGrid, optionImages: problem.optionImages) { i in
                        guard !revealed else { return }
                        answer(i, correctIndex: correctIndex)
                    }
                    if revealed {
                        feedback(problem)
                        Text("Tap to continue").font(.footnote).foregroundStyle(Theme.inkSoft)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding()
            }
        }
        .overlay {
            if revealed {
                Color.clear.contentShape(Rectangle()).onTapGesture { advance() }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            QuizProgressBar(fraction: items.isEmpty ? 0 : Double(masteredNow) / Double(items.count))
            HStack {
                Text("Mastered \(masteredNow) / \(items.count)")
                    .font(.footnote).foregroundStyle(Theme.inkSoft)
                Spacer()
                Text("\(queueIds.count) left").font(.footnote).foregroundStyle(Theme.inkSoft)
            }
        }
        .padding()
    }

    @ViewBuilder private func feedback(_ problem: DrillProblem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(wasCorrect ? "Correct ✓" : "Not quite ✗")
                .font(.headline).foregroundStyle(wasCorrect ? Theme.success : Theme.danger)
            if let explanation = problem.explanation {
                Text(explanation).font(.callout).foregroundStyle(Theme.ink)
            }
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.parchmentDeep).clipShape(RoundedRectangle(cornerRadius: 10))
        .transition(.opacity)
    }

    // MARK: summary
    @ViewBuilder private var summary: some View {
        VStack(spacing: 18) {
            Text(masteredNow == items.count && !items.isEmpty ? "✦" : "✓")
                .font(.system(size: 52)).foregroundStyle(Theme.gold400)
            Text(masteredNow == items.count && !items.isEmpty ? "All mastered!" : "Session complete")
                .font(.title.weight(.bold)).foregroundStyle(Theme.crimson)
            Text("Mastered \(masteredNow) / \(items.count)").foregroundStyle(Theme.ink)
            Text("\(correctCount) / \(answered) correct this session")
                .font(.footnote).foregroundStyle(Theme.inkSoft)
            if !auth.isSignedIn {
                Text("Sign in to save drill progress and earn badges.")
                    .font(.footnote).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.center)
            }
            PrimaryButton(title: "Keep going") { finished = false; setup() }
            SecondaryButton(title: "Done") { onExit() }
        }
        .padding(32)
    }

    // MARK: logic
    private func setup() {
        items = def.poolItems?(level) ?? []
        masteredNow = store.masteredCount(userId: userId, slug: def.slug, items: items)
        queueIds = store.buildDeck(userId: userId, slug: def.slug, items: items)
        answered = 0; correctCount = 0
        startedAt = Date()
        present()
    }

    private func present() {
        guard let id = queueIds.first else { finish(); return }
        currentId = id
        problem = def.problemForItem?(id, level)
        choice = nil
        revealed = false
    }

    private func answer(_ i: Int, correctIndex: Int) {
        guard !revealed, let id = currentId else { return }
        let correct = i == correctIndex
        choice = i
        wasCorrect = correct
        withAnimation(.easeInOut(duration: 0.2)) { revealed = true }
        answered += 1
        if correct { correctCount += 1; Haptics.success() } else { Haptics.error() }
        store.grade(userId: userId, slug: def.slug, item: id, correct: correct)
        masteredNow = store.masteredCount(userId: userId, slug: def.slug, items: items)
    }

    private func advance() {
        guard !queueIds.isEmpty else { finish(); return }
        let id = queueIds.removeFirst()
        if !wasCorrect {
            queueIds.insert(id, at: min(4, queueIds.count))   // resurface soon
        }
        present()
    }

    private func finish() {
        finished = true
        recordSession()
    }

    // A Learn session IS practice — record a count-mode session so it feeds the streak
    // and existing drill badges. Per-item mastery stays on-device.
    private func recordSession() {
        guard auth.isSignedIn, answered > 0 else { return }
        let body = DrillSessionBody(
            slug: def.slug, level: level, total: answered, correct: correctCount,
            bestStreak: 0, mode: "count",
            durationSec: Int(Date().timeIntervalSince(startedAt)), clientId: makeClientId()
        )
        Task { _ = await queue.submit(path: "/drills/session", body: body, clientId: makeClientId()) }
    }
}
