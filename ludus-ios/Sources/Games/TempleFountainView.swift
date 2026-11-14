import SwiftUI

// MARK: - Leo's Fountain  (Number Crunchers · pour)
//
// In a sunny courtyard a bronze lion-head spout (Leo) fills glass jugs. The order card says how
// full: ½, ¾, 2⁄3, 0.7, 40 %, ½ + ¼ … Press and HOLD anywhere: Leo opens his mouth and water pours.
// Let go to stop — one pour per jug. Close enough to the order: Leo grins and the jug sparkles.
// Off: a gold ribbon drops onto the jug at the right level and the water slides to it ("this is
// ¾"), so every miss shows the answer. Pour over the brim and it splashes everywhere.
//
// Strand: fractions as "how full" → unit & non-unit fractions → decimals → percentages →
// equivalents → fraction / decimal arithmetic. Tuned off `d`:
//   • content kind via `tier` (halves & quarters with a ribbon at the target → marks only →
//     thirds/fifths/sixths → tenths as decimals → percentages & equivalents → sums/differences);
//   • the jug's marks fade out (and later lie in a DIFFERENT denominator, so it's estimation);
//   • the flow speeds up (a full jug in ~6 s → ~2.4 s) and the "close enough" window shrinks.

// MARK: Content

private enum FPart: Hashable { case frac(Int, Int), txt(String) }

private struct FOrder {
    var target: Double
    var parts: [FPart]
    var say: String
    var ribbon = false           // the target level is drawn on the jug (the very start)
    var marks = 0                // parts the jug's side is marked in (0 = no marks)
    var picture = false          // a little jug icon on the card shows the level
}

private func fGcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : fGcd(b, a % b) }

private func fSay(_ n: Int, _ d: Int) -> String {
    let names = [2: "half", 3: "third", 4: "quarter", 5: "fifth", 6: "sixth", 8: "eighth", 10: "tenth", 12: "twelfth"]
    let nums = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven"]
    let base = names[d] ?? "\(d)th"
    if n == 1 { return "one " + base }
    return (n < nums.count ? nums[n] : "\(n)") + " " + (base == "half" ? "halves" : base + "s")
}

private func fDec(_ x: Double) -> String {
    var s = String(format: "%.2f", x)
    while s.hasSuffix("0") { s.removeLast() }
    if s.hasSuffix(".") { s.removeLast() }
    return s
}

// MARK: Model

@MainActor
private final class FountainModel: ArcadeModel {
    enum Stage { case ready, pouring, judging, done }

    @Published var order = FOrder(target: 0.5, parts: [.frac(1, 2)], say: "one half", ribbon: true, marks: 2, picture: true)
    @Published var stage: Stage = .ready
    @Published var water: Double = 0           // settled level (0…1.1)
    @Published var pourStart: Date?
    @Published var good = false
    @Published var perfect = false
    @Published var spilled = false
    @Published var showAnswer = false
    @Published var roundID = 0

    var flow: Double { ramp(0.16, 0.42, to: 9) }          // jugs per second
    var tol: Double { ramp(0.075, 0.025, to: 9.5) }

    private var gen = 0
    private var overflow: DispatchWorkItem?

    init() { super.init(key: GameID.fountain.rawValue) }

    override func onBegin() { next() }

    private func later(_ t: Double, _ f: @escaping (FountainModel) -> Void) {
        let g = gen
        DispatchQueue.main.asyncAfter(deadline: .now() + t) { [weak self] in
            guard let self, self.gen == g, self.phase == .playing else { return }
            f(self)
        }
    }

    private func next() {
        gen += 1
        overflow?.cancel()
        var o = makeOrder()
        var n = 0
        while abs(o.target - order.target) < 0.001 && n < 6 { o = makeOrder(); n += 1 }
        order = o
        water = 0; pourStart = nil; good = false; perfect = false; spilled = false; showAnswer = false
        stage = .ready
        roundID += 1
        if d < 4 { LibraryVoice.say("Fill it to " + o.say, rate: 0.45) }
    }

    func sayOrder() { LibraryVoice.say("Fill it to " + order.say, rate: 0.45) }

    /// The live level while pouring (time-based, so no per-frame state).
    func liveLevel(at t: Date) -> Double {
        guard let s = pourStart else { return water }
        return water + flow * max(0, t.timeIntervalSince(s))
    }

    func startPour() {
        guard phase == .playing, stage == .ready else { return }
        stage = .pouring
        pourStart = Date()
        Sfx.play(.whoosh, volume: 0.5)
        Haptics.light()
        let left = (1.0 - water) / flow
        let item = DispatchWorkItem { [weak self] in
            guard let self, self.stage == .pouring else { return }
            self.spilled = true
            self.stopPour()
        }
        overflow = item
        DispatchQueue.main.asyncAfter(deadline: .now() + left, execute: item)
    }

    func stopPour() {
        guard stage == .pouring, let s = pourStart else { return }
        overflow?.cancel()
        water = min(1, water + flow * Date().timeIntervalSince(s))
        pourStart = nil
        stage = .judging
        later(0.35) { $0.judge() }
    }

    private func judge() {
        let err = abs(water - order.target)
        if !spilled && err <= tol {
            good = true
            perfect = err <= tol * 0.35
            stage = .done
            Sfx.play(.sparkle)
            hit(points: perfect ? 2 : 1)
            later(1.3) { $0.next() }
        } else {
            good = false
            stage = .done
            if spilled { Sfx.play(.whoosh) }
            miss(reason: spilled ? "Splash!" : "Out of hearts!", delay: 2.6)
            later(0.4) { m in
                m.showAnswer = true
                withAnimation(.easeInOut(duration: 0.9)) { m.water = m.order.target }
                LibraryVoice.say("This is " + m.order.say, rate: 0.48)
            }
            later(2.8) { m in if !m.dying { m.next() } }
        }
    }

    override func botAct(correct: Bool) {
        guard stage == .ready else { return }
        let aim = correct ? order.target + Double.random(in: -0.3...0.3) * tol
                          : order.target + (Bool.random() || order.target < 0.25 ? 1 : -1) * tol * Double.random(in: 1.8...3)
        startPour()
        let t = max(0.05, (min(0.99, aim) - water) / flow)
        later(t) { $0.stopPour() }
    }

    // MARK: Orders

    private func makeOrder() -> FOrder {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b) }
        let marksGone = chance(1, from: 3.6, to: 5.6)          // the jug's side marks fade out
        let k = tier([1, 2, 3, 4.3, 5.3, 6.3, 7.3])
        switch k {
        case 0:   // halves and quarters, with a ribbon at the level
            let (n, dd) = [(1, 2), (1, 4), (3, 4), (1, 2)].randomElement()!
            return FOrder(target: Double(n) / Double(dd), parts: [.frac(n, dd)], say: fSay(n, dd),
                          ribbon: d < 1.8, marks: dd, picture: true)
        case 1:   // halves & quarters & whole-ish, marks only
            let (n, dd) = [(1, 2), (1, 4), (3, 4), (2, 4)].randomElement()!
            return FOrder(target: Double(n) / Double(dd), parts: [.frac(n, dd)], say: fSay(n, dd),
                          marks: marksGone ? 0 : 4, picture: d < 2.6)
        case 2:   // thirds, fifths, sixths, eighths
            let dd = [3, 5, 6, 8].randomElement()!, n = r(1, dd - 1)
            if fGcd(n, dd) != 1 { fallthrough }
            return FOrder(target: Double(n) / Double(dd), parts: [.frac(n, dd)], say: fSay(n, dd),
                          marks: marksGone ? (chance(1, from: 5, to: 7) ? [4, 10].randomElement()! : 0) : dd)
        case 3:   // decimals
            let t = Double(r(1, 9)) / 10 + (chance(0.5, from: 5, to: 7) ? 0.05 : 0)
            return FOrder(target: t, parts: [.txt(fDec(t))], say: fDec(t).replacingOccurrences(of: "0.", with: "zero point "),
                          marks: marksGone ? 0 : 10)
        case 4:   // percentages
            let p = [10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90].randomElement()!
            return FOrder(target: Double(p) / 100, parts: [.txt("\(p)%")], say: "\(p) percent",
                          marks: marksGone ? 0 : (p % 10 == 0 ? 10 : 4))
        case 5:   // equivalents & non-unit fractions in bigger denominators
            let base = [(1, 2), (1, 3), (2, 3), (1, 4), (3, 4), (2, 5), (3, 5)].randomElement()!
            let m = r(2, 4)
            let n = base.0 * m, dd = base.1 * m
            return FOrder(target: Double(base.0) / Double(base.1), parts: [.frac(n, dd)], say: fSay(n, dd),
                          marks: marksGone ? 0 : base.1)
        default:  // arithmetic
            switch r(0, 3) {
            case 0:   // a/b + c/d
                let pairs = [((1, 2), (1, 4)), ((1, 3), (1, 3)), ((1, 4), (1, 4)), ((1, 3), (1, 6)), ((1, 2), (1, 3)),
                             ((1, 4), (1, 2)), ((2, 5), (1, 5)), ((1, 6), (1, 2)), ((1, 8), (1, 2))]
                let (a, b) = pairs.randomElement()!
                let t = Double(a.0) / Double(a.1) + Double(b.0) / Double(b.1)
                return FOrder(target: t, parts: [.frac(a.0, a.1), .txt("+"), .frac(b.0, b.1)],
                              say: fSay(a.0, a.1) + " plus " + fSay(b.0, b.1))
            case 1:   // 1 − a/b
                let (n, dd) = [(1, 3), (1, 4), (3, 4), (2, 5), (1, 6), (3, 8)].randomElement()!
                return FOrder(target: 1 - Double(n) / Double(dd), parts: [.txt("1 −"), .frac(n, dd)],
                              say: "one minus " + fSay(n, dd))
            case 2:   // a fraction of a fraction
                let (a, b) = [((1, 2), (1, 2)), ((1, 2), (3, 4)), ((2, 3), (3, 4)), ((1, 3), (3, 4)), ((1, 2), (4, 5))].randomElement()!
                let t = Double(a.0 * b.0) / Double(a.1 * b.1)
                return FOrder(target: t, parts: [.frac(a.0, a.1), .txt("of"), .frac(b.0, b.1)],
                              say: fSay(a.0, a.1) + " of " + fSay(b.0, b.1))
            default:  // decimals sum
                let a = Double(r(1, 4)) / 10, b = Double(r(1, 9)) * 0.05
                let t = a + b
                return FOrder(target: t, parts: [.txt("\(fDec(a)) + \(fDec(b))")],
                              say: "\(fDec(a)) plus \(fDec(b))")
            }
        }
    }
}

// MARK: - View

struct TempleFountainView: View {
    let onClose: () -> Void
    @StateObject private var model = FountainModel()

    var body: some View {
        ArcadeShell(model: model,
                    spec: GameID.fountain.spec ?? GameSpec(title: "Leo's Fountain", mechanic: "pour", premise: "", game: .fountain),
                    accent: Lu.sky, onClose: { LibraryVoice.stop(); onClose() },
                    backdrop: { Courtyard() }) {
            FountainPlay(model: model)
        }
        .onDisappear { LibraryVoice.stop() }
    }
}

/// A sunny courtyard: blue sky, a stone wall with ivy, a terracotta roof edge, the fountain basin.
private struct Courtyard: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Color(hex: 0x5aa3d8), Color(hex: 0xb5dcf0)], startPoint: .top, endPoint: .bottom)
                // Roof tiles
                HStack(spacing: 0) {
                    ForEach(0..<16) { _ in
                        Capsule().fill(LinearGradient(colors: [Color(hex: 0xd2704a), Color(hex: 0x9a4426)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 30, height: 30)
                    }
                }
                .frame(width: w, alignment: .leading)
                .offset(y: h * 0.15)
                // Stone wall
                Canvas { ctx, sz in
                    let top = sz.height * 0.18
                    ctx.fill(Path(CGRect(x: 0, y: top, width: sz.width, height: sz.height - top)), with: .color(Color(hex: 0xd9c9a6)))
                    var y = top, row = 0
                    let bh: CGFloat = 34
                    while y < sz.height {
                        var x: CGFloat = row % 2 == 0 ? -20 : -50
                        while x < sz.width {
                            let shade: Double = 0.06 * Double((Int(x) / 60 + row) % 3)
                            ctx.fill(Path(roundedRect: CGRect(x: x + 2, y: y + 2, width: 60 - 4, height: bh - 4), cornerRadius: 4),
                                     with: .color(Color(hex: 0xe8dbbb).opacity(1 - shade)))
                            x += 60
                        }
                        y += bh; row += 1
                    }
                }
                // Ivy down the sides
                ForEach(0..<9) { i in
                    Text("🌿").font(.system(size: 26)).rotationEffect(.degrees(Double(i * 40)))
                        .position(x: i % 2 == 0 ? 14 : 30, y: h * 0.2 + CGFloat(i) * 28)
                    Text("🌿").font(.system(size: 24)).rotationEffect(.degrees(Double(-i * 35)))
                        .position(x: w - (i % 2 == 0 ? 16 : 32), y: h * 0.22 + CGFloat(i) * 26)
                }
                // Basin
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: [Color(hex: 0xcfc6b3), Color(hex: 0x9b927f)], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.9, height: h * 0.16)
                    .position(x: w / 2, y: h * 0.86)
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [Color(hex: 0x4d9cc9), Color(hex: 0x2f6f99)], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.8, height: 22)
                    .position(x: w / 2, y: h * 0.795)
                Capsule().fill(Color(hex: 0xe9e2d1)).frame(width: w * 0.94, height: 16).position(x: w / 2, y: h * 0.78)
            }
        }
    }
}

private struct FountainPlay: View {
    @ObservedObject var model: FountainModel
    @State private var holding = false

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let jugW = min(150, w * 0.38), jugH = min(250, h * 0.32)
            let jugBottom = h * 0.79
            let jugRect = CGRect(x: w / 2 - jugW / 2, y: jugBottom - jugH, width: jugW, height: jugH)
            let mouth = CGPoint(x: w / 2, y: jugRect.minY - 56)

            ZStack(alignment: .topLeading) {
                // Hold anywhere to pour.
                Color.clear.contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            guard !holding else { return }
                            holding = true
                            model.startPour()
                        }
                        .onEnded { _ in
                            holding = false
                            model.stopPour()
                        })

                orderCard.frame(width: w - 28).position(x: w / 2, y: 112)

                TimelineView(.animation(minimumInterval: 1 / 60, paused: model.phase != .playing)) { tl in
                    let lv = model.stage == .pouring ? model.liveLevel(at: tl.date) : model.water
                    let t = tl.date.timeIntervalSinceReferenceDate
                    ZStack(alignment: .topLeading) {
                        if model.stage == .pouring {
                            Stream(t: t)
                                .frame(width: 16, height: max(0, jugRect.maxY - jugRect.height * CGFloat(min(1, lv)) - mouth.y - 10))
                                .position(x: mouth.x, y: (mouth.y + 10 + jugRect.maxY - jugRect.height * CGFloat(min(1, lv))) / 2)
                        }
                        Jug(level: lv, t: t, order: model.order, showRibbon: model.order.ribbon || model.showAnswer,
                            answerLabel: model.showAnswer, glow: model.good, spilled: model.spilled)
                            .frame(width: jugRect.width, height: jugRect.height)
                            .position(x: jugRect.midX, y: jugRect.midY)
                    }
                }
                .allowsHitTesting(false)

                LionSpout(open: model.stage == .pouring, mood: mood)
                    .position(x: mouth.x, y: mouth.y - 23)
                    .allowsHitTesting(false)

                verdict.position(x: w / 2, y: jugRect.midY).allowsHitTesting(false)

                holdHint.position(x: w / 2, y: h - 34).allowsHitTesting(false)
            }
        }
    }

    private var mood: LionSpout.Mood {
        switch model.stage {
        case .done: return model.good ? .happy : .oops
        default: return .idle
        }
    }

    private var orderCard: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text("FILL IT TO").font(luFont(12, .heavy)).tracking(2).foregroundStyle(Color(hex: 0x2c4a63))
                HStack(spacing: 10) {
                    ForEach(Array(model.order.parts.enumerated()), id: \.offset) { _, part in
                        switch part {
                        case .frac(let n, let d): FracView(n: n, d: d, size: 34)
                        case .txt(let s): Text(s).font(luSerif(s.count > 6 ? 30 : 40, .black)).foregroundStyle(Color(hex: 0x14283a))
                            .lineLimit(1).minimumScaleFactor(0.5)
                        }
                    }
                    if model.order.picture { MiniJug(fill: model.order.target).frame(width: 30, height: 46) }
                }
            }
            .frame(maxWidth: .infinity)
            LibrarySpeakerButton(size: 46) { model.sayOrder() }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [Color(hex: 0xf8f3e6), Color(hex: 0xe3d7b8)], startPoint: .top, endPoint: .bottom)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0x2f6f99), lineWidth: 3))
        .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)
        .id(model.roundID)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: model.roundID)
    }

    @ViewBuilder private var verdict: some View {
        if model.stage == .done {
            Text(model.good ? (model.perfect ? "PERFECT!" : "LOVELY!") : (model.spilled ? "SPLASH!" : (model.water > model.order.target ? "Too full!" : "Not enough!")))
                .font(luFont(28)).foregroundStyle(Color(hex: model.good ? Lu.gold : 0xffffff))
                .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
                .padding(.horizontal, 14).padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(model.good ? 0 : 0.35)))
                .transition(.scale(scale: 0.4).combined(with: .opacity))
        }
    }

    private var holdHint: some View {
        HStack(spacing: 8) {
            Image(systemName: model.stage == .pouring ? "drop.fill" : "hand.point.up.fill").font(.system(size: 20, weight: .bold))
            Text(model.stage == .pouring ? "let go to stop" : "HOLD to pour").font(luFont(18, .heavy))
        }
        .foregroundStyle(Color(hex: 0x2b2216))
        .padding(.horizontal, 18).padding(.vertical, 10)
        .background(Capsule().fill(Color(hex: 0xf3ead6).opacity(0.92)))
        .opacity(model.stage == .ready || model.stage == .pouring ? 1 : 0)
    }
}

/// A stacked fraction: numerator over a bar over denominator.
private struct FracView: View {
    let n: Int, d: Int
    var size: CGFloat = 34
    var color = Color(hex: 0x14283a)
    var body: some View {
        VStack(spacing: 1) {
            Text("\(n)").font(luSerif(size, .black))
            Capsule().frame(width: size * (n > 9 || d > 9 ? 1.25 : 0.8), height: max(3, size * 0.09))
            Text("\(d)").font(luSerif(size, .black))
        }
        .foregroundStyle(color)
        .fixedSize()
    }
}

/// A tiny jug pictogram filled to a level (the picture hint).
private struct MiniJug: View {
    let fill: Double
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.6))
                Rectangle().fill(Color(hex: 0x3b8fd0)).frame(height: g.size.height * CGFloat(fill))
            }
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: 0x2c4a63), lineWidth: 2))
        }
    }
}

/// The falling stream of water, gently wobbling.
private struct Stream: View {
    let t: Double
    var body: some View {
        GeometryReader { g in
            let h = g.size.height, w = g.size.width
            Path { p in
                p.move(to: CGPoint(x: w * 0.25, y: 0))
                for i in 0...12 {
                    let y = h * CGFloat(i) / 12
                    p.addLine(to: CGPoint(x: w * 0.2 + CGFloat(sin(t * 18 + Double(i))) * 1.5, y: y))
                }
                for i in (0...12).reversed() {
                    let y = h * CGFloat(i) / 12
                    p.addLine(to: CGPoint(x: w * 0.8 + CGFloat(sin(t * 16 + Double(i) * 1.3)) * 1.5, y: y))
                }
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [Color(hex: 0xbfe6ff), Color(hex: 0x4ea6e0)], startPoint: .leading, endPoint: .trailing))
        }
    }
}

/// The glass jug: water with a wavy top, side marks, the gold ribbon (answer), and a tag.
private struct Jug: View {
    let level: Double
    let t: Double
    let order: FOrder
    let showRibbon: Bool
    let answerLabel: Bool
    let glow: Bool
    let spilled: Bool

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let inner = CGRect(x: 8, y: 0, width: w - 16, height: h - 8)
            let lv = CGFloat(min(1, max(0, level)))
            let waterTop = inner.maxY - inner.height * lv
            ZStack(alignment: .topLeading) {
                // glass back
                RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.22))
                // water
                Wave(top: waterTop, t: t, calm: lv <= 0.001)
                    .fill(LinearGradient(colors: [Color(hex: 0x7cc6f2), Color(hex: 0x2a78b8)], startPoint: .top, endPoint: .bottom))
                    .clipShape(RoundedRectangle(cornerRadius: 14).inset(by: 6))
                // marks
                if order.marks > 1 {
                    ForEach(1..<order.marks, id: \.self) { i in
                        let y = inner.maxY - inner.height * CGFloat(i) / CGFloat(order.marks)
                        Rectangle().fill(Color(hex: 0x14283a).opacity(0.7)).frame(width: 18, height: 3)
                            .position(x: w - 14, y: y)
                    }
                }
                // ribbon at the target
                if showRibbon {
                    let y = inner.maxY - inner.height * CGFloat(order.target)
                    ZStack {
                        Rectangle().fill(Color(hex: Lu.gold)).frame(width: w + 20, height: 6)
                        if answerLabel {
                            answerTag.offset(x: w / 2 + 34)
                        }
                    }
                    .position(x: w / 2, y: y)
                    .shadow(color: .black.opacity(0.3), radius: 0, x: 0, y: 2)
                    .transition(.opacity)
                }
                // glass front + rim
                RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.85), lineWidth: 5)
                Capsule().fill(Color.white.opacity(0.45)).frame(width: 8, height: h * 0.6).position(x: 18, y: h * 0.42)
                Capsule().fill(Color(hex: 0xe9e2d1)).frame(width: w + 12, height: 12).position(x: w / 2, y: 0)
                if spilled {
                    ForEach(0..<6) { i in
                        Circle().fill(Color(hex: 0x7cc6f2)).frame(width: 10)
                            .position(x: i < 3 ? -8 - CGFloat(i * 9) : w + 8 + CGFloat((i - 3) * 9), y: 10 + CGFloat(i % 3) * 30)
                    }
                }
            }
            .shadow(color: glow ? Color(hex: Lu.gold).opacity(0.9) : .clear, radius: glow ? 16 : 0)
        }
    }

    private var answerTag: some View {
        Group {
            if order.parts.count == 1, case .frac(let n, let d) = order.parts[0] {
                FracView(n: n, d: d, size: 16)
            } else if order.parts.count == 1, case .txt(let s) = order.parts[0] {
                Text(s).font(luFont(17, .heavy)).foregroundStyle(Color(hex: 0x14283a))
            } else {
                Text("= " + fDec(order.target)).font(luFont(15, .heavy)).foregroundStyle(Color(hex: 0x14283a))
            }
        }
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: Lu.gold)))
        .fixedSize()
    }
}

private struct Wave: Shape {
    var top: CGFloat
    let t: Double
    let calm: Bool
    func path(in r: CGRect) -> Path {
        var p = Path()
        guard !calm else { return p }
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        for i in 0...20 {
            let x = r.width * CGFloat(i) / 20
            let y = top + CGFloat(sin(t * 4 + Double(i) * 0.7)) * 2.5
            p.addLine(to: CGPoint(x: x, y: y))
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Leo, the bronze lion-head spout: a shaggy mane, a broad nose, a mouth that opens to pour.
private struct LionSpout: View {
    enum Mood { case idle, happy, oops }
    let open: Bool
    let mood: Mood

    var body: some View {
        ZStack {
            // Wall plaque
            Circle().fill(Color(hex: 0xbfb197)).frame(width: 128).overlay(Circle().stroke(Color(hex: 0x8f846c), lineWidth: 3))
            // Mane
            ForEach(0..<14) { i in
                Ellipse().fill(Color(hex: i % 2 == 0 ? 0xb07a2e : 0x8f5f1f)).frame(width: 30, height: 44)
                    .offset(y: -40).rotationEffect(.degrees(Double(i) / 14 * 360))
            }
            Circle().fill(RadialGradient(colors: [Color(hex: 0xe7b65a), Color(hex: 0xb7832e)], center: UnitPoint(x: 0.4, y: 0.35),
                                         startRadius: 4, endRadius: 46))
                .frame(width: 84)
            // Ears
            Circle().fill(Color(hex: 0xc48f3c)).frame(width: 20).offset(x: -30, y: -32)
            Circle().fill(Color(hex: 0xc48f3c)).frame(width: 20).offset(x: 30, y: -32)
            // Eyes
            eyes.offset(y: -10)
            // Muzzle + nose
            Ellipse().fill(Color(hex: 0xf0cf8a)).frame(width: 46, height: 30).offset(y: 12)
            Triangle().fill(Color(hex: 0x5a3414)).frame(width: 16, height: 11).offset(y: 3)
            // Mouth
            Ellipse().fill(Color(hex: 0x4a1d10))
                .frame(width: open ? 26 : (mood == .happy ? 24 : 16), height: open ? 18 : (mood == .happy ? 8 : 4))
                .offset(y: 23)
            if mood == .oops {
                Text("💦").font(.system(size: 20)).offset(x: 40, y: -30)
            }
        }
        .scaleEffect(mood == .happy ? 1.06 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: mood)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: open)
    }

    @ViewBuilder private var eyes: some View {
        HStack(spacing: 18) {
            ForEach(0..<2) { _ in
                if mood == .happy {
                    SmileEye().stroke(Color(hex: 0x3a2008), style: StrokeStyle(lineWidth: 3, lineCap: .round)).frame(width: 12, height: 6)
                } else {
                    ZStack {
                        Ellipse().fill(Color.white).frame(width: 12, height: mood == .oops ? 14 : 11)
                        Circle().fill(Color(hex: 0x2a1606)).frame(width: 6).offset(y: open ? 2 : 0)
                    }
                }
            }
        }
    }
}
private struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY)); p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.closeSubpath(); return p
    }
}
private struct SmileEye: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.midX, y: r.minY - r.height))
        return p
    }
}
