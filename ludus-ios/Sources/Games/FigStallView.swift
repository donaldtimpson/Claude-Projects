import SwiftUI

// MARK: - The Fig Stall (Market · Money) — making change
//
// You keep a fruit stall on a sunny market street. A customer buys fruit and puts their money on
// the counter; you give the CHANGE by tapping coins (and later bills) out of the till into their
// purse. A count-up strip does it the way real cashiers do: start at the price and count up to
// what they paid — "37… 38, 39, 40, 50!". Too much change and the customer frowns; every miss
// shows the change that was right.
//
// Difficulty (continuous, `d`): paid with a nickel (I) → a dime → a quarter → a dollar → two
// fruits (add them first) → $5 and $10 bills → $20 with three fruits. The count-up strip fades
// (d 3.2–5.5), then the value badges on the coins (5–7.5); from d≈4.6 customers tap their feet (a
// patience bar that tightens from 45 s to 20 s, running only once they've set their money down);
// from d≈7.5 the change must use the fewest coins and bills.

struct FSFruit: Hashable {
    let id: String, emoji: String, one: String, many: String
}

let fsFruits: [FSFruit] = [
    .init(id: "fig", emoji: "", one: "fig", many: "figs"),        // drawn (there's no fig emoji)
    .init(id: "apple", emoji: "🍎", one: "apple", many: "apples"),
    .init(id: "banana", emoji: "🍌", one: "banana", many: "bananas"),
    .init(id: "pear", emoji: "🍐", one: "pear", many: "pears"),
    .init(id: "orange", emoji: "🍊", one: "orange", many: "oranges"),
    .init(id: "lemon", emoji: "🍋", one: "lemon", many: "lemons"),
    .init(id: "peach", emoji: "🍑", one: "peach", many: "peaches"),
    .init(id: "grapes", emoji: "🍇", one: "bunch of grapes", many: "bunches of grapes"),
    .init(id: "melon", emoji: "🍉", one: "melon", many: "melons"),
]

private func fsFruit(_ id: String) -> FSFruit { fsFruits.first { $0.id == id } ?? fsFruits[1] }

// MARK: Sales

struct FSSale {
    var items: [(fruit: String, price: Int)]
    var paid: [USMoney]            // what the customer hands over
    var till: [USMoney]            // the compartments you can give change from
    var showTrack = true
    var showValues = true
    var fewest = false             // must give the fewest pieces
    var total: Int { items.reduce(0) { $0 + $1.price } }
    var paidSum: Int { paid.reduce(0) { $0 + $1.cents } }
    var change: Int { paidSum - total }
}

@MainActor
private func fsSale(_ m: ArcadeModel) -> FSSale {
    // Staggered so each help leaves on its own, never with a new coin or bill: the count-up strip
    // fades first (d 3.2–5.5), the coins' value badges later (5–7.5), fewest-pieces last (7.5–9.5).
    let values = !m.chance(1, from: 5, to: 7.5)
    let track = !m.chance(1, from: 3.2, to: 5.5)
    let fewest = m.chance(1, from: 7.5, to: 9.5)
    let pick = { (n: Int) in Array(fsFruits.map(\.id).shuffled().prefix(n)) }
    let coinsTill: [USMoney] = USMoney.coins
    switch m.tier([1, 2, 3, 4, 5.5, 6.5, 8], keep: 0.08) {
    case 0:
        let p = Int.random(in: max(1, 4 - m.rampInt(1, 3, to: 2)) ... 4)
        return FSSale(items: [(pick(1)[0], p)], paid: [.nickel], till: [.penny], showTrack: true, showValues: true)
    case 1:
        let p = Int.random(in: m.rampInt(5, 2, from: 2, to: 3)...9)
        return FSSale(items: [(pick(1)[0], p)], paid: [.dime], till: [.penny, .nickel], showTrack: track || m.d < 3, showValues: values || m.d < 3)
    case 2:
        let p = Int.random(in: m.rampInt(15, 5, from: 3, to: 4)...24)
        return FSSale(items: [(pick(1)[0], p)], paid: [.quarter], till: [.penny, .nickel, .dime], showTrack: track, showValues: values)
    case 3:
        let p = Int.random(in: m.rampInt(50, 10, from: 4, to: 5.5)...95)
        return FSSale(items: [(pick(1)[0], p)], paid: [.one], till: coinsTill, showTrack: track, showValues: values, fewest: fewest)
    case 4:
        let f = pick(2)
        let a = Int.random(in: 10...45), b = Int.random(in: 10...(95 - a))
        return FSSale(items: [(f[0], a), (f[1], b)], paid: [.one], till: coinsTill, showTrack: track, showValues: values, fewest: fewest)
    case 5:
        let bill: USMoney = m.d > 7.5 && Bool.random() ? .ten : .five
        let p = 5 * Int.random(in: 21...(bill == .five ? 95 : 190))
        return FSSale(items: [(pick(1)[0], p)], paid: [bill], till: [.penny, .nickel, .dime, .quarter, .one, .five],
                      showTrack: track, showValues: values, fewest: fewest)
    default:
        let f = pick(3)
        let ps = (0..<3).map { _ in 5 * Int.random(in: 15...m.rampInt(80, 120, from: 8, to: 10)) }
        return FSSale(items: zip(f, ps).map { ($0, $1) }, paid: [.twenty], till: [.penny, .nickel, .dime, .quarter, .one, .five, .ten],
                      showTrack: track, showValues: values, fewest: fewest)
    }
}

// MARK: Customers

private struct FSCustomer: Equatable {
    let face: String, tunic: UInt, yay: String
}

private let fsCustomers: [FSCustomer] = [
    .init(face: "👵", tunic: 0x7a6bc4, yay: "Thank you, dear!"),
    .init(face: "🐻", tunic: 0x3f8f6a, yay: "Yum yum! Thanks!"),
    .init(face: "🦊", tunic: 0xd0603a, yay: "Perfect change!"),
    .init(face: "🐵", tunic: 0xd9a33a, yay: "Ooh-ooh! Thanks!"),
    .init(face: "🐰", tunic: 0x5f8fd0, yay: "Hop-hop, hooray!"),
    .init(face: "🐸", tunic: 0xa64d79, yay: "Ribbit! Thank you!"),
    .init(face: "👴", tunic: 0x6d7f3a, yay: "Grazie, friend!"),
    .init(face: "🐼", tunic: 0xc4553f, yay: "Bamboo-tiful!"),
    .init(face: "👧", tunic: 0x3d79a6, yay: "Yay! Thank you!"),
    .init(face: "🦁", tunic: 0x8a4fb0, yay: "A roaring good job!"),
]

// MARK: - Model

@MainActor
private final class FigStallModel: ArcadeModel {
    enum Stage { case giving, done }
    enum Mood { case waiting, happy, cross }

    @Published var sale = FSSale(items: [("fig", 3)], paid: [.nickel], till: [.penny])
    @Published var customer = fsCustomers[0]
    @Published var given: [USMoney] = []
    @Published var stage: Stage = .giving
    @Published var mood: Mood = .waiting
    @Published var serial = 0
    @Published var reveal = false
    @Published var note = ""
    @Published var sparks = 0
    @Published var deadline: Date?
    @Published var patience: Double = 0

    init() { super.init(key: GameID.figStall.rawValue) }
    override func perLevel(_ level: Int) -> Int { level == 1 ? 4 : 5 }

    var givenSum: Int { given.reduce(0) { $0 + $1.cents } }
    var needsDone: Bool { !sale.showTrack || sale.fewest }

    override func onBegin() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil || ProcessInfo.processInfo.environment["LUDUS_SELFTEST"] != nil { selfTest() }
        #endif
        next()
    }

    func next() {
        var c = fsCustomers.randomElement()!
        while c == customer { c = fsCustomers.randomElement()! }
        customer = c
        sale = fsSale(self)
        given = []; stage = .giving; mood = .waiting; reveal = false; note = ""
        serial += 1
        patience = d < 4.6 ? 0 : ramp(45, 20, from: 4.6, to: 10)
        deadline = nil
        let s = serial
        if d < 3 {
            // Said exactly as the bubble shows it.
            LibraryVoice.say("\(order) Here's \(sale.paidSum) cents.")
        }
        // The customer's patience runs only once they've walked up and set their money down.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in self?.startClock(s) }
    }

    /// What the customer asks for, as the bubble shows it: "One fig, please!", "These, please!"
    var order: String {
        sale.items.count == 1 ? "One \(fsFruit(sale.items[0].fruit).one), please!" : "These, please!"
    }

    /// Starts the patience bar for sale `s` (it sits full until now).
    private func startClock(_ s: Int) {
        guard serial == s, stage == .giving, phase == .playing, patience > 0 else { return }
        deadline = Date().addingTimeInterval(patience)
        DispatchQueue.main.asyncAfter(deadline: .now() + patience) { [weak self] in
            guard let self, self.serial == s, self.stage == .giving, self.phase == .playing else { return }
            self.note = "Too slow! The change was \(usMoney(self.sale.change))."
            self.resolve(false)
        }
    }

    func give(_ k: USMoney) {
        guard phase == .playing, stage == .giving else { return }
        given.append(k)
        Sfx.play(.coin, volume: 0.7); Haptics.tap(0.45)
        if givenSum > sale.change {
            note = "Too much! The change is \(usMoney(sale.change))."
            resolve(false)
        } else if givenSum == sale.change && !needsDone {
            resolve(true)
        }
    }

    /// Tap the purse: take the last piece back.
    func takeBack() {
        guard phase == .playing, stage == .giving, !given.isEmpty else { return }
        given.removeLast(); Sfx.play(.tick); Haptics.light()
    }

    func done() {
        guard phase == .playing, stage == .giving else { return }
        if givenSum != sale.change {
            note = givenSum < sale.change ? "Not enough! The change is \(usMoney(sale.change))."
                                          : "Too much! The change is \(usMoney(sale.change))."
            resolve(false)
        } else if sale.fewest && given.count > usFewest(sale.change, from: sale.till).count {
            note = "Right amount — but use fewer coins!"
            resolve(false)
        } else {
            resolve(true)
        }
    }

    private func resolve(_ right: Bool) {
        stage = .done; deadline = nil
        if right {
            mood = .happy; sparks += 1
            Sfx.play(.sparkle, volume: 0.5)
            hit()
        } else {
            mood = .cross; reveal = true
            miss(delay: 2.8)
        }
        let s = serial
        DispatchQueue.main.asyncAfter(deadline: .now() + (right ? 1.3 : 3.0)) { [weak self] in
            guard let self, self.serial == s, self.phase == .playing, !self.dying else { return }
            self.next()
        }
    }

    private var botSerial = -1, botGood = true
    override func botAct(correct: Bool) {
        guard stage == .giving else { return }
        if botSerial != serial { botSerial = serial; botGood = correct }
        let left = sale.change - givenSum
        if left == 0 { done(); return }
        if !botGood {
            if let big = sale.till.first(where: { $0.cents > left }) { give(big) } else { done() }
            return
        }
        give(usFewest(left, from: sale.till).first!)
    }

    #if DEBUG
    private func selfTest() {
        var errs: [String] = []
        marketSweep(self) {
            let s = fsSale(self)
            if s.change <= 0 { errs.append("change \(s.change) paid \(s.paidSum) total \(s.total)") }
            if s.items.contains(where: { $0.price <= 0 }) { errs.append("price") }
            if s.till.allSatisfy({ $0.cents > s.change }) { errs.append("till can't make \(s.change)") }
        }
        marketLog("FIGSTALL SELFTEST: \(errs.isEmpty ? "OK" : "\(errs.count) errors \(Array(Set(errs)).prefix(8))")")
    }
    #endif
}

// MARK: - Scene

/// A sunny market street: sky, terracotta roofs and columns, and the stall's striped awning.
private struct FSStreet: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Color(hex: 0x7cc3ea), Color(hex: 0xcfe9f2)], startPoint: .top, endPoint: .bottom)
                MarketCloud(w: 130).position(x: w * 0.2, y: h * 0.16)
                MarketCloud(w: 90).position(x: w * 0.8, y: h * 0.11)
                // Houses across the street
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<5, id: \.self) { i in
                        VStack(spacing: 0) {
                            FSRoof().fill(Color(hex: 0xb5532e)).frame(height: 26)
                            Rectangle().fill(Color(hex: [0xf1d9a8, 0xe8c48e, 0xf4e2bd, 0xdcb684, 0xefd09e][i]))
                                .overlay(
                                    HStack(spacing: 14) {
                                        ForEach(0..<2, id: \.self) { _ in
                                            RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0x6b4a2e).opacity(0.7)).frame(width: 14, height: 20)
                                        }
                                    }.padding(.top, 12), alignment: .top)
                        }
                        .frame(width: w / 5, height: CGFloat([110, 140, 96, 130, 116][i]))
                    }
                }
                .frame(width: w, height: h * 0.5, alignment: .bottom)
                // The street
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0xc9b08a), Color(hex: 0xa88d68)], startPoint: .top, endPoint: .bottom))
                    .frame(height: h * 0.5).offset(y: h * 0.5)
                // Awning
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { i in
                            Rectangle().fill(Color(hex: i % 2 == 0 ? 0xd9473a : 0xfaf1dc))
                        }
                    }
                    .frame(height: 70)
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { i in
                            FSScallop().fill(Color(hex: i % 2 == 0 ? 0xd9473a : 0xfaf1dc))
                        }
                    }
                    .frame(height: 18)
                }
                .frame(width: w)
                .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
            }
        }
    }
}

private struct FSRoof: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX - 4, y: r.maxY)); p.addLine(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX + 4, y: r.maxY)); p.closeSubpath()
        return p
    }
}

private struct FSScallop: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY * 2))
        return p
    }
}

// MARK: - Pieces

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

/// The customer: a face over a tunic, arms resting on the counter.
private struct FSCustomerView: View {
    let c: FSCustomer
    let mood: FigStallModel.Mood
    @State private var bob = false
    var body: some View {
        ZStack {
            // Tunic + arms
            FSTunic().fill(LinearGradient(colors: [luShade(c.tunic, 25), luShade(c.tunic, -30)], startPoint: .top, endPoint: .bottom))
                .frame(width: 120, height: 90).offset(y: 52)
            Capsule().fill(Color(hex: 0xdcb48c)).frame(width: 66, height: 8).offset(y: 44)       // the belt
            Text(c.face).font(.system(size: 84))
                .offset(y: -18 + (bob ? -3 : 0))
                .rotationEffect(.degrees(mood == .happy ? -8 : 0))
            if mood != .waiting {
                Text(mood == .happy ? "😍" : "😠").font(.system(size: 30)).offset(x: 46, y: -54)
                    .transition(.scale)
            }
        }
        .frame(width: 130, height: 150)
        .modifier(MarketShake(shakes: mood == .cross ? 1 : 0))
        .animation(.spring(response: 0.3, dampingFraction: 0.45), value: mood)
        .onAppear { withAnimation(.easeInOut(duration: 1.1).repeatForever()) { bob = true } }
    }
}

private struct FSTunic: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX - r.width * 0.2, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX + r.width * 0.2, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.35), control: CGPoint(x: r.maxX - 6, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - 8, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + 8, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.35))
        p.addQuadCurve(to: CGPoint(x: r.midX - r.width * 0.2, y: r.minY), control: CGPoint(x: r.minX + 6, y: r.minY))
        p.closeSubpath()
        return p
    }
}

/// A leather purse, open: the change you give lands in it.
private struct FSPurse: View {
    let given: [USMoney]
    let showValues: Bool
    var body: some View {
        ZStack(alignment: .top) {
            FSPurseShape().fill(LinearGradient(colors: [Color(hex: 0x9a5b2e), Color(hex: 0x6a3a18)], startPoint: .top, endPoint: .bottom))
                .overlay(FSPurseShape().stroke(Color(hex: 0x3f210c), lineWidth: 3))
            Ellipse().fill(Color(hex: 0x2c160a)).frame(height: 22).padding(.horizontal, 14).offset(y: 2)
            // The gold kiss-lock frame, sprung open
            HStack(spacing: 0) {
                FSClasp().stroke(Color(hex: Lu.gold), style: StrokeStyle(lineWidth: 4, lineCap: .round)).frame(width: 60, height: 20)
                    .rotationEffect(.degrees(-14), anchor: .bottomTrailing)
                Spacer()
                FSClasp().stroke(Color(hex: Lu.gold), style: StrokeStyle(lineWidth: 4, lineCap: .round)).frame(width: 60, height: 20)
                    .scaleEffect(x: -1).rotationEffect(.degrees(14), anchor: .bottomLeading)
            }
            .padding(.horizontal, 8).offset(y: -10)
            if given.isEmpty {
                Text("CHANGE").font(luFont(13, .heavy)).tracking(2).foregroundStyle(Color(hex: 0xf3d9b0).opacity(0.7))
                    .offset(y: 44)
            }
            // Coins piling up
            // Bills three to a row and coins six, so a fistful of change stays inside the purse.
            let rows: [[Int]] = {
                var out: [[Int]] = []
                for bills in [true, false] {
                    let idx = given.indices.filter { given[$0].isBill == bills }
                    let cols = bills ? 3 : 6
                    for r in stride(from: 0, to: idx.count, by: cols) { out.append(Array(idx[r..<min(idx.count, r + cols)])) }
                }
                return out
            }()
            VStack(spacing: -10) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: -8) {
                        ForEach(row, id: \.self) { i in
                            USMoneyView(kind: given[i], size: given[i].isBill ? 22 : 34, showValue: showValues)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
            }
            .offset(y: -14)
        }
        .frame(width: 150, height: 84)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: given.count)
    }
}

/// Half of a purse's clasp: an arc ending in a little ball.
private struct FSClasp: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.minX + r.width * 0.2, y: r.minY))
        p.addEllipse(in: CGRect(x: r.maxX - 5, y: r.maxY - 12, width: 9, height: 9))
        return p
    }
}

private struct FSPurseShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + 6, y: r.minY + 10))
        p.addLine(to: CGPoint(x: r.maxX - 6, y: r.minY + 10))
        p.addQuadCurve(to: CGPoint(x: r.maxX - 22, y: r.maxY), control: CGPoint(x: r.maxX + 6, y: r.maxY - 6))
        p.addLine(to: CGPoint(x: r.minX + 22, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX + 6, y: r.minY + 10), control: CGPoint(x: r.minX - 6, y: r.maxY - 6))
        p.closeSubpath()
        return p
    }
}

// MARK: - View

struct FigStallView: View {
    let onClose: () -> Void
    @StateObject private var model = FigStallModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.figStall.spec!, accent: Lu.tangerine,
                    onClose: { LibraryVoice.stop(); onClose() },
                    backdrop: { FSStreet() }) {
            FSPlay(model: model)
        }
        .onDisappear { LibraryVoice.stop() }
    }
}

private struct FSPlay: View {
    @ObservedObject var model: FigStallModel
    private var s: FSSale { model.sale }

    var body: some View {
        VStack(spacing: 6) {
            Color.clear.frame(height: 96)
            // Spare height goes up here (sky and houses), so the stall stays in one piece
            // right above the till instead of a gap opening between them.
            Spacer(minLength: 0)
            patienceBar
            customerRow
            counter
            track
            Color.clear.frame(height: 10)
            Text("THE TILL — tap to give change").font(luFont(12, .heavy)).tracking(1)
                .foregroundStyle(Color(hex: 0x4e2e15).opacity(0.8))
            till
            if model.needsDone {
                let ready = model.stage == .giving
                LudusButton(title: "Give change 🤝",
                            fill: ready ? [Lu.mint, 0x3f8f4a] : [Lu.silver, 0xa79f8b],
                            shadow: ready ? 0x2a6a33 : 0x6f6857, fullWidth: true) { model.done() }
                    .opacity(model.given.isEmpty ? 0.6 : 1)
                    .disabled(model.given.isEmpty)
            }
        }
        .padding(.horizontal, 12).padding(.bottom, 6)
    }

    @ViewBuilder private var patienceBar: some View {
        TimelineView(.animation(minimumInterval: 0.1, paused: model.deadline == nil || model.phase != .playing)) { tl in
            // Full until the customer has settled; then it drains.
            let left = model.deadline.map { max(0, $0.timeIntervalSince(tl.date)) } ?? model.patience
            let f = model.patience > 0 ? CGFloat(left / model.patience) : 0
            HStack(spacing: 6) {
                Text("⏳").font(.system(size: 14))
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.black.opacity(0.25))
                        Capsule().fill(Color(hex: f < 0.3 ? Lu.coral : Lu.mint)).frame(width: max(0, g.size.width * f))
                    }
                }
                .frame(height: 8)
            }
        }
        .frame(height: 14)
        .opacity(model.patience > 0 && model.stage == .giving ? 1 : 0)
    }

    private var customerRow: some View {
        HStack(alignment: .bottom, spacing: 4) {
            FSCustomerView(c: model.customer, mood: model.mood)
                .id(model.serial)
                .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .opacity))
                .overlay(MarketSparks(trigger: model.sparks, glyphs: ["✨", "⭐️", "🪙"]))
            MarketBubble(fill: 0xfdf6e3) {
                VStack(alignment: .leading, spacing: 6) {
                    if model.mood == .happy {
                        Text(model.customer.yay).font(luFont(20, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                    } else if model.reveal {
                        Text(model.note).font(luFont(18, .heavy)).foregroundStyle(Color(hex: 0xa33a24))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(model.order)
                            .font(luFont(17, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                        HStack(spacing: 4) {
                            Text("Here's").font(luFont(17, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                            Text(usMoney(s.paidSum)).font(luFont(22)).foregroundStyle(Color(hex: 0x2f7a3a))
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            }
            .padding(.bottom, 60)
        }
        .padding(.bottom, -14)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: model.serial)
    }

    /// The counter: the fruit with price tags, their open purse (the change goes in), and the
    /// money they paid.
    private var counter: some View {
        HStack(alignment: .center, spacing: 6) {
            VStack(spacing: 4) {
                ForEach(Array(s.items.enumerated()), id: \.offset) { _, it in
                    HStack(spacing: 2) {
                        FSFruitIcon(id: it.fruit, size: s.items.count > 1 ? 30 : 46)
                        Text(usMoney(it.price)).font(luFont(s.items.count > 1 ? 14 : 18, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                            .padding(.horizontal, 5)
                            .background(Capsule().fill(Color(hex: 0xfdf3d7)))
                            .lineLimit(1).fixedSize()
                    }
                }
            }
            .frame(minWidth: 84)
            Button(action: { model.takeBack() }) {
                FSPurse(given: model.given, showValues: s.showValues)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            VStack(spacing: 2) {
                Text("PAID").font(luFont(11, .heavy)).tracking(1.5).foregroundStyle(Color(hex: 0xfdf3d7))
                ForEach(Array(s.paid.enumerated()), id: \.offset) { _, k in USMoneyView(kind: k, size: k.isBill ? 34 : 50, showValue: true) }
            }
            .frame(minWidth: 70)
        }
        .padding(.horizontal, 10).padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [Color(hex: 0xb07a46), Color(hex: 0x7a4b25)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0x4e2e15), lineWidth: 3))
                .shadow(color: .black.opacity(0.3), radius: 5, y: 3)
        )
    }

    /// Count up from the price to what they paid.
    private var track: some View {
        let steps: [Int] = model.given.indices.map { i in s.total + model.given[0...i].reduce(0) { $0 + $1.cents } }
        return VStack(spacing: 4) {
            if s.showTrack || model.reveal {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        chip(usMoney(s.total), Lu.ink, Lu.inkDark)
                        ForEach(Array(steps.enumerated()), id: \.offset) { _, v in
                            Text("→").font(luFont(14)).foregroundStyle(Color(hex: Lu.inkDark).opacity(0.6))
                            chip(usMoney(v), v > s.paidSum ? Lu.coral : (v == s.paidSum ? Lu.mint : 0xfdf3d7), Lu.inkDark)
                        }
                        if steps.last != s.paidSum {
                            Text("… →").font(luFont(14)).foregroundStyle(Color(hex: Lu.inkDark).opacity(0.6))
                            chip(usMoney(s.paidSum), Lu.gold, Lu.inkDark).opacity(0.75)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                if model.reveal {
                    HStack(spacing: 4) {
                        Text("Change:").font(luFont(15, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                        // One piece per kind with its count, so $17.35 in change still fits.
                        let f = usFewest(s.change, from: s.till)
                        ForEach(s.till.sorted(by: >).filter { f.contains($0) }, id: \.self) { k in
                            let n = f.filter { $0 == k }.count
                            USMoneyView(kind: k, size: k.isBill ? 24 : 32, showValue: true)
                            if n > 1 { Text("×\(n)").font(luFont(15, .heavy)).foregroundStyle(Color(hex: Lu.inkDark)) }
                        }
                        Text("= \(usMoney(s.change))").font(luFont(17)).foregroundStyle(Color(hex: 0x2f7a3a))
                    }
                    .lineLimit(1).minimumScaleFactor(0.5)
                }
            } else {
                Text(s.items.count > 1 ? "Add it up, then count up to \(usMoney(s.paidSum))!" : "Count up from \(usMoney(s.total)) to \(usMoney(s.paidSum))!")
                    .font(luFont(16, .heavy)).foregroundStyle(Color(hex: Lu.inkDark)).opacity(0.75)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.6)))
        .padding(.leading, 0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: model.given.count)
    }

    private func chip(_ t: String, _ bg: UInt, _ fg: UInt) -> some View {
        Text(t).font(luFont(model.d < 4 ? 24 : 18, .heavy)).foregroundStyle(Color(hex: fg)).monospacedDigit()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(Color(hex: bg)))
    }

    /// The till: a drawer of compartments; tap one to give that coin or bill.
    private var till: some View {
        let bills = s.till.filter(\.isBill), coins = s.till.filter { !$0.isBill }
        return VStack(spacing: 8) {
            if !bills.isEmpty {
                HStack(spacing: 6) {
                    ForEach(bills, id: \.self) { k in compartment(k) }
                }
            }
            HStack(spacing: 6) {
                ForEach(coins, id: \.self) { k in compartment(k) }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [Color(hex: 0x5a3519), Color(hex: 0x3e230f)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xc9a46a), lineWidth: 3))
                .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
        )
    }

    private func compartment(_ k: USMoney) -> some View {
        Button(action: { model.give(k) }) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    USMoneyView(kind: k, size: k.isBill ? 36 : 64, showValue: false)
                        .offset(x: k.isBill ? CGFloat(i) * 2 : 0, y: CGFloat(2 - i) * -3).opacity(0.85)
                }
                USMoneyView(kind: k, size: k.isBill ? 36 : 64, showValue: s.showValues)
            }
            .frame(maxWidth: .infinity, minHeight: k.isBill ? 54 : 80)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x2a170a)))
        }
        .buttonStyle(FSPressStyle())
        .disabled(model.stage != .giving)
    }
}

private struct FSPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
