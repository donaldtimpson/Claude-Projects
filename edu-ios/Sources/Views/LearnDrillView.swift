import SwiftUI

// Learn mode — a never-ending, adaptive practice session over a finite drill's items
// (on-device SRS, prototype v1). New items are introduced gradually (LearnSession:
// graduated introduction + expanding rehearsal), recently-seen items recur soon even when
// correct, and each correct answer raises the item's persistent mastery box. The session
// doesn't stop — you leave with Done; once everything's mastered it keeps cycling.
struct LearnDrillView: View {
    let def: DrillDef
    let level: Int
    let userId: String
    let onExit: () -> Void

    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var queue: WriteQueueManager

    @State private var session: LearnSession?
    @State private var problem: DrillProblem?
    @State private var choice: Int?
    @State private var revealed = false
    @State private var wasCorrect = false
    @State private var masteredNow = 0
    @State private var total = 0
    @State private var startedAt = Date()

    var body: some View {
        Group {
            if let problem, case let .choice(options, correctIndex) = problem.input {
                play(problem: problem, options: options, correctIndex: correctIndex)
            } else {
                ProgressView().tint(Theme.gold300)
            }
        }
        .navigationTitle("Learn").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { onExit() } .tint(Theme.gold300) } }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.parchment)
        .onAppear(perform: setup)
        .onDisappear(perform: recordSession)
    }

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
                Color.clear.contentShape(Rectangle()).onTapGesture { present() }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            QuizProgressBar(fraction: total > 0 ? Double(masteredNow) / Double(total) : 0)
            Text("Mastered \(masteredNow) / \(total)")
                .font(.footnote).foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: logic
    private func setup() {
        let s = LearnSession(userId: userId, slug: def.slug, items: def.poolItems?(level) ?? [])
        session = s
        total = s.items.count
        masteredNow = s.masteredCount
        startedAt = Date()
        present()
    }

    private func present() {
        guard let id = session?.next() else { return }
        problem = def.problemForItem?(id, level)
        choice = nil
        revealed = false
    }

    private func answer(_ i: Int, correctIndex: Int) {
        guard !revealed, let session else { return }
        let correct = i == correctIndex
        choice = i
        wasCorrect = correct
        withAnimation(.easeInOut(duration: 0.2)) { revealed = true }
        if correct { Haptics.success() } else { Haptics.error() }
        session.grade(correct: correct)
        masteredNow = session.masteredCount
    }

    // A Learn session IS practice — record a count-mode session on exit so it feeds the
    // streak and existing drill badges. Per-item mastery stays on-device.
    private func recordSession() {
        guard auth.isSignedIn, let session, session.answered > 0 else { return }
        let body = DrillSessionBody(
            slug: def.slug, level: level, total: session.answered, correct: session.correctCount,
            bestStreak: 0, mode: "count",
            durationSec: Int(Date().timeIntervalSince(startedAt)), clientId: makeClientId()
        )
        Task { _ = await queue.submit(path: "/drills/session", body: body, clientId: makeClientId()) }
    }
}
