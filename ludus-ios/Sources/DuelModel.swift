import SwiftUI

// MARK: - Duel in the Arena — the rules
//
// Two children at opposite ends of a flat iPad race to answer arithmetic. Each round both get a
// question at THEIR OWN difficulty (a 6-year-old on "+ − to 10" can duel a 10-year-old on "× all
// tables"); the first to answer their own question right takes the point. A wrong tap locks that
// player out for a moment (no button mashing) and stays crossed out for the round. First to
// `target` points wins the laurel.
//
// Social only: a duel pays no denarii and earns no laurels, so it can't be farmed (two siblings
// trading wins, or one child playing both ends) and a handicapped match can't be "unfair" on
// anyone's save. The prize is the victory screen.
//
// DEBUG hooks: LUDUS_DUEL_SEED=n (deterministic questions), LUDUS_DUEL_TO=n (points to win),
// LUDUS_DUEL_DEMO=play|won (skip setup straight to a mid-duel or a finished one, for screenshots).

enum DuelSide: String, CaseIterable {
    case top, bottom
    var other: DuelSide { self == .top ? .bottom : .top }
}

/// The four challenges, named for the arcade's rank ladder so even the easiest one sounds proud.
enum DuelLevel: Int, CaseIterable, Identifiable {
    case tiro, legionary, centurion, consul
    var id: Int { rawValue }
    var rank: String { ["Tiro", "Legionary", "Centurion", "Consul"][rawValue] }
    var label: String { ["+ − to 10", "+ − to 20", "× 2, 5, 10", "× all tables"][rawValue] }
    /// Little ones get three answers to choose from; everyone else four.
    var choices: Int { self == .tiro ? 3 : 4 }

    func question(_ rng: inout DuelRNG) -> DuelQuestion {
        func r(_ x: ClosedRange<Int>) -> Int { Int.random(in: x, using: &rng) }
        let a: Int, b: Int, op: String, ans: Int
        switch self {
        case .tiro:
            if Bool.random(using: &rng) { a = r(1...9); b = r(1...(10 - a)); op = "+"; ans = a + b }
            else { a = r(2...10); b = r(1...a); op = "−"; ans = a - b }
        case .legionary:
            if Bool.random(using: &rng) { a = r(3...17); b = r(max(2, 11 - a)...(20 - a)); op = "+"; ans = a + b }
            else { a = r(11...20); b = r(2...(a - 1)); op = "−"; ans = a - b }
        case .centurion:
            let t = [2, 5, 10].randomElement(using: &rng)!, n = r(1...10)
            (a, b) = Bool.random(using: &rng) ? (t, n) : (n, t); op = "×"; ans = a * b
        case .consul:
            a = r(2...12); b = r(2...12); op = "×"; ans = a * b
        }
        // Near misses a child might really make: off by one or two, a table step off, a ten off,
        // the wrong operation.
        var near: [Int]
        if op == "×" {
            near = [a * (b + 1), a * (b - 1), (a + 1) * b, (a - 1) * b, ans + 1, ans - 1, a + b, ans + 10, ans - 10]
        } else {
            near = [ans + 1, ans - 1, ans + 2, ans - 2, op == "+" ? abs(a - b) : a + b]
            if self == .legionary { near += [ans + 10, ans - 10] }
        }
        var opts = [ans]
        for v in near.shuffled(using: &rng) where v >= 0 && !opts.contains(v) && opts.count < choices { opts.append(v) }
        var k = 3
        while opts.count < choices { if !opts.contains(ans + k) { opts.append(ans + k) }; k += 1 }
        return DuelQuestion(prompt: "\(a) \(op) \(b)", answer: ans, options: opts.shuffled(using: &rng))
    }
}

struct DuelQuestion: Equatable {
    let prompt: String
    let answer: Int
    let options: [Int]
}

/// SplitMix64: a seedable generator, so a DEBUG run can replay the same questions.
struct DuelRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

struct DuelPlayer {
    var name: String
    var emblem: String
    var wax: UInt
    var profileID: String?
    var level: DuelLevel
    var ready = false
    var score = 0
    var q: DuelQuestion?
    /// Option indices tapped wrong this round (crossed out until the next question).
    var wrong: Set<Int> = []
    var locked = false
    /// Bumped on every lockout, so the view restarts its countdown ring.
    var lockID = 0
    var lastPrompt = ""
}

enum DuelPhase: Equatable {
    case setup
    case countdown(Int)          // 3, 2, 1, then 0 = "GO!"
    case playing
    case roundOver(DuelSide)     // who took the point
    case won(DuelSide)
}

@MainActor
final class DuelModel: ObservableObject {
    @Published var top: DuelPlayer
    @Published var bottom: DuelPlayer
    @Published private(set) var phase: DuelPhase = .setup
    @Published private(set) var round = 0
    @Published var paused = false
    private(set) var target = 7
    static let lockSeconds = 1.5
    /// Invalidates scheduled steps (lock expiry, next round) after a rematch.
    private var epoch = 0
    private var rng = DuelRNG(seed: UInt64.random(in: 1...UInt64.max))

    init() {
        let all = LudusProfiles.shared.all
        let current = LudusProfiles.shared.current ?? all.first
        // Player 1 sits at the bottom (the iPad's "home" end). With two or more players saved, each
        // end starts as a different child; otherwise the guest seats get a lion and an eagle.
        if let me = current {
            bottom = DuelPlayer(name: me.name, emblem: LudusProfiles.emblems[me.emblem % LudusProfiles.emblems.count],
                                wax: LudusProfiles.waxes[me.wax % LudusProfiles.waxes.count],
                                profileID: me.id, level: .legionary)
        } else {
            bottom = DuelPlayer(name: "Player 1", emblem: "🦁", wax: 0xb3262d, level: .legionary)
        }
        if let you = all.first(where: { $0.id != current?.id }) {
            top = DuelPlayer(name: you.name, emblem: LudusProfiles.emblems[you.emblem % LudusProfiles.emblems.count],
                             wax: LudusProfiles.waxes[you.wax % LudusProfiles.waxes.count],
                             profileID: you.id, level: .legionary)
        } else {
            top = DuelPlayer(name: "Player 2", emblem: "🦅", wax: 0x2f6fb0, level: .legionary)
        }
        if top.wax == bottom.wax { top.wax = bottom.wax == 0x2f6fb0 ? 0xb3262d : 0x2f6fb0 }
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if let s = UInt64(env["LUDUS_DUEL_SEED"] ?? "") { rng = DuelRNG(seed: s) }
        if let n = Int(env["LUDUS_DUEL_TO"] ?? ""), n > 0 { target = n }
        switch env["LUDUS_DUEL_DEMO"] {
        case "play":
            top.level = .consul; bottom.level = .tiro
            top.score = 3; bottom.score = 4
            deal(); phase = .playing
        case "won":
            top.level = .consul; bottom.level = .tiro
            top.score = 4; bottom.score = target
            phase = .won(.bottom)
        default: break
        }
        #endif
    }

    var targetPoints: Int { target }

    subscript(side: DuelSide) -> DuelPlayer {
        get { side == .top ? top : bottom }
        set { if side == .top { top = newValue } else { bottom = newValue } }
    }

    // MARK: Setup

    func choose(_ side: DuelSide, level: DuelLevel) {
        guard phase == .setup, !self[side].ready else { return }
        self[side].level = level
        Sfx.play(.tick, volume: 0.6); Haptics.light()
    }

    /// Seat a saved player at this end (never the same child at both ends).
    func choose(_ side: DuelSide, profile p: LudusProfile) {
        guard phase == .setup, !self[side].ready, self[side.other].profileID != p.id else { return }
        self[side].profileID = p.id
        self[side].name = p.name
        self[side].emblem = LudusProfiles.emblems[p.emblem % LudusProfiles.emblems.count]
        self[side].wax = LudusProfiles.waxes[p.wax % LudusProfiles.waxes.count]
        Sfx.play(.tick, volume: 0.6); Haptics.light()
    }

    func toggleReady(_ side: DuelSide) {
        guard phase == .setup else { return }
        self[side].ready.toggle()
        Sfx.play(self[side].ready ? .pop : .tick); Haptics.tap(0.5)
        if top.ready && bottom.ready { countdown(3) }
    }

    private func countdown(_ n: Int) {
        phase = .countdown(n)
        Sfx.play(n == 0 ? .whoosh : .tick)
        let e = epoch
        DispatchQueue.main.asyncAfter(deadline: .now() + (n == 0 ? 0.5 : 0.7)) { [weak self] in
            guard let self, self.epoch == e, case .countdown = self.phase else { return }
            if n > 0 { self.countdown(n - 1) } else { self.deal(); self.phase = .playing }
        }
    }

    // MARK: Play

    private func deal() {
        round += 1
        for s in DuelSide.allCases {
            var q = self[s].level.question(&rng)
            var tries = 0
            while q.prompt == self[s].lastPrompt && tries < 6 { q = self[s].level.question(&rng); tries += 1 }
            self[s].q = q
            self[s].lastPrompt = q.prompt
            self[s].wrong = []
            self[s].locked = false
        }
    }

    /// A press on one of `side`'s answers. Both ends can press at once; whichever right answer
    /// reaches here first takes the round.
    func tap(_ side: DuelSide, option i: Int) {
        guard phase == .playing, !paused, !self[side].locked, let q = self[side].q,
              q.options.indices.contains(i), !self[side].wrong.contains(i) else { return }
        if q.options[i] == q.answer {
            self[side].score += 1
            phase = .roundOver(side)
            Sfx.play(.correct(combo: self[side].score)); Haptics.success()
            let e = epoch
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
                guard let self, self.epoch == e else { return }
                if self[side].score >= self.target {
                    self.phase = .won(side)
                    Sfx.play(.win)
                } else {
                    self.deal(); self.phase = .playing
                }
            }
        } else {
            self[side].wrong.insert(i)
            self[side].locked = true
            self[side].lockID += 1
            Sfx.play(.wrong, volume: 0.7); Haptics.error()
            let id = self[side].lockID, e = epoch
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.lockSeconds) { [weak self] in
                guard let self, self.epoch == e, self[side].lockID == id else { return }
                self[side].locked = false
            }
        }
    }

    /// Back to the challenge picker (so the one who lost can pick an easier challenge), scores cleared.
    func rematch() {
        epoch += 1
        for s in DuelSide.allCases {
            self[s].score = 0; self[s].ready = false; self[s].q = nil
            self[s].wrong = []; self[s].locked = false
        }
        paused = false
        phase = .setup
        Sfx.play(.tick)
    }
}
