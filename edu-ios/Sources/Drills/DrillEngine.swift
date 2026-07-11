import Foundation

// Native Swift reimplementation of the drill generators (the web app keeps its
// own TS copy in lib/drills). Pure, synchronous, offline — no network.

enum DrillInput {
    // Integer numeric answer, entered on the custom keypad (non-negative).
    case numeric(answer: Int, unit: String?)
    case choice(options: [String], correctIndex: Int)
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

enum DrillCatalog {
    static let all: [DrillDef] = [arithmetic, unitCircle, vectors]

    static func drill(slug: String) -> DrillDef? { all.first { $0.slug == slug } }

    // MARK: arithmetic (numeric keypad)
    static let arithmetic = DrillDef(
        slug: "arithmetic",
        title: "Arithmetic",
        blurb: "Fast mental addition, subtraction, and multiplication.",
        icon: "🧮"
    ) { level in
        let ops: [(String, (Int, Int) -> Int)] = [("+", (+)), ("−", (-)), ("×", (*))]
        let (symbol, fn) = ops.randomElement()!
        let bound = level == 1 ? 12 : level == 2 ? 40 : 120
        var a = Int.random(in: 2...bound)
        var b = Int.random(in: 2...bound)
        // Keep subtraction non-negative so the keypad needs no minus sign.
        if symbol == "−", a < b { swap(&a, &b) }
        let answer = fn(a, b)
        return DrillProblem(
            prompt: "\(a) \(symbol) \(b)",
            input: .numeric(answer: answer, unit: nil),
            explanation: "\(a) \(symbol) \(b) = \(answer)"
        )
    }

    // MARK: unit circle (choice)
    static let unitCircle = DrillDef(
        slug: "unit-circle",
        title: "Unit Circle",
        blurb: "Recall exact sine and cosine values.",
        icon: "🌀"
    ) { _ in
        let angles: [(label: String, sin: String, cos: String)] = [
            ("0", "0", "1"),
            ("π/6", "1/2", "√3/2"),
            ("π/4", "√2/2", "√2/2"),
            ("π/3", "√3/2", "1/2"),
            ("π/2", "1", "0"),
        ]
        let choices = ["0", "1/2", "√2/2", "√3/2", "1"]
        let angle = angles.randomElement()!
        let useSin = Bool.random()
        let correctValue = useSin ? angle.sin : angle.cos
        let correctIndex = choices.firstIndex(of: correctValue) ?? 0
        let fn = useSin ? "sin" : "cos"
        return DrillProblem(
            prompt: "\(fn)(\(angle.label)) = ?",
            input: .choice(options: choices, correctIndex: correctIndex),
            explanation: "\(fn)(\(angle.label)) = \(correctValue)"
        )
    }

    // MARK: vectors (choice — pick the correct components)
    static let vectors = DrillDef(
        slug: "vectors",
        title: "Vectors",
        blurb: "Resolve a vector into its x and y components.",
        icon: "➡️"
    ) { level in
        let magnitude = Double(Int.random(in: 2...(level == 1 ? 10 : 20)))
        let angleDeg = Double([0, 30, 45, 60, 90].randomElement()!)
        let rad = angleDeg * .pi / 180
        let vx = magnitude * cos(rad)
        let vy = magnitude * sin(rad)

        func fmt(_ x: Double, _ y: Double) -> String {
            String(format: "(%.2f, %.2f)", x, y)
        }
        let correct = fmt(vx, vy)
        // Distractors: swapped components (sin/cos mix-up), and each axis zeroed —
        // the classic mistakes. De-duped against the correct answer.
        var options = Set<String>([correct])
        for candidate in [fmt(vy, vx), fmt(vx, -vy), fmt(magnitude, 0), fmt(0, magnitude)] {
            if options.count >= 4 { break }
            options.insert(candidate)
        }
        // Pad (rare, e.g. angle 45° makes vx==vy) so there are always four choices.
        var pad = 1
        while options.count < 4 {
            options.insert(fmt(vx + Double(pad), vy - Double(pad)))
            pad += 1
        }
        let shuffled = options.shuffled()
        let correctIndex = shuffled.firstIndex(of: correct) ?? 0
        return DrillProblem(
            prompt: "A vector has magnitude \(Int(magnitude)) at \(Int(angleDeg))°. Find its components (vₓ, v_y).",
            input: .choice(options: shuffled, correctIndex: correctIndex),
            explanation: String(
                format: "vₓ = %.0f·cos(%.0f°) = %.2f,  v_y = %.0f·sin(%.0f°) = %.2f",
                magnitude, angleDeg, vx, magnitude, angleDeg, vy
            )
        )
    }
}
