package com.timpsonlyceum.lyceum.drills

import kotlin.math.abs
import kotlin.random.Random

// Native Kotlin reimplementation of the drill generators, ported from the iOS
// app's DrillEngine.swift (edu-web keeps the canonical TypeScript copy in
// lib/drills). Pure, synchronous, offline — no network at any point.
//
// Answers render as clean Unicode (3√3, √2/2, π/6) rather than KaTeX, so a drill
// question costs nothing to draw. The minus sign throughout is U+2212, not a
// hyphen, which is why [neg] exists.

/** How a drill question is answered. */
sealed interface DrillInput {
    /** Typed on the keypad — an exact non-negative integer. */
    data class Numeric(val answer: Int, val unit: String? = null) : DrillInput
    /** Always four options. */
    data class Choice(val options: List<String>, val correctIndex: Int) : DrillInput
    /** Tap the named region on the map; the target is the problem's dedupe key. */
    data class MapTap(val kind: GeoMapKind) : DrillInput
}

enum class GeoMapKind { WORLD, US_STATES }

/** A figure drawn alongside the prompt. */
sealed interface DrillDiagram {
    data class Vector(val angleDeg: Double, val component: String) : DrillDiagram
    data class UnitCircle(val angleDeg: Double, val fn: String) : DrillDiagram
    data class Matrix(val rows: List<List<Int>>) : DrillDiagram
    data class MatrixVector(val matrix: List<List<Int>>, val vector: List<Int>) : DrillDiagram
    data class GeoMap(val kind: GeoMapKind, val highlightId: String) : DrillDiagram
}

data class DrillProblem(
    val prompt: String,
    val input: DrillInput,
    val explanation: String? = null,
    val diagram: DrillDiagram? = null,
    /**
     * Keys the "don't repeat the last few questions" guard when the prompt itself
     * is constant — every map drill asks "What country is highlighted?".
     */
    val dedupeKey: String? = null,
    /** Pin the 2×2 tile layout; country names vary too much to let it flip. */
    val forceGrid: Boolean = false,
    /** Pin the full-width list layout, for options that are whole sentences. */
    val forceList: Boolean = false,
) {
    val identity: String get() = dedupeKey ?: prompt
}

data class DrillDef(
    val slug: String,
    val title: String,
    val blurb: String,
    val icon: String,
    val category: DrillCategory,
    /**
     * Whether Easy/Medium/Hard is a meaningful axis. True for maths (bigger
     * numbers) and geography (obscurity); false where a three-way split of one
     * concept's material would be arbitrary.
     */
    val difficultyTiers: Boolean = true,
    val generate: (Int) -> DrillProblem,
)

enum class DrillCategory(val label: String) {
    ARITHMETIC("Arithmetic"),
    ALGEBRA("Algebra & Sequences"),
    CALCULUS("Calculus"),
    LINEAR_ALGEBRA("Linear Algebra"),
    TRIGONOMETRY("Trigonometry"),
    GEOGRAPHY("Geography"),
    GRAMMAR("Grammar"),
    LESSONS("Lesson Homework"),
}

object DrillEngine {

    // `by lazy`, not a plain val: these are declared further down the object, so
    // an eager list here would read them before they are initialised.
    private val procedural: List<DrillDef> by lazy {
        listOf(
            arithmetic, percentages, orderOfOps, powersOfTwo, squares, gcdDrill, primes,
            sequences, logarithms, derivative, integral,
            determinant, solveSystem, matrixVector, dotProduct, unitCircle, vectors,
        )
    }

    /**
     * Every drill: the procedural generators above, plus the geography set and
     * the bundled grammar and lesson catalogues once their loaders have run. Recomputed rather than
     * cached in a `by lazy`, because the JSON-backed half arrives after process
     * start and a lazy would freeze the list before it landed.
     */
    val all: List<DrillDef> get() = procedural + GeoDrills.all + GrammarDrills.all

    private val bySlug: Map<String, DrillDef> get() = all.associateBy { it.slug }

    fun drill(slug: String): DrillDef? = bySlug[slug]

    // ---- helpers ----

    private tailrec fun gcd(a: Int, b: Int): Int = if (b == 0) a else gcd(b, a % b)

    /**
     * Shuffle "bag" for small discrete domains (powers, squares): draw the whole
     * range in a random order before any value repeats, so the same number does
     * not come round twice in quick succession. One bag per (drill, level).
     */
    private val bags = mutableMapOf<String, MutableList<Int>>()

    @Synchronized
    fun draw(key: String, domain: () -> List<Int>): Int {
        val bag = bags[key]
        if (bag == null || bag.isEmpty()) bags[key] = domain().shuffled().toMutableList()
        return bags[key]!!.removeAt(bags[key]!!.lastIndex)
    }

    @Synchronized
    fun resetBag(slug: String, level: Int) { bags.remove("$slug-L$level") }

    /** Unicode superscripts for exponents (x⁴). */
    private fun sup(n: Int): String {
        val m = mapOf(
            '-' to '⁻', '0' to '⁰', '1' to '¹', '2' to '²', '3' to '³',
            '4' to '⁴', '5' to '⁵', '6' to '⁶', '7' to '⁷', '8' to '⁸', '9' to '⁹',
        )
        return n.toString().map { m[it] ?: it }.joinToString("")
    }

    /** Unicode subscripts for bases (log₂). */
    private fun sub(n: Int): String {
        val m = mapOf(
            '0' to '₀', '1' to '₁', '2' to '₂', '3' to '₃', '4' to '₄',
            '5' to '₅', '6' to '₆', '7' to '₇', '8' to '₈', '9' to '₉',
        )
        return n.toString().map { m[it] ?: it }.joinToString("")
    }

    /** Render c·xⁿ compactly: 12x⁴, 3x, 5 (n=0), x² (c=1), −x³. */
    private fun powTerm(c: Int, n: Int): String {
        if (n == 0) return "$c"
        val base = if (n == 1) "x" else "x${sup(n)}"
        return when (c) {
            1 -> base
            -1 -> "−$base"
            else -> "$c$base"
        }
    }

    /** A proper minus sign, not a hyphen. */
    private fun neg(x: Int): String = x.toString().replace("-", "−")

    /** Format a x + b y = c with tidy signs; drops zero terms. */
    private fun eqn(a: Int, b: Int, c: Int): String {
        var s = ""
        if (a != 0) s += if (a == 1) "x" else if (a == -1) "−x" else "${neg(a)}x"
        if (b != 0) {
            val mag = if (abs(b) == 1) "y" else "${abs(b)}y"
            s += if (s.isEmpty()) {
                if (b < 0) "−$mag" else mag
            } else {
                if (b < 0) " − $mag" else " + $mag"
            }
        }
        return "$s = ${neg(c)}"
    }

    private fun pair(x: Int, y: Int): String = "(${neg(x)}, ${neg(y)})"

    /** Build four shuffled options from a correct value plus a pool of distractors. */
    private fun fourChoices(correct: String, pool: List<String>): Pair<List<String>, Int> {
        val seen = mutableSetOf(correct)
        val d = mutableListOf<String>()
        for (x in pool) {
            if (seen.add(x)) {
                d += x
                if (d.size == 3) break
            }
        }
        var pad = 2
        while (d.size < 3) {
            val f = "$pad"
            if (seen.add(f)) d += f
            pad++
        }
        val opts = (listOf(correct) + d).shuffled()
        return opts to opts.indexOf(correct).coerceAtLeast(0)
    }

    private fun <T> sampleDistinct(pool: List<T>, n: Int): List<T> = pool.shuffled().take(n)

    private fun isPrime(n: Int): Boolean {
        if (n < 2) return false
        if (n < 4) return true
        if (n % 2 == 0) return false
        var i = 3
        while (i * i <= n) {
            if (n % i == 0) return false
            i += 2
        }
        return true
    }

    private fun rand(range: IntRange) = Random.nextInt(range.first, range.last + 1)

    // ---- Arithmetic ----

    /** Quick recall of +, −, ×, ÷, with the inverses built so they stay clean. */
    val arithmetic = DrillDef(
        slug = "arithmetic",
        title = "Mental Arithmetic",
        blurb = "Quick recall of addition, subtraction, multiplication, and division.",
        icon = "🧮",
        category = DrillCategory.ARITHMETIC,
    ) { level ->
        val ops: List<String>
        val add: IntRange
        val mulA: IntRange
        val mulB: IntRange
        when (level) {
            1 -> { ops = listOf("+", "−", "×"); add = 1..13; mulA = 1..6; mulB = 1..6 }
            2 -> { ops = listOf("+", "−", "×", "÷"); add = 1..50; mulA = 1..13; mulB = 1..13 }
            else -> { ops = listOf("+", "−", "×", "÷"); add = 1..500; mulA = 1..13; mulB = 11..20 }
        }

        fun problem(a: Int, sym: String, b: Int, answer: Int) = DrillProblem(
            prompt = "$a $sym $b",
            input = DrillInput.Numeric(answer),
            explanation = "$a $sym $b = $answer",
        )

        when (ops.random()) {
            "+" -> {
                val a = rand(add); val b = rand(add)
                problem(a, "+", b, a + b)
            }
            "−" -> {
                // The inverse of a + b: the minuend is the sum, so nothing goes negative.
                val a = rand(add); val b = rand(add)
                val sum = a + b
                val s = if (Random.nextBoolean()) a else b
                problem(sum, "−", s, sum - s)
            }
            "×" -> {
                val a = rand(mulA); val b = rand(mulB)
                problem(a, "×", b, a * b)
            }
            else -> {
                // The inverse of a × b: the dividend is the product, so it divides evenly.
                val a = rand(mulA); val b = rand(mulB)
                val product = a * b
                val divisor = if (Random.nextBoolean()) a else b
                problem(product, "÷", divisor, product / divisor)
            }
        }
    }

    /** Mental percents, with the multiplier chosen so the answer stays whole. */
    val percentages = DrillDef(
        slug = "percentages",
        title = "Percentages",
        blurb = "Mental percents of a number — tips, discounts, and more.",
        icon = "％",
        category = DrillCategory.ARITHMETIC,
    ) { level ->
        val ps = when (level) {
            1 -> listOf(5, 10, 20, 25, 50)
            2 -> listOf(5, 10, 15, 20, 25, 50)
            else -> listOf(5, 15, 20, 25, 40, 60, 75)
        }
        val p = ps.random()
        val step = 100 / gcd(p, 100)   // the smallest n that keeps the answer whole
        val k = rand(2..(if (level == 1) 10 else if (level == 2) 16 else 25))
        val n = step * k
        val answer = p * n / 100
        DrillProblem(
            prompt = "$p% of $n",
            input = DrillInput.Numeric(answer),
            explanation = "$p% of $n = $answer",
        )
    }

    val orderOfOps = DrillDef(
        slug = "order-of-operations",
        title = "Order of Operations",
        blurb = "Evaluate expressions with the right precedence (PEMDAS).",
        icon = "🔢",
        category = DrillCategory.ARITHMETIC,
    ) { level ->
        val hi = if (level == 1) 9 else if (level == 2) 12 else 20
        val a = rand(2..hi); val b = rand(2..9); val c = rand(2..hi)
        // Two shapes, so the × term lands on either side and the habit of going
        // left to right gets caught both ways.
        if (Random.nextBoolean()) {
            DrillProblem(
                prompt = "$a + $b × $c",
                input = DrillInput.Numeric(a + b * c),
                explanation = "$b × $c first = ${b * c}, then + $a = ${a + b * c}",
            )
        } else {
            DrillProblem(
                prompt = "$b × $c + $a",
                input = DrillInput.Numeric(b * c + a),
                explanation = "$b × $c first = ${b * c}, then + $a = ${b * c + a}",
            )
        }
    }

    val powersOfTwo = DrillDef(
        slug = "powers-of-two",
        title = "Powers of Two",
        blurb = "Recall 2ⁿ — the numbers behind bytes, bits, and binary.",
        icon = "⚡️",
        category = DrillCategory.ARITHMETIC,
    ) { level ->
        val maxK = if (level == 1) 8 else if (level == 2) 12 else 16
        val k = draw("pow2_$level") { (2..maxK).toList() }
        val answer = 1 shl k
        DrillProblem(
            prompt = "2^$k",
            input = DrillInput.Numeric(answer),
            explanation = "2^$k = $answer",
        )
    }

    val squares = DrillDef(
        slug = "squares",
        title = "Squares & Roots",
        blurb = "Perfect squares and their roots, on sight.",
        icon = "▧",
        category = DrillCategory.ARITHMETIC,
    ) { level ->
        val hi = if (level == 1) 12 else if (level == 2) 20 else 30
        val n = draw("sq_$level") { (2..hi).toList() }
        if (Random.nextBoolean()) {
            DrillProblem("$n²", DrillInput.Numeric(n * n), "$n² = ${n * n}")
        } else {
            DrillProblem("√${n * n}", DrillInput.Numeric(n), "√${n * n} = $n")
        }
    }

    val gcdDrill = DrillDef(
        slug = "gcd",
        title = "Greatest Common Divisor",
        blurb = "Find the largest number that divides both.",
        icon = "∩",
        category = DrillCategory.ARITHMETIC,
    ) { level ->
        val hi = if (level == 1) 20 else if (level == 2) 60 else 120
        val a = rand(2..hi); val b = rand(2..hi)
        DrillProblem(
            prompt = "gcd($a, $b)",
            input = DrillInput.Numeric(gcd(a, b)),
            explanation = "gcd($a, $b) = ${gcd(a, b)}",
        )
    }

    val primes = DrillDef(
        slug = "primes",
        title = "Prime or Composite",
        blurb = "Snap-judge whether a number is prime.",
        icon = "🧩",
        category = DrillCategory.ARITHMETIC,
    ) { level ->
        val hi = if (level == 1) 40 else if (level == 2) 80 else 150
        val n = rand(2..hi)
        val prime = isPrime(n)
        // Naming the factor pair is the whole lesson when the answer is composite.
        var why = ""
        if (!prime) {
            var f = 2
            while (f * f <= n) {
                if (n % f == 0) { why = " ($f × ${n / f})"; break }
                f++
            }
        }
        DrillProblem(
            prompt = "Is $n prime?",
            input = DrillInput.Choice(listOf("Prime", "Composite"), if (prime) 0 else 1),
            explanation = "$n is ${if (prime) "prime" else "composite"}$why.",
        )
    }

    // ---- Algebra ----

    val sequences = DrillDef(
        slug = "sequences",
        title = "Next in Sequence",
        blurb = "Spot the pattern and give the next term.",
        icon = "🔗",
        category = DrillCategory.ALGEBRA,
    ) { level ->
        if (Random.nextBoolean()) {
            val a = rand(1..9); val d = rand(2..(if (level == 1) 5 else 9))
            val terms = (0 until 4).map { a + it * d }
            DrillProblem(
                prompt = terms.joinToString(",  ") + ",  ?",
                input = DrillInput.Numeric(a + 4 * d),
                explanation = "Arithmetic, +$d each step → ${a + 4 * d}",
            )
        } else {
            val a = rand(1..4); val r = rand(2..(if (level == 1) 3 else 4))
            var p = 1
            val terms = (0 until 4).map { val v = a * p; p *= r; v }
            val next = a * p
            DrillProblem(
                prompt = terms.joinToString(",  ") + ",  ?",
                input = DrillInput.Numeric(next),
                explanation = "Geometric, ×$r each step → $next",
            )
        }
    }

    val logarithms = DrillDef(
        slug = "logarithms",
        title = "Logarithms",
        blurb = "Evaluate a logarithm — the exponent that gets you there.",
        icon = "㏒",
        category = DrillCategory.ALGEBRA,
    ) { level ->
        val bases = when (level) {
            1 -> listOf(2)
            2 -> listOf(2, 3)
            else -> listOf(2, 3, 5, 10)
        }
        val b = bases.random()
        val maxK = if (b == 2) (if (level == 1) 8 else 12) else if (b == 3) 5 else 4
        val k = draw("log_${b}_$level") { (1..maxK).toList() }
        var value = 1
        repeat(k) { value *= b }
        DrillProblem(
            prompt = "log${sub(b)}($value)",
            input = DrillInput.Numeric(k),
            explanation = "$b^$k = $value, so log${sub(b)}($value) = $k",
        )
    }

    // ---- Calculus ----

    val derivative = DrillDef(
        slug = "derivative",
        title = "Derivatives",
        blurb = "Differentiate c·xⁿ with the power rule.",
        icon = "ƒ′",
        category = DrillCategory.CALCULUS,
    ) { level ->
        val n = rand(2..(if (level == 1) 5 else if (level == 2) 7 else 9))
        val c = if (level == 1) rand(1..5) else rand(2..9)
        val correct = powTerm(c * n, n - 1)
        // Each distractor is a specific mistake, not noise.
        val (options, correctIndex) = fourChoices(
            correct,
            listOf(
                powTerm(c, n),                  // forgot to differentiate at all
                powTerm(c * n, n),              // forgot to drop the power
                powTerm(c, n - 1),              // forgot the coefficient factor
                powTerm(c * (n - 1), n - 1),
            ),
        )
        DrillProblem(
            prompt = "d/dx (${powTerm(c, n)})",
            input = DrillInput.Choice(options, correctIndex),
            explanation = "Bring down $n, reduce the power: $correct",
        )
    }

    val integral = DrillDef(
        slug = "integral",
        title = "Integrals",
        blurb = "Integrate c·xⁿ with the power rule — don't forget + C.",
        icon = "∫",
        category = DrillCategory.CALCULUS,
    ) { level ->
        val n = rand(1..(if (level == 1) 4 else if (level == 2) 6 else 8))
        val m = n + 1
        val k = if (level == 1) rand(1..3) else rand(1..5)
        val c = k * m
        // Every option carries + C, so it is never the giveaway.
        val correct = "${powTerm(k, m)} + C"
        val (options, correctIndex) = fourChoices(
            correct,
            listOf(
                "${powTerm(c, m)} + C",       // forgot to divide by the new power
                "${powTerm(k, n)} + C",       // didn't raise the power
                "${powTerm(k, m + 1)} + C",   // raised it too far
                "${powTerm(c, n)} + C",       // both mistakes at once
            ),
        )
        DrillProblem(
            prompt = "∫ ${powTerm(c, n)} dx",
            input = DrillInput.Choice(options, correctIndex),
            explanation = "Raise the power, divide by it: $correct",
        )
    }

    // ---- Linear algebra ----

    val determinant = DrillDef(
        slug = "determinant",
        title = "2×2 Determinant",
        blurb = "Compute ad − bc for a 2×2 matrix.",
        icon = "▦",
        category = DrillCategory.LINEAR_ALGEBRA,
    ) { level ->
        val range = if (level == 1) 1..6 else if (level == 2) -6..9 else -12..12
        val a = rand(range); val b = rand(range); val c = rand(range); val d = rand(range)
        val det = a * d - b * c
        val (options, correctIndex) = fourChoices(
            neg(det),
            listOf(
                neg(a * d + b * c),   // sign slip on the second product
                neg(b * c - a * d),   // reversed, i.e. −det
                neg(a * b - c * d),   // multiplied the wrong pairs
                neg(det + 3), neg(det - 4),
            ),
        )
        DrillProblem(
            prompt = "Determinant = ?",
            input = DrillInput.Choice(options, correctIndex),
            explanation = "ad − bc = ($a)($d) − ($b)($c) = ${neg(det)}",
            diagram = DrillDiagram.Matrix(listOf(listOf(a, b), listOf(c, d))),
        )
    }

    val solveSystem = DrillDef(
        slug = "solve-system",
        title = "Solve the System",
        blurb = "Two equations, two unknowns — find the (x, y) that works.",
        icon = "⊞",
        category = DrillCategory.LINEAR_ALGEBRA,
    ) { level ->
        val solR = if (level == 1) 0..4 else if (level == 2) -3..4 else -5..5
        val coefR = if (level == 1) listOf(-2, -1, 1, 2) else listOf(-3, -2, -1, 1, 2, 3)
        val x = rand(solR); val y = rand(solR)
        var a1: Int; var b1: Int; var a2: Int; var b2: Int
        do {
            a1 = coefR.random(); b1 = coefR.random()
            a2 = coefR.random(); b2 = coefR.random()
        } while (a1 * b2 - a2 * b1 == 0)   // the two equations must be independent
        val c1 = a1 * x + b1 * y
        val c2 = a2 * x + b2 * y
        val (options, correctIndex) = fourChoices(
            pair(x, y),
            listOf(
                pair(y, x),                  // swapped x and y
                pair(-x, y), pair(x, -y),    // sign slips
                pair(x + 1, y - 1),
            ),
        )
        DrillProblem(
            prompt = "${eqn(a1, b1, c1)}\n${eqn(a2, b2, c2)}\n\nSolve for (x, y)",
            input = DrillInput.Choice(options, correctIndex),
            explanation = "x = ${neg(x)}, y = ${neg(y)} satisfies both equations.",
        )
    }

    val matrixVector = DrillDef(
        slug = "matrix-vector",
        title = "Matrix × Vector",
        blurb = "Multiply a 2×2 matrix by a vector — rows dotted with the vector.",
        icon = "⧉",
        category = DrillCategory.LINEAR_ALGEBRA,
    ) { level ->
        val r = if (level == 1) -2..3 else if (level == 2) -3..4 else -5..5
        val a = rand(r); val b = rand(r); val c = rand(r); val d = rand(r)
        val x = rand(r); val y = rand(r)
        val p = a * x + b * y
        val q = c * x + d * y
        val (options, correctIndex) = fourChoices(
            pair(p, q),
            listOf(
                pair(a * x, d * y),   // multiplied component-wise, the classic mistake
                pair(q, p),           // rows swapped
                pair(a * x + b * y, c * x - d * y),
                pair(p + 1, q),
            ),
        )
        DrillProblem(
            prompt = "A·v = ?",
            input = DrillInput.Choice(options, correctIndex),
            explanation = "Row 1 · v = ${neg(p)},  Row 2 · v = ${neg(q)}",
            diagram = DrillDiagram.MatrixVector(listOf(listOf(a, b), listOf(c, d)), listOf(x, y)),
        )
    }

    val dotProduct = DrillDef(
        slug = "dot-product",
        title = "Dot Product",
        blurb = "Multiply matching components and add them up.",
        icon = "•",
        category = DrillCategory.LINEAR_ALGEBRA,
    ) { level ->
        val r = if (level == 1) -3..4 else if (level == 2) -5..6 else -8..8
        val a1 = rand(r); val a2 = rand(r); val b1 = rand(r); val b2 = rand(r)
        val dot = a1 * b1 + a2 * b2
        val (options, correctIndex) = fourChoices(
            neg(dot),
            listOf(
                neg(a1 * b1 - a2 * b2),   // subtracted instead of adding
                neg(a1 * b2 + a2 * b1),   // paired the wrong components
                neg(dot + 2), neg(dot - 3),
            ),
        )
        DrillProblem(
            prompt = "(${neg(a1)}, ${neg(a2)}) · (${neg(b1)}, ${neg(b2)}) = ?",
            input = DrillInput.Choice(options, correctIndex),
            explanation = "(${neg(a1)})(${neg(b1)}) + (${neg(a2)})(${neg(b2)}) = ${neg(dot)}",
        )
    }

    // ---- Trigonometry ----

    private data class Angle(
        val display: String, val deg: Double,
        val sin: String, val cos: String, val tan: String,
    )

    /** The sixteen standard angles, with exact values as display strings. */
    private val angles = listOf(
        Angle("0", 0.0, "0", "1", "0"),
        Angle("π/6", 30.0, "1/2", "√3/2", "√3/3"),
        Angle("π/4", 45.0, "√2/2", "√2/2", "1"),
        Angle("π/3", 60.0, "√3/2", "1/2", "√3"),
        Angle("π/2", 90.0, "1", "0", "undefined"),
        Angle("2π/3", 120.0, "√3/2", "−1/2", "−√3"),
        Angle("3π/4", 135.0, "√2/2", "−√2/2", "−1"),
        Angle("5π/6", 150.0, "1/2", "−√3/2", "−√3/3"),
        Angle("π", 180.0, "0", "−1", "0"),
        Angle("7π/6", 210.0, "−1/2", "−√3/2", "√3/3"),
        Angle("5π/4", 225.0, "−√2/2", "−√2/2", "1"),
        Angle("4π/3", 240.0, "−√3/2", "−1/2", "√3"),
        Angle("3π/2", 270.0, "−1", "0", "undefined"),
        Angle("5π/3", 300.0, "−√3/2", "1/2", "−√3"),
        Angle("7π/4", 315.0, "−√2/2", "√2/2", "−1"),
        Angle("11π/6", 330.0, "−1/2", "√3/2", "−√3/3"),
    )

    private val sinCosPool = listOf("0", "1", "−1", "1/2", "−1/2", "√2/2", "−√2/2", "√3/2", "−√3/2")
    private val tanPool = listOf("0", "1", "−1", "√3/3", "−√3/3", "√3", "−√3", "undefined")

    val unitCircle = DrillDef(
        slug = "unit-circle",
        title = "Unit Circle",
        blurb = "Recall exact sine, cosine, and tangent values at standard angles.",
        icon = "🔵",
        category = DrillCategory.TRIGONOMETRY,
    ) { level ->
        val fns = if (level == 1) listOf("sin", "cos") else listOf("sin", "cos", "tan")
        val angleCount = if (level == 1) 5 else if (level == 2) 9 else angles.size
        val angle = angles[Random.nextInt(angleCount)]
        val fn = fns.random()
        val correct = when (fn) {
            "sin" -> angle.sin
            "cos" -> angle.cos
            else -> angle.tan
        }
        // Distractors are drawn from the values this function actually takes, so a
        // wrong answer is always a plausible one.
        val pool = (if (fn == "tan") tanPool else sinCosPool).filter { it != correct }
        val options = (listOf(correct) + sampleDistinct(pool, 3)).shuffled()
        DrillProblem(
            prompt = "$fn(${angle.display}) = ?",
            input = DrillInput.Choice(options, options.indexOf(correct).coerceAtLeast(0)),
            explanation = "$fn(${angle.display}) = $correct",
            diagram = DrillDiagram.UnitCircle(angle.deg, fn),
        )
    }

    private data class AngleRow(val deg: Int, val cos: String, val sin: String)

    private val vecAngles = listOf(
        AngleRow(0, "1", "0"),
        AngleRow(30, "√3/2", "1/2"),
        AngleRow(45, "√2/2", "√2/2"),
        AngleRow(60, "1/2", "√3/2"),
        AngleRow(90, "0", "1"),
        AngleRow(120, "−1/2", "√3/2"),
        AngleRow(135, "−√2/2", "√2/2"),
        AngleRow(150, "−√3/2", "1/2"),
        AngleRow(180, "−1", "0"),
        AngleRow(210, "−√3/2", "−1/2"),
        AngleRow(225, "−√2/2", "−√2/2"),
        AngleRow(240, "−1/2", "−√3/2"),
        AngleRow(270, "0", "−1"),
        AngleRow(300, "1/2", "−√3/2"),
        AngleRow(315, "√2/2", "−√2/2"),
        AngleRow(330, "√3/2", "−1/2"),
    )

    /** An exact component, coeff·√root; root 1 means a plain integer. */
    private data class Comp(val coeff: Int, val root: Int)

    private fun scale(token: String, k: Int): Comp = when (token) {
        "1" -> Comp(2 * k, 1)
        "−1" -> Comp(-2 * k, 1)
        "1/2" -> Comp(k, 1)
        "−1/2" -> Comp(-k, 1)
        "√2/2" -> Comp(k, 2)
        "−√2/2" -> Comp(-k, 2)
        "√3/2" -> Comp(k, 3)
        "−√3/2" -> Comp(-k, 3)
        else -> Comp(0, 1)   // "0"
    }

    private fun compDisplay(c: Comp): String {
        if (c.coeff == 0) return "0"
        if (c.root == 1) return "${c.coeff}".replace("-", "−")
        val r = if (c.root == 2) "√2" else "√3"
        return when (c.coeff) {
            1 -> r
            -1 -> "−$r"
            else -> "${c.coeff}".replace("-", "−") + r
        }
    }

    val vectors = DrillDef(
        slug = "vectors",
        title = "Vector Components",
        blurb = "Find a vector's x or y component at common angles — exact values, no calculator.",
        icon = "➹",
        category = DrillCategory.TRIGONOMETRY,
    ) { level ->
        val kRange = if (level == 1) 1..5 else if (level == 2) 1..6 else 2..8
        val angleCount = if (level == 1) 5 else if (level == 2) 9 else vecAngles.size
        val k = rand(kRange)
        val r = 2 * k
        val angle = vecAngles[Random.nextInt(angleCount)]
        val axis = if (Random.nextBoolean()) "x" else "y"
        val correct = scale(if (axis == "x") angle.cos else angle.sin, k)

        // Distractors are values a component of THIS magnitude can actually take.
        val poolComps = listOf(
            Comp(0, 1),
            Comp(k, 1), Comp(-k, 1),
            Comp(2 * k, 1), Comp(-2 * k, 1),
            Comp(k, 2), Comp(-k, 2),
            Comp(k, 3), Comp(-k, 3),
        ).filter { it != correct }.distinct()

        val optionComps = (listOf(correct) + sampleDistinct(poolComps, 3)).shuffled()
        val options = optionComps.map { compDisplay(it) }
        val fn = if (axis == "x") "cos" else "sin"
        DrillProblem(
            prompt = "|v| = $r,  θ = ${angle.deg}°\n$axis-component = ?",
            input = DrillInput.Choice(options, optionComps.indexOf(correct).coerceAtLeast(0)),
            explanation = "$axis-component = $r·$fn(${angle.deg}°) = ${compDisplay(correct)}",
            diagram = DrillDiagram.Vector(angle.deg.toDouble(), axis),
        )
    }
}
