import SwiftUI

// MARK: - Ludus mini-game: "Critter Sort"
//
// A falling-tile lane-sorter that teaches animal classes. An animal tile (emoji + name)
// drifts down from the top; the player sends it to the correct bin — MAMMAL, BIRD, or
// REPTILE — by tapping that bin. Correct sorts bank points with a combo multiplier; a
// wrong bin, or a tile that reaches the floor unsorted, costs a heart. Three hearts, game
// over at zero. The fall speeds up as the score climbs. Starts slow and gentle so a young
// player can succeed. Shares the Ludus theme/economy with the other games.

// MARK: - Model

private enum CSClass {
    case mammal, bird, reptile
}

private struct CSAnimal {
    let emoji: String
    let name: String
    let cls: CSClass
}

private let csBank: [CSAnimal] = [
    // Mammals
    CSAnimal(emoji: "🐕", name: "Dog", cls: .mammal),
    CSAnimal(emoji: "🐈", name: "Cat", cls: .mammal),
    CSAnimal(emoji: "🐴", name: "Horse", cls: .mammal),
    CSAnimal(emoji: "🦁", name: "Lion", cls: .mammal),
    CSAnimal(emoji: "🐘", name: "Elephant", cls: .mammal),
    CSAnimal(emoji: "🐻", name: "Bear", cls: .mammal),
    CSAnimal(emoji: "🐰", name: "Rabbit", cls: .mammal),
    CSAnimal(emoji: "🐮", name: "Cow", cls: .mammal),
    CSAnimal(emoji: "🐷", name: "Pig", cls: .mammal),
    CSAnimal(emoji: "🐒", name: "Monkey", cls: .mammal),
    CSAnimal(emoji: "🐭", name: "Mouse", cls: .mammal),
    CSAnimal(emoji: "🦊", name: "Fox", cls: .mammal),
    // Birds
    CSAnimal(emoji: "🦅", name: "Eagle", cls: .bird),
    CSAnimal(emoji: "🦉", name: "Owl", cls: .bird),
    CSAnimal(emoji: "🦜", name: "Parrot", cls: .bird),
    CSAnimal(emoji: "🐧", name: "Penguin", cls: .bird),
    CSAnimal(emoji: "🦆", name: "Duck", cls: .bird),
    CSAnimal(emoji: "🐔", name: "Chicken", cls: .bird),
    CSAnimal(emoji: "🦩", name: "Flamingo", cls: .bird),
    CSAnimal(emoji: "🦢", name: "Swan", cls: .bird),
    CSAnimal(emoji: "🦃", name: "Turkey", cls: .bird),
    CSAnimal(emoji: "🐦", name: "Robin", cls: .bird),
    // Reptiles
    CSAnimal(emoji: "🐍", name: "Snake", cls: .reptile),
    CSAnimal(emoji: "🦎", name: "Lizard", cls: .reptile),
    CSAnimal(emoji: "🐢", name: "Turtle", cls: .reptile),
    CSAnimal(emoji: "🐊", name: "Crocodile", cls: .reptile),
    CSAnimal(emoji: "🦖", name: "T-Rex", cls: .reptile),
    CSAnimal(emoji: "🐉", name: "Dragon", cls: .reptile),
]

/// An animal currently in play — falling, or animating into a bin.
private struct CSTile: Identifiable {
    let id = UUID()
    let animal: CSAnimal
    var progress: CGFloat        // 0 at top, 1 at floor
    var landing: CSClass?        // non-nil once sent to a bin (animating out)
    var landAnim: CGFloat = 0    // 0→1 during the fly-to-bin animation
    var correct: Bool = false
}

private struct CSParticle: Identifiable {
    let id = UUID()
    var x: CGFloat; var y: CGFloat
    var vx: CGFloat; var vy: CGFloat
    var life: CGFloat
    var r: CGFloat
    var hex: UInt
}

private struct CSFloater: Identifiable {
    let id = UUID()
    var x: CGFloat; var y: CGFloat
    var text: String
    var life: CGFloat
    var hex: UInt
}

// MARK: - Engine

@MainActor
private final class CSEngine: ObservableObject {
    enum Phase { case playing, over }

    // Coarse state driving the SwiftUI views.
    @Published var phase: Phase = .playing
    @Published var score = 0
    @Published var den = 0
    @Published var hearts = 3
    @Published var combo = 0
    @Published var tiles: [CSTile] = []
    @Published var particles: [CSParticle] = []
    @Published var floaters: [CSFloater] = []
    @Published var flash: CGFloat = 0        // red damage flash 1→0

    // Run summary (published on game over).
    @Published var best = 0
    @Published var lastScore = 0
    @Published var lastDen = 0
    @Published var newBest = false

    private let gameKey = "critterSort"

    private var size: CGSize = .zero
    private var lastTick: Date?
    private var running = false
    private var lastName: String? = nil

    // Fall geometry: a tile falls through the play field above the bins.
    private var binTop: CGFloat { size.height * 0.70 }
    private var tileTop: CGFloat { size.height * 0.22 }

    init() {
        best = LudusStore.best(gameKey)
    }

    // Fall duration (seconds) for one tile, shrinking as the score climbs.
    // Starts very slow (~8.5s) so a young player has plenty of time to think.
    private func fallDuration() -> Double {
        max(3.6, 8.5 - Double(score) * 0.09)
    }

    func start() {
        tiles.removeAll(); particles.removeAll(); floaters.removeAll()
        score = 0; den = 0; hearts = 3; combo = 0
        flash = 0; lastTick = nil; lastName = nil
        newBest = false
        phase = .playing
        running = true
        Haptics.prime()
    }

    private func nextAnimal() -> CSAnimal {
        var a = csBank.randomElement()!
        while a.name == lastName && csBank.count > 1 {
            a = csBank.randomElement()!
        }
        lastName = a.name
        return a
    }

    private func spawn() {
        tiles.append(CSTile(animal: nextAnimal(), progress: 0))
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
                // Stagger a second tile only once the first is well down the field.
                if let lead = tiles.first(where: { $0.landing == nil }), lead.progress > 0.62 {
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
    func tileCenter(_ t: CSTile) -> CGPoint {
        let y = tileTop + (binTop - tileTop) * t.progress
        return CGPoint(x: size.width / 2, y: y)
    }

    /// Horizontal target for a bin, used by the fly-to-bin landing animation.
    func binTargetX(_ cls: CSClass) -> CGFloat {
        switch cls {
        case .mammal:  return size.width * 0.18
        case .bird:    return size.width * 0.50
        case .reptile: return size.width * 0.82
        }
    }

    // MARK: Input — the player taps a bin.

    func chooseBin(_ cls: CSClass) {
        guard running else { return }
        // Act on the lowest live tile (closest to the floor).
        guard let idx = tiles.enumerated()
            .filter({ $0.element.landing == nil })
            .max(by: { $0.element.progress < $1.element.progress })?.offset
        else { return }

        let t = tiles[idx]
        let center = tileCenter(t)
        let correct = (t.animal.cls == cls)

        tiles[idx].landing = cls
        tiles[idx].correct = correct
        tiles[idx].landAnim = 0.001

        if correct {
            combo += 1
            let pts = 1 + max(0, combo - 1)   // combo multiplier for streaks
            score += pts
            den += pts
            burst(center.x, center.y, tint(cls), 14)
            floaters.append(CSFloater(x: center.x, y: center.y - 30, text: "+\(pts)", life: 1, hex: Lu.gold))
            Haptics.tap(min(1.0, 0.55 + Double(combo) * 0.06))
        } else {
            damage(at: center, label: "WRONG!")
        }
    }

    func tint(_ cls: CSClass) -> UInt {
        switch cls {
        case .mammal:  return Lu.coral
        case .bird:    return Lu.sky
        case .reptile: return Lu.mint
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
        floaters.append(CSFloater(x: center.x, y: center.y - 30, text: label, life: 1, hex: Lu.coral))
        Haptics.error()
        if hearts <= 0 { gameOver() }
    }

    private func burst(_ x: CGFloat, _ y: CGFloat, _ hex: UInt, _ n: Int) {
        for _ in 0..<n {
            let a = Double.random(in: 0..<(2 * .pi))
            let sp = Double.random(in: 70...260)
            particles.append(CSParticle(
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

struct CritterSortView: View {
    let onClose: () -> Void
    @StateObject private var game = CSEngine()

    // Drive the fall from a timer (fires OUTSIDE the view-render pass) so mutating the
    // engine's @Published state is safe and actually repaints. Advancing inside a
    // TimelineView body silently freezes the tile.
    private let ticker = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LudusBackground().ignoresSafeArea()

                CSPlayfield(game: game, size: geo.size)

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
                    CSBins(game: game)
                }
                .ignoresSafeArea(.container, edges: .bottom)

                // HUD (top, respects safe area).
                VStack {
                    HStack(alignment: .top, spacing: 8) {
                        LudusCloseButton(action: onClose)
                        StatPill(label: "SCORE", value: "\(game.score)", valueHex: Lu.gold)
                        Spacer(minLength: 4)
                        HeartsRow(hearts: game.hearts)
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
                    LudusGameOverView(
                        reason: "Critter Sort",
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
            .onReceive(ticker) { _ in game.advance(to: Date(), size: geo.size) }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onAppear { game.start() }
    }
}

// MARK: - Playfield (falling tiles, particles, floaters)

private struct CSPlayfield: View {
    @ObservedObject var game: CSEngine
    let size: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Hint header.
            Text("Tap MAMMAL, BIRD, or REPTILE!")
                .font(luFont(13, .heavy))
                .tracking(1)
                .foregroundStyle(Color(hex: Lu.inkDim).opacity(0.85))
                .frame(width: size.width)
                .position(x: size.width / 2, y: size.height * 0.135)

            // Falling / landing tiles.
            ForEach(game.tiles) { tile in
                CSTileCard(emoji: tile.animal.emoji, name: tile.animal.name)
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

    private func tilePosition(_ tile: CSTile) -> CGPoint {
        let center = game.tileCenter(tile)
        guard let landing = tile.landing else { return center }
        // Fly toward the chosen bin.
        let targetX = game.binTargetX(landing)
        let targetY = size.height * 0.80
        let a = tile.landAnim
        return CGPoint(
            x: center.x + (targetX - center.x) * a,
            y: center.y + (targetY - center.y) * a
        )
    }
}

private struct CSTileCard: View {
    let emoji: String
    let name: String
    var body: some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.system(size: 38))
            Text(name)
                .font(luFont(30))
                .foregroundStyle(Color(hex: Lu.inkDark))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
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

private struct CSBins: View {
    @ObservedObject var game: CSEngine

    var body: some View {
        HStack(spacing: 10) {
            CSBinButton(title: "MAMMAL", emoji: "🐾", tint: Lu.coral) { game.chooseBin(.mammal) }
            CSBinButton(title: "BIRD", emoji: "🪶", tint: Lu.sky) { game.chooseBin(.bird) }
            CSBinButton(title: "REPTILE", emoji: "🥚", tint: Lu.mint) { game.chooseBin(.reptile) }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 30)
    }
}

private struct CSBinButton: View {
    let title: String
    let emoji: String
    let tint: UInt
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(emoji)
                    .font(.system(size: 24))
                Text(title)
                    .font(luFont(19))
                    .foregroundStyle(Color(hex: Lu.inkDark))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                ZStack {
                    luPanelShape(22)
                    RoundedRectangle(cornerRadius: 22)
                        .fill(LinearGradient(colors: [Color(hex: tint), luShade(tint, -40)],
                                             startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.4), lineWidth: 2))
                }
            )
            .shadow(color: luShade(tint, -70).opacity(0.7), radius: 0, x: 0, y: 6)
        }
        .buttonStyle(CSPressStyle())
    }
}

/// A little squish on press so a bin tap feels physical.
private struct CSPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
