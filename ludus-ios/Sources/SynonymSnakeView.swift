import SwiftUI

// MARK: - Synonym Snake  (Word Wizards · steer, vocabulary)
//
// Vipera the garden snake slithers round the hedges of a Roman garden. Steer her by tapping beside
// her head (she turns toward your finger) or by swiping. The sign says what to eat — fruit, words
// that MEAN the same, words that mean the OPPOSITE, words built on a Latin root — and the rest
// make her sick. No crash deaths (she wraps through the hedges and may cross herself), so hearts
// are only about words. A wrong bite says why ("*tiny* is the OPPOSITE of big").
//
// Continuous difficulty (GameKit `d`); kinds fade in via `tier`, older kinds stay as review:
//   pictures: "eat the FRUIT" (d 1) → easy synonyms with a picture hint (2.4) → easy OPPOSITES
//   (3.6) → harder synonyms & opposites (4.8) → tier-2 vocabulary (6) → Latin & Greek roots:
//   AUD = hear → audience, audible; dodge aunt, autumn (7.2)
//   step time 0.62 s → 0.30 s by d 9 · good food 2 → 3 · bad food 1 → 4 by d 7
//   opposite traps in synonym rounds: chance ramps 0 → 60% from d 2.6 to 4.5

private struct SSSet {
    let target: String
    let hint: String         // picture next to the target word (for a root: the meaning)
    let good: [String]
    let opposite: [String]   // opposites (for a root: look-alikes that are NOT from it)
}

private let ssPictureSets: [SSSet] = [
    SSSet(target: "FRUIT", hint: "🍎", good: ["🍎", "🍌", "🍇", "🍓", "🍊", "🍐", "🍒", "🍉", "🍍"],
          opposite: ["🚗", "⚽️", "🧦", "🪑", "🐶", "🎈", "✏️", "🧸"]),
    SSSet(target: "ANIMALS", hint: "🐾", good: ["🐶", "🐱", "🐮", "🐷", "🐸", "🐵", "🐰", "🦁", "🐘"],
          opposite: ["🍎", "🚗", "⚽️", "🧦", "🎈", "🍌", "✏️", "🏠"]),
    SSSet(target: "THINGS THAT GO", hint: "🚗", good: ["🚗", "🚌", "🚲", "✈️", "🚂", "🚀", "🚜", "⛵️"],
          opposite: ["🍎", "🪑", "🧦", "🌳", "🎂", "🏠", "🧸"]),
    SSSet(target: "SWEETS", hint: "🍭", good: ["🍰", "🍩", "🍪", "🍭", "🍬", "🧁", "🍫", "🍦"],
          opposite: ["🥦", "🥕", "🧦", "🚗", "🐟", "⚽️", "✏️"]),
]
// Levels III–IV.
private let ssEasy: [SSSet] = [
    SSSet(target: "BIG", hint: "🐘", good: ["large", "huge", "giant"], opposite: ["small", "tiny", "little"]),
    SSSet(target: "SMALL", hint: "🐭", good: ["little", "tiny", "mini"], opposite: ["big", "huge", "large"]),
    SSSet(target: "HAPPY", hint: "😀", good: ["glad", "joyful", "cheerful"], opposite: ["sad", "upset", "grumpy"]),
    SSSet(target: "SAD", hint: "😢", good: ["unhappy", "upset", "gloomy"], opposite: ["happy", "glad", "cheerful"]),
    SSSet(target: "FAST", hint: "🐇", good: ["quick", "speedy", "rapid"], opposite: ["slow", "sluggish"]),
    SSSet(target: "COLD", hint: "🧊", good: ["chilly", "icy", "freezing"], opposite: ["hot", "warm", "boiling"]),
    SSSet(target: "SHOUT", hint: "📣", good: ["yell", "scream", "holler"], opposite: ["whisper", "murmur"]),
    SSSet(target: "WET", hint: "💧", good: ["damp", "soggy", "soaked"], opposite: ["dry", "parched"]),
    SSSet(target: "SCARED", hint: "😱", good: ["afraid", "frightened", "fearful"], opposite: ["brave", "bold", "calm"]),
    SSSet(target: "TIRED", hint: "😴", good: ["sleepy", "weary", "worn out"], opposite: ["awake", "lively", "rested"]),
]
// Level V.
private let ssMedium: [SSSet] = [
    SSSet(target: "ANGRY", hint: "😠", good: ["mad", "cross", "furious"], opposite: ["calm", "pleased", "cheerful"]),
    SSSet(target: "SMART", hint: "🧠", good: ["clever", "bright", "wise"], opposite: ["foolish", "silly", "dim"]),
    SSSet(target: "BRAVE", hint: "🦁", good: ["bold", "fearless", "daring"], opposite: ["scared", "timid", "cowardly"]),
    SSSet(target: "QUIET", hint: "🤫", good: ["silent", "hushed", "muted"], opposite: ["loud", "noisy", "booming"]),
    SSSet(target: "STRONG", hint: "💪", good: ["powerful", "mighty", "tough"], opposite: ["weak", "feeble", "frail"]),
    SSSet(target: "EASY", hint: "✅", good: ["simple", "effortless"], opposite: ["hard", "difficult", "tricky"]),
    SSSet(target: "RICH", hint: "💰", good: ["wealthy", "well-off"], opposite: ["poor", "needy"]),
    SSSet(target: "FUNNY", hint: "🤣", good: ["comical", "hilarious", "amusing"], opposite: ["serious", "solemn"]),
]
// Level VI+.
private let ssHard: [SSSet] = [
    SSSet(target: "ENORMOUS", hint: "🐋", good: ["immense", "massive", "colossal", "vast"], opposite: ["tiny", "microscopic", "puny"]),
    SSSet(target: "FURIOUS", hint: "🌋", good: ["enraged", "livid", "irate"], opposite: ["calm", "content", "serene"]),
    SSSet(target: "TIMID", hint: "🐢", good: ["shy", "bashful", "meek"], opposite: ["bold", "daring", "confident"]),
    SSSet(target: "FRAGILE", hint: "🥚", good: ["delicate", "breakable", "flimsy"], opposite: ["sturdy", "tough", "solid"]),
    SSSet(target: "GLOOMY", hint: "🌧️", good: ["dismal", "dreary", "bleak"], opposite: ["cheerful", "bright", "sunny"]),
    SSSet(target: "HUNGRY", hint: "🍽️", good: ["starving", "famished", "ravenous"], opposite: ["full", "stuffed"]),
    SSSet(target: "CALM", hint: "🌊", good: ["peaceful", "tranquil", "serene"], opposite: ["frantic", "anxious", "restless"]),
    SSSet(target: "HONEST", hint: "🤝", good: ["truthful", "sincere", "frank"], opposite: ["sneaky", "deceitful", "dishonest"]),
    SSSet(target: "STRANGE", hint: "👽", good: ["odd", "peculiar", "bizarre"], opposite: ["normal", "ordinary", "usual"]),
    SSSet(target: "EXHAUSTED", hint: "😩", good: ["weary", "drained", "worn out"], opposite: ["lively", "energetic", "rested"]),
    SSSet(target: "ANCIENT", hint: "🏛️", good: ["old", "aged", "age-old"], opposite: ["modern", "new", "recent"]),
    SSSet(target: "BRIEF", hint: "⏱️", good: ["short", "quick", "concise"], opposite: ["long", "lengthy", "endless"]),
]
/// Unrelated words (bad food at III, mixed in later).
private let ssFillers = ["dog", "table", "purple", "pizza", "tree", "sock", "river", "book", "seven", "window", "spoon", "cloud"]

/// Latin (and two Greek) roots. "good" really come from the root; "opposite" only look like it.
private let ssRoots: [SSSet] = [
    SSSet(target: "SCRIB", hint: "write ✍️", good: ["describe", "scribble", "script", "manuscript", "inscription"],
          opposite: ["scrub", "scrap", "screen", "scream", "crib"]),
    SSSet(target: "PORT", hint: "carry 📦", good: ["transport", "portable", "import", "export", "report"],
          opposite: ["pork", "short", "popcorn", "forty"]),
    SSSet(target: "AUD", hint: "hear 👂", good: ["audio", "audience", "audible", "auditorium", "audition"],
          opposite: ["aunt", "autumn", "author", "August"]),
    SSSet(target: "VIS / VID", hint: "see 👁️", good: ["vision", "visible", "video", "invisible", "television", "supervise"],
          opposite: ["violin", "vinegar", "village", "vivid"]),
    SSSet(target: "DICT", hint: "say 🗣️", good: ["dictionary", "predict", "dictate", "contradict", "verdict"],
          opposite: ["dinosaur", "district", "dish", "dice"]),
    SSSet(target: "SPECT", hint: "look 🔍", good: ["inspect", "spectator", "spectacles", "respect", "suspect"],
          opposite: ["speech", "spend", "spell", "spill"]),
    SSSet(target: "AQUA", hint: "water 💧", good: ["aquarium", "aquatic", "aqueduct", "aquamarine"],
          opposite: ["equal", "acorn", "quack"]),
    SSSet(target: "PED", hint: "foot 🦶", good: ["pedal", "pedestrian", "centipede", "pedicure", "biped"],
          opposite: ["pebble", "pencil", "pepper", "petal"]),
    SSSet(target: "RUPT", hint: "break 💥", good: ["erupt", "interrupt", "rupture", "bankrupt", "disrupt"],
          opposite: ["rope", "rust", "rapid", "rabbit"]),
    SSSet(target: "MANU", hint: "hand ✋", good: ["manual", "manuscript", "manicure", "manufacture"],
          opposite: ["mango", "many", "mane", "menu"]),
    SSSet(target: "TELE (Greek)", hint: "far 🔭", good: ["telephone", "telescope", "television", "telegram"],
          opposite: ["tell", "tale", "telling", "tulip"]),
    SSSet(target: "PHON (Greek)", hint: "sound 🔊", good: ["telephone", "microphone", "symphony", "phonics", "headphones"],
          opposite: ["photo", "pony", "fond", "phase"]),
]

/// What a round asks for.
private enum SSMode { case pictures, same, opposite, root }

private struct SSRound {
    var mode: SSMode = .pictures
    var set: SSSet = ssPictureSets[0]
    var good: [String] { mode == .opposite ? set.opposite : set.good }
    /// Wrong answers that are a real trap: for "same" the opposites, for "opposite" the synonyms,
    /// for a root the look-alikes.
    var traps: [String] { mode == .opposite ? set.good : set.opposite }
}

private let ssTierStarts: [Double] = [1, 2.4, 3.6, 4.8, 6, 7.2]

// MARK: - Engine

private struct SSCell: Hashable { var col: Int, row: Int }

private enum SSDir {
    case up, down, left, right
    var delta: (Int, Int) {
        switch self { case .up: return (0, -1); case .down: return (0, 1); case .left: return (-1, 0); case .right: return (1, 0) }
    }
    func isOpposite(_ o: SSDir) -> Bool {
        switch (self, o) { case (.up, .down), (.down, .up), (.left, .right), (.right, .left): return true; default: return false }
    }
}

private struct SSFood: Identifiable, Equatable {
    let id = UUID()
    var cell: SSCell
    let word: String
    let good: Bool
    let trap: Bool
}

private struct SSPop: Identifiable { let id = UUID(); let cell: SSCell; let good: Bool }

@MainActor
private final class SynonymSnakeModel: ArcadeModel {
    let cols = 6, rows = 9

    @Published var snake: [SSCell] = []
    @Published var foods: [SSFood] = []
    @Published var round = SSRound()
    @Published var mood = 0                 // 0 calm, 1 yum, -1 yuck
    @Published var lesson: String?
    @Published var pops: [SSPop] = []

    /// Where the body was one step ago and when the last step happened (the view glides between).
    private(set) var prevSnake: [SSCell] = []
    private(set) var stepAt = Date()
    private(set) var dir: SSDir = .right
    private var queued: SSDir?
    private var eatenThisSet = 0
    private var loop: Task<Void, Never>?
    private var botGoal: UUID?
    private var lessonToken = UUID()

    init() {
        super.init(key: GameID.synonymSnake.rawValue)
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { ssSelfCheck() }
        #endif
    }

    var stepTime: Double { ramp(0.62, 0.30, to: 9) }
    private var goodOnBoard: Int { rampInt(2, 3, from: 3, to: 5) }
    private var badOnBoard: Int { rampInt(1, 4, from: 1, to: 7) }
    var pictures: Bool { round.mode == .pictures }
    var heading: CGFloat {
        switch dir { case .right: return 0; case .down: return .pi / 2; case .left: return .pi; case .up: return -.pi / 2 }
    }

    override func onBegin() {
        snake = [SSCell(col: 2, row: rows / 2), SSCell(col: 1, row: rows / 2), SSCell(col: 0, row: rows / 2)]
        prevSnake = snake; stepAt = Date()
        dir = .right; queued = nil; mood = 0; lesson = nil; pops = []; botGoal = nil
        newSet()
        loop?.cancel()
        loop = Task { @MainActor [weak self] in
            while true {
                let d = self?.stepTime ?? 1
                try? await Task.sleep(nanoseconds: UInt64(d * 1_000_000_000))
                guard let me = self, !Task.isCancelled, me.phase == .playing else { return }
                me.step()
            }
        }
    }

    func stop() { loop?.cancel() }

    private func newSet() {
        let t = tier(ssTierStarts)
        var r = SSRound()
        for _ in 0..<8 {
            switch t {
            case 0: r = SSRound(mode: .pictures, set: ssPictureSets.randomElement()!)
            case 1: r = SSRound(mode: .same, set: ssEasy.randomElement()!)
            case 2: r = SSRound(mode: .opposite, set: ssEasy.randomElement()!)
            case 3: r = SSRound(mode: Bool.random() ? .same : .opposite, set: ssMedium.randomElement()!)
            case 4: r = SSRound(mode: Bool.random() ? .same : .opposite, set: ssHard.randomElement()!)
            default: r = SSRound(mode: .root, set: ssRoots.randomElement()!)
            }
            if r.set.target != round.set.target && r.good.count >= 2 { break }
        }
        round = r; eatenThisSet = 0
        foods = []
        refill()
        LibraryVoice.say(sayCue)
    }

    var sayCue: String {
        switch round.mode {
        case .pictures: return "Eat all the \(round.set.target.lowercased())!"
        case .same: return "Eat words that mean \(round.set.target.lowercased())!"
        case .opposite: return "Eat the opposites of \(round.set.target.lowercased())!"
        case .root: return "Eat words from the root that means \(round.set.hint.filter { $0.isLetter || $0 == " " }.trimmingCharacters(in: .whitespaces))!"
        }
    }

    /// Top the board up, away from the head and from each other (word labels are wider than a cell).
    private func refill() {
        func place(_ word: String, good: Bool, trap: Bool) {
            let head = snake.first ?? SSCell(col: 0, row: 0)
            var free: [SSCell] = []
            for r in 0..<rows { for c in 0..<cols {
                let cell = SSCell(col: c, row: r)
                if snake.contains(cell) { continue }
                if abs(c - head.col) + abs(r - head.row) < 3 { continue }
                if foods.contains(where: { $0.cell.row == r && abs($0.cell.col - c) < 2 || ($0.cell.col == c && abs($0.cell.row - r) < 1) }) { continue }
                free.append(cell)
            } }
            guard let cell = free.randomElement() else { return }
            foods.append(SSFood(cell: cell, word: word, good: good, trap: trap))
        }
        var guardCount = 0
        while foods.filter(\.good).count < goodOnBoard && guardCount < 10 {
            guardCount += 1
            let unused = round.good.filter { w in !foods.contains { $0.word == w } }
            place((unused.isEmpty ? round.good : unused).randomElement()!, good: true, trap: false)
        }
        guardCount = 0
        while foods.filter({ !$0.good }).count < badOnBoard && guardCount < 10 {
            guardCount += 1
            let useTrap: Bool
            switch round.mode {
            case .pictures, .root: useTrap = true
            case .opposite: useTrap = Double.random(in: 0..<1) < 0.6
            case .same: useTrap = chance(0.6, from: 2.6, to: 4.5)
            }
            let pool = (useTrap ? round.traps : ssFillers).filter { w in !foods.contains { $0.word == w } && !round.good.contains(w) }
            guard let w = pool.randomElement() else { continue }
            place(w, good: false, trap: useTrap)
        }
    }

    // MARK: Input

    func steer(_ d: SSDir) {
        guard phase == .playing else { return }
        if d.isOpposite(queued ?? dir) || d == (queued ?? dir) { return }
        queued = d
        Sfx.play(.tick, volume: 0.5)
    }

    /// Tap steering: turn toward the finger, relative to the head.
    func tapSteer(dc: CGFloat, dr: CGFloat) {
        let horizontal = dir == .left || dir == .right
        if horizontal, abs(dr) >= 0.5 { steer(dr < 0 ? .up : .down) }
        else if !horizontal, abs(dc) >= 0.5 { steer(dc < 0 ? .left : .right) }
    }

    // MARK: Step

    private func step() {
        guard phase == .playing, let head = snake.first else { return }
        botSteer(head)
        if let q = queued { dir = q; queued = nil }
        let (dc, dr) = dir.delta
        let next = SSCell(col: (head.col + dc + cols) % cols, row: (head.row + dr + rows) % rows)   // wrap
        prevSnake = snake
        stepAt = Date()
        var body = snake
        body.insert(next, at: 0)
        if let i = foods.firstIndex(where: { $0.cell == next }) {
            let f = foods.remove(at: i)
            if f.good { if body.count > 12 { body.removeLast() } } else { body.removeLast(); if body.count > 3 { body.removeLast() } }
            snake = body
            // keep prevSnake aligned with the body for gliding
            while prevSnake.count < snake.count { prevSnake.append(prevSnake.last ?? next) }
            eat(f, at: next)
        } else {
            body.removeLast()
            snake = body
        }
    }

    private func eat(_ f: SSFood, at cell: SSCell) {
        let p = SSPop(cell: cell, good: f.good)
        pops.append(p)
        if f.good {
            mood = 1
            Sfx.play(.chomp)
            let up = hit()
            eatenThisSet += 1
            if eatenThisSet >= 3 { newSet() } else { refill() }
            _ = up
        } else {
            mood = -1
            say(lessonFor(f))
            miss(delay: 1.6)
            refill()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.pops.removeAll { $0.id == p.id }
            if self?.phase == .playing { self?.mood = 0 }
        }
    }

    private func lessonFor(_ f: SSFood) -> String {
        let t = round.set.target.lowercased()
        let right = round.good.first { g in foods.contains { $0.word == g } } ?? round.good[0]
        switch round.mode {
        case .pictures:
            let one = ["FRUIT": "a fruit", "ANIMALS": "an animal", "THINGS THAT GO": "a thing that goes", "SWEETS": "a sweet"][round.set.target] ?? t
            return "\(f.word) isn't \(one) — eat \(round.good.prefix(2).joined(separator: " "))"
        case .same:
            return f.trap ? "*\(f.word)* is the OPPOSITE of \(t)" : "*\(f.word)* doesn't mean \(t) — *\(right)* does"
        case .opposite:
            return f.trap ? "*\(f.word)* means the SAME as \(t)" : "*\(f.word)* isn't the opposite of \(t) — *\(right)* is"
        case .root:
            let meaning = round.set.hint.filter { $0.isLetter || $0 == " " }.trimmingCharacters(in: .whitespaces)
            return "*\(f.word)* isn't from \(round.set.target) (\(meaning)) — *\(right)* is"
        }
    }

    private func say(_ s: String) {
        let t = UUID(); lessonToken = t
        lesson = s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [weak self] in if self?.lessonToken == t { self?.lesson = nil } }
    }

    // MARK: Bot — picks a food, then steers toward it each step through `steer` (a swipe).

    override func botAct(correct: Bool) {
        if let g = botGoal, foods.contains(where: { $0.id == g }) { return }
        botGoal = foods.filter { $0.good == correct }.randomElement()?.id
    }

    private func botSteer(_ head: SSCell) {
        guard let g = botGoal, let f = foods.first(where: { $0.id == g }) else { botGoal = nil; return }
        func wrapDelta(_ a: Int, _ b: Int, _ n: Int) -> Int { var d = (b - a) % n; if d > n / 2 { d -= n }; if d < -n / 2 { d += n }; return d }
        let dc = wrapDelta(head.col, f.cell.col, cols), dr = wrapDelta(head.row, f.cell.row, rows)
        var want: [SSDir] = []
        if dc != 0 { want.append(dc > 0 ? .right : .left) }
        if dr != 0 { want.append(dr > 0 ? .down : .up) }
        let legal = [SSDir.up, .down, .left, .right].filter { !$0.isOpposite(dir) }
        let order = (want.contains(dir) ? [dir] : []) + want.filter { legal.contains($0) } + [dir] + legal
        let safe = order.first { d in
            let (x, y) = d.delta
            let n = SSCell(col: (head.col + x + cols) % cols, row: (head.row + y + rows) % rows)
            return !foods.contains { $0.cell == n && $0.id != g }
        } ?? dir
        if safe != dir { steer(safe) }
    }
}

#if DEBUG
/// Good, trap and filler words never overlap within a set, so every food has one honest answer.
private func ssSelfCheck() {
    var problems: [String] = []
    for s in ssPictureSets + ssEasy + ssMedium + ssHard + ssRoots {
        if !Set(s.good).isDisjoint(with: s.opposite) { problems.append("\(s.target) overlap") }
        if !ssPictureSets.contains(where: { $0.target == s.target }) &&
            (!Set(s.good).isDisjoint(with: ssFillers) || !Set(s.opposite).isDisjoint(with: ssFillers)) { problems.append("\(s.target) filler overlap") }
        if s.good.count < 2 || s.opposite.count < 2 { problems.append("\(s.target) too few") }
    }
    for s in ssRoots {
        let root = s.target.split(separator: " ").first.map { String($0).lowercased() } ?? ""
        if !s.target.contains("/") {
            for g in s.good where !g.lowercased().contains(root.prefix(3)) { problems.append("\(g) lacks \(root)") }
        }
    }
    print("SNAKE SELFCHECK: \(problems.isEmpty ? "OK" : problems.joined(separator: " | "))")
}
#endif

// MARK: - View

struct SynonymSnakeView: View {
    let onClose: () -> Void
    // Held in @State (not observed) so this view — and the shell it builds — isn't rebuilt on
    // every snake step; the shell and the play area observe the model themselves.
    @State private var model = SynonymSnakeModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.synonymSnake.spec ?? GameSpec(title: "Synonym Snake", mechanic: "", premise: "", game: .synonymSnake),
                    accent: Lu.mint, onClose: { LibraryVoice.stop(); onClose() },
                    backdrop: { SSGardenBackdrop() }) {
            SSPlayArea(model: model)
        }
        .onDisappear { model.stop(); LibraryVoice.stop() }
    }
}

/// A Roman peristyle garden: warm stone colonnade above, clipped box hedges, roses.
private struct SSGardenBackdrop: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .top) {
                LinearGradient(colors: [Color(hex: 0x9ed0e8), Color(hex: 0xe8f1d8)], startPoint: .top, endPoint: .bottom)
                // colonnade
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { _ in
                        Rectangle().fill(LinearGradient(colors: [Color(hex: 0xe9dcc0), Color(hex: 0xfaf3e2), Color(hex: 0xcdbd9c)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 18).frame(maxWidth: .infinity)
                    }
                }
                .frame(height: h * 0.3)
                Rectangle().fill(Color(hex: 0xc9744a)).frame(height: 26)          // tiled roof
                    .overlay(HStack(spacing: 6) { ForEach(0..<30, id: \.self) { _ in Capsule().fill(Color(hex: 0xa85a36)).frame(width: 8) } })
                    .clipped()
                // lawn
                LinearGradient(colors: [Color(hex: 0x7cbf5c), Color(hex: 0x5a9e43)], startPoint: .top, endPoint: .bottom)
                    .frame(height: h * 0.76).offset(y: h * 0.24)
                ForEach(0..<8, id: \.self) { k in
                    Text(k % 2 == 0 ? "🌹" : "🌿").font(.system(size: 20))
                        .position(x: w * (0.06 + CGFloat(k) * 0.125), y: h * 0.255)
                }
            }
        }
    }
}

private struct SSPlayArea: View {
    @ObservedObject var model: SynonymSnakeModel
    @State private var swiped = false

    var body: some View {
        VStack(spacing: 8) {
            HUDSpace(52)
            SSBanner(model: model)
            GeometryReader { geo in
                let cell = min(geo.size.width / CGFloat(model.cols), geo.size.height / CGFloat(model.rows))
                let w = cell * CGFloat(model.cols), h = cell * CGFloat(model.rows)
                let ox = (geo.size.width - w) / 2
                let center = { (c: SSCell) in CGPoint(x: ox + (CGFloat(c.col) + 0.5) * cell, y: (CGFloat(c.row) + 0.5) * cell) }
                ZStack(alignment: .topLeading) {
                    // hedge border + checker lawn
                    RoundedRectangle(cornerRadius: 22).fill(Color(hex: 0x2f6b2a))
                        .frame(width: w + 16, height: h + 16).offset(x: ox - 8, y: -8)
                        .shadow(color: .black.opacity(0.3), radius: 6, y: 4)
                    Canvas { ctx, _ in
                        for r in 0..<model.rows { for c in 0..<model.cols {
                            let p = center(SSCell(col: c, row: r))
                            ctx.fill(Path(CGRect(x: p.x - cell / 2, y: p.y - cell / 2, width: cell, height: cell)),
                                     with: .color(Color(hex: (r + c) % 2 == 0 ? 0x8fd06a : 0x80c35c)))
                        } }
                        // little hedge bumps on the border
                        for k in 0..<Int((w + h) * 2 / 22) {
                            let t = CGFloat(k) * 22
                            let pt: CGPoint = t < w ? CGPoint(x: ox + t, y: -4)
                                : t < w + h ? CGPoint(x: ox + w + 4, y: t - w)
                                : t < 2 * w + h ? CGPoint(x: ox + w - (t - w - h), y: h + 4)
                                : CGPoint(x: ox - 4, y: h - (t - 2 * w - h))
                            ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 9, y: pt.y - 9, width: 18, height: 18)), with: .color(Color(hex: 0x3d8a35)))
                        }
                    }
                    .frame(width: geo.size.width, height: h)
                    .clipShape(RoundedRectangle(cornerRadius: 16).offset(x: 0).size(width: geo.size.width, height: h))

                    ForEach(model.foods) { f in
                        let p = center(f.cell)
                        let half = model.pictures ? cell / 2 : cell * 0.8
                        SSFoodView(food: f, picture: model.pictures, cell: cell)
                            .position(x: min(max(p.x, ox + half), ox + w - half), y: p.y)
                            .transition(.scale.combined(with: .opacity))
                    }
                    TimelineView(.animation(paused: model.phase != .playing)) { tl in
                        Canvas { ctx, _ in
                            drawSnake(&ctx, now: tl.date, cell: cell, center: center)
                        }
                    }
                    .frame(width: geo.size.width, height: h)
                    .allowsHitTesting(false)
                    ForEach(model.pops) { p in
                        LibraryBurst(glyphs: p.good ? ["✨", "⭐️", "✨", "🌟", "✨"] : ["💥", "🤢", "💥"]).position(center(p.cell))
                    }
                }
                .frame(width: geo.size.width, height: h)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            let t = v.translation
                            guard !swiped, max(abs(t.width), abs(t.height)) > 22 else { return }
                            swiped = true
                            if abs(t.width) > abs(t.height) { model.steer(t.width > 0 ? .right : .left) }
                            else { model.steer(t.height > 0 ? .down : .up) }
                        }
                        .onEnded { v in
                            defer { swiped = false }
                            guard !swiped, let head = model.snake.first else { return }
                            let hp = center(head)
                            model.tapSteer(dc: (v.location.x - hp.x) / cell, dr: (v.location.y - hp.y) / cell)
                        }
                )
            }
            .padding(.top, 8).padding(.bottom, 12)
        }
        .padding(.horizontal, 16)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: model.foods)
    }

    /// The snake: one thick, rounded, striped tube that glides between grid steps, and a head
    /// with eyes (happy squint on a good bite, queasy green on a bad one) and a flicking tongue.
    private func drawSnake(_ ctx: inout GraphicsContext, now: Date, cell: CGFloat, center: (SSCell) -> CGPoint) {
        let body = model.snake, prev = model.prevSnake
        guard !body.isEmpty else { return }
        let f = CGFloat(min(1, max(0, now.timeIntervalSince(model.stepAt) / max(0.05, model.stepTime * 0.9))))
        var pts: [CGPoint] = []
        for i in body.indices {
            let to = center(body[i])
            let from = center(prev.indices.contains(i) ? prev[i] : body[i])
            if abs(to.x - from.x) > cell * 1.5 || abs(to.y - from.y) > cell * 1.5 { pts.append(to) }   // wrapped: no glide
            else { pts.append(CGPoint(x: from.x + (to.x - from.x) * f, y: from.y + (to.y - from.y) * f)) }
        }
        // split the tube where it wraps through the hedge
        // (each cut end gets a half-cell stub running out toward the edge it went through)
        var runs: [[CGPoint]] = [[pts[0]]]
        for i in 1..<pts.count {
            let dx = pts[i].x - pts[i - 1].x, dy = pts[i].y - pts[i - 1].y
            if hypot(dx, dy) > cell * 1.5 {
                let sx: CGFloat = abs(dx) > cell * 1.5 ? (dx > 0 ? 1 : -1) : 0
                let sy: CGFloat = abs(dy) > cell * 1.5 ? (dy > 0 ? 1 : -1) : 0
                runs[runs.count - 1].append(CGPoint(x: pts[i - 1].x - sx * cell * 0.5, y: pts[i - 1].y - sy * cell * 0.5))
                runs.append([CGPoint(x: pts[i].x + sx * cell * 0.5, y: pts[i].y + sy * cell * 0.5)])
            }
            runs[runs.count - 1].append(pts[i])
        }
        let sick = model.mood < 0
        let skin = Color(hex: sick ? 0xa8b84a : 0x3f9a4a), belly = Color(hex: sick ? 0xd8e08a : 0xf2d66b)
        for run in runs {
            var p = Path()
            p.addLines(run)
            if run.count == 1 { p = Path(ellipseIn: CGRect(x: run[0].x - 1, y: run[0].y - 1, width: 2, height: 2)) }
            ctx.stroke(p, with: .color(Color.black.opacity(0.18)), style: StrokeStyle(lineWidth: cell * 0.62, lineCap: .round, lineJoin: .round))
            ctx.stroke(p, with: .color(skin), style: StrokeStyle(lineWidth: cell * 0.56, lineCap: .round, lineJoin: .round))
            ctx.stroke(p, with: .color(belly), style: StrokeStyle(lineWidth: cell * 0.16, lineCap: .round, lineJoin: .round, dash: [cell * 0.22, cell * 0.2]))
        }
        // head
        let h = pts[0]
        let a = model.heading
        let dx = cos(a), dy = sin(a)
        let r = cell * 0.4
        // tongue
        if Int(now.timeIntervalSinceReferenceDate * 3) % 3 == 0 || model.mood > 0 {
            var t = Path()
            let tip = CGPoint(x: h.x + dx * r * 1.9, y: h.y + dy * r * 1.9)
            t.move(to: CGPoint(x: h.x + dx * r * 0.9, y: h.y + dy * r * 0.9)); t.addLine(to: tip)
            t.move(to: tip); t.addLine(to: CGPoint(x: tip.x + (dx - dy) * 5, y: tip.y + (dy + dx) * 5))
            t.move(to: tip); t.addLine(to: CGPoint(x: tip.x + (dx + dy) * 5, y: tip.y + (dy - dx) * 5))
            ctx.stroke(t, with: .color(Color(hex: 0xd8344a)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
        ctx.fill(Path(ellipseIn: CGRect(x: h.x - r, y: h.y - r, width: r * 2, height: r * 2)), with: .color(skin))
        for s in [-1.0, 1.0] as [CGFloat] {
            let e = CGPoint(x: h.x + dx * r * 0.35 - dy * r * 0.5 * s, y: h.y + dy * r * 0.35 + dx * r * 0.5 * s)
            let er = r * 0.36
            ctx.fill(Path(ellipseIn: CGRect(x: e.x - er, y: e.y - er, width: er * 2, height: er * 2)), with: .color(.white))
            if model.mood > 0 {
                var arc = Path()
                arc.addArc(center: e, radius: er * 0.6, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
                ctx.stroke(arc, with: .color(.black), lineWidth: 2.5)
            } else {
                let pr = er * (model.mood < 0 ? 0.35 : 0.55)
                let pc = CGPoint(x: e.x + dx * er * 0.3, y: e.y + dy * er * 0.3)
                ctx.fill(Path(ellipseIn: CGRect(x: pc.x - pr, y: pc.y - pr, width: pr * 2, height: pr * 2)), with: .color(.black))
            }
        }
        // rosy cheek
        ctx.fill(Path(ellipseIn: CGRect(x: h.x - dx * r * 0.2 - 4, y: h.y - dy * r * 0.2 - 4, width: 8, height: 8)), with: .color(Color(hex: 0xf28b82).opacity(0.0)))
    }
}

private struct SSBanner: View {
    @ObservedObject var model: SynonymSnakeModel

    private var heading: String {
        switch model.round.mode {
        case .pictures: return "EAT ALL THE"
        case .same: return "EAT WORDS THAT MEAN"
        case .opposite: return "EAT THE OPPOSITES OF"
        case .root: return "EAT WORDS FROM THE ROOT"
        }
    }

    var body: some View {
        let set = model.round.set
        ZStack {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(heading).font(luFont(11, .heavy)).tracking(1.6).foregroundStyle(Color(hex: 0x6a4a22))
                    HStack(spacing: 8) {
                        if model.round.mode != .root { Text(set.hint).font(.system(size: 30)) }
                        Text(set.target).font(luSerif(28, .black))
                            .foregroundStyle(Color(hex: model.round.mode == .opposite ? 0xb0371c : 0x2a5a1c))
                            .lineLimit(1).minimumScaleFactor(0.5)
                        if model.round.mode == .root {
                            Text("= " + set.hint).font(luFont(18, .heavy)).foregroundStyle(Color(hex: 0x2a1d10))
                                .lineLimit(1).minimumScaleFactor(0.6)
                        }
                    }
                }
                Spacer(minLength: 0)
                LibrarySpeakerButton(size: 44) { LibraryVoice.say(model.sayCue) }
            }
            .opacity(model.lesson == nil ? 1 : 0)
            if let lesson = model.lesson {
                libMarked(lesson, base: 0x2a1d10, mark: 0xb0371c)
                    .font(luFont(17, .heavy)).multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.6)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 70)
        .background(Parchment(radius: 16))
        .overlay(alignment: .bottomTrailing) {
            if model.combo >= 2 && model.lesson == nil {
                Text("×\(model.combo)").font(luFont(16)).foregroundStyle(Color(hex: 0xfff3c4))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Color(hex: 0x2f6b2a)))
                    .offset(x: 6, y: 10)
                    .id(model.combo).transition(.scale(scale: 1.4).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: set.target)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: model.lesson)
    }
}

private struct SSFoodView: View {
    let food: SSFood
    let picture: Bool
    let cell: CGFloat
    @State private var bob = false

    var body: some View {
        Group {
            if picture {
                Text(food.word).font(.system(size: cell * 0.7))
                    .frame(width: cell * 0.96, height: cell * 0.96)
                    .background(Circle().fill(Color(hex: 0xfdf6e3)).shadow(color: .black.opacity(0.25), radius: 2, y: 2))
            } else {
                Text(food.word).font(luFont(min(18, cell * 0.3), .black)).foregroundStyle(Color(hex: 0x2a1d10))
                    .lineLimit(1).minimumScaleFactor(0.45)
                    .padding(.horizontal, 8)
                    .frame(width: cell * 1.6, height: cell * 0.68)
                    .background(Capsule().fill(LinearGradient(colors: [Color(hex: 0xfffaf0), Color(hex: 0xf0e2c0)], startPoint: .top, endPoint: .bottom))
                        .overlay(Capsule().stroke(Color(hex: 0x6a4a22).opacity(0.6), lineWidth: 2))
                        .shadow(color: .black.opacity(0.25), radius: 2, y: 2))
            }
        }
        .scaleEffect(bob ? 1.04 : 0.96)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: bob)
        .onAppear { bob = true }
    }
}
