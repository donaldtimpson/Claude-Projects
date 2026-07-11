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

struct DrillProblem: Identifiable {
    let id = UUID()
    let prompt: String
    let input: DrillInput
    let explanation: String?
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
    static let all: [DrillDef] = [arithmetic, unitCircle, vectors]
    static func drill(slug: String) -> DrillDef? { all.first { $0.slug == slug } }

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
    private struct Angle { let display: String; let sin: String; let cos: String; let tan: String }
    // 16 standard angles with exact-value KEYS (also used as display strings).
    private static let angles: [Angle] = [
        Angle(display: "0",      sin: "0",     cos: "1",     tan: "0"),
        Angle(display: "π/6",    sin: "1/2",   cos: "√3/2",  tan: "√3/3"),
        Angle(display: "π/4",    sin: "√2/2",  cos: "√2/2",  tan: "1"),
        Angle(display: "π/3",    sin: "√3/2",  cos: "1/2",   tan: "√3"),
        Angle(display: "π/2",    sin: "1",     cos: "0",     tan: "undefined"),
        Angle(display: "2π/3",   sin: "√3/2",  cos: "−1/2",  tan: "−√3"),
        Angle(display: "3π/4",   sin: "√2/2",  cos: "−√2/2", tan: "−1"),
        Angle(display: "5π/6",   sin: "1/2",   cos: "−√3/2", tan: "−√3/3"),
        Angle(display: "π",      sin: "0",     cos: "−1",    tan: "0"),
        Angle(display: "7π/6",   sin: "−1/2",  cos: "−√3/2", tan: "√3/3"),
        Angle(display: "5π/4",   sin: "−√2/2", cos: "−√2/2", tan: "1"),
        Angle(display: "4π/3",   sin: "−√3/2", cos: "−1/2",  tan: "√3"),
        Angle(display: "3π/2",   sin: "−1",    cos: "0",     tan: "undefined"),
        Angle(display: "5π/3",   sin: "−√3/2", cos: "1/2",   tan: "−√3"),
        Angle(display: "7π/4",   sin: "−√2/2", cos: "√2/2",  tan: "−1"),
        Angle(display: "11π/6",  sin: "−1/2",  cos: "√3/2",  tan: "−√3/3"),
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
            explanation: "\(fn)(\(angle.display)) = \(correct)"
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
            explanation: "\(axis)-component = \(r)·\(fn)(\(angle.deg)°) = \(compDisplay(correct))"
        )
    }
}
