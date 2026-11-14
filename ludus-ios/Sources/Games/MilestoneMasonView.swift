import SwiftUI

// MARK: - Milestone Mason (Forum · History · Roman numerals)
//
// The Romans lined their roads with stone milestones, each carved with how many miles it was to
// Rome. You are the mason: a traveller tells you a number and you CARVE it, tapping stone letters
// (I V X L C D M) onto the blank milestone, then strike DONE. The stone shows what your carving is
// worth as you go (early on), so a child discovers that V is five and IV is "one before five".
// A right stone gets its letters painted red (the Romans really painted them) and the traveller
// cheers "Gratias!"; a wrong one shows the right numeral and how it adds up (X + IV = 10 + 4).
// A correct-but-long carving (IIII for 4) is gently sent back: "Shorter! Romans wrote IV".
//
// Difficulty runs on `d` (GameKit):
//   • what to carve — tier([1, 2, 3.4, 5, 6.8]): 1–3 (only I) → 4–9 (V, then IV/IX) → 10–39 (X)
//     → 40–100 (L, C) → years AD on a dedication stone (D, M: AD 79 Vesuvius … this year);
//   • help fades: pebbles to count (gone by ~3.5), the live "= 7" read-out (gone by ~6);
//   • from d≈4 the traveller is walking up the road — finish before he arrives (30 s → 12 s).

// MARK: Numerals

private let mmSymbols: [(Character, Int)] = [("I", 1), ("V", 5), ("X", 10), ("L", 50), ("C", 100), ("D", 500), ("M", 1000)]

/// The standard way to write n (1…3999).
func romanStandard(_ n: Int) -> String {
    let table: [(Int, String)] = [(1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"),
                                  (50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
    var v = n, s = ""
    for (val, sym) in table { while v >= val { s += sym; v -= val } }
    return s
}

/// What a carving is worth, read the Roman way (a smaller letter before a bigger one subtracts).
private func romanValue(_ s: [Character]) -> Int {
    let vals = s.compactMap { c in mmSymbols.first { $0.0 == c }?.1 }
    var total = 0
    for (i, v) in vals.enumerated() {
        if i + 1 < vals.count && v < vals[i + 1] { total -= v } else { total += v }
    }
    return total
}

/// The standard numeral split into its parts with their values: XIV → [("X",10), ("IV",4)].
private func romanParts(_ n: Int) -> [(String, Int)] {
    let table: [(Int, String)] = [(1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"),
                                  (50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
    var v = n, out: [(String, Int)] = []
    for (val, sym) in table { while v >= val { out.append((sym, val)); v -= val } }
    // Merge runs of the same part (X, X → XX 20) so the sum reads simply.
    var merged: [(String, Int)] = []
    for p in out {
        if let last = merged.last, last.0.first == p.0.first, p.0.count == 1, last.0.allSatisfy({ $0 == p.0.first }) {
            merged[merged.count - 1] = (last.0 + p.0, last.1 + p.1)
        } else { merged.append(p) }
    }
    return merged
}

// MARK: Orders

/// A year worth carving (all AD; checked against standard references).
private let mmYears: [(Int, String, String)] = [
    (79, "🌋", "Vesuvius buries Pompeii"),
    (80, "🏟️", "The Colosseum opens"),
    (117, "🦅", "The Roman Empire at its biggest"),
    (122, "🧱", "Hadrian's Wall is begun"),
    (476, "🏛️", "The last emperor of the West loses his throne"),
    (1066, "⚔️", "The Battle of Hastings"),
    (1215, "📜", "Magna Carta is sealed"),
    (1492, "⛵️", "Columbus crosses the Atlantic"),
    (1620, "🚢", "The Mayflower sails"),
    (1776, "🦅", "The Declaration of Independence"),
    (1903, "✈️", "The first airplane flight"),
    (1912, "🧊", "The Titanic sinks"),
    (1969, "🌕", "People walk on the Moon"),
    (2000, "🎆", "The whole world parties for the year 2000"),
]

private struct MMOrder {
    let n: Int
    let year: (String, String)?      // (emoji, what happened) for a year stone
    let dots: Bool                   // show pebbles to count
    let live: Bool                   // show the "= n" read-out while carving
    let limit: Double                // seconds before the traveller arrives (0 = no rush)
    var answer: String { romanStandard(n) }
}

// MARK: Model

@MainActor
private final class MasonModel: ArcadeModel {
    enum Stage: Equatable { case carving, right, wrong, hint }

    @Published var order = MMOrder(n: 1, year: nil, dots: true, live: true, limit: 0)
    @Published var carved: [Character] = []
    @Published var stage: Stage = .carving
    @Published var roundNo = 0
    @Published var strikes = 0                   // bumps on every chisel strike (mason swings)
    @Published var deadline: Date?
    @Published var symbolsShown = 1

    init() { super.init(key: GameID.milestone.rawValue) }

    override func onBegin() { next() }

    var value: Int { romanValue(carved) }

    func next() {
        order = makeOrder()
        carved = []
        stage = .carving
        roundNo += 1
        // Letters on the bench: everything this difficulty uses (never just the ones this answer needs).
        let rank = d < 2 ? 1 : d < 3.4 ? 2 : d < 5 ? 3 : d < 6.8 ? 5 : 7
        let need = order.answer.compactMap { c in mmSymbols.firstIndex { $0.0 == c } }.max() ?? 0
        symbolsShown = max(rank, need + 1)
        deadline = order.limit > 0 ? Date().addingTimeInterval(order.limit) : nil
        if order.limit > 0 {
            forumAfter(self, order.limit, round: { $0.roundNo }) { m in
                if m.stage == .carving || m.stage == .hint { m.timeUp() }
            }
        }
        sayOrder()
    }

    func sayOrder() {
        if let y = order.year { LibraryVoice.say("Carve the year \(order.n). \(y.1).") }
        else { LibraryVoice.say(order.n == 1 ? "Carve one mile!" : "Carve \(order.n) miles!") }
    }

    private func makeOrder() -> MMOrder {
        let k = tier([1, 2, 3.4, 5, 6.8])
        var n = 1
        var year: (String, String)?
        switch k {
        case 0: n = Int.random(in: 1...3)
        case 1:
            // 5–8 first (V and adding); 4 and 9 (one-before) join from d≈2.5.
            let pool = d < 2.5 ? Array(5...8) : Array(4...9)
            n = pool.randomElement()!
        case 2: n = Int.random(in: 10...rampInt(19, 39, from: 3.4, to: 5))
        case 3: n = Int.random(in: 40...rampInt(60, 100, from: 5, to: 6.5))
        default:
            if chance(0.5, from: 7.5, to: 10) {
                n = Int.random(in: 1000...2025)
                year = ("🏛️", "A cornerstone for a new building")
            } else if Double.random(in: 0..<1) < 0.12 {
                n = Calendar.current.component(.year, from: Date())
                year = ("🎂", "This year — now!")
            } else {
                let y = mmYears.randomElement()!
                n = y.0; year = (y.1, y.2)
            }
        }
        if n == order.n && k < 4 { n = n == 1 ? 2 : n - 1 }      // never the same number twice running
        let dots = n <= 10 && !chance(1, from: 2, to: 3.5)
        let live = !chance(1, from: 3.6, to: 6)
        let limit = d >= 4 ? ramp(30, 12, from: 4, to: 10) + Double(romanStandard(n).count) * 0.8 : 0
        return MMOrder(n: n, year: year, dots: dots, live: live, limit: limit)
    }

    // Input — taps and the bot both come through here.
    func carve(_ c: Character) {
        guard phase == .playing, stage == .carving || stage == .hint, carved.count < 16 else { return }
        stage = .carving
        carved.append(c)
        strikes += 1
        Sfx.play(.thud, volume: 0.7)
        Haptics.tap(0.55)
    }

    func undo() {
        guard phase == .playing, stage == .carving || stage == .hint, !carved.isEmpty else { return }
        stage = .carving
        carved.removeLast()
        Sfx.play(.whoosh, volume: 0.5)
        Haptics.light()
    }

    func done() {
        guard phase == .playing, stage == .carving || stage == .hint, !carved.isEmpty else { return }
        if String(carved) == order.answer {
            stage = .right
            deadline = nil
            hit(points: 1 + order.answer.count / 3)
            Sfx.play(.coin)
            LibraryVoice.say("Gratias!")
            forumAfter(self, 1.8, round: { $0.roundNo }) { $0.next() }
        } else if value == order.n {
            // Right amount, long way round (IIII for 4): no heart, just a nudge.
            stage = .hint
            Sfx.play(.tick)
            Haptics.light()
        } else {
            fail(reason: "Out of hearts!")
        }
    }

    private func timeUp() { fail(reason: "The traveller walked on!") }

    private func fail(reason: String) {
        stage = .wrong
        deadline = nil
        let last = miss(reason: reason, delay: 3.0)
        LibraryVoice.say("\(order.n) is \(order.answer.map(String.init).joined(separator: " "))")
        if !last { forumAfter(self, 3.2, round: { $0.roundNo }) { $0.next() } }
    }

    override func botAct(correct: Bool) {
        guard stage == .carving || stage == .hint else { return }
        // One tap per act, like a child: a slip is a wrong letter (fixed with undo next time) or,
        // once the stone is wrong, striking DONE anyway.
        let ans = Array(order.answer)
        let onTrack = carved.count <= ans.count && Array(ans.prefix(carved.count)) == carved
        let letters = mmSymbols.prefix(symbolsShown).map(\.0)
        if onTrack && carved.count < ans.count {
            carve(correct ? ans[carved.count] : (letters.filter { $0 != ans[carved.count] }.randomElement() ?? "I"))
        } else if onTrack {
            if correct { done() } else { carve(letters.randomElement() ?? "I"); done() }
        } else {
            if correct { undo() } else { done() }
        }
    }
}

// MARK: View

struct MilestoneMasonView: View {
    let onClose: () -> Void
    @StateObject private var model = MasonModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.milestone.spec!, accent: Lu.coral,
                    onClose: { LibraryVoice.stop(); onClose() },
                    backdrop: { MMRoadScene() }) {
            MMPlay(model: model)
        }
        .onDisappear { LibraryVoice.stop() }
    }
}

private struct MMPlay: View {
    @ObservedObject var model: MasonModel

    var body: some View {
        VStack(spacing: 6) {
            Color.clear.frame(height: 58)
            MMOrderBubble(model: model)
            GeometryReader { g in
                MMYard(model: model, size: g.size)
            }
            MMBench(model: model)
        }
        .padding(.horizontal, 14).padding(.bottom, 6)
    }
}

/// The traveller's request: the number (and pebbles to count early on), or a year and its event.
private struct MMOrderBubble: View {
    @ObservedObject var model: MasonModel

    var body: some View {
        let o = model.order
        ForumBubble(fill: 0xfdf6e3, tailX: 0.82) {
            HStack(spacing: 12) {
                if let y = o.year {
                    Text(y.0).font(.system(size: 40))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("CARVE THE YEAR").font(luFont(11, .heavy)).tracking(1.4).foregroundStyle(Color(hex: 0x8a6a3a))
                        Text("AD \(o.n)").font(luSerif(30, .black)).foregroundStyle(Color(hex: Lu.inkDark))
                        Text(y.1).font(luFont(14, .bold)).foregroundStyle(Color(hex: 0x5a4a3a))
                            .lineLimit(2).minimumScaleFactor(0.7)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HOW FAR TO ROME?").font(luFont(11, .heavy)).tracking(1.4).foregroundStyle(Color(hex: 0x8a6a3a))
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(o.n)").font(luSerif(40, .black)).foregroundStyle(Color(hex: Lu.inkDark))
                            Text(o.n == 1 ? "mile" : "miles").font(luFont(18, .heavy)).foregroundStyle(Color(hex: 0x5a4a3a))
                        }
                    }
                    if o.dots { pebbles(o.n) }
                }
                Spacer(minLength: 0)
                LibrarySpeakerButton(size: 44) { model.sayOrder() }
            }
        }
        .frame(minHeight: 84)
        .id(model.roundNo)
        .transition(.scale(scale: 0.8).combined(with: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: model.roundNo)
    }

    /// n pebbles in rows of five; each lights gold as the carving reaches it.
    private func pebbles(_ n: Int) -> some View {
        let lit = min(n, model.value)
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<((n + 4) / 5), id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<min(5, n - row * 5), id: \.self) { k in
                        let i = row * 5 + k
                        Circle()
                            .fill(Color(hex: i < lit ? Lu.gold : 0xb9ad98))
                            .overlay(Circle().stroke(Color(hex: 0x6a5a48), lineWidth: 1.5))
                            .frame(width: n <= 5 ? 22 : 16, height: n <= 5 ? 22 : 16)
                            .scaleEffect(i < lit ? 1.12 : 1)
                    }
                }
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: lit)
    }
}

/// The work yard: the mason, the milestone, and the traveller on the road.
private struct MMYard: View {
    @ObservedObject var model: MasonModel
    let size: CGSize
    @State private var swing = false
    @State private var shakes: CGFloat = 0

    var body: some View {
        let stoneH = min(size.height * 0.94, 330)
        let stoneW = min(stoneH * 0.6, size.width * 0.5)
        ZStack {
            // The traveller: walks up the road while there's a rush, otherwise waits by the stone.
            traveller
            MMStone(model: model, width: stoneW, height: stoneH)
                .modifier(ForumShake(amount: 8, shakes: shakes))
                .position(x: size.width * 0.5, y: size.height - stoneH / 2)
            // The mason with his mallet, left of the stone.
            ZStack(alignment: .topTrailing) {
                ForumPerson(mood: masonMood, hat: .cap, tunic: 0x6f8f4e, skin: 0xe6b48a, size: 140, beard: true, lookX: 1)
                MMMallet()
                    .rotationEffect(.degrees(swing ? 35 : -30), anchor: .bottomLeading)
                    .offset(x: 16, y: 54)
            }
            .position(x: size.width * 0.5 - stoneW / 2 - 34, y: size.height - 72)
        }
        .onChange(of: model.strikes) { _ in
            withAnimation(.easeIn(duration: 0.08)) { swing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { swing = false } }
        }
        .onChange(of: model.stage) { s in
            if s == .wrong || s == .hint { withAnimation(.linear(duration: 0.45)) { shakes += 1 } }
        }
    }

    private var masonMood: ForumPerson.Mood {
        switch model.stage {
        case .right: return .cheer
        case .wrong: return .oops
        case .hint: return .think
        case .carving: return .idle
        }
    }

    private var traveller: some View {
        let mood: ForumPerson.Mood = model.stage == .right ? .cheer : (model.stage == .wrong ? .oops : .talk)
        let near = CGPoint(x: size.width * 0.5 + min(size.height * 0.94, 330) * 0.3 + 40, y: size.height - 72)
        return TimelineView(.animation(minimumInterval: 1 / 20, paused: model.deadline == nil || model.phase != .playing)) { tl in
            let t: CGFloat = {
                guard let dl = model.deadline, model.order.limit > 0 else { return 1 }
                return CGFloat(1 - max(0, dl.timeIntervalSince(tl.date)) / model.order.limit)
            }()
            let far = CGPoint(x: size.width * 0.86, y: size.height * 0.08)
            let x = far.x + (near.x - far.x) * t, y = far.y + (near.y - far.y) * t
            let walking = model.deadline != nil
            let step = walking ? sin(tl.date.timeIntervalSinceReferenceDate * 9) : 0
            ForumPerson(mood: mood, hat: model.order.year == nil ? .hood : .laurel,
                        tunic: model.order.year == nil ? 0x4f7fb0 : 0xf2ead8, skin: 0xd9a27a, size: 140, lookX: -1)
                .scaleEffect(0.45 + 0.55 * t)
                .rotationEffect(.degrees(step * 4))
                .offset(y: CGFloat(abs(step)) * -3)
                .position(x: x, y: y)
                .opacity(model.phase == .playing ? 1 : 0)
        }
        .offset(y: model.stage == .right ? -10 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.4), value: model.stage)
    }
}

/// The milestone: a stone column on a plinth with ROMA … M·P around the carving (or ANNO …
/// DOMINI on a year stone). Letters are cut dark, then painted red when the stone is right.
private struct MMStone: View {
    @ObservedObject var model: MasonModel
    let width: CGFloat, height: CGFloat

    var body: some View {
        let o = model.order
        let showAnswer = model.stage == .wrong
        let text = showAnswer ? o.answer : String(model.carved)
        let painted = model.stage == .right || showAnswer
        let fontSize = min(width * 0.36, (width * 0.9) / CGFloat(max(3, text.count)) * 1.55)
        ZStack {
            // Plinth.
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Color(hex: 0xb7ae9c), Color(hex: 0x8e8574)], startPoint: .top, endPoint: .bottom))
                .frame(width: width * 1.18, height: height * 0.1)
                .offset(y: height * 0.45)
            // Column, shaded round.
            RoundedRectangle(cornerRadius: width * 0.16)
                .fill(LinearGradient(colors: [Color(hex: 0xa59d8c), Color(hex: 0xe9e2d2), Color(hex: 0xd6cdb9), Color(hex: 0x948b7a)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: width, height: height * 0.9)
                .offset(y: -height * 0.04)
            // Weathering speckles.
            ForEach(0..<14, id: \.self) { i in
                Circle().fill(Color(hex: 0x7d7566).opacity(0.25))
                    .frame(width: CGFloat(3 + (i * 7) % 5))
                    .offset(x: width * (CGFloat((i * 37) % 80) / 100 - 0.4), y: height * (CGFloat((i * 53) % 84) / 100 - 0.46))
            }
            VStack(spacing: height * 0.02) {
                Text(o.year == nil ? "ROMA" : "ANNO").font(luSerif(width * 0.17, .black)).tracking(3)
                    .foregroundStyle(Color(hex: 0x6a6153))
                Rectangle().fill(Color(hex: 0x8a8170)).frame(width: width * 0.7, height: 2)
                ZStack {
                    if text.isEmpty {
                        Text("?").font(luSerif(width * 0.3, .black)).foregroundStyle(Color(hex: 0x8a8170).opacity(0.5))
                    }
                    MMCarving(text: text, painted: painted, fontSize: fontSize)
                        .frame(width: width * 0.94)
                }
                .frame(height: height * 0.3)
                Rectangle().fill(Color(hex: 0x8a8170)).frame(width: width * 0.7, height: 2)
                Text(o.year == nil ? "M · P" : "DOMINI").font(luSerif(width * 0.13, .black)).tracking(2)
                    .foregroundStyle(Color(hex: 0x6a6153))
                readout.frame(height: height * 0.13)
            }
            .offset(y: -height * 0.03)
        }
        .frame(width: width * 1.2, height: height)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: model.stage)
    }

    /// Under the carving: what it's worth (early levels), a gentle hint, or how the answer adds up.
    @ViewBuilder private var readout: some View {
        let o = model.order
        switch model.stage {
        case .wrong:
            let parts = romanParts(o.n)
            Text(parts.count > 1 ? parts.map(\.0).joined(separator: "+") + " = " + parts.map { "\($0.1)" }.joined(separator: "+")
                                 : "\(parts.first?.0 ?? "") = \(o.n)")
                .font(luFont(width * 0.1, .heavy)).foregroundStyle(Color(hex: 0x8a2a1a))
                .lineLimit(1).minimumScaleFactor(0.4).padding(.horizontal, 6)
        case .hint:
            Text("Shorter! Romans wrote \(o.answer)").font(luFont(width * 0.085, .heavy))
                .foregroundStyle(Color(hex: 0x8a2a1a)).multilineTextAlignment(.center)
                .lineLimit(2).minimumScaleFactor(0.5).padding(.horizontal, 8)
        case .right:
            Text("✓ \(o.n)").font(luFont(width * 0.14, .heavy)).foregroundStyle(Color(hex: 0x3f7a3a))
        case .carving:
            if o.live && !model.carved.isEmpty {
                Text("= \(model.value)").font(luFont(width * 0.14, .heavy))
                    .foregroundStyle(Color(hex: model.value == o.n ? 0x3f7a3a : 0x5a5246))
            }
        }
    }
}

/// The cut letters: each pops in with a puff of chips; dark when cut, red when painted.
private struct MMCarving: View {
    let text: String
    let painted: Bool
    let fontSize: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, c in
                MMLetter(c: c, painted: painted, size: fontSize)
            }
        }
        .lineLimit(1)
    }
}

private struct MMLetter: View {
    let c: Character
    let painted: Bool
    let size: CGFloat
    @State private var cut = false

    var body: some View {
        ZStack {
            Text(String(c)).font(luSerif(size, .black)).foregroundStyle(Color.white.opacity(0.55)).offset(x: 1, y: 1.5)
            Text(String(c)).font(luSerif(size, .black))
                .foregroundStyle(Color(hex: painted ? 0xb3261e : 0x4a443a))
            // Chips flying off the chisel.
            ForEach(0..<5, id: \.self) { k in
                let a = Double(k) / 5 * 2 * .pi + 0.4
                Circle().fill(Color(hex: 0xd8d0bf)).frame(width: 4, height: 4)
                    .offset(x: cut ? CGFloat(cos(a)) * size * 0.6 : 0, y: cut ? CGFloat(sin(a)) * size * 0.6 : 0)
                    .opacity(cut ? 0 : 1)
            }
        }
        .scaleEffect(cut ? 1 : 1.6)
        .opacity(cut ? 1 : 0.2)
        .onAppear { withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) { cut = true } }
        .animation(.easeOut(duration: 0.4), value: painted)
    }
}

private struct MMMallet: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Capsule().fill(Color(hex: 0x7a4a26)).frame(width: 6, height: 34).offset(x: 2)
            RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0x9a6a3a)).frame(width: 26, height: 16).offset(x: -8, y: -30)
        }
        .frame(width: 30, height: 44, alignment: .bottomLeading)
    }
}

/// The mason's bench: stone letters to carve, undo, and the DONE strike.
private struct MMBench: View {
    @ObservedObject var model: MasonModel

    var body: some View {
        let syms = Array(mmSymbols.prefix(model.symbolsShown))
        let busy = model.stage == .right || model.stage == .wrong
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(syms, id: \.0) { s in
                    Button { model.carve(s.0) } label: {
                        VStack(spacing: 0) {
                            Text(String(s.0)).font(luSerif(syms.count > 5 ? 28 : 34, .black))
                                .foregroundStyle(Color(hex: 0x3a342a))
                            if model.order.live || model.d < 5 {
                                Text("\(s.1)").font(luFont(11, .heavy)).foregroundStyle(Color(hex: 0x6a6153))
                            }
                        }
                        .frame(maxWidth: syms.count <= 2 ? 96 : .infinity, minHeight: 64)
                        .background(MMStoneTile())
                    }
                    .buttonStyle(MMPress())
                }
            }
            HStack(spacing: 10) {
                Button { model.undo() } label: {
                    Image(systemName: "delete.left.fill").font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color(hex: Lu.ink))
                        .frame(width: 76, height: 54)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0x6a5240))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0x3a2a1a), lineWidth: 2)))
                }
                .buttonStyle(MMPress())
                .opacity(model.carved.isEmpty ? 0.45 : 1)
                Button { model.done() } label: {
                    HStack(spacing: 8) {
                        Text("🔨").font(.system(size: 24))
                        Text("Done!").font(luSerif(22, .black)).foregroundStyle(Color(hex: 0x3a2708))
                    }
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [Color(hex: Lu.gold), Color(hex: Lu.tangerine)], startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xb96b1e), lineWidth: 2)))
                }
                .buttonStyle(MMPress())
                .opacity(model.carved.isEmpty ? 0.5 : 1)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [Color(hex: 0x8a5a34), Color(hex: 0x6a4224)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: 0x4a2c16), lineWidth: 3))
                .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
        )
        .disabled(busy)
    }
}

private struct MMStoneTile: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(LinearGradient(colors: [Color(hex: 0xefe8d8), Color(hex: 0xc9bfa9)], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0x8a8170), lineWidth: 2))
            .shadow(color: .black.opacity(0.3), radius: 0, y: 3)
    }
}

private struct MMPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

/// The Via Appia at morning: sky, hills with cypresses, Rome on the horizon, a paved road.
private struct MMRoadScene: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let horizon = h * 0.36
            ZStack {
                LinearGradient(colors: [Color(hex: 0x6fb2e6), Color(hex: 0xbfe0f2), Color(hex: 0xf6dfb0)],
                               startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.4))
                Circle().fill(Color(hex: 0xfff3c4)).frame(width: w * 0.22).position(x: w * 0.18, y: h * 0.13)
                    .shadow(color: Color(hex: 0xffe08a), radius: 30)
                // Far hills.
                Ellipse().fill(Color(hex: 0x9cbf7a)).frame(width: w * 1.1, height: h * 0.16).position(x: w * 0.2, y: horizon + h * 0.02)
                Ellipse().fill(Color(hex: 0x8db46c)).frame(width: w * 1.0, height: h * 0.13).position(x: w * 0.95, y: horizon + h * 0.02)
                // Rome on the horizon: a dome, a temple, walls.
                ZStack {
                    Rectangle().fill(Color(hex: 0xd9c9a8)).frame(width: w * 0.3, height: h * 0.025).offset(y: h * 0.0)
                    ForumDome().fill(Color(hex: 0xe8dcc0)).frame(width: w * 0.08, height: h * 0.03).offset(x: -w * 0.06, y: -h * 0.025)
                    ForumTriangle().fill(Color(hex: 0xe8dcc0)).frame(width: w * 0.09, height: h * 0.018).offset(x: w * 0.06, y: -h * 0.035)
                    ForEach(0..<4, id: \.self) { i in
                        Rectangle().fill(Color(hex: 0xefe5cc)).frame(width: w * 0.008, height: h * 0.022)
                            .offset(x: w * (0.03 + 0.02 * Double(i)), y: -h * 0.015)
                    }
                }
                .position(x: w * 0.5, y: horizon - h * 0.005)
                // Fields.
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0x86b25e), Color(hex: 0x5f8f3e)], startPoint: .top, endPoint: .bottom))
                    .frame(height: h - horizon).position(x: w / 2, y: horizon + (h - horizon) / 2)
                // The road, paved in big stones, narrowing to Rome.
                MMRoad(horizon: horizon / h)
                    .fill(LinearGradient(colors: [Color(hex: 0xb8ae98), Color(hex: 0x8f8572)], startPoint: .top, endPoint: .bottom))
                MMRoadJoints(horizon: horizon / h).stroke(Color(hex: 0x6f6656).opacity(0.5), lineWidth: 1.5)
                // Cypresses along the road.
                ForEach(0..<6, id: \.self) { i in
                    let t = Double(i) / 6
                    let side: Double = i.isMultiple(of: 2) ? -1 : 1
                    let y = horizon + (h - horizon) * CGFloat(0.04 + t * t * 0.5)
                    let s = CGFloat(0.25 + t * 1.4)
                    Ellipse().fill(Color(hex: 0x2f5a2a))
                        .frame(width: 18 * s, height: 70 * s)
                        .position(x: w * 0.5 + CGFloat(side) * (w * 0.06 + w * 0.5 * CGFloat(t)), y: y - 30 * s)
                }
            }
        }
    }
}

private struct MMRoad: Shape {
    let horizon: CGFloat
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.midX - r.width * 0.015, y: r.height * horizon))
            p.addLine(to: CGPoint(x: r.midX + r.width * 0.015, y: r.height * horizon))
            p.addLine(to: CGPoint(x: r.midX + r.width * 0.5, y: r.maxY))
            p.addLine(to: CGPoint(x: r.midX - r.width * 0.5, y: r.maxY))
            p.closeSubpath()
        }
    }
}

/// Cross-joints between paving rows, closer together toward the horizon.
private struct MMRoadJoints: Shape {
    let horizon: CGFloat
    func path(in r: CGRect) -> Path {
        Path { p in
            let top = r.height * horizon
            for k in 1..<14 {
                let t = pow(CGFloat(k) / 14, 2)
                let y = top + (r.maxY - top) * t
                let half = r.width * (0.015 + 0.485 * t)
                p.move(to: CGPoint(x: r.midX - half, y: y))
                p.addLine(to: CGPoint(x: r.midX + half, y: y))
            }
        }
    }
}
