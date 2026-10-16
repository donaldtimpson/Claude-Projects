import SwiftUI

// MARK: - Porcus the Piggy Bank (Market · Money)
//
// Porcus the talking piggy bank helps you save. Drag (or tap) each day's coin into him — he
// gets fatter as he fills — and answer his money questions; every right answer puts a prize on
// the shelf. Every question has one checkable answer (no "would you rather").
//
// Ladder: I a prize costs 3–5 coins; 1 coin a day — drag each in, count up, tap BUY (buying
// too early is the only slip) · II temptations, 1 coin a day: "Buy the 🍭 and still get the 🪁
// by Day 7?" YES/NO, all within 10 · III needs vs wants (school shoes = need, toy dinosaur =
// want) + temptations at 2 coins a day, within 20 · IV planning: "3 a week, the bike costs 18 —
// how many weeks?" (exact) · V planning with savings and a remainder; save/give/spend jars by
// halves · VI jars by percent (50/40/10 of 10–100) · VII interest: 10% a week, one week, 4
// choices · VIII+ two weeks of interest (100 → 110 → 121), 5/20/25% rates, "now or later?".

struct PItem: Hashable { let emoji: String, name: String }

private let pPrizes: [PItem] = [
    .init(emoji: "🪁", name: "kite"), .init(emoji: "⚽️", name: "ball"), .init(emoji: "🧸", name: "teddy"),
    .init(emoji: "🛹", name: "skateboard"), .init(emoji: "🚲", name: "bike"), .init(emoji: "🎮", name: "game"),
    .init(emoji: "🎨", name: "paint set"), .init(emoji: "🎸", name: "guitar"), .init(emoji: "🔭", name: "telescope"),
    .init(emoji: "🛼", name: "roller skates"),
]
private let pTreats: [PItem] = [
    .init(emoji: "🍭", name: "lollipop"), .init(emoji: "🍦", name: "ice cream"), .init(emoji: "🧁", name: "cupcake"),
    .init(emoji: "🎈", name: "balloon"), .init(emoji: "🍬", name: "candy"), .init(emoji: "🥨", name: "pretzel"),
]
/// Needs and wants — only clear-cut cases a child would agree on.
let pNeeds: [PItem] = [
    .init(emoji: "👟", name: "Shoes for school"), .init(emoji: "🧥", name: "Warm winter coat"),
    .init(emoji: "🪥", name: "Toothbrush"), .init(emoji: "💊", name: "Medicine when sick"),
    .init(emoji: "🍞", name: "Bread for dinner"), .init(emoji: "🥛", name: "Milk for breakfast"),
    .init(emoji: "🧼", name: "Soap"), .init(emoji: "✏️", name: "Pencils for school"),
    .init(emoji: "👓", name: "Glasses to see"), .init(emoji: "💧", name: "Drinking water"),
    .init(emoji: "🩹", name: "Bandage for a cut"), .init(emoji: "🥦", name: "Vegetables for dinner"),
]
let pWants: [PItem] = [
    .init(emoji: "🦖", name: "Toy dinosaur"), .init(emoji: "🍭", name: "Lollipop"), .init(emoji: "🎮", name: "Video game"),
    .init(emoji: "🪁", name: "Kite"), .init(emoji: "🎈", name: "Balloon"), .init(emoji: "🍦", name: "Ice cream"),
    .init(emoji: "🛹", name: "Skateboard"), .init(emoji: "🪀", name: "Yo-yo"), .init(emoji: "🧁", name: "Cupcake"),
    .init(emoji: "🎸", name: "Toy guitar"), .init(emoji: "🎟️", name: "Movie ticket"), .init(emoji: "🃏", name: "Trading cards"),
]

// MARK: Rounds

struct PRound {
    enum Kind { case fill, tempt, sort, choice }
    var kind: Kind
    var prize: PItem
    var cost = 0                  // prize price (fill / tempt)
    var startCoins = 0            // in Porcus when the round opens
    var feed = 0                  // coins to drag in before the question
    var perDay = 1                // tempt: coins a day
    var day = 1                   // tempt: today (1…6); the week ends on Day 7
    var treat: PItem?
    var treatCost = 0
    var prompt = ""
    var options: [String] = []
    var correct = 0
    var explain = ""              // shown on a miss
    var shelf = ""                // what a right answer puts on the shelf
}

private func plural(_ n: Int, _ one: String, _ many: String) -> String { "\(n) \(n == 1 ? one : many)" }

/// The answer plus distinct, positive distractors (likeliest first), shuffled.
private func pOptions(_ ans: Int, _ cands: [Int], _ n: Int, _ fmt: (Int) -> String) -> ([String], Int) {
    var nums = [ans]
    for c in cands where c > 0 && !nums.contains(c) && nums.count < n { nums.append(c) }
    var k = 1
    while nums.count < n { if !nums.contains(ans + k) { nums.append(ans + k) }; k += 1 }
    nums.shuffle()
    return (nums.map(fmt), nums.firstIndex(of: ans)!)
}

private func pChoices(_ level: Int) -> Int { level >= 7 ? 4 : 3 }

private func pFill() -> PRound {
    let c = Int.random(in: 3...5)
    return PRound(kind: .fill, prize: pPrizes.randomElement()!, cost: c, feed: c, shelf: "")
}

/// "Buy the treat and still get the prize by Day 7?" — balanced YES/NO, and the prize is always
/// reachable if you skip the treat (so NO only ever means "the treat costs the prize").
private func pTempt(perDay: Int) -> PRound {
    let wantYes = Bool.random()
    for _ in 0..<2000 {
        let d = Int.random(in: 1...6), r = 7 - d
        let k = perDay == 1 ? Int.random(in: 4...7) : Int.random(in: 8...16)
        let h = Int.random(in: max(perDay, perDay * d - (perDay == 1 ? 2 : 4))...(perDay * d))
        let c = perDay == 1 ? Int.random(in: 1...3) : Int.random(in: 2...5)
        let end = h - c + r * perDay
        guard h >= c, h + r * perDay >= k, h < k, (end >= k) == wantYes, h + r * perDay <= 20 else { continue }
        let prize = pPrizes.randomElement()!, treat = pTreats.randomElement()!
        return PRound(kind: .tempt, prize: prize, cost: k, startCoins: h - perDay, feed: perDay, perDay: perDay, day: d,
                      treat: treat, treatCost: c,
                      prompt: "Buy the \(treat.emoji) and still get the \(prize.emoji) by Day 7?",
                      options: ["✅ YES", "❌ NO"], correct: wantYes ? 0 : 1,
                      explain: "\(h) − \(c) + \(r * perDay) more = \(end) 🪙 · the \(prize.emoji) costs \(k)",
                      shelf: prize.emoji)
    }
    return pFill()
}

private func pSort() -> PRound {
    let need = Bool.random()
    let it = (need ? pNeeds : pWants).randomElement()!
    return PRound(kind: .sort, prize: it, prompt: it.name, options: ["NEED", "WANT"], correct: need ? 0 : 1,
                  explain: "\(it.emoji) \(it.name) is a \(need ? "NEED" : "WANT")", shelf: it.emoji)
}

private func pWeeks(_ n: Int) -> String { plural(n, "week", "weeks") }

private func pPlanExact(_ level: Int) -> PRound {
    let a = Int.random(in: 2...5), w = Int.random(in: 2...6), p = pPrizes.randomElement()!
    let (o, c) = pOptions(w, [w - 1, w + 1, w + 2].shuffled(), pChoices(level), pWeeks)
    return PRound(kind: .choice, prize: p,
                  prompt: "You get \(a) 🪙 every week.\nThe \(p.emoji) costs \(a * w) 🪙.\nHow many weeks to save?",
                  options: o, correct: c, explain: "\(a) × \(w) = \(a * w) → \(pWeeks(w))", shelf: p.emoji)
}

private func pPlanRemainder(_ level: Int) -> PRound {
    for _ in 0..<500 {
        let h = Int.random(in: 1...9), a = Int.random(in: 2...6)
        let cost = Int.random(in: (h + a + 1)...(level >= 8 ? 60 : 40))
        let need = cost - h, w = (need + a - 1) / a
        guard (2...8).contains(w), need % a != 0 || Bool.random() else { continue }
        let p = pPrizes.randomElement()!
        let (o, c) = pOptions(w, [w - 1, w + 1, w + 2].shuffled(), pChoices(level), pWeeks)
        return PRound(kind: .choice, prize: p, startCoins: h,
                      prompt: "Porcus has \(h) 🪙. You get \(a) 🪙 a week.\nThe \(p.emoji) costs \(cost) 🪙.\nHow many weeks until you can buy it?",
                      options: o, correct: c,
                      explain: "Need \(need) more · \(w - 1) × \(a) = \((w - 1) * a) is short · \(w) × \(a) = \(w * a) ✓",
                      shelf: p.emoji)
    }
    return pPlanExact(level)
}

private func pJarsHalf(_ level: Int) -> PRound {
    let t = [6, 8, 10, 12, 14, 16, 18, 20].randomElement()!, g = Int.random(in: 1...2)
    let save = t / 2, spend = t - save - g
    let askSave = Bool.random()
    let ans = askSave ? save : spend
    let (o, c) = pOptions(ans, [askSave ? spend : save, ans + 1, ans - 1, ans + 2, ans - 2], pChoices(level), { "\($0) 🪙" })
    return PRound(kind: .choice, prize: PItem(emoji: "🫙", name: "jars"), startCoins: t,
                  prompt: "You got \(t) 🪙!\nHALF go in SAVE, \(g) in GIVE,\nthe rest in SPEND.\nHow many go in \(askSave ? "SAVE" : "SPEND")?",
                  options: o, correct: c,
                  explain: "Half of \(t) = \(save) SAVE · \(t) − \(save) − \(g) = \(spend) SPEND", shelf: "🫙")
}

private func pJarsPercent(_ level: Int) -> PRound {
    let splits = [(50, 40, 10), (60, 30, 10), (70, 20, 10), (50, 30, 20), (60, 20, 20)]
    let s = splits.randomElement()!
    let t = 10 * Int.random(in: 1...(level >= 8 ? 20 : 10))
    let jars = [("SAVE", s.0), ("SPEND", s.1), ("GIVE", s.2)]
    let ask = jars.randomElement()!
    let tenth = t / 10, ans = t * ask.1 / 100
    let others = jars.filter { $0.0 != ask.0 }.map { t * $0.1 / 100 }
    let (o, c) = pOptions(ans, [ask.1 == 10 ? 0 : ask.1] + others + [ans + tenth, ans - tenth], pChoices(level), { "\($0) 🪙" })
    return PRound(kind: .choice, prize: PItem(emoji: "🫙", name: "jars"), startCoins: t,
                  prompt: "Share out \(t) 🪙:\nSAVE \(s.0)% · SPEND \(s.1)% · GIVE \(s.2)%\nHow many go in \(ask.0)?",
                  options: o, correct: c,
                  explain: "10% of \(t) = \(tenth) → \(ask.1)% = \(ask.1 / 10) × \(tenth) = \(ans)", shelf: "🫙")
}

private func pInterest1(_ level: Int) -> PRound {
    let h = 10 * Int.random(in: 2...20), i = h / 10
    if Bool.random() {
        let (o, c) = pOptions(h + i, [h + 10, h + 1, h + i + 1, h + 2 * i, h + i - 1].shuffled(), pChoices(level), { "\($0) 🪙" })
        return PRound(kind: .choice, prize: PItem(emoji: "💰", name: "interest"), startCoins: h,
                      prompt: "Porcus pays 10% each week.\nHe holds \(h) 🪙.\nHow many after 1 week?",
                      options: o, correct: c, explain: "10% of \(h) = \(i) → \(h) + \(i) = \(h + i)", shelf: "💰")
    }
    let (o, c) = pOptions(i, [10, i + 1, i * 2, i - 1, i + 10].shuffled(), pChoices(level), { "\($0) 🪙" })
    return PRound(kind: .choice, prize: PItem(emoji: "💰", name: "interest"), startCoins: h,
                  prompt: "Porcus pays 10% each week.\nHe holds \(h) 🪙.\nHow much does he pay you this week?",
                  options: o, correct: c, explain: "10% of \(h) = \(h) ÷ 10 = \(i)", shelf: "💰")
}

private func pInterestTop(_ level: Int) -> PRound {
    switch Int.random(in: 0..<3) {
    case 0:     // two weeks of 10% — the second week pays interest on the interest too
        let h = 100 * Int.random(in: 1...5), w1 = h + h / 10, w2 = w1 + w1 / 10
        let (o, c) = pOptions(w2, [h + 2 * (h / 10), w1, w2 + 1, w2 - 1].shuffled(), pChoices(level), { "\($0) 🪙" })
        return PRound(kind: .choice, prize: PItem(emoji: "💰", name: "interest"), startCoins: h,
                      prompt: "Porcus pays 10% each week.\nHe holds \(h) 🪙.\nHow many after 2 weeks?",
                      options: o, correct: c, explain: "\(h) → +\(h / 10) = \(w1) → +\(w1 / 10) = \(w2)", shelf: "💰")
    case 1:     // other rates, chosen so the interest is whole
        let (r, step) = [(5, 20), (20, 5), (25, 4)].randomElement()!
        let h = step * Int.random(in: 2...(200 / step)), i = h * r / 100
        let (o, c) = pOptions(h + i, [h + r, h + i + 1, h + 2 * i, h + i - 1, h + h / 10].shuffled(), pChoices(level), { "\($0) 🪙" })
        return PRound(kind: .choice, prize: PItem(emoji: "💰", name: "interest"), startCoins: h,
                      prompt: "Porcus pays \(r)% this week.\nHe holds \(h) 🪙.\nHow many after 1 week?",
                      options: o, correct: c, explain: "\(r)% of \(h) = \(i) → \(h) + \(i) = \(h + i)", shelf: "💰")
    default:    // save now or later?
        let x = 100 * Int.random(in: 1...2), y = x + 10 * Int.random(in: 0...4)
        let a = x + x / 10 + (x + x / 10) / 10, b = y + y / 10
        let correct = a > b ? 0 : a < b ? 1 : 2
        return PRound(kind: .choice, prize: PItem(emoji: "💰", name: "interest"), startCoins: x,
                      prompt: "Porcus pays 10% a week.\nA: put in \(x) 🪙 now, wait 2 weeks.\nB: put in \(y) 🪙 next week, wait 1 week.\nWhich ends with more?",
                      options: ["Plan A", "Plan B", "The same"], correct: correct,
                      explain: "A: \(x) → \(x + x / 10) → \(a) · B: \(y) → \(b)", shelf: "💰")
    }
}

func porcusRound(_ level: Int) -> PRound {
    let r = Int.random(in: 0..<20)
    switch level {
    case 1: return pFill()
    case 2: return pTempt(perDay: 1)
    case 3: return r < 10 ? pSort() : pTempt(perDay: 2)
    case 4: return r < 12 ? pPlanExact(4) : r < 16 ? pSort() : pTempt(perDay: 2)
    case 5: return r < 8 ? pPlanRemainder(5) : r < 16 ? pJarsHalf(5) : pPlanExact(5)
    case 6: return r < 10 ? pJarsPercent(6) : r < 16 ? pPlanRemainder(6) : pJarsHalf(6)
    case 7: return r < 10 ? pInterest1(7) : r < 15 ? pJarsPercent(7) : pPlanRemainder(7)
    default: return r < 10 ? pInterestTop(level) : r < 14 ? pInterest1(level) : r < 17 ? pJarsPercent(level) : pPlanRemainder(level)
    }
}

#if DEBUG
/// Self-check: each choice question's marked answer is the true one, and options are distinct.
func porcusSelfCheck() -> [String] {
    var errs: [String] = []
    func nums(_ s: String) -> [Int] { s.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) } }
    for level in 1...10 {
        for _ in 0..<3000 {
            let r = porcusRound(level)
            if Set(r.options).count != r.options.count { errs.append("L\(level) dup \(r.options)") }
            if r.kind != .fill && !r.options.indices.contains(r.correct) { errs.append("L\(level) bad index") }
            switch r.kind {
            case .fill:
                if level != 1 || !(3...5).contains(r.cost) || r.feed != r.cost { errs.append("fill \(r.cost)") }
            case .tempt:
                let h = r.startCoins + r.feed, end = h - r.treatCost + (7 - r.day) * r.perDay
                if (end >= r.cost) != (r.correct == 0) { errs.append("tempt answer") }
                if h + (7 - r.day) * r.perDay > (level <= 2 ? 10 : 20) || r.cost > 20 { errs.append("tempt too big") }
                if h < r.treatCost { errs.append("tempt can't afford treat") }
            case .sort:
                let need = pNeeds.contains(r.prize), want = pWants.contains(r.prize)
                if need == want || (r.correct == 0) != need { errs.append("sort \(r.prize)") }
            case .choice:
                let opts = r.options.map { nums($0).first ?? -1 }
                if r.prompt.contains("weeks to save") {
                    let n = nums(r.prompt); if n[1] / n[0] != opts[r.correct] || n[1] % n[0] != 0 { errs.append("planExact") }
                } else if r.prompt.contains("until you can buy") {
                    let n = nums(r.prompt), w = opts[r.correct]
                    if !(n[0] + w * n[1] >= n[2] && n[0] + (w - 1) * n[1] < n[2]) { errs.append("planRem \(r.prompt) \(w)") }
                } else if r.prompt.contains("HALF") {
                    let n = nums(r.prompt), t = n[0], g = n[1]
                    let ans = r.prompt.hasSuffix("SAVE?") ? t / 2 : t - t / 2 - g
                    if ans != opts[r.correct] || t % 2 != 0 { errs.append("jarsHalf") }
                } else if r.prompt.contains("Share out") {
                    let n = nums(r.prompt), t = n[0]
                    let pct = r.prompt.hasSuffix("SAVE?") ? n[1] : r.prompt.hasSuffix("SPEND?") ? n[2] : n[3]
                    if t * pct % 100 != 0 || t * pct / 100 != opts[r.correct] || n[1] + n[2] + n[3] != 100 { errs.append("jarsPct \(r.prompt)") }
                } else if r.options.contains("Plan A") {
                    let n = nums(r.prompt), x = n[1], y = n[3]
                    let a = Double(x) * 1.1 * 1.1, b = Double(y) * 1.1
                    let want = abs(a - b) < 0.001 ? 2 : a > b ? 0 : 1
                    if want != r.correct { errs.append("nowLater \(x) \(y)") }
                } else if r.prompt.contains("after 2 weeks") {
                    let n = nums(r.prompt), h = n[1]
                    if Double(opts[r.correct]) != (Double(h) * 1.21).rounded() || h * 121 % 100 != 0 { errs.append("int2") }
                } else if r.prompt.contains("after 1 week") {
                    let n = nums(r.prompt), rate = n[0], h = n[1]
                    if h * rate % 100 != 0 || h + h * rate / 100 != opts[r.correct] { errs.append("int1 \(r.prompt)") }
                } else if r.prompt.contains("pay you") {
                    let n = nums(r.prompt)
                    if n[1] * n[0] / 100 != opts[r.correct] || n[1] % 10 != 0 { errs.append("int pay") }
                } else { errs.append("unchecked \(r.prompt)") }
                if r.options.count != (r.options.contains("Plan A") ? 3 : pChoices(level)) { errs.append("L\(level) count \(r.options.count)") }
                if opts.contains(where: { $0 <= 0 }) && !r.options.contains("Plan A") { errs.append("non-positive \(r.options)") }
            }
        }
    }
    let overlap = Set(pNeeds.map(\.emoji)).intersection(pWants.map(\.emoji))
    if !overlap.isEmpty { errs.append("need/want overlap \(overlap)") }
    return errs
}
#endif

// MARK: - Model

@MainActor
private final class PorcusModel: ArcadeModel {
    enum Stage { case feeding, asking, done }
    enum Mood { case calm, happy, betrayed, sad }

    @Published var round = pFill()
    @Published var coins = 0
    @Published var pending = 0
    @Published var stage: Stage = .feeding
    @Published var mood: Mood = .calm
    @Published var say = ""
    @Published var chosen: Int?
    @Published var shelf: [String] = []
    @Published var serial = 0
    @Published var fed = 0                 // bumps per coin (Porcus gulps)
    @Published var sparks = 0
    @Published var showExplain = false

    init() { super.init(key: GameID.porcus.rawValue) }

    override func perLevel(_ level: Int) -> Int { level == 1 ? 4 : 5 }

    override func onBegin() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFTEST"] != nil {
            let errs = porcusSelfCheck()
            marketLog("PORCUS SELFTEST: \(errs.isEmpty ? "OK" : "\(errs.count) errors") \(Array(Set(errs)).prefix(12))")
        }
        #endif
        shelf = []
        newRound()
    }

    func newRound() {
        round = porcusRound(level)
        coins = round.startCoins
        pending = round.feed
        stage = pending > 0 ? .feeding : .asking
        mood = .calm; chosen = nil; showExplain = false
        switch round.kind {
        case .fill: say = "Let's save for the \(round.prize.emoji)!"
        case .tempt: say = "Day \(round.day)! Feed me!"
        case .sort: say = "Need it or want it?"
        case .choice: say = "Oink? Think…"
        }
        serial += 1
    }

    /// One coin goes into Porcus (a drag that lands on him, or a tap on the coin).
    func feedCoin() {
        guard phase == .playing, stage == .feeding, pending > 0 else { return }
        pending -= 1; coins += 1; fed += 1; mood = .calm
        Haptics.tap(0.5)
        say = round.kind == .fill ? "Oink! \(coins)!" : "Oink! Yum!"
        if pending == 0 {
            stage = .asking
            if round.kind == .tempt { say = "A \(round.treat?.name ?? "treat")… 🤔" }
        }
    }

    /// Level I: buy the prize — only once enough coins are in.
    func buy() {
        guard phase == .playing, round.kind == .fill, stage != .done else { return }
        if coins >= round.cost {
            stage = .done; coins -= round.cost; mood = .happy; say = "Hooray! Enjoy the \(round.prize.emoji)!"
            shelf.append(round.prize.emoji); sparks += 1
            hit()
            next(after: 1.4)
        } else {
            mood = .sad; say = "Not yet! \(coins) of \(round.cost) 🪙"
            miss(delay: 1.4)
            if dying { stage = .done }
        }
    }

    /// Answer a question (tempt / sort / choice): `i` indexes `round.options`.
    func answer(_ i: Int) {
        guard phase == .playing, stage == .asking, round.kind != .fill, round.options.indices.contains(i) else { return }
        chosen = i; stage = .done
        let right = i == round.correct
        if right {
            hit(); sparks += 1
            if !round.shelf.isEmpty { shelf.append(round.shelf) }
        } else {
            miss(delay: 2.6); showExplain = true
        }
        // Porcus reacts — and in a temptation the right choice then happens either way.
        if round.kind == .tempt && round.correct == 0 {
            coins -= round.treatCost; mood = .betrayed
            say = right ? "My coin! 😱 …OK, still enough." : "Yes! You can — still enough!"
        } else if round.kind == .tempt {
            mood = right ? .happy : .sad
            say = right ? "Saved! Oink-oink! 💕" : "No! The \(round.prize.emoji) needs every coin!"
        } else {
            mood = right ? .happy : .sad
            say = right ? ["Oink! Clever!", "Right! 💕", "Bravo!", "Oink-oink!"].randomElement()! : "Oops! Look…"
        }
        next(after: right ? 1.4 : 2.8)
    }

    private func next(after t: Double) {
        let s = serial
        DispatchQueue.main.asyncAfter(deadline: .now() + t) { [weak self] in
            guard let self, self.serial == s, self.phase == .playing, !self.dying else { return }
            self.newRound()
        }
    }

    // One move per call. The bot decides per round whether it will be right; a wrong level-I
    // round taps BUY too early, a wrong question taps a wrong answer.
    private var botSerial = -1, botGood = true
    override func botAct(correct: Bool) {
        guard stage != .done else { return }
        if botSerial != serial { botSerial = serial; botGood = correct }
        switch round.kind {
        case .fill:
            if pending > 0 && !botGood { botSerial = -1; buy() }     // too early (then re-decide)
            else if pending > 0 { feedCoin() } else { buy() }
        default:
            if stage == .feeding { feedCoin(); return }
            let wrong = round.options.indices.filter { $0 != round.correct }
            answer(botGood ? round.correct : wrong.randomElement()!)
        }
    }
}

// MARK: - Views

/// A gold coin, drawn.
private struct PCoin: View {
    var size: CGFloat = 64
    var ghost = false
    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [Color(hex: 0xfff1a8), Color(hex: Lu.gold), Color(hex: 0xb8860b)],
                                 center: UnitPoint(x: 0.35, y: 0.3), startRadius: 1, endRadius: size * 0.7))
            .overlay(Circle().inset(by: size * 0.12).stroke(Color(hex: 0x9c7b33), lineWidth: max(1.5, size * 0.05)))
            .overlay(Text("1").font(luSerif(size * 0.42, .black)).foregroundStyle(Color(hex: 0x7a5a12)))
            .frame(width: size, height: size)
            .opacity(ghost ? 0.3 : 1)
    }
}

private struct PFramesKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) { value.merge(nextValue()) { $1 } }
}

private extension View {
    func pFrame(_ name: String) -> some View {
        background(GeometryReader { g in Color.clear.preference(key: PFramesKey.self, value: [name: g.frame(in: .named("pf"))]) })
    }
}

/// Something the child can drag onto a target (or just tap): `drop` gets the release point in
/// the "pf" space and says whether it landed.
private struct PDraggable<Content: View>: View {
    let drop: (CGPoint) -> Bool
    let tap: () -> Void
    @ViewBuilder let content: Content
    @State private var drag: CGSize = .zero
    var body: some View {
        content
            .offset(drag)
            .scaleEffect(drag == .zero ? 1 : 1.1)
            .gesture(DragGesture(minimumDistance: 6, coordinateSpace: .named("pf"))
                .onChanged { drag = $0.translation }
                .onEnded { v in
                    if drop(v.location) { drag = .zero } else { withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { drag = .zero } }
                })
            .simultaneousGesture(TapGesture().onEnded { tap() })
    }
}

struct PorcusView: View {
    let onClose: () -> Void
    @StateObject private var model = PorcusModel()
    @State private var frames: [String: CGRect] = [:]

    var body: some View {
        ArcadeShell(model: model, spec: GameID.porcus.spec!, accent: Lu.coral, onClose: onClose) {
            VStack(spacing: 8) {
                Color.clear.frame(height: 52)
                shelfRow
                pigRow
                middle
                Spacer(minLength: 4)
                bottom
            }
            .padding(.horizontal, 14).padding(.bottom, 8)
            .coordinateSpace(name: "pf")
            .onPreferenceChange(PFramesKey.self) { frames = $0 }
        }
    }

    private func lands(_ p: CGPoint, on name: String) -> Bool {
        frames[name]?.insetBy(dx: -30, dy: -30).contains(p) ?? false
    }

    private var shelfRow: some View {
        HStack(spacing: 4) {
            Text("🏆").font(.system(size: 20))
            ForEach(Array(model.shelf.suffix(9).enumerated()), id: \.offset) { _, e in
                Text(e).font(.system(size: 24)).transition(.scale(scale: 0.2).combined(with: .opacity))
            }
            Spacer()
        }
        .frame(height: 34)
        .padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x6e4524).opacity(0.55)))
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: model.shelf.count)
    }

    // Porcus — fatter as he fills — with his coin count and what he's saying.
    private var pigRow: some View {
        let f = min(1, log2(1 + Double(model.coins)) / log2(31))
        return HStack(alignment: .center, spacing: 8) {
            ZStack {
                Text("🐷").font(.system(size: 92))
                    .scaleEffect(x: 0.85 + 0.45 * f, y: 0.85 + 0.22 * f)
                    .scaleEffect(model.mood == .happy ? 1.12 : 1)
                    .rotationEffect(.degrees(model.mood == .happy ? -10 : model.mood == .betrayed ? 12 : 0))
                    .modifier(MarketShake(shakes: CGFloat(model.lastMiss + (model.mood == .betrayed ? 1 : 0))))
                    .animation(.spring(response: 0.3, dampingFraction: 0.35), value: model.mood)
                    .animation(.spring(response: 0.25, dampingFraction: 0.4), value: model.coins)
                    .animation(.linear(duration: 0.45), value: model.lastMiss)
                Text("\(model.coins)").font(luFont(22)).foregroundStyle(Color(hex: Lu.inkDark))
                    .padding(.horizontal, 9).padding(.vertical, 2)
                    .background(Capsule().fill(Color(hex: Lu.gold)).overlay(Capsule().stroke(Color(hex: 0x9c7b33), lineWidth: 2)))
                    .offset(y: 54)
                MarketSparks(trigger: model.sparks, glyphs: ["🪙", "✨", "💕"])
            }
            .frame(width: 150, height: 140)
            .pFrame("pig")

            MarketBubble {
                Text(model.say).font(luFont(19, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                    .multilineTextAlignment(.leading).minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .padding(.bottom, 30)
        }
    }

    @ViewBuilder private var middle: some View {
        let r = model.round
        switch r.kind {
        case .fill:
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Text(r.prize.emoji).font(.system(size: 54))
                    Text("=").font(luFont(30)).foregroundStyle(Color(hex: Lu.inkDim))
                    HStack(spacing: 6) {
                        ForEach(0..<r.cost, id: \.self) { i in PCoin(size: 40, ghost: i >= model.coins) }
                    }
                }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12).background(luPanelShape(18))
        case .tempt:
            VStack(spacing: 10) {
                calendar(r)
                HStack(spacing: 14) {
                    tag(r.prize.emoji, r.cost, goal: true)
                    tag(r.treat?.emoji ?? "🍭", r.treatCost, goal: false)
                }
                if model.stage != .feeding && r.perDay == 1 {
                    ifYouBuy(r)
                }
                if model.stage != .feeding {
                    Text(r.prompt).font(luFont(20, .heavy)).foregroundStyle(Color(hex: Lu.ink))
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity).padding(12).background(luPanelShape(18))
        case .sort:
            PDraggable(drop: { p in
                if lands(p, on: "jar0") { model.answer(0); return true }
                if lands(p, on: "jar1") { model.answer(1); return true }
                return false
            }, tap: {}) {
                VStack(spacing: 4) {
                    Text(r.prize.emoji).font(.system(size: 64))
                    Text(r.prompt).font(luFont(20, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                }
                .padding(.horizontal, 22).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: Lu.ink)))
                .opacity(model.stage == .done ? 0 : 1)
            }
            .id(model.serial)
        case .choice:
            Text(r.prompt).font(luFont(r.prompt.count > 90 ? 18 : 21, .heavy)).foregroundStyle(Color(hex: Lu.ink))
                .multilineTextAlignment(.center).lineSpacing(3).minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity).padding(14).background(luPanelShape(18))
        }
    }

    private func calendar(_ r: PRound) -> some View {
        HStack(spacing: 4) {
            ForEach(1...7, id: \.self) { d in
                VStack(spacing: 2) {
                    Text("\(d)").font(luFont(13, .heavy)).foregroundStyle(Color(hex: d == r.day ? Lu.inkDark : Lu.inkDim))
                    if d < r.day {
                        Text("✓").font(luFont(16)).foregroundStyle(Color(hex: Lu.mint)).frame(height: 30)
                    } else if d == r.day {
                        Text("☀️").font(.system(size: 20)).frame(height: 30)
                    } else {
                        VStack(spacing: -12) { ForEach(0..<r.perDay, id: \.self) { _ in PCoin(size: 22, ghost: false).opacity(0.55) } }
                            .frame(height: 30)
                    }
                }
                .frame(maxWidth: .infinity).padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: d == r.day ? Lu.gold : Lu.panel)))
            }
        }
    }

    /// Gradus II's counting aid: the coins left if you buy the treat (the treat's coins crossed
    /// out) plus the coins still to come — count the gold ones and compare with the prize.
    private func ifYouBuy(_ r: PRound) -> some View {
        let h = r.startCoins + r.feed, left = h - r.treatCost, future = 7 - r.day
        return HStack(spacing: 3) {
            ForEach(0..<max(0, left), id: \.self) { _ in PCoin(size: 26) }
            Text(r.treat?.emoji ?? "🍭").font(.system(size: 22))
            ForEach(0..<r.treatCost, id: \.self) { _ in
                PCoin(size: 26).opacity(0.35).overlay(Text("✕").font(luFont(20)).foregroundStyle(Color(hex: Lu.coral)))
            }
            Text("+").font(luFont(20)).foregroundStyle(Color(hex: Lu.inkDim))
            ForEach(0..<future, id: \.self) { _ in PCoin(size: 26).opacity(0.6) }
        }
    }

    private func tag(_ emoji: String, _ cost: Int, goal: Bool) -> some View {
        HStack(spacing: 6) {
            Text(emoji).font(.system(size: 34))
            Text("\(cost) 🪙").font(luFont(20)).foregroundStyle(Color(hex: Lu.inkDark))
        }
        .padding(.horizontal, 12).padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: goal ? Lu.mint : Lu.ink)))
    }

    @ViewBuilder private var bottom: some View {
        let r = model.round
        VStack(spacing: 10) {
            if model.showExplain {
                Text(r.explain).font(luFont(17, .heavy)).foregroundStyle(Color(hex: Lu.gold))
                    .multilineTextAlignment(.center).minimumScaleFactor(0.6).lineLimit(3)
                    .transition(.opacity)
            }
            if model.stage == .feeding {
                VStack(spacing: 4) {
                    PDraggable(drop: { p in
                        guard lands(p, on: "pig") else { return false }
                        model.feedCoin(); return true
                    }, tap: { model.feedCoin() }) {
                        PCoin(size: 84)
                    }
                    .id(model.fed)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
                    Text("👆 ➜ 🐷").font(.system(size: 22)).opacity(0.8)
                }
                .frame(height: 130)
            }
            switch r.kind {
            case .fill:
                LudusButton(title: "Buy \(r.prize.emoji)", fill: model.coins >= r.cost ? [Lu.gold, Lu.tangerine] : [Lu.panel2, Lu.panel],
                            fullWidth: true) { model.buy() }
                    .scaleEffect(model.coins >= r.cost && model.stage != .done ? 1.05 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.4), value: model.coins >= r.cost)
            case .sort:
                HStack(spacing: 14) {
                    jar(0, "NEED", "🏠", Lu.sky)
                    jar(1, "WANT", "🎈", Lu.grape)
                }
            case .tempt, .choice:
                if model.stage != .feeding {
                    let n = r.options.count
                    let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: n == 4 ? 2 : n)
                    LazyVGrid(columns: cols, spacing: 10) {
                        ForEach(r.options.indices, id: \.self) { i in
                            MarketChoiceButton(text: r.options[i], state: state(i), height: n <= 2 ? 88 : 72) { model.answer(i) }
                        }
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.showExplain)
    }

    private func state(_ i: Int) -> MarketChoiceState {
        guard model.stage == .done, let c = model.chosen else { return .open }
        return i == model.round.correct ? .right : i == c ? .wrong : .faded
    }

    private func jar(_ i: Int, _ label: String, _ icon: String, _ hex: UInt) -> some View {
        let st = state(i)
        return Button(action: { model.answer(i) }) {
            VStack(spacing: 4) {
                Text(icon).font(.system(size: 40))
                Text(label).font(luFont(24)).foregroundStyle(Color(hex: Lu.inkDark))
                if model.stage == .done && i == model.round.correct {
                    Text(model.round.prize.emoji).font(.system(size: 30)).transition(.scale)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(RoundedRectangle(cornerRadius: 26).fill(Color(hex: st == .wrong ? Lu.coral : st == .right ? Lu.mint : hex))
                .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.white.opacity(0.35), lineWidth: 3)))
            .opacity(st == .faded ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(model.stage != .asking)
        .pFrame("jar\(i)")
    }
}
