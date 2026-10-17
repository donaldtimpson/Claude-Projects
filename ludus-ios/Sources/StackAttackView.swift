import SwiftUI

// MARK: - Stack Attack  (Number Crunchers · stacker)
//
// Solve the sum, tap the answer, and a stone block drops onto the tower (each level's blocks
// get their own colour, so the tower shows how far the run climbed). A wrong answer wobbles
// the tower and shows the right sum. From level IV the next block hangs over the tower and
// slowly lowers — answer before it lands.
//   I     + within 5, as pictures to count (🍎🍎 + 🍎), 3 choices
//   II    + within 10, pictures
//   III   − within 10, pictures with the taken-away ones crossed out (and some plain + to 10)
//   IV    + and − within 20, numbers only; the block clock starts (18 s)
//   V     ×2 ×5 ×10, and 2-digit + without carrying; 4 choices
//   VI    × tables 2–9, ÷ by 2, 5, 10
//   VII   × to 12, ÷ tables 2–9, 2-digit + and − with carrying
//   VIII+ all of it plus missing numbers (? × 7 = 56, 48 ÷ ? = 6); the clock tightens to 7 s
// Everything is input-driven SwiftUI animation — no frame loop, no timers ticking.

private struct SAPicture { let emoji: String; let a: Int; let b: Int; let minus: Bool }

private struct SAProblem {
    let a: Int, b: Int, c: Int    // a op b = c
    let op: String                // "+", "−", "×", "÷"
    let unknown: Int              // 0 = a, 1 = b, 2 = c (the "?")
    var options: [Int] = []
    var correct = 0
    var pic: SAPicture?
    var answer: Int { [a, b, c][unknown] }
    private func part(_ i: Int, solved: Bool) -> String { i == unknown && !solved ? "?" : "\([a, b, c][i])" }
    func text(solved: Bool) -> String { "\(part(0, solved: solved)) \(op) \(part(1, solved: solved)) = \(part(2, solved: solved))" }
}

private let saEmoji = ["🍎", "⭐️", "🐟", "🐞", "🍪", "🌸", "🐥"]

/// Seconds the hanging block takes to land (0 = no clock).
private func saTime(_ level: Int) -> Double { level <= 3 ? 0 : max(7, 18 - Double(level - 4) * 2.5) }
private func saChoices(_ level: Int) -> Int { level <= 4 ? 3 : 4 }

private func saProblem(_ level: Int) -> SAProblem {
    func r(_ x: ClosedRange<Int>) -> Int { Int.random(in: x) }
    func plus(_ a: Int, _ b: Int) -> SAProblem { SAProblem(a: a, b: b, c: a + b, op: "+", unknown: 2) }
    func minus(_ a: Int, _ b: Int) -> SAProblem { SAProblem(a: a, b: b, c: a - b, op: "−", unknown: 2) }
    func times(_ a: Int, _ b: Int) -> SAProblem { SAProblem(a: a, b: b, c: a * b, op: "×", unknown: 2) }
    func divide(_ d: Int, _ q: Int) -> SAProblem { SAProblem(a: d * q, b: d, c: q, op: "÷", unknown: 2) }
    func pictured(_ p: SAProblem) -> SAProblem {
        var p = p; p.pic = SAPicture(emoji: saEmoji.randomElement()!, a: p.a, b: p.b, minus: p.op == "−"); return p
    }
    func noCarryPlus() -> SAProblem {
        let t1 = r(1...7), t2 = r(1...(8 - t1)), o1 = r(0...8), o2 = r(0...(9 - o1))
        return plus(t1 * 10 + o1, t2 * 10 + o2)
    }
    func carryPlus() -> SAProblem {
        var a = 0, b = 0
        repeat { a = r(15...79); b = r(15...79) } while a % 10 + b % 10 < 10
        return plus(a, b)
    }
    func borrowMinus() -> SAProblem {
        var a = 0, b = 0
        repeat { a = r(31...99); b = r(12...(a - 6)) } while a % 10 >= b % 10
        return minus(a, b)
    }

    var p: SAProblem
    switch level {
    case 1:
        let a = r(1...4); p = pictured(plus(a, r(1...(5 - a))))
    case 2:
        p = pictured(plus(r(1...5), r(1...5)))
    case 3:
        if Double.random(in: 0..<1) < 0.65 { let a = r(3...10); p = pictured(minus(a, r(1...(a - 1)))) }
        else { let a = r(2...8); p = plus(a, r(1...(10 - a))) }
    case 4:
        if Bool.random() { let a = r(3...17); p = plus(a, r(2...(20 - a))) }
        else { let a = r(8...20); p = minus(a, r(2...(a - 1))) }
    case 5:
        if Double.random(in: 0..<1) < 0.65 {
            let k = [2, 5, 10].randomElement()!, n = r(1...10)
            p = Bool.random() ? times(k, n) : times(n, k)
        } else { p = noCarryPlus() }
    case 6:
        if Double.random(in: 0..<1) < 0.6 { p = times(r(2...9), r(2...9)) }
        else { p = divide([2, 5, 10].randomElement()!, r(1...10)) }
    case 7:
        switch r(0...3) {
        case 0: p = times(r(2...12), r(2...12))
        case 1: p = divide(r(2...9), r(2...9))
        case 2: p = carryPlus()
        default: p = borrowMinus()
        }
    default:
        switch r(0...5) {
        case 0: p = times(r(3...12), r(3...12))
        case 1: p = divide(r(3...12), r(2...12))
        case 2: var m = times(r(3...12), r(3...12)); m = SAProblem(a: m.a, b: m.b, c: m.c, op: "×", unknown: 0); p = m
        case 3: let d = divide(r(3...12), r(2...12)); p = SAProblem(a: d.a, b: d.b, c: d.c, op: "÷", unknown: 1)
        case 4: let s = carryPlus(); p = SAProblem(a: s.a, b: s.b, c: s.c, op: "+", unknown: Bool.random() ? 0 : 1)
        default: p = borrowMinus()
        }
    }

    // Wrong choices: near misses (±1, ±2, ±10) and, for × / ÷, the neighbouring table facts.
    let ans = p.answer
    var near = [ans + 1, ans - 1, ans + 2, ans - 2]
    if ans >= 12 { near += [ans + 10, ans - 10] }
    if p.op == "×" && p.unknown == 2 { near += [p.a * (p.b + 1), p.a * (p.b - 1), (p.a + 1) * p.b, (p.a - 1) * p.b] }
    let floor = level <= 3 ? 1 : 0
    var opts = [ans]
    for o in near.shuffled() where o >= floor && !opts.contains(o) && opts.count < saChoices(level) { opts.append(o) }
    var k = 3
    while opts.count < saChoices(level) { if !opts.contains(ans + k) { opts.append(ans + k) }; k += 1 }
    opts.shuffle()
    p.options = opts
    p.correct = opts.firstIndex(of: ans)!
    return p
}

private struct SABlock: Identifiable {
    let id: Int
    let colorHex: UInt
    let offset: CGFloat           // a little jitter for a hand-stacked look
}

@MainActor
private final class SAEngine: ArcadeModel {
    @Published var problem = saProblem(1)
    @Published var blocks: [SABlock] = []
    @Published var revealed = false
    @Published var chosen: Int?
    @Published var wobble = false
    @Published var drop: CGFloat = 0           // 0 → 1 as the hanging block lowers
    @Published var perQ: Double = 0
    @Published var mood = "🙂"

    private var blockCounter = 0
    private var timeout: DispatchWorkItem?

    init() {
        super.init(key: GameID.stackAttack.rawValue)
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { Self.selfCheck() }
        #endif
    }

    override func onBegin() {
        blocks = []; blockCounter = 0; wobble = false; mood = "🙂"
        nextProblem()
    }

    func choose(_ i: Int) {
        guard phase == .playing, !revealed else { return }
        timeout?.cancel()
        revealed = true; chosen = i
        withAnimation(.easeOut(duration: 0.15)) { drop = 0 }
        let right = i == problem.correct
        if right {
            blockCounter += 1
            let hex = Lu.bubbleHexes[(level - 1) % Lu.bubbleHexes.count]
            withAnimation(.spring(response: 0.34, dampingFraction: 0.62)) {
                blocks.append(SABlock(id: blockCounter, colorHex: hex, offset: CGFloat.random(in: -10...10)))
            }
            mood = combo >= 2 ? "🤩" : "😄"
            hit()
        } else {
            mood = "😵"
            withAnimation(.spring(response: 0.16, dampingFraction: 0.28)) { wobble = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { self?.wobble = false }
            }
            miss(reason: i < 0 ? "The block landed!" : "The tower toppled!", delay: 1.6)
        }
        // A miss lingers so the right sum sinks in.
        DispatchQueue.main.asyncAfter(deadline: .now() + (right ? 0.55 : 1.6)) { [weak self] in
            guard let self, self.phase == .playing, !self.dying else { return }
            self.nextProblem()
        }
    }

    override func botAct(correct: Bool) {
        guard !revealed, !problem.options.isEmpty else { return }
        let wrong = problem.options.indices.filter { $0 != problem.correct }
        choose(correct ? problem.correct : wrong.randomElement()!)
    }

    private func nextProblem() {
        problem = saProblem(level)
        revealed = false; chosen = nil
        if mood == "😵" { mood = "🙂" }
        perQ = saTime(level)
        drop = 0
        guard perQ > 0 else { return }
        // The hanging block lowers as one SwiftUI animation; a single work item lands it.
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.revealed else { return }
            withAnimation(.linear(duration: self.perQ)) { self.drop = 1 }
        }
        let item = DispatchWorkItem { [weak self] in
            guard let self, self.phase == .playing, !self.revealed else { return }
            self.choose(-1)
        }
        timeout = item
        DispatchQueue.main.asyncAfter(deadline: .now() + perQ, execute: item)
    }

    override func finish(_ reason: String) {
        timeout?.cancel()
        super.finish(reason)
    }

    #if DEBUG
    /// Every problem: whole, non-negative numbers; a op b really equals c; the "?" is one of
    /// them; the options are distinct and exactly one is the answer. LUDUS_SELFCHECK=1.
    static func selfCheck() {
        for level in 1...10 {
            for _ in 0..<3000 {
                let p = saProblem(level)
                let ok: Bool
                switch p.op {
                case "+": ok = p.a + p.b == p.c
                case "−": ok = p.a - p.b == p.c
                case "×": ok = p.a * p.b == p.c
                case "÷": ok = p.b != 0 && p.a % p.b == 0 && p.a / p.b == p.c
                default: ok = false
                }
                precondition(ok && min(p.a, p.b, p.c) >= 0, "L\(level) bad sum \(p.text(solved: true))")
                precondition(Set(p.options).count == p.options.count, "L\(level) duplicate options \(p.options)")
                precondition(p.options.filter { $0 == p.answer }.count == 1 && p.options[p.correct] == p.answer, "L\(level) answer")
                precondition(p.options.count == saChoices(level) && p.options.allSatisfy { $0 >= 0 }, "L\(level) options \(p.options)")
                if level <= 2 { precondition(p.pic != nil && p.c <= (level == 1 ? 5 : 10), "L\(level) too big") }
            }
            print("SELFCHECK stackAttack L\(level) ok — e.g. \(saProblem(level).text(solved: false))")
        }
    }
    #endif
}

// MARK: - Views

private struct SAOptionButton: View {
    let value: Int
    let index: Int
    let revealed: Bool
    let chosen: Int?
    let correct: Int
    let action: () -> Void

    private var fillHex: UInt {
        guard revealed else { return Lu.panel }
        if index == correct { return Lu.mint }
        if index == chosen { return Lu.coral }
        return Lu.panel
    }

    var body: some View {
        Button(action: action) {
            Text("\(value)")
                .font(luFont(34))
                .foregroundStyle(Color(hex: revealed && (index == correct || index == chosen) ? Lu.inkDark : Lu.ink))
                .minimumScaleFactor(0.5).lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 84)
                .padding(.horizontal, 6)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: fillHex))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: Lu.line), lineWidth: 2)))
                .scaleEffect(revealed && index == correct && chosen != correct ? 1.06 : 1)
                .opacity(revealed && index != correct && index != chosen ? 0.45 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: revealed)
        }
        .buttonStyle(.plain)
        .disabled(revealed)
    }
}

/// `n` pictures in rows of five; the last `crossed` are taken away (faded, ✕).
private struct SAGroup: View {
    let n: Int, emoji: String, size: CGFloat
    var crossed = 0
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(0..<((n + 4) / 5), id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(row * 5..<min(n, row * 5 + 5), id: \.self) { k in
                        let gone = k >= n - crossed
                        Text(emoji).font(.system(size: size)).opacity(gone ? 0.35 : 1)
                            .overlay {
                                if gone {
                                    Image(systemName: "xmark").font(.system(size: size * 0.8, weight: .black))
                                        .foregroundStyle(Color(hex: Lu.coral))
                                }
                            }
                    }
                }
            }
        }
    }
}

private struct SAPictureSum: View {
    let pic: SAPicture
    var body: some View {
        // As big as a row of (up to) five per group allows.
        let across = pic.minus ? min(pic.a, 5) : min(pic.a, 5) + min(pic.b, 5) + 1
        let size = min(42, 280 / CGFloat(across))
        HStack(spacing: 10) {
            if pic.minus {
                SAGroup(n: pic.a, emoji: pic.emoji, size: size, crossed: pic.b)
            } else {
                SAGroup(n: pic.a, emoji: pic.emoji, size: size)
                Text("+").font(luFont(34)).foregroundStyle(Color(hex: Lu.gold))
                SAGroup(n: pic.b, emoji: pic.emoji, size: size)
            }
        }
    }
}

private struct SATowerView: View {
    let blocks: [SABlock]
    let wobble: Bool
    let hanging: Bool
    let drop: CGFloat
    let hangHex: UInt
    let mood: String

    private let blockH: CGFloat = 28
    private let blockW: CGFloat = 124
    private let gap: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            // Show what fits; the tower "scrolls" so the top stays in view (room kept for the face).
            let capacity = max(3, Int((geo.size.height - 70) / (blockH + gap)))
            let visible = Array(blocks.suffix(capacity))
            let baseX = geo.size.width / 2
            let rowY: (Int) -> CGFloat = { geo.size.height - 14 - blockH / 2 - CGFloat($0) * (blockH + gap) }
            let topY = visible.isEmpty ? geo.size.height - 14 : rowY(visible.count - 1) - blockH / 2

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: Lu.ground2))
                    .frame(width: blockW + 30, height: 12)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: Lu.line), lineWidth: 2))
                    .frame(maxHeight: .infinity, alignment: .bottom)

                ForEach(Array(visible.enumerated()), id: \.element.id) { row, block in
                    SAStoneBlock(hex: block.colorHex, width: blockW, height: blockH)
                        .position(x: baseX + block.offset + (wobble ? CGFloat(row) * 2 : 0), y: rowY(row))
                        .rotationEffect(.degrees(wobble ? Double(row) * 0.8 : 0), anchor: .bottom)
                        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                }

                // The builder stands on top and reacts.
                Text(mood).font(.system(size: 40))
                    .position(x: baseX + (visible.last?.offset ?? 0) + (wobble ? 14 : 0), y: topY - 22)
                    .rotationEffect(.degrees(wobble ? 12 : 0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: visible.count)

                if hanging {
                    // The next block, lowering on its rope; it lands on the face at drop = 1.
                    let y = 18 + (topY - 44 - blockH / 2 - 18) * drop
                    Rectangle().fill(Color(hex: Lu.inkDim).opacity(0.6)).frame(width: 2, height: max(0, y - blockH / 2))
                        .position(x: geo.size.width - 60, y: max(0, y - blockH / 2) / 2)
                    SAStoneBlock(hex: hangHex, width: 64, height: blockH)
                        .opacity(0.9)
                        .position(x: geo.size.width - 60, y: y)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: wobble)
        }
    }
}

private struct SAStoneBlock: View {
    let hex: UInt
    let width: CGFloat
    let height: CGFloat
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(LinearGradient(colors: [luShade(hex, 14), Color(hex: hex), luShade(hex, -12)], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(luShade(hex, -30), lineWidth: 2))
            .overlay(RoundedRectangle(cornerRadius: 2).fill(luShade(hex, 26).opacity(0.5)).frame(height: 2)
                .padding(.horizontal, 8).offset(y: -height * 0.28))
            .frame(width: width, height: height)
    }
}

struct StackAttackView: View {
    let onClose: () -> Void
    @StateObject private var engine = SAEngine()

    var body: some View {
        ArcadeShell(model: engine,
                    spec: GameID.stackAttack.spec ?? GameSpec(title: "Stack Attack", mechanic: "stacker", premise: "", game: .stackAttack),
                    accent: Lu.tangerine, onClose: onClose) {
            VStack(spacing: 10) {
                Color.clear.frame(height: 56)     // under the HUD

                // Problem card: pictures to count (early levels), then the sum itself.
                let p = engine.problem
                VStack(spacing: 8) {
                    if let pic = p.pic { SAPictureSum(pic: pic) }
                    Text(p.text(solved: engine.revealed))
                        .font(luFont(p.pic == nil ? 46 : 34))
                        .foregroundStyle(Color(hex: !engine.revealed ? Lu.ink : engine.chosen == p.correct ? Lu.mint : Lu.gold))
                        .minimumScaleFactor(0.5).lineLimit(1)
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: p.pic == nil ? 100 : 150)
                .padding(.vertical, 10)
                .background(luPanelShape(20))

                ZStack {
                    if engine.combo >= 2 {
                        Text("COMBO ×\(engine.combo)!").font(luFont(18)).foregroundStyle(Color(hex: Lu.mint))
                            .id(engine.combo).transition(.scale(scale: 1.25).combined(with: .opacity))
                    }
                }
                .frame(height: 22)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: engine.combo)

                SATowerView(blocks: engine.blocks, wobble: engine.wobble,
                            hanging: engine.perQ > 0 && !engine.revealed && engine.phase == .playing,
                            drop: engine.drop,
                            hangHex: Lu.bubbleHexes[(engine.level - 1) % Lu.bubbleHexes.count],
                            mood: engine.mood)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .topLeading) {
                        Text("HEIGHT \(engine.blocks.count)").font(luSerif(13, .bold)).tracking(1.5)
                            .foregroundStyle(Color(hex: Lu.inkDim)).padding(.leading, 4)
                    }

                let n = engine.problem.options.count
                HStack(spacing: 10) {
                    ForEach(0..<n, id: \.self) { idx in
                        SAOptionButton(value: engine.problem.options[idx], index: idx,
                                       revealed: engine.revealed, chosen: engine.chosen,
                                       correct: engine.problem.correct,
                                       action: { engine.choose(idx) })
                    }
                }
                .padding(.bottom, 6)
            }
            .padding(.horizontal, 14).padding(.top, 4)
        }
    }
}
