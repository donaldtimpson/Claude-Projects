import Foundation

// Native Swift reimplementation of the web drill generators (edu-web keeps the
// canonical TS copy in lib/drills). Pure, synchronous, offline — no network.
// Mirrors the web logic: division + inverses (arithmetic), sin/cos/tan over the
// full circle (unit circle), and single-component exact-radical answers (vectors).
// Math renders as clean Unicode (e.g. 3√3, √2/2, π/6) — no KaTeX needed.

enum DrillInput {
    case numeric(answer: Int, unit: String?)   // typed on the keypad (integer, exact)
    case choice(options: [String], correctIndex: Int) // always 4 options
    case mapTap(kind: GeoMapKind)              // tap the named region on the map (target = dedupeKey)
}

// Which bundled atlas a map drill draws (resolved to geometry in the SwiftUI layer).
enum GeoMapKind { case world, usStates }

enum DrillDiagramSpec {
    case vector(angleDeg: Double, component: String)   // "x" or "y"
    case unitCircle(angleDeg: Double, fn: String)      // sin / cos / tan
    case matrix(rows: [[Int]])                         // determinant, drawn with | · | bars
    case matrixVector(matrix: [[Int]], vector: [Int])  // A·v, drawn with [ ] brackets
    case geoMap(kind: GeoMapKind, highlightId: String) // map with one region highlighted
}

struct DrillProblem: Identifiable {
    let id = UUID()
    let prompt: String
    let input: DrillInput
    let explanation: String?
    var diagram: DrillDiagramSpec? = nil
    // Key the "don't repeat the last few questions" guard on this instead of the
    // prompt when the prompt is constant (e.g. map drills all ask "What country…?").
    var dedupeKey: String? = nil
    var identity: String { dedupeKey ?? prompt }
    // Pin the option layout so it doesn't flip question to question. Country names vary
    // in length; force the 2×2 grid (tiles stack the flag over a wrapping name).
    var forceGrid: Bool = false
    // Per-option flag image resource names (e.g. "us-ca") for drills whose flags are
    // images not emoji (US states). Parallel to the choice options.
    var optionImages: [String]? = nil
}

struct DrillDef: Identifiable {
    var id: String { slug }
    let slug: String
    let title: String
    let blurb: String
    let icon: String
    // Number of distinct questions available at a difficulty, for drills with a finite
    // pool (map drills). Enables Practice's "All" length; nil ⇒ procedurally endless.
    var poolSize: ((Int) -> Int)? = nil
    // Learn mode (spaced-repetition) support. `poolItems` lists the stable item ids at a
    // difficulty; `problemForItem` builds the problem for a specific item id. Both nil ⇒
    // the drill can't be Learned (procedural drills with no per-item identity).
    var poolItems: ((Int) -> [String])? = nil
    var problemForItem: ((String, Int) -> DrillProblem)? = nil
    // Present this drill's play screens in landscape (tap-to-locate maps are far wider
    // than tall; the rotated screen gives the map its long dimension as width).
    var landscape: Bool = false
    let generate: (Int) -> DrillProblem
}

// Sample `n` distinct elements from `pool` (already de-duped), excluding none.
private func sampleDistinct<T>(_ pool: [T], _ n: Int) -> [T] {
    Array(pool.shuffled().prefix(n))
}

enum DrillCatalog {
    static let all: [DrillDef] = [
        arithmetic, percentages, orderOfOps, powersOfTwo, squares, gcdDrill, primes,
        sequences, logarithms, derivative, integral,
        determinant, solveSystem, matrixVector, dotProduct, unitCircle, vectors,
        nameCountry, nameState, locateCountry, locateState,
    ]
    static func drill(slug: String) -> DrillDef? { all.first { $0.slug == slug } }

    private static func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }

    // Shuffle "bag" for small discrete domains (powers, squares…): draw the whole
    // range in a random order before any value repeats, so you don't see the same
    // number twice in quick succession. One bag per (drill, level); refills when empty.
    private static var bags: [String: [Int]] = [:]
    private static func draw(_ key: String, _ domain: () -> [Int]) -> Int {
        if bags[key]?.isEmpty ?? true { bags[key] = domain().shuffled() }
        return bags[key]!.removeLast()
    }
    // Clear a map drill's bag so a new session starts a fresh full permutation — makes
    // Practice's "All" cover every region exactly once. Key matches the map drills' bag
    // key ("<slug>-L<level>"); a no-op for drills that key their bag differently.
    static func resetBag(slug: String, level: Int) { bags["\(slug)-L\(level)"] = nil }

    // Difficulty pools for the map drills, shared by generate() and poolSize().
    static func countryPool(_ level: Int) -> [GeoRegion] {
        let all = GeoAtlas.world.askable
        switch level {
        case 1:  return all.filter { ($0.rank <= 2 && !easyRemove.contains($0.name)) || easyAdd.contains($0.name) }
        case 2:  return all.filter { $0.rank <= 3 }
        default: return all
        }
    }
    static func statePool(_ level: Int) -> [GeoRegion] {
        GeoAtlas.usStates.askable.filter { $0.rank <= level }
    }

    // Unicode super/subscripts for exponents and bases (x⁴, log₂).
    private static func sup(_ n: Int) -> String {
        let m: [Character: Character] = ["-": "⁻", "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹"]
        return String(String(n).map { m[$0] ?? $0 })
    }
    private static func sub(_ n: Int) -> String {
        let m: [Character: Character] = ["0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄", "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉"]
        return String(String(n).map { m[$0] ?? $0 })
    }
    // Render c·xⁿ compactly: 12x⁴, 3x, 5 (n=0), x² (c=1), −x³.
    private static func powTerm(_ c: Int, _ n: Int) -> String {
        if n == 0 { return "\(c)" }
        let base = n == 1 ? "x" : "x\(sup(n))"
        if c == 1 { return base }
        if c == -1 { return "−\(base)" }
        return "\(c)\(base)"
    }
    private static func neg(_ x: Int) -> String { String(x).replacingOccurrences(of: "-", with: "−") }

    // Format a x + b y = c with tidy signs (x, −x, 2x; drops zero terms).
    private static func eqn(_ a: Int, _ b: Int, _ c: Int) -> String {
        var s = ""
        if a != 0 { s += a == 1 ? "x" : a == -1 ? "−x" : "\(neg(a))x" }
        if b != 0 {
            let mag = abs(b) == 1 ? "y" : "\(abs(b))y"
            if s.isEmpty { s += b < 0 ? "−\(mag)" : mag }
            else { s += b < 0 ? " − \(mag)" : " + \(mag)" }
        }
        return s + " = \(neg(c))"
    }
    private static func pair(_ x: Int, _ y: Int) -> String { "(\(neg(x)), \(neg(y)))" }

    // Build 4 shuffled options from a correct value + a pool of distractor strings.
    private static func fourChoices(_ correct: String, _ pool: [String]) -> (options: [String], correctIndex: Int) {
        var seen = Set([correct]); var d: [String] = []
        for x in pool where seen.insert(x).inserted { d.append(x); if d.count == 3 { break } }
        var pad = 2
        while d.count < 3 { let f = "\(pad)"; if seen.insert(f).inserted { d.append(f) }; pad += 1 }
        let opts = ([correct] + d).shuffled()
        return (opts, opts.firstIndex(of: correct) ?? 0)
    }
    private static func isPrime(_ n: Int) -> Bool {
        if n < 2 { return false }
        if n < 4 { return true }
        if n % 2 == 0 { return false }
        var i = 3
        while i * i <= n { if n % i == 0 { return false }; i += 2 }
        return true
    }

    // MARK: - Percentages (numeric; clean integer answers)
    static let percentages = DrillDef(
        slug: "percentages",
        title: "Percentages",
        blurb: "Mental percents of a number — tips, discounts, and more.",
        icon: "％"
    ) { level in
        let ps = level == 1 ? [5, 10, 20, 25, 50] : level == 2 ? [5, 10, 15, 20, 25, 50] : [5, 15, 20, 25, 40, 60, 75]
        let p = ps.randomElement()!
        let step = 100 / gcd(p, 100)          // smallest N that keeps the answer whole
        let k = Int.random(in: 2...(level == 1 ? 10 : level == 2 ? 16 : 25))
        let n = step * k
        let answer = p * n / 100
        return DrillProblem(prompt: "\(p)% of \(n)",
                            input: .numeric(answer: answer, unit: nil),
                            explanation: "\(p)% of \(n) = \(answer)")
    }

    // MARK: - Order of operations (numeric; precedence, not left-to-right)
    static let orderOfOps = DrillDef(
        slug: "order-of-operations",
        title: "Order of Operations",
        blurb: "Evaluate expressions with the right precedence (PEMDAS).",
        icon: "🔢"
    ) { level in
        let hi = level == 1 ? 9 : level == 2 ? 12 : 20
        let a = Int.random(in: 2...hi), b = Int.random(in: 2...9), c = Int.random(in: 2...hi)
        // Two shapes so the ×-term lands on either side; answer respects precedence.
        if Bool.random() {
            return DrillProblem(prompt: "\(a) + \(b) × \(c)",
                                input: .numeric(answer: a + b * c, unit: nil),
                                explanation: "\(b) × \(c) first = \(b * c), then + \(a) = \(a + b * c)")
        } else {
            return DrillProblem(prompt: "\(b) × \(c) + \(a)",
                                input: .numeric(answer: b * c + a, unit: nil),
                                explanation: "\(b) × \(c) first = \(b * c), then + \(a) = \(b * c + a)")
        }
    }

    // MARK: - Powers of two (numeric; CS-flavored recall)
    static let powersOfTwo = DrillDef(
        slug: "powers-of-two",
        title: "Powers of Two",
        blurb: "Recall 2ⁿ — the numbers behind bytes, bits, and binary.",
        icon: "⚡️"
    ) { level in
        let maxK = level == 1 ? 8 : level == 2 ? 12 : 16
        let k = draw("pow2_\(level)") { Array(2...maxK) }
        let answer = 1 << k
        return DrillProblem(prompt: "2^\(k)",
                            input: .numeric(answer: answer, unit: nil),
                            explanation: "2^\(k) = \(answer)")
    }

    // MARK: - Squares & roots (numeric)
    static let squares = DrillDef(
        slug: "squares",
        title: "Squares & Roots",
        blurb: "Perfect squares and their roots, on sight.",
        icon: "▧"
    ) { level in
        let hi = level == 1 ? 12 : level == 2 ? 20 : 30
        let n = draw("sq_\(level)") { Array(2...hi) }
        if Bool.random() {
            return DrillProblem(prompt: "\(n)²",
                                input: .numeric(answer: n * n, unit: nil),
                                explanation: "\(n)² = \(n * n)")
        } else {
            return DrillProblem(prompt: "√\(n * n)",
                                input: .numeric(answer: n, unit: nil),
                                explanation: "√\(n * n) = \(n)")
        }
    }

    // MARK: - Prime or composite (choice)
    static let primes = DrillDef(
        slug: "primes",
        title: "Prime or Composite",
        blurb: "Snap-judge whether a number is prime.",
        icon: "🧩"
    ) { level in
        let hi = level == 1 ? 40 : level == 2 ? 80 : 150
        let n = Int.random(in: 2...hi)
        let options = ["Prime", "Composite"]
        let correctIndex = isPrime(n) ? 0 : 1
        var why = ""
        if !isPrime(n) {
            var f = 2
            while f * f <= n { if n % f == 0 { why = " (\(f) × \(n / f))"; break }; f += 1 }
        }
        return DrillProblem(prompt: "Is \(n) prime?",
                            input: .choice(options: options, correctIndex: correctIndex),
                            explanation: "\(n) is \(isPrime(n) ? "prime" : "composite")\(why).")
    }

    // MARK: - Arithmetic (numeric keypad; +, −, ×, ÷ with clean inverses)
    static let arithmetic = DrillDef(
        slug: "arithmetic",
        title: "Mental Arithmetic",
        blurb: "Quick recall of addition, subtraction, multiplication, and division.",
        icon: "🧮"
    ) { level in
        // Per-level ranges (mirror web): additive family for +/−, multiplicative for ×/÷.
        let ops: [String]
        let add: ClosedRange<Int>
        let mulA: ClosedRange<Int>
        let mulB: ClosedRange<Int>
        switch level {
        case 1: ops = ["+", "−", "×"];           add = 1...13;  mulA = 1...6;  mulB = 1...6
        case 2: ops = ["+", "−", "×", "÷"];       add = 1...50;  mulA = 1...13; mulB = 1...13
        default: ops = ["+", "−", "×", "÷"];      add = 1...500; mulA = 1...13; mulB = 11...20
        }
        let op = ops.randomElement()!

        func problem(_ a: Int, _ sym: String, _ b: Int, _ answer: Int) -> DrillProblem {
            DrillProblem(prompt: "\(a) \(sym) \(b)",
                         input: .numeric(answer: answer, unit: nil),
                         explanation: "\(a) \(sym) \(b) = \(answer)")
        }

        switch op {
        case "+":
            let a = Int.random(in: add), b = Int.random(in: add)
            return problem(a, "+", b, a + b)
        case "−":
            // Inverse of a+b: minuend is the sum; subtract one operand back out.
            let a = Int.random(in: add), b = Int.random(in: add)
            let sum = a + b
            let sub = Bool.random() ? a : b
            return problem(sum, "−", sub, sum - sub)
        case "×":
            let a = Int.random(in: mulA), b = Int.random(in: mulB)
            return problem(a, "×", b, a * b)
        default: // ÷ — inverse of a×b: dividend is the product; divide by one operand.
            let a = Int.random(in: mulA), b = Int.random(in: mulB)
            let product = a * b
            let divisor = Bool.random() ? a : b
            return problem(product, "÷", divisor, product / divisor)
        }
    }

    // MARK: - Logarithms (numeric keypad; log_b(bᵏ) = k)
    static let logarithms = DrillDef(
        slug: "logarithms",
        title: "Logarithms",
        blurb: "Evaluate a logarithm — the exponent that gets you there.",
        icon: "㏒"
    ) { level in
        let bases = level == 1 ? [2] : level == 2 ? [2, 3] : [2, 3, 5, 10]
        let b = bases.randomElement()!
        let maxK = b == 2 ? (level == 1 ? 8 : 12) : b == 3 ? 5 : 4
        let k = draw("log_\(b)_\(level)") { Array(1...maxK) }
        let value = Int(pow(Double(b), Double(k)))
        return DrillProblem(prompt: "log\(sub(b))(\(value))",
                            input: .numeric(answer: k, unit: nil),
                            explanation: "\(b)^\(k) = \(value), so log\(sub(b))(\(value)) = \(k)")
    }

    // MARK: - Greatest common divisor (numeric)
    static let gcdDrill = DrillDef(
        slug: "gcd",
        title: "Greatest Common Divisor",
        blurb: "Find the largest number that divides both.",
        icon: "∩"
    ) { level in
        let hi = level == 1 ? 20 : level == 2 ? 60 : 120
        let a = Int.random(in: 2...hi), b = Int.random(in: 2...hi)
        return DrillProblem(prompt: "gcd(\(a), \(b))",
                            input: .numeric(answer: gcd(a, b), unit: nil),
                            explanation: "gcd(\(a), \(b)) = \(gcd(a, b))")
    }

    // MARK: - Next in sequence (numeric; arithmetic or geometric)
    static let sequences = DrillDef(
        slug: "sequences",
        title: "Next in Sequence",
        blurb: "Spot the pattern and give the next term.",
        icon: "🔗"
    ) { level in
        if Bool.random() {
            let a = Int.random(in: 1...9), d = Int.random(in: 2...(level == 1 ? 5 : 9))
            let terms = (0..<4).map { a + $0 * d }
            return DrillProblem(prompt: "\(terms.map(String.init).joined(separator: ",  ")),  ?",
                                input: .numeric(answer: a + 4 * d, unit: nil),
                                explanation: "Arithmetic, +\(d) each step → \(a + 4 * d)")
        } else {
            let a = Int.random(in: 1...4), r = Int.random(in: 2...(level == 1 ? 3 : 4))
            let terms = (0..<4).map { a * Int(pow(Double(r), Double($0))) }
            return DrillProblem(prompt: "\(terms.map(String.init).joined(separator: ",  ")),  ?",
                                input: .numeric(answer: a * Int(pow(Double(r), 4)), unit: nil),
                                explanation: "Geometric, ×\(r) each step → \(a * Int(pow(Double(r), 4)))")
        }
    }

    // MARK: - Derivatives (choice; power rule on c·xⁿ)
    static let derivative = DrillDef(
        slug: "derivative",
        title: "Derivatives",
        blurb: "Differentiate c·xⁿ with the power rule.",
        icon: "ƒ′"
    ) { level in
        let n = Int.random(in: 2...(level == 1 ? 5 : level == 2 ? 7 : 9))
        let c = level == 1 ? Int.random(in: 1...5) : Int.random(in: 2...9)
        let correct = powTerm(c * n, n - 1)
        let (options, correctIndex) = fourChoices(correct, [
            powTerm(c, n),            // forgot to differentiate
            powTerm(c * n, n),        // forgot to drop the power
            powTerm(c, n - 1),        // forgot the coefficient factor
            powTerm(c * (n - 1), n - 1),
        ])
        return DrillProblem(prompt: "d/dx (\(powTerm(c, n)))",
                            input: .choice(options: options, correctIndex: correctIndex),
                            explanation: "Bring down \(n), reduce the power: \(correct)")
    }

    // MARK: - Integrals (choice; power rule + C)
    static let integral = DrillDef(
        slug: "integral",
        title: "Integrals",
        blurb: "Integrate c·xⁿ with the power rule — don't forget + C.",
        icon: "∫"
    ) { level in
        let n = Int.random(in: 1...(level == 1 ? 4 : level == 2 ? 6 : 8))
        let m = n + 1
        let k = level == 1 ? Int.random(in: 1...3) : Int.random(in: 1...5)
        let c = k * m
        // Every option carries + C, so it's never a giveaway.
        let correct = "\(powTerm(k, m)) + C"
        let (options, correctIndex) = fourChoices(correct, [
            "\(powTerm(c, m)) + C",       // forgot to divide by the new power
            "\(powTerm(k, n)) + C",       // didn't raise the power
            "\(powTerm(k, m + 1)) + C",   // raised the power too far
            "\(powTerm(c, n)) + C",       // both mistakes
        ])
        return DrillProblem(prompt: "∫ \(powTerm(c, n)) dx",
                            input: .choice(options: options, correctIndex: correctIndex),
                            explanation: "Raise the power, divide by it: \(correct)")
    }

    // MARK: - 2×2 Determinant (choice; ad − bc, with a rendered matrix)
    static let determinant = DrillDef(
        slug: "determinant",
        title: "2×2 Determinant",
        blurb: "Compute ad − bc for a 2×2 matrix.",
        icon: "▦"
    ) { level in
        let range = level == 1 ? 1...6 : level == 2 ? -6...9 : -12...12
        func e() -> Int { Int.random(in: range) }
        let a = e(), b = e(), c = e(), d = e()
        let det = a * d - b * c
        let (options, correctIndex) = fourChoices(neg(det), [
            neg(a * d + b * c),   // sign slip on the second product
            neg(b * c - a * d),   // reversed (−det)
            neg(a * b - c * d),   // multiplied the wrong pairs
            neg(det + 3), neg(det - 4),
        ])
        return DrillProblem(prompt: "Determinant = ?",
                            input: .choice(options: options, correctIndex: correctIndex),
                            explanation: "ad − bc = (\(a))(\(d)) − (\(b))(\(c)) = \(neg(det))",
                            diagram: .matrix(rows: [[a, b], [c, d]]))
    }

    // MARK: - Solve a 2×2 system (choice; pick the (x, y) that satisfies both)
    static let solveSystem = DrillDef(
        slug: "solve-system",
        title: "Solve the System",
        blurb: "Two equations, two unknowns — find the (x, y) that works.",
        icon: "⊞"
    ) { level in
        let solR = level == 1 ? 0...4 : level == 2 ? -3...4 : -5...5
        let coefR = level == 1 ? [-2, -1, 1, 2] : [-3, -2, -1, 1, 2, 3]
        let x = Int.random(in: solR), y = Int.random(in: solR)
        var a1 = 1, b1 = 1, a2 = 1, b2 = 1
        repeat {
            a1 = coefR.randomElement()!; b1 = coefR.randomElement()!
            a2 = coefR.randomElement()!; b2 = coefR.randomElement()!
        } while a1 * b2 - a2 * b1 == 0   // must be independent
        let c1 = a1 * x + b1 * y, c2 = a2 * x + b2 * y
        let (options, correctIndex) = fourChoices(pair(x, y), [
            pair(y, x),          // swapped x and y
            pair(-x, y), pair(x, -y),   // sign slips
            pair(x + 1, y - 1),
        ])
        return DrillProblem(prompt: "\(eqn(a1, b1, c1))\n\(eqn(a2, b2, c2))\n\nSolve for (x, y)",
                            input: .choice(options: options, correctIndex: correctIndex),
                            explanation: "x = \(neg(x)), y = \(neg(y)) satisfies both equations.")
    }

    // MARK: - Matrix × vector (choice; A·v for a 2×2 and a 2-vector)
    static let matrixVector = DrillDef(
        slug: "matrix-vector",
        title: "Matrix × Vector",
        blurb: "Multiply a 2×2 matrix by a vector — rows dotted with the vector.",
        icon: "⧉"
    ) { level in
        let r = level == 1 ? -2...3 : level == 2 ? -3...4 : -5...5
        func e() -> Int { Int.random(in: r) }
        let a = e(), b = e(), c = e(), d = e(), x = e(), y = e()
        let p = a * x + b * y, q = c * x + d * y
        let (options, correctIndex) = fourChoices(pair(p, q), [
            pair(a * x, d * y),   // multiplied component-wise (the classic mistake)
            pair(q, p),           // rows swapped
            pair(a * x + b * y, c * x - d * y),
            pair(p + 1, q),
        ])
        return DrillProblem(prompt: "A·v = ?",
                            input: .choice(options: options, correctIndex: correctIndex),
                            explanation: "Row 1 · v = \(neg(p)),  Row 2 · v = \(neg(q))",
                            diagram: .matrixVector(matrix: [[a, b], [c, d]], vector: [x, y]))
    }

    // MARK: - Dot product (choice; scalar result, can be negative)
    static let dotProduct = DrillDef(
        slug: "dot-product",
        title: "Dot Product",
        blurb: "Multiply matching components and add them up.",
        icon: "•"
    ) { level in
        let r = level == 1 ? -3...4 : level == 2 ? -5...6 : -8...8
        func e() -> Int { Int.random(in: r) }
        let a1 = e(), a2 = e(), b1 = e(), b2 = e()
        let dot = a1 * b1 + a2 * b2
        let (options, correctIndex) = fourChoices(neg(dot), [
            neg(a1 * b1 - a2 * b2),   // subtracted instead of added
            neg(a1 * b2 + a2 * b1),   // paired the wrong components
            neg(dot + 2), neg(dot - 3),
        ])
        return DrillProblem(prompt: "(\(neg(a1)), \(neg(a2))) · (\(neg(b1)), \(neg(b2))) = ?",
                            input: .choice(options: options, correctIndex: correctIndex),
                            explanation: "(\(neg(a1)))(\(neg(b1))) + (\(neg(a2)))(\(neg(b2))) = \(neg(dot))")
    }

    // MARK: - Unit circle (choice; sin/cos/tan at standard angles, exact values)
    private struct Angle { let display: String; let deg: Double; let sin: String; let cos: String; let tan: String }
    // 16 standard angles with exact-value KEYS (also used as display strings).
    private static let angles: [Angle] = [
        Angle(display: "0",      deg: 0,   sin: "0",     cos: "1",     tan: "0"),
        Angle(display: "π/6",    deg: 30,  sin: "1/2",   cos: "√3/2",  tan: "√3/3"),
        Angle(display: "π/4",    deg: 45,  sin: "√2/2",  cos: "√2/2",  tan: "1"),
        Angle(display: "π/3",    deg: 60,  sin: "√3/2",  cos: "1/2",   tan: "√3"),
        Angle(display: "π/2",    deg: 90,  sin: "1",     cos: "0",     tan: "undefined"),
        Angle(display: "2π/3",   deg: 120, sin: "√3/2",  cos: "−1/2",  tan: "−√3"),
        Angle(display: "3π/4",   deg: 135, sin: "√2/2",  cos: "−√2/2", tan: "−1"),
        Angle(display: "5π/6",   deg: 150, sin: "1/2",   cos: "−√3/2", tan: "−√3/3"),
        Angle(display: "π",      deg: 180, sin: "0",     cos: "−1",    tan: "0"),
        Angle(display: "7π/6",   deg: 210, sin: "−1/2",  cos: "−√3/2", tan: "√3/3"),
        Angle(display: "5π/4",   deg: 225, sin: "−√2/2", cos: "−√2/2", tan: "1"),
        Angle(display: "4π/3",   deg: 240, sin: "−√3/2", cos: "−1/2",  tan: "√3"),
        Angle(display: "3π/2",   deg: 270, sin: "−1",    cos: "0",     tan: "undefined"),
        Angle(display: "5π/3",   deg: 300, sin: "−√3/2", cos: "1/2",   tan: "−√3"),
        Angle(display: "7π/4",   deg: 315, sin: "−√2/2", cos: "√2/2",  tan: "−1"),
        Angle(display: "11π/6",  deg: 330, sin: "−1/2",  cos: "√3/2",  tan: "−√3/3"),
    ]
    private static let sinCosPool = ["0", "1", "−1", "1/2", "−1/2", "√2/2", "−√2/2", "√3/2", "−√3/2"]
    private static let tanPool = ["0", "1", "−1", "√3/3", "−√3/3", "√3", "−√3", "undefined"]

    static let unitCircle = DrillDef(
        slug: "unit-circle",
        title: "Unit Circle",
        blurb: "Recall exact sine, cosine, and tangent values at standard angles.",
        icon: "🔵"
    ) { level in
        let fns = level == 1 ? ["sin", "cos"] : ["sin", "cos", "tan"]
        let angleCount = level == 1 ? 5 : level == 2 ? 9 : angles.count
        let angle = angles[Int.random(in: 0..<angleCount)]
        let fn = fns.randomElement()!
        let correct = fn == "sin" ? angle.sin : fn == "cos" ? angle.cos : angle.tan
        let pool = (fn == "tan" ? tanPool : sinCosPool).filter { $0 != correct }
        let options = ([correct] + sampleDistinct(pool, 3)).shuffled()
        return DrillProblem(
            prompt: "\(fn)(\(angle.display)) = ?",
            input: .choice(options: options, correctIndex: options.firstIndex(of: correct) ?? 0),
            explanation: "\(fn)(\(angle.display)) = \(correct)",
            diagram: .unitCircle(angleDeg: angle.deg, fn: fn)
        )
    }

    // MARK: - Vectors (choice; pick ONE component as an exact radical)
    private struct AngleRow { let deg: Int; let cos: String; let sin: String }
    private static let vecAngles: [AngleRow] = [
        AngleRow(deg: 0, cos: "1", sin: "0"),
        AngleRow(deg: 30, cos: "√3/2", sin: "1/2"),
        AngleRow(deg: 45, cos: "√2/2", sin: "√2/2"),
        AngleRow(deg: 60, cos: "1/2", sin: "√3/2"),
        AngleRow(deg: 90, cos: "0", sin: "1"),
        AngleRow(deg: 120, cos: "−1/2", sin: "√3/2"),
        AngleRow(deg: 135, cos: "−√2/2", sin: "√2/2"),
        AngleRow(deg: 150, cos: "−√3/2", sin: "1/2"),
        AngleRow(deg: 180, cos: "−1", sin: "0"),
        AngleRow(deg: 210, cos: "−√3/2", sin: "−1/2"),
        AngleRow(deg: 225, cos: "−√2/2", sin: "−√2/2"),
        AngleRow(deg: 240, cos: "−1/2", sin: "−√3/2"),
        AngleRow(deg: 270, cos: "0", sin: "−1"),
        AngleRow(deg: 300, cos: "1/2", sin: "−√3/2"),
        AngleRow(deg: 315, cos: "√2/2", sin: "−√2/2"),
        AngleRow(deg: 330, cos: "√3/2", sin: "−1/2"),
    ]

    // An exact component = coeff·√root (root 1 ⇒ plain integer). Keyed for de-dupe.
    private struct Comp: Equatable { let coeff: Int; let root: Int }
    private static func scale(_ token: String, _ k: Int) -> Comp {
        switch token {
        case "1": return Comp(coeff: 2 * k, root: 1)
        case "−1": return Comp(coeff: -2 * k, root: 1)
        case "1/2": return Comp(coeff: k, root: 1)
        case "−1/2": return Comp(coeff: -k, root: 1)
        case "√2/2": return Comp(coeff: k, root: 2)
        case "−√2/2": return Comp(coeff: -k, root: 2)
        case "√3/2": return Comp(coeff: k, root: 3)
        case "−√3/2": return Comp(coeff: -k, root: 3)
        default: return Comp(coeff: 0, root: 1) // "0"
        }
    }
    private static func compDisplay(_ c: Comp) -> String {
        if c.coeff == 0 { return "0" }
        if c.root == 1 { return "\(c.coeff)" }
        let r = c.root == 2 ? "√2" : "√3"
        if c.coeff == 1 { return r }
        if c.coeff == -1 { return "−\(r)" }
        return "\(c.coeff)\(r)"
    }

    static let vectors = DrillDef(
        slug: "vectors",
        title: "Vector Components",
        blurb: "Find a vector's x or y component at common angles — exact values, no calculator.",
        icon: "➹"
    ) { level in
        let kRange = level == 1 ? 1...5 : level == 2 ? 1...6 : 2...8
        let angleCount = level == 1 ? 5 : level == 2 ? 9 : vecAngles.count
        let k = Int.random(in: kRange)
        let r = 2 * k
        let angle = vecAngles[Int.random(in: 0..<angleCount)]
        let axis = Bool.random() ? "x" : "y"
        let correct = scale(axis == "x" ? angle.cos : angle.sin, k)

        // Plausible exact distractors: values components of THIS magnitude can take.
        let poolComps = [
            Comp(coeff: 0, root: 1),
            Comp(coeff: k, root: 1), Comp(coeff: -k, root: 1),
            Comp(coeff: 2 * k, root: 1), Comp(coeff: -2 * k, root: 1),
            Comp(coeff: k, root: 2), Comp(coeff: -k, root: 2),
            Comp(coeff: k, root: 3), Comp(coeff: -k, root: 3),
        ].filter { $0 != correct }
        var seen = Set<String>()
        let dedup = poolComps.filter { seen.insert("\($0.coeff)_\($0.root)").inserted }
        let optionComps = ([correct] + sampleDistinct(dedup, 3)).shuffled()
        let options = optionComps.map(compDisplay)
        let correctIndex = optionComps.firstIndex(of: correct) ?? 0

        let fn = axis == "x" ? "cos" : "sin"
        return DrillProblem(
            prompt: "|v| = \(r),  θ = \(angle.deg)°\n\(axis)-component = ?",
            input: .choice(options: options, correctIndex: correctIndex),
            explanation: "\(axis)-component = \(r)·\(fn)(\(angle.deg)°) = \(compDisplay(correct))",
            diagram: .vector(angleDeg: Double(angle.deg), component: axis)
        )
    }

    // MARK: - Name the Country (choice; identify the highlighted country on a world map)
    // Hand-curated tweaks to the Easy tier, since LABELRANK prominence isn't a perfect
    // "how famous" score. Removed countries still appear on Medium/Hard.
    private static let easyRemove: Set<String> = ["Kenya", "Democratic Republic of the Congo", "Ethiopia"]
    private static let easyAdd: Set<String> = ["Iceland", "Ireland", "Greece"]

    // Build a map-drill problem for a specific target region: 3 same-group distractors
    // (continent for countries, US region for states), shuffled options, flag on each.
    // `flags` = emoji flag baked into the label (countries) or image names (states).
    private static func mapProblem(target: GeoRegion, pool all: [GeoRegion], kind: GeoMapKind,
                                   emojiFlag: Bool, imageFlag: Bool) -> DrillProblem {
        let sameGroup = all.filter { $0.continent == target.continent && $0.id != target.id }
        var distractors: [GeoRegion] = []
        var seen: Set<String> = [target.id]
        for r in sameGroup.shuffled() + all.shuffled() {
            if seen.insert(r.id).inserted { distractors.append(r) }
            if distractors.count == 3 { break }
        }
        func label(_ r: GeoRegion) -> String {
            emojiFlag && !r.flag.isEmpty ? "\(r.flag) \(r.name)" : r.name
        }
        let picks = ([target] + distractors).shuffled()
        return DrillProblem(
            prompt: "",   // the map IS the question; the nav title names the drill
            input: .choice(options: picks.map(label), correctIndex: picks.firstIndex { $0.id == target.id } ?? 0),
            explanation: "\(label(target)) — \(target.continent).",
            diagram: .geoMap(kind: kind, highlightId: target.id),
            dedupeKey: target.id,
            forceGrid: true,
            optionImages: imageFlag ? picks.map { "us-\(($0.iso ?? "").lowercased())" } : nil
        )
    }

    private static func countryProblem(_ target: GeoRegion) -> DrillProblem {
        mapProblem(target: target, pool: GeoAtlas.world.askable, kind: .world, emojiFlag: true, imageFlag: false)
    }
    private static func stateProblem(_ target: GeoRegion) -> DrillProblem {
        mapProblem(target: target, pool: GeoAtlas.usStates.askable, kind: .usStates, emojiFlag: false, imageFlag: true)
    }

    static let nameCountry = DrillDef(
        slug: "name-country",
        title: "Name the Country",
        blurb: "Identify the highlighted country on the world map.",
        icon: "🌍",
        poolSize: { countryPool($0).count },
        poolItems: { countryPool($0).map(\.id) },
        problemForItem: { id, _ in countryProblem(GeoAtlas.world.region(id) ?? GeoAtlas.world.askable[0]) }
    ) { level in
        // Difficulty = how obscure the target can be (see countryPool). Draw from a
        // shuffle bag so a quiz cycles the whole pool before repeating.
        let pool = countryPool(level)
        let target = pool.isEmpty ? GeoAtlas.world.askable.randomElement()!
            : pool[draw("name-country-L\(level)") { Array(0..<pool.count) }]
        return countryProblem(target)
    }

    // MARK: - Name the State (choice; identify the highlighted U.S. state, with rivers)
    static let nameState = DrillDef(
        slug: "name-state",
        title: "Name the State",
        blurb: "Identify the highlighted U.S. state — major rivers drawn in for context.",
        icon: "🗺️",
        poolSize: { statePool($0).count },
        poolItems: { statePool($0).map(\.id) },
        problemForItem: { id, _ in stateProblem(GeoAtlas.usStates.region(id) ?? GeoAtlas.usStates.askable[0]) }
    ) { level in
        // Difficulty by size tier (see statePool).
        let pool = statePool(level)
        let target = pool.isEmpty ? GeoAtlas.usStates.askable.randomElement()!
            : pool[draw("name-state-L\(level)") { Array(0..<pool.count) }]
        return stateProblem(target)
    }

    // MARK: - Locate (tap-to-find; the named region must be tapped on the map)
    private static func locateProblem(_ target: GeoRegion, kind: GeoMapKind) -> DrillProblem {
        DrillProblem(
            prompt: target.name,              // shown as "Find <name>" by the map-tap UI
            input: .mapTap(kind: kind),
            explanation: "\(target.name) — \(target.continent).",
            dedupeKey: target.id              // the region to tap
        )
    }

    static let locateCountry = DrillDef(
        slug: "locate-country",
        title: "Where's the Country?",
        blurb: "Find the named country on the world map — tap it.",
        icon: "🧭",
        poolSize: { countryPool($0).count },
        poolItems: { countryPool($0).map(\.id) },
        problemForItem: { id, _ in locateProblem(GeoAtlas.world.region(id) ?? GeoAtlas.world.askable[0], kind: .world) },
        landscape: true
    ) { level in
        let pool = countryPool(level)
        let target = pool.isEmpty ? GeoAtlas.world.askable.randomElement()!
            : pool[draw("locate-country-L\(level)") { Array(0..<pool.count) }]
        return locateProblem(target, kind: .world)
    }

    static let locateState = DrillDef(
        slug: "locate-state",
        title: "Where's the State?",
        blurb: "Find the named U.S. state — tap it.",
        icon: "📍",
        poolSize: { statePool($0).count },
        poolItems: { statePool($0).map(\.id) },
        problemForItem: { id, _ in locateProblem(GeoAtlas.usStates.region(id) ?? GeoAtlas.usStates.askable[0], kind: .usStates) },
        landscape: true
    ) { level in
        let pool = statePool(level)
        let target = pool.isEmpty ? GeoAtlas.usStates.askable.randomElement()!
            : pool[draw("locate-state-L\(level)") { Array(0..<pool.count) }]
        return locateProblem(target, kind: .usStates)
    }
}
