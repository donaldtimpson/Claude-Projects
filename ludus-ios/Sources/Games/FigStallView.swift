import SwiftUI

// MARK: - The Fig Stall (Market · Money)
//
// You run a fruit stall. A customer holds up an order; tap fruit from the crates into the bag
// (tap the bag to take the last one out), then GIVE it. From Gradus III you also ring up the
// total. Money is US cents (¢, as in Coin Count); from VII prices are dollars and cents.
//
// Ladder: I one fruit, 1–5, all pictures, 2 crates · II two fruits (or one, up to 8), pictures
// + numbers, 3 crates · III prices on the crates; pick the total of 3 (≤ 20¢) · IV the order in
// words ("half a dozen figs and three pears"), totals ≤ 50¢ · V budgets ("I have 23¢ — as many
// pears as I can!") + a patience bar (45 s) · VI a melon plus as many as the rest buys; 4 totals
// · VII dollar prices ($0.75), 4 totals · VIII+ dollar word orders and dollar budgets; patience
// eases from 40 s to a floor of 25 s.
// The goat eats a short bag; Granny pays in kisses.

struct FSFruit: Hashable {
    let id: String, emoji: String, one: String, many: String
    func name(_ n: Int) -> String { n == 1 ? one : many }
}

let fsFruits: [FSFruit] = [
    .init(id: "fig", emoji: "", one: "fig", many: "figs"),        // drawn (there's no fig emoji)
    .init(id: "apple", emoji: "🍎", one: "apple", many: "apples"),
    .init(id: "banana", emoji: "🍌", one: "banana", many: "bananas"),
    .init(id: "pear", emoji: "🍐", one: "pear", many: "pears"),
    .init(id: "orange", emoji: "🍊", one: "orange", many: "oranges"),
    .init(id: "lemon", emoji: "🍋", one: "lemon", many: "lemons"),
    .init(id: "peach", emoji: "🍑", one: "peach", many: "peaches"),
    .init(id: "strawberry", emoji: "🍓", one: "strawberry", many: "strawberries"),
    .init(id: "kiwi", emoji: "🥝", one: "kiwi", many: "kiwis"),
    .init(id: "melon", emoji: "🍉", one: "melon", many: "melons"),
]

private func fsFruit(_ id: String) -> FSFruit { fsFruits.first { $0.id == id } ?? fsFruits[1] }

private let fsWords = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"]

func fsMoney(_ cents: Int, dollars: Bool) -> String {
    dollars ? String(format: "$%d.%02d", cents / 100, cents % 100) : "\(cents)¢"
}

// MARK: Orders

struct FSOrder {
    enum Bubble: Equatable { case pictures, numbered, words(String), budget(String) }
    var kinds: [String]                 // fruit ids wanted, in display order
    var want: [String: Int]
    var bubble: Bubble
    var crates: [String]
    var prices: [String: Int] = [:]     // cents; empty = no prices shown
    var dollars = false
    var totalOptions: [Int] = []        // non-empty = a ring-up step after the bag
    var totalCorrect = 0
    var bagNote = ""                    // teaching line when the bag is wrong ("half a dozen = 6")
    var total: Int { kinds.reduce(0) { $0 + (prices[$1] ?? 0) * (want[$1] ?? 0) } }
    var totalExplain: String {
        kinds.map { "\(want[$0] ?? 0) × \(fsMoney(prices[$0] ?? 0, dollars: dollars))" }.joined(separator: " + ")
            + " = " + fsMoney(total, dollars: dollars)
    }
    func money(_ c: Int) -> String { fsMoney(c, dollars: dollars) }
}

private func fsPick(_ n: Int, except: Set<String> = []) -> [String] {
    Array(fsFruits.map(\.id).filter { !except.contains($0) }.shuffled().prefix(n))
}

private func fsCrates(_ kinds: [String], _ n: Int) -> [String] {
    (kinds + fsPick(max(0, n - kinds.count), except: Set(kinds))).shuffled()
}

/// Ring-up choices: the total plus the likeliest slips (one too many/few of a fruit, then near misses).
private func fsTotals(_ o: FSOrder, _ n: Int) -> ([Int], Int) {
    let t = o.total, step = o.dollars ? 25 : 1
    let likely = o.kinds.flatMap { k in [t - (o.prices[k] ?? 0), t + (o.prices[k] ?? 0)] }
    let near = [t + step, t - step, t + 2 * step, t - 2 * step, t + 4 * step]
    var opts = [t]
    for c in likely.shuffled() + near.shuffled() where c > 0 && !opts.contains(c) && opts.count < n { opts.append(c) }
    opts.shuffle()
    return (opts, opts.firstIndex(of: t) ?? 0)
}

/// A price on every crate (so the crates don't give the order away); melons always cost more.
private func fsPrices(_ crates: [String], dollars: Bool, maxCents: Int, fixed: [String: Int] = [:]) -> [String: Int] {
    var p = fixed
    for k in crates where p[k] == nil {
        if k == "melon" { p[k] = dollars ? [200, 250, 300].randomElement()! : Int.random(in: 5...9) }
        else { p[k] = dollars ? [25, 50, 75, 100, 125, 150, 200].filter { $0 <= maxCents }.randomElement()! : Int.random(in: 1...maxCents) }
    }
    return p
}

private func withTotals(_ o: FSOrder, _ n: Int) -> FSOrder {
    var o = o
    (o.totalOptions, o.totalCorrect) = fsTotals(o, n)
    return o
}

/// Choices in the ring-up at a level: 3, then 4 from VI.
private func fsChoices(_ level: Int) -> Int { level >= 6 ? 4 : 3 }

private func fsWordsOrder(_ level: Int, dollars: Bool, maxPrice: Int, maxTotal: Int, crates: Int) -> FSOrder {
    let specials: [(Int, String, String)] = [(12, "a dozen", "a dozen"), (6, "half a dozen", "half a dozen"), (2, "a pair of", "a pair")]
    for _ in 0..<400 {
        let kinds = fsPick(Bool.random() ? 2 : 1, except: ["melon"])
        var want: [String: Int] = [:], parts: [String] = [], note = ""
        let a = fsFruit(kinds[0])
        if Int.random(in: 0..<4) < 3 {
            let s = specials.randomElement()!
            want[a.id] = s.0; parts.append("\(s.1) \(a.many)"); note = "\(s.2) = \(s.0)"
        } else {
            let q = Int.random(in: 2...9); want[a.id] = q; parts.append("\(fsWords[q]) \(a.name(q))")
        }
        if kinds.count > 1 {
            let b = fsFruit(kinds[1]), q = Int.random(in: 1...5)
            want[b.id] = q; parts.append("\(fsWords[q]) \(b.name(q))")
        }
        var text = parts.joined(separator: " and ") + ", please!"
        text = text.prefix(1).uppercased() + text.dropFirst()
        let cs = fsCrates(kinds, crates)
        let o = FSOrder(kinds: kinds, want: want, bubble: .words(text), crates: cs,
                        prices: fsPrices(cs, dollars: dollars, maxCents: maxPrice), dollars: dollars, bagNote: note)
        if o.total <= maxTotal { return withTotals(o, fsChoices(level)) }
    }
    return fsPricedOrder(level, dollars: dollars)
}

private func fsPricedOrder(_ level: Int, dollars: Bool) -> FSOrder {
    for _ in 0..<400 {
        let kinds = fsPick(dollars || Bool.random() ? 2 : 1, except: ["melon"])
        var want: [String: Int] = [:]
        for k in kinds { want[k] = Int.random(in: 1...4) }
        let cs = fsCrates(kinds, 3)
        let o = FSOrder(kinds: kinds, want: want, bubble: .numbered, crates: cs,
                        prices: fsPrices(cs, dollars: dollars, maxCents: dollars ? 200 : 3), dollars: dollars)
        if o.total <= (dollars ? 1000 : 20) && o.total >= (dollars ? 0 : 3) { return withTotals(o, dollars ? 4 : fsChoices(level)) }
    }
    return FSOrder(kinds: ["apple"], want: ["apple": 2], bubble: .numbered, crates: ["apple", "pear", "fig"], prices: ["apple": 2])
}

/// "I have 23¢ — as many pears as I can!" (with `melon`: one melon first, then as many as the rest buys).
private func fsBudgetOrder(_ level: Int, dollars: Bool, melon: Bool) -> FSOrder {
    for _ in 0..<400 {
        let k = fsPick(1, except: ["melon"])[0], f = fsFruit(k)
        let p = dollars ? [50, 75, 100, 125].randomElement()! : Int.random(in: 2...(level >= 6 ? 6 : 5))
        let n = Int.random(in: 2...(melon ? 6 : (level >= 6 ? 10 : 8)))
        let m = melon ? (dollars ? [200, 250, 300].randomElement()! : Int.random(in: 5...9)) : 0
        let r = dollars ? 25 * Int.random(in: 0..<(p / 25)) : Int.random(in: 0..<p)
        let budget = m + p * n + r
        guard budget <= (dollars ? 1500 : (level >= 6 ? 45 : 30)) else { continue }
        let money = { (c: Int) in fsMoney(c, dollars: dollars) }
        var kinds = [k], want = [k: n], prices = [k: p]
        let text: String, note: String
        if melon {
            kinds = ["melon", k]; want["melon"] = 1; prices["melon"] = m
            text = "I have \(money(budget)). One melon, then as many \(f.many) as I can!"
            note = "\(money(budget)) − \(money(m)) melon = \(money(budget - m)) → \(n) \(f.name(n)) (\(money(n * p)))"
        } else {
            text = "I have \(money(budget)). As many \(f.many) as I can!"
            note = "\(n) \(f.name(n)) cost \(money(n * p)) — \(n + 1) would cost \(money((n + 1) * p))"
        }
        let cs = fsCrates(kinds, level >= 6 ? 4 : 3)
        return FSOrder(kinds: kinds, want: want, bubble: .budget(text), crates: cs,
                       prices: fsPrices(cs, dollars: dollars, maxCents: dollars ? 200 : 6, fixed: prices), dollars: dollars, bagNote: note)
    }
    return fsPricedOrder(level, dollars: dollars)
}

func fsMakeOrder(_ level: Int) -> FSOrder {
    switch level {
    case 1:
        let k = fsPick(2)
        return FSOrder(kinds: [k[0]], want: [k[0]: Int.random(in: 1...5)], bubble: .pictures, crates: k.shuffled())
    case 2:
        if Int.random(in: 0..<10) < 3 {
            let k = fsPick(1)
            return FSOrder(kinds: k, want: [k[0]: Int.random(in: 5...8)], bubble: .numbered, crates: fsCrates(k, 3))
        }
        let k = fsPick(2)
        return FSOrder(kinds: k, want: [k[0]: Int.random(in: 1...4), k[1]: Int.random(in: 1...4)], bubble: .numbered, crates: fsCrates(k, 3))
    case 3: return fsPricedOrder(3, dollars: false)
    case 4: return fsWordsOrder(4, dollars: false, maxPrice: 4, maxTotal: 50, crates: 3)
    case 5: return Bool.random() ? fsBudgetOrder(5, dollars: false, melon: false)
                                 : fsWordsOrder(5, dollars: false, maxPrice: 5, maxTotal: 60, crates: 3)
    case 6:
        switch Int.random(in: 0..<20) {
        case 0..<7: return fsBudgetOrder(6, dollars: false, melon: true)
        case 7..<13: return fsBudgetOrder(6, dollars: false, melon: false)
        default: return fsWordsOrder(6, dollars: false, maxPrice: 6, maxTotal: 80, crates: 4)
        }
    case 7: return fsPricedOrder(7, dollars: true)
    default:
        switch Int.random(in: 0..<10) {
        case 0..<4: return fsWordsOrder(level, dollars: true, maxPrice: 150, maxTotal: 1500, crates: 4)
        case 4..<7: return fsBudgetOrder(level, dollars: true, melon: false)
        default: return fsBudgetOrder(level, dollars: true, melon: true)
        }
    }
}

/// Seconds of patience per customer: none below V, 45 s at V, easing to a 25 s floor.
private func fsPatience(_ level: Int) -> Double { level < 5 ? 0 : max(25, 45 - Double(level - 5) * 5) }

#if DEBUG
/// Self-check: every generated order is solvable with exactly one right bag and one right total.
func fsSelfCheck() -> [String] {
    var errors: [String] = []
    for level in 1...10 {
        for _ in 0..<3000 {
            let o = fsMakeOrder(level)
            let n = o.want.values.reduce(0, +)
            if Set(o.kinds) != Set(o.want.keys) || o.want.values.contains(where: { $0 < 1 }) { errors.append("L\(level) bad want \(o.want)") }
            if !Set(o.kinds).isSubset(of: Set(o.crates)) { errors.append("L\(level) missing crate \(o.kinds) \(o.crates)") }
            if Set(o.crates).count != o.crates.count { errors.append("L\(level) dup crates") }
            if level == 1 && (n > 5 || o.crates.count != 2) { errors.append("L1 too big \(n)") }
            if level <= 2 && n > 8 { errors.append("L2 too big \(n)") }
            if level >= 3 && !o.crates.allSatisfy({ (o.prices[$0] ?? 0) > 0 }) { errors.append("L\(level) unpriced crate") }
            if !o.totalOptions.isEmpty {
                if o.totalOptions[o.totalCorrect] != o.total { errors.append("L\(level) total index") }
                if Set(o.totalOptions).count != o.totalOptions.count { errors.append("L\(level) dup totals \(o.totalOptions)") }
                if o.totalOptions.contains(where: { $0 <= 0 }) { errors.append("L\(level) non-positive total") }
                if o.totalOptions.count != (level >= 6 ? 4 : 3) { errors.append("L\(level) \(o.totalOptions.count) totals") }
                if level == 3 && o.total > 20 { errors.append("L3 total \(o.total)") }
                if level == 4 && o.total > 50 { errors.append("L4 total \(o.total)") }
            }
            if case .budget(let text) = o.bubble {
                // The bag is right iff it's the most of the cheap fruit the budget buys (after the melon).
                guard let b = Int(text.filter(\.isNumber)) else { errors.append("budget parse"); continue }
                let fixed = o.want["melon"].map { _ in o.prices["melon"]! } ?? 0
                let k = o.kinds.last!, p = o.prices[k]!
                if (b - fixed) / p != o.want[k]! { errors.append("L\(level) budget \(text) \(o.want)") }
                if o.total > b || o.total + p <= b { errors.append("L\(level) budget not tight \(text)") }
                if !o.totalOptions.isEmpty { errors.append("budget with ring-up") }
            } else if level >= 3 && o.totalOptions.isEmpty { errors.append("L\(level) no ring-up") }
        }
    }
    return errors
}
#endif

// MARK: Customers

private struct FSCustomer {
    let emoji: String, yay: String, boo: String
    var goat = false
    var granny = false
}

private let fsCustomers: [FSCustomer] = [
    .init(emoji: "👵", yay: "💋 Thank you, dear!", boo: "Oh dear, oh dear…", granny: true),
    .init(emoji: "🐐", yay: "Meh-eh-eh! Yum!", boo: "Not enough! CHOMP!", goat: true),
    .init(emoji: "👨‍🌾", yay: "Grazie, friend!", boo: "That's not my order!"),
    .init(emoji: "👧", yay: "Yay! Thank you!", boo: "Hmm… that's wrong!"),
    .init(emoji: "🐻", yay: "Yum yum yum!", boo: "Grrr… count again!"),
    .init(emoji: "🦊", yay: "Perfect! Ha-ha!", boo: "Sly try… but no!"),
    .init(emoji: "🐵", yay: "Ooh-ooh! Bananas… I mean, thanks!", boo: "Eek! Wrong bag!"),
    .init(emoji: "🤴", yay: "Splendid! Most royal!", boo: "Off with the bag!"),
]

// MARK: - Model

@MainActor
private final class FigStallModel: ArcadeModel {
    enum Stage { case bagging, ringing, done }
    enum Mood { case waiting, happy, sad, eaten }

    @Published var order = fsMakeOrder(1)
    @Published var customer = fsCustomers[0]
    @Published var serial = 0
    @Published var bag: [String] = []
    @Published var stage: Stage = .bagging
    @Published var mood: Mood = .waiting
    @Published var revealBag = false
    @Published var chosenTotal: Int?
    @Published var patience: Double = 0
    @Published var patienceMax: Double = 0
    @Published var bursts = 0
    @Published var sparks = 0
    private var timer: Timer?

    init() { super.init(key: GameID.figStall.rawValue) }

    override func perLevel(_ level: Int) -> Int { level <= 2 ? 6 : 5 }

    override func onBegin() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFTEST"] != nil {
            let errs = fsSelfCheck()
            marketLog("FIGSTALL SELFTEST: \(errs.isEmpty ? "OK" : "\(errs.count) errors") \(Array(Set(errs)).prefix(12))")
        }
        #endif
        newCustomer()
    }

    func count(_ id: String) -> Int { bag.filter { $0 == id }.count }

    private var bagRight: Bool {
        Set(bag).isSubset(of: Set(order.kinds)) && order.kinds.allSatisfy { count($0) == order.want[$0] }
    }

    func newCustomer() {
        var c = fsCustomers.randomElement()!
        while c.emoji == customer.emoji { c = fsCustomers.randomElement()! }
        customer = c
        order = fsMakeOrder(level)
        bag = []; stage = .bagging; mood = .waiting; revealBag = false; chosenTotal = nil
        serial += 1
        patienceMax = fsPatience(level); patience = patienceMax
        startClock()
    }

    func tapCrate(_ id: String) {
        guard phase == .playing, stage == .bagging else { return }
        if bag.count >= 20 {                    // a silly heap bursts the bag — start over, no penalty
            bag = []; bursts += 1; Haptics.error(); return
        }
        bag.append(id); Haptics.tap(0.4)
    }

    func tapBag() {
        guard phase == .playing, stage == .bagging, !bag.isEmpty else { return }
        bag.removeLast(); Haptics.light()
    }

    func give() {
        guard phase == .playing, stage == .bagging, !bag.isEmpty else { return }
        if bagRight {
            if order.totalOptions.isEmpty { resolve(true) } else { stage = .ringing; Haptics.tap(0.6) }
        } else {
            let short = order.kinds.contains { count($0) < (order.want[$0] ?? 0) }
            revealBag = true
            resolve(false, eaten: short && customer.goat)
        }
    }

    func chooseTotal(_ i: Int) {
        guard phase == .playing, stage == .ringing, order.totalOptions.indices.contains(i) else { return }
        chosenTotal = i
        resolve(i == order.totalCorrect)
    }

    private func timeOut() {
        guard stage != .done else { return }
        revealBag = stage == .bagging
        resolve(false)
    }

    private func resolve(_ right: Bool, eaten: Bool = false) {
        stopClock()
        stage = .done
        let linger = right ? 1.2 : 2.6        // a miss lingers so the right answer sinks in
        if right {
            mood = .happy; sparks += 1
            hit()
        } else {
            mood = eaten ? .eaten : .sad
            miss(delay: linger)
        }
        let s = serial
        DispatchQueue.main.asyncAfter(deadline: .now() + linger) { [weak self] in
            guard let self, self.serial == s, self.phase == .playing, !self.dying else { return }
            self.newCustomer()
        }
    }

    private func startClock() {
        timer?.invalidate(); timer = nil
        guard patienceMax > 0 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func stopClock() { timer?.invalidate(); timer = nil }

    private func tick() {
        guard phase == .playing, stage != .done else { stopClock(); return }
        patience = max(0, patience - 0.1)
        if patience <= 0 { timeOut() }
    }

    // One move per call, as a child would tap. The bot decides per customer whether it gets the
    // order right; a wrong customer gets a bag one short (or one over), or a wrong total.
    private var botSerial = -1, botGood = true, botErrBag = true, botDelta = 1
    override func botAct(correct: Bool) {
        guard stage != .done else { return }
        if botSerial != serial {
            botSerial = serial; botGood = correct
            botErrBag = order.totalOptions.isEmpty || Bool.random()
            botDelta = order.want.values.reduce(0, +) > 1 && Bool.random() ? -1 : 1
        }
        switch stage {
        case .bagging:
            var target = order.want
            if !botGood && botErrBag {
                let k = order.kinds[0]
                target[k, default: 0] += botDelta
            }
            for k in order.crates where count(k) < (target[k] ?? 0) { tapCrate(k); return }
            give()
        case .ringing:
            let wrong = order.totalOptions.indices.filter { $0 != order.totalCorrect }
            chooseTotal(botGood ? order.totalCorrect : wrong.randomElement()!)
        case .done: break
        }
    }
}

// MARK: - Views

/// A fruit picture — the emoji, or a drawn fig.
struct FSFruitIcon: View {
    let id: String
    var size: CGFloat = 40
    var body: some View {
        if id == "fig" {
            ZStack {
                Circle().fill(RadialGradient(colors: [Color(hex: 0xa86bb8), Color(hex: 0x5b2a6e)],
                                             center: UnitPoint(x: 0.35, y: 0.35), startRadius: 1, endRadius: size * 0.45))
                    .frame(width: size * 0.74, height: size * 0.74).offset(y: size * 0.1)
                Ellipse().fill(Color(hex: 0x6e3482)).frame(width: size * 0.34, height: size * 0.42).offset(y: -size * 0.16)
                Capsule().fill(Color(hex: 0x6a9a3a)).frame(width: size * 0.09, height: size * 0.2)
                    .rotationEffect(.degrees(15)).offset(x: size * 0.02, y: -size * 0.4)
            }
            .frame(width: size, height: size)
        } else {
            Text(fsFruit(id).emoji).font(.system(size: size * 0.86)).frame(width: size, height: size)
        }
    }
}

/// Fruit pictures in a wrapping grid.
private struct FSFruitPile: View {
    let ids: [String]
    var size: CGFloat
    var cols: Int = 6
    var body: some View {
        let rows = stride(from: 0, to: ids.count, by: cols).map { Array(ids[$0..<min($0 + cols, ids.count)]) }
        VStack(spacing: 2) {
            ForEach(rows.indices, id: \.self) { r in
                HStack(spacing: 2) { ForEach(rows[r].indices, id: \.self) { i in FSFruitIcon(id: rows[r][i], size: size) } }
            }
        }
    }
}

/// "3 ×" then three pictures — one line per fruit.
private struct FSNumberedOrder: View {
    let order: FSOrder
    var size: CGFloat = 30
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(order.kinds, id: \.self) { k in
                let n = order.want[k] ?? 0
                HStack(spacing: 8) {
                    Text("\(n)").font(luFont(28)).foregroundStyle(Color(hex: Lu.inkDark)).frame(minWidth: 30)
                    FSFruitPile(ids: Array(repeating: k, count: n), size: n > 6 ? size * 0.8 : size, cols: 6)
                }
            }
        }
    }
}

struct FigStallView: View {
    let onClose: () -> Void
    @StateObject private var model = FigStallModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.figStall.spec!, accent: Lu.tangerine, onClose: onClose) {
            VStack(spacing: 10) {
                Color.clear.frame(height: 52)
                customerRow
                patienceBar
                Spacer(minLength: 4)
                bagView
                Spacer(minLength: 4)
                bottom
            }
            .padding(.horizontal, 14).padding(.bottom, 8)
        }
    }

    // Customer + order bubble
    private var customerRow: some View {
        HStack(alignment: .center, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                Text(model.customer.emoji).font(.system(size: 78))
                    .scaleEffect(model.mood == .happy ? 1.15 : 1)
                    .rotationEffect(.degrees(model.mood == .happy ? -8 : 0))
                    .modifier(MarketShake(shakes: CGFloat(model.lastMiss)))
                    .animation(.spring(response: 0.3, dampingFraction: 0.4), value: model.mood)
                    .animation(.linear(duration: 0.45), value: model.lastMiss)
                if model.mood != .waiting {
                    Text(model.mood == .happy ? (model.customer.granny ? "😘" : "😍") : model.mood == .eaten ? "😋" : "😠")
                        .font(.system(size: 30)).offset(x: 8, y: -6)
                        .transition(.scale)
                }
                MarketSparks(trigger: model.sparks, glyphs: model.customer.granny ? ["💋", "✨"] : ["✨", "⭐️", "🪙"])
                    .frame(width: 1, height: 1).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: 104, height: 110)
            .id(model.serial)
            .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .opacity))

            MarketBubble {
                Group {
                    if model.mood != .waiting {
                        Text(model.mood == .happy ? model.customer.yay : model.customer.boo)
                            .font(luFont(20, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                    } else {
                        orderContent
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 64)
            }
            .padding(.bottom, 12)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: model.serial)
        .frame(minHeight: 120)
    }

    @ViewBuilder private var orderContent: some View {
        switch model.order.bubble {
        case .pictures:
            let k = model.order.kinds[0]
            FSFruitPile(ids: Array(repeating: k, count: model.order.want[k] ?? 0), size: 44, cols: 5)
        case .numbered:
            FSNumberedOrder(order: model.order)
        case .words(let t):
            Text(t).font(luFont(21, .heavy)).foregroundStyle(Color(hex: Lu.inkDark)).multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        case .budget(let t):
            HStack(spacing: 8) {
                Text("👛").font(.system(size: 34))
                Text(t).font(luFont(20, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var patienceBar: some View {
        GeometryReader { geo in
            let f = model.patienceMax > 0 ? model.patience / model.patienceMax : 0
            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: Lu.panel))
                Capsule().fill(Color(hex: f < 0.3 ? Lu.coral : Lu.mint))
                    .frame(width: max(0, geo.size.width * CGFloat(f)))
            }
        }
        .frame(height: 8)
        .opacity(model.patienceMax > 0 ? 1 : 0)
    }

    // The bag: tap it to take the last fruit back out.
    private var bagView: some View {
        let groups = model.bag.reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
        let big = model.bag.count > 10
        return Button(action: { model.tapBag() }) {
            ZStack(alignment: .top) {
                FSBagShape()
                    .fill(LinearGradient(colors: [Color(hex: 0xd9a86a), Color(hex: 0xa87440)], startPoint: .top, endPoint: .bottom))
                    .overlay(FSBagShape().stroke(Color(hex: 0x6e4a24), lineWidth: 3))
                VStack(spacing: 4) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(groups, id: \.self) { k in
                            let n = model.count(k)
                            VStack(spacing: 2) {
                                FSFruitPile(ids: Array(repeating: k, count: n), size: big ? 24 : 34, cols: big ? 6 : 4)
                                Text(model.order.prices[k].map { "\(n) × \(model.order.money($0))" } ?? "\(n)")
                                    .font(luFont(model.level >= 2 ? 16 : 13, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                                    .opacity(model.level >= 2 ? 1 : 0.6)
                            }
                        }
                    }
                    .padding(.top, 34)
                }
                if model.mood == .eaten {
                    Text("CHOMP!").font(luFont(34)).foregroundStyle(Color(hex: Lu.coral)).rotationEffect(.degrees(-12)).padding(.top, 60)
                }
            }
            .frame(maxWidth: 300).frame(height: 230)
            .scaleEffect(model.mood == .eaten ? 0.55 : 1)
            .rotationEffect(.degrees(model.mood == .eaten ? 14 : 0))
            .opacity(model.mood == .eaten ? 0.6 : 1)
            .scaleEffect(model.mood == .happy ? 0.9 : 1)
            .offset(x: model.mood == .happy ? -90 : 0, y: model.mood == .happy ? -60 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: model.mood)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: model.bag.count)
            .modifier(MarketShake(amount: 6, shakes: CGFloat(model.bursts)))
            .animation(.linear(duration: 0.4), value: model.bursts)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var bottom: some View {
        if model.revealBag {
            VStack(spacing: 8) {
                Text("NEEDED").font(luFont(13, .heavy)).tracking(2).foregroundStyle(Color(hex: Lu.inkDim))
                FSNumberedOrder(order: model.order, size: 28)
                    .padding(10).background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: Lu.mint)))
                if !model.order.bagNote.isEmpty {
                    Text(model.order.bagNote).font(luFont(17, .heavy)).foregroundStyle(Color(hex: Lu.gold))
                        .multilineTextAlignment(.center).minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 190)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        } else if model.stage == .ringing || (model.stage == .done && model.chosenTotal != nil) {
            ringUp
        } else {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    ForEach(model.order.crates, id: \.self) { k in crate(k) }
                }
                LudusButton(title: "Give 🤝", fill: [Lu.mint, 0x3f8f4a], shadow: 0x2a6a33, fullWidth: true) { model.give() }
                    .opacity(model.bag.isEmpty || model.stage != .bagging ? 0.45 : 1)
            }
        }
    }

    private func crate(_ k: String) -> some View {
        Button(action: { model.tapCrate(k) }) {
            VStack(spacing: 2) {
                FSFruitIcon(id: k, size: model.order.crates.count >= 4 ? 44 : 54)
                if let p = model.order.prices[k] {
                    Text(model.order.money(p)).font(luFont(17, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                        .padding(.horizontal, 7).padding(.vertical, 1)
                        .background(Capsule().fill(Color(hex: Lu.ink)))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 104)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [Color(hex: 0x9a6a3c), Color(hex: 0x6e4524)], startPoint: .top, endPoint: .bottom))
                    .overlay(VStack(spacing: 18) { ForEach(0..<3, id: \.self) { _ in Rectangle().fill(Color.black.opacity(0.12)).frame(height: 3) } })
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0x4a2e16), lineWidth: 3))
            )
        }
        .buttonStyle(.plain)
    }

    private var ringUp: some View {
        let o = model.order
        let done = model.stage == .done
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: o.totalOptions.count == 4 ? 2 : 3)
        return VStack(spacing: 10) {
            Text("HOW MUCH?").font(luFont(16, .heavy)).tracking(2).foregroundStyle(Color(hex: Lu.gold))
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(o.totalOptions.indices, id: \.self) { i in
                    let st: MarketChoiceState = !done ? .open : i == o.totalCorrect ? .right : i == model.chosenTotal ? .wrong : .faded
                    MarketChoiceButton(text: o.money(o.totalOptions[i]), state: st) { model.chooseTotal(i) }
                }
            }
            Text(o.totalExplain).font(luFont(17, .heavy)).foregroundStyle(Color(hex: Lu.ink))
                .minimumScaleFactor(0.6).lineLimit(1)
                .opacity(done && model.chosenTotal != o.totalCorrect ? 1 : 0)
        }
        .frame(minHeight: 190)
    }
}

/// A paper grocery bag with a folded, zig-zag top.
private struct FSBagShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let top = r.minY + 22
        p.move(to: CGPoint(x: r.minX + 10, y: top))
        let teeth = 8
        for i in 0...teeth {
            let x = r.minX + 10 + (r.width - 20) * CGFloat(i) / CGFloat(teeth)
            p.addLine(to: CGPoint(x: x, y: i % 2 == 0 ? top : top - 10))
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - 14))
        p.addQuadCurve(to: CGPoint(x: r.maxX - 14, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + 14, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - 14), control: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
