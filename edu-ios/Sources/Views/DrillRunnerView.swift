import SwiftUI

enum DrillMode: String { case practice, learn, rapidFire }

// Compact, translucent (liquid-glass) result card — correct/not-quite plus the answer,
// sized to its text. Shown over the map during the brief reveal on the geography drills.
struct DrillResultCard: View {
    let ok: Bool
    let detail: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(ok ? "Correct ✓" : "Not quite ✗")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(ok ? Theme.success : Theme.danger)
            if let detail {
                Text(detail).font(.caption).foregroundStyle(Theme.ink)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.18), lineWidth: 0.5))
        .frame(maxWidth: 260, alignment: .leading)
        .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
        .transition(.opacity)
    }
}

// Full-screen tint that blinks green/red on a geography answer — hard-to-miss feedback
// (paired with the success/error haptics). Matches RapidFireView's flash exactly: a
// persistent layer that animates its color (0.22 opacity, ease-out 0.15s), sitting BEHIND
// the content so it washes the margins rather than tinting the map itself.
struct DrillFlash: View {
    let correct: Bool?
    var body: some View {
        (correct == nil ? Color.clear : (correct! ? Theme.success : Theme.danger).opacity(0.22))
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .animation(.easeOut(duration: 0.15), value: correct)
    }
}

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
    @State private var revealed = false   // math drills: hold the result until "tap to continue"
    @State private var wasCorrect = false
    @State private var finished = false
    // Geography drills auto-advance after a brief reveal; `flash` blinks the background.
    @State private var flash: Bool?
    @State private var locked = false     // Rapid-Fire-style guard for the instant-advance drills
    // Remembered across launches (global last-used config) so you don't reconfigure every
    // time; sanitized per-drill in setup() when a stored choice isn't available for a drill.
    @AppStorage("drill_last_mode") private var mode: DrillMode = .practice
    /// A homework drill has exactly one shape — the fixed-length run that earns the ✦ —
    /// so Practice / Learn / Rapid Fire is a choice with no meaning there. `mode` is a
    /// SINGLE preference shared by every drill, so without this a Rapid Fire round on a
    /// math drill would drop the next lesson straight into a timed "homework" run.
    /// Overridden for the duration rather than written to, so the stored preference
    /// survives for the drills where it does mean something.
    private var activeMode: DrillMode { def?.homeworkLength != nil ? .practice : mode }
    @AppStorage("drill_last_rapidSeconds") private var rapidSeconds = 60
    @AppStorage("drill_last_practiceLen") private var practiceLen = 10   // 10, 20, or 0 = All
    /// Lesson drills offer the same two sessions the web does: the homework run, or a
    /// short practice. Defaults to homework and is deliberately NOT persisted — the
    /// point of opening a lesson is the homework, and web resets to it each visit too.
    @State private var lessonHomework = true
    @State private var launchedLevel: Int?   // rapid/learn present at this difficulty
    @State private var recentPrompts: [String] = []

    @State private var count = 10
    private var def: DrillDef? { DrillCatalog.drill(slug: slug) }

    var body: some View {
        ZStack {
            Theme.parchment.ignoresSafeArea()
            DrillFlash(correct: flash)   // behind the content, like Rapid Fire
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(def?.title ?? "Drill")
        .navigationBarTitleDisplayMode(.inline)
        .task { await syncBests() }
    }

    @ViewBuilder private var content: some View {
        if let def {
            if finished {
                summaryView
            } else if let lvl = launchedLevel, activeMode == .rapidFire {
                RapidFireView(def: def, level: lvl, seconds: rapidSeconds) { launchedLevel = nil }
            } else if let lvl = launchedLevel, activeMode == .learn {
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
    // Drop a remembered choice that this particular drill can't offer (Learn needs a pool;
    // "All" length needs a finite pool), so the picker never sits on an unavailable value.
    private func sanitizeConfig(_ def: DrillDef) {
        if mode == .learn && def.poolItems == nil { mode = .practice }
        if practiceLen == 0 && def.poolSize == nil { practiceLen = 10 }
    }

    @ViewBuilder private func setup(_ def: DrillDef) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                Text(def.icon).font(.system(size: 64))
                Text(def.blurb).foregroundStyle(Theme.ink).multilineTextAlignment(.center)

                if def.homeworkLength == nil {
                    Picker("Mode", selection: $mode) {
                        Text("Practice").tag(DrillMode.practice)
                        if def.poolItems != nil { Text("Learn").tag(DrillMode.learn) }
                        Text("Rapid Fire").tag(DrillMode.rapidFire)
                    }
                    .pickerStyle(.segmented)
                }

                switch activeMode {
                case .rapidFire:
                    Picker("Length", selection: $rapidSeconds) {
                        Text("60s").tag(60)
                        Text("120s").tag(120)
                    }
                    .pickerStyle(.segmented)
                case .practice:
                    if let hl = def.homeworkLength {
                        Picker("Session", selection: $lessonHomework) {
                            Text("Homework · \(hl)").tag(true)
                            Text("Practice · 10").tag(false)
                        }
                        .pickerStyle(.segmented)
                    } else {
                        Picker("Length", selection: $practiceLen) {
                            Text("10").tag(10)
                            Text("20").tag(20)
                            if def.poolSize != nil { Text("All").tag(0) }
                        }
                        .pickerStyle(.segmented)
                    }
                case .learn:
                    EmptyView()
                }

                Text(modeBlurb)
                    .font(.footnote).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.center)

                // Drills with a meaningful Easy/Medium/Hard axis (math, geography, the Grammar
                // Gauntlet's concept tiers) get three buttons; single-concept drills, where a
                // 3-way split would be arbitrary, get one Start and always run the full pool.
                if def.difficultyTiers {
                    Text("Choose a difficulty")
                        .font(.display(13)).kerning(1).foregroundStyle(Theme.gold400)
                    ForEach([(1, "Easy"), (2, "Medium"), (3, "Hard")], id: \.0) { value, label in
                        VStack(spacing: 4) {
                            SecondaryButton(title: label) { start(def: def, level: value) }
                            difficultyStat(def, value)
                        }
                    }
                } else {
                    VStack(spacing: 4) {
                        PrimaryButton(title: "Start") { start(def: def, level: 3) }
                        difficultyStat(def, 3)
                    }
                }
            }
            .padding()
        }
        .onAppear { sanitizeConfig(def) }
    }

    // The per-mode stat under a difficulty button (Rapid Fire best / Learn mastery / nothing).
    @ViewBuilder private func difficultyStat(_ def: DrillDef, _ value: Int) -> some View {
        switch activeMode {
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

    // MARK: locate runner — the shared full-screen landscape map (same as Learn / Rapid Fire).
    @ViewBuilder private func locateRunner(def: DrillDef, level: Int, problem: DrillProblem) -> some View {
        if case let .mapTap(kind) = problem.input {
            LocateScreen(
                kind: kind, targetId: problem.dedupeKey ?? "", prompt: problem.prompt,
                revealed: revealed, tappedId: tappedRegion, flash: flash,
                resultOK: wasCorrect, resultDetail: wasCorrect ? nil : problem.explanation,
                onAdvanceTap: { next(def: def, level: level) },
                onTap: { tapped in
                    guard !revealed else { return }
                    tappedRegion = tapped
                    reveal(correct: tapped == problem.dedupeKey)
                }
            ) {
                HStack(spacing: 12) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
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
            }
        }
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
                let useGrid = !problem.forceList && (problem.forceGrid || options.allSatisfy { $0.count <= 12 })
                // Identify ("Name the…") matches Rapid Fire: no option-color reveal, just the
                // background blink + advance. Math choice drills still reveal + wait for a tap.
                OptionButtons(options: options, correctIndex: correctIndex, selected: choice, revealed: isIdentify ? false : revealed, grid: useGrid, optionImages: problem.optionImages) { i in
                    guard !revealed, !locked else { return }
                    choice = i
                    reveal(correct: i == correctIndex)
                }

                if revealed {   // only the math choice drills set `revealed`
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
            if def?.homeworkLength != nil, pct < 100 {
                Text("Homework needs a flawless run — try again for the ✦.")
                    .font(.footnote).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.center)
            }
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
        switch activeMode {
        case .rapidFire: return "Beat the clock — build a combo for a high score."
        case .learn: return "Practice until you've mastered them all — weak ones come back more."
        case .practice:
            if let hl = def?.homeworkLength {
                return lessonHomework
                    ? "A random \(hl) from the pool. Get every one right to earn the ✦ — full credit if this lesson is assigned in your class."
                    : "10 questions at your pace. Practice only — the ✦ needs the full \(hl)."
            }
            return practiceLen == 0 ? "Every one, once, at your pace." : "\(practiceLen) problems at your pace."
        }
    }

    private func start(def: DrillDef, level value: Int) {
        switch activeMode {
        case .rapidFire, .learn:
            launchedLevel = value   // presented by RapidFireView / LearnDrillView
        case .practice:
            // A lesson runs its homework length, or a short practice if that was chosen
            // (a flawless 10 can't ace: the server needs correct == total AND total >= 30).
            // Every other drill uses 10/20/All.
            if let hl = def.homeworkLength {
                count = lessonHomework ? hl : 10
            } else {
                count = practiceLen == 0 ? (def.poolSize?(value) ?? 20) : practiceLen
            }
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
        flash = nil
        locked = false
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

    // Geography drills (identify + locate) — the map IS the question, so we auto-advance
    // like the web version instead of demanding a "tap to continue" second tap.
    // Identify ("Name the Country / State") — choice + highlighted-map diagram.
    private var isIdentify: Bool {
        if case .geoMap? = problem?.diagram { return true }
        return false
    }
    // Locate ("Where's the Country / State") — tap the region on the map.
    private var isLocate: Bool {
        if case .mapTap = problem?.input { return true }
        return false
    }

    private func reveal(correct: Bool) {
        wasCorrect = correct
        answered += 1
        if correct {
            correctCount += 1; streak += 1; bestStreak = max(bestStreak, streak)
            Haptics.success()
        } else {
            streak = 0
            Haptics.error()
        }
        guard let def, let lvl = level else {
            withAnimation(.easeInOut(duration: 0.2)) { revealed = true }
            return
        }
        let token = problem?.id
        if isIdentify {
            // EXACTLY like Rapid Fire: blink the background, hold briefly (no option reveal,
            // no card), then advance. `locked` guards a double-answer for this touch batch.
            locked = true
            flash = correct
            DispatchQueue.main.asyncAfter(deadline: .now() + (correct ? 0.14 : 0.42)) {
                flash = nil
                locked = false
                if problem?.id == token { next(def: def, level: lvl) }
            }
        } else if isLocate {
            // Locate needs the green/red map reveal (no hover on iOS), held a beat, then advance.
            withAnimation(.easeInOut(duration: 0.2)) { revealed = true }
            flash = correct
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { if revealed { flash = nil } }
            DispatchQueue.main.asyncAfter(deadline: .now() + (correct ? 0.7 : 1.4)) {
                guard revealed, problem?.id == token else { return }
                next(def: def, level: lvl)
            }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) { revealed = true }   // math: tap to continue
        }
    }

    private func next(def: DrillDef, level value: Int) {
        if answered >= count {
            // Homework: a flawless run earns the lesson's ✦ (on-device, honor system).
            if def.homeworkLength != nil && correctCount == count {
                LessonProgress.shared.markAced(userId: userId, slug: slug)
            }
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
