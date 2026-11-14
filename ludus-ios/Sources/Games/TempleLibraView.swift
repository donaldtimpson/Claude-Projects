import SwiftUI

// MARK: - Libra  (Number Crunchers · balance)
//
// In the temple treasury stands a great bronze balance (libra — Latin for "scales"). One pan holds
// a load; somewhere there's an empty sack ("?" — later "x"). Tap bronze weights from the tray into
// the sack, then pull the lever: the peg drops out and the beam swings. Level = right, and coins
// rain. Tilted = the sack was too light / too heavy — the beam shows which way, then the sack is
// refilled with the right amount and the beam settles level, so every miss shows the answer.
//
// Strand: counting → addition → missing addends → bigger sums/differences → multiplication and
// division → simple equations (2x + 3 = 15) → order of operations → x on both sides, balloons that
// LIFT (x − 4 = 9). Every step is the same idea a child can SEE: both sides weigh the same.
//
// Tuned off `d`: the content kind via `tier`, the numbers inside each kind via `ramp`, and the tray
// (from single 1-weights to 1·2·5·10·20·50).

// MARK: Content

private enum LItem: Hashable {
    case fruit(String, Int)          // n of a fruit, each weighing 1
    case weight(Int)
    case bag                         // the child's sack (its fill is the unknown)
    case block(String, Int)          // a stone block engraved with an expression
    case balloon(Int)                // a balloon that lifts n

    func value(_ x: Int) -> Int {
        switch self {
        case .fruit(_, let n): return n
        case .weight(let w): return w
        case .bag: return x
        case .block(_, let v): return v
        case .balloon(let n): return -n
        }
    }
}

private struct LPuzzle {
    var left: [LItem]
    var right: [LItem]
    var answer: Int
    var eq: String            // the equation the scale stands for ("" at the picture start)
    var tray: [Int]
    var letter = false        // the sack is "x" (equations), not "?"
    var hint = "Make it balance!"

    func weight(_ side: [LItem], _ x: Int) -> Int { side.reduce(0) { $0 + $1.value(x) } }
    func diff(_ x: Int) -> Int { weight(right, x) - weight(left, x) }     // > 0: right heavier
    var balanced: Bool { diff(answer) == 0 }
}

// MARK: Model

@MainActor
private final class LibraModel: ArcadeModel {
    enum Stage { case filling, weighing, settled }

    @Published var p = LPuzzle(left: [.fruit("🍎", 3)], right: [.bag], answer: 3, eq: "", tray: [1])
    @Published var sack: [Int] = []          // weights in the sack
    @Published var stage: Stage = .filling
    @Published var tilt: Double = 0          // degrees, + = right side down
    @Published var correct = false
    @Published var roundID = 0
    private var gen = 0

    var fill: Int { sack.reduce(0, +) }

    init() { super.init(key: GameID.libra.rawValue) }

    override func onBegin() { next() }

    private func later(_ t: Double, _ f: @escaping (LibraModel) -> Void) {
        let g = gen
        DispatchQueue.main.asyncAfter(deadline: .now() + t) { [weak self] in
            guard let self, self.gen == g, self.phase == .playing else { return }
            f(self)
        }
    }

    private func next() {
        gen += 1
        var np = makePuzzle()
        var n = 0
        while (!np.balanced || np.answer <= 0) && n < 20 { np = makePuzzle(); n += 1 }
        p = np
        sack = []; stage = .filling; tilt = 0; correct = false
        roundID += 1
    }

    func add(_ w: Int) {
        guard phase == .playing, stage == .filling, fill + w <= 999, sack.count < 14 else { return }
        sack.append(w)
        Sfx.play(.tick); Haptics.light()
    }

    func remove(at i: Int) {
        guard phase == .playing, stage == .filling, sack.indices.contains(i) else { return }
        sack.remove(at: i)
        Sfx.play(.pop, volume: 0.5); Haptics.light()
    }

    func clear() {
        guard stage == .filling, !sack.isEmpty else { return }
        sack = []; Sfx.play(.whoosh, volume: 0.6)
    }

    /// The angle for a difference: a small difference still visibly tips.
    private func angle(for diff: Int) -> Double {
        guard diff != 0 else { return 0 }
        let total = Double(max(4, p.weight(p.left, p.answer)))
        let mag = min(15, 5 + 10 * Double(abs(diff)) / (total * 0.4))
        return diff > 0 ? mag : -mag
    }

    func weigh() {
        guard phase == .playing, stage == .filling, !sack.isEmpty else { return }
        stage = .weighing
        Sfx.play(.thud, volume: 0.5)
        let dfx = p.diff(fill)
        tilt = angle(for: dfx)
        if dfx == 0 {
            correct = true
            later(0.45) { m in
                m.stage = .settled
                Sfx.play(.coin)
                m.hit(points: m.p.letter ? 2 : 1)
                m.later(1.4) { $0.next() }
            }
        } else {
            correct = false
            later(0.5) { m in m.miss(delay: 2.6) }
            later(1.3) { m in
                // Refill the sack with the right amount (in the tray's coins) and let it settle.
                m.sack = m.coins(for: m.p.answer)
                m.tilt = 0
                m.stage = .settled
                Sfx.play(.sparkle)
            }
            later(2.9) { m in if !m.dying { m.next() } }
        }
    }

    /// The fewest tray weights that make `n` (greedy works for 1·2·5·10·20·50 coinage).
    func coins(for n: Int) -> [Int] {
        var left = n, out: [Int] = []
        for c in p.tray.sorted(by: >) { while left >= c && out.count < 30 { out.append(c); left -= c } }
        return out
    }

    override func botAct(correct ok: Bool) {
        guard stage == .filling else { return }
        let target = ok ? p.answer : max(1, p.answer + (Bool.random() ? 1 : -1) * Int.random(in: 1...3))
        sack = coins(for: target == p.answer || target > 0 ? target : p.answer + 1)
        weigh()
    }

    // MARK: Puzzle maker

    private func makePuzzle() -> LPuzzle {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: min(a, b)...max(a, b)) }
        let fruits = ["🍎", "🍐", "🍋", "🍇", "🫒", "🍑"]
        let k = tier([1, 2, 3, 4.1, 5.1, 6.1, 7, 8], keep: 0.15)
        switch k {
        case 0:   // count the fruit
            let n = r(1, rampInt(4, 10, to: 2.2))
            return LPuzzle(left: [.fruit(fruits.randomElement()!, n)], right: [.bag], answer: n, eq: "",
                           tray: d < 1.7 ? [1] : [1, 5], hint: "Make it balance!")
        case 1:   // a + b
            let m = rampInt(5, 10, from: 2, to: 3.5)
            let a = r(1, m), b = r(1, m)
            return LPuzzle(left: [.weight(a), .weight(b)], right: [.bag], answer: a + b, eq: "\(a) + \(b) = ?", tray: [1, 2, 5, 10])
        case 2:   // b + ? = t
            let t = r(5, rampInt(10, 20, from: 3, to: 4.5)), b = r(1, t - 1)
            return LPuzzle(left: [.weight(t)], right: [.weight(b), .bag], answer: t - b, eq: "\(b) + ? = \(t)", tray: [1, 2, 5, 10])
        case 3:   // within 100: a sum or a difference
            let top = rampInt(40, 99, from: 4.1, to: 6)
            if Bool.random() {
                let a = r(11, top / 2), b = r(6, top - a)
                return LPuzzle(left: [.weight(a), .weight(b)], right: [.bag], answer: a + b, eq: "\(a) + \(b) = ?",
                               tray: [1, 2, 5, 10, 20, 50])
            }
            let t = r(25, top), b = r(5, t - 5)
            return LPuzzle(left: [.weight(t)], right: [.weight(b), .bag], answer: t - b, eq: "\(b) + ? = \(t)",
                           tray: [1, 2, 5, 10, 20, 50])
        case 4:   // × and ÷ as repeated weights / repeated sacks
            let n = r(2, rampInt(3, 5, from: 5.1, to: 7)), a = r(2, rampInt(5, 10, from: 5.1, to: 7))
            if Bool.random() {
                return LPuzzle(left: Array(repeating: .weight(a), count: n), right: [.bag], answer: n * a,
                               eq: "\(n) × \(a) = ?", tray: [1, 2, 5, 10, 20, 50])
            }
            return LPuzzle(left: Array(repeating: .bag, count: n), right: [.weight(n * a)], answer: a,
                           eq: "\(n) × ? = \(n * a)", tray: [1, 2, 5, 10], hint: "Every sack gets the same!")
        case 5:   // kx + c = t
            let kk = r(1, rampInt(2, 4, from: 6.1, to: 8)), x = r(2, rampInt(9, 15, from: 6.1, to: 9)), c = r(1, rampInt(9, 20, to: 9))
            let lhs = (kk == 1 ? "x" : "\(kk)x") + " + \(c)"
            return LPuzzle(left: Array(repeating: .bag, count: kk) + [.weight(c)], right: [.weight(kk * x + c)], answer: x,
                           eq: "\(lhs) = \(kk * x + c)", tray: [1, 2, 5, 10], letter: true, hint: "Every sack is x")
        case 6:   // order of operations on an engraved block
            let (text, v) = opsExpression()
            return LPuzzle(left: [.block(text, v)], right: [.bag], answer: v, eq: "\(text) = ?",
                           tray: [1, 2, 5, 10, 20, 50], hint: "× and ÷ before + and −")
        default:  // x on both sides, or a balloon that lifts
            if Bool.random() {
                let x = r(2, 12), k2 = r(1, 2), k1 = k2 + r(1, 2), c1 = r(1, 10)
                let c2 = (k1 - k2) * x + c1
                let l = (k1 == 1 ? "x" : "\(k1)x") + " + \(c1)", rr = (k2 == 1 ? "x" : "\(k2)x") + " + \(c2)"
                return LPuzzle(left: Array(repeating: .bag, count: k1) + [.weight(c1)],
                               right: Array(repeating: .bag, count: k2) + [.weight(c2)], answer: x,
                               eq: "\(l) = \(rr)", tray: [1, 2, 5, 10], letter: true, hint: "Every sack is x")
            }
            let x = r(5, 30), n = r(2, min(9, x - 1))
            return LPuzzle(left: [.bag, .balloon(n)], right: [.weight(x - n)], answer: x,
                           eq: "x − \(n) = \(x - n)", tray: [1, 2, 5, 10, 20], letter: true, hint: "🎈 lifts — it takes away")
        }
    }

    /// An expression where order of operations matters (value 1…120, whole numbers).
    private func opsExpression() -> (String, Int) {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b) }
        for _ in 0..<50 {
            let a = r(2, 9), b = r(2, 9), c = r(2, 9)
            let pick = r(0, 5)
            var text = "", v = 0
            switch pick {
            case 0: text = "\(a) + \(b) × \(c)"; v = a + b * c
            case 1: text = "\(a) × \(b) − \(c)"; v = a * b - c
            case 2: text = "(\(a) + \(b)) × \(c)"; v = (a + b) * c
            case 3: text = "\(a * c) ÷ \(c) + \(b)"; v = a + b
            case 4: text = "\(a + 20) − \(b) × \(c)"; v = a + 20 - b * c
            default:
                let e = r(2, 5)
                text = "\(a) × \(b) + \(c) × \(e)"; v = a * b + c * e
            }
            if v >= 1 && v <= 120 && (d >= 7.6 || pick != 5) { return (text, v) }
        }
        return ("2 + 3 × 4", 14)
    }
}

// MARK: - View

struct TempleLibraView: View {
    let onClose: () -> Void
    @StateObject private var model = LibraModel()

    var body: some View {
        ArcadeShell(model: model,
                    spec: GameID.libra.spec ?? GameSpec(title: "Libra", mechanic: "balance", premise: "", game: .libra),
                    accent: Lu.gold, onClose: onClose,
                    backdrop: { Treasury() }) {
            LibraPlay(model: model)
        }
    }
}

/// The treasury: a warm ochre wall with a painted frieze, two marble columns, a mosaic floor.
private struct Treasury: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Color(hex: 0x6b2a1e), Color(hex: 0xa2492f), Color(hex: 0xc0663f)],
                               startPoint: .top, endPoint: .bottom)
                // Frieze band
                Rectangle().fill(Color(hex: 0x3c1a14)).frame(height: 18).offset(y: h * 0.2)
                HStack(spacing: 10) {
                    ForEach(0..<14) { _ in
                        Image(systemName: "diamond.fill").font(.system(size: 8)).foregroundStyle(Color(hex: 0xd9a441).opacity(0.7))
                    }
                }
                .frame(width: w).offset(y: h * 0.2 + 4)
                // Columns
                ForEach([0.035, 0.965], id: \.self) { fx in
                    Column().frame(width: 30, height: h * 0.6).position(x: w * fx, y: h * 0.52)
                }
                // Mosaic floor
                Canvas { ctx, sz in
                    let top = sz.height * 0.82
                    ctx.fill(Path(CGRect(x: 0, y: top, width: sz.width, height: sz.height - top)), with: .color(Color(hex: 0xd8c39a)))
                    let s: CGFloat = 18
                    var row = 0
                    var y = top
                    while y < sz.height {
                        var x: CGFloat = row % 2 == 0 ? 0 : -s / 2
                        while x < sz.width {
                            let hex: UInt = (Int(x / s) + row) % 5 == 0 ? 0x8c3b24 : ((Int(x / s) + row) % 3 == 0 ? 0xbfa070 : 0xe6d4ad)
                            ctx.fill(Path(roundedRect: CGRect(x: x + 1, y: y + 1, width: s - 2, height: s - 2), cornerRadius: 2),
                                     with: .color(Color(hex: hex)))
                            x += s
                        }
                        y += s; row += 1
                    }
                    ctx.fill(Path(CGRect(x: 0, y: top - 6, width: sz.width, height: 6)), with: .color(Color(hex: 0x5a2618)))
                }
            }
        }
    }
}

private struct Column: View {
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xefe6d2)).frame(height: 14)
            HStack(spacing: 3) {
                ForEach(0..<5) { _ in Rectangle().fill(LinearGradient(colors: [Color(hex: 0xf4ecda), Color(hex: 0xcfc4ab)], startPoint: .leading, endPoint: .trailing)) }
            }
            .padding(.horizontal, 4)
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xefe6d2)).frame(height: 14)
        }
        .shadow(color: .black.opacity(0.25), radius: 6, x: 3)
    }
}

private struct LibraPlay: View {
    @ObservedObject var model: LibraModel
    @State private var shake: CGFloat = 0

    private var p: LPuzzle { model.p }

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let pivot = CGPoint(x: w / 2, y: h * 0.29)
            let L = min(w * 0.3, 130)
            let tilt = model.tilt
            let rad = tilt * .pi / 180
            let leftEnd = CGPoint(x: pivot.x - L * CGFloat(cos(rad)), y: pivot.y - L * CGFloat(sin(rad)))
            let rightEnd = CGPoint(x: pivot.x + L * CGFloat(cos(rad)), y: pivot.y + L * CGFloat(sin(rad)))
            let hang: CGFloat = h * 0.17

            ZStack(alignment: .topLeading) {
                equationPlaque.frame(width: w - 32).position(x: w / 2, y: 98)

                // Post and base
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [Color(hex: 0xc58b3a), Color(hex: 0x7c4f1c)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 16, height: h * 0.34).position(x: pivot.x, y: pivot.y + h * 0.17)
                Trapezoid().fill(Color(hex: 0x7c4f1c)).frame(width: 110, height: 22).position(x: pivot.x, y: pivot.y + h * 0.34)

                // Chains + pans (pans stay level, hanging from the beam ends)
                pan(items: p.left, at: leftEnd, hang: hang, side: 0)
                pan(items: p.right, at: rightEnd, hang: hang, side: 1)

                // Beam
                Capsule()
                    .fill(LinearGradient(colors: [Color(hex: 0xf0c66a), Color(hex: 0xa8742a)], startPoint: .top, endPoint: .bottom))
                    .overlay(Capsule().stroke(Color(hex: 0x6b4515), lineWidth: 2))
                    .frame(width: L * 2 + 20, height: 14)
                    .rotationEffect(.degrees(tilt))
                    .position(pivot)
                // Pivot cap + the peg that holds the beam until the lever is pulled
                Circle().fill(Color(hex: 0xf5d27a)).overlay(Circle().stroke(Color(hex: 0x6b4515), lineWidth: 2))
                    .frame(width: 26).position(pivot)
                if model.stage == .filling {
                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0x5a3818)).frame(width: 10, height: 34)
                        .position(x: pivot.x + 30, y: pivot.y + 18)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                verdict.position(x: w / 2, y: pivot.y - 40)

                sackPanel.frame(width: w - 28).position(x: w / 2, y: h * 0.70)
                trayRow.frame(width: w - 20).position(x: w / 2, y: h * 0.835)
                lever.position(x: w / 2, y: h - 40)
            }
            .animation(.spring(response: 0.7, dampingFraction: 0.45), value: model.tilt)
        }
        .onChange(of: model.lastMiss) { _ in withAnimation(.linear(duration: 0.45)) { shake += 1 } }
    }

    // MARK: Equation plaque

    private var equationPlaque: some View {
        VStack(spacing: 2) {
            if p.eq.isEmpty {
                Text(p.hint).font(luSerif(26, .black)).foregroundStyle(Color(hex: 0x3a2410))
            } else {
                Text(p.eq).font(luSerif(p.eq.count > 16 ? 26 : 32, .black)).foregroundStyle(Color(hex: 0x3a2410))
                    .lineLimit(1).minimumScaleFactor(0.5)
                if p.hint != "Make it balance!" {
                    Text(p.hint).font(luFont(14, .heavy)).foregroundStyle(Color(hex: 0x7a5228))
                }
            }
        }
        .padding(.vertical, 8).padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(LinearGradient(colors: [Color(hex: 0xf6edd8), Color(hex: 0xdccba5)], startPoint: .top, endPoint: .bottom))
            .shadow(color: .black.opacity(0.35), radius: 0, x: 0, y: 4))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0x9c7b33), lineWidth: 3))
        .id(model.roundID)
        .transition(.opacity)
    }

    @ViewBuilder private var verdict: some View {
        if model.stage == .settled || model.stage == .weighing {
            if model.correct && model.stage == .settled {
                Text("BALANCED!").font(luFont(30)).foregroundStyle(Color(hex: Lu.gold))
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 2, y: 2)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            } else if !model.correct {
                let dfx = p.diff(model.stage == .settled ? p.answer : model.fill)
                let txt: String = model.stage == .settled
                    ? (p.letter ? "x = \(p.answer)" : "? = \(p.answer)")
                    : (sackSide == 1 ? (dfx > 0 ? "Too heavy!" : "Too light!") : (dfx > 0 ? "Too light!" : "Too heavy!"))
                Text(txt).font(luFont(26)).foregroundStyle(Color(hex: model.stage == .settled ? Lu.mint : 0xffd0c0))
                    .padding(.horizontal, 14).padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.45)))
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
        }
    }

    /// Which side the (first) sack is on.
    private var sackSide: Int { p.right.contains(.bag) && !p.left.contains(.bag) ? 1 : 0 }

    // MARK: Pans

    private func pan(items: [LItem], at end: CGPoint, hang: CGFloat, side: Int) -> some View {
        let panY = end.y + hang
        return ZStack(alignment: .topLeading) {
            Path { path in
                path.move(to: end); path.addLine(to: CGPoint(x: end.x - 54, y: panY))
                path.move(to: end); path.addLine(to: CGPoint(x: end.x + 54, y: panY))
            }
            .stroke(Color(hex: 0x4a3418), style: StrokeStyle(lineWidth: 2, dash: [4, 2]))
            PanBowl().frame(width: 124, height: 24).position(x: end.x, y: panY + 10)
            PanLoad(items: items, fill: model.fill, letter: p.letter,
                    showFill: !model.sack.isEmpty, reveal: model.stage == .settled && !model.correct)
                .frame(width: 124)
                .position(x: end.x, y: panY - 2)
                .alignmentGuide(.top) { _ in 0 }
                .offset(y: -30)
        }
    }

    // MARK: The sack (what the child has put in)

    private var sackPanel: some View {
        HStack(spacing: 10) {
            SackIcon(label: model.sack.isEmpty ? (p.letter ? "x" : "?") : "\(model.fill)", size: 54,
                     glow: model.stage == .settled && model.correct)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if model.sack.isEmpty {
                        Text("Tap weights to fill the sack").font(luFont(15, .bold)).foregroundStyle(Color(hex: 0xf3e2c0).opacity(0.85))
                    }
                    ForEach(Array(model.sack.enumerated()), id: \.offset) { i, wgt in
                        Button { model.remove(at: i) } label: { WeightView(value: wgt, size: 40) }
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.vertical, 4)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: model.sack)
            }
            if !model.sack.isEmpty && model.stage == .filling {
                Button { model.clear() } label: {
                    Image(systemName: "arrow.uturn.backward.circle.fill").font(.system(size: 30))
                        .foregroundStyle(Color(hex: 0xf3e2c0))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0x3c1a14).opacity(0.75)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0x9c7b33), lineWidth: 2))
        .modifier(LibraryShake(amount: 8, shakes: shake))
    }

    private var trayRow: some View {
        HStack(spacing: 8) {
            ForEach(p.tray, id: \.self) { wgt in
                Button { model.add(wgt) } label: {
                    WeightView(value: wgt, size: p.tray.count > 5 ? 48 : 58)
                        .frame(minWidth: 44, minHeight: 56)
                }
                .buttonStyle(PressScale())
            }
        }
        .padding(.vertical, 8).padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Color(hex: 0x8a5a2b), Color(hex: 0x5e3a18)], startPoint: .top, endPoint: .bottom)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0x3a220c), lineWidth: 2))
        .opacity(model.stage == .filling ? 1 : 0.6)
    }

    private var lever: some View {
        Button { model.weigh() } label: {
            HStack(spacing: 10) {
                Image(systemName: "scalemass.fill").font(.system(size: 22, weight: .bold))
                Text("WEIGH IT").font(luFont(22))
            }
            .foregroundStyle(Color(hex: Lu.inkDark))
            .frame(width: 220, height: 56)
            .background(Capsule().fill(LinearGradient(colors: [Color(hex: 0xffe08a), Color(hex: Lu.gold)], startPoint: .top, endPoint: .bottom))
                .shadow(color: .black.opacity(0.4), radius: 0, x: 0, y: 4))
            .overlay(Capsule().stroke(Color(hex: 0x7a5a12), lineWidth: 3))
        }
        .buttonStyle(PressScale())
        .disabled(model.sack.isEmpty || model.stage != .filling)
        .opacity(model.sack.isEmpty || model.stage != .filling ? 0.5 : 1)
    }
}

private struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// What sits on a pan: fruit in neat rows, bronze weights, sacks, engraved blocks, balloons.
private struct PanLoad: View {
    let items: [LItem]
    let fill: Int
    let letter: Bool
    let showFill: Bool
    let reveal: Bool

    var body: some View {
        let balloons = items.compactMap { if case .balloon(let n) = $0 { return n } else { return nil } }
        let rest = items.filter { if case .balloon = $0 { return false } else { return true } }
        ZStack(alignment: .bottom) {
            ForEach(Array(balloons.enumerated()), id: \.offset) { _, n in
                VStack(spacing: 0) {
                    ZStack {
                        Ellipse().fill(RadialGradient(colors: [Color(hex: 0xff9a8a), Color(hex: 0xd8352a)], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 2, endRadius: 30))
                            .frame(width: 50, height: 58)
                        VStack(spacing: -2) {
                            Text("lifts").font(luFont(10, .heavy))
                            Text("\(n)").font(luFont(22))
                        }
                        .foregroundStyle(.white)
                    }
                    Rectangle().fill(Color.white.opacity(0.8)).frame(width: 1.5, height: 46)
                }
                .offset(x: 34, y: -16)
            }
            FlowRow(items: rest, fill: fill, letter: letter, showFill: showFill, reveal: reveal)
        }
    }
}

private struct FlowRow: View {
    let items: [LItem]
    let fill: Int
    let letter: Bool
    let showFill: Bool
    let reveal: Bool

    var body: some View {
        // Fruit piles get their own rows of 5; everything else wraps 3 to a row.
        let rows = layout()
        VStack(spacing: 2) {
            ForEach(rows.indices, id: \.self) { ri in
                HStack(spacing: 3) {
                    ForEach(rows[ri].indices, id: \.self) { ci in cell(rows[ri][ci]) }
                }
            }
        }
    }

    private enum Cell { case fruit(String), item(LItem) }

    private func layout() -> [[Cell]] {
        var cells: [Cell] = []
        for it in items {
            if case .fruit(let e, let n) = it { cells += Array(repeating: .fruit(e), count: n) } else { cells.append(.item(it)) }
        }
        let fruitOnly = cells.allSatisfy { if case .fruit = $0 { return true }; return false }
        let per = fruitOnly ? 5 : 3
        var rows: [[Cell]] = []
        var i = 0
        while i < cells.count { rows.append(Array(cells[i..<min(cells.count, i + per)])); i += per }
        return rows.reversed()      // fullest row at the bottom
    }

    @ViewBuilder private func cell(_ c: Cell) -> some View {
        switch c {
        case .fruit(let e): Text(e).font(.system(size: 24))
        case .item(let it):
            switch it {
            case .weight(let w): WeightView(value: w, size: items.count > 4 ? 34 : 40)
            case .bag: SackIcon(label: showFill || reveal ? "\(fill)" : (letter ? "x" : "?"), size: items.count > 3 ? 36 : 44, glow: reveal)
            case .block(let t, _):
                Text(t).font(luFont(16, .heavy)).foregroundStyle(Color(hex: 0x2d2a26))
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .padding(.horizontal, 6).frame(width: 128, height: 40)
                    .background(RoundedRectangle(cornerRadius: 4).fill(LinearGradient(colors: [Color(hex: 0xeee7d6), Color(hex: 0xb9b09c)], startPoint: .top, endPoint: .bottom)))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: 0x6f6858), lineWidth: 1.5))
            default: EmptyView()
            }
        }
    }
}

/// A bronze weight: a squat bell shape with its number stamped on it.
private struct WeightView: View {
    let value: Int
    var size: CGFloat = 44
    var body: some View {
        let big = value >= 20
        ZStack {
            WeightShape()
                .fill(LinearGradient(colors: big ? [Color(hex: 0xf2d27c), Color(hex: 0xb07d24)] : [Color(hex: 0xd99a5c), Color(hex: 0x8a5426)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(WeightShape().stroke(Color(hex: 0x4a2c10), lineWidth: 1.5))
            Text("\(value)").font(luFont(size * (value >= 100 ? 0.3 : 0.4))).foregroundStyle(Color(hex: 0x2b1606))
                .offset(y: size * 0.1)
        }
        .frame(width: size * (big ? 1.05 : 0.9), height: size * 0.92)
    }
}
private struct WeightShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let knob = r.width * 0.18
        p.addEllipse(in: CGRect(x: r.midX - knob, y: r.minY, width: knob * 2, height: knob * 1.4))
        p.move(to: CGPoint(x: r.minX + r.width * 0.22, y: r.minY + knob * 1.1))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.22, y: r.minY + knob * 1.1))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY - 3), control: CGPoint(x: r.maxX - r.width * 0.02, y: r.midY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - 3))
        p.addQuadCurve(to: CGPoint(x: r.minX + r.width * 0.22, y: r.minY + knob * 1.1), control: CGPoint(x: r.minX + r.width * 0.02, y: r.midY))
        p.closeSubpath()
        return p
    }
}

/// A tied burlap sack with a tag.
private struct SackIcon: View {
    let label: String
    var size: CGFloat = 44
    var glow = false
    var body: some View {
        ZStack {
            SackShape().fill(LinearGradient(colors: [Color(hex: 0xe0c08a), Color(hex: 0xa98450)], startPoint: .top, endPoint: .bottom))
                .overlay(SackShape().stroke(Color(hex: 0x5e4320), lineWidth: 1.5))
            Capsule().fill(Color(hex: 0x7a5228)).frame(width: size * 0.42, height: size * 0.08).offset(y: -size * 0.24)
            Text(label).font(luFont(size * (label.count > 2 ? 0.3 : 0.4))).foregroundStyle(Color(hex: 0x2b1606))
                .lineLimit(1).minimumScaleFactor(0.5).frame(width: size * 0.8)
                .offset(y: size * 0.12)
        }
        .frame(width: size, height: size)
        .shadow(color: glow ? Color(hex: Lu.mint) : .clear, radius: glow ? 8 : 0)
    }
}
private struct SackShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX - r.width * 0.16, y: r.minY + r.height * 0.26))
        p.addLine(to: CGPoint(x: r.midX - r.width * 0.26, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX + r.width * 0.26, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX + r.width * 0.16, y: r.minY + r.height * 0.26))
        p.addQuadCurve(to: CGPoint(x: r.midX + r.width * 0.36, y: r.maxY), control: CGPoint(x: r.maxX + r.width * 0.08, y: r.midY + r.height * 0.1))
        p.addLine(to: CGPoint(x: r.midX - r.width * 0.36, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.midX - r.width * 0.16, y: r.minY + r.height * 0.26), control: CGPoint(x: r.minX - r.width * 0.08, y: r.midY + r.height * 0.1))
        p.closeSubpath()
        return p
    }
}

private struct PanBowl: View {
    var body: some View {
        ZStack {
            HalfBowl().fill(LinearGradient(colors: [Color(hex: 0xe9b95a), Color(hex: 0x8a5f1e)], startPoint: .top, endPoint: .bottom))
            Capsule().fill(Color(hex: 0xf7d98c)).frame(height: 6).frame(maxHeight: .infinity, alignment: .top)
        }
        .shadow(color: .black.opacity(0.3), radius: 0, x: 0, y: 3)
    }
}
private struct HalfBowl: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY * 2))
        p.closeSubpath()
        return p
    }
}
private struct Trapezoid: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.2, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX - r.width * 0.2, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.closeSubpath()
        return p
    }
}
