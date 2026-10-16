import SwiftUI

// MARK: - Lupa Chomp (Temple · Math) — the Capitoline she-wolf always eats the BIGGER pile.
//
// Two piles slide in; tap the bigger one (or drag the wolf toward it). She bounds over and chomps
// it, and her belly swells with the streak. A wrong pick: she sniffs, looks puzzled, the right
// pile glows and the "mouth" sign (> / <) opens toward it, with each pile's value spelled out.
//
// Level ladder (from IV the piles creep toward her — the gentle clock):
//   I    food piles of 1–5 vs 1–5, always ≥ 2 apart; no clock
//   II   piles to 9 only 1–3 apart, or a pile vs a numeral to 10
//   III  numerals to 20, tens-vs-ones (23 vs 32), a pile vs a close numeral
//   IV   2-digit swaps (47 vs 74), easy sums vs a number (3 + 4 vs 6); 12 s approach
//   V    3-digit swaps (406 vs 460), sum vs sum, take-aways within 20; 10 s
//   VI   pie pictures (½ vs ⅓, ⅖ vs ⅘), decimals (0.5 vs 0.45), products (3×4 vs 2×7); 9 s
//   VII  unlike-denominator fractions (⅔ vs ¾), negatives (−3 vs −7), product vs sum; 8 s
//   VIII+ exponents (2⁵ vs 5²), fraction vs decimal, signed expressions; 7 s easing to 4.5 s

// MARK: - Content

private enum LCShow {
    case dots(Int, String)      // a pile of food emoji to count
    case text(String)           // a numeral or expression
    case pie(Int, Int)          // n/d of a pie, drawn (with its fraction under it)
    case frac(Int, Int)         // n/d as a stacked fraction
}

private struct LCPile {
    let show: LCShow
    let value: Double
    var note: String = ""        // shown on the reveal (e.g. "= 7", "= 8/12")
}

private let lcSuper: [Character: Character] = ["0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
                                               "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹"]
/// An integer with a true minus sign.
private func lcNum(_ n: Int) -> String { n < 0 ? "−\(-n)" : "\(n)" }
private func lcPow(_ b: Int, _ e: Int) -> String { "\(b)" + String("\(e)".compactMap { lcSuper[$0] }) }
private func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? abs(a) : gcd(b, a % b) }
private func ipow(_ b: Int, _ e: Int) -> Int { (0..<e).reduce(1) { acc, _ in acc * b } }
/// A decimal to at most two places, trailing zeros trimmed ("0.67", "0.5").
private func lcDec(_ x: Double) -> String {
    var s = String(format: "%.2f", x)
    while s.hasSuffix("0") { s.removeLast() }
    if s.hasSuffix(".") { s.removeLast() }
    return s
}

/// Two distinct ints in `range`, `gap` apart.
private func lcPair(_ range: ClosedRange<Int>, gap: ClosedRange<Int>) -> (Int, Int) {
    while true {
        let a = Int.random(in: range), d = Int.random(in: gap)
        let b = Bool.random() ? a + d : a - d
        if range.contains(b) && b != a { return (a, b) }
    }
}

/// A 2-digit number and its digit swap (47 / 74), digits distinct and non-zero.
private func lcSwap2() -> (Int, Int) {
    let a = Int.random(in: 1...9)
    let b = (1...9).filter { $0 != a }.randomElement()!
    return (a * 10 + b, b * 10 + a)
}

/// Two different 3-digit arrangements of the same three digits (406 / 460).
private func lcSwap3() -> (Int, Int) {
    while true {
        let d = Array((0...9).shuffled().prefix(3))
        let perms = [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]]
            .map { d[$0[0]] * 100 + d[$0[1]] * 10 + d[$0[2]] }.filter { $0 >= 100 }
        let p = perms.shuffled()
        if p.count >= 2 { return (p[0], p[1]) }
    }
}

private func lcRound(_ level: Int) -> [LCPile] {
    let food = ["🍖", "🍗", "🐟"].randomElement()!
    func dots(_ n: Int) -> LCPile { LCPile(show: .dots(n, food), value: Double(n), note: "\(n)") }
    func num(_ n: Int) -> LCPile { LCPile(show: .text(lcNum(n)), value: Double(n)) }
    func expr(_ s: String, _ v: Int) -> LCPile { LCPile(show: .text(s), value: Double(v), note: "= \(lcNum(v))") }
    let roll = Double.random(in: 0..<1)
    var a: LCPile, b: LCPile

    switch level {
    case 1:
        let (x, y) = lcPair(1...5, gap: 2...4); a = dots(x); b = dots(y)
    case 2:
        if roll < 0.6 { let (x, y) = lcPair(2...9, gap: 1...3); a = dots(x); b = dots(y) }
        else {
            let (x, y) = lcPair(1...10, gap: 2...5)
            if x <= 9 { a = dots(x); b = num(y) } else { a = dots(y); b = num(x) }
        }
    case 3:
        if roll < 0.4 { let (x, y) = lcPair(1...20, gap: 1...6); a = num(x); b = num(y) }
        else if roll < 0.7 {
            let t = Int.random(in: 1...4), o = (1...9).filter { $0 != t }.randomElement()!
            a = num(t * 10 + o); b = num(o * 10 + t)
        } else { let (x, y) = lcPair(1...9, gap: 1...2); a = dots(x); b = num(y) }
    case 4:
        if roll < 0.4 { let (x, y) = lcSwap2(); a = num(x); b = num(y) }
        else {
            let p = Int.random(in: 1...5), q = Int.random(in: 1...5)
            var n = p + q + [-2, -1, 1, 2].randomElement()!
            if n < 1 { n = p + q + 1 }
            a = expr("\(p) + \(q)", p + q); b = num(n)
        }
    case 5:
        if roll < 0.35 { let (x, y) = lcSwap3(); a = num(x); b = num(y) }
        else if roll < 0.7 {
            var p, q, r, s: Int
            repeat { p = .random(in: 2...9); q = .random(in: 2...9); r = .random(in: 2...9); s = .random(in: 2...9) }
            while p + q == r + s || abs(p + q - r - s) > 3
            a = expr("\(p) + \(q)", p + q); b = expr("\(r) + \(s)", r + s)
        } else {
            let p = Int.random(in: 10...20), q = Int.random(in: 2...9)
            var n = p - q + [-2, -1, 1, 2].randomElement()!
            if n < 0 { n = p - q + 1 }
            a = expr("\(p) − \(q)", p - q); b = num(n)
        }
    case 6:
        if roll < 0.35 {
            if Bool.random() {
                let (x, y) = lcPair(2...6, gap: 1...3)
                a = LCPile(show: .pie(1, x), value: 1 / Double(x)); b = LCPile(show: .pie(1, y), value: 1 / Double(y))
            } else {
                let d = Int.random(in: 3...8), (x, y) = lcPair(1...(d - 1), gap: 1...3)
                a = LCPile(show: .pie(x, d), value: Double(x) / Double(d)); b = LCPile(show: .pie(y, d), value: Double(y) / Double(d))
            }
        } else if roll < 0.7 {
            let t = Int.random(in: 1...9)
            let h = ((t * 10 - 9)...(t * 10 + 9)).filter { $0 % 10 != 0 && $0 > 0 && $0 < 100 }.randomElement()!
            a = LCPile(show: .text("0.\(t)"), value: Double(t) / 10)
            b = LCPile(show: .text(String(format: "0.%02d", h)), value: Double(h) / 100)
        } else {
            var p, q, r, s: Int
            repeat { p = .random(in: 2...9); q = .random(in: 2...9); r = .random(in: 2...9); s = .random(in: 2...9) }
            while p * q == r * s || abs(p * q - r * s) > 8
            a = expr("\(p) × \(q)", p * q); b = expr("\(r) × \(s)", r * s)
        }
    case 7:
        if roll < 0.35 { (a, b) = lcFracPair() }
        else if roll < 0.7 {
            let (x, y) = lcPair(-20...9, gap: 1...8)
            if x >= 0 && y >= 0 { a = num(-x - 1); b = num(-y - 1) } else { a = num(x); b = num(y) }
        } else {
            var p, q, s, t: Int
            repeat { p = .random(in: 3...9); q = .random(in: 3...9); s = .random(in: 10...70); t = .random(in: 1...9) }
            while p * q == s + t || abs(p * q - s - t) > 6
            a = expr("\(p) × \(q)", p * q); b = expr("\(s) + \(t)", s + t)
        }
    default:
        if roll < 0.35 {
            var p, q, r, s: Int
            repeat { p = .random(in: 2...6); q = .random(in: 2...5); r = .random(in: 2...6); s = .random(in: 2...5) }
            while p == r || ipow(p, q) == ipow(r, s) || ipow(p, q) > 1000 || ipow(r, s) > 1000
            a = expr(lcPow(p, q), ipow(p, q)); b = expr(lcPow(r, s), ipow(r, s))
        } else if roll < 0.65 {
            var n, d, h: Int
            repeat { d = .random(in: 3...9); n = .random(in: 1...(d - 1)); h = .random(in: 5...95) }
            while abs(Double(n) / Double(d) - Double(h) / 100) < 0.02 || abs(Double(n) / Double(d) - Double(h) / 100) > 0.15
            let v = Double(n) / Double(d)
            let exact = (100 * n) % d == 0
            a = LCPile(show: .frac(n, d), value: v, note: (exact ? "= " : "≈ ") + lcDec(v))
            b = LCPile(show: .text(lcDec(Double(h) / 100)), value: Double(h) / 100)
        } else {
            // a negative plus a positive vs a product with one negative factor (always negative)
            var p, q, r, s: Int
            repeat { p = .random(in: -9...(-2)); q = .random(in: 1...12); r = .random(in: 2...5); s = .random(in: 1...4) }
            while p + q == -r * s || abs(p + q + r * s) > 12
            a = expr("\(lcNum(p)) + \(q)", p + q)
            b = expr(Bool.random() ? "\(lcNum(-r)) × \(s)" : "\(r) × \(lcNum(-s))", -r * s)
        }
    }
    return Bool.random() ? [a, b] : [b, a]
}

/// Two fractions with unlike denominators; the notes rewrite both over a common denominator.
private func lcFracPair() -> (LCPile, LCPile) {
    while true {
        let d1 = Int.random(in: 2...9), d2 = Int.random(in: 2...9)
        guard d1 != d2 else { continue }
        let n1 = Int.random(in: 1..<d1), n2 = Int.random(in: 1..<d2)
        guard gcd(n1, d1) == 1, gcd(n2, d2) == 1, n1 * d2 != n2 * d1 else { continue }
        let l = d1 / gcd(d1, d2) * d2
        guard l <= 36 else { continue }
        return (LCPile(show: .frac(n1, d1), value: Double(n1) / Double(d1), note: "= \(n1 * l / d1)/\(l)"),
                LCPile(show: .frac(n2, d2), value: Double(n2) / Double(d2), note: "= \(n2 * l / d2)/\(l)"))
    }
}

/// Seconds the piles take to reach the wolf (0 = no clock).
private func lcApproach(_ level: Int) -> Double {
    switch level {
    case ...3: return 0
    case 4: return 12
    case 5: return 10
    case 6: return 9
    case 7: return 8
    default: return max(4.5, 7 - Double(level - 8) * 0.5)
    }
}

// MARK: - Model

@MainActor
private final class LupaModel: ArcadeModel {
    enum Stage: Equatable { case arriving, waiting, eating(Int), confused(Int?) }
    @Published var piles: [LCPile] = []
    @Published var stage: Stage = .arriving
    @Published var round = 0
    @Published var approachStart = Date()
    @Published var approachDur: Double = 0
    @Published var frozen: Double = 0          // how far the piles had crept when the pick landed

    init() { super.init(key: GameID.lupaChomp.rawValue) }

    var bigger: Int { piles.count == 2 && piles[0].value > piles[1].value ? 0 : 1 }

    override func onBegin() { next() }

    private func later(_ s: Double, _ round: Int, _ f: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + s) { [weak self] in
            guard let self, self.round == round, self.phase == .playing else { return }
            f()
        }
    }

    private func next() {
        round += 1
        piles = lcRound(level)
        #if DEBUG
        assert(piles.count == 2 && piles[0].value != piles[1].value, "Lupa: tie or bad pair")
        #endif
        stage = .arriving; frozen = 0
        approachDur = lcApproach(level)
        let r = round
        later(0.55, r) { [unowned self] in
            stage = .waiting; approachStart = Date()
            if approachDur > 0 {
                later(approachDur, r) { [unowned self] in if stage == .waiting { choose(nil) } }
            }
        }
    }

    /// The child's pick (nil = the piles reached her untouched).
    func choose(_ side: Int?) {
        guard phase == .playing, stage == .waiting else { return }
        frozen = approachDur > 0 ? min(1, Date().timeIntervalSince(approachStart) / approachDur) : 0
        let right = side == bigger
        stage = right ? .eating(bigger) : .confused(side)
        if right { hit() } else { miss(reason: side == nil ? "Too slow!" : "Out of hearts!", delay: 2.0) }
        let r = round
        later(right ? 1.05 : 2.3, r) { [unowned self] in if !dying { next() } }
    }

    override func botAct(correct: Bool) {
        guard stage == .waiting else { return }
        choose(correct ? bigger : 1 - bigger)
    }
}

// MARK: - Views

struct LupaChompView: View {
    let onClose: () -> Void
    @StateObject private var model = LupaModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.lupaChomp.spec!, accent: Lu.gold, onClose: onClose) {
            GeometryReader { geo in
                LupaField(model: model, size: geo.size)
            }
            .padding(.top, 62)
        }
    }
}

private struct LupaField: View {
    @ObservedObject var model: LupaModel
    let size: CGSize
    @State private var drag: CGFloat = 0

    private var cardW: CGFloat { min(170, (size.width - 44) / 2) }
    private let cardH: CGFloat = 196
    private var wolfY: CGFloat { size.height - 120 }
    private var travel: CGFloat { max(0, wolfY - 110 - (40 + cardH)) }

    var body: some View {
        let paused = !(model.phase == .playing && model.stage == .waiting && model.approachDur > 0)
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: paused)) { tl in
            let p: Double = model.stage == .waiting && model.approachDur > 0
                ? min(1, tl.date.timeIntervalSince(model.approachStart) / model.approachDur)
                : (model.stage == .arriving ? 0 : model.frozen)
            ZStack(alignment: .top) {
                Text("Which is BIGGER?")
                    .font(luSerif(17, .bold)).textCase(.uppercase).tracking(2)
                    .foregroundStyle(Color(hex: Lu.inkDim))
                    .frame(height: 30)

                ZStack {
                HStack(spacing: 12) {
                    ForEach(0..<min(2, model.piles.count), id: \.self) { i in
                        LupaCard(pile: model.piles[i], index: i, stage: model.stage, isBig: model.bigger == i)
                            .frame(width: cardW, height: cardH)
                            .contentShape(Rectangle())
                            .onTapGesture { model.choose(i) }
                    }
                }
                .id(model.round)
                .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .opacity.animation(.easeOut(duration: 0.12))))
                }
                .animation(.spring(response: 0.45, dampingFraction: 0.75), value: model.round)
                .offset(y: cardY(p))

                mouthSign.offset(y: cardY(p) + cardH / 2 - 26)

                wolf.position(x: size.width / 2, y: wolfY)
            }
            .frame(width: size.width, height: size.height)
        }
    }

    /// The "hungry mouth" sign between the piles, opening toward the bigger one.
    @ViewBuilder private var mouthSign: some View {
        let shown: Bool = { if case .waiting = model.stage { return false }; if case .arriving = model.stage { return false }; return true }()
        Text(model.bigger == 0 ? ">" : "<")
            .font(luFont(44)).foregroundStyle(Color(hex: Lu.gold))
            .frame(width: 52, height: 52)
            .background(Circle().fill(Color(hex: Lu.ground)).overlay(Circle().stroke(Color(hex: Lu.goldLine), lineWidth: 2)))
            .scaleEffect(shown ? 1 : 0.2).opacity(shown ? 1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: shown)
    }

    /// Top of the piles: with no clock they rest a little lower, nearer the wolf.
    private func cardY(_ p: Double) -> CGFloat { 40 + (model.approachDur > 0 ? travel * p : travel * 0.3) }

    private var wolfTarget: CGSize {
        let dx = cardW / 2 + 6
        let up = -(wolfY - (cardY(model.frozen) + cardH) - 30)
        switch model.stage {
        case .eating(let s): return CGSize(width: s == 0 ? -dx : dx, height: up)
        case .confused(let s?): return CGSize(width: s == 0 ? -dx * 0.8 : dx * 0.8, height: up * 0.55)
        default: return CGSize(width: drag, height: 0)
        }
    }

    private var wolf: some View {
        let belly = CGFloat(min(model.combo, 8))
        let confused: Bool = { if case .confused = model.stage { return true }; return false }()
        let eating: Bool = { if case .eating = model.stage { return true }; return false }()
        return ZStack {
            Ellipse().fill(Color(hex: Lu.mint).opacity(0.25)).frame(width: 190, height: 30).offset(y: 86)
            // tail (wags while she eats) and legs
            Capsule().fill(LinearGradient(colors: [Color(hex: 0x8d8698), Color(hex: 0xd8d2de)], startPoint: .leading, endPoint: .trailing))
                .frame(width: 62, height: 20)
                .rotationEffect(.degrees(eating ? -50 : -25), anchor: .leading)
                .offset(x: 72 + belly * 3, y: 22)
                .animation(.spring(response: 0.18, dampingFraction: 0.2), value: eating)
            ForEach([-34, -14, 14, 34], id: \.self) { x in
                Capsule().fill(Color(hex: 0x6e6680)).frame(width: 15, height: 34)
                    .offset(x: CGFloat(x) * (1 + belly * 0.06), y: 66)
            }
            // body + belly (swells with the streak)
            Ellipse()
                .fill(LinearGradient(colors: [Color(hex: 0xa9a3b3), Color(hex: 0x6e6680)], startPoint: .top, endPoint: .bottom))
                .overlay(Ellipse().fill(Color(hex: 0xe6dccb)).frame(width: 40 + belly * 6, height: 34 + belly * 2.5).offset(y: 10))
                .frame(width: 104 + belly * 7, height: 72 + belly * 3)
                .offset(y: 34)
            Text("🐺").font(.system(size: 84)).offset(x: -18, y: -20)
                .scaleEffect(eating ? 1.12 : 1)
            // thought bubble
            Text(eating ? "😋" : (confused ? "❓" : ""))
                .font(.system(size: 34))
                .offset(x: 58, y: -70)
                .scaleEffect(eating || confused ? 1 : 0.1)
                .opacity(eating || confused ? 1 : 0)
            if eating {
                Text("CHOMP!").font(luFont(24)).foregroundStyle(Color(hex: Lu.gold))
                    .offset(y: -100).transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .rotationEffect(.degrees(confused ? 12 : 0))
        .animation(.spring(response: 0.16, dampingFraction: 0.18), value: confused)
        .offset(wolfTarget)
        .animation(.spring(response: 0.38, dampingFraction: 0.68), value: model.stage)
        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: model.combo)
        .gesture(DragGesture(minimumDistance: 8)
            .onChanged { v in drag = max(-60, min(60, v.translation.width)) }
            .onEnded { v in
                drag = 0
                if v.translation.width < -30 { model.choose(0) } else if v.translation.width > 30 { model.choose(1) }
            })
        .frame(width: 180, height: 200)
        .contentShape(Rectangle())
    }
}

private struct LupaCard: View {
    let pile: LCPile
    let index: Int
    let stage: LupaModel.Stage
    let isBig: Bool

    private var eaten: Bool { if case .eating(let s) = stage { return s == index }; return false }
    private var revealed: Bool {
        switch stage { case .eating, .confused: return true; default: return false }
    }
    private var wrongPicked: Bool { if case .confused(let s) = stage { return s == index }; return false }
    private var glow: Bool { if case .confused = stage { return isBig }; return false }

    var body: some View {
        VStack(spacing: 6) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(eaten ? 0.05 : 1).opacity(eaten ? 0 : 1)
                .animation(.easeIn(duration: 0.25).delay(0.15), value: eaten)
            Text(pile.note.isEmpty ? " " : pile.note)
                .font(luFont(20)).foregroundStyle(Color(hex: glow ? Lu.gold : Lu.ink))
                .opacity(revealed && !pile.note.isEmpty ? 1 : 0)
                .lineLimit(1).minimumScaleFactor(0.5)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(colors: [Color(hex: Lu.panel2), Color(hex: Lu.panel)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 22)
                    .stroke(Color(hex: glow ? Lu.gold : (wrongPicked ? Lu.coral : Lu.line)), lineWidth: glow ? 5 : 2))
        )
        .overlay(alignment: .top) {
            if glow {
                Text("BIGGER").font(luFont(13, .heavy)).tracking(1.5).foregroundStyle(Color(hex: Lu.inkDark))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: Lu.gold)))
                    .offset(y: -12)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .scaleEffect(glow ? 1.06 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: glow)
    }

    @ViewBuilder private var content: some View {
        switch pile.show {
        case .dots(let n, let e): LupaDots(n: n, emoji: e)
        case .text(let s):
            Text(s).font(luFont(s.count <= 3 ? 64 : (s.count <= 6 ? 42 : 32)))
                .foregroundStyle(Color(hex: Lu.ink)).lineLimit(1).minimumScaleFactor(0.4)
        case .pie(let n, let d):
            VStack(spacing: 4) {
                LupaPie(n: n, d: d).frame(width: 104, height: 104)
                Text("\(n)/\(d)").font(luFont(20)).foregroundStyle(Color(hex: Lu.inkDim))
            }
        case .frac(let n, let d): LupaFraction(n: n, d: d)
        }
    }
}

/// Food in rows of three (four as 2 + 2) — easy to count at a glance.
private struct LupaDots: View {
    let n: Int, emoji: String
    var body: some View {
        let rows: [Int] = n == 4 ? [2, 2] : stride(from: 0, to: n, by: 3).map { min(3, n - $0) }
        let size: CGFloat = n <= 6 ? 40 : 34
        VStack(spacing: 4) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, c in
                HStack(spacing: 4) { ForEach(0..<c, id: \.self) { _ in Text(emoji).font(.system(size: size)) } }
            }
        }
    }
}

private struct LupaPie: View {
    let n: Int, d: Int
    var body: some View {
        Canvas { ctx, sz in
            let c = CGPoint(x: sz.width / 2, y: sz.height / 2), r = min(sz.width, sz.height) / 2 - 3
            for i in 0..<d {
                let a0 = Angle.degrees(-90 + 360 * Double(i) / Double(d)), a1 = Angle.degrees(-90 + 360 * Double(i + 1) / Double(d))
                var p = Path(); p.move(to: c); p.addArc(center: c, radius: r, startAngle: a0, endAngle: a1, clockwise: false); p.closeSubpath()
                ctx.fill(p, with: .color(Color(hex: i < n ? Lu.tangerine : Lu.ground)))
                ctx.stroke(p, with: .color(Color(hex: Lu.ink).opacity(0.8)), lineWidth: 2)
            }
        }
    }
}

private struct LupaFraction: View {
    let n: Int, d: Int
    var body: some View {
        VStack(spacing: 2) {
            Text("\(n)").font(luFont(48))
            Capsule().frame(width: 56, height: 5)
            Text("\(d)").font(luFont(48))
        }
        .foregroundStyle(Color(hex: Lu.ink))
    }
}
