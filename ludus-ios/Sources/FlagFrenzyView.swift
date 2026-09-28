import SwiftUI

// MARK: - Flag Frenzy  (Globe Trotters · pop-the-target, geography)
//
// The app shows ONE flag at the top ("Find this flag: 🇯🇵 Japan"). Flags float up; tap the
// one that matches. It's pure visual matching — a 7-year-old can start with zero geography
// knowledge, and picks up the country names by playing. The target flag is always on
// screen (guaranteed spawns), the pace is gentle, and a missed flag costs nothing — only a
// wrong tap costs a heart. Emoji flags = no image assets.

private struct FFFlag: Identifiable {
    let id = UUID()
    var x: CGFloat; var y: CGFloat; var r: CGFloat; var vx: CGFloat; var phase: CGFloat
    let country: GeoCountry
    var pop: CGFloat = 0
}
private struct FFParticle { var x, y, vx, vy, life, r: CGFloat; var hex: UInt }
private struct FFFloater { var x, y: CGFloat; var text: String; var life: CGFloat; var hex: UInt }

@MainActor
private final class FlagFrenzyEngine: ObservableObject {
    enum Phase { case playing, over }
    @Published var phase: Phase = .playing
    @Published var score = 0
    @Published var den = 0
    @Published var hearts = 3
    @Published var combo = 0
    @Published var target: GeoCountry = Geo.countries[0]   // shown in the banner
    @Published var lastScore = 0
    @Published var lastDen = 0
    @Published var best = 0
    @Published var newBest = false
    @Published var reason = ""

    private var current: GeoCountry = Geo.countries[0]      // logic source of truth (sync)
    private(set) var flags: [FFFlag] = []
    private var particles: [FFParticle] = []
    private var floaters: [FFFloater] = []
    private var size: CGSize = .zero
    private var elapsed = 0.0
    private var spawnAcc = 0.0
    private var lastTick: Date?
    private var simulating = false
    private var shake: CGFloat = 0

    private let key = "flagFrenzy"

    private func radius() -> CGFloat { max(32, min(56, size.width * 0.125)) }

    func start() {
        flags.removeAll(); particles.removeAll(); floaters.removeAll()
        score = 0; den = 0; hearts = 3; combo = 0
        elapsed = 0; spawnAcc = 0; lastTick = nil; shake = 0
        reason = ""; newBest = false
        current = Geo.countries.randomElement() ?? Geo.countries[0]
        target = current
        phase = .playing; simulating = true
        Haptics.prime()
    }

    @discardableResult
    func advance(to date: Date, size: CGSize) -> Int {
        self.size = size
        guard let prev = lastTick else { lastTick = date; seed(); return flags.count }
        lastTick = date
        var dt = date.timeIntervalSince(prev)
        dt = min(max(dt, 0), 0.05)

        if simulating {
            elapsed += dt
            // Gentle pace — slow rise, one flag at a time-ish.
            let interval = max(0.8, 1.5 - elapsed * 0.01)
            let hScale = size.height / 760
            let speed = min(110, 34 + elapsed * 1.2) * hScale
            spawnAcc += dt
            while spawnAcc >= interval { spawnAcc -= interval; spawnOne() }

            for i in flags.indices.reversed() {
                if flags[i].pop > 0 {
                    flags[i].pop += CGFloat(dt) * 6
                    if flags[i].pop >= 1 { flags.remove(at: i) }
                    continue
                }
                flags[i].phase += CGFloat(dt) * 2.0
                flags[i].y -= CGFloat(speed * dt)
                flags[i].x += flags[i].vx * CGFloat(dt) + sin(flags[i].phase) * 0.3
                let r = flags[i].r
                if flags[i].x < r { flags[i].x = r; flags[i].vx = abs(flags[i].vx) }
                if flags[i].x > size.width - r { flags[i].x = size.width - r; flags[i].vx = -abs(flags[i].vx) }
                // Escaped the top — no penalty; just recycle. Keep the target findable.
                if flags[i].y < -r {
                    let wasTarget = flags[i].country.name == current.name
                    flags.remove(at: i)
                    if wasTarget { spawnCountry(current) }
                }
            }
        }
        stepEffects(dt)
        return flags.count
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
        // A few flags already up, including the current target so it's there from frame one.
        spawnCountry(current, atY: size.height * 0.55)
        for k in 0..<3 {
            spawnOne(atY: size.height * CGFloat(0.62 + Double(k) * 0.13))
        }
    }

    private func spawnOne(atY: CGFloat? = nil) {
        // ~45% of spawns are the current target so it's always findable.
        if Double.random(in: 0..<1) < 0.45 {
            spawnCountry(current, atY: atY)
        } else {
            spawnCountry(Geo.countries.randomElement() ?? current, atY: atY)
        }
    }

    private func spawnCountry(_ c: GeoCountry, atY: CGFloat? = nil) {
        guard size.width > 0 else { return }
        let r = radius()
        let x = CGFloat.random(in: (r + 8)...(max(r + 9, size.width - r - 8)))
        flags.append(FFFlag(x: x, y: atY ?? (size.height + r), r: r,
                            vx: CGFloat.random(in: -10...10),
                            phase: CGFloat.random(in: 0...6.28),
                            country: c))
    }

    private func setNewTarget() {
        var c = Geo.countries.randomElement() ?? current
        var guard0 = 0
        while c.name == current.name && Geo.countries.count > 1 && guard0 < 20 {
            c = Geo.countries.randomElement() ?? current; guard0 += 1
        }
        current = c
        DispatchQueue.main.async { [weak self] in self?.target = c }
        // Make sure the new target is on screen soon.
        spawnCountry(c)
        spawnCountry(c, atY: size.height * 0.8)
    }

    func tap(_ p: CGPoint) {
        guard simulating else { return }
        for i in flags.indices.reversed() {
            if flags[i].pop > 0 { continue }
            let f = flags[i]
            let dx = p.x - f.x, dy = p.y - f.y
            let hit = f.r + 12
            if dx * dx + dy * dy <= hit * hit {
                if f.country.name == current.name {
                    combo += 1
                    let pts = combo
                    score += pts; den += pts
                    flags[i].pop = 0.001
                    burst(f.x, f.y, Lu.mint, 12)
                    floaters.append(FFFloater(x: f.x, y: f.y - f.r, text: "+\(pts)", life: 1, hex: Lu.gold))
                    Haptics.tap(0.5 + Double(combo) * 0.06)
                    setNewTarget()
                } else {
                    combo = 0
                    flags[i].pop = 0.001
                    burst(f.x, f.y, Lu.coral, 8)
                    floaters.append(FFFloater(x: f.x, y: f.y - f.r, text: f.country.name, life: 1, hex: Lu.coral))
                    shake = 0.28
                    Haptics.error()
                    DispatchQueue.main.async { [weak self] in
                        guard let self, self.simulating else { return }
                        self.hearts -= 1
                        if self.hearts <= 0 { self.triggerGameOver("Out of hearts!") }
                    }
                }
                return
            }
        }
    }

    private func burst(_ x: CGFloat, _ y: CGFloat, _ hex: UInt, _ n: Int) {
        for _ in 0..<n {
            let a = Double.random(in: 0..<6.28), sp = Double.random(in: 60...240)
            particles.append(FFParticle(x: x, y: y, vx: CGFloat(cos(a) * sp), vy: CGFloat(sin(a) * sp - 40),
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
            let m = shake / 0.34 * 14
            ctx.translateBy(x: CGFloat.random(in: -m...m), y: CGFloat.random(in: -m...m))
        }
        for f in flags {
            let grow: CGFloat = f.pop > 0 ? 1 + f.pop * 0.6 : 1
            let r = f.r * grow
            let alpha: Double = f.pop > 0 ? Double(1 - f.pop) : 1
            let rect = CGRect(x: f.x - r, y: f.y - r, width: r * 2, height: r * 2)
            ctx.opacity = alpha * 0.92
            ctx.fill(Path(ellipseIn: rect), with: .color(Color(hex: 0xfef6e9)))
            ctx.opacity = alpha * 0.6
            ctx.stroke(Path(ellipseIn: rect), with: .color(Color(hex: Lu.line)), lineWidth: 3)
            ctx.opacity = alpha
            let t = ctx.resolve(Text(f.country.flag).font(.system(size: r * 1.25)))
            ctx.draw(t, at: CGPoint(x: f.x, y: f.y))
        }
        for p in particles {
            ctx.opacity = Double(max(0, p.life))
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - p.r, y: p.y - p.r, width: p.r * 2, height: p.r * 2)),
                     with: .color(Color(hex: p.hex)))
        }
        for fl in floaters {
            ctx.opacity = Double(max(0, fl.life))
            let t = ctx.resolve(Text(fl.text).font(luFont(20)).foregroundColor(Color(hex: fl.hex)))
            ctx.draw(t, at: CGPoint(x: fl.x, y: fl.y))
        }
        ctx.opacity = 1
    }
}

struct FlagFrenzyView: View {
    let onClose: () -> Void
    @StateObject private var game = FlagFrenzyEngine()

    var body: some View {
        ZStack {
            LudusBackground().ignoresSafeArea()
            TimelineView(.animation) { tl in
                Canvas { ctx, sz in
                    game.advance(to: tl.date, size: sz)
                    game.render(context: &ctx, size: sz)
                }
                .gesture(SpatialTapGesture().onEnded { ev in game.tap(ev.location) })
            }
            .ignoresSafeArea()

            VStack(spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    Color.clear.frame(width: 38, height: 38)
                    StatPill(label: "SCORE", value: "\(game.score)", valueHex: Lu.gold)
                    Spacer(minLength: 4)
                    HeartsRow(hearts: game.hearts)
                    Spacer(minLength: 4)
                    StatPill(label: "DENARII", value: "\(game.den)", valueHex: Lu.silver)
                }
                // The flag to find — shown big so it's pure matching.
                VStack(spacing: 2) {
                    Text("FIND THIS FLAG").font(luFont(11, .heavy)).tracking(2).foregroundStyle(Color(hex: Lu.inkDim))
                    HStack(spacing: 10) {
                        Text(game.target.flag).font(.system(size: 40))
                        Text(game.target.name).font(luFont(22)).foregroundStyle(Color(hex: Lu.ink))
                            .lineLimit(1).minimumScaleFactor(0.6)
                    }
                }
                .padding(.horizontal, 18).padding(.vertical, 10)
                .background(luPanelShape(16))
                .id(game.target.id)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: game.target.id)

                Spacer()
            }
            .padding(.horizontal, 12).padding(.top, 4)
            .allowsHitTesting(false)

            VStack {
                HStack { LudusCloseButton(action: onClose); Spacer() }
                Spacer()
            }
            .padding(.horizontal, 12).padding(.top, 4)

            if game.combo >= 2 && game.phase == .playing {
                Text("COMBO ×\(game.combo)!")
                    .font(luFont(24)).foregroundStyle(Color(hex: Lu.mint))
                    .padding(.top, 150).frame(maxHeight: .infinity, alignment: .top)
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
