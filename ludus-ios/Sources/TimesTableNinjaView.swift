import SwiftUI

// MARK: - Times Table Ninja  (Number Crunchers · slash)
//
// Night in the villa's moonlit garden. Fruit — oranges, apples, plums, lemons, melons — is tossed
// up past the lanterns, each with a number on it. The banner names a times table ("Slice the 3s");
// swipe (or just tap) the fruit in that table: it splits into two halves and splashes juice. Slicing
// a wrong one (or a bomb) is a miss: the game says why ("7 is not in the 2s") and rings the fruit
// that IS right. Fruit that falls unsliced is fine — no penalty. The table changes every 3 slices
// (the fruit in the air puffs away so nothing changes meaning mid-flight).
//
// Strand: skip counting → times tables → division facts. Tuned off `d` (GameKit):
//   • which table: `tier` over 2s → 5s → 10s → 3s → 4s → 6s → 7s → 8s → 9s → 11s → 12s → ÷ facts
//     ("Make 8": slice 56÷7). Each new table fades in; the older ones stay as review;
//   • the table's opening sequence is shown while it's new; counting dots for the 2s / 5s early on;
//   • products reach further (×5 → ×12); gravity, launch rate and double launches ramp up; bombs
//     fade in from ~IV; fruit shrinks a little.

private struct TTNFruit {
    var x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat, r: CGFloat
    var spin: CGFloat, spinV: CGFloat
    var val: Int                 // the number (or the quotient, for a ÷ fact)
    var label: String            // what's written on it ("14", "56÷7")
    var bomb: Bool
    var kind: Int                // which fruit it is
    var pop: CGFloat = 0         // 0 alive; 0→1 while bursting (wrong ones)
    var fade: CGFloat = 0        // 0 alive; 0→1 while puffing away (table changed)
    var glow: CGFloat = 0        // seconds of "this one!" ring after a miss
    var alive: Bool { pop == 0 && fade == 0 }
}
/// A sliced half flying off.
private struct TTNHalf { var x, y, vx, vy, angle, spinV, r: CGFloat; var kind: Int; var life: CGFloat }
private struct TTNParticle { var x, y, vx, vy, life, r: CGFloat; var hex: UInt }
private struct TTNSplat { var x, y, r: CGFloat; var hex: UInt; var life: CGFloat }
private struct TTNFloater { var x, y: CGFloat; var text: String; var life: CGFloat; var hex: UInt; var size: CGFloat }
private struct TTNBladePoint { var p: CGPoint; var life: CGFloat }

/// Skin / flesh colours of the fruit kinds: orange, apple, plum, lemon, lime, peach.
private let ttnSkins: [(skin: UInt, flesh: UInt)] = [
    (0xf28c28, 0xffc56b), (0xd8342c, 0xfbeed0), (0x7b3fa0, 0xf2c94c), (0xf4d03f, 0xfdf2a6), (0x6fb33c, 0xd6f09a), (0xf4a07a, 0xffd8a8),
]

/// The tables in the order they fade in, and the difficulty each starts at. The last entry is the
/// ÷ mode ("Make q").
private let ttnTables = [2, 5, 10, 3, 4, 6, 7, 8, 9, 11, 12, 0]
private let ttnStarts: [Double] = [1, 2, 2.8, 3.6, 4.3, 5.0, 5.6, 6.2, 6.8, 7.4, 7.9, 8.5]

/// A fruit for `target`: (value, label). Multiples: a multiple of `target` up to `maxMul`× it,
/// or a non-multiple in the same range. Division: a÷b = q whose quotient is `target` (right) or not.
private func ttnMakeFruit(division: Bool, target: Int, maxMul: Int, right: Bool) -> (val: Int, label: String) {
    if division {
        let q = right ? target : (1...max(maxMul, target + 1)).filter { $0 != target }.randomElement()!
        let b = Int.random(in: 2...maxMul)
        return (q, "\(q * b)÷\(b)")
    }
    let n = right ? target * Int.random(in: 1...maxMul)
                  : (1...(target * maxMul)).filter { $0 % target != 0 }.randomElement()!
    return (n, "\(n)")
}

@MainActor
private final class TTNEngine: ArcadeModel {
    @Published private(set) var target = 2
    @Published private(set) var division = false
    @Published private(set) var tableIndex = 0

    private var fruit: [TTNFruit] = []
    private var halves: [TTNHalf] = []
    private var particles: [TTNParticle] = []
    private var splats: [TTNSplat] = []
    private var floaters: [TTNFloater] = []
    private var blade: [TTNBladePoint] = []
    private var size: CGSize = .zero
    private var spawnAcc = 0.0
    private var lastTick: Date?
    private var shake: CGFloat = 0
    private var swiping = false
    private var hitsOnTarget = 0
    private var swipeSound = false

    init() {
        super.init(key: GameID.timesTableNinja.rawValue)
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { Self.selfCheck() }
        #endif
    }

    // Continuous tuning: gravity (pt/s² on an 800-pt field), seconds between launches, fruit radius.
    private var gravity: CGFloat { CGFloat(ramp(200, 520, to: 9.5)) }
    private var interval: Double { ramp(1.7, 0.8, to: 9.5) }
    private var radius: CGFloat { max(36, min(56, size.width * CGFloat(ramp(0.135, 0.108, to: 6)))) }
    var maxMul: Int { rampInt(5, 12, to: 8) }
    private var bombChance: Double { ramp(0, 0.1, from: 4, to: 9) }
    /// Show the opening sequence while the table is new to this run's difficulty.
    var hint: Bool { !division && d < ttnStarts[tableIndex] + 1.4 }
    private var showDots: Bool { !division && (target == 2 || target == 5) && d < 2.7 }

    override func onBegin() {
        fruit.removeAll(); halves.removeAll(); particles.removeAll(); splats.removeAll(); floaters.removeAll(); blade.removeAll()
        spawnAcc = 0.8; lastTick = nil; shake = 0; swiping = false
        hitsOnTarget = 0
        pickTarget(avoidSame: false)
    }

    /// Choose the next table (or ÷ answer) by the difficulty tiers.
    private func pickTarget(avoidSame: Bool) {
        var idx = tier(ttnStarts, keep: 0.15)
        var tries = 0
        while avoidSame && idx == tableIndex && tries < 4 && d > 2 { idx = tier(ttnStarts, keep: 0.15); tries += 1 }
        tableIndex = idx
        if ttnTables[idx] == 0 {
            division = true
            var q = Int.random(in: 2...9)
            while avoidSame && q == target && tries < 8 { q = Int.random(in: 2...9); tries += 1 }
            target = q
        } else {
            division = false
            target = ttnTables[idx]
        }
    }

    /// New table: the fruit in the air puffs away, so nothing changes meaning mid-flight.
    private func switchTarget() {
        hitsOnTarget = 0
        let old = (target, division)
        pickTarget(avoidSame: true)
        if old != (target, division) {
            for i in fruit.indices where fruit[i].alive { fruit[i].fade = 0.001 }
            spawnAcc = interval * 0.5
            Sfx.play(.sparkle, volume: 0.5)
        }
    }

    // MARK: Simulation (inside the Canvas draw pass — defer @Published writes)

    func advance(to date: Date, size: CGSize) {
        self.size = size
        guard phase == .playing else { lastTick = nil; return }
        guard let prev = lastTick else { lastTick = date; return }
        lastTick = date
        let dt = min(max(date.timeIntervalSince(prev), 0), 0.05)
        let g = gravity * size.height / 800

        if !dying {
            spawnAcc += dt
            if spawnAcc >= interval {
                spawnAcc = 0
                spawnOne()
                if chance(0.35, from: 5, to: 9.5) { spawnOne() }
            }
        }
        for i in fruit.indices.reversed() {
            if fruit[i].pop > 0 {
                fruit[i].pop += CGFloat(dt) * 5.5
                if fruit[i].pop >= 1 { fruit.remove(at: i) }
                continue
            }
            if fruit[i].fade > 0 {
                fruit[i].fade += CGFloat(dt) * 2.5
                if fruit[i].fade >= 1 { fruit.remove(at: i) }
                continue
            }
            if fruit[i].glow > 0 { fruit[i].glow -= CGFloat(dt) }
            fruit[i].vy += g * CGFloat(dt)
            fruit[i].x += fruit[i].vx * CGFloat(dt)
            fruit[i].y += fruit[i].vy * CGFloat(dt)
            fruit[i].spin += fruit[i].spinV * CGFloat(dt)
            if fruit[i].vy > 0 && fruit[i].y > size.height + fruit[i].r + 20 { fruit.remove(at: i) }   // fell: no penalty
        }
        for i in halves.indices.reversed() {
            halves[i].vy += g * 1.2 * CGFloat(dt)
            halves[i].x += halves[i].vx * CGFloat(dt)
            halves[i].y += halves[i].vy * CGFloat(dt)
            halves[i].angle += halves[i].spinV * CGFloat(dt)
            halves[i].life -= CGFloat(dt) * 0.8
            if halves[i].life <= 0 || halves[i].y > size.height + 80 { halves.remove(at: i) }
        }
        for i in particles.indices.reversed() {
            particles[i].life -= CGFloat(dt) * 1.7
            if particles[i].life <= 0 { particles.remove(at: i); continue }
            particles[i].vy += CGFloat(420 * dt)
            particles[i].x += particles[i].vx * CGFloat(dt)
            particles[i].y += particles[i].vy * CGFloat(dt)
        }
        for i in splats.indices.reversed() {
            splats[i].life -= CGFloat(dt) * 0.6
            splats[i].y += CGFloat(10 * dt)
            if splats[i].life <= 0 { splats.remove(at: i) }
        }
        for i in floaters.indices.reversed() {
            floaters[i].life -= CGFloat(dt) * 0.75
            floaters[i].y -= CGFloat(28 * dt)
            if floaters[i].life <= 0 { floaters.remove(at: i) }
        }
        for i in blade.indices.reversed() {
            blade[i].life -= CGFloat(dt) * 6
            if blade[i].life <= 0 { blade.remove(at: i) }
        }
        if shake > 0 { shake -= CGFloat(dt) }
    }

    private func spawnOne() {
        guard size.width > 0, size.height > 0 else { return }
        let r = radius
        let g = gravity * size.height / 800
        let bomb = Double.random(in: 0..<1) < bombChance
        let right = !bomb && Double.random(in: 0..<1) < 0.58
        let (val, label) = ttnMakeFruit(division: division, target: target, maxMul: maxMul, right: right)
        let x0 = CGFloat.random(in: (size.width * 0.18)...(size.width * 0.82))
        let y0 = size.height + r
        let apex = size.height * CGFloat.random(in: 0.3...0.48)
        let vy = -sqrt(2 * g * (y0 - apex))
        let flight = 2 * -vy / g
        let land = CGFloat.random(in: (size.width * 0.15)...(size.width * 0.85))
        fruit.append(TTNFruit(x: x0, y: y0, vx: (land - x0) / flight, vy: vy, r: r,
                              spin: 0, spinV: CGFloat.random(in: -0.8...0.8),
                              val: val, label: label, bomb: bomb, kind: Int.random(in: 0..<ttnSkins.count)))
        Sfx.play(.whoosh, volume: 0.25)
    }

    // MARK: Blade (gesture-driven)

    func bladeMove(_ p: CGPoint) {
        if !swiping { swiping = true; swipeSound = false; blade.removeAll(keepingCapacity: true) }
        let prev = blade.last?.p ?? p          // a plain tap tests the touch point itself
        blade.append(TTNBladePoint(p: p, life: 1))
        if blade.count > 8 { blade.removeFirst(blade.count - 8) }
        if !swipeSound && hypot(p.x - prev.x, p.y - prev.y) > 18 { swipeSound = true; Sfx.play(.whoosh, volume: 0.4) }
        testSegment(prev, p)
    }

    func bladeEnd() { swiping = false }

    private func testSegment(_ a: CGPoint, _ b: CGPoint) {
        guard phase == .playing, !dying else { return }
        for i in fruit.indices.reversed() where i < fruit.count && fruit[i].alive {
            if ttnSegmentHitsCircle(a, b, CGPoint(x: fruit[i].x, y: fruit[i].y), fruit[i].r + 8) {
                let ang = atan2(b.y - a.y, b.x - a.x)
                slice(i, angle: a == b ? CGFloat.random(in: -0.4...0.4) : ang)
                if dying { return }
            }
        }
    }

    private func isRight(_ f: TTNFruit) -> Bool { division ? f.val == target : f.val % target == 0 }

    private func slice(_ i: Int, angle: CGFloat) {
        let f = fruit[i]
        if f.bomb {
            fruit[i].pop = 0.001
            burst(f.x, f.y, Lu.coral, 16)
            Sfx.play(.thud)
            wrong(at: f, text: "💥 BOOM!", reason: "Boom!")
        } else if isRight(f) {
            fruit.remove(at: i)
            // Two halves fly apart across the cut; juice splats on the night air.
            let nx = -sin(angle), ny = cos(angle)
            for s in [-1.0, 1.0] as [CGFloat] {
                halves.append(TTNHalf(x: f.x + nx * s * 4, y: f.y + ny * s * 4, vx: f.vx * 0.5 + nx * s * 120,
                                      vy: min(f.vy, 0) * 0.3 + ny * s * 120 - 60, angle: angle + (s < 0 ? .pi : 0),
                                      spinV: s * CGFloat.random(in: 2...4), r: f.r, kind: f.kind, life: 1))
            }
            splats.append(TTNSplat(x: f.x, y: f.y, r: f.r * 1.1, hex: ttnSkins[f.kind].flesh, life: 1))
            burst(f.x, f.y, ttnSkins[f.kind].flesh, 12)
            Sfx.play(.pop)
            let pts = min(combo + 1, 5)
            hitsOnTarget += 1
            let climbed = hit()
            floaters.append(TTNFloater(x: f.x, y: f.y - f.r, text: "+\(pts)", life: 1, hex: Lu.gold, size: 28))
            if !climbed && hitsOnTarget >= 3 && d >= 2 { switchTarget() }
        } else {
            fruit[i].pop = 0.001
            burst(f.x, f.y, Lu.coral, 10)
            let why = division ? "\(f.label) = \(f.val)" : "\(f.val) is not in the \(target)s"
            wrong(at: f, text: why, reason: "Out of hearts!")
        }
    }

    private func wrong(at f: TTNFruit, text: String, reason: String) {
        shake = 0.3
        floaters.append(TTNFloater(x: min(max(f.x, 120), size.width - 120), y: max(f.y - f.r - 10, 260),
                                   text: text, life: 1.5, hex: Lu.coral, size: 26))
        // Teach: ring the fruit that IS right.
        for j in fruit.indices where fruit[j].alive && !fruit[j].bomb && isRight(fruit[j]) { fruit[j].glow = 1.6 }
        miss(reason: reason, delay: 1.2)
    }

    /// DEBUG autoplayer: a short swipe through a right fruit (or, when wrong, a wrong one / bomb).
    override func botAct(correct: Bool) {
        let live = fruit.filter { $0.alive && $0.y > 200 && $0.y < size.height - $0.r }
        let pick = live.filter { (!$0.bomb && isRight($0)) == correct }.min { $0.y < $1.y }
        guard let f = pick else { return }
        bladeMove(CGPoint(x: f.x - 6, y: f.y))
        bladeMove(CGPoint(x: f.x + 6, y: f.y))
        bladeEnd()
    }

    private func burst(_ x: CGFloat, _ y: CGFloat, _ hex: UInt, _ n: Int) {
        for _ in 0..<n {
            let a = Double.random(in: 0..<6.28), sp = Double.random(in: 70...280)
            particles.append(TTNParticle(x: x, y: y, vx: CGFloat(cos(a) * sp), vy: CGFloat(sin(a) * sp - 60),
                                         life: 1, r: CGFloat.random(in: 3...7), hex: hex))
        }
    }

    // MARK: Drawing

    func render(context ctx: inout GraphicsContext, size: CGSize) {
        if shake > 0 {
            let m = shake / 0.3 * 12
            ctx.translateBy(x: CGFloat.random(in: -m...m), y: CGFloat.random(in: -m...m))
        }
        for s in splats {
            ctx.opacity = Double(max(0, s.life)) * 0.45
            for k in 0..<5 {
                let a = Double(k) * 1.3, rr = s.r * (k == 0 ? 1 : 0.35)
                let cx = s.x + (k == 0 ? 0 : CGFloat(cos(a)) * s.r * 1.1), cy = s.y + (k == 0 ? 0 : CGFloat(sin(a)) * s.r * 1.1)
                ctx.fill(Path(ellipseIn: CGRect(x: cx - rr, y: cy - rr, width: rr * 2, height: rr * 2)), with: .color(Color(hex: s.hex)))
            }
        }
        ctx.opacity = 1
        for h in halves { drawHalf(&ctx, h) }
        for f in fruit { drawFruit(&ctx, f) }
        ctx.opacity = 1
        for p in particles {
            ctx.opacity = Double(max(0, p.life))
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - p.r, y: p.y - p.r, width: p.r * 2, height: p.r * 2)),
                     with: .color(Color(hex: p.hex)))
        }
        if blade.count >= 2 {
            var path = Path()
            path.move(to: blade[0].p)
            for pt in blade.dropFirst() { path.addLine(to: pt.p) }
            let head = Double(blade.last?.life ?? 0)
            ctx.opacity = 0.35 * head
            ctx.stroke(path, with: .color(Color(hex: 0x9fd8ff)), style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
            ctx.opacity = 0.95 * head
            ctx.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
        }
        for f in floaters {
            ctx.opacity = Double(max(0, min(1, f.life)))
            let t = ctx.resolve(Text(f.text).font(luFont(f.size)).foregroundColor(Color(hex: f.hex)))
            if f.hex == Lu.coral {
                let w = t.measure(in: size).width + 24
                ctx.fill(Path(roundedRect: CGRect(x: f.x - w / 2, y: f.y - f.size * 0.75, width: w, height: f.size * 1.5),
                              cornerRadius: 12), with: .color(Color(hex: 0x0e1430).opacity(0.9)))
            }
            ctx.draw(t, at: CGPoint(x: f.x, y: f.y))
        }
        ctx.opacity = 1
    }

    private func drawFruit(_ ctx: inout GraphicsContext, _ f: TTNFruit) {
        let grow: CGFloat = f.pop > 0 ? 1 + f.pop * 0.7 : 1
        let r = f.r * grow
        let alpha: Double = f.pop > 0 ? Double(1 - f.pop) : f.fade > 0 ? Double(1 - f.fade) * 0.6 : 1
        let rect = CGRect(x: f.x - r, y: f.y - r, width: r * 2, height: r * 2)
        if f.glow > 0 {
            ctx.opacity = Double(min(1, f.glow))
            ctx.stroke(Path(ellipseIn: rect.insetBy(dx: -8, dy: -8)), with: .color(Color(hex: Lu.gold)), lineWidth: 6)
        }
        ctx.opacity = alpha
        if f.bomb {
            ctx.fill(Path(ellipseIn: rect), with: .radialGradient(
                Gradient(colors: [Color(hex: 0x5a5a6a), Color(hex: 0x24242c), .black]),
                center: CGPoint(x: f.x - r * 0.3, y: f.y - r * 0.34), startRadius: r * 0.1, endRadius: r))
            var fuse = Path()
            fuse.move(to: CGPoint(x: f.x + r * 0.4, y: f.y - r * 0.8))
            fuse.addQuadCurve(to: CGPoint(x: f.x + r * 0.8, y: f.y - r * 1.25), control: CGPoint(x: f.x + r * 0.9, y: f.y - r * 0.8))
            ctx.stroke(fuse, with: .color(Color(hex: 0xb08a5a)), lineWidth: 4)
            let spark = CGFloat.random(in: 4...8)
            ctx.fill(Path(ellipseIn: CGRect(x: f.x + r * 0.8 - spark, y: f.y - r * 1.25 - spark, width: spark * 2, height: spark * 2)),
                     with: .color(Color(hex: Lu.gold)))
            ctx.draw(ctx.resolve(Text("✕").font(luFont(r * 0.8)).foregroundColor(Color(hex: Lu.coral))), at: CGPoint(x: f.x, y: f.y + 2))
            return
        }
        let sk = ttnSkins[f.kind]
        // Stem + leaf turn with the spin.
        var leafCtx = ctx
        leafCtx.translateBy(x: f.x, y: f.y)
        leafCtx.rotate(by: .radians(Double(f.spin) * 0.25))
        leafCtx.fill(Path(roundedRect: CGRect(x: -2.5, y: -r - 9, width: 5, height: 13), cornerRadius: 2), with: .color(Color(hex: 0x6b4a2a)))
        leafCtx.fill(Path(ellipseIn: CGRect(x: 1, y: -r - 12, width: r * 0.55, height: r * 0.26)), with: .color(Color(hex: 0x4f9a3e)))
        let body = f.kind == 3 ? Path(ellipseIn: rect.insetBy(dx: -r * 0.08, dy: r * 0.06)) : Path(ellipseIn: rect)
        ctx.fill(body, with: .radialGradient(
            Gradient(colors: [luShade(sk.skin, 60), Color(hex: sk.skin), luShade(sk.skin, -50)]),
            center: CGPoint(x: f.x - r * 0.32, y: f.y - r * 0.36), startRadius: r * 0.1, endRadius: r * 1.05))
        ctx.opacity = alpha * 0.45
        ctx.fill(Path(ellipseIn: CGRect(x: f.x - r * 0.62, y: f.y - r * 0.7, width: r * 0.5, height: r * 0.28)), with: .color(.white))
        ctx.opacity = alpha
        // A cream label disc keeps the number readable on every skin.
        let lr = r * 0.66
        ctx.fill(Path(ellipseIn: CGRect(x: f.x - lr, y: f.y - lr, width: lr * 2, height: lr * 2)), with: .color(Color(hex: 0xfff8e6).opacity(0.92)))
        let ink = Color(hex: Lu.inkDark)
        if showDots && f.val <= 20 {
            ctx.draw(ctx.resolve(Text(f.label).font(luFont(r * 0.5)).foregroundColor(ink)), at: CGPoint(x: f.x, y: f.y - r * 0.24))
            drawCountingDots(ctx, n: f.val, group: target == 2 ? 2 : 5, at: CGPoint(x: f.x, y: f.y + r * 0.32), r: r * 0.7, color: ink)
        } else {
            let fs = f.label.count >= 5 ? r * 0.36 : f.label.count == 4 ? r * 0.42 : f.label.count == 3 ? r * 0.56 : r * 0.72
            ctx.draw(ctx.resolve(Text(f.label).font(luFont(fs)).foregroundColor(ink)), at: CGPoint(x: f.x, y: f.y))
        }
    }

    private func drawHalf(_ ctx: inout GraphicsContext, _ h: TTNHalf) {
        let sk = ttnSkins[h.kind]
        var c = ctx
        c.opacity = Double(max(0, min(1, h.life * 1.5)))
        c.translateBy(x: h.x, y: h.y)
        c.rotate(by: .radians(Double(h.angle)))
        var half = Path()
        half.addArc(center: .zero, radius: h.r, startAngle: .zero, endAngle: .degrees(180), clockwise: false)
        half.closeSubpath()
        c.fill(half, with: .color(Color(hex: sk.skin)))
        var flesh = Path()
        flesh.addArc(center: .zero, radius: h.r * 0.84, startAngle: .zero, endAngle: .degrees(180), clockwise: false)
        flesh.closeSubpath()
        c.fill(flesh, with: .color(Color(hex: sk.flesh)))
        for k in 0..<3 {     // seeds
            let a = Double(k + 1) * .pi / 4
            c.fill(Path(ellipseIn: CGRect(x: CGFloat(cos(a)) * h.r * 0.45 - 2.5, y: CGFloat(sin(a)) * h.r * 0.45 - 4, width: 5, height: 8)),
                   with: .color(Color(hex: 0x5a3a1a).opacity(0.7)))
        }
    }

    #if DEBUG
    /// Every fruit must be clearly right or wrong for its target; ÷ facts always divide exactly.
    static func selfCheck() {
        for (i, t) in ttnTables.enumerated() {
            for maxMul in [5, 8, 12] {
                for k in 0..<300 {
                    let right = k % 2 == 0
                    if t == 0 {
                        let q = 2 + k % 8
                        let (val, label) = ttnMakeFruit(division: true, target: q, maxMul: maxMul, right: right)
                        let parts = label.split(separator: "÷").compactMap { Int($0) }
                        precondition(parts.count == 2 && parts[0] % parts[1] == 0 && parts[0] / parts[1] == val, "bad fact \(label)")
                        precondition((val == q) == right, "\(label) vs \(q)")
                    } else {
                        let (val, label) = ttnMakeFruit(division: false, target: t, maxMul: maxMul, right: right)
                        precondition(Int(label) == val && val > 0 && val <= t * maxMul, "bad \(label)")
                        precondition((val % t == 0) == right, "\(val) vs the \(t)s")
                    }
                }
            }
            print("SELFCHECK timesTableNinja tier \(i) (\(t == 0 ? "÷" : "\(t)s")) ok")
        }
    }
    #endif
}

/// Does the segment a→b pass within `r` of point c?
private func ttnSegmentHitsCircle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ r: CGFloat) -> Bool {
    let abx = b.x - a.x, aby = b.y - a.y
    let len2 = abx * abx + aby * aby
    let t = len2 > 0 ? max(0, min(1, ((c.x - a.x) * abx + (c.y - a.y) * aby) / len2)) : 0
    let dx = c.x - (a.x + abx * t), dy = c.y - (a.y + aby * t)
    return dx * dx + dy * dy <= r * r
}

/// Counting dots (pairs, or rows of `group`) under a number.
private func drawCountingDots(_ ctx: GraphicsContext, n: Int, group: Int, at c: CGPoint, r: CGFloat, color: Color) {
    guard n > 0 else { return }
    let cols = group == 2 ? (n + 1) / 2 : min(n, group)
    let rows = group == 2 ? min(n, 2) : (n + group - 1) / group
    let s = min(r * 0.3, r * 1.5 / CGFloat(max(cols, 1)), r * 0.8 / CGFloat(max(rows, 1)))
    let dr = s * 0.4
    for k in 0..<n {
        let (col, row) = group == 2 ? (k / 2, k % 2) : (k % group, k / group)
        let x = c.x + (CGFloat(col) - CGFloat(cols - 1) / 2) * s
        let y = c.y + (CGFloat(row) - CGFloat(rows - 1) / 2) * s
        ctx.fill(Path(ellipseIn: CGRect(x: x - dr, y: y - dr, width: dr * 2, height: dr * 2)), with: .color(color))
    }
}

struct TimesTableNinjaView: View {
    let onClose: () -> Void
    @StateObject private var game = TTNEngine()

    var body: some View {
        ArcadeShell(model: game,
                    spec: GameID.timesTableNinja.spec ?? GameSpec(title: "Times Table Ninja", mechanic: "slash", premise: "", game: .timesTableNinja),
                    accent: Lu.coral, onClose: onClose,
                    backdrop: { MoonGarden() }) {
            ZStack(alignment: .top) {
                TimelineView(.animation(minimumInterval: nil, paused: game.phase != .playing)) { tl in
                    Canvas { ctx, sz in
                        game.advance(to: tl.date, size: sz)
                        game.render(context: &ctx, size: sz)
                    }
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { v in game.bladeMove(v.location) }
                        .onEnded { _ in game.bladeEnd() })
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    HUDSpace(62)
                    TTNBanner(target: game.target, division: game.division, hint: game.hint, maxMul: game.maxMul, combo: game.combo)
                }
                .opacity(game.phase == .playing ? 1 : 0)
                .allowsHitTesting(false)
            }
        }
    }
}

/// The villa garden at night: a deep sky, a big moon, stars, a tiled wall with glowing lanterns,
/// cypress silhouettes.
private struct MoonGarden: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Color(hex: 0x0b1030), Color(hex: 0x1d2257), Color(hex: 0x3b2f6b)], startPoint: .top, endPoint: .bottom)
                ForEach(0..<40) { i in
                    let x = w * CGFloat((i * 73) % 100) / 100, y = h * CGFloat((i * 37) % 60) / 100
                    Circle().fill(Color.white.opacity(i % 3 == 0 ? 0.9 : 0.5)).frame(width: i % 4 == 0 ? 3 : 2).position(x: x, y: y)
                }
                Circle().fill(RadialGradient(colors: [Color(hex: 0xfff6d8).opacity(0.5), .clear], center: .center, startRadius: 40, endRadius: 140))
                    .frame(width: 280, height: 280).position(x: w * 0.75, y: h * 0.3)
                Circle().fill(Color(hex: 0xfdf1c8)).frame(width: 110).position(x: w * 0.75, y: h * 0.3)
                Circle().fill(Color(hex: 0xe9d9a8)).frame(width: 18).position(x: w * 0.72, y: h * 0.29)
                Circle().fill(Color(hex: 0xe9d9a8)).frame(width: 12).position(x: w * 0.79, y: h * 0.32)
                // Cypresses
                ForEach(0..<4) { i in
                    let x = w * [0.06, 0.16, 0.86, 0.96][i], th = h * [0.3, 0.22, 0.26, 0.34][i]
                    Capsule().fill(Color(hex: 0x0d1a24)).frame(width: 34, height: th).position(x: x, y: h * 0.8 - th / 2)
                }
                // Wall with roof tiles and lanterns
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0x3a2236), Color(hex: 0x22142a)], startPoint: .top, endPoint: .bottom))
                    .frame(height: h * 0.24).offset(y: h * 0.78)
                HStack(spacing: 0) {
                    ForEach(0..<18) { _ in Capsule().fill(Color(hex: 0x6a2c22)).frame(width: 26, height: 20) }
                }
                .frame(width: w, alignment: .leading).offset(y: h * 0.77)
                ForEach(0..<3) { i in
                    let x = w * [0.18, 0.5, 0.82][i]
                    ZStack {
                        Circle().fill(RadialGradient(colors: [Color(hex: 0xffb347).opacity(0.55), .clear], center: .center, startRadius: 4, endRadius: 60))
                            .frame(width: 120, height: 120)
                        RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0xf08a24)).frame(width: 22, height: 30)
                        RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0x3a1a0a)).frame(width: 26, height: 5).offset(y: -16)
                    }
                    .position(x: x, y: h * 0.85)
                }
            }
        }
    }
}

/// The ninja himself, drawn: a dark hood, a peach eye-band with two eyes, a red headband whose
/// tails flutter.
private struct NinjaHead: View {
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 26, y: 12)); p.addQuadCurve(to: CGPoint(x: 42, y: 4), control: CGPoint(x: 36, y: 14))
                p.move(to: CGPoint(x: 26, y: 14)); p.addQuadCurve(to: CGPoint(x: 40, y: 20), control: CGPoint(x: 34, y: 12))
            }
            .stroke(Color(hex: 0xd33b2c), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            Circle().fill(Color(hex: 0x1d1b2a)).frame(width: 36).position(x: 18, y: 18)
            Capsule().fill(Color(hex: 0xf3c9a0)).frame(width: 28, height: 11).position(x: 18, y: 17)
            Circle().fill(Color.black).frame(width: 5).position(x: 13, y: 17)
            Circle().fill(Color.black).frame(width: 5).position(x: 23, y: 17)
            Capsule().fill(Color(hex: 0xd33b2c)).frame(width: 34, height: 5).position(x: 18, y: 8)
        }
        .frame(width: 44, height: 36)
    }
}

/// "Slice the 2s" (+ the opening of the table while it's new), or "Make 8" for ÷ facts.
private struct TTNBanner: View {
    let target: Int
    let division: Bool
    let hint: Bool
    let maxMul: Int
    let combo: Int
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 10) {
                NinjaHead()
                Text(division ? "Make \(target)" : "Slice the \(target)s").font(luFont(28)).foregroundStyle(Color(hex: 0x2b1708))
            }
            if division {
                Text("slice the ÷ that equal \(target)").font(luFont(15, .bold)).foregroundStyle(Color(hex: 0x6e4520))
            } else if hint {
                let shown = (1...min(5, maxMul)).map { "\($0 * target)" }.joined(separator: " · ")
                Text(shown + " …").font(luFont(17, .heavy)).foregroundStyle(Color(hex: 0xa2401c))
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Color(hex: 0xf6e7c4), Color(hex: 0xdcc394)], startPoint: .top, endPoint: .bottom))
            .shadow(color: .black.opacity(0.4), radius: 0, x: 0, y: 4))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0x8a5a2b), lineWidth: 3))
        .id("\(target)\(division)")
        .transition(.scale(scale: 0.8).combined(with: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: target)
        .overlay(alignment: .bottom) {
            if combo >= 2 {
                Text("COMBO ×\(combo)!").font(luFont(18)).foregroundStyle(Color(hex: Lu.mint))
                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                    .id(combo).offset(y: 28)
                    .transition(.scale(scale: 1.25).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: combo)
    }
}
