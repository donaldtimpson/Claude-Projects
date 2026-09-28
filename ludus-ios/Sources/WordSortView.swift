import SwiftUI

// MARK: - Ludus mini-game: "Word Sort"
//
// A falling-item lane-sorter that teaches parts of speech. A word tile drifts down from
// the top; the player sends it to the correct bin — LEFT = NOUN, RIGHT = VERB — by
// tapping that bin (primary input) or swiping the tile toward it. Correct sorts bank
// points with a combo multiplier; a wrong bin, or a tile that reaches the floor
// unsorted, costs a heart. Three hearts, game over at zero. The fall speeds up as the
// score climbs. Shares the Ludus theme/economy with the other games.

// MARK: - Model

private enum WSCategory {
    case noun, verb
}

private struct WSWord {
    let text: String
    let category: WSCategory
}

private let wsBank: [WSWord] = [
    // Nouns
    WSWord(text: "dog", category: .noun),
    WSWord(text: "table", category: .noun),
    WSWord(text: "river", category: .noun),
    WSWord(text: "mountain", category: .noun),
    WSWord(text: "teacher", category: .noun),
    WSWord(text: "apple", category: .noun),
    WSWord(text: "garden", category: .noun),
    WSWord(text: "bridge", category: .noun),
    WSWord(text: "forest", category: .noun),
    WSWord(text: "painter", category: .noun),
    WSWord(text: "castle", category: .noun),
    WSWord(text: "island", category: .noun),
    WSWord(text: "wagon", category: .noun),
    WSWord(text: "lantern", category: .noun),
    WSWord(text: "harbor", category: .noun),
    WSWord(text: "meadow", category: .noun),
    WSWord(text: "farmer", category: .noun),
    WSWord(text: "kitten", category: .noun),
    WSWord(text: "window", category: .noun),
    WSWord(text: "candle", category: .noun),
    // Verbs
    WSWord(text: "run", category: .verb),
    WSWord(text: "jump", category: .verb),
    WSWord(text: "sing", category: .verb),
    WSWord(text: "laugh", category: .verb),
    WSWord(text: "write", category: .verb),
    WSWord(text: "throw", category: .verb),
    WSWord(text: "dream", category: .verb),
    WSWord(text: "whistle", category: .verb),
    WSWord(text: "sail", category: .verb),
    WSWord(text: "climb", category: .verb),
    WSWord(text: "swim", category: .verb),
    WSWord(text: "gallop", category: .verb),
    WSWord(text: "shout", category: .verb),
    WSWord(text: "wander", category: .verb),
    WSWord(text: "sparkle", category: .verb),
    WSWord(text: "gather", category: .verb),
    WSWord(text: "stumble", category: .verb),
    WSWord(text: "cheer", category: .verb),
    WSWord(text: "paint", category: .verb),
    WSWord(text: "listen", category: .verb),
]

/// A word currently in play — falling, or animating into a bin.
private struct WSTile: Identifiable {
    let id = UUID()
    let word: WSWord
    var progress: CGFloat        // 0 at top, 1 at floor
    var landing: WSCategory?     // non-nil once sent to a bin (animating out)
    var landAnim: CGFloat = 0    // 0→1 during the fly-to-bin animation
    var correct: Bool = false
}

private struct WSParticle: Identifiable {
    let id = UUID()
    var x: CGFloat; var y: CGFloat
    var vx: CGFloat; var vy: CGFloat
    var life: CGFloat
    var r: CGFloat
    var hex: UInt
}

private struct WSFloater: Identifiable {
    let id = UUID()
    var x: CGFloat; var y: CGFloat
    var text: String
    var life: CGFloat
    var hex: UInt
}

// MARK: - Engine

@MainActor
private final class WSEngine: ObservableObject {
    enum Phase { case playing, over }

    // Coarse state driving the SwiftUI views.
    @Published var phase: Phase = .playing
    @Published var score = 0
    @Published var den = 0
    @Published var hearts = 3
    @Published var combo = 0
    @Published var tiles: [WSTile] = []
    @Published var particles: [WSParticle] = []
    @Published var floaters: [WSFloater] = []
    @Published var flash: CGFloat = 0        // red damage flash 1→0

    // Run summary (published on game over).
    @Published var best = 0
    @Published var lastScore = 0
    @Published var lastDen = 0
    @Published var newBest = false

    private let gameKey = "wordSort"

    private var size: CGSize = .zero
    private var lastTick: Date?
    private var running = false
    private var lastWord: String? = nil

    // Fall geometry: a tile falls through the play field above the bins.
    private var binTop: CGFloat { size.height * 0.72 }
    private var tileTop: CGFloat { size.height * 0.22 }

    init() {
        best = LudusStore.best(gameKey)
    }

    // Fall duration (seconds) for one tile, shrinking as the score climbs.
    private func fallDuration() -> Double {
        max(3.8, 9.5 - Double(score) * 0.10)
    }

    func start() {
        tiles.removeAll(); particles.removeAll(); floaters.removeAll()
        score = 0; den = 0; hearts = 3; combo = 0
        flash = 0; lastTick = nil; lastWord = nil
        newBest = false
        phase = .playing
        running = true
        Haptics.prime()
    }

    private func nextWord() -> WSWord {
        var w = wsBank.randomElement()!
        while w.text == lastWord && wsBank.count > 1 {
            w = wsBank.randomElement()!
        }
        lastWord = w.text
        return w
    }

    private func spawn() {
        tiles.append(WSTile(word: nextWord(), progress: 0))
    }

    /// Advance the simulation. Returns tile count so it can be used as `let _ = ...`
    /// inside a ViewBuilder.
    @discardableResult
    func advance(to date: Date, size: CGSize) -> Int {
        self.size = size
        guard let prev = lastTick else { lastTick = date; return tiles.count }
        lastTick = date
        var dt = date.timeIntervalSince(prev)
        if dt < 0 { dt = 0 }
        if dt > 0.05 { dt = 0.05 }

        if running {
            // Keep at least one live (non-landing) tile in play, at most 2 total.
            let liveCount = tiles.filter { $0.landing == nil }.count
            if liveCount == 0 && tiles.count < 2 {
                spawn()
            } else if liveCount == 1 && tiles.count < 2 {
                // Stagger a second tile only once the first is partway down.
                if let lead = tiles.first(where: { $0.landing == nil }), lead.progress > 0.55 {
                    spawn()
                }
            }

            let step = CGFloat(dt / fallDuration())
            for i in tiles.indices {
                if tiles[i].landing == nil {
                    tiles[i].progress += step
                    if tiles[i].progress >= 1 {
                        // Reached the floor unsorted — a miss.
                        tiles[i].progress = 1
                        missTile(at: i)
                        break
                    }
                } else {
                    tiles[i].landAnim += CGFloat(dt) * 4
                }
            }
            tiles.removeAll { $0.landing != nil && $0.landAnim >= 1 }
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
            floaters[i].life -= CGFloat(dt) * 1.25
            floaters[i].y -= CGFloat(46 * dt)
            if floaters[i].life <= 0 { floaters.remove(at: i) }
        }
        if flash > 0 { flash = max(0, flash - CGFloat(dt) * 2.6) }
        return tiles.count
    }

    /// The on-screen center of a live tile, for particle/floater anchoring.
    func tileCenter(_ t: WSTile) -> CGPoint {
        let y = tileTop + (binTop - tileTop) * t.progress
        return CGPoint(x: size.width / 2, y: y)
    }

    // MARK: Input — the player taps a bin.

    func chooseBin(_ cat: WSCategory) {
        guard running else { return }
        // Act on the lowest live tile (closest to the floor).
        guard let idx = tiles.enumerated()
            .filter({ $0.element.landing == nil })
            .max(by: { $0.element.progress < $1.element.progress })?.offset
        else { return }

        let t = tiles[idx]
        let center = tileCenter(t)
        let correct = (t.word.category == cat)

        tiles[idx].landing = cat
        tiles[idx].correct = correct
        tiles[idx].landAnim = 0.001

        if correct {
            combo += 1
            let pts = 1 + max(0, combo - 1)   // combo multiplier for streaks
            score += pts
            den += pts
            let hex = cat == .noun ? Lu.sky : Lu.mint
            burst(center.x, center.y, hex, 14)
            floaters.append(WSFloater(x: center.x, y: center.y - 30, text: "+\(pts)", life: 1, hex: Lu.gold))
            Haptics.tap(min(1.0, 0.55 + Double(combo) * 0.06))
        } else {
            damage(at: center, label: "WRONG!")
        }
    }

    private func missTile(at index: Int) {
        guard tiles.indices.contains(index) else { return }
        let t = tiles[index]
        let center = tileCenter(t)
        // Remove the escaped tile and take the hit.
        tiles.remove(at: index)
        damage(at: center, label: "MISSED!")
    }

    private func damage(at center: CGPoint, label: String) {
        combo = 0
        hearts -= 1
        flash = 1
        burst(center.x, center.y, Lu.coral, 10)
        floaters.append(WSFloater(x: center.x, y: center.y - 30, text: label, life: 1, hex: Lu.coral))
        Haptics.error()
        if hearts <= 0 { gameOver() }
    }

    private func burst(_ x: CGFloat, _ y: CGFloat, _ hex: UInt, _ n: Int) {
        for _ in 0..<n {
            let a = Double.random(in: 0..<(2 * .pi))
            let sp = Double.random(in: 70...260)
            particles.append(WSParticle(
                x: x, y: y,
                vx: CGFloat(cos(a) * sp), vy: CGFloat(sin(a) * sp - 50),
                life: 1, r: CGFloat.random(in: 3...7), hex: hex
            ))
        }
    }

    private func gameOver() {
        guard running else { return }
        running = false
        let s = score
        let d = den
        LudusStore.award(d)
        let isBest = LudusStore.recordBest(gameKey, s)
        Haptics.error()
        // Flip published UI state outside the current view-update pass.
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

struct WordSortView: View {
    let onClose: () -> Void
    @StateObject private var game = WSEngine()

    // Drive the fall from a timer (fires OUTSIDE the view-render pass) so mutating the
    // engine's @Published state is safe and actually repaints. Advancing inside a
    // TimelineView body silently froze the tile.
    private let ticker = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LudusBackground().ignoresSafeArea()

                WSPlayfield(game: game, size: geo.size)

                // Damage flash.
                if game.flash > 0 {
                    Color(hex: Lu.coral)
                        .opacity(Double(game.flash) * 0.28)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                // Bins overlay (bottom).
                VStack {
                    Spacer()
                    WSBins(game: game)
                }
                .ignoresSafeArea(.container, edges: .bottom)

                // HUD (top, respects safe area).
                VStack {
                    HStack(alignment: .top, spacing: 8) {
                        LudusCloseButton(action: onClose)
                        StatPill(label: "SCORE", value: "\(game.score)", valueHex: Lu.gold)
                        Spacer(minLength: 4)
                        WSHearts(hearts: game.hearts)
                        Spacer(minLength: 4)
                        StatPill(label: "DENARII", value: "\(game.den)", valueHex: Lu.silver)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)

                // Combo flourish.
                if game.combo >= 2 && game.phase == .playing {
                    Text("COMBO ×\(game.combo)!")
                        .font(luFont(26))
                        .foregroundStyle(Color(hex: Lu.mint))
                        .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 3)
                        .padding(.top, 130)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .id(game.combo)
                        .transition(.scale(scale: 1.25).combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: game.combo)
                        .allowsHitTesting(false)
                }

                if game.phase == .over {
                    WSGameOver(game: game, onAgain: { game.start() }, onClose: onClose)
                        .transition(.opacity)
                }
            }
            .onReceive(ticker) { _ in game.advance(to: Date(), size: geo.size) }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onAppear { game.start() }
    }
}

// MARK: - Playfield (falling tiles, particles, floaters)

private struct WSPlayfield: View {
    @ObservedObject var game: WSEngine
    let size: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Hint header.
            Text("Sort the word into NOUN or VERB")
                .font(luFont(13, .heavy))
                .tracking(1)
                .foregroundStyle(Color(hex: Lu.inkDim).opacity(0.85))
                .frame(width: size.width)
                .position(x: size.width / 2, y: size.height * 0.135)

            // Falling / landing tiles.
            ForEach(game.tiles) { tile in
                WSTileCard(word: tile.word.text)
                    .position(tilePosition(tile))
                    .scaleEffect(tile.landing != nil ? max(0.2, 1 - tile.landAnim) : 1)
                    .opacity(tile.landing != nil ? Double(max(0, 1 - tile.landAnim)) : 1)
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
                    .font(luFont(24))
                    .foregroundStyle(Color(hex: f.hex))
                    .opacity(Double(max(0, f.life)))
                    .position(x: f.x, y: f.y)
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }

    private func tilePosition(_ tile: WSTile) -> CGPoint {
        let center = game.tileCenter(tile)
        guard let landing = tile.landing else { return center }
        // Fly toward the chosen bin.
        let targetX = landing == .noun ? size.width * 0.25 : size.width * 0.75
        let targetY = size.height * 0.82
        let a = tile.landAnim
        return CGPoint(
            x: center.x + (targetX - center.x) * a,
            y: center.y + (targetY - center.y) * a
        )
    }
}

private struct WSTileCard: View {
    let word: String
    var body: some View {
        Text(word)
            .font(luFont(34))
            .foregroundStyle(Color(hex: Lu.inkDark))
            .padding(.horizontal, 26)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: [.white, Color(hex: Lu.silver)],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(hex: Lu.grape).opacity(0.55), lineWidth: 3))
                    .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 8)
            )
    }
}

// MARK: - Bins

private struct WSBins: View {
    @ObservedObject var game: WSEngine

    var body: some View {
        HStack(spacing: 12) {
            WSBinButton(title: "NOUN", tint: Lu.sky) { game.chooseBin(.noun) }
            WSBinButton(title: "VERB", tint: Lu.mint) { game.chooseBin(.verb) }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 30)
    }
}

private struct WSBinButton: View {
    let title: String
    let tint: UInt
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(Color(hex: Lu.inkDark).opacity(0.75))
                Text(title)
                    .font(luFont(28))
                    .foregroundStyle(Color(hex: Lu.inkDark))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 26)
            .background(
                ZStack {
                    luPanelShape(24)
                    RoundedRectangle(cornerRadius: 24)
                        .fill(LinearGradient(colors: [Color(hex: tint), luShade(tint, -40)],
                                             startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.4), lineWidth: 2))
                }
            )
            .shadow(color: luShade(tint, -70).opacity(0.7), radius: 0, x: 0, y: 6)
        }
        .buttonStyle(WSPressStyle())
    }
}

/// A little squish on press so a bin tap feels physical.
private struct WSPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Hearts

private struct WSHearts: View {
    let hearts: Int
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < hearts ? "heart.fill" : "heart")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(hex: i < hearts ? Lu.coral : Lu.line))
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(luPanelShape(14))
    }
}

// MARK: - Game over

private struct WSGameOver: View {
    @ObservedObject var game: WSEngine
    let onAgain: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            VStack(spacing: 10) {
                Text("WORD SORT")
                    .font(luFont(12, .heavy))
                    .tracking(3)
                    .foregroundStyle(Color(hex: Lu.grape))
                Text("Game Over")
                    .font(luFont(52))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, Color(hex: Lu.gold), Color(hex: Lu.coral)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                if game.newBest {
                    Text("★ NEW BEST! ★")
                        .font(luFont(15))
                        .foregroundStyle(Color(hex: Lu.mint))
                }
                HStack(spacing: 12) {
                    WSResultCard(label: "SCORE", value: "\(game.lastScore)", hex: Lu.gold)
                    WSResultCard(label: "BEST", value: "\(game.best)", hex: Lu.mint)
                    WSResultCard(label: "DENARII WON", value: "\(game.lastDen)", hex: Lu.silver)
                }
                .padding(.top, 4)

                LudusButton(title: "PLAY AGAIN", action: onAgain)
                    .padding(.top, 12)
                Button("Done", action: onClose)
                    .font(luFont(15, .bold))
                    .foregroundStyle(Color(hex: Lu.inkDim))
                    .padding(.top, 4)
            }
            .padding(28)
        }
    }
}

private struct WSResultCard: View {
    let label: String
    let value: String
    let hex: UInt
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(luFont(10, .heavy))
                .tracking(1.2)
                .foregroundStyle(Color(hex: Lu.inkDim))
            Text(value)
                .font(luFont(30))
                .monospacedDigit()
                .foregroundStyle(Color(hex: hex))
        }
        .frame(minWidth: 92)
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(luPanelShape(16))
    }
}
