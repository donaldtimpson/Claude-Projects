import Foundation

// One brand icon for every drill: a leather medallion with a gilt SF Symbol (see `Medallion`
// in DrillsView). This maps each non-lesson drill slug to its glyph. Every name was checked
// against the system SF Symbols list and is available on iOS 18 (the deployment target).
enum DrillSymbols {
    /// SF Symbol for a drill's medallion, by slug. Lessons (DrillCatalog.lessonSlugs) aren't here: they show their lesson numeral.
    static let bySlug: [String: String] = [
        // Mental Math
        "arithmetic": "plus.slash.minus",
        "percentages": "percent",
        "order-of-operations": "parentheses",
        "powers-of-two": "chart.line.uptrend.xyaxis",   // exponential growth
        "squares": "x.squareroot",
        "gcd": "divide",
        "primes": "atom",                                // indivisible
        "sequences": "ellipsis",                         // 1, 2, 3, …
        "logarithms": "chart.xyaxis.line",

        // Calculus
        "derivative": "line.diagonal",                   // slope of the tangent
        "integral": "chart.bar.xaxis",                   // Riemann sum, area under the curve

        // Trigonometry
        "unit-circle": "circle.and.line.horizontal",
        "vectors": "arrow.up.right",

        // Linear Algebra
        "determinant": "square.grid.2x2",                // 2×2
        "solve-system": "equal",
        "matrix-vector": "multiply",
        "dot-product": "smallcircle.filled.circle",

        // Geography
        "name-country": "globe.americas.fill",
        "name-state": "map",
        "locate-country": "scope",
        "locate-state": "mappin.and.ellipse",
        "capital-country": "building.columns",
        "capital-state": "star.circle",                  // the capital star on a map

        // Grammar
        "its-vs-its": "character.cursor.ibeam",
        "your-youre": "hand.point.right",                // you
        "there-their-theyre": "signpost.right",          // there
        "than-then": "scalemass",                        // comparison
        "affect-effect": "wand.and.stars",
        "who-whom": "person.fill.questionmark",
        "fewer-less": "number",                          // countable
        "a-vs-an": "speaker.wave.2",                     // it's the sound, not the letter
        "me-vs-i": "person.crop.circle",
        "confusables-mixed": "shuffle",
        "one-word-or-two": "rectangle.split.2x1",
        "apostrophes": "quote.closing",
        "irregular-plurals": "square.stack.3d.up",
        "irregular-verbs": "figure.run",
        "subject-verb-agreement": "hand.thumbsup",
        "comma-sense": "pause.circle",
        "capitalization": "textformat",
        "spot-the-error": "magnifyingglass",
        "sentence-fragment-runon": "scissors",
        "active-passive": "arrow.left.arrow.right",
        "subject-predicate-copula": "link",              // the copula links subject and predicate
        "verb-classes": "arrow.triangle.branch",
        "predicate-nominative-case": "equal.circle",     // renames the subject
        "grammar-gauntlet": "trophy",
    ]
}
