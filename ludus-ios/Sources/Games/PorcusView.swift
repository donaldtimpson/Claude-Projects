import SwiftUI

// MARK: - Porcus the Piggy Bank (Market · Money)
//
// A ceramic piggy bank sits on a bedroom desk; a prize hangs on the shelf with its price tag.
// Drag real US coins (and later dollar bills) from the tray into the slot on Porcus's back to
// pay exactly the price. He gulps each coin, gets rounder, and the chalk tag on his side counts along —
// until the tag goes blank and YOU must count (then you press PAY). Too much and he coughs the
// coins back out, and a miss always shows a set of coins that works.
//
// Difficulty (continuous, `d`): content kinds fade in by `tier` — pennies (I) → + nickels →
// + dimes → + quarters → fewest coins → dollar bills → "feed the rest" (saving toward a goal) →
// interest (10%, then 5/20/25/50%). Price ranges grow with `d` inside each kind; the running
// total on Porcus's tag fades away (d 3.3–5.3), and later the value badges on the coins
// (d 5.5–7.5: recognise them by size and colour).

struct PItem: Hashable { let emoji: String, name: String }

private let pPrizes: [PItem] = [
    .init(emoji: "🪁", name: "kite"), .init(emoji: "⚽️", name: "ball"), .init(emoji: "🧸", name: "teddy"),
    .init(emoji: "🛹", name: "skateboard"), .init(emoji: "🎨", name: "paint set"), .init(emoji: "🪀", name: "yo-yo"),
    .init(emoji: "🎈", name: "balloon"), .init(emoji: "🦖", name: "dinosaur"), .init(emoji: "🚂", name: "toy train"),
    .init(emoji: "🛼", name: "roller skate"), .init(emoji: "📚", name: "book"), .init(emoji: "🎲", name: "dice game"),
]

// MARK: Tasks

struct PorcusTask {
    enum Kind { case count, fewest, dollars, goal, interest }
    var kind: Kind
    var prize: PItem
    var price: Int            // what the prize costs (cents)
    var saved = 0             // already in Porcus (goal / interest)
    var target: Int           // what you must feed
    var tray: [USMoney]       // the stacks on the tray, small → big
    var showTotal = true
    var showValues = true
    var line = ""             // what Porcus says (spoken too)
    var explain = ""          // how the answer works (shown on a miss)
}

/// A price that NEEDS the newest coin (so each kind teaches its coin).
private func pPrice(_ lo: Int, _ hi: Int, needs coin: USMoney?) -> Int {
    for _ in 0..<50 {
        let p = Int.random(in: lo...max(lo, hi))
        if let c = coin { if p >= c.cents { return p } } else { return p }
    }
    return max(lo, coin?.cents ?? lo)
}

@MainActor
private func porcusTask(_ m: ArcadeModel) -> PorcusTask {
    let prize = pPrizes.randomElement()!
    // Staggered so no two arrive with a new coin: the running total fades between d 3.3 and 5.3
    // (once dimes are known), the coins' value badges only after that, between 5.5 and 7.5.
    let values = !m.chance(1, from: 5.5, to: 7.5)
    let total = !m.chance(1, from: 3.3, to: 5.3)
    switch m.tier([1, 1.8, 2.8, 3.8, 5, 6, 7, 8.5], keep: 0.08) {
    case 0:
        let p = pPrice(2, m.rampInt(4, 9, to: 2.5), needs: nil)
        return PorcusTask(kind: .count, prize: prize, price: p, target: p, tray: [.penny], showTotal: true, showValues: true,
                          line: "Feed me \(p) cents for the \(prize.name)!", explain: "\(p) pennies = \(p)¢")
    case 1:
        let p = pPrice(5, m.rampInt(9, 19, from: 1.8, to: 3.5), needs: .nickel)
        return PorcusTask(kind: .count, prize: prize, price: p, target: p, tray: [.penny, .nickel], showTotal: total || m.d < 3,
                          showValues: values || m.d < 3, line: "\(p) cents, please! A nickel is 5.", explain: pExplain(p, [.penny, .nickel]))
    case 2:
        let p = pPrice(10, m.rampInt(25, 49, from: 2.8, to: 4.5), needs: .dime)
        return PorcusTask(kind: .count, prize: prize, price: p, target: p, tray: [.penny, .nickel, .dime], showTotal: total,
                          showValues: values, line: "\(p) cents! A dime is 10.", explain: pExplain(p, [.penny, .nickel, .dime]))
    case 3:
        let p = pPrice(25, m.rampInt(50, 99, from: 3.8, to: 5.5), needs: .quarter)
        return PorcusTask(kind: .count, prize: prize, price: p, target: p, tray: USMoney.coins, showTotal: total,
                          showValues: values, line: "\(p) cents! A quarter is 25.", explain: pExplain(p, USMoney.coins))
    case 4:
        let p = pPrice(m.rampInt(30, 55, from: 5, to: 7), 99, needs: .quarter)
        let n = usFewest(p, from: USMoney.coins).count
        return PorcusTask(kind: .fewest, prize: prize, price: p, target: p, tray: USMoney.coins, showTotal: total,
                          showValues: values, line: "\(p) cents — with the FEWEST coins!",
                          explain: "Fewest: \(n) coins — " + pExplain(p, USMoney.coins))
    case 5:
        let p = 5 * Int.random(in: 21...m.rampInt(60, 99, from: 6, to: 8))
        return PorcusTask(kind: .dollars, prize: prize, price: p, target: p, tray: [.penny, .nickel, .dime, .quarter, .one],
                          showTotal: total, showValues: values, line: "The \(prize.name) costs \(usMoney(p)). Feed me exactly that!",
                          explain: pExplain(p, [.penny, .nickel, .dime, .quarter, .one]))
    case 6:
        let p = 5 * Int.random(in: 12...m.rampInt(30, 80, from: 7, to: 9))
        let s = 5 * Int.random(in: 2...(p / 5 - 3))
        let need = p - s
        return PorcusTask(kind: .goal, prize: prize, price: p, saved: s, target: need,
                          tray: need >= 100 ? [.penny, .nickel, .dime, .quarter, .one] : USMoney.coins,
                          showTotal: false, showValues: values,
                          line: "I've saved \(usMoney(s)). The \(prize.name) costs \(usMoney(p)). Feed me the rest!",
                          explain: "\(usMoney(p)) − \(usMoney(s)) = \(usMoney(need))")
    default:
        // Interest: whole-cent answers only.
        let rates = [10] + (m.d > 9 ? [5, 20, 25, 50] : m.d > 8.8 ? [20, 50] : [])
        let r = rates.randomElement()!
        let step = r == 10 ? 10 : r == 5 ? 20 : r == 20 ? 5 : r == 25 ? 4 : 2
        var held = 0
        repeat { held = step * Int.random(in: max(1, 100 / step)...(1000 / step)) } while held % 100 != 0 && Bool.random()
        let i = held * r / 100
        return PorcusTask(kind: .interest, prize: PItem(emoji: "💰", name: "interest"), price: held + i, saved: held, target: i,
                          tray: i >= 100 ? [.penny, .nickel, .dime, .quarter, .one] : USMoney.coins,
                          showTotal: false, showValues: values,
                          line: "I hold \(usMoney(held)). It earns \(r)% interest. Feed me the interest!",
                          explain: "\(r)% of \(usMoney(held)) = \(usMoney(i))")
    }
}

private func pExplain(_ p: Int, _ tray: [USMoney]) -> String {
    let f = usFewest(p, from: tray)
    let groups = tray.sorted(by: >).compactMap { k -> String? in
        let n = f.filter { $0 == k }.count
        return n == 0 ? nil : "\(n) × \(k.label)"
    }
    return groups.joined(separator: " + ") + " = \(usMoney(p))"
}

// MARK: - Model

@MainActor
private final class PorcusModel: ArcadeModel {
    enum Stage { case feeding, done }
    enum Mood { case calm, gulp, happy, cough, sad }

    @Published var task = PorcusTask(kind: .count, prize: pPrizes[0], price: 3, target: 3, tray: [.penny])
    @Published var fed: [USMoney] = []
    @Published var stage: Stage = .feeding
    @Published var mood: Mood = .calm
    @Published var say = ""
    @Published var shelf: [String] = []
    @Published var serial = 0
    @Published var plinks = 0
    @Published var sparks = 0
    @Published var reveal = false

    init() { super.init(key: GameID.porcus.rawValue) }
    override func perLevel(_ level: Int) -> Int { level == 1 ? 4 : 5 }

    var sum: Int { fed.reduce(0) { $0 + $1.cents } }
    /// A PAY button is needed when the tag doesn't count for you, or the fewest-coins rule applies.
    var needsPay: Bool { !task.showTotal || task.kind == .fewest }

    override func onBegin() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil || ProcessInfo.processInfo.environment["LUDUS_SELFTEST"] != nil { selfTest() }
        #endif
        shelf = []
        newTask()
    }

    func newTask() {
        task = porcusTask(self)
        fed = []; stage = .feeding; mood = .calm; reveal = false
        say = task.line
        serial += 1
        if d < 4 { LibraryVoice.say(task.line) }
    }

    func sayAgain() { LibraryVoice.say(task.line) }

    func feed(_ k: USMoney) {
        guard phase == .playing, stage == .feeding else { return }
        fed.append(k); plinks += 1
        Sfx.play(.coin, volume: 0.8); Haptics.tap(0.5)
        mood = .gulp
        let s = serial
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self, self.serial == s, self.mood == .gulp else { return }
            self.mood = .calm
        }
        if sum > task.target {
            say = "Too much! *cough* That's \(usMoney(sum))."
            resolve(false, cough: true)
        } else if sum == task.target && !needsPay {
            resolve(true)
        } else if task.showTotal {
            say = "\(usMoney(sum))…"
        }
    }

    /// Tap Porcus: shake the last coin back out.
    func shakeOut() {
        guard phase == .playing, stage == .feeding, !fed.isEmpty else { return }
        fed.removeLast()
        Sfx.play(.tick); Haptics.light()
        say = task.showTotal ? "\(usMoney(sum))…" : "Clink! One back out."
    }

    func pay() {
        guard phase == .playing, stage == .feeding, !fed.isEmpty else { return }
        if sum != task.target {
            say = sum < task.target ? "Not enough yet — that's \(usMoney(sum))." : "Too much — that's \(usMoney(sum))."
            resolve(false)
        } else if task.kind == .fewest && fed.count > usFewest(task.target, from: task.tray).count {
            say = "Right amount — but fewer coins can do it!"
            resolve(false)
        } else {
            resolve(true)
        }
    }

    private func resolve(_ right: Bool, cough: Bool = false) {
        stage = .done
        if right {
            mood = .happy; sparks += 1
            say = ["Oink! Exactly right!", "Hooray! Oink-oink!", "Perfect! 💕", "Clink-clink — yes!"].randomElement()!
            if task.kind != .interest || shelf.count < 12 { shelf.append(task.prize.emoji) }
            Sfx.play(.sparkle, volume: 0.6)
            hit()
        } else {
            mood = cough ? .cough : .sad
            reveal = true
            miss(delay: 2.8)
        }
        let s = serial
        DispatchQueue.main.asyncAfter(deadline: .now() + (right ? 1.4 : 3.0)) { [weak self] in
            guard let self, self.serial == s, self.phase == .playing, !self.dying else { return }
            self.newTask()
        }
    }

    // One move per call, as a child would: the right next coin (fewest-coins order), then PAY.
    // A wrong round overshoots with a big coin, or pays one penny short.
    private var botSerial = -1, botGood = true
    override func botAct(correct: Bool) {
        guard stage == .feeding else { return }
        if botSerial != serial { botSerial = serial; botGood = correct }
        let left = task.target - sum
        if !botGood {
            if Bool.random(), let big = task.tray.first(where: { $0.cents > left }) { feed(big) }
            else if left > 1 { feed(usFewest(left - 1, from: task.tray).first ?? .penny); if sum == task.target - 1 { pay() } }
            else { feed(task.tray.max()!) }
            return
        }
        if left == 0 { pay(); return }
        feed(usFewest(left, from: task.tray).first!)
    }

    #if DEBUG
    private func selfTest() {
        var errs: [String] = []
        marketSweep(self) {
            let t = porcusTask(self)
            if t.target <= 0 { errs.append("target \(t.target) \(t.kind)") }
            if usFewest(t.target, from: t.tray).reduce(0, { $0 + $1.cents }) != t.target { errs.append("unmakeable \(t.target)") }
            if t.kind == .goal && t.saved + t.target != t.price { errs.append("goal sum") }
            if t.kind == .interest && t.saved + t.target != t.price { errs.append("interest sum") }
        }
        marketLog("PORCUS SELFTEST: \(errs.isEmpty ? "OK" : "\(errs.count) errors \(Array(Set(errs)).prefix(8))")")
    }
    #endif
}

// MARK: - Scene

/// A cosy bedroom at dusk: striped wallpaper, a window with the moon, a wooden desk.
private struct PorcusRoom: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Color(hex: 0x6b4a6e), Color(hex: 0x8a5d6b)], startPoint: .top, endPoint: .bottom)
                // Wallpaper stripes
                HStack(spacing: 22) {
                    ForEach(0..<Int(w / 44) + 2, id: \.self) { _ in
                        Rectangle().fill(Color.white.opacity(0.05)).frame(width: 22)
                    }
                }
                // Window with the night sky and moon
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(LinearGradient(colors: [Color(hex: 0x1d2a5c), Color(hex: 0x4a4f8f)],
                                                                            startPoint: .top, endPoint: .bottom))
                    Circle().fill(Color(hex: 0xfff4c9)).frame(width: 34).offset(x: 22, y: -26)
                        .shadow(color: Color(hex: 0xfff4c9).opacity(0.8), radius: 10)
                    ForEach(0..<6, id: \.self) { i in
                        Circle().fill(Color.white.opacity(0.8)).frame(width: 2.5)
                            .offset(x: CGFloat([-40, -20, 10, -46, 34, -8][i]), y: CGFloat([-40, 10, 30, 22, 26, -44][i]))
                    }
                    Rectangle().fill(Color(hex: 0xe9d7b8)).frame(width: 6)
                    Rectangle().fill(Color(hex: 0xe9d7b8)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xe9d7b8), lineWidth: 8)
                }
                .frame(width: 104, height: 108)
                // Sideways on a tablet: just right of the play column and below the HUD rails.
                .position(x: w > h ? min(w - 66, w / 2 + ArcadeLayout.columnWidth / 2 + 90) : w - 66,
                          y: h * (w > h ? 0.32 : 0.205))
                // Desk
                VStack(spacing: 0) {
                    Rectangle().fill(LinearGradient(colors: [Color(hex: 0xb07a46), Color(hex: 0x8d5a2e)], startPoint: .top, endPoint: .bottom))
                        .frame(height: 16)
                    Rectangle().fill(LinearGradient(colors: [Color(hex: 0x7a4b25), Color(hex: 0x4e2e15)], startPoint: .top, endPoint: .bottom))
                }
                .frame(height: h * 0.38)
                .offset(y: h * 0.62)
            }
        }
    }
}

// MARK: - Porcus himself

/// A pink ceramic piggy bank, side-on, facing left: coin slot on his back, curly tail, blushing
/// cheeks. `fat` (0…1) rounds him out as coins go in.
private struct PorcusPig: View {
    let mood: PorcusModel.Mood
    let fat: CGFloat
    @State private var blink = false

    private let pink = [Color(hex: 0xffc4d6), Color(hex: 0xf28aa8), Color(hex: 0xc9587a)]

    var body: some View {
        let bw: CGFloat = 200 + fat * 26, bh: CGFloat = 138 + fat * 18
        ZStack {
            // Legs
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 9).fill(i % 2 == 0 ? pink[2] : pink[1])
                    .frame(width: 30, height: 40)
                    .offset(x: [-62, -30, 34, 66][i] * (bw / 200), y: bh * 0.42)
            }
            // Tail
            PTail().stroke(pink[2], style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 30, height: 30)
                .offset(x: bw * 0.52, y: -bh * 0.08)
                .rotationEffect(.degrees(mood == .happy ? 20 : 0))
            // Body
            Ellipse().fill(RadialGradient(colors: pink, center: UnitPoint(x: 0.38, y: 0.3), startRadius: 4, endRadius: bw * 0.62))
                .frame(width: bw, height: bh)
            Ellipse().fill(Color.white.opacity(0.35)).frame(width: bw * 0.36, height: bh * 0.16)
                .rotationEffect(.degrees(-10)).offset(x: -bw * 0.06, y: -bh * 0.3)
            // Coin slot
            Capsule().fill(Color(hex: 0x5a1c33)).frame(width: 52, height: 10)
                .overlay(Capsule().stroke(pink[2], lineWidth: 2))
                .offset(x: bw * 0.06, y: -bh * 0.44)
            // Ear (back) and ear (front)
            PEar().fill(pink[2]).frame(width: 34, height: 40).rotationEffect(.degrees(-18)).offset(x: -bw * 0.26, y: -bh * 0.48)
            PEar().fill(pink[1]).frame(width: 36, height: 44).rotationEffect(.degrees(-30)).offset(x: -bw * 0.36, y: -bh * 0.44)
            // Snout
            ZStack {
                Ellipse().fill(LinearGradient(colors: [pink[0], pink[1]], startPoint: .top, endPoint: .bottom))
                    .frame(width: 46, height: mood == .gulp ? 50 : 56)
                    .overlay(Ellipse().stroke(pink[2], lineWidth: 2.5))
                HStack(spacing: 9) {
                    Capsule().fill(Color(hex: 0x8a2e4f)).frame(width: 8, height: 14)
                    Capsule().fill(Color(hex: 0x8a2e4f)).frame(width: 8, height: 14)
                }
            }
            .offset(x: -bw * 0.5, y: -bh * 0.02)
            // Eye
            eye.offset(x: -bw * 0.3, y: -bh * 0.17)
            // Cheek
            Circle().fill(Color(hex: 0xff6f91).opacity(mood == .gulp ? 0.75 : 0.45)).frame(width: mood == .gulp ? 32 : 24)
                .offset(x: -bw * 0.3, y: bh * 0.1)
            // Mouth
            mouth.offset(x: -bw * 0.36, y: bh * 0.22)
        }
        .frame(width: 280, height: 220)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: fat)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: mood)
        .onAppear { blinkLoop() }
    }

    @ViewBuilder private var eye: some View {
        switch mood {
        case .happy:
            PSmileArc().stroke(Color(hex: 0x3a1424), style: StrokeStyle(lineWidth: 5, lineCap: .round)).frame(width: 24, height: 12)
        case .cough:
            Text("✕").font(luFont(22)).foregroundStyle(Color(hex: 0x3a1424))
        default:
            ZStack {
                Ellipse().fill(Color.white).frame(width: 24, height: blink ? 3 : 28)
                Circle().fill(Color(hex: 0x2a1020)).frame(width: 14).offset(x: -3, y: 2).opacity(blink ? 0 : 1)
                Circle().fill(Color.white).frame(width: 5).offset(x: -6, y: -2).opacity(blink ? 0 : 1)
                if mood == .sad {
                    Capsule().fill(Color(hex: 0x3a1424)).frame(width: 26, height: 5).rotationEffect(.degrees(-16)).offset(y: -18)
                }
            }
        }
    }

    @ViewBuilder private var mouth: some View {
        switch mood {
        case .happy, .gulp:
            Ellipse().fill(Color(hex: 0x8a2e4f)).frame(width: 22, height: mood == .gulp ? 10 : 16)
        case .cough:
            Ellipse().fill(Color(hex: 0x8a2e4f)).frame(width: 18, height: 20)
        case .sad:      // ∩ — a frown
            PSmileArc().stroke(Color(hex: 0x8a2e4f), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 18, height: 7)
        case .calm:     // ∪ — a smile
            PSmileArc().stroke(Color(hex: 0x8a2e4f), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 20, height: 8).rotationEffect(.degrees(180))
        }
    }

    private func blinkLoop() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.2...4.5)) {
            withAnimation(.easeInOut(duration: 0.08)) { blink = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation(.easeInOut(duration: 0.08)) { blink = false }
                blinkLoop()
            }
        }
    }
}

private struct PEar: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY), control: CGPoint(x: r.minX, y: r.minY + r.height * 0.2))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.maxX, y: r.minY + r.height * 0.3))
        p.closeSubpath()
        return p
    }
}

private struct PTail: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addCurve(to: CGPoint(x: r.maxX * 0.8, y: r.minY), control1: CGPoint(x: r.width * 0.4, y: r.maxY), control2: CGPoint(x: r.maxX, y: r.maxY * 0.6))
        p.addCurve(to: CGPoint(x: r.width * 0.45, y: r.height * 0.3), control1: CGPoint(x: r.width * 0.6, y: r.minY - r.height * 0.2), control2: CGPoint(x: r.width * 0.4, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.height * 0.45), control1: CGPoint(x: r.width * 0.5, y: r.height * 0.6), control2: CGPoint(x: r.maxX, y: r.height * 0.7))
        return p
    }
}

private struct PSmileArc: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.8))
        return p
    }
}

// MARK: - View

struct PorcusView: View {
    let onClose: () -> Void
    @StateObject private var model = PorcusModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.porcus.spec!, accent: Lu.coral,
                    onClose: { LibraryVoice.stop(); onClose() },
                    backdrop: { PorcusRoom() }) {
            PorcusPlay(model: model)
        }
        .onDisappear { LibraryVoice.stop() }
    }
}

private struct PorcusPlay: View {
    @ObservedObject var model: PorcusModel
    @State private var frames: [String: CGRect] = [:]
    @State private var hover = false
    @State private var plunk = false

    private var t: PorcusTask { model.task }

    var body: some View {
        VStack(spacing: 6) {
            HUDSpace(54)
            shelf
            bubble.padding(.top, 26)
            pig
            bottom
        }
        .padding(.horizontal, 12).padding(.bottom, 6)
        .coordinateSpace(name: "porcus")
        .onPreferenceChange(MarketFrames.self) { frames = $0 }
        .onChange(of: model.plinks) { _ in
            plunk = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { plunk = false }
        }
    }

    // The shelf: the prize standing on it with its price tag hanging below, and the prizes
    // already bought lined up beside it.
    private var shelf: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 6) {
                Text(t.prize.emoji).font(.system(size: 52))
                    .scaleEffect(model.stage == .done && model.mood == .happy ? 1.25 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.45), value: model.mood)
                    .frame(width: 88)
                    .id(model.serial)
                    .transition(.scale.combined(with: .opacity))
                HStack(spacing: 0) {
                    ForEach(Array(model.shelf.suffix(7).enumerated()), id: \.offset) { _, e in
                        Text(e).font(.system(size: 24)).transition(.scale(scale: 0.2).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 112)
            }
            ZStack(alignment: .topLeading) {
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0xa06a3a), Color(hex: 0x6e4524)], startPoint: .top, endPoint: .bottom))
                    .frame(height: 10).clipShape(RoundedRectangle(cornerRadius: 3))
                    .padding(.trailing, 112)
                Text(usMoney(t.price))
                    .font(luFont(24)).foregroundStyle(Color(hex: Lu.inkDark))
                    .padding(.leading, 16).padding(.trailing, 10).padding(.vertical, 3)
                    .background(PTagShape().fill(Color(hex: 0xfdf3d7), style: FillStyle(eoFill: true))
                        .overlay(PTagShape().stroke(Color(hex: 0x9c7b33), lineWidth: 2)))
                    .rotationEffect(.degrees(-6))
                    .offset(x: 14, y: 12)
                    .opacity(t.kind == .interest ? 0 : 1)
            }
        }
        .padding(.top, 6)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: model.shelf.count)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: model.serial)
    }

    private var bubble: some View {
        MarketBubble(fill: 0xfdf6e3) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.say).font(luFont(t.line.count > 60 ? 17 : 20, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                        .lineLimit(3).minimumScaleFactor(0.6)
                    if model.reveal {
                        Text(t.explain).font(luFont(16, .heavy)).foregroundStyle(Color(hex: 0x2f7a3a))
                            .lineLimit(2).minimumScaleFactor(0.6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                LibrarySpeakerButton(size: 40) { model.sayAgain() }
            }
        }
        .frame(minHeight: 70)
        .animation(.easeOut(duration: 0.2), value: model.reveal)
    }

    // Porcus grows into whatever room the screen has (a tall phone has a lot of empty desk
    // otherwise), and sits at the bottom of it, just above the coins.
    private var pig: some View {
        GeometryReader { g in
            // Never wider than the screen (he's ≈ 290 pt wide at k = 1).
            let k = max(1, min(g.size.height / 250, (g.size.width - 12) / 290, 1.45))
            pig(k)
                .frame(width: g.size.width, height: 250 * k)
                .marketFrame("pig", in: "porcus")      // the whole pig zone takes a dropped coin
                .frame(width: g.size.width, height: g.size.height, alignment: .bottom)
        }
        .frame(minHeight: 250, maxHeight: .infinity)
    }

    private func pig(_ k: CGFloat) -> some View {
        let fat = CGFloat(min(1, Double(model.sum + model.task.saved) / Double(max(1, model.task.price))))
        return ZStack {
            PorcusPig(mood: model.mood, fat: fat)
                .scaleEffect((hover ? 1.24 : 1.16) * k)
                .scaleEffect(x: plunk ? 1.05 : 1, y: plunk ? 0.95 : 1, anchor: .bottom)
                .modifier(MarketShake(shakes: CGFloat(model.lastMiss)))
                .animation(.spring(response: 0.2, dampingFraction: 0.5), value: plunk)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: hover)
                .animation(.linear(duration: 0.5), value: model.lastMiss)
                .onTapGesture { model.shakeOut() }
            // Coins coughed back out
            if model.mood == .cough {
                MarketSparks(trigger: model.lastMiss, glyphs: ["🪙"], radius: 120)
            }
            MarketSparks(trigger: model.sparks, glyphs: ["💕", "✨", "🪙"], radius: 110)
            tag.offset(x: 28 * k, y: 40 * k)
        }
    }

    /// The chalk tag on his side: the running total, or "?" once you must count yourself.
    private var tag: some View {
        let text: String = {
            if t.kind == .goal || t.kind == .interest {
                return usMoney(t.saved) + (model.fed.isEmpty ? "" : " + ?")
            }
            return t.showTotal ? usMoney(model.sum) : (model.fed.isEmpty ? "0¢" : "?")
        }()
        return Text(text)
            .font(luFont(22)).foregroundStyle(.white).monospacedDigit()
            .padding(.horizontal, 12).padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0x2f3b33))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0xa07a46), lineWidth: 3)))
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: model.sum)
    }

    @ViewBuilder private var bottom: some View {
        VStack(spacing: 8) {
            if model.reveal {
                // A set of coins that works.
                VStack(spacing: 4) {
                    Text(t.kind == .fewest ? "FEWEST COINS" : "THIS WORKS").font(luFont(12, .heavy)).tracking(2)
                        .foregroundStyle(Color(hex: Lu.ink).opacity(0.8))
                    // One piece per kind with its count ("× 3"), so even $5 in bills fits the width.
                    let f = usFewest(t.target, from: t.tray)
                    HStack(spacing: 10) {
                        ForEach(t.tray.sorted(by: >).filter { f.contains($0) }, id: \.self) { k in
                            let n = f.filter { $0 == k }.count
                            HStack(spacing: 3) {
                                USMoneyView(kind: k, size: k.isBill ? 34 : 40, showValue: true)
                                if n > 1 { Text("× \(n)").font(luFont(18, .heavy)).foregroundStyle(Color(hex: Lu.inkDark)) }
                            }
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: Lu.mint).opacity(0.85)))
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .frame(height: 78)
            } else {
                // What's already gone in, small (so you can recount); a long run shows its last
                // dozen and how many more. Same height as the answer above, so Porcus doesn't
                // jump in size when it appears.
                HStack(spacing: 2) {
                    if model.fed.count > 12 {
                        Text("+\(model.fed.count - 12)").font(luFont(15, .heavy)).foregroundStyle(Color(hex: Lu.ink))
                    }
                    ForEach(Array(model.fed.suffix(12).enumerated()), id: \.offset) { _, k in
                        USMoneyView(kind: k, size: k.isBill ? 20 : (model.fed.count > 9 ? 24 : 30), showValue: t.showValues)
                    }
                }
                .frame(height: 78)
            }
            tray
            if model.needsPay {
                let ready = !model.fed.isEmpty && model.stage == .feeding
                LudusButton(title: "Pay 🛒", fill: ready ? [Lu.mint, 0x3f8f4a] : [Lu.silver, 0xa79f8b],
                            shadow: ready ? 0x2a6a33 : 0x6f6857, fullWidth: true) { model.pay() }
                    .opacity(ready ? 1 : 0.85)
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.reveal)
    }

    /// The coin tray: one stack per kind; drag a coin to Porcus's slot (or tap the stack).
    private var tray: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(t.tray, id: \.self) { k in
                VStack(spacing: 2) {
                    ZStack {
                        if !k.isBill {
                            ForEach(0..<3, id: \.self) { i in
                                USMoneyView(kind: k, size: 58, showValue: false).offset(y: CGFloat(3 - i) * 3).opacity(0.9)
                            }
                        } else {
                            USMoneyView(kind: k, size: 50, showValue: false).offset(x: 3, y: 4).opacity(0.9)
                        }
                        MarketDraggable(space: "porcus", enabled: model.stage == .feeding,
                                        onDrag: { p in hover = p.map { frames["pig"]?.insetBy(dx: -20, dy: -20).contains($0) ?? false } ?? false },
                                        drop: { p in
                                            guard frames["pig"]?.insetBy(dx: -30, dy: -30).contains(p) ?? false else { return false }
                                            model.feed(k); return true
                                        },
                                        tap: { model.feed(k) }) {
                            USMoneyView(kind: k, size: k.isBill ? 50 : 58, showValue: t.showValues)
                        }
                        .id("\(k.rawValue)-\(model.plinks)")
                    }
                    .frame(minWidth: k.isBill ? 110 : 52, minHeight: 64)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(LinearGradient(colors: [Color(hex: 0x2f5e46), Color(hex: 0x1f4232)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: 0xc9a46a), lineWidth: 4))
                .shadow(color: .black.opacity(0.35), radius: 6, y: 4)
        )
        .id(model.serial)
    }
}

/// A paper price tag with a punched hole.
private struct PTagShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let n: CGFloat = 12
        p.move(to: CGPoint(x: r.minX + n, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - 4, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + 4), control: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - 4))
        p.addQuadCurve(to: CGPoint(x: r.maxX - 4, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + n, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        p.addEllipse(in: CGRect(x: r.minX + 6, y: r.midY - 3, width: 6, height: 6))
        return p
    }
}
