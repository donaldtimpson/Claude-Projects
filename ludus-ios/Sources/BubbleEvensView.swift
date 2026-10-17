import SwiftUI

// MARK: - Bubble Evens  (Number Crunchers · pop-the-target)
//
// Bubbles rise; the RULE banner says which ones to pop. Pop a match to score; popping a
// non-match is a miss — and the game says why ("7 is odd") and rings the bubbles that DO match.
// A bubble that reaches the banner's bottom edge has escaped and fades out there (so nothing is
// ever tappable under the banner or the HUD's ✕); an escaped match costs a heart from III on,
// but is free at I–II (like Flag Frenzy). The rule changes every level:
//   I     pop the 🍎 (pictures — no numbers)
//   II    even numbers to 10, with dots in pairs (every dot has a partner = even)
//   III   even numbers to 20
//   IV    the 5s (to 50)
//   V     the 3s (to 36)
//   VI    primes (to 30)
//   VII   factors of 12–24
//   VIII+ a mix: the 6s–9s, primes to 50, factors of 30–60; faster each level (capped)
// Big, slow bubbles at first; smaller and quicker as the levels climb.

/// What a bubble says: a picture (level I) or a number.
private struct BERule {
    let title: String            // "EVEN numbers"
    let hint: String             // "every dot has a partner"
    let targets: [String]
    let others: [String]
    var picture = false
    var dots = false             // draw counting dots (in pairs) under the numeral
    /// Why a tapped non-match is wrong / why an escaped match was right.
    let whyNot: (String) -> String
    let whyYes: (String) -> String
    /// Independent recomputation of the rule (DEBUG self-check).
    let test: (String) -> Bool
}

private func beIsPrime(_ n: Int) -> Bool {
    guard n >= 2 else { return false }
    var d = 2
    while d * d <= n { if n % d == 0 { return false }; d += 1 }
    return true
}

private func beRuleNumbers(title: String, hint: String, range: ClosedRange<Int>, dots: Bool = false,
                           _ pred: @escaping (Int) -> Bool,
                           whyNot: @escaping (Int) -> String, whyYes: @escaping (Int) -> String) -> BERule {
    BERule(title: title, hint: hint,
           targets: range.filter(pred).map(String.init), others: range.filter { !pred($0) }.map(String.init),
           dots: dots,
           whyNot: { whyNot(Int($0) ?? 0) }, whyYes: { whyYes(Int($0) ?? 0) },
           test: { Int($0).map(pred) ?? false })
}

private func beMultiples(_ k: Int, upTo hi: Int, hint: String) -> BERule {
    beRuleNumbers(title: "Pop the \(k)s", hint: hint, range: 1...hi, { $0 % k == 0 },
                  whyNot: { "\($0) is not in the \(k)s" }, whyYes: { "\($0) = \(k) × \($0 / k)" })
}

private func bePrimes(upTo hi: Int) -> BERule {
    beRuleNumbers(title: "Pop the PRIMES", hint: "only 1 × itself", range: 2...hi, beIsPrime,
                  whyNot: { n in
                      let f = (2...n).first { n % $0 == 0 } ?? n
                      return "\(n) = \(f) × \(n / f)"
                  },
                  whyYes: { "\($0) is prime!" })
}

private func beFactors(of big: Int) -> BERule {
    beRuleNumbers(title: "Factors of \(big)", hint: "numbers that go into \(big)", range: 1...big, { big % $0 == 0 },
                  whyNot: { "\($0) doesn't go into \(big)" }, whyYes: { "\($0) × \(big / $0) = \(big)" })
}

private let bePictureSets: [(String, [String])] = [("🍎", ["🍌", "🍇"]), ("⭐️", ["🌙", "☁️"]), ("🐟", ["🐸", "🐢"])]

private func beRule(_ level: Int) -> BERule {
    switch level {
    case 1:
        let (pic, rest) = bePictureSets.randomElement()!
        return BERule(title: "Pop the \(pic)", hint: "only the \(pic)", targets: [pic], others: rest, picture: true,
                      whyNot: { _ in "Only \(pic)!" }, whyYes: { _ in "\(pic) got away!" }, test: { $0 == pic })
    case 2:
        return beRuleNumbers(title: "Pop EVEN numbers", hint: "every dot has a partner", range: 1...10, dots: true,
                             { $0 % 2 == 0 }, whyNot: { "\($0) is odd" }, whyYes: { "\($0) is even!" })
    case 3:
        return beRuleNumbers(title: "Pop EVEN numbers", hint: "they end in 0 2 4 6 8", range: 1...20,
                             { $0 % 2 == 0 }, whyNot: { "\($0) is odd" }, whyYes: { "\($0) is even!" })
    case 4: return beMultiples(5, upTo: 50, hint: "5  10  15  20 …")
    case 5: return beMultiples(3, upTo: 36, hint: "3  6  9  12 …")
    case 6: return bePrimes(upTo: 30)
    case 7: return beFactors(of: [12, 16, 18, 20, 24].randomElement()!)
    default:
        switch Int.random(in: 0..<3) {
        case 0: let k = Int.random(in: 6...9); return beMultiples(k, upTo: k * 10, hint: "\(k)  \(2 * k)  \(3 * k) …")
        case 1: return bePrimes(upTo: 50)
        default: return beFactors(of: [30, 36, 48, 60].randomElement()!)
        }
    }
}

private struct BEBubble {
    var x: CGFloat; var y: CGFloat; var r: CGFloat; var vx: CGFloat; var phase: CGFloat
    var text: String; var target: Bool; var hex: UInt
    var pop: CGFloat = 0          // 0 alive; 0→1 while bursting
    var fade: CGFloat = 0         // 0 alive; 0→1 while fading away (rule changed)
    var glow: CGFloat = 0         // seconds left of the "this one!" ring after a miss
    var escaped = false           // reached the banner: fades out in place instead of drifting on
    var alive: Bool { pop == 0 && fade == 0 }
}
private struct BEParticle { var x, y, vx, vy, life, r: CGFloat; var hex: UInt }
private struct BEFloater { var x, y: CGFloat; var text: String; var life: CGFloat; var hex: UInt; var size: CGFloat }

@MainActor
private final class BubbleEvensEngine: ArcadeModel {
    @Published private(set) var rule = beRule(1)

    private(set) var bubbles: [BEBubble] = []
    private var particles: [BEParticle] = []
    private var floaters: [BEFloater] = []
    private var size: CGSize = .zero
    private var spawnAcc = 0.0
    private var lastTick: Date?
    private var shake: CGFloat = 0
    private var needsSeed = false
    /// Canvas y of the rule banner's bottom edge: bubbles escape (and fade) when their top reaches it.
    var ceiling: CGFloat = 0

    init() {
        super.init(key: GameID.bubbleEvens.rawValue)
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { Self.selfCheck() }
        #endif
    }

    // Level tuning: rise speed (pt/s on a 760-pt-tall field), seconds between spawns, radius share
    // of the width, most bubbles on screen at once.
    private var speed: Double { level <= 7 ? [60, 62, 68, 72, 76, 80, 84][level - 1] : min(120, 88 + Double(level - 8) * 4) }
    private var interval: Double { level <= 7 ? [2.0, 1.9, 1.7, 1.55, 1.45, 1.35, 1.25][level - 1] : max(0.85, 1.2 - Double(level - 8) * 0.05) }
    private var radius: CGFloat {
        let share: CGFloat = level <= 2 ? 0.135 : level <= 5 ? 0.12 : 0.11
        return max(34, min(58, size.width * share))
    }
    private var cap: Int { level <= 2 ? 6 : level <= 5 ? 8 : 10 }

    override func onBegin() {
        bubbles.removeAll(); particles.removeAll(); floaters.removeAll()
        spawnAcc = 0; lastTick = nil; shake = 0
        rule = beRule(level)
        needsSeed = true
    }

    override func onLevelUp() {
        rule = beRule(level)
        // The rule changed: the old bubbles drift off harmlessly.
        for i in bubbles.indices where bubbles[i].alive { bubbles[i].fade = 0.001 }
        spawnAcc = interval * 0.6
    }

    // MARK: Simulation (runs inside the Canvas draw pass — defer any @Published writes)

    func advance(to date: Date, size: CGSize) {
        self.size = size
        guard phase == .playing else { lastTick = nil; return }
        guard let prev = lastTick else { lastTick = date; return }
        lastTick = date
        let dt = min(max(date.timeIntervalSince(prev), 0), 0.05)

        if needsSeed, size.width > 0 {
            needsSeed = false
            // Start with bubbles already partway up so the field is alive at the whistle.
            for k in 0..<3 { spawnOne(atY: size.height * CGFloat(0.55 + Double(k) * 0.16)) }
        }
        if !dying {
            spawnAcc += dt
            if spawnAcc >= interval {
                spawnAcc = 0
                if bubbles.filter(\.alive).count < cap { spawnOne() }
            }
        }

        let rise = CGFloat(speed * dt) * size.height / 760
        for i in bubbles.indices.reversed() {
            if bubbles[i].pop > 0 {
                bubbles[i].pop += CGFloat(dt) * 6
                if bubbles[i].pop >= 1 { bubbles.remove(at: i) }
                continue
            }
            if bubbles[i].fade > 0 {
                bubbles[i].fade += CGFloat(dt) * 2.5
                if !bubbles[i].escaped { bubbles[i].y -= rise * 2 }
                if bubbles[i].fade >= 1 { bubbles.remove(at: i) }
                continue
            }
            if bubbles[i].glow > 0 { bubbles[i].glow -= CGFloat(dt) }
            bubbles[i].phase += CGFloat(dt) * 2.2
            bubbles[i].y -= rise
            bubbles[i].x += bubbles[i].vx * CGFloat(dt) + sin(bubbles[i].phase) * 0.3
            let r = bubbles[i].r
            if bubbles[i].x < r { bubbles[i].x = r; bubbles[i].vx = abs(bubbles[i].vx) }
            if bubbles[i].x > size.width - r { bubbles[i].x = size.width - r; bubbles[i].vx = -abs(bubbles[i].vx) }
            if bubbles[i].y - r <= ceiling {
                bubbles[i].escaped = true; bubbles[i].fade = 0.001
                if bubbles[i].target { escaped(bubbles[i]) }
            }
        }
        stepEffects(dt)
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
            floaters[i].life -= CGFloat(dt) * 0.75
            floaters[i].y -= CGFloat(30 * dt)
            if floaters[i].life <= 0 { floaters.remove(at: i) }
        }
        if shake > 0 { shake -= CGFloat(dt) }
    }

    private func spawnOne(atY: CGFloat? = nil) {
        guard size.width > 0 else { return }
        let r = radius
        let target = Double.random(in: 0..<1) < 0.5
        guard let text = (target ? rule.targets : rule.others).randomElement() else { return }
        let x = CGFloat.random(in: r...(max(r + 1, size.width - r)))
        bubbles.append(BEBubble(x: x, y: atY ?? (size.height + r), r: r,
                                vx: CGFloat.random(in: -12...12), phase: CGFloat.random(in: 0...6.28),
                                text: text, target: target,
                                hex: (rule.picture ? Lu.bubbleHexes.filter { $0 != Lu.coral } : Lu.bubbleHexes).randomElement() ?? Lu.sky))
    }

    /// A match reached the banner: say what it was — a miss from III on, free at I–II.
    private func escaped(_ b: BEBubble) {
        guard !dying else { return }
        let y = max(ceiling + 34, 240)
        if level <= 2 {
            floaters.append(BEFloater(x: min(max(b.x, 90), size.width - 90), y: y,
                                      text: rule.whyYes(b.text), life: 1.2, hex: Lu.inkDim, size: 22))
            return
        }
        shake = 0.22
        floaters.append(BEFloater(x: min(max(b.x, 90), size.width - 90), y: y,
                                  text: rule.whyYes(b.text), life: 1.4, hex: Lu.coral, size: 26))
        DispatchQueue.main.async { [weak self] in self?.miss(reason: "A bubble got away!", delay: 1.0) }
    }

    // MARK: Input

    func tap(_ p: CGPoint) {
        guard phase == .playing, !dying else { return }
        guard let i = bubbles.indices.reversed().first(where: { i in
            let b = bubbles[i]
            let dx = p.x - b.x, dy = p.y - b.y
            return b.alive && dx * dx + dy * dy <= (b.r + 10) * (b.r + 10)
        }) else { return }
        let b = bubbles[i]
        bubbles[i].pop = 0.001
        if b.target {
            burst(b.x, b.y, b.hex, 12)
            hit()
            floaters.append(BEFloater(x: b.x, y: b.y - b.r, text: "+\(min(max(combo, 1), 5))", life: 1, hex: Lu.gold, size: 28))
        } else {
            burst(b.x, b.y, Lu.coral, 8)
            shake = 0.28
            floaters.append(BEFloater(x: min(max(b.x, 100), size.width - 100), y: max(b.y - b.r, 240),
                                      text: rule.whyNot(b.text), life: 1.4, hex: Lu.coral, size: 26))
            // Teach: ring the bubbles that DO match.
            for j in bubbles.indices where bubbles[j].alive && bubbles[j].target { bubbles[j].glow = 1.6 }
            miss(reason: "Out of hearts!", delay: 1.2)
        }
    }

    /// DEBUG autoplayer: tap the highest matching bubble (or, when wrong, a non-match).
    override func botAct(correct: Bool) {
        let live = bubbles.filter { $0.alive && $0.y > 120 && $0.y < size.height - $0.r }
        let pick = live.filter { $0.target == correct }.min { $0.y < $1.y }
        if let b = pick { tap(CGPoint(x: b.x, y: b.y)) }
    }

    private func burst(_ x: CGFloat, _ y: CGFloat, _ hex: UInt, _ n: Int) {
        for _ in 0..<n {
            let a = Double.random(in: 0..<6.28), sp = Double.random(in: 60...240)
            particles.append(BEParticle(x: x, y: y, vx: CGFloat(cos(a) * sp), vy: CGFloat(sin(a) * sp - 40),
                                        life: 1, r: CGFloat.random(in: 3...7), hex: hex))
        }
    }

    // MARK: Drawing

    func render(context ctx: inout GraphicsContext, size: CGSize) {
        if shake > 0 {
            let m = shake / 0.3 * 12
            ctx.translateBy(x: CGFloat.random(in: -m...m), y: CGFloat.random(in: -m...m))
        }
        for b in bubbles {
            let grow: CGFloat = b.pop > 0 ? 1 + b.pop * 0.6 : 1
            let r = b.r * grow
            let alpha: Double = b.pop > 0 ? Double(1 - b.pop) : b.fade > 0 ? Double(1 - b.fade) * 0.6 : 1
            let rect = CGRect(x: b.x - r, y: b.y - r, width: r * 2, height: r * 2)
            if b.glow > 0 {
                ctx.opacity = Double(min(1, b.glow))
                ctx.stroke(Path(ellipseIn: rect.insetBy(dx: -7, dy: -7)), with: .color(Color(hex: Lu.gold)), lineWidth: 5)
            }
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
            if rule.picture && Int(b.text) == nil {
                ctx.draw(ctx.resolve(Text(b.text).font(.system(size: r * 1.05))), at: CGPoint(x: b.x, y: b.y + r * 0.04))
            } else if rule.dots, let n = Int(b.text) {
                let t = ctx.resolve(Text(b.text).font(luFont(r * 0.72)).foregroundColor(Color(hex: Lu.inkDark)))
                ctx.draw(t, at: CGPoint(x: b.x, y: b.y - r * 0.2))
                drawCountingDots(ctx, n: n, group: 2, at: CGPoint(x: b.x, y: b.y + r * 0.45), r: r, color: Color(hex: Lu.inkDark))
            } else {
                let fs = b.text.count >= 2 ? r * 0.8 : r * 0.92
                let t = ctx.resolve(Text(b.text).font(luFont(fs)).foregroundColor(Color(hex: Lu.inkDark)))
                ctx.draw(t, at: CGPoint(x: b.x, y: b.y))
            }
        }
        for p in particles {
            ctx.opacity = Double(max(0, p.life))
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - p.r, y: p.y - p.r, width: p.r * 2, height: p.r * 2)),
                     with: .color(Color(hex: p.hex)))
        }
        for f in floaters {
            ctx.opacity = Double(max(0, min(1, f.life)))
            let t = ctx.resolve(Text(f.text).font(luFont(f.size)).foregroundColor(Color(hex: f.hex)))
            let w = t.measure(in: size).width + 24
            let box = CGRect(x: f.x - w / 2, y: f.y - f.size * 0.75, width: w, height: f.size * 1.5)
            if f.hex == Lu.coral {
                ctx.fill(Path(roundedRect: box, cornerRadius: 12), with: .color(Color(hex: Lu.ground).opacity(0.85)))
            }
            ctx.draw(t, at: CGPoint(x: f.x, y: f.y))
        }
        ctx.opacity = 1
    }

    #if DEBUG
    /// Every level's rule must split its bubbles cleanly: each label is a match or not, never
    /// both, and the match flag agrees with an independent recomputation (n % 2, trial-division
    /// primality, N % n …). Run with LUDUS_SELFCHECK=1; prints one line per level.
    static func selfCheck() {
        for lv in 1...10 {
            for _ in 0..<60 {
                let r = beRule(lv)
                precondition(!r.targets.isEmpty && !r.others.isEmpty, "L\(lv) \(r.title): empty side")
                precondition(Set(r.targets).isDisjoint(with: r.others), "L\(lv) \(r.title): overlap")
                for t in r.targets { precondition(r.test(t), "L\(lv) \(r.title): \(t) should match") }
                for o in r.others { precondition(!r.test(o), "L\(lv) \(r.title): \(o) should not match") }
                let indep: (Int) -> Bool
                if r.title.contains("EVEN") { indep = { $0 % 2 == 0 } }
                else if r.title.contains("PRIMES") { indep = { n in n > 1 && !(2..<n).contains { n % $0 == 0 } } }
                else if r.title.hasPrefix("Factors of "), let big = Int(r.title.dropFirst(11)) { indep = { big % $0 == 0 } }
                else if r.title.hasPrefix("Pop the "), let k = Int(r.title.dropFirst(8).dropLast()) { indep = { $0 % k == 0 } }
                else { continue }   // level I pictures
                for t in r.targets { precondition(indep(Int(t)!), "L\(lv) \(r.title): \(t) wrongly a target") }
                for o in r.others { precondition(!indep(Int(o)!), "L\(lv) \(r.title): \(o) wrongly a non-target") }
            }
            print("SELFCHECK bubbleEvens L\(lv) ok — e.g. \(beRule(lv).title)")
        }
    }
    #endif
}

/// Draws `n` counting dots: in pairs (`group` 2 → two-high columns, an odd one left alone) or in
/// rows of `group` (e.g. fives). Fits inside a disc of radius `r`.
func drawCountingDots(_ ctx: GraphicsContext, n: Int, group: Int, at c: CGPoint, r: CGFloat, color: Color) {
    guard n > 0 else { return }
    let cols = group == 2 ? (n + 1) / 2 : min(n, group)
    let rows = group == 2 ? min(n, 2) : (n + group - 1) / group
    let s = min(r * 0.26, r * 1.3 / CGFloat(max(cols, 1)), r * 0.72 / CGFloat(max(rows, 1)))
    let dr = s * 0.4
    for k in 0..<n {
        let (col, row) = group == 2 ? (k / 2, k % 2) : (k % group, k / group)
        let x = c.x + (CGFloat(col) - CGFloat(cols - 1) / 2) * s
        let y = c.y + (CGFloat(row) - CGFloat(rows - 1) / 2) * s
        ctx.fill(Path(ellipseIn: CGRect(x: x - dr, y: y - dr, width: dr * 2, height: dr * 2)), with: .color(color))
    }
}

struct BubbleEvensView: View {
    let onClose: () -> Void
    @StateObject private var game = BubbleEvensEngine()
    @State private var canvasTop: CGFloat = 0
    @State private var bannerBottom: CGFloat = 0

    var body: some View {
        ArcadeShell(model: game,
                    spec: GameID.bubbleEvens.spec ?? GameSpec(title: "Bubble Evens", mechanic: "pop", premise: "", game: .bubbleEvens),
                    accent: Lu.sky, onClose: onClose) {
            ZStack(alignment: .top) {
                // Step AND draw inside the Canvas, keyed to the timeline clock (advancing outside
                // the Canvas silently froze the render). The clock stops unless a run is on.
                TimelineView(.animation(minimumInterval: nil, paused: game.phase != .playing)) { tl in
                    Canvas { ctx, sz in
                        game.advance(to: tl.date, size: sz)
                        game.render(context: &ctx, size: sz)
                    }
                    .gesture(SpatialTapGesture().onEnded { ev in game.tap(ev.location) })
                    .background(GeometryReader { g in
                        Color.clear.onAppear { canvasTop = g.frame(in: .global).minY }
                            .onChange(of: g.frame(in: .global).minY) { canvasTop = $0 }
                    })
                }
                .ignoresSafeArea()

                BERuleBanner(rule: game.rule, combo: game.combo)
                    .background(GeometryReader { g in
                        Color.clear.onAppear { bannerBottom = g.frame(in: .global).maxY }
                            .onChange(of: g.frame(in: .global).maxY) { bannerBottom = $0 }
                    })
                    .padding(.top, 62)
                    .opacity(game.phase == .playing ? 1 : 0)
                    .allowsHitTesting(false)
            }
            .onChange(of: bannerBottom - canvasTop) { game.ceiling = max(0, $0) }
        }
    }
}

/// The rule for this level, big, under the HUD.
private struct BERuleBanner: View {
    let rule: BERule
    let combo: Int
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Text("👆").font(.system(size: 30))
                if rule.picture, let pic = rule.targets.first {
                    Text("POP").font(luFont(26)).foregroundStyle(Color(hex: Lu.ink))
                    Text(pic).font(.system(size: 44))
                } else {
                    Text(rule.title).font(luFont(26)).foregroundStyle(Color(hex: Lu.ink))
                        .lineLimit(1).minimumScaleFactor(0.6)
                }
            }
            if !rule.picture {
                Text(rule.hint).font(luFont(15, .bold)).foregroundStyle(Color(hex: Lu.inkDim))
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 8)
        .background(luPanelShape(18).opacity(0.92))
        .id(rule.title + rule.hint)
        .transition(.scale(scale: 0.8).combined(with: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: rule.title)
        .overlay(alignment: .bottom) {
            if combo >= 2 {
                Text("COMBO ×\(combo)!").font(luFont(18)).foregroundStyle(Color(hex: Lu.mint))
                    .id(combo).offset(y: 26)
                    .transition(.scale(scale: 1.25).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: combo)
    }
}
