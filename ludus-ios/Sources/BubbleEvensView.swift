import SwiftUI

// MARK: - Bubble Evens  (Number Crunchers · pop-the-target)
//
// Tap the EVEN numbers as they rise; let odds drift by. If an even escapes the top the
// run ends. Wrong taps (odds) cost a heart. The first Ludus mechanic — a template for
// every other "pop the ones that match the rule" game.

private struct BEBubble: Identifiable {
    let id = UUID()
    var x: CGFloat; var y: CGFloat; var r: CGFloat; var vx: CGFloat; var phase: CGFloat
    var val: Int; var even: Bool; var hex: UInt; var pop: CGFloat = 0
}
private struct BEParticle { var x, y, vx, vy, life, r: CGFloat; var hex: UInt }
private struct BEFloater { var x, y: CGFloat; var text: String; var life: CGFloat; var hex: UInt }

@MainActor
private final class BubbleEvensEngine: ObservableObject {
    enum Phase { case playing, over }
    @Published var phase: Phase = .playing
    @Published var score = 0
    @Published var den = 0
    @Published var hearts = 3
    @Published var combo = 0
    @Published var lastScore = 0
    @Published var lastDen = 0
    @Published var best = 0
    @Published var newBest = false
    @Published var reason = ""

    private(set) var bubbles: [BEBubble] = []
    private var particles: [BEParticle] = []
    private var floaters: [BEFloater] = []
    private var size: CGSize = .zero
    private var elapsed = 0.0
    private var spawnAcc = 0.0
    private var lastTick: Date?
    private var simulating = false
    private var shake: CGFloat = 0

    private let key = "bubbleEvens"

    private func radius() -> CGFloat { max(30, min(56, size.width * 0.12)) }

    func start() {
        bubbles.removeAll(); particles.removeAll(); floaters.removeAll()
        score = 0; den = 0; hearts = 3; combo = 0
        elapsed = 0; spawnAcc = 0; lastTick = nil; shake = 0
        reason = ""; newBest = false
        phase = .playing; simulating = true
        Haptics.prime()
    }

    @discardableResult
    func advance(to date: Date, size: CGSize) -> Int {
        self.size = size
        guard let prev = lastTick else { lastTick = date; seed(); return bubbles.count }
        lastTick = date
        var dt = date.timeIntervalSince(prev)
        dt = min(max(dt, 0), 0.05)

        if simulating {
            elapsed += dt
            let interval = max(0.5, 1.25 - elapsed * 0.018)
            let hScale = size.height / 760
            let speed = min(160, 52 + elapsed * 2.4) * hScale
            spawnAcc += dt
            while spawnAcc >= interval { spawnAcc -= interval; spawnOne() }

            for i in bubbles.indices.reversed() {
                if bubbles[i].pop > 0 {
                    bubbles[i].pop += CGFloat(dt) * 6
                    if bubbles[i].pop >= 1 { bubbles.remove(at: i) }
                    continue
                }
                bubbles[i].phase += CGFloat(dt) * 2.2
                bubbles[i].y -= CGFloat(speed * dt)
                bubbles[i].x += bubbles[i].vx * CGFloat(dt) + sin(bubbles[i].phase) * 0.3
                let r = bubbles[i].r
                if bubbles[i].x < r { bubbles[i].x = r; bubbles[i].vx = abs(bubbles[i].vx) }
                if bubbles[i].x > size.width - r { bubbles[i].x = size.width - r; bubbles[i].vx = -abs(bubbles[i].vx) }
                if bubbles[i].y < -r {
                    let wasEven = bubbles[i].even
                    let fx = bubbles[i].x
                    bubbles.remove(at: i)
                    if wasEven { missEven(fx) }
                }
            }
        }
        stepEffects(dt)
        return bubbles.count
    }

    private func stepEffects(_ dt: Double) {
        for i in particles.indices.reversed() {
            particles[i].life -= CGFloat(dt) * 1.7
            if particles[i].life <= 0 { particles.remove(at: i); continue }
            particles[i].vy += CGFloat(380 * dt)
            particles[i].x += particles[i].vx * CGFloat(dt)
            particles[i].y += particles[i].vy * CGFloat(dt)
        }
        for i in floaters.indices.reversed() {
            floaters[i].life -= CGFloat(dt) * 1.3
            floaters[i].y -= CGFloat(42 * dt)
            if floaters[i].life <= 0 { floaters.remove(at: i) }
        }
        if shake > 0 { shake -= CGFloat(dt) }
    }

    private func seed() {
        guard size.width > 0 else { return }
        // Start with bubbles already partway up so the field is alive at the whistle.
        for k in 0..<4 { spawnOne(atY: size.height * CGFloat(0.5 + Double(k) * 0.14)) }
    }

    private func spawnOne(atY: CGFloat? = nil) {
        guard size.width > 0 else { return }
        let r = radius()
        let even = Double.random(in: 0..<1) < 0.52
        let val = even ? 2 * Int.random(in: 1...30) : 2 * Int.random(in: 0...29) + 1
        let x = CGFloat.random(in: (r + 8)...(max(r + 9, size.width - r - 8)))
        bubbles.append(BEBubble(x: x, y: atY ?? (size.height + r), r: r,
                                vx: CGFloat.random(in: -14...14),
                                phase: CGFloat.random(in: 0...6.28),
                                val: val, even: even,
                                hex: Lu.bubbleHexes.randomElement() ?? Lu.sky))
    }

    // A missed even now costs a heart instead of instantly ending the run — far kinder as
    // a first impression, and it still punishes letting evens slip past.
    private func missEven(_ x: CGFloat) {
        shake = 0.26
        floaters.append(BEFloater(x: min(max(x, 30), size.width - 30), y: 44, text: "MISSED!", life: 1, hex: Lu.coral))
        Haptics.error()
        DispatchQueue.main.async { [weak self] in
            guard let self, self.simulating else { return }
            self.combo = 0
            self.hearts -= 1
            if self.hearts <= 0 { self.triggerGameOver("Out of hearts!") }
        }
    }

    func tap(_ p: CGPoint) {
        guard simulating else { return }
        for i in bubbles.indices.reversed() {
            if bubbles[i].pop > 0 { continue }
            let b = bubbles[i]
            let dx = p.x - b.x, dy = p.y - b.y
            let hit = b.r + 12
            if dx * dx + dy * dy <= hit * hit {
                if b.even {
                    combo += 1
                    let pts = combo
                    score += pts; den += pts
                    bubbles[i].pop = 0.001
                    burst(b.x, b.y, b.hex, 12)
                    floaters.append(BEFloater(x: b.x, y: b.y - b.r, text: "+\(pts)", life: 1, hex: Lu.gold))
                    Haptics.tap(0.5 + Double(combo) * 0.06)
                } else {
                    combo = 0; hearts -= 1
                    bubbles[i].pop = 0.001
                    burst(b.x, b.y, Lu.coral, 8)
                    floaters.append(BEFloater(x: b.x, y: b.y - b.r, text: "ODD!", life: 1, hex: Lu.coral))
                    shake = 0.3
                    Haptics.error()
                    if hearts <= 0 { triggerGameOver("Out of hearts!") }
                }
                return
            }
        }
    }

    private func burst(_ x: CGFloat, _ y: CGFloat, _ hex: UInt, _ n: Int) {
        for _ in 0..<n {
            let a = Double.random(in: 0..<6.28), sp = Double.random(in: 60...240)
            particles.append(BEParticle(x: x, y: y, vx: CGFloat(cos(a) * sp), vy: CGFloat(sin(a) * sp - 40),
                                        life: 1, r: CGFloat.random(in: 3...7), hex: hex))
        }
    }

    private func triggerGameOver(_ why: String) {
        guard simulating else { return }
        simulating = false
        shake = 0.34
        let s = score, d = den
        LudusStore.award(d)
        let isBest = LudusStore.recordBest(key, s)
        Haptics.error()
        DispatchQueue.main.async {
            self.lastScore = s; self.lastDen = d
            self.best = LudusStore.best(self.key); self.newBest = isBest
            self.reason = why; self.phase = .over
        }
    }

    func render(context ctx: inout GraphicsContext, size: CGSize) {
        if shake > 0 {
            let m = shake / 0.34 * 16
            ctx.translateBy(x: CGFloat.random(in: -m...m), y: CGFloat.random(in: -m...m))
        }
        for b in bubbles {
            let grow: CGFloat = b.pop > 0 ? 1 + b.pop * 0.6 : 1
            let r = b.r * grow
            let alpha: Double = b.pop > 0 ? Double(1 - b.pop) : 1
            let rect = CGRect(x: b.x - r, y: b.y - r, width: r * 2, height: r * 2)
            ctx.opacity = alpha * 0.94
            let grad = Gradient(colors: [.white, Color(hex: b.hex), luShade(b.hex, -30)])
            ctx.fill(Path(ellipseIn: rect),
                     with: .radialGradient(grad, center: CGPoint(x: b.x - r * 0.32, y: b.y - r * 0.36),
                                           startRadius: r * 0.15, endRadius: r))
            ctx.opacity = alpha * 0.55
            ctx.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 3)
            ctx.opacity = alpha * 0.5
            ctx.fill(Path(ellipseIn: CGRect(x: b.x - r * 0.58, y: b.y - r * 0.64, width: r * 0.62, height: r * 0.36)),
                     with: .color(.white))
            ctx.opacity = alpha
            let t = ctx.resolve(Text("\(b.val)").font(luFont(r * 0.92)).foregroundColor(Color(hex: Lu.inkDark)))
            ctx.draw(t, at: CGPoint(x: b.x, y: b.y))
        }
        for p in particles {
            ctx.opacity = Double(max(0, p.life))
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - p.r, y: p.y - p.r, width: p.r * 2, height: p.r * 2)),
                     with: .color(Color(hex: p.hex)))
        }
        for f in floaters {
            ctx.opacity = Double(max(0, f.life))
            let t = ctx.resolve(Text(f.text).font(luFont(26)).foregroundColor(Color(hex: f.hex)))
            ctx.draw(t, at: CGPoint(x: f.x, y: f.y))
        }
        ctx.opacity = 1
    }
}

struct BubbleEvensView: View {
    let onClose: () -> Void
    @StateObject private var game = BubbleEvensEngine()

    var body: some View {
        ZStack {
            LudusBackground().ignoresSafeArea()
            // Step AND draw inside the Canvas, keyed to the timeline clock — this is what
            // forces SwiftUI to actually repaint every frame. (Advancing outside the Canvas
            // silently froze the render.)
            TimelineView(.animation) { tl in
                Canvas { ctx, sz in
                    game.advance(to: tl.date, size: sz)
                    game.render(context: &ctx, size: sz)
                }
                .gesture(SpatialTapGesture().onEnded { ev in game.tap(ev.location) })
            }
            .ignoresSafeArea()

            // HUD — non-interactive so every tap falls straight through to the game.
            VStack {
                HStack(alignment: .top, spacing: 8) {
                    Color.clear.frame(width: 38, height: 38)
                    StatPill(label: "SCORE", value: "\(game.score)", valueHex: Lu.gold)
                    Spacer(minLength: 4)
                    HeartsRow(hearts: game.hearts)
                    Spacer(minLength: 4)
                    StatPill(label: "DENARII", value: "\(game.den)", valueHex: Lu.silver)
                }
                Spacer()
            }
            .padding(.horizontal, 12).padding(.top, 4)
            .allowsHitTesting(false)

            // Close button as its own interactive overlay in the HUD's top-left slot.
            VStack {
                HStack { LudusCloseButton(action: onClose); Spacer() }
                Spacer()
            }
            .padding(.horizontal, 12).padding(.top, 4)

            if game.combo >= 2 && game.phase == .playing {
                Text("COMBO ×\(game.combo)!")
                    .font(luFont(26)).foregroundStyle(Color(hex: Lu.mint))
                    .padding(.top, 78).frame(maxHeight: .infinity, alignment: .top)
                    .id(game.combo)
                    .transition(.scale(scale: 1.25).combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: game.combo)
                    .allowsHitTesting(false)
            }

            if game.phase == .over {
                LudusGameOverView(reason: game.reason, score: game.lastScore, best: game.best,
                                  denRun: game.lastDen, newBest: game.newBest,
                                  onAgain: { game.start() }, onClose: onClose)
                    .transition(.opacity)
            }
        }
        .statusBarHidden(true)
        .onAppear { game.start() }
    }
}
