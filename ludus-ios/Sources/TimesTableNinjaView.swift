import SwiftUI

// MARK: - Times Table Ninja  (Number Crunchers · slash)
//
// Fruit arcs up from the bottom, each carrying a number. The banner names a times table
// ("Slice the 2s"); swipe — or just tap — the fruit in that table. Slicing a wrong one (or a
// bomb) is a miss: the game says why ("7 is not in the 2s") and rings the right fruit. Fruit
// that falls unsliced is fine — no penalty. Mixed levels switch table every 3 slices (the fruit
// in the air puffs away so nothing changes meaning mid-flight).
//   I     the 2s, 2×1…5, odd numbers as the others — every fruit shows its dots in pairs
//   II    the 5s only, 5×1…4 (to 20), dots in fives
//   III   the 10s, ×1…5
//   IV    2s / 5s / 10s mixed, ×1…10
//   V     the 3s and 4s (bombs start, rarely)
//   VI    the 6s and 7s
//   VII   the 8s and 9s
//   VIII  11s and 12s mixed with 6–9, ×1…12
//   IX+   division: "Make 8" — slice the ÷ facts that equal 8 (56÷7 …); quicker each level, capped
// Early fruit floats on low gravity (≈4 s in the air); later levels fall faster.

private struct TTNFruit {
    var x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat, r: CGFloat
    var spin: CGFloat, spinV: CGFloat
    var val: Int                 // the number (or the quotient, for a ÷ fact)
    var label: String            // what's written on it ("14", "56÷7")
    var bomb: Bool
    var hex: UInt
    var pop: CGFloat = 0         // 0 alive; 0→1 while bursting
    var fade: CGFloat = 0        // 0 alive; 0→1 while puffing away (table changed)
    var glow: CGFloat = 0        // seconds of "this one!" ring after a miss
    var alive: Bool { pop == 0 && fade == 0 }
}
private struct TTNParticle { var x, y, vx, vy, life, r: CGFloat; var hex: UInt }
private struct TTNFloater { var x, y: CGFloat; var text: String; var life: CGFloat; var hex: UInt; var size: CGFloat }
private struct TTNBladePoint { var p: CGPoint; var life: CGFloat }

/// One level's content.
private struct TTNLevel {
    let tables: [Int]            // multiples mode: the tables; division mode: the target answers
    let maxMul: Int
    var division = false
    var hint = false             // show "2 · 4 · 6 …" under the banner
    var bombs = 0.0
}

private func ttnLevel(_ level: Int) -> TTNLevel {
    switch level {
    case 1: return TTNLevel(tables: [2], maxMul: 5, hint: true)
    case 2: return TTNLevel(tables: [5], maxMul: 4, hint: true)
    case 3: return TTNLevel(tables: [10], maxMul: 5, hint: true)
    case 4: return TTNLevel(tables: [2, 5, 10], maxMul: 10, hint: true)
    case 5: return TTNLevel(tables: [3, 4], maxMul: 10, hint: true, bombs: 0.05)
    case 6: return TTNLevel(tables: [6, 7], maxMul: 10, bombs: 0.06)
    case 7: return TTNLevel(tables: [8, 9], maxMul: 10, bombs: 0.08)
    case 8: return TTNLevel(tables: [11, 12, 6, 7, 8, 9], maxMul: 12, bombs: 0.08)
    case 9: return TTNLevel(tables: Array(2...9), maxMul: 9, division: true, bombs: 0.08)
    default: return TTNLevel(tables: Array(2...12), maxMul: 12, division: true, bombs: 0.1)
    }
}

/// A fruit for `target` at this level: (value, label, right?). Multiples mode: a multiple of
/// `target` up to `maxMul`× it, or a non-multiple in the same range. Division mode: a fact
/// a÷b = q whose quotient q is `target` (right) or another 1…maxMul (wrong).
private func ttnMakeFruit(_ lv: TTNLevel, target: Int, right: Bool) -> (val: Int, label: String) {
    if lv.division {
        let q = right ? target : (1...lv.maxMul).filter { $0 != target }.randomElement()!
        let b = Int.random(in: 2...lv.maxMul)
        return (q, "\(q * b)÷\(b)")
    }
    let n = right ? target * Int.random(in: 1...lv.maxMul)
                  : (1...(target * lv.maxMul)).filter { $0 % target != 0 }.randomElement()!
    return (n, "\(n)")
}

private func ttnIsRight(_ lv: TTNLevel, target: Int, val: Int) -> Bool {
    lv.division ? val == target : val % target == 0
}

@MainActor
private final class TTNEngine: ArcadeModel {
    @Published private(set) var target = 2
    @Published private(set) var lv = ttnLevel(1)

    private var fruit: [TTNFruit] = []
    private var particles: [TTNParticle] = []
    private var floaters: [TTNFloater] = []
    private var blade: [TTNBladePoint] = []
    private var size: CGSize = .zero
    private var spawnAcc = 0.0
    private var lastTick: Date?
    private var shake: CGFloat = 0
    private var swiping = false
    private var hitsOnTarget = 0

    init() {
        super.init(key: GameID.timesTableNinja.rawValue)
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { Self.selfCheck() }
        #endif
    }

    // Level tuning: gravity (pt/s² on an 800-pt field), seconds between launches, fruit radius.
    private var gravity: CGFloat { level <= 7 ? [200, 230, 270, 310, 350, 390, 430][level - 1] : min(540, 460 + CGFloat(level - 8) * 15) }
    private var interval: Double { level <= 7 ? [1.7, 1.6, 1.45, 1.35, 1.25, 1.15, 1.05][level - 1] : max(0.75, 1.0 - Double(level - 8) * 0.04) }
    private var radius: CGFloat {
        let share: CGFloat = level <= 2 ? 0.135 : level <= 5 ? 0.12 : 0.11
        return max(36, min(56, size.width * share))
    }
    private var showDots: Bool { level <= 2 && !lv.division }

    override func onBegin() {
        fruit.removeAll(); particles.removeAll(); floaters.removeAll(); blade.removeAll()
        spawnAcc = 0.8; lastTick = nil; shake = 0; swiping = false
        lv = ttnLevel(level)
        hitsOnTarget = 0
        target = lv.tables.randomElement()!
    }

    override func onLevelUp() {
        lv = ttnLevel(level)
        switchTarget()
    }

    /// New table (or answer): the fruit in the air puffs away, so nothing changes meaning mid-flight.
    private func switchTarget() {
        hitsOnTarget = 0
        let choices = lv.tables.filter { $0 != target }
        target = (choices.isEmpty ? lv.tables : choices).randomElement()!
        for i in fruit.indices where fruit[i].alive { fruit[i].fade = 0.001 }
        spawnAcc = interval * 0.5
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
                if level >= 6 && Double.random(in: 0..<1) < 0.3 { spawnOne() }
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
        for i in particles.indices.reversed() {
            particles[i].life -= CGFloat(dt) * 1.7
            if particles[i].life <= 0 { particles.remove(at: i); continue }
            particles[i].vy += CGFloat(420 * dt)
            particles[i].x += particles[i].vx * CGFloat(dt)
            particles[i].y += particles[i].vy * CGFloat(dt)
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
        let bomb = Double.random(in: 0..<1) < lv.bombs
        let right = !bomb && Double.random(in: 0..<1) < 0.6
        let (val, label) = ttnMakeFruit(lv, target: target, right: right)
        let x0 = CGFloat.random(in: (size.width * 0.18)...(size.width * 0.82))
        let y0 = size.height + r
        let apex = size.height * CGFloat.random(in: 0.3...0.48)
        let vy = -sqrt(2 * g * (y0 - apex))
        let flight = 2 * -vy / g
        let land = CGFloat.random(in: (size.width * 0.15)...(size.width * 0.85))
        fruit.append(TTNFruit(x: x0, y: y0, vx: (land - x0) / flight, vy: vy, r: r,
                              spin: 0, spinV: CGFloat.random(in: -0.8...0.8),
                              val: val, label: label, bomb: bomb,
                              hex: bomb ? Lu.inkDark : (Lu.bubbleHexes.randomElement() ?? Lu.sky)))
    }

    // MARK: Blade (gesture-driven)

    func bladeMove(_ p: CGPoint) {
        if !swiping { swiping = true; blade.removeAll(keepingCapacity: true) }
        let prev = blade.last?.p ?? p          // a plain tap tests the touch point itself
        blade.append(TTNBladePoint(p: p, life: 1))
        if blade.count > 8 { blade.removeFirst(blade.count - 8) }
        testSegment(prev, p)
    }

    func bladeEnd() { swiping = false }

    private func testSegment(_ a: CGPoint, _ b: CGPoint) {
        guard phase == .playing, !dying else { return }
        for i in fruit.indices where fruit[i].alive {
            if ttnSegmentHitsCircle(a, b, CGPoint(x: fruit[i].x, y: fruit[i].y), fruit[i].r + 8) {
                slice(i)
                if dying { return }
            }
        }
    }

    private func slice(_ i: Int) {
        let f = fruit[i]
        fruit[i].pop = 0.001
        if f.bomb {
            burst(f.x, f.y, Lu.coral, 14)
            wrong(at: f, text: "💥 BOOM!", reason: "Boom!")
        } else if ttnIsRight(lv, target: target, val: f.val) {
            burst(f.x, f.y, f.hex, 14)
            let pts = min(combo + 1, 5)
            hitsOnTarget += 1
            let climbed = hit()
            floaters.append(TTNFloater(x: f.x, y: f.y - f.r, text: "+\(pts)", life: 1, hex: Lu.gold, size: 28))
            if !climbed && lv.tables.count > 1 && hitsOnTarget >= 3 { switchTarget() }
        } else {
            burst(f.x, f.y, Lu.coral, 10)
            let why = lv.division ? "\(f.label) = \(f.val)" : "\(f.val) is not in the \(target)s"
            wrong(at: f, text: why, reason: "Out of hearts!")
        }
    }

    private func wrong(at f: TTNFruit, text: String, reason: String) {
        shake = 0.3
        floaters.append(TTNFloater(x: min(max(f.x, 110), size.width - 110), y: max(f.y - f.r - 10, 240),
                                   text: text, life: 1.4, hex: Lu.coral, size: 26))
        // Teach: ring the fruit that IS right.
        for j in fruit.indices where fruit[j].alive && !fruit[j].bomb && ttnIsRight(lv, target: target, val: fruit[j].val) {
            fruit[j].glow = 1.6
        }
        miss(reason: reason, delay: 1.2)
    }

    /// DEBUG autoplayer: a short swipe through a right fruit (or, when wrong, a wrong one / bomb).
    override func botAct(correct: Bool) {
        let live = fruit.filter { $0.alive && $0.y > 170 && $0.y < size.height - $0.r }
        let pick = live.filter { (!$0.bomb && ttnIsRight(lv, target: target, val: $0.val)) == correct }
            .min { $0.y < $1.y }
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
        for f in fruit {
            let grow: CGFloat = f.pop > 0 ? 1 + f.pop * 0.7 : 1
            let r = f.r * grow
            let alpha: Double = f.pop > 0 ? Double(1 - f.pop) : f.fade > 0 ? Double(1 - f.fade) * 0.6 : 1
            let rect = CGRect(x: f.x - r, y: f.y - r, width: r * 2, height: r * 2)
            if f.glow > 0 {
                ctx.opacity = Double(min(1, f.glow))
                ctx.stroke(Path(ellipseIn: rect.insetBy(dx: -7, dy: -7)), with: .color(Color(hex: Lu.gold)), lineWidth: 5)
            }
            if f.bomb {
                ctx.opacity = alpha
                ctx.fill(Path(ellipseIn: rect), with: .radialGradient(
                    Gradient(colors: [luShade(Lu.inkDark, 40), Color(hex: Lu.inkDark), .black]),
                    center: CGPoint(x: f.x - r * 0.3, y: f.y - r * 0.34), startRadius: r * 0.1, endRadius: r))
                ctx.stroke(Path(ellipseIn: rect), with: .color(Color(hex: Lu.coral)), lineWidth: 3)
                ctx.draw(ctx.resolve(Text("💣").font(.system(size: r * 1.05))), at: CGPoint(x: f.x, y: f.y))
                continue
            }
            // A round fruit: body, gloss, a stem and a leaf that turn with its spin.
            ctx.opacity = alpha
            var leafCtx = ctx
            leafCtx.translateBy(x: f.x, y: f.y)
            leafCtx.rotate(by: .radians(Double(f.spin) * 0.25))
            leafCtx.fill(Path(roundedRect: CGRect(x: -2.5, y: -r - 9, width: 5, height: 13), cornerRadius: 2),
                         with: .color(Color(hex: 0x6b4a2a)))
            leafCtx.fill(Path(ellipseIn: CGRect(x: 1, y: -r - 12, width: r * 0.55, height: r * 0.26)),
                         with: .color(Color(hex: Lu.mint)))
            ctx.fill(Path(ellipseIn: rect), with: .radialGradient(
                Gradient(colors: [.white, Color(hex: f.hex), luShade(f.hex, -34)]),
                center: CGPoint(x: f.x - r * 0.32, y: f.y - r * 0.36), startRadius: r * 0.15, endRadius: r))
            ctx.opacity = alpha * 0.5
            ctx.fill(Path(ellipseIn: CGRect(x: f.x - r * 0.56, y: f.y - r * 0.62, width: r * 0.6, height: r * 0.34)),
                     with: .color(.white))
            ctx.opacity = alpha
            let ink = Color(hex: Lu.inkDark)
            let dotGroup = target == 2 ? 2 : 5
            if showDots && f.val <= 20 && (target == 2 || target == 5) {
                ctx.draw(ctx.resolve(Text(f.label).font(luFont(r * 0.62)).foregroundColor(ink)),
                         at: CGPoint(x: f.x, y: f.y - r * 0.32))
                drawCountingDots(ctx, n: f.val, group: dotGroup, at: CGPoint(x: f.x, y: f.y + r * 0.38), r: r * 0.95, color: ink)
            } else {
                let fs = f.label.count >= 4 ? r * 0.5 : f.label.count == 3 ? r * 0.66 : r * 0.86
                ctx.draw(ctx.resolve(Text(f.label).font(luFont(fs)).foregroundColor(ink)), at: CGPoint(x: f.x, y: f.y))
            }
        }
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
            ctx.opacity = 0.3 * head
            ctx.stroke(path, with: .color(Color(hex: Lu.mint)), style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round))
            ctx.opacity = 0.9 * head
            ctx.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
        }
        for f in floaters {
            ctx.opacity = Double(max(0, min(1, f.life)))
            let t = ctx.resolve(Text(f.text).font(luFont(f.size)).foregroundColor(Color(hex: f.hex)))
            if f.hex == Lu.coral {
                let w = t.measure(in: size).width + 24
                ctx.fill(Path(roundedRect: CGRect(x: f.x - w / 2, y: f.y - f.size * 0.75, width: w, height: f.size * 1.5),
                              cornerRadius: 12), with: .color(Color(hex: Lu.ground).opacity(0.85)))
            }
            ctx.draw(t, at: CGPoint(x: f.x, y: f.y))
        }
        ctx.opacity = 1
    }

    #if DEBUG
    /// Every fruit must be clearly right or wrong for the banner's target: right fruit are
    /// multiples (or ÷ facts whose quotient IS the target, checked by parsing "a÷b" and dividing),
    /// wrong fruit never are, and ÷ facts always divide exactly. LUDUS_SELFCHECK=1.
    static func selfCheck() {
        for level in 1...10 {
            let lv = ttnLevel(level)
            for t in lv.tables {
                for k in 0..<400 {
                    let right = k % 2 == 0
                    let (val, label) = ttnMakeFruit(lv, target: t, right: right)
                    if lv.division {
                        let parts = label.split(separator: "÷").compactMap { Int($0) }
                        precondition(parts.count == 2 && parts[0] % parts[1] == 0 && parts[0] / parts[1] == val, "L\(level) bad fact \(label)")
                        precondition((val == t) == right, "L\(level) \(label) vs target \(t)")
                    } else {
                        precondition(Int(label) == val && val > 0, "L\(level) bad label \(label)")
                        precondition((val % t == 0) == right, "L\(level) \(val) vs the \(t)s")
                        precondition(val <= t * lv.maxMul, "L\(level) \(val) out of range")
                        precondition(level != 2 || (t == 5 && val <= 20), "L2 must be the 5s to 20, got \(val)")
                    }
                }
            }
            print("SELFCHECK timesTableNinja L\(level) ok — tables \(lv.tables)\(lv.division ? " ÷" : "")")
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

struct TimesTableNinjaView: View {
    let onClose: () -> Void
    @StateObject private var game = TTNEngine()

    var body: some View {
        ArcadeShell(model: game,
                    spec: GameID.timesTableNinja.spec ?? GameSpec(title: "Times Table Ninja", mechanic: "slash", premise: "", game: .timesTableNinja),
                    accent: Lu.coral, onClose: onClose) {
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

                TTNBanner(target: game.target, lv: game.lv, combo: game.combo)
                    .padding(.top, 62)
                    .opacity(game.phase == .playing ? 1 : 0)
                    .allowsHitTesting(false)
            }
        }
    }
}

/// "Slice the 2s" (+ the first few of the table while it's new), or "Make 8" for ÷ facts.
private struct TTNBanner: View {
    let target: Int
    let lv: TTNLevel
    let combo: Int
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 10) {
                Text("🥷").font(.system(size: 30))
                Text(lv.division ? "Make \(target)" : "Slice the \(target)s").font(luFont(28)).foregroundStyle(Color(hex: Lu.ink))
            }
            if lv.division {
                Text("slice the ÷ that equal \(target)").font(luFont(15, .bold)).foregroundStyle(Color(hex: Lu.inkDim))
            } else if lv.hint {
                let shown = (1...min(5, lv.maxMul)).map { "\($0 * target)" }.joined(separator: " · ")
                Text(shown + (lv.maxMul > 5 ? " …" : "")).font(luFont(17, .bold)).foregroundStyle(Color(hex: Lu.gold))
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 8)
        .background(luPanelShape(18).opacity(0.92))
        .id(target)
        .transition(.scale(scale: 0.8).combined(with: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: target)
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
