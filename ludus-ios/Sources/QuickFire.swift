import SwiftUI

// MARK: - QuickFire — a shared "pick the right answer, fast" engine
//
// One button-based quiz mechanic (timer bar, hearts, combo multiplier) that several
// games pour a question-deck into: Capital Clash (geography), True/False Blitz (logic),
// Odd One Out (reasoning). Add a game = write a `() -> QFQuestion` generator.

struct QFQuestion {
    let topLabel: String     // small eyebrow, e.g. "NAME THIS COUNTRY"
    let big: String          // text prompt (used when there's no shape)
    let options: [String]
    let correct: Int
    var shape: GeoShape? = nil   // when set, the prompt is a drawn country silhouette
}

@MainActor
private final class QuickFireEngine: ObservableObject {
    enum Phase { case playing, over }
    @Published var phase: Phase = .playing
    @Published var score = 0
    @Published var hearts = 3
    @Published var combo = 0
    @Published var den = 0
    @Published var tLeft: Double = 5
    @Published var perQ: Double = 5
    @Published var question = QFQuestion(topLabel: "", big: "", options: [], correct: 0)
    @Published var revealed = false
    @Published var chosen: Int?
    @Published var lastScore = 0
    @Published var lastDen = 0
    @Published var best = 0
    @Published var newBest = false
    @Published var reason = ""

    let key: String
    private let make: (Int) -> QFQuestion   // passed the current score, for difficulty ramp

    init(key: String, make: @escaping (Int) -> QFQuestion) {
        self.key = key
        self.make = make
    }

    func start() {
        score = 0; hearts = 3; combo = 0; den = 0
        revealed = false; chosen = nil; reason = ""; newBest = false
        perQ = 8; tLeft = 8
        question = make(0)
        phase = .playing
        Haptics.prime()
    }

    func tickStep() {
        guard phase == .playing, !revealed else { return }
        tLeft -= 0.05
        if tLeft <= 0 { timeout() }
    }

    private func timeout() {
        guard !revealed else { return }
        revealed = true; chosen = nil; combo = 0; hearts -= 1
        Haptics.error()
        advanceAfterReveal()
    }

    func choose(_ i: Int) {
        guard phase == .playing, !revealed else { return }
        revealed = true; chosen = i
        if i == question.correct {
            combo += 1
            let pts = combo
            score += pts; den += pts
            Haptics.success()
        } else {
            combo = 0; hearts -= 1
            Haptics.error()
        }
        advanceAfterReveal()
    }

    private func advanceAfterReveal() {
        let correctAnswer = chosen == question.correct
        let delay = correctAnswer ? 0.4 : 0.7
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            if self.hearts <= 0 { self.gameOver("Out of hearts!") } else { self.nextQuestion() }
        }
    }

    private func nextQuestion() {
        question = make(score)
        revealed = false; chosen = nil
        perQ = max(4.0, 8.0 - Double(score) * 0.05)
        tLeft = perQ
    }

    private func gameOver(_ why: String) {
        LudusStore.award(den)
        newBest = LudusStore.recordBest(key, score)
        best = LudusStore.best(key)
        lastScore = score; lastDen = den
        reason = why
        phase = .over
    }
}

private struct QFOptionButton: View {
    let text: String
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
    private var textHex: UInt {
        (revealed && (index == correct || index == chosen)) ? Lu.inkDark : Lu.ink
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(luFont(22))
                .foregroundStyle(Color(hex: textHex))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 74)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(hex: fillHex))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: Lu.line), lineWidth: 2))
                )
                .opacity(revealed && index != correct && index != chosen ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(revealed)
    }
}

private struct QuickFireView: View {
    @StateObject var engine: QuickFireEngine
    let subtitle: String
    let accent: UInt
    let onClose: () -> Void

    private let tick = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            LudusBackground().ignoresSafeArea()

            VStack(spacing: 14) {
                HStack(alignment: .top, spacing: 8) {
                    LudusCloseButton(action: onClose)
                    StatPill(label: "SCORE", value: "\(engine.score)", valueHex: Lu.gold)
                    Spacer(minLength: 4)
                    HeartsRow(hearts: engine.hearts)
                    Spacer(minLength: 4)
                    StatPill(label: "DENARII", value: "\(engine.den)", valueHex: Lu.silver)
                }

                // Timer bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: Lu.panel))
                        Capsule().fill(Color(hex: engine.tLeft / max(engine.perQ, 0.01) < 0.3 ? Lu.coral : accent))
                            .frame(width: max(0, geo.size.width * CGFloat(min(1, engine.tLeft / max(engine.perQ, 0.01)))))
                    }
                }
                .frame(height: 10)

                Spacer(minLength: 8)

                VStack(spacing: 8) {
                    Text(engine.question.topLabel)
                        .font(luSerif(14, .bold)).textCase(.uppercase).tracking(2)
                        .foregroundStyle(Color(hex: Lu.inkDim))
                    if let shape = engine.question.shape {
                        CountryContextView(target: shape)
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(engine.question.big)
                            .font(luFont(engine.question.big.count > 26 ? 26 : 34))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(Color(hex: Lu.ink))
                    }
                }
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding(.vertical, 18)
                .background(luPanelShape(20))

                if engine.combo >= 2 {
                    Text("COMBO ×\(engine.combo)!")
                        .font(luFont(18)).foregroundStyle(Color(hex: Lu.mint))
                        .id(engine.combo)
                        .transition(.scale(scale: 1.2).combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: engine.combo)
                }

                Spacer(minLength: 8)

                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(Array(engine.question.options.enumerated()), id: \.offset) { idx, opt in
                        QFOptionButton(text: opt, index: idx, revealed: engine.revealed,
                                       chosen: engine.chosen, correct: engine.question.correct,
                                       action: { engine.choose(idx) })
                    }
                }
                .padding(.bottom, 6)
            }
            .padding(.horizontal, 14).padding(.top, 4)

            if engine.phase == .over {
                LudusGameOverView(reason: engine.reason, score: engine.lastScore, best: engine.best,
                                  denRun: engine.lastDen, newBest: engine.newBest,
                                  onAgain: { engine.start() }, onClose: onClose)
                    .transition(.opacity)
            }
        }
        .statusBarHidden(true)
        .onReceive(tick) { _ in engine.tickStep() }
        .onAppear { engine.start() }
    }
}

// MARK: - Games built on QuickFire

// Orbis widens its pool with score, easiest silhouettes first.
private let orbisTier1: Set<String> = [
    "United States", "Italy", "Japan", "Australia", "Brazil", "France",
    "United Kingdom", "India", "China", "Russia", "Egypt", "Canada", "Mexico", "Spain",
]
private let orbisTier2: Set<String> = orbisTier1.union([
    "Germany", "Argentina", "Chile", "South Africa", "Saudi Arabia", "Turkey",
    "Indonesia", "South Korea", "Portugal", "New Zealand",
])

private func countryQuestion(_ score: Int) -> QFQuestion {
    var pool = GeoShapes.quizPool
    let allowed: Set<String>? = score >= 60 ? nil : (score >= 25 ? orbisTier2 : orbisTier1)
    if let allowed {
        let filtered = pool.filter { allowed.contains($0.name) }
        if filtered.count >= 4 { pool = filtered }
    }
    guard let answer = pool.randomElement() else {
        return QFQuestion(topLabel: "NAME THIS COUNTRY", big: "map unavailable", options: ["—"], correct: 0)
    }
    var opts = [answer.name]
    var guard0 = 0
    while opts.count < 4 && guard0 < 300 {
        if let o = pool.randomElement()?.name, !opts.contains(o) { opts.append(o) }
        guard0 += 1
    }
    opts.shuffle()
    return QFQuestion(topLabel: "NAME THIS COUNTRY", big: "", options: opts,
                      correct: opts.firstIndex(of: answer.name) ?? 0, shape: answer)
}

/// "Orbis" — name the country from the shape of its borders.
struct NameCountryView: View {
    let onClose: () -> Void
    var body: some View {
        QuickFireView(engine: QuickFireEngine(key: "nameCountry", make: countryQuestion),
                      subtitle: "Name the country", accent: Lu.sky, onClose: onClose)
    }
}

private func trueFalseQuestion(_ score: Int) -> QFQuestion {
    switch Int.random(in: 0..<3) {
    case 0: // easy addition
        let a = Int.random(in: 2...12), b = Int.random(in: 2...12)
        let real = a + b
        let shown = Bool.random() ? real : real + [-2, -1, 1, 2].randomElement()!
        return QFQuestion(topLabel: "TRUE OR FALSE?", big: "\(a) + \(b) = \(shown)",
                          options: ["TRUE", "FALSE"], correct: (shown == real) ? 0 : 1)
    case 1: // small multiplication
        let a = Int.random(in: 2...5), b = Int.random(in: 2...5)
        let real = a * b
        let shown = Bool.random() ? real : real + [-2, -1, 1, 2].randomElement()!
        return QFQuestion(topLabel: "TRUE OR FALSE?", big: "\(a) × \(b) = \(shown)",
                          options: ["TRUE", "FALSE"], correct: (shown == real) ? 0 : 1)
    default: // geography — famous countries only
        let c = Geo.famous.randomElement() ?? Geo.countries[0]
        let makeTrue = Bool.random()
        let cap = makeTrue ? c.capital : (Geo.famous.randomElement() ?? Geo.countries[0]).capital
        return QFQuestion(topLabel: "TRUE OR FALSE?", big: "\(c.flag)  \(cap) is the capital of \(c.name)",
                          options: ["TRUE", "FALSE"], correct: (cap == c.capital) ? 0 : 1)
    }
}

struct TrueFalseBlitzView: View {
    let onClose: () -> Void
    var body: some View {
        QuickFireView(engine: QuickFireEngine(key: "trueFalseBlitz", make: trueFalseQuestion),
                      subtitle: "Snap judgement", accent: Lu.grape, onClose: onClose)
    }
}

private func oddOneOutQuestion(_ score: Int) -> QFQuestion {
    // (prompt, in-group members, outsiders)
    let groups: [(String, [String], [String])] = [
        ("Which is NOT an animal?", ["Dog", "Cat", "Horse", "Cow", "Tiger", "Rabbit", "Bear"], ["Apple", "Table", "River", "Car", "Shoe"]),
        ("Which is NOT a fruit?", ["Apple", "Banana", "Grape", "Orange", "Mango", "Cherry"], ["Carrot", "Potato", "Onion", "Dog", "Chair"]),
        ("Which is NOT even?", ["2", "4", "6", "8", "10", "12", "14"], ["3", "5", "7", "9", "11"]),
        ("Which is NOT a color?", ["Red", "Blue", "Green", "Yellow", "Purple", "Orange"], ["Seven", "Dog", "Chair", "River"]),
        ("Which is NOT a country?", ["France", "Japan", "Brazil", "Kenya", "Canada", "Egypt"], ["Paris", "London", "Rome", "Tokyo"]),
    ]
    let g = groups.randomElement()!
    var opts = Array(g.1.shuffled().prefix(3))
    let odd = g.2.randomElement()!
    opts.append(odd)
    opts.shuffle()
    return QFQuestion(topLabel: "ODD ONE OUT", big: g.0, options: opts, correct: opts.firstIndex(of: odd) ?? 0)
}

struct OddOneOutView: View {
    let onClose: () -> Void
    var body: some View {
        QuickFireView(engine: QuickFireEngine(key: "oddOneOut", make: oddOneOutQuestion),
                      subtitle: "Spot the outsider", accent: Lu.tangerine, onClose: onClose)
    }
}

// MARK: History — "Timeline" (which came first)

private let timelineEvents: [(String, Int)] = [
    ("The Pyramids", -2560), ("First Olympics", -776), ("Rome is founded", -753),
    ("The Great Wall", -220), ("Julius Caesar", -50), ("Printing press", 1440),
    ("Columbus sails", 1492), ("The Pilgrims", 1620), ("USA is founded", 1776),
    ("The light bulb", 1879), ("First airplane", 1903), ("Titanic sinks", 1912),
    ("Moon landing", 1969), ("First iPhone", 2007),
]

private func timelineQuestion(_ score: Int) -> QFQuestion {
    var picks: [(String, Int)] = []
    var guard0 = 0
    while picks.count < 4 && guard0 < 200 {
        let e = timelineEvents.randomElement()!
        if !picks.contains(where: { $0.0 == e.0 }) { picks.append(e) }
        guard0 += 1
    }
    let earliest = picks.min(by: { $0.1 < $1.1 })?.0 ?? picks[0].0
    let opts = picks.map { $0.0 }.shuffled()
    return QFQuestion(topLabel: "WHICH CAME FIRST?", big: "", options: opts,
                      correct: opts.firstIndex(of: earliest) ?? 0)
}

/// Named TimeOrderView (not TimelineView — that collides with SwiftUI.TimelineView).
struct TimeOrderView: View {
    let onClose: () -> Void
    var body: some View {
        QuickFireView(engine: QuickFireEngine(key: "timeline", make: timelineQuestion),
                      subtitle: "Order history", accent: Lu.tangerine, onClose: onClose)
    }
}

// MARK: Money — "Coin Count"

private func coinCountQuestion(_ score: Int) -> QFQuestion {
    let coins: [(String, String, Int)] = [("penny", "pennies", 1), ("nickel", "nickels", 5),
                                          ("dime", "dimes", 10), ("quarter", "quarters", 25)]
    let maxTypes = score < 20 ? 2 : 3
    let chosen = coins.shuffled().prefix(Int.random(in: 1...maxTypes))
    var parts: [String] = []
    var total = 0
    for (one, many, val) in chosen {
        let n = Int.random(in: 1...3)
        total += n * val
        parts.append("\(n) \(n == 1 ? one : many)")
    }
    var opts = ["\(total)¢"]
    var guard0 = 0
    while opts.count < 4 && guard0 < 200 {
        let d = total + [5, -5, 10, -10, 15, 25, -25].randomElement()!
        if d > 0, !opts.contains("\(d)¢") { opts.append("\(d)¢") }
        guard0 += 1
    }
    opts.shuffle()
    return QFQuestion(topLabel: "HOW MUCH?", big: parts.joined(separator: "\n+ "),
                      options: opts, correct: opts.firstIndex(of: "\(total)¢") ?? 0)
}

struct CoinCountView: View {
    let onClose: () -> Void
    var body: some View {
        QuickFireView(engine: QuickFireEngine(key: "coinCount", make: coinCountQuestion),
                      subtitle: "Add up the coins", accent: Lu.gold, onClose: onClose)
    }
}

// MARK: Logic — "Pattern Pop" (what comes next)

private func patternQuestion(_ score: Int) -> QFQuestion {
    let steps = score < 20 ? [1, 2, 5, 10] : [2, 3, 4, 5, 10]
    let step = steps.randomElement() ?? 2
    let start = Int.random(in: 1...9)
    let seq = (0..<4).map { start + $0 * step }
    let answer = start + 4 * step
    var opts = ["\(answer)"]
    var guard0 = 0
    while opts.count < 4 && guard0 < 200 {
        let d = answer + [1, -1, 2, -2, step, -step].randomElement()!
        if d > 0, !opts.contains("\(d)") { opts.append("\(d)") }
        guard0 += 1
    }
    opts.shuffle()
    return QFQuestion(topLabel: "WHAT COMES NEXT?",
                      big: seq.map(String.init).joined(separator: ",  ") + ",  ?",
                      options: opts, correct: opts.firstIndex(of: "\(answer)") ?? 0)
}

struct PatternPopView: View {
    let onClose: () -> Void
    var body: some View {
        QuickFireView(engine: QuickFireEngine(key: "patternPop", make: patternQuestion),
                      subtitle: "Finish the pattern", accent: Lu.grape, onClose: onClose)
    }
}
