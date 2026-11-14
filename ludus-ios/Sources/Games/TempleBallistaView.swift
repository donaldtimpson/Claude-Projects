import SwiftUI

// MARK: - Ballista  (Number Crunchers · aim)
//
// The legion's practice range: clay pots hide in the grass along a long wooden number line marked
// by little milestones. The centurion calls a number — drag to aim the ballista along the line,
// let go to fire. The stone arcs over and lands; the pot for that number pops up — SMASH if the
// stone was close enough, otherwise it stands there with its number flag and a bracket showing how
// far off the shot was (so every miss shows where the number really lives).
//
// Strand: number sense → place value → negatives → decimals → estimation with expressions.
// Everything is tuned off the continuous difficulty `d` (GameKit):
//   • content kinds fade in via `tier`: 0–10 (snaps to whole numbers, every milestone labelled,
//     dots under the call, read aloud) → 0–20 → 0–100 → −10…10 → 0–1000 → decimals → mixed
//     challenges (sums/products to place, "halfway between", 0–10 000);
//   • within each kind the milestone labels thin out (every one → a few → only the ends);
//   • the hit window shrinks from ~5 % of the line to ~1.8 %.

// MARK: Content

private struct BQ {
    var lo: Double, hi: Double
    var minor: Double                 // tick spacing
    var labels: [Double]              // milestones with numbers on them
    var target: Double
    var call: String                  // what the centurion shouts
    var sub: String? = nil            // a small line under the call ("halfway between …")
    var say: String
    var snap: Double? = nil           // aim snaps to this step (the whole-number tiers)
    var tol: Double                   // hit window (± value units)
    var dots = 0                      // counting dots under the call (the very start)
    var span: Double { hi - lo }
}

/// A number the way a child writes it: true minus sign, thousands comma, ≤ 2 decimals.
private func bFmt(_ v: Double) -> String {
    let neg = v < 0
    let a = abs(v)
    var s: String
    if abs(a - a.rounded()) < 1e-9 {
        let n = Int(a.rounded())
        s = n >= 10_000 ? String(format: "%d,%03d", n / 1000, n % 1000) : "\(n)"
    } else {
        s = String(format: "%.2f", a)
        while s.hasSuffix("0") { s.removeLast() }
    }
    return (neg ? "−" : "") + s
}
private func bSay(_ v: Double) -> String { v < 0 ? "negative " + bFmt(-v).replacingOccurrences(of: ",", with: "") : bFmt(v).replacingOccurrences(of: ",", with: "") }

private func stride(_ lo: Double, _ hi: Double, _ step: Double) -> [Double] {
    var out: [Double] = []
    var v = lo
    while v <= hi + step * 0.001 { out.append((v / step).rounded() * step); v += step }
    return out
}

// MARK: Model

@MainActor
private final class BallistaModel: ArcadeModel {
    enum Stage { case aiming, flying, landed }

    @Published var q = BQ(lo: 0, hi: 10, minor: 1, labels: stride(0, 10, 1), target: 5, call: "5", say: "5", snap: 1, tol: 0.4)
    @Published var stage: Stage = .aiming
    @Published var aim: Double?
    @Published var shot: Double?
    @Published var shotID = 0
    @Published var wasHit = false
    @Published var bullseye = false
    @Published var roundID = 0

    private var gen = 0

    init() { super.init(key: GameID.ballista.rawValue) }

    override func onBegin() { next() }

    private func later(_ t: Double, _ f: @escaping (BallistaModel) -> Void) {
        let g = gen
        DispatchQueue.main.asyncAfter(deadline: .now() + t) { [weak self] in
            guard let self, self.gen == g, self.phase == .playing else { return }
            f(self)
        }
    }

    private func next() {
        gen += 1
        var nq = makeQ()
        var guardN = 0
        while abs(nq.target - q.target) < 1e-9 && guardN < 8 { nq = makeQ(); guardN += 1 }
        q = nq
        stage = .aiming; aim = nil; shot = nil; wasHit = false; bullseye = false
        roundID += 1
        if d < 3.6 { LibraryVoice.say(q.say, rate: 0.45) }
    }

    func sayCall() { LibraryVoice.say(q.say, rate: 0.45) }

    /// Clamp (and snap) a raw value on the current line.
    func settle(_ v: Double) -> Double {
        var x = min(q.hi, max(q.lo, v))
        if let s = q.snap { x = (x / s).rounded() * s }
        return x
    }

    func fire(at raw: Double) {
        guard phase == .playing, stage == .aiming else { return }
        let v = settle(raw)
        aim = v; shot = v; shotID += 1
        stage = .flying
        Sfx.play(.whoosh)
        Haptics.tap(0.6)
        later(0.72) { m in m.land() }
    }

    private func land() {
        guard let s = shot else { return }
        let err = abs(s - q.target)
        stage = .landed
        if err <= q.tol + 1e-9 {
            wasHit = true
            bullseye = err <= q.tol * 0.34 + 1e-9 && q.snap == nil
            Sfx.play(.thud, volume: 0.6)
            Sfx.play(.pop)
            hit(points: bullseye ? 2 : 1)
            if bullseye { Sfx.play(.coin) }
            later(1.25) { $0.next() }
        } else {
            wasHit = false
            Sfx.play(.thud)
            miss(delay: 2.4)
            later(0.35) { m in LibraryVoice.say("\(m.q.say) is here", rate: 0.48) }
            later(2.5) { m in if !m.dying { m.next() } }
        }
    }

    override func botAct(correct: Bool) {
        guard stage == .aiming else { return }
        if correct { fire(at: q.target + Double.random(in: -0.5...0.5) * q.tol); return }
        var v = q.target + (Bool.random() ? 1 : -1) * q.tol * Double.random(in: 2.5...5)
        if v < q.lo || v > q.hi { v = q.target + (q.target - v) }
        fire(at: v)
    }

    // MARK: Question maker (all of it off `d`)

    private func makeQ() -> BQ {
        let share = ramp(0.05, 0.018, from: 3, to: 9.5)       // hit window as a share of the line
        let k = tier([1, 2.2, 3.2, 4.5, 5.6, 6.6, 7.6], keep: 0.15)
        func r(_ x: ClosedRange<Int>) -> Int { Int.random(in: x) }
        /// Thins the milestone labels as `d` climbs past `start`: every one → the given middle set → the ends.
        func thin(_ start: Double, all: [Double], mid: [Double], ends: [Double]) -> [Double] {
            let t = ramp(0, 1, from: start, to: start + 2.4)
            return t < 0.34 ? all : (t < 0.7 ? mid : ends)
        }
        func pick(_ cands: [Double], avoid labels: [Double]) -> Double {
            let free = cands.filter { c in !labels.contains { abs($0 - c) < 1e-9 } }
            return (free.isEmpty ? cands : free).randomElement()!
        }
        switch k {
        case 0:   // 0–10, whole numbers, snapping
            let labels = thin(1, all: stride(0, 10, 1), mid: [0, 5, 10], ends: [0, 10])
            let t = labels.count > 3 ? Double(r(1...9)) : pick(stride(1, 9, 1), avoid: labels)
            return BQ(lo: 0, hi: 10, minor: 1, labels: labels, target: t, call: bFmt(t), say: bSay(t),
                      snap: 1, tol: 0.4, dots: d < 1.9 ? Int(t) : 0)
        case 1:   // 0–20
            let labels = thin(2.2, all: stride(0, 20, 2), mid: [0, 10, 20], ends: [0, 20])
            let t = pick(stride(1, 19, 1), avoid: labels)
            return BQ(lo: 0, hi: 20, minor: 1, labels: labels, target: t, call: bFmt(t), say: bSay(t), snap: 1, tol: 0.4)
        case 2:   // 0–100: tens first, then any number
            let labels = thin(3.2, all: stride(0, 100, 10), mid: [0, 50, 100], ends: [0, 100])
            let tens = chance(1, from: 3.2, to: 4.6) ? false : true
            let t = tens ? pick(stride(10, 90, 10), avoid: labels) : pick(stride(3, 97, 1), avoid: labels)
            return BQ(lo: 0, hi: 100, minor: 10, labels: labels, target: t, call: bFmt(t), say: bSay(t),
                      tol: max(2.5, 100 * share))
        case 3:   // −10…10
            let labels = thin(4.5, all: stride(-10, 10, 2), mid: [-10, -5, 0, 5, 10], ends: [-10, 0, 10])
            var t = pick(stride(-9, 9, 1), avoid: labels)
            if t >= 0 && Double.random(in: 0..<1) < 0.7 { t = -max(1, t) }      // mostly negatives
            return BQ(lo: -10, hi: 10, minor: 1, labels: labels, target: t, call: bFmt(t), say: bSay(t), snap: 1, tol: 0.4)
        case 4:   // 0–1000
            let labels = thin(5.6, all: stride(0, 1000, 100), mid: [0, 500, 1000], ends: [0, 1000])
            let coarse = !chance(1, from: 5.6, to: 7)
            let t = coarse ? pick(stride(50, 950, 50), avoid: labels) : Double(r(1...99) * 10)
            return BQ(lo: 0, hi: 1000, minor: 100, labels: labels, target: t, call: bFmt(t), say: bSay(t),
                      tol: 1000 * share)
        case 5:   // decimals: tenths on 0–1, or x.y on 0–10
            if Bool.random() {
                let labels = thin(6.6, all: stride(0, 1, 0.1), mid: [0, 0.5, 1], ends: [0, 1])
                let t = pick(stride(0.1, 0.9, 0.1), avoid: labels)
                return BQ(lo: 0, hi: 1, minor: 0.1, labels: labels, target: t, call: bFmt(t), say: bSay(t),
                          tol: max(0.025, share))
            }
            let labels = thin(6.6, all: stride(0, 10, 1), mid: [0, 5, 10], ends: [0, 10])
            let t = Double(r(1...9)) + Double(r(1...9)) / 10
            return BQ(lo: 0, hi: 10, minor: 1, labels: labels, target: (t * 10).rounded() / 10, call: bFmt(t), say: bSay(t),
                      tol: max(0.2, 10 * share))
        default:  // challenges
            switch r(0...4) {
            case 0:   // a product on 0–100
                let a = r(3...9), b = r(3...9)
                let t = Double(a * b)
                return BQ(lo: 0, hi: 100, minor: 10, labels: [0, 50, 100], target: t, call: "\(a) × \(b)",
                          sub: "work it out, then aim", say: "\(a) times \(b)", tol: max(2, 100 * share))
            case 1:   // a sum or difference on 0–1000
                let a = r(12...60) * 10, b = r(5...35) * 10
                let plus = a + b <= 990 && Bool.random()
                let t = Double(plus ? a + b : a - b)
                if t <= 0 { fallthrough }
                return BQ(lo: 0, hi: 1000, minor: 100, labels: [0, 500, 1000], target: t,
                          call: "\(a) \(plus ? "+" : "−") \(b)", sub: "work it out, then aim",
                          say: "\(a) \(plus ? "plus" : "minus") \(b)", tol: 1000 * share)
            case 2:   // signed sums on −20…20
                let a = r(-12...12), b = r(-12...12)
                let t = Double(a + b)
                if b == 0 || abs(t) > 19 || a == 0 { fallthrough }
                let bs = b < 0 ? "− \(-b)" : "+ \(b)"
                return BQ(lo: -20, hi: 20, minor: 5, labels: [-20, 0, 20], target: t,
                          call: "\(bFmt(Double(a))) \(bs)", sub: "work it out, then aim",
                          say: "\(bSay(Double(a))) \(b < 0 ? "minus" : "plus") \(abs(b))", snap: 1, tol: 0.4)
            case 3:   // halfway between two marked numbers
                let a = r(2...40) * 10, gap = r(2...25) * 20
                let b = a + gap
                if b > 980 { fallthrough }
                let t = Double(a + b) / 2
                return BQ(lo: 0, hi: 1000, minor: 100, labels: [0, Double(a), Double(b), 1000], target: t,
                          call: "Halfway", sub: "between \(a) and \(b)", say: "halfway between \(a) and \(b)",
                          tol: 1000 * share)
            default:  // 0–10 000
                let t = Double(r(1...19) * 500 + (Bool.random() ? 0 : r(1...4) * 100))
                return BQ(lo: 0, hi: 10_000, minor: 1000, labels: [0, 5000, 10_000], target: min(9900, t),
                          call: bFmt(min(9900, t)), say: bSay(min(9900, t)), tol: 10_000 * share)
            }
        }
    }
}

// MARK: - View

struct TempleBallistaView: View {
    let onClose: () -> Void
    @StateObject private var model = BallistaModel()

    var body: some View {
        ArcadeShell(model: model,
                    spec: GameID.ballista.spec ?? GameSpec(title: "Ballista", mechanic: "aim", premise: "", game: .ballista),
                    accent: Lu.tangerine, onClose: { LibraryVoice.stop(); onClose() },
                    backdrop: { BallistaRange() }) {
            BallistaPlay(model: model)
        }
        .onDisappear { LibraryVoice.stop() }
    }
}

/// The practice range: dawn sky, a sun, rolling hills with cypresses, a grassy field.
private struct BallistaRange: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Color(hex: 0x3d6fa8), Color(hex: 0x8fb9d9), Color(hex: 0xf3d9a4)],
                               startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.5))
                Circle().fill(RadialGradient(colors: [Color(hex: 0xfff4c4), Color(hex: 0xf8c95a).opacity(0)],
                                             center: .center, startRadius: 10, endRadius: 90))
                    .frame(width: 180, height: 180).position(x: w * 0.78, y: h * 0.27)
                Circle().fill(Color(hex: 0xfff1b8)).frame(width: 54).position(x: w * 0.78, y: h * 0.27)
                Hills(phase: 0.3, amp: 0.035, base: 0.40).fill(Color(hex: 0x8aa37a))
                Hills(phase: 2.1, amp: 0.03, base: 0.44).fill(Color(hex: 0x6f9460))
                ForEach(0..<5) { i in
                    let x = w * [0.08, 0.15, 0.62, 0.88, 0.94][i]
                    Capsule().fill(Color(hex: 0x2f5a33)).frame(width: 12, height: [44, 32, 38, 50, 34][i])
                        .position(x: x, y: h * 0.44 - CGFloat([44, 32, 38, 50, 34][i]) / 2 + 6)
                }
                LinearGradient(colors: [Color(hex: 0x6aa04f), Color(hex: 0x4f8a3c), Color(hex: 0x3d6f30)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: h * 0.54).offset(y: h * 0.46)
                // A worn path from the ballista out to the line.
                Path { p in
                    p.move(to: CGPoint(x: w * 0.42, y: h))
                    p.addLine(to: CGPoint(x: w * 0.47, y: h * 0.6))
                    p.addLine(to: CGPoint(x: w * 0.53, y: h * 0.6))
                    p.addLine(to: CGPoint(x: w * 0.58, y: h))
                }
                .fill(Color(hex: 0xb79a63).opacity(0.35))
                // Grass tufts
                ForEach(0..<14) { i in
                    let x = w * CGFloat((i * 37) % 100) / 100, y = h * (0.62 + CGFloat((i * 53) % 34) / 100)
                    Text("ʌʌ").font(.system(size: 12, weight: .bold)).foregroundStyle(Color(hex: 0x2f5f2a).opacity(0.6))
                        .position(x: x, y: y)
                }
            }
        }
    }
}

private struct Hills: Shape {
    let phase: Double, amp: Double, base: Double
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: r.height))
        for i in 0...40 {
            let x = Double(i) / 40
            let y = base + amp * sin(x * 5.2 + phase) + amp * 0.5 * sin(x * 11 + phase * 2)
            p.addLine(to: CGPoint(x: r.width * x, y: r.height * y))
        }
        p.addLine(to: CGPoint(x: r.width, y: r.height))
        p.closeSubpath()
        return p
    }
}

private struct BallistaPlay: View {
    @ObservedObject var model: BallistaModel
    @State private var flight: CGFloat = 0
    @State private var dragging = false
    @State private var cheer = false

    private var q: BQ { model.q }

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let x0: CGFloat = 30, x1 = w - 30
            let lineY = h * 0.56
            let engine = CGPoint(x: w / 2, y: h - 74)
            let xOf: (Double) -> CGFloat = { v in x0 + CGFloat((v - q.lo) / q.span) * (x1 - x0) }
            let vOf: (CGFloat) -> Double = { x in q.lo + Double((x - x0) / (x1 - x0)) * q.span }

            ZStack(alignment: .topLeading) {
                // The whole field aims: drag sets the aim, letting go fires.
                Color.clear.contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            guard model.stage == .aiming, model.phase == .playing, v.startLocation.y > 190 else { return }
                            let nv = model.settle(vOf(v.location.x))
                            if model.aim.map({ abs($0 - nv) > 1e-9 }) ?? true, q.snap != nil { Sfx.play(.tick, volume: 0.5) }
                            if !dragging { dragging = true; Haptics.light() }
                            model.aim = nv
                        }
                        .onEnded { v in
                            guard dragging else { return }
                            dragging = false
                            if let a = model.aim { model.fire(at: a) }
                        })

                NumberLine(q: q, x0: x0, x1: x1, y: lineY)
                    .allowsHitTesting(false)

                aimGuide(engine: engine, lineY: lineY, xOf: xOf)
                    .allowsHitTesting(false)

                reveal(lineY: lineY, xOf: xOf)
                    .allowsHitTesting(false)

                stone(engine: engine, lineY: lineY, xOf: xOf)
                    .allowsHitTesting(false)

                BallistaEngine(angle: engineAngle(engine: engine, lineY: lineY, xOf: xOf),
                               loaded: model.stage == .aiming)
                    .position(engine)
                    .allowsHitTesting(false)

                Legionary(cheer: cheer, sad: model.stage == .landed && !model.wasHit)
                    .position(x: w - 58, y: h - 70)
                    .allowsHitTesting(false)

                callSign
                    .frame(width: w - 28)
                    .position(x: w / 2, y: 122)
            }
        }
        .padding(.top, 4)
        .onChange(of: model.shotID) { _ in
            flight = 0
            withAnimation(.timingCurve(0.3, 0.1, 0.7, 1, duration: 0.7)) { flight = 1 }
        }
        .onChange(of: model.stage) { s in
            if s == .landed && model.wasHit {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { cheer = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { withAnimation(.spring()) { cheer = false } }
            }
        }
        .onChange(of: model.roundID) { _ in flight = 0 }
    }

    private func engineAngle(engine: CGPoint, lineY: CGFloat, xOf: (Double) -> CGFloat) -> Double {
        guard let a = model.aim else { return 0 }
        let dx = xOf(a) - engine.x, dy = engine.y - lineY
        return atan2(Double(dx), Double(dy)) * 180 / .pi
    }

    // MARK: Call sign

    private var callSign: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(model.q.sub == nil ? "HIT" : "AIM FOR").font(luFont(12, .heavy)).tracking(2)
                    .foregroundStyle(Color(hex: 0x5b3a1c))
                Text(q.call).font(luSerif(q.call.count > 7 ? 34 : 46, .black)).foregroundStyle(Color(hex: 0x2b1708))
                    .lineLimit(1).minimumScaleFactor(0.5)
                if let s = q.sub {
                    Text(s).font(luFont(16, .heavy)).foregroundStyle(Color(hex: 0x5b3a1c))
                        .lineLimit(1).minimumScaleFactor(0.6)
                }
                if q.dots > 0 { CountDots(n: q.dots) }
            }
            .frame(maxWidth: .infinity)
            LibrarySpeakerButton(size: 46) { model.sayCall() }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(WoodSign())
        .id(model.roundID)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: model.roundID)
    }

    // MARK: Aim guide

    @ViewBuilder
    private func aimGuide(engine: CGPoint, lineY: CGFloat, xOf: @escaping (Double) -> CGFloat) -> some View {
        if model.stage == .aiming, let a = model.aim {
            let ax = xOf(a)
            ZStack(alignment: .topLeading) {
                Path { p in
                    p.move(to: CGPoint(x: engine.x, y: engine.y - 30))
                    p.addQuadCurve(to: CGPoint(x: ax, y: lineY),
                                   control: CGPoint(x: (engine.x + ax) / 2, y: lineY - 150))
                }
                .stroke(Color.white.opacity(0.75), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 9]))
                Circle().stroke(Color(hex: Lu.coral), lineWidth: 4).frame(width: 34, height: 34)
                    .overlay(Rectangle().fill(Color(hex: Lu.coral)).frame(width: 2, height: 46))
                    .position(x: ax, y: lineY)
            }
        }
    }

    // MARK: Stone in flight / resting

    @ViewBuilder
    private func stone(engine: CGPoint, lineY: CGFloat, xOf: @escaping (Double) -> CGFloat) -> some View {
        if let s = model.shot, model.stage != .aiming {
            let to = CGPoint(x: xOf(s), y: lineY - 4)
            Circle().fill(RadialGradient(colors: [Color(hex: 0xd9d4c7), Color(hex: 0x7d766a)], center: UnitPoint(x: 0.35, y: 0.3),
                                         startRadius: 1, endRadius: 14))
                .frame(width: 22, height: 22)
                .modifier(ArcFlight(t: flight, from: CGPoint(x: engine.x, y: engine.y - 30), to: to, peak: 190))
                .opacity(model.stage == .landed && model.wasHit ? 0 : 1)
            if model.stage == .landed {
                Dust(hit: model.wasHit).position(to)
            }
        }
    }

    // MARK: Reveal — the pot at the true spot

    @ViewBuilder
    private func reveal(lineY: CGFloat, xOf: @escaping (Double) -> CGFloat) -> some View {
        if model.stage == .landed {
            let tx = xOf(q.target)
            ZStack(alignment: .topLeading) {
                if model.wasHit {
                    Shards().position(x: tx, y: lineY - 26)
                    Text(model.bullseye ? "BULLSEYE!" : ["SMASH!", "CRACK!", "BULL'S-EYE!"][model.roundID % 2])
                        .font(luFont(30)).foregroundStyle(Color(hex: Lu.gold))
                        .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
                        .position(x: min(max(tx, 90), xOf(q.hi) - 60), y: lineY - 92)
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                } else {
                    if let s = model.shot {
                        let sx = xOf(s)
                        Path { p in
                            p.move(to: CGPoint(x: sx, y: lineY + 34)); p.addLine(to: CGPoint(x: sx, y: lineY + 42))
                            p.addLine(to: CGPoint(x: tx, y: lineY + 42)); p.addLine(to: CGPoint(x: tx, y: lineY + 34))
                        }
                        .stroke(Color(hex: Lu.coral), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    }
                    PotOnPost(label: q.sub == nil ? q.call : bFmt(q.target))
                        .position(x: tx, y: lineY - 44)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: model.stage)
        }
    }
}

/// A wooden plank sign, hung by two ropes.
private struct WoodSign: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [Color(hex: 0xe2b77a), Color(hex: 0xc48f52)], startPoint: .top, endPoint: .bottom))
            VStack(spacing: 14) {
                ForEach(0..<3) { _ in Rectangle().fill(Color(hex: 0x9a6a36).opacity(0.25)).frame(height: 1.5) }
            }
            .padding(.horizontal, 10)
            RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0x6e4520), lineWidth: 3)
            HStack {
                Circle().fill(Color(hex: 0x5a3a1c)).frame(width: 7)
                Spacer()
                Circle().fill(Color(hex: 0x5a3a1c)).frame(width: 7)
            }
            .padding(.horizontal, 10)
            .frame(maxHeight: .infinity, alignment: .top).padding(.top, 8)
        }
        .shadow(color: .black.opacity(0.3), radius: 0, x: 0, y: 4)
    }
}

/// Up to 10 counting dots in rows of five.
private struct CountDots: View {
    let n: Int
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<((n + 4) / 5), id: \.self) { row in
                HStack(spacing: 5) {
                    ForEach(0..<min(5, n - row * 5), id: \.self) { _ in
                        Circle().fill(Color(hex: Lu.coral)).frame(width: 13, height: 13)
                            .overlay(Circle().stroke(Color(hex: 0x6e2a1c), lineWidth: 1.5))
                    }
                }
            }
        }
        .padding(.top, 2)
    }
}

/// The long wooden number line with stakes and stone milestones carrying the labels.
private struct NumberLine: View {
    let q: BQ
    let x0: CGFloat, x1: CGFloat, y: CGFloat

    var body: some View {
        Canvas { ctx, _ in
            let x: (Double) -> CGFloat = { v in x0 + CGFloat((v - q.lo) / q.span) * (x1 - x0) }
            // Shadow + beam
            ctx.fill(Path(roundedRect: CGRect(x: x0 - 12, y: y + 3, width: x1 - x0 + 24, height: 14), cornerRadius: 7),
                     with: .color(.black.opacity(0.2)))
            ctx.fill(Path(roundedRect: CGRect(x: x0 - 12, y: y - 7, width: x1 - x0 + 24, height: 14), cornerRadius: 7),
                     with: .linearGradient(Gradient(colors: [Color(hex: 0xc99359), Color(hex: 0x8a5a2b)]),
                                           startPoint: CGPoint(x: 0, y: y - 7), endPoint: CGPoint(x: 0, y: y + 7)))
            ctx.stroke(Path(roundedRect: CGRect(x: x0 - 12, y: y - 7, width: x1 - x0 + 24, height: 14), cornerRadius: 7),
                       with: .color(Color(hex: 0x5a3818)), lineWidth: 2)
            // Ticks (stakes)
            let n = Int((q.span / q.minor).rounded())
            let showHalf = n <= 10 && q.minor >= 1 && q.span > 20
            for i in 0...n {
                let v = q.lo + Double(i) * q.minor
                let isLabel = q.labels.contains { abs($0 - v) < q.minor * 0.01 }
                let tx = x(v)
                let tall: CGFloat = isLabel ? 22 : 14
                ctx.fill(Path(roundedRect: CGRect(x: tx - 2, y: y - tall, width: 4, height: tall), cornerRadius: 1.5),
                         with: .color(Color(hex: 0x4a2c12)))
                if showHalf && i < n {
                    let hx = x(v + q.minor / 2)
                    ctx.fill(Path(CGRect(x: hx - 1, y: y - 8, width: 2, height: 8)), with: .color(Color(hex: 0x4a2c12).opacity(0.5)))
                }
            }
            // Milestones with labels
            for v in q.labels {
                let tx = x(v)
                let text = ctx.resolve(Text(bFmt(v)).font(luFont(q.labels.count > 9 ? 13 : 16, .heavy))
                    .foregroundColor(Color(hex: 0x2d2a26)))
                let tw = max(24, text.measure(in: CGSize(width: 200, height: 40)).width + 10)
                let rect = CGRect(x: tx - tw / 2, y: y + 10, width: tw, height: 24)
                var stone = Path()
                stone.addRoundedRect(in: rect, cornerSize: CGSize(width: 8, height: 8))
                ctx.fill(stone, with: .color(Color(hex: 0xe9e3d3)))
                ctx.stroke(stone, with: .color(Color(hex: 0x8d8576)), lineWidth: 1.5)
                ctx.draw(text, at: CGPoint(x: tx, y: y + 22))
            }
        }
    }
}

/// Moves a view along a parabola from `from` to `to` as `t` goes 0 → 1.
private struct ArcFlight: GeometryEffect {
    var t: CGFloat
    let from: CGPoint, to: CGPoint
    let peak: CGFloat
    var animatableData: CGFloat { get { t } set { t = newValue } }
    func effectValue(size: CGSize) -> ProjectionTransform {
        let x = from.x + (to.x - from.x) * t
        let y = from.y + (to.y - from.y) * t - peak * 4 * t * (1 - t)
        let s = 1 - 0.35 * t
        let tf = CGAffineTransform(translationX: x - size.width / 2, y: y - size.height / 2)
            .translatedBy(x: size.width / 2, y: size.height / 2).scaledBy(x: s, y: s)
            .translatedBy(x: -size.width / 2, y: -size.height / 2)
        return ProjectionTransform(tf)
    }
}

/// A puff of dust (miss) or a ring of gold sparks (hit).
private struct Dust: View {
    let hit: Bool
    @State private var go = false
    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                let a = Double(i) / 8 * 2 * .pi
                Circle().fill(hit ? Color(hex: Lu.gold) : Color(hex: 0xcdb48a))
                    .frame(width: hit ? 8 : 14, height: hit ? 8 : 14)
                    .offset(x: go ? CGFloat(cos(a)) * 34 : 0, y: go ? CGFloat(sin(a)) * 16 - 8 : 0)
                    .opacity(go ? 0 : 0.9)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { go = true } }
    }
}

/// A clay pot bursting into shards.
private struct Shards: View {
    @State private var go = false
    var body: some View {
        ZStack {
            ForEach(0..<9) { i in
                let a = Double(i) / 9 * 2 * .pi - .pi / 2
                ShardShape().fill(Color(hex: i % 2 == 0 ? 0xc0643a : 0xa44f2c))
                    .frame(width: 16, height: 13)
                    .rotationEffect(.degrees(go ? Double(i * 90) : 0))
                    .offset(x: go ? CGFloat(cos(a)) * 70 : 0, y: go ? CGFloat(sin(a)) * 50 + 30 : 0)
                    .opacity(go ? 0 : 1)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.8)) { go = true } }
    }
}
private struct ShardShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY)); p.addLine(to: CGPoint(x: r.midX * 0.8, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY)); p.closeSubpath()
        return p
    }
}

/// The pot that was hiding there, on its post, with a flag showing its number.
private struct PotOnPost: View {
    let label: String
    var body: some View {
        VStack(spacing: -4) {
            Text(label).font(luFont(20, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                .padding(.horizontal, 9).padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: Lu.gold)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0x7a5a12), lineWidth: 2))
                .fixedSize()
                .padding(.bottom, 6)
            ZStack {
                Ellipse().fill(LinearGradient(colors: [Color(hex: 0xd77a48), Color(hex: 0x9c4a26)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 30, height: 30)
                RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xb85f35)).frame(width: 14, height: 10).offset(y: -17)
                Capsule().fill(Color(hex: 0xf3d3a0).opacity(0.6)).frame(width: 24, height: 3).offset(y: -2)
            }
            Rectangle().fill(Color(hex: 0x5a3818)).frame(width: 5, height: 22)
        }
    }
}

/// The siege engine: a wheeled base and a bow-armed slider that swings toward the aim.
private struct BallistaEngine: View {
    let angle: Double
    let loaded: Bool
    var body: some View {
        ZStack {
            // Base
            Trapezoid().fill(LinearGradient(colors: [Color(hex: 0x9a6634), Color(hex: 0x6b4220)], startPoint: .top, endPoint: .bottom))
                .frame(width: 110, height: 34).offset(y: 26)
            HStack(spacing: 64) {
                Wheel()
                Wheel()
            }
            .offset(y: 44)
            // Swivel part
            ZStack {
                RoundedRectangle(cornerRadius: 5).fill(Color(hex: 0x8a5a2b)).frame(width: 18, height: 82).offset(y: -18)
                BowArc().stroke(Color(hex: 0x5a3818), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 30).offset(y: -40)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: 50, y: loaded ? 26 : 2)); p.addLine(to: CGPoint(x: 100, y: 0))
                }
                .stroke(Color(hex: 0xf1e6cc), lineWidth: 2).frame(width: 100, height: 30).offset(y: -40)
                if loaded {
                    Circle().fill(RadialGradient(colors: [Color(hex: 0xd9d4c7), Color(hex: 0x7d766a)], center: UnitPoint(x: 0.35, y: 0.3),
                                                 startRadius: 1, endRadius: 12))
                        .frame(width: 20).offset(y: -18)
                }
            }
            .rotationEffect(.degrees(angle * 0.85), anchor: UnitPoint(x: 0.5, y: 0.75))
            .animation(.interactiveSpring(), value: angle)
        }
        .frame(width: 130, height: 120)
    }
}
private struct Wheel: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0x4a2c12)).frame(width: 30)
            Circle().stroke(Color(hex: 0xb07d48), lineWidth: 3).frame(width: 22)
            Rectangle().fill(Color(hex: 0xb07d48)).frame(width: 3, height: 22)
            Rectangle().fill(Color(hex: 0xb07d48)).frame(width: 22, height: 3)
        }
    }
}
private struct Trapezoid: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.15, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX - r.width * 0.15, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.closeSubpath()
        return p
    }
}
private struct BowArc: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY + 10))
        return p
    }
}

/// A little legionary who works the ballista — cheers on a hit, droops on a miss.
private struct Legionary: View {
    let cheer: Bool, sad: Bool
    var body: some View {
        ZStack {
            // Arms
            Capsule().fill(Color(hex: 0xf0c49a)).frame(width: 10, height: 34)
                .rotationEffect(.degrees(cheer ? 150 : 20), anchor: .top).offset(x: -15, y: 2)
            Capsule().fill(Color(hex: 0xf0c49a)).frame(width: 10, height: 34)
                .rotationEffect(.degrees(cheer ? -150 : -20), anchor: .top).offset(x: 15, y: 2)
            // Tunic + belt
            Trapezoid().fill(Color(hex: 0xb8322a)).frame(width: 36, height: 42).offset(y: 18)
            Rectangle().fill(Color(hex: 0x6b4220)).frame(width: 30, height: 5).offset(y: 14)
            // Head + helmet + crest
            Circle().fill(Color(hex: 0xf0c49a)).frame(width: 30).offset(y: -14)
            HalfDisc().fill(LinearGradient(colors: [Color(hex: 0xd9d9d9), Color(hex: 0x8c8c8c)], startPoint: .top, endPoint: .bottom))
                .frame(width: 34, height: 18).offset(y: -24)
            Capsule().fill(Color(hex: 0xd33b2c)).frame(width: 26, height: 9).offset(y: -35)
            // Face
            HStack(spacing: 8) { Circle().fill(Color.black).frame(width: 4); Circle().fill(Color.black).frame(width: 4) }.offset(y: -12)
            SmileArc(up: !sad).stroke(Color(hex: 0x5a2a12), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 12, height: 5).offset(y: -4)
            // Legs
            HStack(spacing: 8) {
                Capsule().fill(Color(hex: 0xf0c49a)).frame(width: 8, height: 16)
                Capsule().fill(Color(hex: 0xf0c49a)).frame(width: 8, height: 16)
            }
            .offset(y: 44)
        }
        .offset(y: cheer ? -8 : 0)
        .frame(width: 70, height: 110)
    }
}
private struct HalfDisc: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: r.midX, y: r.maxY), radius: r.width / 2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.closeSubpath()
        return p
    }
}
private struct SmileArc: Shape {
    let up: Bool
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: up ? r.minY : r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: up ? r.minY : r.maxY), control: CGPoint(x: r.midX, y: up ? r.maxY + 3 : r.minY - 3))
        return p
    }
}
