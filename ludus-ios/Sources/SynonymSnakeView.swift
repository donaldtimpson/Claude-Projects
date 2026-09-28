import SwiftUI

// MARK: - Ludus mini-game: "Synonym Snake"
//
// A gentle grid snake that teaches synonyms. A target word is shown at the top, e.g.
// "Eat the words that mean HAPPY". The snake crawls across a chunky ~9-column grid; the
// player steers it by SWIPING up/down/left/right. Food tiles each show a word — some are
// synonyms of the target (eat them: +points, the snake grows, the combo climbs), some are
// unrelated distractors (eating one costs a heart). Running into a wall or your own tail
// also costs a heart. Three hearts, game over at zero. Every so often the target rotates
// to a fresh word. Deliberately SLOW and forgiving — this is for a 7–9 year old.
//
// ARCHITECTURE: movement is driven by a Timer.publish tick delivered via .onReceive
// (fires OUTSIDE the view-render pass), NOT by mutating state inside a TimelineView /
// Canvas body. All UI is plain SwiftUI (RoundedRectangles + Text in a ZStack, positioned
// by grid cell). The engine is a @MainActor ObservableObject with coarse @Published state.

// MARK: - Word bank

private struct SSTargetWord {
    let target: String
    let synonyms: [String]
    let distractors: [String]
}

private let ssBank: [SSTargetWord] = [
    SSTargetWord(target: "HAPPY", synonyms: ["glad", "joyful", "merry", "cheery"],
                 distractors: ["sad", "angry", "tired", "grumpy"]),
    SSTargetWord(target: "BIG", synonyms: ["large", "huge", "giant", "great"],
                 distractors: ["tiny", "small", "little", "short"]),
    SSTargetWord(target: "FAST", synonyms: ["quick", "rapid", "swift", "speedy"],
                 distractors: ["slow", "lazy", "still", "calm"]),
    SSTargetWord(target: "SMART", synonyms: ["clever", "wise", "bright", "sharp"],
                 distractors: ["silly", "dull", "foolish", "slow"]),
    SSTargetWord(target: "COLD", synonyms: ["chilly", "icy", "frosty", "cool"],
                 distractors: ["hot", "warm", "sunny", "toasty"]),
    SSTargetWord(target: "PRETTY", synonyms: ["lovely", "cute", "fair", "sweet"],
                 distractors: ["ugly", "plain", "dirty", "messy"]),
    SSTargetWord(target: "SCARED", synonyms: ["afraid", "fearful", "nervous", "jumpy"],
                 distractors: ["brave", "calm", "bold", "eager"]),
    SSTargetWord(target: "LOUD", synonyms: ["noisy", "blaring", "booming", "roaring"],
                 distractors: ["quiet", "silent", "soft", "hushed"]),
]

// MARK: - Model

private struct SSCell: Equatable {
    var col: Int
    var row: Int
}

private enum SSDir {
    case up, down, left, right

    var delta: (Int, Int) {
        switch self {
        case .up:    return (0, -1)
        case .down:  return (0, 1)
        case .left:  return (-1, 0)
        case .right: return (1, 0)
        }
    }

    /// True if `other` is the exact reverse — a 180° turn the snake can't make.
    func isOpposite(_ other: SSDir) -> Bool {
        switch (self, other) {
        case (.up, .down), (.down, .up), (.left, .right), (.right, .left): return true
        default: return false
        }
    }
}

private struct SSFood: Identifiable, Equatable {
    let id = UUID()
    var cell: SSCell
    var word: String
    var isSynonym: Bool

    static func == (l: SSFood, r: SSFood) -> Bool { l.id == r.id }
}

private struct SSParticle: Identifiable {
    let id = UUID()
    var x: CGFloat; var y: CGFloat
    var vx: CGFloat; var vy: CGFloat
    var life: CGFloat
    var r: CGFloat
    var hex: UInt
}

private struct SSFloater: Identifiable {
    let id = UUID()
    var x: CGFloat; var y: CGFloat
    var text: String
    var life: CGFloat
    var hex: UInt
}

// MARK: - Engine

@MainActor
private final class SSEngine: ObservableObject {
    enum Phase { case playing, over }

    // Grid geometry. Chunky and square-ish for small hands.
    let cols = 9
    let rows = 11

    // Coarse state driving the SwiftUI views.
    @Published var phase: Phase = .playing
    @Published var score = 0
    @Published var den = 0
    @Published var hearts = 3
    @Published var combo = 0
    @Published var snake: [SSCell] = []
    @Published var foods: [SSFood] = []
    @Published var dir: SSDir = .right
    @Published var target = "HAPPY"
    @Published var particles: [SSParticle] = []
    @Published var floaters: [SSFloater] = []
    @Published var flash: CGFloat = 0        // red damage flash 1→0

    // Run summary (published on game over).
    @Published var best = 0
    @Published var lastScore = 0
    @Published var lastDen = 0
    @Published var newBest = false

    private let gameKey = "synonymSnake"

    // Layout supplied by the view each tick, used for particle/floater math.
    private var boardOrigin: CGPoint = .zero
    private var cellSize: CGFloat = 40

    private var running = false
    private var queuedDir: SSDir? = nil          // next turn buffered from a swipe
    private var currentWord: SSTargetWord = ssBank[0]
    private var eatenThisTarget = 0              // synonyms eaten toward a target rotation

    // Movement clock: slow & forgiving. Accumulate real time and step on a fixed cadence.
    private var moveAccum: Double = 0
    private var lastTick: Date?

    /// Seconds per grid step. Starts slow; nudges only slightly faster with score.
    private var stepInterval: Double {
        max(0.30, 0.44 - Double(score) * 0.004)
    }

    init() {
        best = LudusStore.best(gameKey)
    }

    // MARK: Lifecycle

    func start() {
        snake.removeAll(); foods.removeAll(); particles.removeAll(); floaters.removeAll()
        score = 0; den = 0; hearts = 3; combo = 0
        flash = 0; lastTick = nil; moveAccum = 0
        queuedDir = nil; eatenThisTarget = 0
        newBest = false

        // Snake starts in the middle-left, heading right, length 3.
        let midRow = rows / 2
        snake = [SSCell(col: 3, row: midRow),
                 SSCell(col: 2, row: midRow),
                 SSCell(col: 1, row: midRow)]
        dir = .right

        rotateTarget(initial: true)
        phase = .playing
        running = true
        Haptics.prime()
    }

    /// Give the view the board's pixel geometry (top-left origin + cell size).
    func layout(origin: CGPoint, cell: CGFloat) {
        boardOrigin = origin
        cellSize = cell
    }

    // MARK: Target rotation & food

    private func rotateTarget(initial: Bool) {
        var w = ssBank.randomElement()!
        if !initial {
            while w.target == currentWord.target && ssBank.count > 1 {
                w = ssBank.randomElement()!
            }
        }
        currentWord = w
        target = w.target
        eatenThisTarget = 0
        refillFood()
        if !initial {
            floaters.append(SSFloater(x: boardOrigin.x + boardWidth / 2,
                                      y: boardOrigin.y - 6,
                                      text: "NEW WORD!", life: 1.2, hex: Lu.grape))
        }
    }

    private var boardWidth: CGFloat { cellSize * CGFloat(cols) }

    /// Rebuild the food set so there are always at least a couple of reachable synonyms
    /// on the board plus a couple of distractors, none overlapping the snake or each other.
    private func refillFood() {
        foods.removeAll()
        var occupied = Set(snake.map { cellKey($0) })

        func placeWord(_ word: String, isSynonym: Bool) {
            guard let cell = freeCell(excluding: occupied) else { return }
            occupied.insert(cellKey(cell))
            foods.append(SSFood(cell: cell, word: word, isSynonym: isSynonym))
        }

        // 2 synonyms guaranteed on the board, plus 2 distractors.
        let syns = currentWord.synonyms.shuffled()
        let dists = currentWord.distractors.shuffled()
        for w in syns.prefix(2) { placeWord(w, isSynonym: true) }
        for w in dists.prefix(2) { placeWord(w, isSynonym: false) }
    }

    /// Called when a synonym is eaten: spawn a fresh food so the count stays healthy,
    /// keeping the board reachable. Guarantees at least one synonym remains.
    private func topUpFood() {
        var occupied = Set(snake.map { cellKey($0) })
        for f in foods { occupied.insert(cellKey(f.cell)) }

        // Ensure at least one synonym exists.
        let synCount = foods.filter { $0.isSynonym }.count
        if synCount == 0 {
            if let cell = freeCell(excluding: occupied),
               let word = currentWord.synonyms.randomElement() {
                occupied.insert(cellKey(cell))
                foods.append(SSFood(cell: cell, word: word, isSynonym: true))
            }
        }

        // Keep the board populated (up to ~4 tiles) with a mix.
        while foods.count < 4 {
            let makeSyn = Bool.random()
            let word = (makeSyn ? currentWord.synonyms : currentWord.distractors).randomElement()
            guard let word, let cell = freeCell(excluding: occupied) else { break }
            occupied.insert(cellKey(cell))
            foods.append(SSFood(cell: cell, word: word, isSynonym: makeSyn))
        }
    }

    private func cellKey(_ c: SSCell) -> Int { c.row * cols + c.col }

    private func freeCell(excluding occupied: Set<Int>) -> SSCell? {
        var candidates: [SSCell] = []
        for r in 0..<rows {
            for c in 0..<cols {
                let cell = SSCell(col: c, row: r)
                if !occupied.contains(cellKey(cell)) { candidates.append(cell) }
            }
        }
        return candidates.randomElement()
    }

    // MARK: Input — swipe to steer.

    func steer(_ newDir: SSDir) {
        guard running else { return }
        // Ignore a reverse into ourselves; buffer the turn for the next step so quick
        // double-swipes don't fold the snake on itself.
        let ref = queuedDir ?? dir
        if newDir.isOpposite(ref) { return }
        queuedDir = newDir
        Haptics.light()
    }

    // MARK: Tick — advance the movement clock.

    /// Called from the view's Timer .onReceive (outside the render pass). Steps the snake
    /// on a fixed cadence and always animates particles/floaters.
    func tick(now: Date) {
        guard let prev = lastTick else { lastTick = now; return }
        lastTick = now
        var dt = now.timeIntervalSince(prev)
        if dt < 0 { dt = 0 }
        if dt > 0.1 { dt = 0.1 }        // clamp after backgrounding

        if running {
            moveAccum += dt
            while moveAccum >= stepInterval {
                moveAccum -= stepInterval
                step()
                if !running { break }
            }
        }

        // Particles.
        for i in particles.indices.reversed() {
            particles[i].life -= CGFloat(dt) * 1.7
            if particles[i].life <= 0 { particles.remove(at: i); continue }
            particles[i].vy += CGFloat(420 * dt)
            particles[i].x += particles[i].vx * CGFloat(dt)
            particles[i].y += particles[i].vy * CGFloat(dt)
        }
        // Floaters.
        for i in floaters.indices.reversed() {
            floaters[i].life -= CGFloat(dt) * 1.1
            floaters[i].y -= CGFloat(40 * dt)
            if floaters[i].life <= 0 { floaters.remove(at: i) }
        }
        if flash > 0 { flash = max(0, flash - CGFloat(dt) * 2.6) }
    }

    /// One grid move.
    private func step() {
        guard running, let head = snake.first else { return }

        if let q = queuedDir { dir = q; queuedDir = nil }

        let (dc, dr) = dir.delta
        let next = SSCell(col: head.col + dc, row: head.row + dr)

        // Wall.
        if next.col < 0 || next.col >= cols || next.row < 0 || next.row >= rows {
            damage(at: cellCenter(head), label: "OW!")
            return
        }
        // Self (ignore the tail cell, which will move out of the way — but only if we're
        // not also growing this step; simplest & forgiving: check against the whole body
        // minus the very last segment).
        let body = snake.dropLast()
        if body.contains(next) {
            damage(at: cellCenter(head), label: "OOPS!")
            return
        }

        // Did we land on food?
        if let idx = foods.firstIndex(where: { $0.cell == next }) {
            let food = foods[idx]
            if food.isSynonym {
                eatSynonym(food, movingTo: next)
            } else {
                // Wrong word: take the hit, remove the tile, but keep crawling forward.
                foods.remove(at: idx)
                advanceHead(to: next, grow: false)
                damage(at: cellCenter(next), label: "NOT \(target)")
                topUpFood()
            }
            return
        }

        // Plain move.
        advanceHead(to: next, grow: false)
    }

    private func advanceHead(to next: SSCell, grow: Bool) {
        snake.insert(next, at: 0)
        if !grow { snake.removeLast() }
    }

    private func eatSynonym(_ food: SSFood, movingTo next: SSCell) {
        if let idx = foods.firstIndex(of: food) { foods.remove(at: idx) }
        advanceHead(to: next, grow: true)     // snake grows

        combo += 1
        let pts = 1 + max(0, combo - 1)       // combo bonus for streaks
        score += pts
        den += pts
        eatenThisTarget += 1

        let center = cellCenter(next)
        burst(center.x, center.y, Lu.mint, 14)
        floaters.append(SSFloater(x: center.x, y: center.y - cellSize * 0.5,
                                  text: "+\(pts)", life: 1, hex: Lu.gold))
        Haptics.tap(min(1.0, 0.55 + Double(combo) * 0.06))

        topUpFood()

        // Rotate to a new target after a few good catches.
        if eatenThisTarget >= 3 {
            rotateTarget(initial: false)
        }
    }

    private func damage(at center: CGPoint, label: String) {
        combo = 0
        hearts -= 1
        flash = 1
        burst(center.x, center.y, Lu.coral, 12)
        floaters.append(SSFloater(x: center.x, y: center.y - cellSize * 0.5,
                                  text: label, life: 1.1, hex: Lu.coral))
        Haptics.error()
        if hearts <= 0 {
            gameOver()
            return
        }
        // Forgiving reset: recenter the (possibly wall-crashing) snake and re-seed food,
        // so a small child isn't left stuck against a wall.
        respawnSnake()
        moveAccum = 0
        queuedDir = nil
    }

    /// Put the snake back in a safe spot heading right, preserving its length.
    private func respawnSnake() {
        let len = max(3, snake.count)
        let midRow = rows / 2
        var body: [SSCell] = []
        for i in 0..<len {
            body.append(SSCell(col: max(0, 3 - i), row: midRow))
        }
        // Collapse any duplicate leading cells (when len > startCol) onto a short stub.
        snake = Array(body.prefix(min(len, 4)))
        dir = .right
        // Make sure no food sits under the snake head.
        var occupied = Set(snake.map { cellKey($0) })
        foods.removeAll { occupied.contains(cellKey($0.cell)) }
        for f in foods { occupied.insert(cellKey(f.cell)) }
        topUpFood()
    }

    private func burst(_ x: CGFloat, _ y: CGFloat, _ hex: UInt, _ n: Int) {
        for _ in 0..<n {
            let a = Double.random(in: 0..<(2 * .pi))
            let sp = Double.random(in: 70...240)
            particles.append(SSParticle(
                x: x, y: y,
                vx: CGFloat(cos(a) * sp), vy: CGFloat(sin(a) * sp - 50),
                life: 1, r: CGFloat.random(in: 3...7), hex: hex
            ))
        }
    }

    // MARK: Geometry helpers (pixel centers of grid cells)

    func cellCenter(_ c: SSCell) -> CGPoint {
        CGPoint(x: boardOrigin.x + (CGFloat(c.col) + 0.5) * cellSize,
                y: boardOrigin.y + (CGFloat(c.row) + 0.5) * cellSize)
    }

    private func gameOver() {
        guard running else { return }
        running = false
        let s = score
        let d = den
        LudusStore.award(d)
        let isBest = LudusStore.recordBest(gameKey, s)
        Haptics.error()
        // Flip published UI state outside the current update pass, to be safe.
        DispatchQueue.main.async {
            self.lastScore = s
            self.lastDen = d
            self.newBest = isBest
            self.best = LudusStore.best(self.gameKey)
            self.phase = .over
        }
    }
}

// MARK: - Public entry point

struct SynonymSnakeView: View {
    let onClose: () -> Void
    @StateObject private var game = SSEngine()

    // Drive movement from a Timer that fires OUTSIDE the view-render pass, so mutating the
    // engine's @Published state is safe and actually repaints. Advancing inside a
    // TimelineView/Canvas body would silently freeze the snake.
    private let ticker = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    // Swipe accumulator so a single drag registers exactly one steer.
    @State private var swipeHandled = false

    var body: some View {
        GeometryReader { geo in
            // Compute a chunky, square-cell board centered horizontally, below the HUD.
            let layout = SSBoardLayout(size: geo.size, cols: game.cols, rows: game.rows)

            ZStack {
                LudusBackground().ignoresSafeArea()

                // The play board (grid + snake + food + fx).
                SSBoard(game: game, layout: layout)
                    .onAppear { game.layout(origin: layout.origin, cell: layout.cell) }
                    .onChange(of: layout.cell) { _ in
                        game.layout(origin: layout.origin, cell: layout.cell)
                    }

                // Damage flash.
                if game.flash > 0 {
                    Color(hex: Lu.coral)
                        .opacity(Double(game.flash) * 0.28)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                // HUD (top, respects safe area).
                VStack(spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        LudusCloseButton(action: onClose)
                        StatPill(label: "SCORE", value: "\(game.score)", valueHex: Lu.gold)
                        Spacer(minLength: 4)
                        HeartsRow(hearts: game.hearts)
                        Spacer(minLength: 4)
                        StatPill(label: "DENARII", value: "\(game.den)", valueHex: Lu.silver)
                    }
                    SSTargetBanner(target: game.target)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)

                // Combo flourish.
                if game.combo >= 2 && game.phase == .playing {
                    Text("COMBO ×\(game.combo)!")
                        .font(luFont(24))
                        .foregroundStyle(Color(hex: Lu.mint))
                        .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 3)
                        .padding(.top, 150)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .id(game.combo)
                        .transition(.scale(scale: 1.25).combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: game.combo)
                        .allowsHitTesting(false)
                }

                if game.phase == .over {
                    LudusGameOverView(
                        reason: "Out of hearts",
                        score: game.lastScore,
                        best: game.best,
                        denRun: game.lastDen,
                        newBest: game.newBest,
                        onAgain: { game.start() },
                        onClose: onClose
                    )
                    .transition(.opacity)
                }
            }
            // Swipe steering across the whole screen.
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 18)
                    .onChanged { value in
                        guard !swipeHandled else { return }
                        let t = value.translation
                        if max(abs(t.width), abs(t.height)) < 18 { return }
                        swipeHandled = true
                        if abs(t.width) > abs(t.height) {
                            game.steer(t.width > 0 ? .right : .left)
                        } else {
                            game.steer(t.height > 0 ? .down : .up)
                        }
                    }
                    .onEnded { _ in swipeHandled = false }
            )
            .onReceive(ticker) { _ in
                game.layout(origin: layout.origin, cell: layout.cell)
                game.tick(now: Date())
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onAppear { game.start() }
    }
}

// MARK: - Board layout (pixel geometry for the grid)

private struct SSBoardLayout: Equatable {
    let origin: CGPoint     // top-left of the grid
    let cell: CGFloat       // square cell edge

    init(size: CGSize, cols: Int, rows: Int) {
        // Reserve room for the HUD + banner at top and a little breathing room at bottom.
        let topInset: CGFloat = 170
        let bottomInset: CGFloat = 40
        let sideInset: CGFloat = 12

        let availW = max(1, size.width - sideInset * 2)
        let availH = max(1, size.height - topInset - bottomInset)

        let cellW = availW / CGFloat(cols)
        let cellH = availH / CGFloat(rows)
        let c = max(24, min(cellW, cellH))

        let boardW = c * CGFloat(cols)
        let boardH = c * CGFloat(rows)
        let ox = (size.width - boardW) / 2
        let oy = topInset + max(0, (availH - boardH) / 2)

        self.cell = c
        self.origin = CGPoint(x: ox, y: oy)
    }
}

// MARK: - Target banner

private struct SSTargetBanner: View {
    let target: String
    var body: some View {
        VStack(spacing: 2) {
            Text("Eat the words that mean")
                .font(luFont(13, .heavy))
                .tracking(0.5)
                .foregroundStyle(Color(hex: Lu.inkDim))
            Text(target)
                .font(luSerif(30, .black))
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: Lu.gold), Color(hex: Lu.tangerine)],
                                   startPoint: .top, endPoint: .bottom)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(luPanelShape(16))
    }
}

// MARK: - Board (grid + snake + food + fx)

private struct SSBoard: View {
    @ObservedObject var game: SSEngine
    let layout: SSBoardLayout

    private var boardW: CGFloat { layout.cell * CGFloat(game.cols) }
    private var boardH: CGFloat { layout.cell * CGFloat(game.rows) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Board backing panel.
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: Lu.ground2))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(hex: Lu.goldLine).opacity(0.5), lineWidth: 3)
                )
                .frame(width: boardW, height: boardH)
                .position(x: layout.origin.x + boardW / 2,
                          y: layout.origin.y + boardH / 2)

            // Checkerboard cells for a friendly grid feel.
            ForEach(0..<game.rows, id: \.self) { r in
                ForEach(0..<game.cols, id: \.self) { c in
                    let dark = (r + c).isMultiple(of: 2)
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color(hex: dark ? Lu.panel : Lu.panel2).opacity(0.55))
                        .frame(width: layout.cell - 3, height: layout.cell - 3)
                        .position(cellCenter(col: c, row: r))
                }
            }

            // Food tiles (words).
            ForEach(game.foods) { food in
                SSFoodTile(word: food.word,
                           isSynonym: food.isSynonym,
                           edge: layout.cell)
                    .position(game.cellCenter(food.cell))
            }

            // Snake body.
            ForEach(Array(game.snake.enumerated()), id: \.offset) { pair in
                let idx = pair.offset
                let seg = pair.element
                SSSegment(isHead: idx == 0, edge: layout.cell)
                    .position(game.cellCenter(seg))
                    .zIndex(idx == 0 ? 2 : 1)
            }

            // Particles.
            ForEach(game.particles) { p in
                Circle()
                    .fill(Color(hex: p.hex))
                    .frame(width: p.r * 2, height: p.r * 2)
                    .opacity(Double(max(0, p.life)))
                    .position(x: p.x, y: p.y)
            }

            // Floaters.
            ForEach(game.floaters) { f in
                Text(f.text)
                    .font(luFont(18))
                    .foregroundStyle(Color(hex: f.hex))
                    .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 2)
                    .opacity(Double(max(0, f.life)))
                    .position(x: f.x, y: f.y)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    private func cellCenter(col: Int, row: Int) -> CGPoint {
        CGPoint(x: layout.origin.x + (CGFloat(col) + 0.5) * layout.cell,
                y: layout.origin.y + (CGFloat(row) + 0.5) * layout.cell)
    }
}

// MARK: - Snake segment

private struct SSSegment: View {
    let isHead: Bool
    let edge: CGFloat

    var body: some View {
        let inset: CGFloat = edge * 0.12
        let side = edge - inset * 2
        ZStack {
            RoundedRectangle(cornerRadius: side * 0.32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isHead
                            ? [Color(hex: Lu.mint), luShade(Lu.mint, -50)]
                            : [luShade(Lu.mint, -15), luShade(Lu.mint, -60)],
                        startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.32, style: .continuous)
                        .stroke(Color.white.opacity(isHead ? 0.5 : 0.25), lineWidth: 2)
                )
            if isHead {
                // Two little eyes so the head reads as a face.
                HStack(spacing: side * 0.22) {
                    Circle().fill(Color(hex: Lu.inkDark)).frame(width: side * 0.16, height: side * 0.16)
                    Circle().fill(Color(hex: Lu.inkDark)).frame(width: side * 0.16, height: side * 0.16)
                }
                .offset(y: -side * 0.08)
            }
        }
        .frame(width: side, height: side)
    }
}

// MARK: - Food tile

private struct SSFoodTile: View {
    let word: String
    let isSynonym: Bool
    let edge: CGFloat

    var body: some View {
        let inset: CGFloat = edge * 0.06
        let side = edge - inset * 2
        Text(word)
            .font(luFont(min(15, side * 0.34), .black))
            .minimumScaleFactor(0.4)
            .lineLimit(1)
            .foregroundStyle(Color(hex: Lu.inkDark))
            .padding(.horizontal, 4)
            .frame(width: side, height: side)
            .background(
                RoundedRectangle(cornerRadius: side * 0.28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white, Color(hex: Lu.silver)],
                            startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: side * 0.28, style: .continuous)
                            .stroke(Color(hex: isSynonym ? Lu.mint : Lu.line).opacity(0.9),
                                    lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 3)
            )
    }
}
