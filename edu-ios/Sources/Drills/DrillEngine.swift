import Foundation

// Native Swift reimplementation of the web drill generators (edu-web keeps the
// canonical TS copy in lib/drills). Pure, synchronous, offline — no network.
// Mirrors the web logic: division + inverses (arithmetic), sin/cos/tan over the
// full circle (unit circle), and single-component exact-radical answers (vectors).
// Math renders as clean Unicode (e.g. 3√3, √2/2, π/6) — no KaTeX needed.

enum DrillInput {
    case numeric(answer: Int, unit: String?)   // typed on the keypad (integer, exact)
    case choice(options: [String], correctIndex: Int) // always 4 options
}

enum DrillDiagramSpec {
    case vector(angleDeg: Double, component: String)   // "x" or "y"
    case unitCircle(angleDeg: Double, fn: String)      // sin / cos / tan
}

struct DrillProblem: Identifiable {
    let id = UUID()
    let prompt: String
    let input: DrillInput
    let explanation: String?
    var diagram: DrillDiagramSpec? = nil
}

struct DrillDef: Identifiable {
    var id: String { slug }
    let slug: String
    let title: String
    let blurb: String
    let icon: String
    let generate: (Int) -> DrillProblem
}

// Sample `n` distinct elements from `pool` (already de-duped), excluding none.
private func sampleDistinct<T>(_ pool: [T], _ n: Int) -> [T] {
    Array(pool.shuffled().prefix(n))
}

enum DrillCatalog {
    static let all: [DrillDef] = [
        arithmetic, percentages, orderOfOps, powersOfTwo, squares, primes, unitCircle, vectors,
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
}
