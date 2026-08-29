package com.timpsonlyceum.lyceum.drills

import android.content.Context
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

// Grammar drills — a wide catalogue of multiple-choice practice loaded from the
// bundled assets/drills/*.json, the same authored files the iOS app ships. Content
// lives in data, so adding or editing a question never touches code.
//
// Each drill is a finite pool of items: a prompt (usually with a "___" blank), a
// few options, the index of the correct one, a one-line explanation, and a
// difficulty level.

@Serializable
data class GrammarItem(
    val id: String,
    val level: Int = 1,
    val prompt: String,
    val options: List<String>,
    val answer: Int,
    val explain: String,
)

@Serializable
data class GrammarDrillSpec(
    val slug: String,
    val title: String,
    val blurb: String = "",
    val icon: String = "✒️",
    /** "grid" (short word tiles) | "list" (full-sentence rows) | "auto". */
    val layout: String = "auto",
    /** "fixed" (stable slots for a recurring option set) | anything else shuffles. */
    val order: String = "shuffle",
    /** Concept difficulty 1–3, which is what drives the Gauntlet's tiers. */
    val tier: Int = 2,
    val items: List<GrammarItem>,
)

@Serializable
private data class GrammarFile(val drills: List<GrammarDrillSpec> = emptyList())

object GrammarDrills {

    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }

    private var specs: List<GrammarDrillSpec> = emptyList()
    private var lessonSpecs: List<GrammarDrillSpec> = emptyList()

    /** Every grammar drill, plus the Gauntlet capstone, plus the lesson homework sets. */
    var all: List<DrillDef> = emptyList()
        private set

    /**
     * Loads the bundled catalogues. Safe to call more than once; a malformed item
     * is dropped rather than taking the whole catalogue down with it.
     */
    fun load(context: Context) {
        if (all.isNotEmpty()) return
        specs = read(context, "drills/grammar.json")
        lessonSpecs = read(context, "drills/lessons.json")
        all = specs.map { makeDrill(it) } + listOf(gauntlet()) + lessonSpecs.map { makeDrill(it, lesson = true) }
    }

    private fun read(context: Context, path: String): List<GrammarDrillSpec> = try {
        val text = context.assets.open(path).bufferedReader().use { it.readText() }
        json.decodeFromString(GrammarFile.serializer(), text).drills.mapNotNull { spec ->
            val items = spec.items.filter {
                it.options.size >= 2 &&
                    it.answer in it.options.indices &&
                    it.options.toSet().size == it.options.size   // shuffling keys on the text
            }
            if (items.isEmpty()) null else spec.copy(items = items)
        }
    } catch (e: Exception) {
        emptyList()
    }

    /**
     * One problem from one item, honouring its drill's layout and order.
     *
     * "fixed" sorts the options into stable, content-derived slots so a recurring
     * set (its/it's, than/then) always lands in the same place — read the
     * question rather than re-hunting the moved word. The correct slot still
     * varies with the meaning, so there is nothing to game. Anything else
     * shuffles per play, which kills any positional bias in the authoring.
     */
    private fun problem(item: GrammarItem, layout: String, order: String): DrillProblem {
        val correct = item.options[item.answer.coerceIn(0, item.options.lastIndex)]
        val opts = if (order == "fixed") {
            item.options.sortedBy { it.lowercase() }
        } else {
            item.options.shuffled()
        }
        return DrillProblem(
            prompt = item.prompt,
            input = DrillInput.Choice(opts, opts.indexOf(correct).coerceAtLeast(0)),
            explanation = item.explain,
            dedupeKey = item.id,
            forceGrid = layout == "grid",
            forceList = layout == "list",
        )
    }

    private fun makeDrill(spec: GrammarDrillSpec, lesson: Boolean = false): DrillDef {
        val items = spec.items
        return DrillDef(
            slug = spec.slug,
            title = spec.title,
            blurb = spec.blurb,
            icon = spec.icon,
            category = if (lesson) DrillCategory.LESSONS else DrillCategory.GRAMMAR,
            // A single concept has no honest Easy/Medium/Hard — splitting one
            // concept's sentences three ways would be arbitrary, so the drill
            // just runs its whole pool. Concept difficulty lives in the Gauntlet.
            difficultyTiers = false,
        ) { _ ->
            // Share the shuffle bag so a run walks every item once before repeating.
            val i = DrillEngine.draw("${spec.slug}-L3") { items.indices.toList() }
            problem(items[i], spec.layout, spec.order)
        }
    }

    /**
     * The capstone: every grammar item in one pool, each rendered with its own
     * drill's layout and order. Mixing the topics defeats "I recognise this
     * drill's questions" and makes it a real test of the rules.
     *
     * Difficulty here is concept tier — a genuine beginner-to-advanced ladder,
     * unlike sub-selecting one concept's sentences.
     */
    private fun gauntlet(): DrillDef {
        data class Tagged(val item: GrammarItem, val layout: String, val order: String, val tier: Int)

        val tagged = specs.flatMap { s -> s.items.map { Tagged(it, s.layout, s.order, s.tier) } }

        return DrillDef(
            slug = "grammar-gauntlet",
            title = "Grammar Gauntlet",
            blurb = "Every grammar drill mixed together — Easy to Hard by concept, no pattern to lean on.",
            icon = "🏆",
            category = DrillCategory.GRAMMAR,
        ) { level ->
            val pool = tagged.filter { it.tier <= level }.ifEmpty { tagged }
            val i = DrillEngine.draw("grammar-gauntlet-L$level") { pool.indices.toList() }
            val t = pool[i]
            problem(t.item, t.layout, t.order)
        }
    }
}
