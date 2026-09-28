import SwiftUI

// MARK: - Ludus arcade: "Times Table Ninja"
//
// A fruit-ninja-style drill for the multiplication tables. A target table is shown
// ("Slice the ×7s"); numbers arc up from the bottom. Swipe through the correct
// multiples for points (combo-multiplied within one continuous swipe); swipe a wrong
// number or a bomb and lose a heart. The target rotates every ~12s. Three hearts,
// difficulty ramps, and the run banks denarii into the shared Ludus economy.
//
// Everything here is `private` and `TTN`-prefixed except the public entry point
// `TimesTableNinjaView`, so it can't collide with the other game files. It leans on
// the shared LudusTheme symbols (Lu, luFont, luShade, LudusBackground, LudusButton,
// StatPill, LudusCloseButton, LudusStore, Haptics, Color(hex:)) — none are redefined.

private let ttnGameKey = "timesTableNinja"

// MARK: - Model

private struct TTNProjectile: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var r: CGFloat
    var spin: CGFloat        // current rotation
    var spinV: CGFloat       // rotation velocity
    var val: Int
    var correct: Bool        // true if a multiple of the current target
    var bomb: Bool
    var hex: UInt
    var sliced: Bool = false
    var pop: CGFloat = 0     // 0 alive; grows 0→1 while bursting, then removed
}

private struct TTNParticle {
    var x: CGFloat; var y: CGFloat; var vx: CGFloat; var vy: CGFloat
    var life: CGFloat; var r: CGFloat; var hex: UInt
}

private struct TTNFloater {
    var x: CGFloat; var y: CGFloat; var text: String; var life: CGFloat; var hex: UInt
}

private struct TTNBladePoint {
    var p: CGPoint
    var life: CGFloat
}

// MARK: - Game engine

@MainActor
private final class TTNEngine: ObservableObject {
    enum Phase { case playing, over }

    // Coarse UI state (drives HUD + overlays).
    @Published var phase: Phase = .playing
    @Published var score = 0
    @Published var den = 0
    @Published var hearts = 3
    @Published var combo = 0
    @Published var target = 7
    @Published var lastScore = 0
    @Published var lastDen = 0
    @Published var lastBest = 0
    @Published var newBest = false

    // Per-frame simulation state (read by Canvas each tick; never @Published).
    private var projectiles: [TTNProjectile] = []
    private var particles: [TTNParticle] = []
    private var floaters: [TTNFloater] = []
    private var blade: [TTNBladePoint] = []

    private var size: CGSize = .zero
    private var elapsed: Double = 0
    private var spawnAcc: Double = 0
    private var targetAcc: Double = 0
    private var lastTick: Date?
    private var simulating = false
    private var shake: CGFloat = 0
    private var swiping = false          // true between bladeMove start and bladeEnd

    private let gravity: CGFloat = 480

    // MARK: Lifecycle

    func start() {
        projectiles.removeAll(); particles.removeAll(); floaters.removeAll(); blade.removeAll()
        score = 0; den = 0; hearts = 3; combo = 0
        elapsed = 0; spawnAcc = 0; targetAcc = 0; lastTick = nil; shake = 0
        swiping = false
        newBest = false
        target = availableTables().randomElement() ?? 2
        phase = .playing
        simulating = true
        Haptics.prime()
    }

    private func radius() -> CGFloat {
        max(28, min(46, size.width * 0.105))
    }

    // Start on the friendliest tables (2s, 5s, 10s); widen the pool only once the kid has
    // built up some points, so nobody's stuck slicing ×7s from the whistle.
    private func availableTables() -> [Int] {
        if score >= 80 { return [2, 3, 4, 5, 6, 7, 10] }
        if score >= 40 { return [2, 3, 4, 5, 10] }
        return [2, 5, 10]
    }

    // MARK: Simulation

    // Returns count purely so the caller can `let _ = advance(...)` in a ViewBuilder.
    @discardableResult
    func advance(to date: Date, size: CGSize) -> Int {
        self.size = size
        guard let prev = lastTick else { lastTick = date; return projectiles.count }
        lastTick = date
        var dt = date.timeIntervalSince(prev)
        if dt < 0 { dt = 0 }
        if dt > 0.05 { dt = 0.05 }

        if simulating {
            elapsed += dt

            // Rotate the target table every ~18s — plenty of time to settle into one.
            targetAcc += dt
            if targetAcc >= 18 {
                targetAcc = 0
                rotateTarget()
            }

            // Spawn cadence + strength ramp with elapsed time — gentle, one-at-a-time-ish.
            let interval = max(0.9, 1.8 - elapsed * 0.012)
            spawnAcc += dt
            while spawnAcc >= interval {
                spawnAcc -= interval
                spawnWave()
            }

            // Physics.
            for i in projectiles.indices.reversed() {
                if projectiles[i].pop > 0 {
                    projectiles[i].pop += CGFloat(dt) * 5.5
                    if projectiles[i].pop >= 1 { projectiles.remove(at: i) }
                    continue
                }
                projectiles[i].vy += gravity * CGFloat(dt)
                projectiles[i].x += projectiles[i].vx * CGFloat(dt)
                projectiles[i].y += projectiles[i].vy * CGFloat(dt)
                projectiles[i].spin += projectiles[i].spinV * CGFloat(dt)
                // Fell off the bottom, unsliced — forgiving: just remove.
                if projectiles[i].y > size.height + projectiles[i].r + 40 {
                    projectiles.remove(at: i)
                }
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
            floaters[i].life -= CGFloat(dt) * 1.2
            floaters[i].y -= CGFloat(46 * dt)
            if floaters[i].life <= 0 { floaters.remove(at: i) }
        }
        // Blade trail decay.
        for i in blade.indices.reversed() {
            blade[i].life -= CGFloat(dt) * 6
            if blade[i].life <= 0 { blade.remove(at: i) }
        }
        if shake > 0 { shake -= CGFloat(dt) }
        return projectiles.count
    }

    private func rotateTarget() {
        let tables = availableTables()
        var t = tables.randomElement() ?? 2
        var guard0 = 0
        while t == target && guard0 < 10 { t = tables.randomElement() ?? 2; guard0 += 1 }
        floaters.append(TTNFloater(x: size.width / 2, y: size.height * 0.34,
                                   text: "×\(t)!", life: 1.1, hex: Lu.mint))
        Haptics.light()
        // @Published write; advance() now runs inside the Canvas render pass — defer it.
        DispatchQueue.main.async { [weak self] in self?.target = t }
    }

    private func spawnWave() {
        guard size.width > 0, size.height > 0 else { return }
        // Mostly one at a time; very occasionally two once well warmed up.
        let maxBatch = min(2, 1 + Int(elapsed / 45))
        let batch = Int.random(in: 1...maxBatch)
        for _ in 0..<batch { spawnOne() }
    }

    private func spawnOne() {
        let r = radius()
        // No bombs for the first ~14s, then a slow ramp — they're a spike-flavour, not the point.
        let bomb = Double.random(in: 0..<1) < min(0.10, max(0, (elapsed - 14) * 0.004))

        // Bias toward correct multiples so there's always an easy, satisfying target.
        let correct = !bomb && Double.random(in: 0..<1) < 0.62
        let val: Int
        if correct {
            val = target * Int.random(in: 1...10)
        } else {
            val = ttnDistractor(for: target)
        }

        let launchX = CGFloat.random(in: (size.width * 0.16)...(size.width * 0.84))
        // Aim the arc back toward mid-screen so it stays on-screen.
        let toCenter = (size.width / 2 - launchX)
        let vx = toCenter * CGFloat.random(in: 0.5...0.9) + CGFloat.random(in: -30...30)
        // Slower launch so numbers hang and can be read before slicing.
        let hScale = size.height / 800
        let vy = -CGFloat.random(in: 540...660) * hScale * (1 + CGFloat(elapsed) * 0.003)

        projectiles.append(TTNProjectile(
            x: launchX, y: size.height + r,
            vx: vx, vy: vy, r: r,
            spin: CGFloat.random(in: 0...6.28),
            spinV: CGFloat.random(in: -3...3),
            val: val, correct: correct, bomb: bomb,
            hex: bomb ? Lu.inkDark : (Lu.bubbleHexes.randomElement() ?? Lu.sky)
        ))
    }

    private func ttnDistractor(for t: Int) -> Int {
        // A clearly-not-a-multiple number (no sneaky off-by-one near-misses — those demand
        // exact table knowledge and stump young kids).
        for _ in 0..<20 {
            let cand = Int.random(in: 2...(t * 10 + 3))
            if cand % t != 0 { return cand }
        }
        return t * 2 + 1
    }

    // MARK: Blade / slicing (gesture-driven — synchronous @Published mutation is fine)

    func bladeMove(_ p: CGPoint) {
        if !swiping {
            swiping = true
            blade.removeAll(keepingCapacity: true)
        }
        let prev = blade.last?.p
        blade.append(TTNBladePoint(p: p, life: 1))
        if blade.count > 8 { blade.removeFirst(blade.count - 8) }
        if let a = prev { testSegment(a, p) }
    }

    func bladeEnd() {
        swiping = false
    }

    // Test the blade segment a→b against every live projectile.
    private func testSegment(_ a: CGPoint, _ b: CGPoint) {
        guard simulating else { return }
        for i in projectiles.indices {
            if projectiles[i].sliced || projectiles[i].pop > 0 { continue }
            let c = CGPoint(x: projectiles[i].x, y: projectiles[i].y)
            let hitR = projectiles[i].r + 8
            if ttnSegmentHitsCircle(a, b, c, hitR) {
                slice(i)
                if !simulating { return }   // game over ended the sim mid-loop
            }
        }
    }

    private func slice(_ i: Int) {
        guard projectiles.indices.contains(i) else { return }
        let p = projectiles[i]
        projectiles[i].sliced = true
        projectiles[i].pop = 0.001

        if p.bomb {
            loseHeart(at: CGPoint(x: p.x, y: p.y), label: "BOMB!")
        } else if p.correct {
            combo += 1                       // a real streak now — persists across swipes
            let pts = combo
            score += pts
            den += pts
            burst(p.x, p.y, p.hex, 14)
            floaters.append(TTNFloater(x: p.x, y: p.y - p.r, text: "+\(pts)", life: 1, hex: Lu.gold))
            Haptics.tap(min(1.0, 0.5 + Double(combo) * 0.08))
        } else {
            loseHeart(at: CGPoint(x: p.x, y: p.y), label: "\(p.val)? NO")
        }
    }

    private func loseHeart(at pt: CGPoint, label: String) {
        combo = 0
        hearts -= 1
        burst(pt.x, pt.y, Lu.coral, 12)
        floaters.append(TTNFloater(x: pt.x, y: pt.y - 20, text: label, life: 1.1, hex: Lu.coral))
        shake = 0.32
        Haptics.error()
        if hearts <= 0 { triggerGameOver() }
    }

    private func burst(_ x: CGFloat, _ y: CGFloat, _ hex: UInt, _ n: Int) {
        for _ in 0..<n {
            let a = Double.random(in: 0..<6.28)
            let sp = Double.random(in: 70...280)
            particles.append(TTNParticle(
                x: x, y: y,
                vx: CGFloat(cos(a) * sp), vy: CGFloat(sin(a) * sp - 60),
                life: 1, r: CGFloat.random(in: 3...7), hex: hex
            ))
        }
    }

    private func triggerGameOver() {
        guard simulating else { return }
        simulating = false
        shake = 0.34
        let s = score
        let d = den
        LudusStore.award(d)
        let isBest = LudusStore.recordBest(ttnGameKey, s)
        let bestNow = LudusStore.best(ttnGameKey)
        Haptics.error()
        // Flip published UI state outside the current view-update pass.
        DispatchQueue.main.async {
            self.lastScore = s
            self.lastDen = d
            self.lastBest = bestNow
            self.newBest = isBest
            self.phase = .over
        }
    }

    // MARK: Rendering

    func render(context ctx: inout GraphicsContext, size: CGSize) {
        if shake > 0 {
            let m = shake / 0.34 * 15
            ctx.translateBy(x: CGFloat.random(in: -m...m), y: CGFloat.random(in: -m...m))
        }

        // Target banner (drawn in canvas per spec).
        let banner = ctx.resolve(Text("SLICE THE ×\(target)s")
            .font(luFont(30, .black))
            .foregroundColor(Color(hex: Lu.ink)))
        ctx.opacity = 0.9
        ctx.draw(banner, at: CGPoint(x: size.width / 2, y: size.height * 0.16))
        ctx.opacity = 1

        // Projectiles.
        for p in projectiles {
            let grow: CGFloat = p.pop > 0 ? 1 + p.pop * 0.7 : 1
            let r = p.r * grow
            let alpha: Double = p.pop > 0 ? Double(1 - p.pop) : 1
            let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)

            if p.bomb {
                ctx.opacity = alpha
                let grad = Gradient(colors: [luShade(Lu.inkDark, 40), Color(hex: Lu.inkDark), .black])
                ctx.fill(Path(ellipseIn: rect),
                         with: .radialGradient(grad,
                                               center: CGPoint(x: p.x - r * 0.3, y: p.y - r * 0.34),
                                               startRadius: r * 0.1, endRadius: r))
                ctx.opacity = alpha * 0.8
                ctx.stroke(Path(ellipseIn: rect), with: .color(Color(hex: Lu.coral)), lineWidth: 3)
                ctx.opacity = alpha
                let skull = ctx.resolve(Text("💣")
                    .font(.system(size: r * 1.05)))
                ctx.draw(skull, at: CGPoint(x: p.x, y: p.y))
            } else {
                ctx.opacity = alpha * 0.96
                let grad = Gradient(colors: [.white, Color(hex: p.hex), luShade(p.hex, -34)])
                ctx.fill(Path(ellipseIn: rect),
                         with: .radialGradient(grad,
                                               center: CGPoint(x: p.x - r * 0.32, y: p.y - r * 0.36),
                                               startRadius: r * 0.15, endRadius: r))
                ctx.opacity = alpha * 0.55
                ctx.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 3)
                // glossy highlight
                ctx.opacity = alpha * 0.5
                let gloss = CGRect(x: p.x - r * 0.56, y: p.y - r * 0.62, width: r * 0.6, height: r * 0.34)
                ctx.fill(Path(ellipseIn: gloss), with: .color(.white))
                // numeral
                ctx.opacity = alpha
                let t = ctx.resolve(Text("\(p.val)")
                    .font(.system(size: r * 0.86, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: Lu.inkDark)))
                ctx.draw(t, at: CGPoint(x: p.x, y: p.y))
            }
        }
        ctx.opacity = 1

        // Particles.
        for p in particles {
            ctx.opacity = Double(max(0, p.life))
            let rect = CGRect(x: p.x - p.r, y: p.y - p.r, width: p.r * 2, height: p.r * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(Color(hex: p.hex)))
        }
        ctx.opacity = 1

        // Blade trail — a glowing tapered polyline.
        if blade.count >= 2 {
            var path = Path()
            path.move(to: blade[0].p)
            for pt in blade.dropFirst() { path.addLine(to: pt.p) }
            let headLife = Double(blade.last?.life ?? 0)
            ctx.opacity = 0.3 * headLife
            ctx.stroke(path, with: .color(Color(hex: Lu.mint)),
                       style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round))
            ctx.opacity = 0.9 * headLife
            ctx.stroke(path, with: .color(.white),
                       style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            ctx.opacity = 1
        }

        // Floaters.
        for f in floaters {
            ctx.opacity = Double(max(0, min(1, f.life)))
            let t = ctx.resolve(Text(f.text)
                .font(.system(size: 27, weight: .black, design: .rounded))
                .foregroundColor(Color(hex: f.hex)))
            ctx.draw(t, at: CGPoint(x: f.x, y: f.y))
        }
        ctx.opacity = 1
    }
}

// MARK: - Geometry helper

/// Does the segment a→b pass within `r` of point c?
private func ttnSegmentHitsCircle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ r: CGFloat) -> Bool {
    let abx = b.x - a.x, aby = b.y - a.y
    let acx = c.x - a.x, acy = c.y - a.y
    let len2 = abx * abx + aby * aby
    var t: CGFloat = 0
    if len2 > 0 {
        t = max(0, min(1, (acx * abx + acy * aby) / len2))
    }
    let px = a.x + abx * t, py = a.y + aby * t
    let dx = c.x - px, dy = c.y - py
    return dx * dx + dy * dy <= r * r
}

// MARK: - Public entry point

struct TimesTableNinjaView: View {
    let onClose: () -> Void
    @StateObject private var game = TTNEngine()

    var body: some View {
        ZStack {
            LudusBackground().ignoresSafeArea()

            // Step + draw inside the Canvas, keyed to the timeline clock, so it repaints.
            TimelineView(.animation) { tl in
                Canvas { ctx, sz in
                    game.advance(to: tl.date, size: sz)
                    game.render(context: &ctx, size: sz)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in game.bladeMove(v.location) }
                        .onEnded { _ in game.bladeEnd() }
                )
            }
            .ignoresSafeArea()

            // HUD — non-interactive so swipes fall straight through to the blade.
            VStack {
                HStack(alignment: .top, spacing: 8) {
                    Color.clear.frame(width: 38, height: 38)
                    StatPill(label: "SCORE", value: "\(game.score)", valueHex: Lu.gold)
                    Spacer(minLength: 4)
                    TTNHeartsView(hearts: game.hearts)
                    Spacer(minLength: 4)
                    StatPill(label: "DENARII", value: "\(game.den)", valueHex: Lu.silver)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .allowsHitTesting(false)

            VStack {
                HStack { LudusCloseButton(action: onClose); Spacer() }
                Spacer()
            }
            .padding(.horizontal, 12).padding(.top, 4)

            if game.combo >= 2 && game.phase == .playing {
                Text("COMBO ×\(game.combo)!")
                    .font(luFont(26))
                    .foregroundStyle(Color(hex: Lu.mint))
                    .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 3)
                    .padding(.top, 96)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .id(game.combo)
                    .transition(.scale(scale: 1.25).combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: game.combo)
                    .allowsHitTesting(false)
            }

            if game.phase == .over {
                TTNGameOverView(game: game, onAgain: { game.start() }, onClose: onClose)
                    .transition(.opacity)
            }
        }
        .statusBarHidden(true)
        .onAppear { game.start() }
    }
}

// MARK: - HUD pieces

private struct TTNHeartsView: View {
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

private struct TTNGameOverView: View {
    @ObservedObject var game: TTNEngine
    let onAgain: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.58).ignoresSafeArea()
            VStack(spacing: 10) {
                Text("OUT OF HEARTS")
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
                    TTNResultCard(label: "SCORE", value: "\(game.lastScore)", hex: Lu.gold)
                    TTNResultCard(label: "BEST", value: "\(game.lastBest)", hex: Lu.mint)
                    TTNResultCard(label: "DENARII WON", value: "\(game.lastDen)", hex: Lu.silver)
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

private struct TTNResultCard: View {
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
