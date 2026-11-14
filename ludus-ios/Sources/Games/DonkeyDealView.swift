import SwiftUI

// MARK: - Donkey Deals (Market · Money & life skills) — comparing, choosing, budgeting
//
// Asellus the donkey pulls the family's shopping cart down market street. Two stalls call out
// to him, left and right; the shopping list on the signpost says what you want (the cheaper one,
// the one you NEED, the better deal…). Swipe Asellus toward the right stall — he trots over and
// hee-haws. The wrong stall? He trots back, and the right stall lights up with the working.
//
// Difficulty (continuous, `d`): which is cheaper (pictures + pennies) → needs vs wants → "you
// have 25¢ — which can you buy?" → cheaper with dollars-and-cents traps ($2.05 vs $2.50) →
// price per item ("3 for 60¢" vs "2 for 50¢") → price per ounce → percent discounts ("25% off
// $20" vs "$16") → budgets for a whole basket and "buy 2 get 1 free". From d≈3 the market bell
// starts a countdown that shortens from 20 s to 7 s.

private struct DDOffer {
    var pic: String              // emoji (one or a few)
    var title: String            // the big line on the sign ("3 for 60¢")
    var sub = ""                 // small line ("Bread")
    var pennies = 0              // Gradus I: pennies drawn under the price
}

private struct DDRound {
    var ask: String              // the list's question
    var askPic: String
    var say: String
    var offers: [DDOffer]        // [left, right]
    var correct: Int
    var why: String              // the working (shown on a miss, and briefly on a hit)
}

private let ddNeeds: [(String, String)] = [
    ("🍞", "Bread"), ("🥛", "Milk"), ("🧥", "Winter coat"), ("🪥", "Toothbrush"), ("👟", "School shoes"),
    ("🧼", "Soap"), ("💊", "Medicine"), ("🥦", "Vegetables"), ("✏️", "Pencils"), ("🩹", "Bandages"), ("💧", "Water"),
]
private let ddWants: [(String, String)] = [
    ("🍭", "Lollipop"), ("🎮", "Video game"), ("🧸", "Teddy bear"), ("🎈", "Balloon"), ("🍦", "Ice cream"),
    ("🪀", "Yo-yo"), ("🦖", "Toy dinosaur"), ("🎟️", "Movie ticket"), ("🃏", "Trading cards"), ("🧁", "Cupcake"),
]
private let ddGoods: [(String, String)] = [
    ("🍎", "apples"), ("🍌", "bananas"), ("🥕", "carrots"), ("🍪", "cookies"), ("🥚", "eggs"), ("🍋", "lemons"),
    ("🧦", "socks"), ("✏️", "pencils"), ("🍐", "pears"), ("🧃", "juice boxes"),
]
private let ddSized: [(String, String)] = [("🥣", "Cereal"), ("🥜", "Peanut butter"), ("🍯", "Honey"), ("🧃", "Juice"), ("🧀", "Cheese")]

@MainActor
private func ddRound(_ m: ArcadeModel) -> DDRound {
    func pair(_ a: DDOffer, _ b: DDOffer, aRight: Bool) -> ([DDOffer], Int) {
        Bool.random() ? ([a, b], aRight ? 0 : 1) : ([b, a], aRight ? 1 : 0)
    }
    switch m.tier([1, 1.8, 2.8, 3.8, 5, 6.2, 7.4, 8.6]) {
    case 0:
        let g = ddGoods.randomElement()!
        let a = Int.random(in: 1...m.rampInt(6, 9, to: 1.8))
        var b = Int.random(in: 2...10)
        while abs(a - b) < 2 { b = Int.random(in: 1...10) }
        let lo = min(a, b), hi = max(a, b)
        let (o, c) = pair(DDOffer(pic: g.0, title: "\(lo)¢", pennies: lo), DDOffer(pic: g.0, title: "\(hi)¢", pennies: hi), aRight: true)
        return DDRound(ask: "Which is CHEAPER?", askPic: "🪙⬇️", say: "Which one is cheaper?", offers: o, correct: c,
                       why: "\(lo)¢ is less than \(hi)¢")
    case 1:
        let n = ddNeeds.randomElement()!, w = ddWants.randomElement()!
        let (o, c) = pair(DDOffer(pic: n.0, title: n.1), DDOffer(pic: w.0, title: w.1), aRight: true)
        return DDRound(ask: "Which do you NEED?", askPic: "🏠", say: "Which one do you need?", offers: o, correct: c,
                       why: "\(n.1) is a need — \(w.1.lowercased()) is a want")
    case 2:
        let budget = 5 * Int.random(in: m.rampInt(2, 6, from: 2.8, to: 4)...m.rampInt(6, 19, from: 2.8, to: 4.5))
        let ok = Int.random(in: max(1, budget - 15)...budget)
        let no = Int.random(in: (budget + 1)...(budget + 20))
        let g = ddWants.shuffled().prefix(2).map { $0 }
        let (o, c) = pair(DDOffer(pic: g[0].0, title: usMoney(ok), sub: g[0].1), DDOffer(pic: g[1].0, title: usMoney(no), sub: g[1].1), aRight: true)
        return DDRound(ask: "You have \(usMoney(budget)). Which can you buy?", askPic: "👛", say: "You have \(budget) cents. Which one can you buy?",
                       offers: o, correct: c, why: "\(usMoney(ok)) ≤ \(usMoney(budget)) — \(usMoney(no)) is too much")
    case 3:
        // Decimal traps: $2.05 vs $2.50, 98¢ vs $1.02, $3.40 vs $3.04.
        let g = ddGoods.randomElement()!
        let d = Int.random(in: 1...5)
        let kinds: [(Int, Int)] = [(d * 100 + 5, d * 100 + 50), (95 + Int.random(in: 0...4), 100 + Int.random(in: 1...9)),
                                   (d * 100 + 4, d * 100 + 40), (d * 100 + 15, d * 100 + 51), (d * 100 + 99, (d + 1) * 100 + 9)]
        let (lo, hi) = kinds.randomElement()!
        let (o, c) = pair(DDOffer(pic: g.0, title: usDollars(lo), sub: g.1.capitalized), DDOffer(pic: g.0, title: usDollars(hi), sub: g.1.capitalized), aRight: true)
        return DDRound(ask: "Which is CHEAPER?", askPic: "🪙⬇️", say: "Which one is cheaper?", offers: o, correct: c,
                       why: "\(usDollars(lo)) < \(usDollars(hi)) — look at the dollars, then the dimes")
    case 4:
        // Price per item.
        for _ in 0..<200 {
            let g = ddGoods.randomElement()!
            let na = Int.random(in: 2...6), nb = Int.random(in: 2...6)
            let ua = 5 * Int.random(in: 2...m.rampInt(8, 20, from: 5, to: 7)), ub = 5 * Int.random(in: 2...m.rampInt(8, 20, from: 5, to: 7))
            guard na != nb, ua != ub, abs(ua - ub) >= 5 else { continue }
            let better = ua < ub
            // The bigger pack shouldn't always be the better deal.
            let ta = na * ua, tb = nb * ub
            let A = DDOffer(pic: String(repeating: g.0, count: min(na, 4)), title: "\(na) for \(usMoney(ta))", sub: g.1.capitalized)
            let B = DDOffer(pic: String(repeating: g.0, count: min(nb, 4)), title: "\(nb) for \(usMoney(tb))", sub: g.1.capitalized)
            let (o, c) = pair(A, B, aRight: better)
            return DDRound(ask: "Which is the BETTER DEAL?", askPic: "🏷️", say: "Which is the better deal?", offers: o, correct: c,
                           why: "\(usMoney(ta)) ÷ \(na) = \(usMoney(ua)) each · \(usMoney(tb)) ÷ \(nb) = \(usMoney(ub)) each")
        }
        fallthrough
    case 5:
        // Price per ounce.
        for _ in 0..<200 {
            let g = ddSized.randomElement()!
            let sa = [8, 10, 12, 16, 20, 24, 32].randomElement()!, sb = [8, 10, 12, 16, 20, 24, 32].randomElement()!
            let ua = Int.random(in: 10...40), ub = Int.random(in: 10...40)
            guard sa != sb, abs(ua - ub) >= 3 else { continue }
            let ta = sa * ua, tb = sb * ub
            let A = DDOffer(pic: g.0, title: "\(sa) oz", sub: usDollars(ta)), B = DDOffer(pic: g.0, title: "\(sb) oz", sub: usDollars(tb))
            let (o, c) = pair(A, B, aRight: ua < ub)
            return DDRound(ask: "\(g.1): which is the BETTER DEAL?", askPic: "⚖️", say: "Which is the better deal?", offers: o, correct: c,
                           why: "\(usDollars(ta)) ÷ \(sa) = \(ua)¢ an ounce · \(usDollars(tb)) ÷ \(sb) = \(ub)¢ an ounce")
        }
        fallthrough
    case 6:
        // Percent discounts against a plain price.
        for _ in 0..<200 {
            let g = ddWants.randomElement()!
            let (pct, step) = [(10, 10), (20, 5), (25, 4), (50, 2), (30, 10), (40, 5), (75, 4)].randomElement()!
            let base = step * Int.random(in: max(1, 8 / step)...(m.d > 8 ? 120 / step : 60 / step))
            let sale = base - base * pct / 100
            let plain = sale + (Bool.random() ? 1 : -1) * Int.random(in: 1...max(1, base / 5))
            guard plain > 0, plain != sale, base * pct % 100 == 0, base >= 4 else { continue }
            let A = DDOffer(pic: g.0, title: "$\(base) · \(pct)% off", sub: g.1)
            let B = DDOffer(pic: g.0, title: "$\(plain)", sub: g.1)
            let (o, c) = pair(A, B, aRight: sale < plain)
            return DDRound(ask: "Which costs LESS?", askPic: "🏷️", say: "Which costs less?", offers: o, correct: c,
                           why: "\(pct)% of $\(base) = $\(base * pct / 100) → $\(base) − $\(base * pct / 100) = $\(sale) vs $\(plain)")
        }
        fallthrough
    default:
        if Bool.random() {
            // A basket that fits the budget.
            for _ in 0..<300 {
                let items = Array((ddGoods + ddWants.map { ($0.0, $0.1) }).shuffled().prefix(4))
                let ps = (0..<4).map { _ in 25 * Int.random(in: 2...16) }
                let a = ps[0] + ps[1], b = ps[2] + ps[3]
                let budget = 100 * Int.random(in: 3...8)
                guard (a <= budget) != (b <= budget), abs(a - b) <= 200 else { continue }
                let A = DDOffer(pic: items[0].0 + items[1].0, title: "\(usDollars(ps[0])) + \(usDollars(ps[1]))")
                let B = DDOffer(pic: items[2].0 + items[3].0, title: "\(usDollars(ps[2])) + \(usDollars(ps[3]))")
                let (o, c) = pair(A, B, aRight: a <= budget)
                return DDRound(ask: "You have $\(budget / 100). Which basket can you buy?", askPic: "🧺", say: "Which basket can you buy?",
                               offers: o, correct: c, why: "\(usDollars(a)) vs \(usDollars(b)) — only one is ≤ $\(budget / 100).00")
            }
        }
        // Buy 2 get 1 free vs a 3-pack.
        for _ in 0..<200 {
            let g = ddGoods.randomElement()!
            let each = 25 * Int.random(in: 4...16)
            let free = 2 * each
            let pack = free + (Bool.random() ? 1 : -1) * 25 * Int.random(in: 1...4)
            guard pack > 0, pack != free else { continue }
            let A = DDOffer(pic: g.0 + g.0 + g.0, title: "\(usDollars(each)) each", sub: "Buy 2, get 1 free!")
            let B = DDOffer(pic: g.0 + g.0 + g.0, title: "3 for \(usDollars(pack))", sub: g.1.capitalized)
            let (o, c) = pair(A, B, aRight: free < pack)
            return DDRound(ask: "You need 3. Which costs LESS?", askPic: "🛒", say: "You need three. Which costs less?", offers: o, correct: c,
                           why: "Buy 2 get 1 free = 2 × \(usDollars(each)) = \(usDollars(free)) vs \(usDollars(pack))")
        }
        return DDRound(ask: "Which is CHEAPER?", askPic: "🪙", say: "Which is cheaper?",
                       offers: [DDOffer(pic: "🍎", title: "5¢"), DDOffer(pic: "🍎", title: "9¢")], correct: 0, why: "5¢ < 9¢")
    }
}

// MARK: - Model

@MainActor
private final class DonkeyModel: ArcadeModel {
    enum Stage { case choosing, trotting, done }
    @Published var round = DDRound(ask: "", askPic: "", say: "", offers: [DDOffer(pic: "🍎", title: "3¢"), DDOffer(pic: "🍎", title: "7¢")], correct: 0, why: "")
    @Published var stage: Stage = .choosing
    @Published var chosen: Int?
    @Published var right: Bool?
    @Published var serial = 0
    @Published var deadline: Date?
    @Published var patience: Double = 0
    @Published var haul: [String] = []

    init() { super.init(key: GameID.donkeyDeal.rawValue) }

    override func onBegin() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFTEST"] != nil { selfTest() }
        #endif
        haul = []
        next()
    }

    func next() {
        round = ddRound(self)
        stage = .choosing; chosen = nil; right = nil
        serial += 1
        patience = d < 3 ? 0 : ramp(20, 7, from: 3, to: 10)
        deadline = patience > 0 ? Date().addingTimeInterval(patience) : nil
        if d < 5 { LibraryVoice.say(round.say) }
        let s = serial
        if patience > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + patience) { [weak self] in
                guard let self, self.serial == s, self.stage == .choosing, self.phase == .playing else { return }
                self.resolve(nil)
            }
        }
    }

    func sayAgain() { LibraryVoice.say(round.say) }

    /// Swipe Asellus toward stall `i` (0 = left, 1 = right).
    func choose(_ i: Int) {
        guard phase == .playing, stage == .choosing else { return }
        chosen = i; stage = .trotting; deadline = nil
        Sfx.play(.whoosh, volume: 0.6)
        let s = serial
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self, self.serial == s else { return }
            self.resolve(i)
        }
    }

    private func resolve(_ i: Int?) {
        guard phase == .playing, stage != .done else { return }
        stage = .done; deadline = nil
        let ok = i == round.correct
        right = ok
        if ok {
            haul.append(round.offers[round.correct].pic.first.map(String.init) ?? "🛒")
            Sfx.play(.coin, volume: 0.7)
            hit()
        } else {
            Sfx.play(.thud, volume: 0.6)
            miss(delay: 2.8)
        }
        let s = serial
        DispatchQueue.main.asyncAfter(deadline: .now() + (ok ? 1.3 : 3.2)) { [weak self] in
            guard let self, self.serial == s, self.phase == .playing, !self.dying else { return }
            self.next()
        }
    }

    override func botAct(correct: Bool) {
        guard stage == .choosing else { return }
        choose(correct ? round.correct : 1 - round.correct)
    }

    #if DEBUG
    private func selfTest() {
        var errs: [String] = []
        marketSweep(self) {
            let r = ddRound(self)
            if r.offers.count != 2 || !(0...1).contains(r.correct) { errs.append("shape") }
            if r.offers[0].title == r.offers[1].title && r.offers[0].sub == r.offers[1].sub { errs.append("same \(r.offers[0].title)") }
        }
        marketLog("DONKEY SELFTEST: \(errs.isEmpty ? "OK" : "\(errs.count) errors \(Array(Set(errs)).prefix(8))")")
    }
    #endif
}

// MARK: - Scene

/// Market street in the afternoon: sky, a row of houses, cobbles.
private struct DDStreet: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Color(hex: 0xf7b267), Color(hex: 0xf4d6a0), Color(hex: 0xcfe6ea)], startPoint: .top, endPoint: .bottom)
                MarketCloud(w: 110).position(x: w * 0.3, y: h * 0.13)
                // Distant aqueduct
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { _ in
                        ZStack(alignment: .bottom) {
                            Rectangle().fill(Color(hex: 0xd9a77a))
                            Ellipse().fill(Color(hex: 0xf4d6a0)).frame(width: w / 7 * 0.7, height: 70).offset(y: 35)
                        }
                        .frame(width: w / 7, height: 60)
                    }
                }
                .offset(y: h * 0.3)
                // Cobbles
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0xb9a084), Color(hex: 0x8f7a60)], startPoint: .top, endPoint: .bottom))
                    .frame(height: h * 0.6).offset(y: h * 0.4)
                    .overlay(
                        VStack(spacing: 14) {
                            ForEach(0..<20, id: \.self) { r in
                                HStack(spacing: 10) {
                                    ForEach(0..<9, id: \.self) { _ in
                                        Capsule().fill(Color.black.opacity(0.08)).frame(width: 34, height: 12)
                                    }
                                }
                                .offset(x: r % 2 == 0 ? 0 : 22)
                            }
                        }
                        .offset(y: h * 0.42), alignment: .top)
            }
        }
    }
}

/// Asellus: a grey donkey, side-on, pulling a little cart.
private struct Asellus: View {
    let facing: CGFloat          // -1 left, 1 right
    let trotting: Bool
    let mood: Bool?              // nil / true happy / false sad
    let haul: [String]
    @State private var step = false
    var body: some View {
        ZStack {
            // Cart (behind)
            ZStack {
                RoundedRectangle(cornerRadius: 6).fill(LinearGradient(colors: [Color(hex: 0xb07a46), Color(hex: 0x7a4b25)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 92, height: 46)
                HStack(spacing: -6) { ForEach(Array(haul.suffix(5).enumerated()), id: \.offset) { _, h in Text(h).font(.system(size: 22)) } }
                    .offset(y: -26)
                ForEach([-26.0, 26.0], id: \.self) { x in
                    Circle().stroke(Color(hex: 0x4e2e15), lineWidth: 5).frame(width: 34).offset(x: x, y: 26)
                        .overlay(Circle().fill(Color(hex: 0x4e2e15)).frame(width: 8).offset(x: x, y: 26))
                }
                Rectangle().fill(Color(hex: 0x7a4b25)).frame(width: 40, height: 5).offset(x: 62, y: 4)
            }
            .offset(x: -70, y: 22)
            // Legs
            ForEach(0..<4, id: \.self) { i in
                Capsule().fill(Color(hex: i % 2 == 0 ? 0x8a8f96 : 0x9da2a8)).frame(width: 13, height: 44)
                    .rotationEffect(.degrees(trotting ? (step == (i % 2 == 0) ? 18 : -18) : 0), anchor: .top)
                    .offset(x: [-22, -8, 30, 44][i], y: 36)
            }
            // Tail
            Capsule().fill(Color(hex: 0x6b6f75)).frame(width: 6, height: 34).rotationEffect(.degrees(25)).offset(x: -40, y: 6)
            // Body
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0xb8bcc2), Color(hex: 0x8a8f96)], startPoint: .top, endPoint: .bottom))
                .frame(width: 100, height: 58).offset(x: 10, y: 10)
            Ellipse().fill(Color(hex: 0xe8e4dc)).frame(width: 60, height: 22).offset(x: 12, y: 28)
            // Saddle blanket
            RoundedRectangle(cornerRadius: 6).fill(Color(hex: Lu.coral)).frame(width: 34, height: 30).offset(x: 6, y: 0)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: Lu.gold), lineWidth: 2).frame(width: 34, height: 30).offset(x: 6, y: 0))
            // Neck + head
            Capsule().fill(Color(hex: 0xa3a8ae)).frame(width: 28, height: 56).rotationEffect(.degrees(35)).offset(x: 54, y: -14)
            ZStack {
                // Ears
                Capsule().fill(Color(hex: 0x9da2a8)).frame(width: 13, height: 42).rotationEffect(.degrees(mood == false ? 60 : -12)).offset(x: -10, y: -30)
                Capsule().fill(Color(hex: 0x8a8f96)).frame(width: 13, height: 42).rotationEffect(.degrees(mood == false ? 70 : 8)).offset(x: 2, y: -32)
                Capsule().fill(Color(hex: 0xd6a3a3)).frame(width: 6, height: 26).rotationEffect(.degrees(mood == false ? 60 : -12)).offset(x: -10, y: -30)
                Ellipse().fill(LinearGradient(colors: [Color(hex: 0xb8bcc2), Color(hex: 0x9da2a8)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 44, height: 58).rotationEffect(.degrees(-35))
                Ellipse().fill(Color(hex: 0xe8e4dc)).frame(width: 30, height: 26).offset(x: 14, y: 16)
                Circle().fill(Color(hex: 0x3a3a3a)).frame(width: 5).offset(x: 20, y: 14)
                if mood == true {
                    UrsaLikeArc().stroke(Color(hex: 0x2a2a2a), style: StrokeStyle(lineWidth: 3, lineCap: .round)).frame(width: 12, height: 6).offset(x: -2, y: -6)
                } else {
                    Circle().fill(Color(hex: 0x2a2a2a)).frame(width: 9).offset(x: -2, y: -6)
                    Circle().fill(Color.white).frame(width: 3).offset(x: -3, y: -8)
                }
                // Forelock
                Capsule().fill(Color(hex: 0x5a5e64)).frame(width: 10, height: 16).rotationEffect(.degrees(-30)).offset(x: -10, y: -24)
            }
            .offset(x: 74, y: -36)
        }
        .frame(width: 260, height: 160)
        .scaleEffect(x: facing, y: 1)
        .onAppear { withAnimation(.easeInOut(duration: 0.18).repeatForever()) { step = true } }
    }
}

private struct UrsaLikeArc: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.8))
        return p
    }
}

// MARK: - View

struct DonkeyDealView: View {
    let onClose: () -> Void
    @StateObject private var model = DonkeyModel()
    var body: some View {
        ArcadeShell(model: model, spec: GameID.donkeyDeal.spec!, accent: Lu.coral,
                    onClose: { LibraryVoice.stop(); onClose() },
                    backdrop: { DDStreet() }) {
            DDPlay(model: model)
        }
        .onDisappear { LibraryVoice.stop() }
    }
}

private struct DDPlay: View {
    @ObservedObject var model: DonkeyModel
    @State private var drag: CGFloat = 0
    private var r: DDRound { model.round }

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            VStack(spacing: 8) {
                Color.clear.frame(height: 54)
                signpost
                patienceBar
                HStack(alignment: .top, spacing: 10) {
                    stall(0)
                    stall(1)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                donkey(width: w)
                Text(model.stage == .choosing ? "👈  Swipe Asellus  👉" : " ")
                    .font(luFont(16, .heavy)).foregroundStyle(Color.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.4), radius: 2)
            }
            .padding(.horizontal, 12).padding(.bottom, 8)
        }
    }

    private var signpost: some View {
        HStack(spacing: 10) {
            Text(r.askPic).font(.system(size: 34))
            VStack(alignment: .leading, spacing: 2) {
                Text(r.ask).font(luFont(r.ask.count > 34 ? 18 : 22, .heavy)).foregroundStyle(Color(hex: 0xfdf3d7))
                    .lineLimit(2).minimumScaleFactor(0.7)
                if model.stage == .done, let ok = model.right {
                    Text(ok ? "Hee-haw! " + r.why : r.why).font(luFont(15, .heavy))
                        .foregroundStyle(Color(hex: ok ? 0xb8f0a8 : Lu.gold))
                        .lineLimit(3).minimumScaleFactor(0.6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            LibrarySpeakerButton(size: 40) { model.sayAgain() }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [Color(hex: 0x6e4524), Color(hex: 0x4e2e15)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xc9a46a), lineWidth: 3))
                .shadow(color: .black.opacity(0.3), radius: 5, y: 3)
        )
        .animation(.easeOut(duration: 0.2), value: model.stage)
    }

    @ViewBuilder private var patienceBar: some View {
        TimelineView(.animation(minimumInterval: 0.1, paused: model.deadline == nil || model.phase != .playing)) { tl in
            let left = model.deadline.map { max(0, $0.timeIntervalSince(tl.date)) } ?? 0
            let f = model.patience > 0 ? CGFloat(left / model.patience) : 0
            HStack(spacing: 6) {
                Text("🔔").font(.system(size: 14))
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.black.opacity(0.2))
                        Capsule().fill(Color(hex: f < 0.3 ? Lu.coral : Lu.mint)).frame(width: max(0, g.size.width * f))
                    }
                }
                .frame(height: 8)
            }
        }
        .frame(height: 14)
        .opacity(model.deadline != nil ? 1 : 0)
    }

    private func stall(_ i: Int) -> some View {
        let o = r.offers[i]
        let lit: UInt? = model.stage == .done ? (i == r.correct ? Lu.mint : (i == model.chosen ? Lu.coral : nil)) : nil
        return Button(action: { swipe(to: i) }) {
            VStack(spacing: 0) {
                // Awning
                HStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { k in
                        Rectangle().fill(Color(hex: k % 2 == 0 ? (i == 0 ? 0x3f8f6a : 0x2f6fa0) : 0xfaf1dc))
                    }
                }
                .frame(height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(spacing: 6) {
                    Text(o.pic).font(.system(size: o.pic.count > 2 ? 30 : 52)).lineLimit(1).minimumScaleFactor(0.5)
                    Text(o.title).font(luFont(o.title.count > 12 ? 18 : 26, .black)).foregroundStyle(Color(hex: Lu.inkDark))
                        .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.6)
                    if !o.sub.isEmpty {
                        Text(o.sub).font(luFont(14, .heavy)).foregroundStyle(Color(hex: 0x6e4524))
                            .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.7)
                    }
                    if o.pennies > 0 {
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(22), spacing: 2), count: 5), spacing: 2) {
                            ForEach(0..<o.pennies, id: \.self) { _ in USMoneyView(kind: .penny, size: 26, showValue: false) }
                        }
                    }
                }
                .padding(.vertical, 12).padding(.horizontal, 6)
                .frame(maxWidth: .infinity, minHeight: 220)
                .background(Color(hex: 0xfdf3d7))
                // Counter
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0xb07a46), Color(hex: 0x7a4b25)], startPoint: .top, endPoint: .bottom))
                    .frame(height: 18)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: lit ?? 0x4e2e15), lineWidth: lit == nil ? 3 : 6))
            .shadow(color: lit.map { Color(hex: $0).opacity(0.8) } ?? .black.opacity(0.25), radius: lit == nil ? 4 : 12, y: 3)
            .scaleEffect(lit == Lu.mint ? 1.04 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: model.stage)
        }
        .buttonStyle(.plain)
        .disabled(model.stage != .choosing)
        .id("\(model.serial)-\(i)")
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    private func donkey(width w: CGFloat) -> some View {
        let target: CGFloat = {
            guard let c = model.chosen, model.stage != .choosing else { return drag }
            if model.stage == .done && model.right == false { return 0 }
            return (c == 0 ? -1 : 1) * w * 0.22
        }()
        let facing: CGFloat = model.chosen.map { $0 == 0 ? -1 : 1 } ?? (drag < -4 ? -1 : 1)
        return Asellus(facing: facing, trotting: model.stage == .trotting || abs(drag) > 4, mood: model.right, haul: model.haul)
            .scaleEffect(1.05)
            .offset(x: target)
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: model.stage)
            .frame(height: 170)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 8)
                .onChanged { v in
                    guard model.stage == .choosing, model.phase == .playing else { return }
                    drag = max(-w * 0.25, min(w * 0.25, v.translation.width))
                }
                .onEnded { v in
                    guard model.stage == .choosing else { drag = 0; return }
                    let dx = v.predictedEndTranslation.width
                    if abs(dx) > 50 { swipe(to: dx < 0 ? 0 : 1) } else { withAnimation(.spring()) { drag = 0 } }
                })
            .modifier(MarketShake(shakes: CGFloat(model.lastMiss)))
            .animation(.linear(duration: 0.4), value: model.lastMiss)
    }

    private func swipe(to i: Int) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            drag = 0
            model.choose(i)
        }
    }
}
