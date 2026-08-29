package com.timpsonlyceum.lyceum.drills

/** A category you can drill into: a top-level row that pushes a list of drills. */
data class DrillCategoryRoute(
    val title: String,
    val icon: String,
    val slugs: List<String>,
)

/**
 * The hub's categories, in the iOS order and with the iOS titles and glyphs.
 *
 * Defined as explicit slug lists rather than a field on each drill, exactly as
 * iOS does it. One list is the single answer to "what is in this category", and
 * the ordering within a category is editorial — Mental Math runs easiest first,
 * which a per-drill enum could not express.
 *
 * Slugs are filtered against the live catalogue, so a drill that isn't ported yet
 * (tap-to-locate) simply doesn't appear and the count stays truthful.
 */
object DrillCategories {

    val all: List<DrillCategoryRoute>
        get() = listOf(
            DrillCategoryRoute("Grammar Lessons", "🎓", GrammarDrills.lessonSlugs),
            DrillCategoryRoute(
                "Mental Math", "🧮",
                listOf(
                    "arithmetic", "percentages", "order-of-operations",
                    "powers-of-two", "squares", "gcd", "primes", "sequences", "logarithms",
                ),
            ),
            DrillCategoryRoute("Trigonometry", "📐", listOf("unit-circle", "vectors")),
            DrillCategoryRoute("Calculus", "∫", listOf("derivative", "integral")),
            DrillCategoryRoute(
                "Linear Algebra", "▦",
                listOf("determinant", "solve-system", "matrix-vector", "dot-product"),
            ),
            DrillCategoryRoute(
                "Geography", "🌍",
                listOf(
                    "name-country", "name-state", "locate-country", "locate-state",
                    "capital-country", "capital-state",
                ),
            ),
            DrillCategoryRoute("Grammar", "✒️", GrammarDrills.grammarSlugs),
        ).map { it.copy(slugs = it.slugs.filter { s -> DrillEngine.drill(s) != null }) }

    /** The category title a drill sits under, for search matching. */
    fun titleFor(slug: String): String =
        all.firstOrNull { slug in it.slugs }?.title.orEmpty()

    fun drills(route: DrillCategoryRoute): List<DrillDef> =
        route.slugs.mapNotNull { DrillEngine.drill(it) }

    /** The lessons category is the one whose subtitle counts ✦ rather than drills. */
    fun isLessons(route: DrillCategoryRoute): Boolean = route.title == "Grammar Lessons"
}
