import SwiftUI

// MARK: - GameKit — the shared arcade run + the advancement system
//
// Every Ludus game is endless, but each has LEVELS ("Gradus I, II, III …") and a reachable
// goal so a child can WIN it:
//   • a run climbs one level per `perLevel` correct answers, and each level is a little harder
//     (the game decides what "harder" means — bigger numbers, more choices, less time);
//   • level 1 is pitched at a 7-year-old (counting, pictures, no clock), the top at a 12-year-old;
//   • reaching the game's `won` level earns the BRONZE laurel — the game counts as won (its seal
//     ring segment gilds); `silver` and `gold` levels earn the higher laurels;
//   • once a laurel level is reached, later runs may START there (so a 12-year-old isn't stuck
//     re-counting dots every time).
// Hearts: 3, and every level-up gives one back (kind to young players). Level I is practice — a
// miss there costs no heart. A miss shows the right answer — games must never just say "wrong".
//
// A game = an `ArcadeModel` subclass (calls `hit()` / `miss()` / `finish(_:)`, reads `level`)
// + its play view wrapped in `ArcadeShell`, which owns the HUD, the intro card (how to play,
// goals, start level), the level-up banner and the game-over card.

/// The laurel goals of a game, in levels.
struct GameGoal: Hashable {
    let won: Int, silver: Int, gold: Int
    static let standard = GameGoal(won: 3, silver: 5, gold: 8)
    var levels: [Int] { [won, silver, gold] }
}

enum Medal: Int, Comparable {
    case none, bronze, silver, gold
    static func < (a: Medal, b: Medal) -> Bool { a.rawValue < b.rawValue }
    var hex: UInt {
        switch self {
        case .none: return Lu.line
        case .bronze: return 0xd08a4e
        case .silver: return 0xdcdfe4
        case .gold: return Lu.gold
        }
    }
    var name: String {
        switch self {
        case .none: return ""
        case .bronze: return "Bronze laurel"
        case .silver: return "Silver laurel"
        case .gold: return "Gold laurel"
        }
    }
}

/// Persistent per-game advancement (UserDefaults; one key per game, next to `ludus_best_<game>`).
enum LudusProgress {
    static func levelKey(_ game: String) -> String { "ludus_lvl_\(game)" }
    static func maxLevel(_ game: String) -> Int { UserDefaults.standard.integer(forKey: levelKey(game)) }
    @discardableResult
    static func record(level: Int, for game: String) -> Bool {
        guard level > maxLevel(game) else { return false }
        UserDefaults.standard.set(level, forKey: levelKey(game)); return true
    }
    static func medal(level: Int, goal: GameGoal) -> Medal {
        if level >= goal.gold { return .gold }
        if level >= goal.silver { return .silver }
        if level >= goal.won { return .bronze }
        return .none
    }
    static func medal(_ game: String, goal: GameGoal) -> Medal { medal(level: maxLevel(game), goal: goal) }
    static func won(_ game: String, goal: GameGoal) -> Bool { maxLevel(game) >= goal.won }
}

/// What a finished run achieved (drives the game-over card).
struct ArcadeResult {
    let reason: String
    let score: Int, best: Int, den: Int
    let level: Int, startLevel: Int
    let newBest: Bool
    let medalBefore: Medal, medalAfter: Medal
    var newMedal: Bool { medalAfter > medalBefore }
}

/// A short "how to play" line: a big glyph and a few words (7-year-olds read slowly — keep it short).
struct HowTo: Hashable {
    let icon: String
    let text: String
}

/// The run state + rules every game shares. Subclass it, publish your own state alongside, and
/// override `onBegin()` to reset your board. Call `hit()` on a correct answer and `miss()` on a
/// wrong one; read `level` (1…) to pick the difficulty of the NEXT question.
@MainActor
class ArcadeModel: ObservableObject {
    enum Phase { case intro, playing, over }
    @Published var phase: Phase = .intro
    @Published var score = 0
    @Published var den = 0
    @Published var hearts = 3
    @Published var combo = 0
    @Published var level = 1
    @Published var startLevel = 1
    @Published var progress = 0            // correct answers into the current level
    @Published var levelUps = 0            // bumps on every level-up (drives the banner)
    @Published var result: ArcadeResult?
    @Published var lastMiss = 0            // bumps on every miss (games may flash/shake)

    let key: String
    let goal: GameGoal
    let maxHearts = 3
    /// Correct answers needed to climb a level. Games may vary it with `level`.
    func perLevel(_ level: Int) -> Int { 6 }

    init(key: String, goal: GameGoal? = nil) {
        self.key = key
        self.goal = goal ?? GameID(rawValue: key)?.spec?.goal ?? .standard
        #if DEBUG
        // LUDUS_START_LEVEL=n jumps a run straight to level n (for checking the later levels).
        if let s = ProcessInfo.processInfo.environment["LUDUS_START_LEVEL"], let n = Int(s) { debugStart = n }
        #endif
    }
    private var debugStart: Int?

    /// Levels a run may start from: I, plus every laurel level already reached.
    var startChoices: [Int] {
        let reached = LudusProgress.maxLevel(key)
        return [1] + goal.levels.filter { $0 <= reached && $0 > 1 }
    }

    func begin(level start: Int? = nil) {
        let lv = max(1, debugStart ?? start ?? startLevel)
        startLevel = lv
        score = 0; den = 0; hearts = maxHearts; combo = 0
        level = lv; progress = 0; result = nil
        medalAtStart = LudusProgress.medal(key, goal: goal)
        phase = .playing
        Haptics.prime()
        onBegin()
    }

    /// Reset the game's own board for a fresh run (`level` is already set).
    func onBegin() {}
    /// Called right after the level goes up (e.g. to rebuild a board at the new difficulty).
    func onLevelUp() {}

    /// DEBUG autoplayer hook: make ONE move — the right one if `correct`, else a wrong one — the
    /// way a child's tap/drag would (go through the same code path as the gesture). Called by the
    /// shell every `LUDUS_BOT_EVERY` s while playing when `LUDUS_BOT=<accuracy 0…1>` is set, so a
    /// game can be checked end to end (levels climb, laurels land, the run ends) without touching.
    func botAct(correct: Bool) {}

    /// A correct answer. `points` is the base value; the combo multiplies it (capped so a long
    /// streak doesn't dwarf everything). Returns true if this answer climbed a level.
    @discardableResult
    func hit(points: Int = 1) -> Bool {
        guard phase == .playing else { return false }
        combo += 1
        let pts = points * min(combo, 5)
        score += pts; den += pts
        progress += 1
        if progress >= perLevel(level) {
            progress = 0; level += 1; levelUps += 1
            hearts = min(maxHearts, hearts + 1)
            LudusProgress.record(level: level, for: key)
            Haptics.success()
            onLevelUp()
            return true
        }
        Haptics.tap(0.5 + Double(min(combo, 6)) * 0.06)
        return false
    }

    /// A wrong answer / an escape. Ends the run when the hearts run out (after `delay`, so the
    /// game can show the right answer first). Returns true if that was the last heart.
    @discardableResult
    func miss(reason: String = "Out of hearts!", delay: Double = 0.9) -> Bool {
        guard phase == .playing else { return false }
        combo = 0
        lastMiss += 1
        // Level I is practice: a miss costs no heart (the game still shows the right answer).
        if level == 1 { Haptics.light(); return false }
        hearts -= 1
        Haptics.error()
        if hearts <= 0 {
            hearts = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in self?.finish(reason) }
            return true
        }
        return false
    }

    var dying: Bool { hearts <= 0 }

    func finish(_ reason: String) {
        guard phase == .playing else { return }
        let before = medalAtStart
        // `record` already ran on each level-up; this covers runs that started at a level. The
        // level the run REACHED counts — a run that ends partway through level 3 has reached 3.
        LudusProgress.record(level: level, for: key)
        let after = LudusProgress.medal(key, goal: goal)
        LudusStore.award(den)
        let isBest = LudusStore.recordBest(key, score)
        result = ArcadeResult(reason: reason, score: score, best: LudusStore.best(key), den: den,
                              level: level, startLevel: startLevel, newBest: isBest,
                              medalBefore: before, medalAfter: after)
        phase = .over
        if after > before { Haptics.success() }
    }

    /// The laurel held when the run began (`record(level:)` runs mid-run on each level-up).
    private var medalAtStart: Medal = .none
}

extension GameID {
    /// The catalog entry for this game (title, goal, how-to).
    var spec: GameSpec? {
        for w in ludusWorlds { if let s = w.games.first(where: { $0.game == self }) { return s } }
        return nil
    }
}

// MARK: - Shell

/// Wraps a game's play area with the shared HUD, intro card, level-up banner and game-over card.
/// The play area should do nothing (no timers, no spawns) unless `model.phase == .playing`.
struct ArcadeShell<Model: ArcadeModel, Content: View>: View {
    @ObservedObject var model: Model
    let spec: GameSpec
    var accent: UInt = Lu.gold
    var showHearts = true
    let onClose: () -> Void
    @ViewBuilder let content: Content

    @State private var banner = false

    var body: some View {
        ZStack {
            LudusBackground().ignoresSafeArea()
            content
            hud
            if banner {
                LevelBanner(level: model.level, accent: accent)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
            if model.phase == .intro {
                ArcadeIntroView(spec: spec, model: model, accent: accent, onClose: onClose)
                    .transition(.opacity)
            }
            if model.phase == .over, let r = model.result {
                ArcadeOverView(spec: spec, result: r, goal: model.goal, accent: accent,
                               onAgain: { withAnimation(.easeOut(duration: 0.2)) { model.begin(level: r.startLevel) } },
                               onMenu: { withAnimation(.easeOut(duration: 0.2)) { model.phase = .intro } },
                               onClose: onClose)
                    .transition(.opacity)
            }
        }
        .statusBarHidden(true)
        .onChange(of: model.levelUps) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { banner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                withAnimation(.easeIn(duration: 0.25)) { banner = false }
            }
        }
        .onAppear {
            #if DEBUG
            let env = ProcessInfo.processInfo.environment
            if env["LUDUS_AUTOPLAY"] != nil || env["LUDUS_BOT"] != nil { model.begin() }
            #endif
        }
        #if DEBUG
        .onReceive(botClock) { _ in
            guard model.phase == .playing, let acc = Double(ProcessInfo.processInfo.environment["LUDUS_BOT"] ?? "") else { return }
            model.botAct(correct: Double.random(in: 0..<1) < acc)
        }
        #endif
    }

    #if DEBUG
    private let botClock = Timer.publish(
        every: Double(ProcessInfo.processInfo.environment["LUDUS_BOT_EVERY"] ?? "") ?? 1.2, on: .main, in: .common
    ).autoconnect()
    #endif

    private var hud: some View {
        VStack {
            HStack(alignment: .top, spacing: 8) {
                LudusCloseButton(action: onClose)
                StatPill(label: "SCORE", value: "\(model.score)", valueHex: Lu.gold)
                Spacer(minLength: 4)
                if showHearts { HeartsRow(hearts: model.hearts, maxHearts: model.maxHearts) }
                Spacer(minLength: 4)
                LevelPill(level: model.level, progress: model.progress,
                          per: model.perLevel(model.level), accent: accent)
            }
            Spacer()
        }
        .padding(.horizontal, 12).padding(.top, 4)
        .opacity(model.phase == .playing ? 1 : 0)
    }
}

/// HUD pill: the level as a Roman numeral, with pips filling toward the next level.
struct LevelPill: View {
    let level: Int, progress: Int, per: Int
    var accent: UInt = Lu.gold
    var body: some View {
        VStack(spacing: 3) {
            Text("GRADUS").font(luFont(9, .heavy)).tracking(1.4).foregroundStyle(Color(hex: Lu.inkDim))
            Text(romanNumeral(level)).font(luSerif(19, .black)).foregroundStyle(Color(hex: Lu.ink))
                .lineLimit(1).minimumScaleFactor(0.6)
            HStack(spacing: 2) {
                ForEach(0..<max(per, 1), id: \.self) { i in
                    Capsule().fill(Color(hex: i < progress ? accent : Lu.line))
                        .frame(width: per > 8 ? 4 : 6, height: 4)
                }
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .frame(minWidth: 64)
        .background(luPanelShape(14))
        .animation(.easeOut(duration: 0.2), value: progress)
    }
}

private struct LevelBanner: View {
    let level: Int
    let accent: UInt
    var body: some View {
        VStack(spacing: 2) {
            Text("LEVEL UP").font(luFont(14, .heavy)).tracking(3).foregroundStyle(Color(hex: Lu.mint))
            LaurelFrame(size: 30) {
                Text("Gradus \(romanNumeral(level))").font(luSerif(38, .black))
                    .foregroundStyle(LinearGradient(colors: [.white, Color(hex: Lu.gold)], startPoint: .top, endPoint: .bottom))
            }
            Text("+1 ♥").font(luFont(15, .heavy)).foregroundStyle(Color(hex: Lu.coral)).opacity(0.9)
        }
        .padding(.horizontal, 22).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color(hex: Lu.ground).opacity(0.88))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: Lu.goldLine), lineWidth: 2)))
        .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
    }
}

/// A laurel wreath glyph in a medal's metal (dim when not yet earned).
struct LaurelMedal: View {
    let medal: Medal
    var earned: Bool
    var size: CGFloat = 26
    var body: some View {
        HStack(spacing: -size * 0.18) {
            Image(systemName: "laurel.leading")
            Image(systemName: "laurel.trailing")
        }
        .font(.system(size: size, weight: .bold))
        .foregroundStyle(Color(hex: earned ? medal.hex : Lu.line))
        .shadow(color: earned ? Color(hex: medal.hex).opacity(0.5) : .clear, radius: 6)
    }
}

/// Before a run: what the game is, how to play (icons + few words), the three laurel goals, and
/// which level to start at.
private struct ArcadeIntroView: View {
    let spec: GameSpec
    @ObservedObject var model: ArcadeModel
    let accent: UInt
    let onClose: () -> Void

    var body: some View {
        let reached = LudusProgress.maxLevel(model.key)
        let medal = LudusProgress.medal(model.key, goal: model.goal)
        ZStack {
            LudusBackground().ignoresSafeArea()
            VStack(spacing: 14) {
                HStack { LudusCloseButton(action: onClose); Spacer() }
                Spacer(minLength: 0)
                Text(spec.icon).font(.system(size: 64))
                Text(spec.title).font(luSerif(32, .black)).foregroundStyle(Color(hex: Lu.ink))
                    .multilineTextAlignment(.center).minimumScaleFactor(0.6).lineLimit(2)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(spec.howTo, id: \.self) { h in
                        HStack(spacing: 12) {
                            Text(h.icon).font(.system(size: 28)).frame(width: 40)
                            Text(h.text).font(luFont(18, .bold)).foregroundStyle(Color(hex: Lu.ink))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(luPanelShape(18))

                // Goals: the three laurels and the level each needs.
                HStack(spacing: 0) {
                    ForEach([Medal.bronze, .silver, .gold], id: \.self) { m in
                        let lv = model.goal.levels[m.rawValue - 1]
                        VStack(spacing: 4) {
                            LaurelMedal(medal: m, earned: medal >= m)
                            Text("Gradus \(romanNumeral(lv))").font(luFont(12, .heavy))
                                .foregroundStyle(Color(hex: medal >= m ? m.hex : Lu.inkDim))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 10)
                .background(luPanelShape(18))
                if medal == .none {
                    Text(reached > 1 ? "Best so far: Gradus \(romanNumeral(reached)) — reach \(romanNumeral(model.goal.won)) to win!"
                                     : "Reach Gradus \(romanNumeral(model.goal.won)) to win!")
                        .font(luFont(14, .bold)).foregroundStyle(Color(hex: Lu.inkDim))
                        .multilineTextAlignment(.center)
                }

                let choices = model.startChoices
                if choices.count > 1 {
                    VStack(spacing: 6) {
                        Text("START AT").font(luFont(11, .heavy)).tracking(2).foregroundStyle(Color(hex: Lu.inkDim))
                        HStack(spacing: 10) {
                            ForEach(choices, id: \.self) { lv in
                                Button { model.startLevel = lv } label: {
                                    Text(romanNumeral(lv)).font(luSerif(20, .black))
                                        .foregroundStyle(Color(hex: model.startLevel == lv ? Lu.inkDark : Lu.ink))
                                        .frame(width: 58, height: 44)
                                        .background(RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(hex: model.startLevel == lv ? accent : Lu.panel))
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: Lu.line), lineWidth: 2)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
                LudusButton(title: "Play", fullWidth: true) {
                    withAnimation(.easeOut(duration: 0.2)) { model.begin() }
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 20).padding(.top, 4)
        }
        .onAppear {
            if !model.startChoices.contains(model.startLevel) { model.startLevel = 1 }
        }
    }
}

/// After a run: how far it climbed, any laurel just earned, the next goal, score/best/denarii.
private struct ArcadeOverView: View {
    let spec: GameSpec
    let result: ArcadeResult
    let goal: GameGoal
    let accent: UInt
    let onAgain: () -> Void
    let onMenu: () -> Void
    let onClose: () -> Void

    @State private var pop = false

    private var nextGoal: (Medal, Int)? {
        switch result.medalAfter {
        case .none: return (.bronze, goal.won)
        case .bronze: return (.silver, goal.silver)
        case .silver: return (.gold, goal.gold)
        case .gold: return nil
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            VStack(spacing: 10) {
                Text(result.reason.uppercased()).font(luFont(12, .heavy)).tracking(3)
                    .foregroundStyle(Color(hex: Lu.grape))
                if result.newMedal {
                    VStack(spacing: 4) {
                        LaurelMedal(medal: result.medalAfter, earned: true, size: 64)
                            .scaleEffect(pop ? 1 : 0.3).rotationEffect(.degrees(pop ? 0 : -25))
                        Text(result.medalAfter == .bronze ? "You won \(spec.title)!" : result.medalAfter.name + "!")
                            .font(luSerif(26, .black)).foregroundStyle(Color(hex: result.medalAfter.hex))
                            .multilineTextAlignment(.center)
                    }
                } else {
                    LaurelFrame(size: 30) {
                        Text("Finis").font(luSerif(50, .black)).textCase(.uppercase).tracking(2)
                            .foregroundStyle(LinearGradient(colors: [.white, Color(hex: Lu.gold), Color(hex: Lu.tangerine)],
                                                            startPoint: .top, endPoint: .bottom))
                    }
                }
                Text("You reached Gradus \(romanNumeral(result.level))")
                    .font(luFont(18, .heavy)).foregroundStyle(Color(hex: Lu.ink))
                HStack(spacing: 18) {
                    ForEach([Medal.bronze, .silver, .gold], id: \.self) { m in
                        LaurelMedal(medal: m, earned: result.medalAfter >= m, size: 24)
                    }
                }
                if let (m, lv) = nextGoal {
                    Text("Reach Gradus \(romanNumeral(lv)) for the \(m.name.lowercased())")
                        .font(luFont(14, .bold)).foregroundStyle(Color(hex: Lu.inkDim))
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: 12) {
                    ResultCard(label: "SCORE", value: "\(result.score)", hex: Lu.gold)
                    ResultCard(label: "BEST", value: "\(result.best)", hex: Lu.mint)
                    ResultCard(label: "DENARII", value: "🪙\(result.den)", hex: Lu.silver)
                }
                .padding(.top, 4)
                if result.newBest && !result.newMedal {
                    Text("★ NEW BEST! ★").font(luFont(15)).foregroundStyle(Color(hex: Lu.mint))
                }
                LudusButton(title: "Play Again", action: onAgain).padding(.top, 10)
                HStack(spacing: 28) {
                    Button("Levels", action: onMenu)
                    Button("Done", action: onClose)
                }
                .font(luFont(15, .bold)).foregroundStyle(Color(hex: Lu.inkDim)).padding(.top, 4)
            }
            .padding(24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.15)) { pop = true }
        }
    }
}
