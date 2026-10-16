import SwiftUI

// MARK: - QuickFire — a shared "pick the right answer" engine
//
// One button-based quiz mechanic that several games pour a question-deck into: Orbis
// (geography), True/False Blitz (logic), Odd One Out, Pattern Pop, Timeline, Coin Count. Add a
// game = write a `(level) -> QFQuestion` generator. Runs on GameKit's ArcadeModel (levels,
// hearts, laurels).
//
// Calibration (ages 7 → 12): level I is pictures with TWO choices and no clock; choices grow to
// 3 then 4; the clock only appears at level III and tightens slowly. A wrong answer always
// shows the right one.

struct QFQuestion {
    var topLabel: String     // small eyebrow, e.g. "NAME THIS COUNTRY"
    var big: String          // text/emoji prompt (used when there's no shape)
    var options: [String]
    var correct: Int
    var shape: GeoShape? = nil   // when set, the prompt is a drawn country silhouette
    var coins: [Int]? = nil      // when set, the prompt is a row of drawn coins (cents)
}

/// Seconds per question at a level (0 = no clock): none for I–II, then 20 s easing down to 6 s.
func qfTime(_ level: Int) -> Double { level <= 2 ? 0 : max(6, 20 - Double(level - 3) * 2.5) }

/// Number of answer choices at a level: 2, then 3, then 4.
func qfChoices(_ level: Int) -> Int { level <= 1 ? 2 : (level == 2 ? 3 : 4) }

/// Build options = the answer + distinct distractors (up to `n` in all), shuffled.
func qfOptions(_ answer: String, _ pool: [String], _ n: Int) -> (options: [String], correct: Int) {
    var opts = [answer]
    for o in pool.shuffled() where !opts.contains(o) && opts.count < n { opts.append(o) }
    opts.shuffle()
    return (opts, opts.firstIndex(of: answer) ?? 0)
}

@MainActor
final class QuickFireEngine: ArcadeModel {
    @Published var tLeft: Double = 0
    @Published var perQ: Double = 0
    @Published var question = QFQuestion(topLabel: "", big: "", options: [], correct: 0)
    @Published var revealed = false
    @Published var chosen: Int?

    private let make: (Int) -> QFQuestion   // passed the current level

    init(key: String, make: @escaping (Int) -> QFQuestion) {
        self.make = make
        super.init(key: key)
    }

    override func onBegin() { nextQuestion() }

    func tickStep() {
        guard phase == .playing, !revealed, perQ > 0 else { return }
        tLeft -= 0.05
        if tLeft <= 0 { choose(-1) }
    }

    func choose(_ i: Int) {
        guard phase == .playing, !revealed else { return }
        revealed = true; chosen = i
        let right = i == question.correct
        if right { hit() } else { miss(reason: i < 0 ? "Out of time!" : "Out of hearts!", delay: 1.4) }
        let delay = right ? 0.45 : 1.3        // a miss lingers so the right answer sinks in
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.phase == .playing, !self.dying else { return }
            self.nextQuestion()
        }
    }

    override func botAct(correct: Bool) {
        guard !revealed, !question.options.isEmpty else { return }
        let wrong = question.options.indices.filter { $0 != question.correct }
        choose(correct || wrong.isEmpty ? question.correct : wrong.randomElement()!)
    }

    private func nextQuestion() {
        question = make(level)
        revealed = false; chosen = nil
        perQ = qfTime(level)
        tLeft = perQ
    }
}

private struct QFOptionButton: View {
    let text: String
    let index: Int
    let revealed: Bool
    let chosen: Int?
    let correct: Int
    let big: Bool
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
                .font(luFont(text.count == 1 ? 56 : (big ? 30 : 22)))   // a lone emoji reads as a picture
                .foregroundStyle(Color(hex: textHex))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: big ? 110 : 80)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(hex: fillHex))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: Lu.line), lineWidth: 2))
                )
                .scaleEffect(revealed && index == correct && chosen != correct ? 1.04 : 1)
                .opacity(revealed && index != correct && index != chosen ? 0.45 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: revealed)
        }
        .buttonStyle(.plain)
        .disabled(revealed)
    }
}

/// A coin drawn as a disc with its value — so young players can count what they see.
struct CoinGlyph: View {
    let cents: Int
    var body: some View {
        let d: CGFloat = [1: 44, 5: 50, 10: 40, 25: 58][cents] ?? 46
        let copper = cents == 1
        Circle()
            .fill(RadialGradient(colors: copper ? [Color(hex: 0xf0b07a), Color(hex: 0xb5673a)]
                                                : [Color(hex: 0xf4f4f0), Color(hex: 0x9a9a92)],
                                 center: UnitPoint(x: 0.35, y: 0.3), startRadius: 1, endRadius: d * 0.7))
            .overlay(Circle().stroke(Color.black.opacity(0.25), lineWidth: 2))
            .overlay(Text("\(cents)¢").font(luFont(d * 0.34)).foregroundStyle(Color(hex: Lu.inkDark)))
            .frame(width: d, height: d)
    }
}

private struct QuickFireView: View {
    @StateObject var engine: QuickFireEngine
    let spec: GameSpec
    let accent: UInt
    let onClose: () -> Void

    private let tick = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ArcadeShell(model: engine, spec: spec, accent: accent, onClose: onClose) {
            VStack(spacing: 14) {
                Color.clear.frame(height: 56)     // under the HUD

                // Timer bar (only once the clock starts at level III)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: Lu.panel))
                        Capsule().fill(Color(hex: engine.tLeft / max(engine.perQ, 0.01) < 0.3 ? Lu.coral : accent))
                            .frame(width: max(0, geo.size.width * CGFloat(min(1, engine.tLeft / max(engine.perQ, 0.01)))))
                    }
                }
                .frame(height: 10)
                .opacity(engine.perQ > 0 ? 1 : 0)

                Spacer(minLength: 8)

                VStack(spacing: 10) {
                    Text(engine.question.topLabel)
                        .font(luSerif(15, .bold)).textCase(.uppercase).tracking(2)
                        .foregroundStyle(Color(hex: Lu.inkDim))
                        .multilineTextAlignment(.center)
                    if let shape = engine.question.shape {
                        CountryContextView(target: shape)
                            .frame(height: 190)
                            .frame(maxWidth: .infinity)
                    } else if let coins = engine.question.coins {
                        let rows = stride(from: 0, to: coins.count, by: 5).map { Array(coins[$0..<min($0 + 5, coins.count)]) }
                        VStack(spacing: 8) {
                            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                                HStack(spacing: 8) { ForEach(Array(row.enumerated()), id: \.offset) { _, c in CoinGlyph(cents: c) } }
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        Text(engine.question.big)
                            .font(luFont(engine.question.big.count > 26 ? 26 : 36))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(Color(hex: Lu.ink))
                    }
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: 130)
                .padding(.vertical, 18)
                .background(luPanelShape(20))

                ZStack {
                    if engine.combo >= 2 {
                        Text("COMBO ×\(engine.combo)!")
                            .font(luFont(18)).foregroundStyle(Color(hex: Lu.mint))
                            .id(engine.combo)
                            .transition(.scale(scale: 1.2).combined(with: .opacity))
                    }
                }
                .frame(height: 24)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: engine.combo)

                Spacer(minLength: 8)

                let n = engine.question.options.count
                let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: n == 3 ? 1 : 2)
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(Array(engine.question.options.enumerated()), id: \.offset) { idx, opt in
                        QFOptionButton(text: opt, index: idx, revealed: engine.revealed,
                                       chosen: engine.chosen, correct: engine.question.correct,
                                       big: n <= 2, action: { engine.choose(idx) })
                    }
                }
                .padding(.bottom, 6)
            }
            .padding(.horizontal, 14).padding(.top, 4)
        }
        .onReceive(tick) { _ in engine.tickStep() }
    }
}

/// Opens a QuickFire game from its catalog entry.
@MainActor private func quickFire(_ id: GameID, accent: UInt, onClose: @escaping () -> Void, make: @escaping (Int) -> QFQuestion) -> some View {
    QuickFireView(engine: QuickFireEngine(key: id.rawValue, make: make),
                  spec: id.spec ?? GameSpec(title: id.rawValue, mechanic: "", premise: "", game: id),
                  accent: accent, onClose: onClose)
}

// MARK: - Games built on QuickFire

// Orbis widens its pool with level, the most recognisable silhouettes first.
private let orbisTier0: [String] = ["United States", "Italy", "Australia", "Brazil", "India", "Japan", "Canada", "Russia"]
private let orbisTier1: Set<String> = Set(orbisTier0).union([
    "France", "United Kingdom", "China", "Egypt", "Mexico", "Spain",
])
private let orbisTier2: Set<String> = orbisTier1.union([
    "Germany", "Argentina", "Chile", "South Africa", "Saudi Arabia", "Turkey",
    "Indonesia", "South Korea", "Portugal", "New Zealand",
])

private func countryQuestion(_ level: Int) -> QFQuestion {
    var pool = GeoShapes.quizPool
    let allowed: Set<String>? = level <= 2 ? Set(orbisTier0) : level <= 4 ? orbisTier1 : level <= 6 ? orbisTier2 : nil
    if let allowed {
        let filtered = pool.filter { allowed.contains($0.name) }
        if filtered.count >= 4 { pool = filtered }
    }
    guard let answer = pool.randomElement() else {
        return QFQuestion(topLabel: "NAME THIS COUNTRY", big: "map unavailable", options: ["—"], correct: 0)
    }
    let (opts, c) = qfOptions(answer.name, pool.map(\.name), qfChoices(level))
    return QFQuestion(topLabel: "NAME THIS COUNTRY", big: "", options: opts, correct: c, shape: answer)
}

struct NameCountryView: View {
    let onClose: () -> Void
    var body: some View { quickFire(.nameCountry, accent: Lu.sky, onClose: onClose, make: countryQuestion) }
}

// True / False: picture facts and tiny sums first; capitals and times tables later.
private let tfPictureFacts: [(String, Bool)] = [
    ("🐟 can swim", true), ("🐘 can fly", false), ("🐦 has wings", true), ("🐄 says moo", true),
    ("🐱 has 4 legs", true), ("🐍 has legs", false), ("🌙 comes out at night", true), ("☀️ is cold", false),
    ("🍌 is yellow", true), ("🍎 is blue", false), ("🐢 is very fast", false), ("❄️ is cold", true),
    ("🐶 says meow", false), ("🐝 makes honey", true), ("🌳 is a tree", true), ("🐸 can jump", true),
]
private let tfFacts: [(String, Bool)] = [
    ("A spider has 8 legs", true), ("Whales are fish", false), ("Bats are mammals", true),
    ("The Sun is a star", true), ("Penguins can fly", false), ("Water freezes at 0 °C", true),
    ("A triangle has 4 sides", false), ("Plants need sunlight", true), ("The Moon makes its own light", false),
    ("There are 7 days in a week", true), ("A year has 10 months", false), ("Ice is lighter than water", true),
]

private func trueFalseQuestion(_ level: Int) -> QFQuestion {
    func sum(_ hi: Int, _ op: String = "+") -> QFQuestion {
        let a = Int.random(in: 1...hi), b = Int.random(in: 1...hi)
        let real = op == "×" ? a * b : a + b
        let shown = Bool.random() ? real : max(0, real + [-2, -1, 1, 2].randomElement()!)
        return QFQuestion(topLabel: "TRUE OR FALSE?", big: "\(a) \(op) \(b) = \(shown)",
                          options: ["TRUE ✓", "FALSE ✗"], correct: shown == real ? 0 : 1)
    }
    func fact(_ pool: [(String, Bool)]) -> QFQuestion {
        let f = pool.randomElement()!
        return QFQuestion(topLabel: "TRUE OR FALSE?", big: f.0, options: ["TRUE ✓", "FALSE ✗"], correct: f.1 ? 0 : 1)
    }
    switch level {
    case 1: return Bool.random() ? fact(tfPictureFacts) : sum(3)
    case 2: return [fact(tfPictureFacts), sum(5), fact(tfFacts)].randomElement()!
    case 3: return Bool.random() ? fact(tfFacts) : sum(9)
    case 4: return [fact(tfFacts), sum(12), sum(5, "×")].randomElement()!
    default:
        if Bool.random() { return sum(level >= 7 ? 12 : 9, "×") }
        let c = Geo.famous.randomElement() ?? Geo.countries[0]
        let cap = Bool.random() ? c.capital : (Geo.famous.randomElement() ?? Geo.countries[0]).capital
        return QFQuestion(topLabel: "TRUE OR FALSE?", big: "\(c.flag)  \(cap) is the capital of \(c.name)",
                          options: ["TRUE ✓", "FALSE ✗"], correct: cap == c.capital ? 0 : 1)
    }
}

struct TrueFalseBlitzView: View {
    let onClose: () -> Void
    var body: some View { quickFire(.trueFalseBlitz, accent: Lu.grape, onClose: onClose, make: trueFalseQuestion) }
}

// Odd One Out: emoji groups first (an animal among fruit), then words, then subtler sets.
private let oooPictures: [(String, [String])] = [
    ("animals", ["🐶", "🐱", "🐮", "🐷", "🐸", "🐵", "🐰", "🦁"]),
    ("fruit", ["🍎", "🍌", "🍇", "🍓", "🍊", "🍐", "🍒", "🍉"]),
    ("vehicles", ["🚗", "🚌", "🚲", "✈️", "🚂", "🚀", "🚜", "⛵️"]),
    ("weather", ["☀️", "🌧️", "❄️", "⛈️", "🌈", "🌪️"]),
    ("sports balls", ["⚽️", "🏀", "🏈", "⚾️", "🎾", "🏐"]),
]
private let oooWords: [(String, [String])] = [
    ("animals", ["dog", "cat", "horse", "cow", "tiger", "rabbit", "bear"]),
    ("fruit", ["apple", "banana", "grape", "orange", "mango", "cherry"]),
    ("colours", ["red", "blue", "green", "yellow", "purple", "orange"]),
    ("numbers", ["one", "two", "three", "five", "seven", "ten"]),
    ("body parts", ["hand", "foot", "nose", "ear", "knee", "elbow"]),
]
private let oooHard: [(String, [String], [String])] = [
    ("Which is NOT even?", ["2", "4", "6", "8", "10", "12", "14", "16"], ["3", "5", "7", "9", "11", "13"]),
    ("Which is NOT a mammal?", ["dog", "whale", "bat", "horse", "human", "dolphin"], ["shark", "eagle", "frog", "snake"]),
    ("Which is NOT a country?", ["France", "Japan", "Brazil", "Kenya", "Canada", "Egypt"], ["Paris", "London", "Rome", "Tokyo"]),
    ("Which is NOT a planet?", ["Mars", "Venus", "Jupiter", "Saturn", "Neptune", "Mercury"], ["the Moon", "the Sun"]),
    ("Which is NOT a shape with 4 sides?", ["square", "rectangle", "rhombus", "trapezoid"], ["triangle", "circle", "pentagon"]),
    ("Which is NOT a verb?", ["run", "jump", "swim", "write", "sing", "climb"], ["chair", "happy", "blue", "river"]),
]

private func oddOneOutQuestion(_ level: Int) -> QFQuestion {
    let n = level <= 1 ? 3 : 4      // three-in-a-group at the start, then four
    if level <= 4 {
        let decks = level <= 2 ? oooPictures : oooWords
        let gi = Int.random(in: 0..<decks.count)
        var oi = Int.random(in: 0..<decks.count)
        while oi == gi { oi = Int.random(in: 0..<decks.count) }
        let odd = decks[oi].1.randomElement()!
        var opts = Array(decks[gi].1.shuffled().prefix(n - 1)) + [odd]
        opts.shuffle()
        return QFQuestion(topLabel: "ODD ONE OUT", big: "Which one does NOT belong?",
                          options: opts, correct: opts.firstIndex(of: odd) ?? 0)
    }
    let g = oooHard.randomElement()!
    let odd = g.2.randomElement()!
    var opts = Array(g.1.shuffled().prefix(3)) + [odd]
    opts.shuffle()
    return QFQuestion(topLabel: "ODD ONE OUT", big: g.0, options: opts, correct: opts.firstIndex(of: odd) ?? 0)
}

struct OddOneOutView: View {
    let onClose: () -> Void
    var body: some View { quickFire(.oddOneOut, accent: Lu.tangerine, onClose: onClose, make: oddOneOutQuestion) }
}

// MARK: History — "Timeline" (which came first)

// (event, year, emoji). Level I compares only things ages apart; later levels bring them closer.
private let timelineEvents: [(String, Int, String)] = [
    ("Dinosaurs", -66_000_000, "🦖"), ("The Pyramids", -2560, "🔺"), ("First Olympics", -776, "🏅"),
    ("Rome is founded", -753, "🏛️"), ("The Great Wall", -220, "🧱"), ("Julius Caesar", -50, "👑"),
    ("Printing press", 1440, "📜"), ("Columbus sails", 1492, "⛵️"), ("The Pilgrims", 1620, "🦃"),
    ("USA is founded", 1776, "🇺🇸"), ("Steam trains", 1825, "🚂"), ("The light bulb", 1879, "💡"),
    ("First airplane", 1903, "✈️"), ("Titanic sinks", 1912, "🚢"), ("First TV", 1927, "📺"),
    ("Moon landing", 1969, "🌕"), ("The Internet", 1983, "🌐"), ("First iPhone", 2007, "📱"),
]

private func timelineQuestion(_ level: Int) -> QFQuestion {
    let n = qfChoices(level)
    // The smallest gap allowed between any two choices shrinks with level.
    let minGap: Int = level <= 1 ? 1500 : level == 2 ? 500 : level <= 4 ? 150 : level <= 6 ? 40 : 10
    var picks: [(String, Int, String)] = []
    for _ in 0..<400 {
        picks = []
        for e in timelineEvents.shuffled() where picks.allSatisfy({ abs($0.1 - e.1) >= minGap }) {
            picks.append(e); if picks.count == n { break }
        }
        if picks.count == n { break }
    }
    let earliest = picks.min(by: { $0.1 < $1.1 })!
    let label: (String, Int, String) -> String = { name, _, emoji in "\(emoji)\n\(name)" }
    let opts = picks.map { label($0.0, $0.1, $0.2) }.shuffled()
    return QFQuestion(topLabel: "WHICH CAME FIRST?", big: "Tap the oldest", options: opts,
                      correct: opts.firstIndex(of: label(earliest.0, earliest.1, earliest.2)) ?? 0)
}

/// Named TimeOrderView (not TimelineView — that collides with SwiftUI.TimelineView).
struct TimeOrderView: View {
    let onClose: () -> Void
    var body: some View { quickFire(.timeline, accent: Lu.tangerine, onClose: onClose, make: timelineQuestion) }
}

// MARK: Money — "Coin Count"

// I: 1–5 pennies (count them) · II: pennies to 10 · III: nickels + pennies · IV: + dimes ·
// V: + quarters · VI+: bigger handfuls.
private func coinCountQuestion(_ level: Int) -> QFQuestion {
    var coins: [Int] = []
    switch level {
    case 1: coins = Array(repeating: 1, count: Int.random(in: 1...5))
    case 2: coins = Array(repeating: 1, count: Int.random(in: 3...10))
    case 3: coins = Array(repeating: 5, count: Int.random(in: 1...2)) + Array(repeating: 1, count: Int.random(in: 0...4))
    case 4: coins = Array(repeating: 10, count: Int.random(in: 1...2)) + Array(repeating: 5, count: Int.random(in: 0...1)) + Array(repeating: 1, count: Int.random(in: 0...4))
    case 5: coins = [25] + Array(repeating: 10, count: Int.random(in: 0...2)) + Array(repeating: 5, count: Int.random(in: 0...1)) + Array(repeating: 1, count: Int.random(in: 0...3))
    default:
        coins = Array(repeating: 25, count: Int.random(in: 1...3)) + Array(repeating: 10, count: Int.random(in: 0...3))
            + Array(repeating: 5, count: Int.random(in: 0...2)) + Array(repeating: 1, count: Int.random(in: 0...4))
    }
    let total = coins.reduce(0, +)
    let near = level <= 2 ? [1, -1, 2, -2, 3] : [1, -1, 5, -5, 10, -10]
    let pool = near.map { total + $0 }.filter { $0 > 0 }.map { "\($0)¢" }
    let (opts, c) = qfOptions("\(total)¢", pool, qfChoices(level))
    return QFQuestion(topLabel: "HOW MUCH MONEY?", big: "", options: opts, correct: c, coins: coins.sorted(by: >))
}

struct CoinCountView: View {
    let onClose: () -> Void
    var body: some View { quickFire(.coinCount, accent: Lu.gold, onClose: onClose, make: coinCountQuestion) }
}

// MARK: Logic — "Pattern Pop" (what comes next)

private let patternEmoji = ["🍎", "🍌", "🐶", "🐱", "⭐️", "🌙", "🔴", "🔵", "🟢", "🟡"]

// I: AB picture patterns · II: ABC / AAB · III: count by 1s and 2s · IV: 5s and 10s ·
// V: any step from any start · VI: counting down · VII+: doubling and growing steps.
private func patternQuestion(_ level: Int) -> QFQuestion {
    let n = qfChoices(level)
    if level <= 2 {
        let syms = Array(patternEmoji.shuffled().prefix(3))
        let unit: [String] = level == 1 ? [syms[0], syms[1]]
            : ([[syms[0], syms[1], syms[2]], [syms[0], syms[0], syms[1]]].randomElement()!)
        let len = unit.count * 2 + Int.random(in: 0..<unit.count)
        let seq = (0..<len).map { unit[$0 % unit.count] }
        let answer = unit[len % unit.count]
        let (opts, c) = qfOptions(answer, syms, n)
        return QFQuestion(topLabel: "WHAT COMES NEXT?", big: seq.joined(separator: " ") + " ❓", options: opts, correct: c)
    }
    var seq: [Int] = []
    switch level {
    case 3: let s = [1, 2].randomElement()!; let a = Int.random(in: 0...6); seq = (0..<5).map { a + $0 * s }
    case 4: let s = [5, 10].randomElement()!; let a = Bool.random() ? 0 : s; seq = (0..<5).map { a + $0 * s }
    case 5: let s = Int.random(in: 2...5); let a = Int.random(in: 1...9); seq = (0..<5).map { a + $0 * s }
    case 6: let s = Int.random(in: 1...5); let a = Int.random(in: 20...40); seq = (0..<5).map { a - $0 * s }
    default:
        if Bool.random() { let a = Int.random(in: 1...3); seq = (0..<5).map { a << $0 } }
        else { let a = Int.random(in: 1...5); seq = (0..<5).map { a + $0 * ($0 + 1) / 2 } }   // +1, +2, +3, …
    }
    let answer = seq.removeLast()
    let pool = [1, -1, 2, -2, 3, 5, -5, 10].map { "\(answer + $0)" }
    let (opts, c) = qfOptions("\(answer)", pool, n)
    return QFQuestion(topLabel: "WHAT COMES NEXT?",
                      big: seq.map(String.init).joined(separator: ",  ") + ",  ?",
                      options: opts, correct: c)
}

struct PatternPopView: View {
    let onClose: () -> Void
    var body: some View { quickFire(.patternPop, accent: Lu.grape, onClose: onClose, make: patternQuestion) }
}
