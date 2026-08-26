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
    @State private var revealed = false            // locate: hold the green/red map reveal
    @State private var wasCorrect = false
    @State private var flash: Bool?                // green/red background blink on an answer
    @State private var locked = false              // identify (Rapid-Fire-style) double-tap guard
    @State private var masteredNow = 0
    @State private var progressNow = 0.0   // partial credit toward mastery — see LearnSession.progress
    @State private var total = 0
    @State private var startedAt = Date()

    private var isIdentify: Bool { if case .geoMap? = problem?.diagram { return true }; return false }
    private var isLocate: Bool { if case .mapTap = problem?.input { return true }; return false }

    var body: some View {
        Group {
            if let problem {
                if case let .mapTap(kind) = problem.input {
                    // Locate: the shared full-screen landscape map (same as Practice / Rapid Fire).
                    LocateScreen(
                        kind: kind, targetId: problem.dedupeKey ?? "", prompt: problem.prompt,
                        revealed: revealed, tappedId: tappedId, flash: flash,
                        resultOK: wasCorrect, resultDetail: wasCorrect ? nil : problem.explanation,
                        onAdvanceTap: { present() },
                        onTap: { tapped in
                            guard !revealed else { return }
                            tappedId = tapped
                            grade(correct: tapped == problem.dedupeKey)
                        }
                    ) {
                        HStack(spacing: 12) {
                            Button { onExit() } label: {
                                Image(systemName: "xmark")
                                    .font(.body.weight(.semibold)).foregroundStyle(Theme.gold300)
                                    .frame(width: 42, height: 42)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                                    .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                            }
                            .contentShape(Circle())
                            QuizProgressBar(fraction: progressNow)
                            Text("Mastered \(masteredNow) / \(total)").font(.caption).foregroundStyle(Theme.inkSoft)
                        }
                    }
                } else {
                    identifyBody(problem)
                }
            } else {
                ProgressView().tint(Theme.gold300)
            }
        }
        .navigationTitle("Learn").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { onExit() }.tint(Theme.gold300) } }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: setup)
        .onDisappear(perform: recordSession)
    }

    // Identify ("Name the…") stays portrait: highlighted map + flag options, Rapid-Fire blink.
    @ViewBuilder private func identifyBody(_ problem: DrillProblem) -> some View {
        ZStack {
            Theme.parchment.ignoresSafeArea()
            DrillFlash(correct: flash)
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        if let diagram = problem.diagram {
                            DrillDiagram(spec: diagram).frame(maxWidth: .infinity)
                        }
                        if case let .choice(options, correctIndex) = problem.input {
                            let useGrid = problem.forceGrid || options.allSatisfy { $0.count <= 12 }
                            OptionButtons(options: options, correctIndex: correctIndex, selected: choice,
                                          revealed: false, grid: useGrid, optionImages: problem.optionImages) { i in
                                guard !locked else { return }
                                choice = i
                                grade(correct: i == correctIndex)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            QuizProgressBar(fraction: progressNow)
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
        progressNow = s.progress
        startedAt = Date()
        present()
    }

    private func present() {
        guard let id = session?.next() else { return }
        problem = def.problemForItem?(id, level)
        choice = nil
        tappedId = nil
        revealed = false
        flash = nil
        locked = false
    }

    private func grade(correct: Bool) {
        wasCorrect = correct
        if correct { Haptics.success() } else { Haptics.error() }
        session?.grade(correct: correct)
        masteredNow = session?.masteredCount ?? masteredNow
        progressNow = session?.progress ?? progressNow
        let token = problem?.id
        if isIdentify {
            // EXACTLY like Rapid Fire: blink, brief hold (no option reveal / card), advance.
            locked = true
            flash = correct
            DispatchQueue.main.asyncAfter(deadline: .now() + (correct ? 0.14 : 0.42)) {
                flash = nil
                locked = false
                if problem?.id == token { present() }
            }
        } else {
            // Locate: green/red map reveal held a beat, then advance (an early tap skips).
            withAnimation(.easeInOut(duration: 0.2)) { revealed = true }
            flash = correct
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { if revealed { flash = nil } }
            DispatchQueue.main.asyncAfter(deadline: .now() + (correct ? 0.7 : 1.4)) {
                guard revealed, problem?.id == token else { return }
                present()
            }
        }
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
