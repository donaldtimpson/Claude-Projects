import SwiftUI

// Learn mode — a never-ending, adaptive practice session over a finite drill's items
// (on-device SRS, prototype v1). New items are introduced gradually (LearnSession:
// graduated introduction + expanding rehearsal), recently-seen items recur soon even when
// correct, and each correct answer raises the item's persistent mastery box. The session
// doesn't stop — you leave with Done. Works for both identify (.choice) and locate
// (.mapTap) drills.
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
    @State private var tappedId: String?
    @State private var toast: DrillResultToast?   // instant-advance result popover (web-style)
    @State private var toastSeq = 0
    @State private var locked = false              // guard so a fast double-tap can't skip an item
    @State private var masteredNow = 0
    @State private var total = 0
    @State private var startedAt = Date()

    var body: some View {
        Group {
            if let problem {
                VStack(spacing: 0) {
                    header
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            content(problem)
                            if let toast { DrillToastCard(toast: toast) }
                        }
                        .padding()
                    }
                }
            } else {
                ProgressView().tint(Theme.gold300)
            }
        }
        .navigationTitle("Learn").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { onExit() }.tint(Theme.gold300) } }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.parchment)
        .onAppear(perform: setup)
        .onDisappear(perform: recordSession)
        .task(id: toast?.seq) {
            guard let t = toast else { return }
            try? await Task.sleep(nanoseconds: t.ok ? 900_000_000 : 1_800_000_000)
            if toast?.seq == t.seq { withAnimation { toast = nil } }
        }
    }

    @ViewBuilder private func content(_ problem: DrillProblem) -> some View {
        switch problem.input {
        case let .choice(options, correctIndex):
            if let diagram = problem.diagram {
                DrillDiagram(spec: diagram).frame(maxWidth: .infinity)
            }
            let useGrid = problem.forceGrid || options.allSatisfy { $0.count <= 12 }
            OptionButtons(options: options, correctIndex: correctIndex, selected: choice,
                          revealed: false, grid: useGrid, optionImages: problem.optionImages) { i in
                guard !locked else { return }
                choice = i
                grade(correct: i == correctIndex)
            }
        case let .mapTap(kind):
            Text("Find \(problem.prompt)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink).frame(maxWidth: .infinity, alignment: .center)
            MapTapCard(kind: kind, targetId: problem.dedupeKey ?? "", revealed: false, tappedId: tappedId) { tapped in
                guard !locked else { return }
                tappedId = tapped
                grade(correct: tapped == problem.dedupeKey)
            }
        case .numeric:
            EmptyView()   // Learn is only offered for map drills
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
        tappedId = nil
    }

    private func grade(correct: Bool) {
        if correct { Haptics.success() } else { Haptics.error() }
        session?.grade(correct: correct)
        masteredNow = session?.masteredCount ?? masteredNow
        // Web parity: pop the result as a transient toast and advance instantly. Advancing
        // one runloop later keeps `locked` true through this touch batch (no double-answer).
        toastSeq += 1
        toast = DrillResultToast(seq: toastSeq, ok: correct, detail: correct ? nil : problem?.explanation)
        locked = true
        DispatchQueue.main.async { present(); locked = false }
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
