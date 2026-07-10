import Foundation

// Native Swift reimplementation of the drill generators (the web app keeps its
// own TS copy in lib/drills). Pure, synchronous, offline — no network.

enum DrillInput {
    case numeric(answer: Double, tolerance: Double, unit: String?)
    case choice(options: [String], correctIndex: Int)
    case fields([DrillField])
}

struct DrillField: Identifiable {
    let id = UUID()
    let label: String
    let answer: Double
    let tolerance: Double
    let unit: String?
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

    // MARK: arithmetic (numeric)
    static let arithmetic = DrillDef(
        slug: "arithmetic",
        title: "Arithmetic",
        blurb: "Fast mental addition, subtraction, and multiplication.",
        icon: "🧮"
    ) { level in
        let ops: [(String, (Int, Int) -> Int)] = [("+", (+)), ("−", (-)), ("×", (*))]
        let (symbol, fn) = ops.randomElement()!
        let bound = level == 1 ? 12 : level == 2 ? 40 : 120
        let a = Int.random(in: 2...bound)
        let b = Int.random(in: 2...bound)
        let answer = fn(a, b)
        return DrillProblem(
            prompt: "\(a) \(symbol) \(b)",
            input: .numeric(answer: Double(answer), tolerance: 0, unit: nil),
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

    // MARK: vectors (fields — components from magnitude & angle)
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
        return DrillProblem(
            prompt: "A vector has magnitude \(Int(magnitude)) at \(Int(angleDeg))°. Find its components.",
            input: .fields([
                DrillField(label: "vₓ", answer: vx, tolerance: 0.1, unit: nil),
                DrillField(label: "v_y", answer: vy, tolerance: 0.1, unit: nil),
            ]),
            explanation: String(
                format: "vₓ = %.0f·cos(%.0f°) = %.2f,  v_y = %.0f·sin(%.0f°) = %.2f",
                magnitude, angleDeg, vx, magnitude, angleDeg, vy
            )
        )
    }
}
