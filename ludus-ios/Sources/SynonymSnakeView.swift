import SwiftUI

// MARK: - Synonym Snake  (Library · grid snake, vocabulary)
//
// A friendly snake crawls a chunky grid; steer it by tapping beside its head (it turns toward your
// finger) or by swiping. Eat the foods that match the banner, dodge the rest. Built on GameKit.
// No crash deaths — the snake wraps through the walls and may cross itself — so hearts are only
// about words. A wrong bite says why ("*tiny* is the OPPOSITE of big").
//
// Level ladder:
//   I    pictures: "eat the 🍎 FRUIT" — 2 good + 1 bad on the board, slow snake
//   II   easy synonyms with a picture hint (BIG 🐘 → large, huge, giant); bad = unrelated words
//   III  same words, but some bad ones are OPPOSITES (tiny for BIG)
//   IV   harder words (ANGRY → furious, cross); more food on the board
//   V    tier-2 vocabulary (ENORMOUS → immense, colossal; TIMID → meek, bashful) with opposite traps
//   VI+  tier-2, fuller board, a little faster each level (capped)

private struct SSSet {
    let target: String
    let hint: String         // picture next to the target word
    let good: [String]
    let opposite: [String]
}

// Level I: picture categories (good / bad are emoji).
private let ssPictureSets: [SSSet] = [
    SSSet(target: "FRUIT", hint: "🍎", good: ["🍎", "🍌", "🍇", "🍓", "🍊", "🍐", "🍒", "🍉", "🍍"],
          opposite: ["🚗", "⚽️", "🧦", "🪑", "🐶", "🎈", "✏️", "🧸"]),
    SSSet(target: "ANIMALS", hint: "🐾", good: ["🐶", "🐱", "🐮", "🐷", "🐸", "🐵", "🐰", "🦁", "🐘"],
          opposite: ["🍎", "🚗", "⚽️", "🧦", "🎈", "🍌", "✏️", "🏠"]),
    SSSet(target: "THINGS THAT GO", hint: "🚗", good: ["🚗", "🚌", "🚲", "✈️", "🚂", "🚀", "🚜", "⛵️"],
          opposite: ["🍎", "🐶", "🧦", "🌳", "🎂", "🏠", "🧸"]),
    SSSet(target: "SWEETS", hint: "🍭", good: ["🍰", "🍩", "🍪", "🍭", "🍬", "🧁", "🍫", "🍦"],
          opposite: ["🥦", "🥕", "🧦", "🚗", "🐟", "⚽️", "✏️"]),
]
// Level II–III.
private let ssEasy: [SSSet] = [
    SSSet(target: "BIG", hint: "🐘", good: ["large", "huge", "giant"], opposite: ["small", "tiny", "little"]),
    SSSet(target: "SMALL", hint: "🐭", good: ["little", "tiny", "mini"], opposite: ["big", "huge", "large"]),
    SSSet(target: "HAPPY", hint: "😀", good: ["glad", "joyful", "cheerful"], opposite: ["sad", "upset", "grumpy"]),
    SSSet(target: "SAD", hint: "😢", good: ["unhappy", "upset", "gloomy"], opposite: ["happy", "glad", "cheerful"]),
    SSSet(target: "FAST", hint: "🐇", good: ["quick", "speedy", "rapid"], opposite: ["slow", "sluggish"]),
    SSSet(target: "COLD", hint: "🧊", good: ["chilly", "icy", "freezing"], opposite: ["hot", "warm", "boiling"]),
    SSSet(target: "SHOUT", hint: "📣", good: ["yell", "scream", "holler"], opposite: ["whisper", "mumble"]),
    SSSet(target: "JUMP", hint: "🦘", good: ["leap", "hop", "bounce"], opposite: ["sit", "crawl"]),
    SSSet(target: "SCARED", hint: "😱", good: ["afraid", "frightened", "fearful"], opposite: ["brave", "bold", "calm"]),
    SSSet(target: "TIRED", hint: "😴", good: ["sleepy", "weary", "worn out"], opposite: ["awake", "lively", "rested"]),
]
// Level IV.
private let ssMedium: [SSSet] = [
    SSSet(target: "ANGRY", hint: "😠", good: ["mad", "cross", "furious"], opposite: ["calm", "pleased", "cheerful"]),
    SSSet(target: "SMART", hint: "🧠", good: ["clever", "bright", "wise"], opposite: ["foolish", "silly", "dim"]),
    SSSet(target: "BRAVE", hint: "🦁", good: ["bold", "fearless", "daring"], opposite: ["scared", "timid", "cowardly"]),
    SSSet(target: "QUIET", hint: "🤫", good: ["silent", "hushed", "muted"], opposite: ["loud", "noisy", "booming"]),
    SSSet(target: "STRONG", hint: "💪", good: ["powerful", "mighty", "tough"], opposite: ["weak", "feeble", "frail"]),
    SSSet(target: "EASY", hint: "✅", good: ["simple", "effortless"], opposite: ["hard", "difficult", "tricky"]),
    SSSet(target: "RICH", hint: "💰", good: ["wealthy", "well-off"], opposite: ["poor", "needy"]),
    SSSet(target: "FUNNY", hint: "🤣", good: ["comical", "hilarious", "amusing"], opposite: ["serious", "dull", "boring"]),
]
// Level V+.
private let ssHard: [SSSet] = [
    SSSet(target: "ENORMOUS", hint: "🐋", good: ["immense", "massive", "colossal", "vast"], opposite: ["tiny", "minute", "puny"]),
    SSSet(target: "FURIOUS", hint: "🌋", good: ["enraged", "livid", "irate"], opposite: ["calm", "content", "serene"]),
    SSSet(target: "TIMID", hint: "🐢", good: ["shy", "bashful", "meek"], opposite: ["bold", "daring", "confident"]),
    SSSet(target: "FRAGILE", hint: "🥚", good: ["delicate", "breakable", "flimsy"], opposite: ["sturdy", "tough", "solid"]),
    SSSet(target: "GLOOMY", hint: "🌧️", good: ["dismal", "dreary", "bleak"], opposite: ["cheerful", "bright", "sunny"]),
    SSSet(target: "HUNGRY", hint: "🍽️", good: ["starving", "famished", "ravenous"], opposite: ["full", "stuffed"]),
    SSSet(target: "CALM", hint: "🌊", good: ["peaceful", "tranquil", "serene"], opposite: ["frantic", "anxious", "restless"]),
    SSSet(target: "HONEST", hint: "🤝", good: ["truthful", "sincere", "frank"], opposite: ["sneaky", "deceitful", "dishonest"]),
    SSSet(target: "STRANGE", hint: "👽", good: ["odd", "peculiar", "bizarre"], opposite: ["normal", "ordinary", "usual"]),
    SSSet(target: "EXHAUSTED", hint: "🥵", good: ["weary", "drained", "worn out"], opposite: ["lively", "energetic", "rested"]),
    SSSet(target: "ANCIENT", hint: "🏛️", good: ["old", "aged", "age-old"], opposite: ["modern", "new", "recent"]),
    SSSet(target: "BRIEF", hint: "⏱️", good: ["short", "quick", "concise"], opposite: ["long", "lengthy", "endless"]),
]
/// Unrelated words (bad food at II, mixed in later).
private let ssFillers = ["dog", "table", "blue", "pizza", "tree", "sock", "river", "book", "seven", "window", "spoon", "cloud"]

private func ssSets(_ level: Int) -> [SSSet] {
    switch level { case 1: return ssPictureSets; case 2, 3: return ssEasy; case 4: return ssMedium; default: return ssHard }
}

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
    let opposite: Bool
}

private struct SSPop: Identifiable { let id = UUID(); let cell: SSCell; let text: String; let good: Bool }

@MainActor
private final class SynonymSnakeModel: ArcadeModel {
    let cols = 6, rows = 9

    @Published var snake: [SSCell] = []
    @Published var foods: [SSFood] = []
    @Published var set = ssPictureSets[0]
    @Published var face = "🙂"
    @Published var lesson: String?
    @Published var pops: [SSPop] = []

    private var dir: SSDir = .right
    private var queued: SSDir?
    private var eatenThisSet = 0
    private var loop: Task<Void, Never>?
    private var botGoal: UUID?
    private var lessonToken = UUID()

    init() { super.init(key: GameID.synonymSnake.rawValue) }

    private var stepTime: Double {
        level <= 8 ? [0.62, 0.56, 0.5, 0.46, 0.42, 0.38, 0.35, 0.32][level - 1] : max(0.26, 0.32 - Double(level - 8) * 0.01)
    }
    private var goodOnBoard: Int { level <= 3 ? 2 : 3 }
    private var badOnBoard: Int { level == 1 ? 1 : (level <= 3 ? 2 : 3) }

    override func onBegin() {
        snake = [SSCell(col: 2, row: rows / 2), SSCell(col: 1, row: rows / 2), SSCell(col: 0, row: rows / 2)]
        dir = .right; queued = nil; face = "🙂"; lesson = nil; pops = []; botGoal = nil
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

    override func onLevelUp() { newSet() }

    func stop() { loop?.cancel() }

    private func newSet() {
        var s = ssSets(level).randomElement()!
        for _ in 0..<6 where s.target == set.target { s = ssSets(level).randomElement()! }
        set = s; eatenThisSet = 0
        foods = []
        refill()
    }

    /// Top the board up to `goodOnBoard` good + `badOnBoard` bad foods, away from the head and
    /// from each other (word labels are wider than a cell).
    private func refill() {
        func place(_ word: String, good: Bool, opposite: Bool) {
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
            foods.append(SSFood(cell: cell, word: word, good: good, opposite: opposite))
        }
        var guardCount = 0
        while foods.filter(\.good).count < goodOnBoard && guardCount < 10 {
            guardCount += 1
            let unused = set.good.filter { w in !foods.contains { $0.word == w } }
            place((unused.isEmpty ? set.good : unused).randomElement()!, good: true, opposite: false)
        }
        guardCount = 0
        while foods.filter({ !$0.good }).count < badOnBoard && guardCount < 10 {
            guardCount += 1
            // Opposite traps from III on (pictures at I use their own "bad" list).
            let useOpposite = level == 1 || (level >= 3 && Double.random(in: 0..<1) < 0.6)
            let pool = (useOpposite ? set.opposite : ssFillers).filter { w in !foods.contains { $0.word == w } }
            guard let w = pool.randomElement() else { continue }
            place(w, good: false, opposite: useOpposite && level > 1)
        }
    }

    // MARK: Input

    func steer(_ d: SSDir) {
        guard phase == .playing else { return }
        if d.isOpposite(queued ?? dir) || d == (queued ?? dir) { return }
        queued = d
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
        snake.insert(next, at: 0)
        if let i = foods.firstIndex(where: { $0.cell == next }) {
            let f = foods.remove(at: i)
            eat(f, at: next)
        } else {
            snake.removeLast()
        }
    }

    private func eat(_ f: SSFood, at cell: SSCell) {
        if f.good {
            if snake.count > 12 { snake.removeLast() }    // grow, up to a point
            face = "😋"
            pops.append(SSPop(cell: cell, text: "✨", good: true))
            let up = hit()
            eatenThisSet += 1
            if !up && eatenThisSet >= 3 { newSet() } else if !up { refill() }
        } else {
            snake.removeLast()
            face = "🤢"
            pops.append(SSPop(cell: cell, text: "💥", good: false))
            say(lessonFor(f))
            miss(delay: 1.6)
            refill()
        }
        let p = pops.last!.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.pops.removeAll { $0.id == p }
            if self?.phase == .playing { self?.face = "🙂" }
        }
    }

    private func lessonFor(_ f: SSFood) -> String {
        if level == 1 { return "\(f.word) isn't \(set.target.lowercased() == "things that go" ? "a thing that goes" : set.target.lowercased()) — eat \(set.good.prefix(2).joined(separator: " "))" }
        let t = set.target.lowercased()
        if f.opposite { return "*\(f.word)* is the OPPOSITE of \(t)" }
        return "*\(f.word)* doesn't mean \(t) — *\(set.good[0])* does"
    }

    private func say(_ s: String) {
        let t = UUID(); lessonToken = t
        lesson = s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { [weak self] in if self?.lessonToken == t { self?.lesson = nil } }
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
        // Prefer: keep going if that's a wanted way, else a wanted turn, else any legal way —
        // skipping any move that would bite a different food (a careful child steers around).
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
/// Good, opposite and filler words never overlap within a set, so every food has one honest answer.
private func ssSelfCheck() {
    for s in ssPictureSets + ssEasy + ssMedium + ssHard {
        precondition(Set(s.good).isDisjoint(with: s.opposite), "Synonym Snake: \(s.target) overlap")
        precondition(Set(s.good).isDisjoint(with: ssFillers) && Set(s.opposite).isDisjoint(with: ssFillers) || ssPictureSets.contains { $0.target == s.target },
                     "Synonym Snake: \(s.target) filler overlap")
        precondition(s.good.count >= 2, "Synonym Snake: \(s.target) too few")
    }
    print("SELFCHECK synonymSnake OK")
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
                    accent: Lu.mint, onClose: onClose) {
            SSPlayArea(model: model)
        }
        .onAppear {
            #if DEBUG
            ssSelfCheck()
            #endif
        }
        .onDisappear { model.stop() }
    }
}

private struct SSPlayArea: View {
    @ObservedObject var model: SynonymSnakeModel
    @State private var swiped = false

    var body: some View {
        VStack(spacing: 10) {
            Color.clear.frame(height: 52)
            SSBanner(set: model.set, picture: model.level == 1, lesson: model.lesson, combo: model.combo)
            GeometryReader { geo in
                let cell = min(geo.size.width / CGFloat(model.cols), geo.size.height / CGFloat(model.rows))
                let w = cell * CGFloat(model.cols), h = cell * CGFloat(model.rows)
                let ox = (geo.size.width - w) / 2
                let center = { (c: SSCell) in CGPoint(x: ox + (CGFloat(c.col) + 0.5) * cell, y: (CGFloat(c.row) + 0.5) * cell) }
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 20).fill(Color(hex: Lu.ground2))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: Lu.goldLine).opacity(0.6), lineWidth: 3))
                        .frame(width: w, height: h).offset(x: ox)
                    Canvas { ctx, _ in
                        for r in 0..<model.rows { for c in 0..<model.cols where (r + c) % 2 == 0 {
                            let p = center(SSCell(col: c, row: r))
                            ctx.fill(Path(roundedRect: CGRect(x: p.x - cell / 2 + 2, y: p.y - cell / 2 + 2, width: cell - 4, height: cell - 4), cornerRadius: 8),
                                     with: .color(Color(hex: Lu.panel).opacity(0.6)))
                        } }
                    }
                    .frame(width: geo.size.width, height: h)

                    ForEach(Array(model.snake.enumerated().dropFirst().reversed()), id: \.offset) { i, s in
                        SSSegment(head: false, face: "", cell: cell, t: CGFloat(i) / CGFloat(max(1, model.snake.count)))
                            .position(center(s))
                    }
                    ForEach(model.foods) { f in
                        let p = center(f.cell)
                        let half = model.level == 1 ? cell / 2 : cell * 0.8
                        SSFoodView(food: f, picture: model.level == 1, cell: cell)
                            .position(x: min(max(p.x, ox + half), ox + w - half), y: p.y)
                            .transition(.scale.combined(with: .opacity))
                    }
                    if let h = model.snake.first {
                        SSSegment(head: true, face: model.face, cell: cell, t: 0).position(center(h))
                    }
                    ForEach(model.pops) { p in
                        LaneSparkBurst(glyphs: p.good ? ["✨", "⭐️", "✨", "🌟", "✨"] : ["💥", "💢", "💥"])
                            .position(center(p.cell))
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
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 12)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: model.foods)
    }
}

private struct SSBanner: View {
    let set: SSSet
    let picture: Bool
    let lesson: String?
    let combo: Int

    var body: some View {
        VStack(spacing: 6) {
            VStack(spacing: 2) {
                Text(picture ? "EAT ALL THE" : "EAT WORDS THAT MEAN").font(luFont(12, .heavy)).tracking(2)
                    .foregroundStyle(Color(hex: Lu.inkDim))
                HStack(spacing: 10) {
                    Text(set.hint).font(.system(size: 34))
                    Text(set.target).font(luSerif(30, .black))
                        .foregroundStyle(LinearGradient(colors: [Color(hex: Lu.gold), Color(hex: Lu.tangerine)], startPoint: .top, endPoint: .bottom))
                        .lineLimit(1).minimumScaleFactor(0.6)
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(luPanelShape(16))
            .id(set.target)
            .transition(.scale(scale: 0.85).combined(with: .opacity))

            ZStack {
                if let lesson {
                    luMarked(lesson, base: Lu.inkDark, mark: 0x9c2a14)
                        .font(luFont(17, .heavy)).multilineTextAlignment(.center).minimumScaleFactor(0.6)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Capsule().fill(Color(hex: Lu.gold)))
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                } else if combo >= 2 {
                    Text("COMBO ×\(combo)!").font(luFont(18)).foregroundStyle(Color(hex: Lu.mint))
                        .id(combo).transition(.scale(scale: 1.3).combined(with: .opacity))
                }
            }
            .frame(height: 36)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: set.target)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: lesson)
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
                Text(food.word).font(.system(size: cell * 0.62))
                    .frame(width: cell * 0.92, height: cell * 0.92)
                    .background(Circle().fill(Color.white.opacity(0.9)))
            } else {
                Text(food.word).font(luFont(min(18, cell * 0.3), .black)).foregroundStyle(Color(hex: Lu.inkDark))
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .padding(.horizontal, 8)
                    .frame(width: cell * 1.6, height: cell * 0.7)
                    .background(Capsule().fill(LinearGradient(colors: [.white, Color(hex: Lu.silver)], startPoint: .top, endPoint: .bottom))
                        .overlay(Capsule().stroke(Color(hex: Lu.grape).opacity(0.6), lineWidth: 2)))
            }
        }
        .scaleEffect(bob ? 1.05 : 0.95)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: bob)
        .onAppear { bob = true }
    }
}

private struct SSSegment: View {
    let head: Bool
    let face: String
    let cell: CGFloat
    let t: CGFloat     // 0 at head → 1 at tail

    var body: some View {
        let side = cell * (head ? 0.9 : 0.78 - t * 0.18)
        ZStack {
            RoundedRectangle(cornerRadius: side * 0.38, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: Lu.mint), luShade(Lu.mint, head ? -35 : -60)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: side * 0.38, style: .continuous).stroke(.white.opacity(head ? 0.55 : 0.25), lineWidth: 2))
            if head { Text(face).font(.system(size: side * 0.62)) }
        }
        .frame(width: side, height: side)
        .zIndex(head ? 2 : 1)
    }
}
