import SwiftUI

// MARK: - Chariot Code  (Brain Benders · coding)
//
// Program the chariot BEFORE it runs: tap arrows to lay down a route on the scroll, then GO. The
// horse trots the plan one square at a time — into a hay bale and it's "Neigh-ver mind!", onto the
// 🏁 with every 🍎 eaten and the crowd cheers. A miss rolls the chariot home and plays the right
// program for you, so the answer is always shown.
//
// Difficulty is continuous (`d`):
//   • the arena grows from 3 × 3 to 6 × 7, and the shortest route from 2 moves to ~13;
//   • obstacles thicken; apples to collect fade in from d≈3 (order matters — a real plan);
//   • the planned-route preview line fades out (d 2.5 → 5) so the plan lives in your head;
//   • REPEAT steps (tap a step for ×2, ×3) fade in from d≈3.5, and the scroll gets fewer spare
//     slots, so by d≈8 a route only fits if you spot the loops.

// MARK: Grid + solver

private enum CCDir: Int, CaseIterable {
    case up, right, down, left
    var dr: Int { [-1, 0, 1, 0][rawValue] }
    var dc: Int { [0, 1, 0, -1][rawValue] }
    var arrow: String { ["arrow.up", "arrow.right", "arrow.down", "arrow.left"][rawValue] }
}

private struct CCPos: Hashable { var r: Int, c: Int }

private enum CCThing: Equatable {
    case empty, hay, jar, lion, apple
    var blocks: Bool { self == .hay || self == .jar || self == .lion }
}

private struct CCCmd: Identifiable, Equatable {
    let id = UUID()
    var dir: CCDir
    var times = 1
}

private struct CCPuzzle {
    var rows: Int, cols: Int
    var cells: [[CCThing]]
    var start: CCPos, goal: CCPos
    var apples: [CCPos]
    var loops: Bool
    var slots: Int
    var preview: Bool
    var answer: [CCCmd]          // the shown / bot solution (fits `slots`)
    var moves: Int               // the shortest route length

    func inside(_ p: CCPos) -> Bool { p.r >= 0 && p.r < rows && p.c >= 0 && p.c < cols }
    func free(_ p: CCPos) -> Bool { inside(p) && !cells[p.r][p.c].blocks }
}

/// Fewest commands (or fewest moves) from start to goal, eating every apple, as a 0-1 BFS over
/// (square, apples eaten, last direction, run length). `maxRun` 1 = no repeats (each step its own
/// command); 3 = a command may repeat ×2 or ×3. Returns the program.
private func ccSolve(_ p: CCPuzzle, maxRun: Int, fewestMoves: Bool) -> [CCCmd]? {
    struct S: Hashable { var pos: CCPos, mask: Int, dir: Int, run: Int }
    let all = (1 << p.apples.count) - 1
    func eat(_ pos: CCPos, _ m: Int) -> Int {
        if let i = p.apples.firstIndex(of: pos) { return m | (1 << i) }
        return m
    }
    let s0 = S(pos: p.start, mask: eat(p.start, 0), dir: -1, run: 0)
    var dist: [S: Int] = [s0: 0]
    var prev: [S: S] = [:]
    var dq: [S] = [s0]
    var head = 0
    // A deque emulated with a front-insert array is fine at this size (≤ 42 × 8 × 5 × 4 states).
    var front: [S] = []
    func pop() -> S? {
        if let f = front.popLast() { return f }
        if head < dq.count { head += 1; return dq[head - 1] }
        return nil
    }
    var end: S?
    while let s = pop() {
        let ds = dist[s]!
        if s.pos == p.goal && s.mask == all { end = s; break }
        if s.pos == p.goal && s.dir >= 0 { /* passing through the goal early is fine only if apples remain */ }
        for d in CCDir.allCases {
            let np = CCPos(r: s.pos.r + d.dr, c: s.pos.c + d.dc)
            guard p.free(np) else { continue }
            let same = d.rawValue == s.dir && s.run < maxRun
            let cost = fewestMoves ? 1 : (same ? 0 : 1)
            let ns = S(pos: np, mask: eat(np, s.mask), dir: d.rawValue, run: same ? s.run + 1 : 1)
            let nd = ds + cost
            if dist[ns] == nil || nd < dist[ns]! {
                dist[ns] = nd; prev[ns] = s
                if cost == 0 { front.append(ns) } else { dq.append(ns) }
            }
        }
    }
    guard var cur = end else { return nil }
    var dirs: [CCDir] = []
    while let pr = prev[cur] { dirs.append(CCDir(rawValue: cur.dir)!); cur = pr }
    dirs.reverse()
    var out: [CCCmd] = []
    for d in dirs {
        if let last = out.last, last.dir == d, last.times < maxRun { out[out.count - 1].times += 1 }
        else { out.append(CCCmd(dir: d)) }
    }
    return out
}

/// What a program does: the squares visited, whether it crashed (and where), apples eaten.
private struct CCTrace {
    var path: [CCPos]          // start + every square reached
    var crash: CCPos?          // the blocked / off-board square it tried to enter
    var stepOfCmd: [Int]       // for each step, which command it belongs to
    var won: Bool
}

private func ccRun(_ p: CCPuzzle, _ prog: [CCCmd]) -> CCTrace {
    var pos = p.start
    var path = [pos]
    var eaten = Set<CCPos>()
    if p.apples.contains(pos) { eaten.insert(pos) }
    var owner: [Int] = []
    for (ci, c) in prog.enumerated() {
        for _ in 0..<c.times {
            let np = CCPos(r: pos.r + c.dir.dr, c: pos.c + c.dir.dc)
            guard p.free(np) else { return CCTrace(path: path, crash: np, stepOfCmd: owner + [ci], won: false) }
            pos = np; path.append(pos); owner.append(ci)
            if p.apples.contains(pos) { eaten.insert(pos) }
            if pos == p.goal && eaten.count == p.apples.count {
                return CCTrace(path: path, crash: nil, stepOfCmd: owner, won: true)
            }
        }
    }
    return CCTrace(path: path, crash: nil, stepOfCmd: owner, won: false)
}

// MARK: - Model

@MainActor
private final class ChariotModel: ArcadeModel {
    @Published var puzzle: CCPuzzle
    @Published var program: [CCCmd] = []
    @Published var pos = CCPos(r: 0, c: 0)
    @Published var eaten: Set<CCPos> = []
    @Published var facingLeft = false
    @Published var running = false
    @Published var activeCmd: Int?
    @Published var crashAt: CCPos?
    @Published var showing = false        // playing the right answer after a miss
    @Published var cheer = false
    @Published var hintDir: CCDir?
    @Published var puzzleID = 0
    @Published var bubble: String?

    private var gen = 0

    init() {
        puzzle = CCPuzzle(rows: 3, cols: 3, cells: Array(repeating: Array(repeating: .empty, count: 3), count: 3),
                          start: CCPos(r: 1, c: 0), goal: CCPos(r: 1, c: 2), apples: [], loops: false,
                          slots: 4, preview: true, answer: [CCCmd(dir: .right, times: 1), CCCmd(dir: .right, times: 1)], moves: 2)
        super.init(key: GameID.chariotCode.rawValue)
    }

    override func perLevel(_ level: Int) -> Int { 4 }
    override func onBegin() { newPuzzle() }

    private func later(_ s: Double, _ f: @escaping () -> Void) {
        let g = gen
        DispatchQueue.main.asyncAfter(deadline: .now() + s) { [weak self] in
            guard let self, self.gen == g, self.phase == .playing else { return }
            f()
        }
    }

    // MARK: Puzzle generation

    private func make() -> CCPuzzle {
        let cols = rampInt(3, 6, to: 8)
        let rows = rampInt(3, 7, to: 9)
        let want = rampInt(2, 13, to: 9)
        let density = ramp(0, 0.28, from: 1.5, to: 7.5)
        let appleN = Int((ramp(0, 2.6, from: 2.6, to: 9) + Double.random(in: 0..<0.8)).rounded(.down))
        let loopsOn = d >= 3.5 && (chance(1, from: 3.5, to: 5) || want > 8)
        let spare = rampInt(3, 0, from: 1, to: 8)
        let preview = !chance(1, from: 2.5, to: 5)
        var best: (CCPuzzle, Int)?
        for attempt in 0..<400 {
            var cells = Array(repeating: Array(repeating: CCThing.empty, count: cols), count: rows)
            let all = (0..<rows).flatMap { r in (0..<cols).map { CCPos(r: r, c: $0) } }.shuffled()
            let start = all[0], goal = all[1]
            if abs(start.r - goal.r) + abs(start.c - goal.c) < min(want, 2) { continue }
            let kinds: [CCThing] = [.hay, .hay, .jar, .lion]
            let nObs = Int(Double(rows * cols) * density)
            for p in all.dropFirst(2).prefix(nObs) { cells[p.r][p.c] = kinds.randomElement()! }
            let apples = Array(all.dropFirst(2 + nObs).prefix(appleN))
            for a in apples { cells[a.r][a.c] = .apple }
            var pz = CCPuzzle(rows: rows, cols: cols, cells: cells, start: start, goal: goal, apples: apples,
                              loops: loopsOn, slots: 0, preview: preview, answer: [], moves: 0)
            guard let short = ccSolve(pz, maxRun: 1, fewestMoves: true) else { continue }
            let moves = short.count
            if !loopsOn && moves > 8 { continue }
            let answer = loopsOn ? (ccSolve(pz, maxRun: 3, fewestMoves: false) ?? short) : short
            pz.moves = moves
            pz.answer = answer
            pz.slots = min(8, answer.count + spare)
            if answer.count > 8 { continue }
            let off = abs(moves - want)
            if off <= (attempt < 250 ? 1 : 3) { return pz }
            if best == nil || off < best!.1 { best = (pz, off) }
        }
        return best?.0 ?? puzzle
    }

    func newPuzzle() {
        gen += 1
        let pz = make()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            puzzle = pz
            program = []
            pos = pz.start
            eaten = pz.apples.contains(pz.start) ? [pz.start] : []
            facingLeft = pz.goal.c < pz.start.c
            running = false; activeCmd = nil; crashAt = nil; showing = false; cheer = false
            hintDir = nil; bubble = nil
            puzzleID += 1
        }
        armHint()
    }

    /// Young players (d < 4) who stall get the next right arrow glowing.
    private func armHint() {
        guard d < 4 else { return }
        let n = program.count
        later(ramp(4, 12, to: 4)) { [unowned self] in
            guard !running, program.count == n else { return }
            // The next step of the answer, if the plan so far matches it.
            let flat = puzzle.answer.flatMap { Array(repeating: $0.dir, count: $0.times) }
            let mine = program.flatMap { Array(repeating: $0.dir, count: $0.times) }
            if mine.count < flat.count && Array(flat.prefix(mine.count)) == mine {
                withAnimation(.easeOut(duration: 0.25)) { hintDir = flat[mine.count] }
            }
        }
    }

    // MARK: Editing the program

    var full: Bool { program.count >= puzzle.slots }

    func add(_ dir: CCDir) {
        guard phase == .playing, !running else { return }
        if puzzle.loops, let last = program.last, last.dir == dir, last.times < 3,
           program.count >= puzzle.slots {
            // A full scroll: a repeated arrow folds into the last step.
            program[program.count - 1].times += 1
        } else {
            guard !full else { Haptics.light(); Sfx.play(.tick); return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { program.append(CCCmd(dir: dir)) }
        }
        hintDir = nil
        Haptics.tap(0.35)
        Sfx.play(.tick)
        armHint()
    }

    /// Tap a step: cycles ×1 → ×2 → ×3 when repeats are on; otherwise removes it.
    func tapStep(_ i: Int) {
        guard phase == .playing, !running, i < program.count else { return }
        if puzzle.loops {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                program[i].times = program[i].times % 3 + 1
            }
            Sfx.play(.pop, volume: 0.6)
        } else {
            _ = withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { program.remove(at: i) }
            Sfx.play(.whoosh, volume: 0.4)
        }
        Haptics.tap(0.3)
    }

    func undo() {
        guard phase == .playing, !running, !program.isEmpty else { return }
        _ = withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { program.removeLast() }
        Sfx.play(.whoosh, volume: 0.4)
        Haptics.tap(0.3)
        armHint()
    }

    /// The route the current plan traces (for the preview line).
    var planTrace: CCTrace { ccRun(puzzle, program) }

    // MARK: Running

    func go() {
        guard phase == .playing, !running, !program.isEmpty else { return }
        run(program, isAnswer: false)
    }

    private func run(_ prog: [CCCmd], isAnswer: Bool) {
        running = true
        hintDir = nil
        let trace = ccRun(puzzle, prog)
        let step = isAnswer ? 0.3 : ramp(0.42, 0.3, to: 6)
        Sfx.play(.whoosh, volume: 0.7)
        for k in 1..<max(1, trace.path.count) {
            let p = trace.path[k], prevP = trace.path[k - 1]
            let ci = trace.stepOfCmd[k - 1]
            later(step * Double(k)) { [unowned self] in
                activeCmd = ci
                if p.c != prevP.c { facingLeft = p.c < prevP.c }
                withAnimation(.easeInOut(duration: step * 0.9)) { pos = p }
                if puzzle.apples.contains(p) && !eaten.contains(p) {
                    _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { eaten.insert(p) }
                    Sfx.play(.chomp)
                    Haptics.tap(0.5)
                } else {
                    Sfx.play(.tick, volume: 0.5)
                }
            }
        }
        let endT = step * Double(trace.path.count) + 0.15
        later(endT) { [unowned self] in
            if let c = trace.crash {
                activeCmd = trace.stepOfCmd.last
                withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) { crashAt = c }
                Sfx.play(.thud)
                bubble = "Neigh-ver mind!"
            }
            if isAnswer {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { cheer = true }
                bubble = "That's the way!"
                later(1.3) { [unowned self] in if !dying { newPuzzle() } }
                return
            }
            if trace.won {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { cheer = true }
                bubble = ["Hay-hay!", "Whinny-ner!", "Neigh-ce!", "Gallop-tastic!"].randomElement()!
                Sfx.play(.coin)
                let tidy = program.count <= puzzle.answer.count
                hit(points: tidy ? 2 : 1)
                later(1.4) { [unowned self] in newPuzzle() }
            } else {
                if trace.crash == nil {
                    bubble = eaten.count < puzzle.apples.count && trace.path.last == puzzle.goal
                        ? "I'm still hungry!" : "Where's the flag?"
                }
                let last = miss(delay: 3.5 + 0.3 * Double(puzzle.moves))
                later(1.3) { [unowned self] in showAnswer(final: last) }
            }
        }
    }

    /// After a miss: roll home, put the right program on the scroll, and drive it.
    private func showAnswer(final: Bool) {
        withAnimation(.easeInOut(duration: 0.4)) {
            pos = puzzle.start
            eaten = puzzle.apples.contains(puzzle.start) ? [puzzle.start] : []
            crashAt = nil; activeCmd = nil; bubble = nil
            program = puzzle.answer
            showing = true
            facingLeft = puzzle.goal.c < puzzle.start.c
        }
        later(0.7) { [unowned self] in run(puzzle.answer, isAnswer: true) }
    }

    override func botAct(correct: Bool) {
        guard !running else { return }
        if correct {
            program = puzzle.answer
        } else {
            var wrong = puzzle.answer
            if let i = wrong.indices.randomElement() {
                wrong[i].dir = CCDir(rawValue: (wrong[i].dir.rawValue + 1 + Int.random(in: 0..<3)) % 4)!
            }
            program = wrong
        }
        go()
    }
}

// MARK: - Pictures

/// The arena: blue sky, a ring of stands with a dotted crowd, and raked sand below.
private struct CCBackdrop: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .top) {
                LinearGradient(colors: [Color(hex: 0xe7c48a), Color(hex: 0xd6a964), Color(hex: 0xc9965a)],
                               startPoint: .top, endPoint: .bottom)
                // Rake lines in the sand
                Canvas { ctx, size in
                    var y: CGFloat = h * 0.2
                    var k = 0
                    while y < size.height {
                        var p = Path()
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addCurve(to: CGPoint(x: size.width, y: y + 6),
                                   control1: CGPoint(x: size.width * 0.3, y: y - 8),
                                   control2: CGPoint(x: size.width * 0.7, y: y + 14))
                        ctx.stroke(p, with: .color(.black.opacity(k % 2 == 0 ? 0.05 : 0.03)), lineWidth: 2)
                        y += 26; k += 1
                    }
                }
                // Sky + stands
                VStack(spacing: 0) {
                    LinearGradient(colors: [Color(hex: 0x5fa8e0), Color(hex: 0x9fd0f0)], startPoint: .top, endPoint: .bottom)
                        .frame(height: h * 0.06)
                    CCStands().frame(height: h * 0.13)
                    Rectangle().fill(Color(hex: 0x7a5232)).frame(height: 6)
                }
                .frame(width: w)
            }
        }
    }
}

/// Tiers of the stands with a dotted crowd.
private struct CCStands: View {
    var body: some View {
        Canvas { ctx, size in
            let tiers = 3
            let th = size.height / CGFloat(tiers)
            let colours: [UInt] = [0xe0684f, 0x4fa6cf, 0xf5c542, 0x63b96b, 0xa96fd6, 0xf6ecd4]
            for t in 0..<tiers {
                let y = CGFloat(t) * th
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: th)),
                         with: .color(Color(hex: t % 2 == 0 ? 0xb88a5c : 0xa77a4f)))
                var x: CGFloat = CGFloat(t % 2) * 7 + 4
                var i = t * 3
                while x < size.width {
                    let c = colours[(i * 7 + t) % colours.count]
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y + th * 0.18, width: 10, height: 10)),
                             with: .color(Color(hex: 0xf1c79a)))
                    ctx.fill(Path(roundedRect: CGRect(x: x - 1, y: y + th * 0.18 + 9, width: 12, height: th * 0.5),
                                  cornerRadius: 3), with: .color(Color(hex: c)))
                    x += 15; i += 1
                }
            }
        }
    }
}

/// A hay bale: a rounded golden block with straw lines and a twine band.
private struct CCHay: View {
    let s: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.16)
                .fill(LinearGradient(colors: [Color(hex: 0xf3d36b), Color(hex: 0xc99a2e)], startPoint: .top, endPoint: .bottom))
            VStack(spacing: s * 0.08) {
                ForEach(0..<4, id: \.self) { _ in
                    Capsule().fill(Color(hex: 0xa77a1e).opacity(0.5)).frame(height: s * 0.03)
                }
            }
            .padding(.horizontal, s * 0.1)
            Rectangle().fill(Color(hex: 0x8a4b2a)).frame(width: s * 0.07)
        }
        .frame(width: s * 0.78, height: s * 0.6)
        .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: s * 0.05)
    }
}

/// The chariot: a horse pulling a little two-wheeled cart with a charioteer.
private struct CCChariot: View {
    let s: CGFloat
    let left: Bool
    var bump = false
    var body: some View {
        HStack(alignment: .bottom, spacing: -s * 0.12) {
            // Cart (behind the horse)
            ZStack(alignment: .bottom) {
                CCDriver(s: s * 0.3).offset(y: -s * 0.3)
                CCCartBody().fill(LinearGradient(colors: [Color(hex: 0xe0684f), Color(hex: 0x9c3a26)], startPoint: .top, endPoint: .bottom))
                    .frame(width: s * 0.34, height: s * 0.3).offset(y: -s * 0.08)
                CCWheel().frame(width: s * 0.3, height: s * 0.3).offset(x: -s * 0.02, y: s * 0.02)
            }
            .frame(width: s * 0.36, height: s * 0.62, alignment: .bottom)
            Text("🐎").font(.system(size: s * 0.6))
                .scaleEffect(x: -1, y: 1)            // the emoji faces left; flip to face the cart's way
        }
        .scaleEffect(x: left ? -1 : 1, y: 1)
        .rotationEffect(.degrees(bump ? -10 : 0))
    }
}

/// The charioteer: a round face in a bronze helmet with a red crest.
private struct CCDriver: View {
    let s: CGFloat
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xf1c79a)).frame(width: s * 0.8).offset(y: s * 0.1)
            Circle().fill(Color(hex: 0x2a1a10)).frame(width: s * 0.1).offset(x: s * 0.16, y: s * 0.12)
            Capsule().fill(Color(hex: 0x8a2a1a)).frame(width: s * 0.2, height: s * 0.06).offset(x: s * 0.12, y: s * 0.3)
            Circle().trim(from: 0.5, to: 1).fill(Color(hex: 0xd9a84a)).frame(width: s * 0.9).offset(y: s * 0.02)
            Capsule().fill(Color(hex: 0xd0402a)).frame(width: s * 0.7, height: s * 0.22).offset(y: -s * 0.42)
        }
        .frame(width: s, height: s)
    }
}

private struct CCCartBody: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY * 0.75 + r.minY * 0.25), control: CGPoint(x: r.maxX * 0.95, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct CCWheel: View {
    var body: some View {
        GeometryReader { g in
            let s = g.size.width
            ZStack {
                Circle().stroke(Color(hex: 0x4a2a14), lineWidth: s * 0.14)
                ForEach(0..<4, id: \.self) { i in
                    Capsule().fill(Color(hex: 0x6a3a1c)).frame(width: s * 0.08, height: s * 0.86)
                        .rotationEffect(.degrees(Double(i) * 45))
                }
                Circle().fill(Color(hex: Lu.gold)).frame(width: s * 0.22)
            }
        }
    }
}

/// The finish post: a chequered flag on a pole, ringed by a laurel.
private struct CCFlag: View {
    let s: CGFloat
    var wave = false
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: Lu.gold).opacity(0.28)).frame(width: s * 0.84)
            Image(systemName: "laurel.leading").font(.system(size: s * 0.42, weight: .bold))
                .foregroundStyle(Color(hex: 0x4e8a3a)).offset(x: -s * 0.2, y: s * 0.06)
            Image(systemName: "laurel.trailing").font(.system(size: s * 0.42, weight: .bold))
                .foregroundStyle(Color(hex: 0x4e8a3a)).offset(x: s * 0.2, y: s * 0.06)
            Text("🏁").font(.system(size: s * 0.46)).rotationEffect(.degrees(wave ? -8 : 4))
        }
    }
}

// MARK: - View

struct ChariotCodeView: View {
    let onClose: () -> Void
    @StateObject private var model = ChariotModel()
    @State private var wave = false

    var body: some View {
        ArcadeShell(model: model,
                    spec: GameID.chariotCode.spec ?? GameSpec(title: "Chariot Code", mechanic: "", premise: "", game: .chariotCode),
                    accent: Lu.coral, onClose: onClose,
                    backdrop: { CCBackdrop() }) {
            VStack(spacing: 10) {
                HUDSpace(60)
                GeometryReader { geo in arena(geo.size) }
                scroll
                pad
            }
            .padding(.horizontal, 12).padding(.bottom, 8)
        }
        .onAppear { withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { wave = true } }
    }

    // MARK: Arena

    private func arena(_ size: CGSize) -> some View {
        let pz = model.puzzle
        let gap: CGFloat = 4
        let cs = min(104, (size.width - gap * CGFloat(pz.cols - 1)) / CGFloat(pz.cols),
                     (size.height - gap * CGFloat(pz.rows - 1)) / CGFloat(pz.rows))
        let gw = cs * CGFloat(pz.cols) + gap * CGFloat(pz.cols - 1)
        let gh = cs * CGFloat(pz.rows) + gap * CGFloat(pz.rows - 1)
        func centre(_ p: CCPos) -> CGPoint {
            CGPoint(x: CGFloat(p.c) * (cs + gap) + cs / 2, y: CGFloat(p.r) * (cs + gap) + cs / 2)
        }
        let trace = model.planTrace
        return ZStack(alignment: .topLeading) {
            // Track squares
            ForEach(0..<pz.rows, id: \.self) { r in
                ForEach(0..<pz.cols, id: \.self) { c in
                    RoundedRectangle(cornerRadius: cs * 0.14)
                        .fill(Color(hex: (r + c) % 2 == 0 ? 0xf0d59c : 0xe6c78a))
                        .overlay(RoundedRectangle(cornerRadius: cs * 0.14).stroke(Color(hex: 0xb98c52).opacity(0.6), lineWidth: 1.5))
                        .frame(width: cs, height: cs)
                        .position(centre(CCPos(r: r, c: c)))
                }
            }
            // Planned route (preview) — or the answer being shown
            if (pz.preview || model.showing) && !model.program.isEmpty && !model.running {
                Path { p in
                    p.move(to: centre(trace.path[0]))
                    for q in trace.path.dropFirst() { p.addLine(to: centre(q)) }
                    if let c = trace.crash {
                        let a = centre(trace.path.last!), b = centre(c)
                        p.addLine(to: CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2))
                    }
                }
                .stroke(Color(hex: 0x7a3e1c).opacity(0.55), style: StrokeStyle(lineWidth: cs * 0.1, lineCap: .round, lineJoin: .round, dash: [cs * 0.02, cs * 0.2]))
            }
            // Things
            ForEach(0..<pz.rows, id: \.self) { r in
                ForEach(0..<pz.cols, id: \.self) { c in
                    let p = CCPos(r: r, c: c)
                    thing(pz.cells[r][c], at: p, cs: cs)
                        .position(centre(p))
                }
            }
            CCFlag(s: cs, wave: wave).position(centre(pz.goal))
            if let c = model.crashAt, pz.inside(c) {
                Text("💥").font(.system(size: cs * 0.5)).position(centre(c))
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
            }
            CCChariot(s: cs, left: model.facingLeft, bump: model.crashAt != nil)
                .position(centre(model.pos))
                .shadow(color: .black.opacity(0.25), radius: 2, y: 2)
            if let b = model.bubble {
                Text(b).font(luFont(15, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(.white).shadow(color: .black.opacity(0.2), radius: 3, y: 2))
                    .fixedSize()
                    .position(x: min(max(centre(model.pos).x, 70), gw - 70), y: max(14, centre(model.pos).y - cs * 0.62))
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            }
            if model.cheer {
                Text("🎉").font(.system(size: cs * 0.6)).position(x: min(gw - cs * 0.3, centre(pz.goal).x + cs * 0.55), y: centre(pz.goal).y + cs * 0.1)
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
            }
        }
        .frame(width: gw, height: gh)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0x8a5a32))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: 0x5e3a1e), lineWidth: 3)))
        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        .id(model.puzzleID)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
        .frame(width: size.width, height: size.height)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: model.bubble)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: model.crashAt)
    }

    @ViewBuilder private func thing(_ t: CCThing, at p: CCPos, cs: CGFloat) -> some View {
        switch t {
        case .hay: CCHay(s: cs)
        case .jar: Text("🏺").font(.system(size: cs * 0.6))
        case .lion:
            ZStack(alignment: .topTrailing) {
                Text("🦁").font(.system(size: cs * 0.56))
                Text("💤").font(.system(size: cs * 0.26)).offset(x: cs * 0.1, y: -cs * 0.12)
            }
        case .apple:
            if !model.eaten.contains(p) {
                Text("🍎").font(.system(size: cs * 0.5)).transition(.scale(scale: 0.1).combined(with: .opacity))
            }
        case .empty: EmptyView()
        }
    }

    // MARK: The program scroll

    private var scroll: some View {
        let pz = model.puzzle
        return VStack(spacing: 4) {
            HStack(spacing: 6) {
                ForEach(0..<pz.slots, id: \.self) { i in
                    slot(i)
                }
            }
            .frame(maxWidth: .infinity)
            if pz.loops && !model.running {
                Text("Tap a step to repeat it ×2, ×3")
                    .font(luFont(13, .heavy)).foregroundStyle(Color(hex: 0x5a3414))
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 9)
        .background(CCScrollShape().fill(LinearGradient(colors: [Color(hex: 0xf7e7c0), Color(hex: 0xe8cf98)], startPoint: .top, endPoint: .bottom))
            .overlay(CCScrollShape().stroke(Color(hex: 0xa77a44), lineWidth: 2)))
        .overlay(alignment: .topTrailing) {
            if model.showing {
                Text("THE RIGHT WAY").font(luFont(10, .heavy)).tracking(1.2)
                    .foregroundStyle(.white).padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Color(hex: 0x4e8a3a))).offset(x: -10, y: -9)
            }
        }
    }

    private func slot(_ i: Int) -> some View {
        let cmd = i < model.program.count ? model.program[i] : nil
        let active = model.activeCmd == i && model.running
        let side: CGFloat = model.puzzle.slots > 6 ? 38 : 44
        return Button { model.tapStep(i) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(cmd == nil ? Color(hex: 0xd9bd84).opacity(0.5)
                          : Color(hex: model.showing ? 0x4e8a3a : (active ? Lu.gold : 0x8a4b2a)))
                    .overlay(RoundedRectangle(cornerRadius: 9)
                        .stroke(Color(hex: 0x8a6a3a).opacity(cmd == nil ? 0.5 : 0), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                if let c = cmd {
                    Image(systemName: c.dir.arrow).font(.system(size: side * 0.48, weight: .black))
                        .foregroundStyle(Color(hex: active ? Lu.inkDark : 0xfff4dc))
                    if c.times > 1 {
                        Text("×\(c.times)").font(luFont(13, .black)).foregroundStyle(Color(hex: Lu.inkDark))
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Capsule().fill(Color(hex: Lu.gold)))
                            .offset(x: side * 0.34, y: -side * 0.38)
                    }
                }
            }
            .frame(width: side, height: side)
            .scaleEffect(active ? 1.12 : 1)
        }
        .buttonStyle(.plain)
        .disabled(cmd == nil)
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: active)
    }

    // MARK: Arrow pad + GO

    private var pad: some View {
        HStack(spacing: 8) {
            ForEach([CCDir.left, .up, .down, .right], id: \.self) { d in
                CCArrowKey(dir: d, glow: model.hintDir == d,
                           enabled: !model.running && (!model.full || model.puzzle.loops)) { model.add(d) }
            }
            Button { model.undo() } label: {
                Image(systemName: "delete.left.fill").font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: 0xfff4dc))
                    .frame(width: 48, height: 64)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0x6a4a3a)))
            }
            .buttonStyle(.plain)
            .disabled(model.running || model.program.isEmpty)
            .opacity(model.running || model.program.isEmpty ? 0.45 : 1)
            Button { model.go() } label: {
                VStack(spacing: 0) {
                    Text("🏇").font(.system(size: 26))
                    Text("GO").font(luFont(20)).foregroundStyle(Color(hex: Lu.inkDark))
                }
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [Color(hex: 0x8fd987), Color(hex: Lu.mint)], startPoint: .top, endPoint: .bottom)))
                .background(RoundedRectangle(cornerRadius: 16).fill(luShade(Lu.mint, -70)).offset(y: 4))
            }
            .buttonStyle(.plain)
            .disabled(model.running || model.program.isEmpty)
            .opacity(model.running || model.program.isEmpty ? 0.5 : 1)
        }
    }
}

private struct CCArrowKey: View {
    let dir: CCDir
    let glow: Bool
    let enabled: Bool
    let action: () -> Void
    @State private var pulse = false
    var body: some View {
        Button(action: action) {
            Image(systemName: dir.arrow).font(.system(size: 26, weight: .black))
                .foregroundStyle(Color(hex: 0xfff4dc))
                .frame(width: 54, height: 64)
                .background(RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [Color(hex: 0xb0643a), Color(hex: 0x8a4b2a)], startPoint: .top, endPoint: .bottom)))
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0x4a2a14)).offset(y: 4))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: Lu.gold), lineWidth: glow ? 4 : 0)
                    .scaleEffect(glow && pulse ? 1.08 : 1))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
        .onAppear { withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { pulse = true } }
    }
}

/// A parchment scroll: a rounded strip with curled ends.
private struct CCScrollShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path(roundedRect: r.insetBy(dx: 6, dy: 0), cornerRadius: 8)
        p.addRoundedRect(in: CGRect(x: r.minX, y: r.minY + 2, width: 12, height: r.height - 4), cornerSize: CGSize(width: 6, height: 6))
        p.addRoundedRect(in: CGRect(x: r.maxX - 12, y: r.minY + 2, width: 12, height: r.height - 4), cornerSize: CGSize(width: 6, height: 6))
        return p
    }
}
