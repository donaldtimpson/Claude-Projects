import SwiftUI

enum DrillMode: Hashable { case practice, learn, rapidFire }

struct DrillRunnerView: View {
    let slug: String
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var queue: WriteQueueManager
    @Environment(\.dismiss) private var dismiss
    private var userId: String { auth.user?.id ?? "guest" }

    @State private var level: Int?
    @State private var problem: DrillProblem?
    @State private var answered = 0
    @State private var correctCount = 0
    @State private var streak = 0
    @State private var bestStreak = 0
    @State private var startedAt = Date()

    @State private var numericEntry = ""
    @State private var choice: Int?
    @State private var tappedRegion: String?   // tap-to-locate: the region the user tapped
    @State private var revealed = false
    @State private var wasCorrect = false
    @State private var finished = false
    @State private var mode: DrillMode = .practice
    @State private var rapidSeconds = 60
    @State private var launchedLevel: Int?   // rapid/learn present at this difficulty
    @State private var recentPrompts: [String] = []
    @State private var practiceLen = 10   // 10, 20, or 0 = All (whole pool at that difficulty)

    @State private var count = 10
    private var def: DrillDef? { DrillCatalog.drill(slug: slug) }

    var body: some View {
        Group {
            if let def {
                if finished {
                    summaryView
                } else if let lvl = launchedLevel, mode == .rapidFire {
                    RapidFireView(def: def, level: lvl, seconds: rapidSeconds) { launchedLevel = nil }
                } else if let lvl = launchedLevel, mode == .learn {
                    LearnDrillView(def: def, level: lvl, userId: userId) { launchedLevel = nil }
                } else if let level, let problem {
                    if def.landscape {
                        locateRunner(def: def, level: level, problem: problem)
                    } else {
                        runner(def: def, level: level, problem: problem)
                    }
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
        .task { await syncBests() }
    }

    // Pull the server's synced Rapid Fire bests into local storage (merge by max),
    // so high scores follow the user across devices. Recording a run pushes up;
    // this pulls down. Offline / signed-out just keeps the local values.
    private func syncBests() async {
        guard auth.isSignedIn,
              let me: MeResponse = try? await APIClient.shared.get("/me") else { return }
        for b in me.drillBests ?? [] where b.slug == slug {
            let key = rapidBestKey(b.level, b.durationSec)
            if b.best > UserDefaults.standard.integer(forKey: key) {
                UserDefaults.standard.set(b.best, forKey: key)
            }
        }
    }

    // MARK: setup
    @ViewBuilder private func setup(_ def: DrillDef) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                Text(def.icon).font(.system(size: 64))
                Text(def.blurb).foregroundStyle(Theme.ink).multilineTextAlignment(.center)

                Picker("Mode", selection: $mode) {
                    Text("Practice").tag(DrillMode.practice)
                    if def.poolItems != nil { Text("Learn").tag(DrillMode.learn) }
                    Text("Rapid Fire").tag(DrillMode.rapidFire)
                }
                .pickerStyle(.segmented)

                switch mode {
                case .rapidFire:
                    Picker("Length", selection: $rapidSeconds) {
                        Text("60s").tag(60)
                        Text("120s").tag(120)
                    }
                    .pickerStyle(.segmented)
                case .practice:
                    Picker("Length", selection: $practiceLen) {
                        Text("10").tag(10)
                        Text("20").tag(20)
                        if def.poolSize != nil { Text("All").tag(0) }
                    }
                    .pickerStyle(.segmented)
                case .learn:
                    EmptyView()
                }

                Text(modeBlurb)
                    .font(.footnote).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.center)

                Text("Choose a difficulty")
                    .font(.display(13)).kerning(1).foregroundStyle(Theme.gold400)
                ForEach([(1, "Easy"), (2, "Medium"), (3, "Hard")], id: \.0) { value, label in
                    VStack(spacing: 4) {
                        SecondaryButton(title: label) { start(def: def, level: value) }
                        switch mode {
                        case .rapidFire:
                            let best = UserDefaults.standard.integer(forKey: rapidBestKey(value, rapidSeconds))
                            Text(best > 0 ? "\(rapidSeconds)s best · \(best)" : "No \(rapidSeconds)s score yet")
                                .font(.caption2)
                                .foregroundStyle(best > 0 ? Theme.gold400 : Theme.inkSoft)
                        case .learn:
                            let items = def.poolItems?(value) ?? []
                            let m = DrillMastery.shared.masteredCount(userId: userId, slug: slug, items: items)
                            Text("\(m) / \(items.count) mastered")
                                .font(.caption2)
                                .foregroundStyle(m > 0 ? Theme.gold400 : Theme.inkSoft)
                        case .practice:
                            EmptyView()
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: locate runner (landscape, full-screen pannable map)
    // Tap-to-locate plays in landscape (the maps are far wider than tall). Own top bar
    // (close + progress + streak) since the nav bar and status bar are hidden for a clean
    // full-screen map that stays within the safe area. The map fills the frame and pans.
    @ViewBuilder private func locateRunner(def: DrillDef, level: Int, problem: DrillProblem) -> some View {
        ForcedLandscape {
            VStack(spacing: 6) {
                HStack(spacing: 12) {
                    // Big liquid-glass close button — generous hit target, matches the glass
                    // result card. (The nav bar is hidden on this full-screen map.)
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.gold300)
                            .frame(width: 42, height: 42)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                            .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                    }
                    .contentShape(Circle())
                    QuizProgressBar(fraction: Double(answered) / Double(count))
                    Text("\(min(answered + 1, count)) / \(count)").font(.caption).foregroundStyle(Theme.inkSoft)
                    StreakPill(streak: streak)
                }
                Text("Find \(problem.prompt)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                if case let .mapTap(kind) = problem.input {
                    MapTapCard(kind: kind, targetId: problem.dedupeKey ?? "", revealed: revealed,
                               tappedId: tappedRegion, fillFrame: true) { tapped in
                        guard !revealed else { return }
                        tappedRegion = tapped
                        reveal(correct: tapped == problem.dedupeKey)
                    }
                    .frame(maxHeight: .infinity)
                    // Tap the map to advance only after answering (options/selection are off then).
                    .overlay {
                        if revealed {
                            Color.clear.contentShape(Rectangle())
                                .onTapGesture { next(def: def, level: level) }
                        }
                    }
                    // Compact glass card in the bottom-left so it hugs its text instead of
                    // spanning the map and hiding the region you tapped. Non-interactive so a
                    // tap on it still advances via the overlay above.
                    .overlay(alignment: .bottomLeading) {
                        if revealed {
                            locateFeedback(problem)
                                .padding(10)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Theme.parchment)
        .statusBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // Compact, translucent (liquid-glass) result card for the full-screen locate map — sized
    // to its text so it doesn't curtain off the map / the region you tapped.
    @ViewBuilder private func locateFeedback(_ problem: DrillProblem) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(wasCorrect ? "Correct ✓" : "Not quite ✗")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(wasCorrect ? Theme.success : Theme.danger)
            if let explanation = problem.explanation {
                Text(explanation).font(.caption).foregroundStyle(Theme.ink)
            }
            Text(answered >= count ? "Tap to finish" : "Tap to continue")
                .font(.caption2).foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.18), lineWidth: 0.5))
        .frame(maxWidth: 260, alignment: .leading)
        .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
    }

    // MARK: runner
    @ViewBuilder private func runner(def: DrillDef, level: Int, problem: DrillProblem) -> some View {
        VStack(spacing: 0) {
            header
            switch problem.input {
            case let .numeric(_, unit): numericBody(unit: unit, problem: problem)
            case let .choice(options, correctIndex): choiceBody(options: options, correctIndex: correctIndex, problem: problem)
            case let .mapTap(kind): mapTapBody(kind: kind, problem: problem)
            }
        }
        // Tap-anywhere-to-advance only exists AFTER answering (options are disabled then).
        // Pre-answer, a blanket tap gesture competes with the option buttons inside the
        // ScrollView — which broke selection once the tall map made the card scroll.
        .overlay {
            if revealed {
                Color.clear.contentShape(Rectangle())
                    .onTapGesture { next(def: def, level: level) }
            }
        }
    }

    private var header: some View {
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
    }

    // Numeric: big prompt up top, keypad + Check together in the thumb zone.
    @ViewBuilder private func numericBody(unit: String?, problem: DrillProblem) -> some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            Text(problem.prompt)
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
            if revealed {
                feedback(problem)
                tapHint
            }
            Spacer(minLength: 0)
            NumericKeypad(entry: $numericEntry, unit: unit, disabled: revealed)
                .onChange(of: numericEntry) { _, newValue in
                    // Auto-submit once the entry reaches the answer's digit count — no Check button.
                    guard !revealed, case let .numeric(answer, _) = problem.input else { return }
                    if newValue.count >= String(answer).count { submitNumeric(problem) }
                }
        }
        .padding()
    }

    // Choice: prompt + a 2×2 grid of tiles; tapping a tile answers immediately.
    @ViewBuilder private func choiceBody(options: [String], correctIndex: Int, problem: DrillProblem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if !problem.prompt.isEmpty {
                    Text(problem.prompt)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }

                if let diagram = problem.diagram {
                    DrillDiagram(spec: diagram).frame(maxWidth: .infinity)
                }

                // Layout is fixed per drill so it doesn't flip question to question:
                // forceGrid pins the 2×2 grid (country tiles stack the flag over the
                // name); otherwise short answers tile 2×2 and long ones fall back to a list.
                let useGrid = problem.forceGrid || options.allSatisfy { $0.count <= 12 }
                OptionButtons(options: options, correctIndex: correctIndex, selected: choice, revealed: revealed, grid: useGrid, optionImages: problem.optionImages) { i in
                    guard !revealed else { return }
                    choice = i
                    reveal(correct: i == correctIndex)
                }

                if revealed {
                    feedback(problem)
                    tapHint
                }
            }
            .padding()
        }
    }

    // Tap-to-locate (landscape): prompt on top, the wide map filling the rest; tap the
    // named region to answer. No scroll — everything fits the rotated frame. Feedback
    // overlays the map so it never squeezes the map out.
    @ViewBuilder private func mapTapBody(kind: GeoMapKind, problem: DrillProblem) -> some View {
        VStack(spacing: 8) {
            Text("Find \(problem.prompt)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .center)
            MapTapCard(kind: kind, targetId: problem.dedupeKey ?? "", revealed: revealed,
                       tappedId: tappedRegion, aspect: 2.1) { tapped in
                guard !revealed else { return }
                tappedRegion = tapped
                reveal(correct: tapped == problem.dedupeKey)
            }
            .frame(maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                if revealed {
                    VStack(spacing: 4) { feedback(problem); tapHint }
                        .padding(.horizontal, 12).padding(.bottom, 8)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private var tapHint: some View {
        Text(answered >= count ? "Tap to finish" : "Tap to continue")
            .font(.footnote).foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .center)
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
    // Rapid Fire best-score key (per drill, difficulty, sprint length) — matches RapidFireView.
    private func rapidBestKey(_ level: Int, _ seconds: Int) -> String { "rapidbest_\(slug)_L\(level)_\(seconds)" }

    private var modeBlurb: String {
        switch mode {
        case .rapidFire: return "Beat the clock — build a combo for a high score."
        case .learn: return "Practice until you've mastered them all — weak ones come back more."
        case .practice: return practiceLen == 0 ? "Every one, once, at your pace." : "\(practiceLen) problems at your pace."
        }
    }

    private func start(def: DrillDef, level value: Int) {
        switch mode {
        case .rapidFire, .learn:
            launchedLevel = value   // presented by RapidFireView / LearnDrillView
        case .practice:
            // Resolve the session length: 10/20, or "All" = the whole pool at this difficulty.
            count = practiceLen == 0 ? (def.poolSize?(value) ?? 20) : practiceLen
            // Fresh shuffle bag so the session (esp. "All") walks every region once, in order.
            DrillCatalog.resetBag(slug: slug, level: value)
            level = value
            startedAt = Date()
            answered = 0; correctCount = 0; streak = 0; bestStreak = 0
            generate(def: def, level: value)
        }
    }

    private func generate(def: DrillDef, level value: Int) {
        problem = freshProblem(def, value)
        numericEntry = ""
        choice = nil
        tappedRegion = nil
        revealed = false
    }

    // Avoid asking a question we just asked: retry a few times if the prompt
    // matches one of the last few. Capped so tiny-domain drills can't spin.
    private func freshProblem(_ def: DrillDef, _ value: Int) -> DrillProblem {
        var p = def.generate(value)
        var tries = 0
        while recentPrompts.contains(p.identity) && tries < 8 { p = def.generate(value); tries += 1 }
        recentPrompts.append(p.identity)
        if recentPrompts.count > 3 { recentPrompts.removeFirst() }
        return p
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
