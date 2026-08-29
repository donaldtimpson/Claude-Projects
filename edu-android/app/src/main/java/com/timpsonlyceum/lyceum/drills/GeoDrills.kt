package com.timpsonlyceum.lyceum.drills

// The geography drills: identify a highlighted region, or name its capital.
//
// No emoji flags, unlike iOS. iOS composes 🇩🇪 from "DE" on every device, so the
// iOS options carry a flag before the country name. Android does not, and the
// fallback is two boxed letters — "[D][E] Germany" — which is worse than no flag.
// It cannot be detected reliably either: on the API 36 emulator both
// Paint.hasGlyph and text measurement report the sequence as composed while the
// raster still shows boxes. So the name and the highlighted map carry the
// question here, which they already did; the flag was only ever a garnish.
// GeoRegion.flag is kept for a platform where this becomes safe.
//
// Difficulty is obscurity, not size of number — Easy asks about the countries
// everyone can place, Hard reaches the whole atlas. Distractors are drawn from
// the same continent first, so a wrong answer is always a plausible one rather
// than a giveaway from the other side of the world.

object GeoDrills {

    /** Countries famous enough for Easy that LABELRANK alone gets wrong. */
    private val easyRemove = setOf("Kenya", "Democratic Republic of the Congo", "Ethiopia")
    private val easyAdd = setOf("Iceland", "Ireland", "Greece")

    fun countryPool(level: Int): List<GeoRegion> {
        val all = GeoAtlas.world.askable
        return when (level) {
            1 -> all.filter { (it.rank <= 2 && it.name !in easyRemove) || it.name in easyAdd }
            2 -> all.filter { it.rank <= 3 }
            else -> all
        }
    }

    fun statePool(level: Int): List<GeoRegion> =
        GeoAtlas.usStates.askable.filter { it.rank <= level }

    val all: List<DrillDef> by lazy {
        listOf(nameCountry, nameState, capitalCountry, capitalState)
    }

    /** Three distractors, same continent first, then anywhere. */
    private fun distractors(target: GeoRegion, all: List<GeoRegion>): List<GeoRegion> {
        val seen = mutableSetOf(target.id)
        val out = mutableListOf<GeoRegion>()
        val sameGroup = all.filter { it.continent == target.continent && it.id != target.id }
        for (r in sameGroup.shuffled() + all.shuffled()) {
            if (seen.add(r.id)) out += r
            if (out.size == 3) break
        }
        return out
    }

    /** "Which region is highlighted?" — the map is the question, so the prompt is empty. */
    private fun mapProblem(
        target: GeoRegion,
        all: List<GeoRegion>,
        kind: GeoMapKind,
    ): DrillProblem {
        fun label(r: GeoRegion) = r.name
        val picks = (listOf(target) + distractors(target, all)).shuffled()
        return DrillProblem(
            prompt = "",
            input = DrillInput.Choice(picks.map { label(it) }, picks.indexOfFirst { it.id == target.id }.coerceAtLeast(0)),
            explanation = "${label(target)} — ${target.continent}.",
            diagram = DrillDiagram.GeoMap(kind, target.id),
            dedupeKey = target.id,
            forceGrid = true,
        )
    }

    /** Same shape, but the answer is the capital city. */
    private fun capitalProblem(
        target: GeoRegion,
        all: List<GeoRegion>,
        kind: GeoMapKind,
        capitals: Map<String, String>,
    ): DrillProblem {
        fun cap(r: GeoRegion) = capitals[r.id] ?: r.name
        val picks = (listOf(target) + distractors(target, all)).shuffled()
        // Countries get their flag in the prompt; states have no emoji flag, so
        // the map alone identifies them.
        return DrillProblem(
            prompt = "Capital of ${target.name}?",
            input = DrillInput.Choice(picks.map { cap(it) }, picks.indexOfFirst { it.id == target.id }.coerceAtLeast(0)),
            explanation = "${cap(target)} — capital of ${target.name}.",
            diagram = DrillDiagram.GeoMap(kind, target.id),
            dedupeKey = "cap:${target.id}",
            forceGrid = true,
        )
    }

    /** Draw from a shuffle bag, so a run cycles the whole pool before repeating. */
    private fun pick(pool: List<GeoRegion>, fallback: List<GeoRegion>, bagKey: String): GeoRegion? {
        if (pool.isEmpty()) return fallback.randomOrNull()
        return pool[DrillEngine.draw(bagKey) { pool.indices.toList() }]
    }

    private fun empty(message: String) = DrillProblem(
        prompt = message,
        input = DrillInput.Choice(listOf("OK", "OK "), 0),
        explanation = null,
    )

    val nameCountry = DrillDef(
        slug = "name-country",
        title = "Name the Country",
        blurb = "Identify the highlighted country on the world map.",
        icon = "🌍",
        poolSize = { countryPool(it).size },
        poolItems = { countryPool(it).map { r -> r.id } },
        problemForItem = { id, _ ->
            val r = GeoAtlas.world.region(id) ?: GeoAtlas.world.askable.first()
            mapProblem(r, GeoAtlas.world.askable, GeoMapKind.WORLD)
        },
    ) { level ->
        val pool = countryPool(level)
        val target = pick(pool, GeoAtlas.world.askable, "name-country-L$level")
        if (target == null) empty("Atlas unavailable.")
        else mapProblem(target, GeoAtlas.world.askable, GeoMapKind.WORLD)
    }

    val nameState = DrillDef(
        slug = "name-state",
        title = "Name the State",
        blurb = "Identify the highlighted U.S. state — major rivers drawn in for context.",
        icon = "🗺️",
        poolSize = { statePool(it).size },
        poolItems = { statePool(it).map { r -> r.id } },
        problemForItem = { id, _ ->
            val r = GeoAtlas.usStates.region(id) ?: GeoAtlas.usStates.askable.first()
            mapProblem(r, GeoAtlas.usStates.askable, GeoMapKind.US_STATES)
        },
    ) { level ->
        val pool = statePool(level)
        val target = pick(pool, GeoAtlas.usStates.askable, "name-state-L$level")
        if (target == null) empty("Atlas unavailable.")
        else mapProblem(target, GeoAtlas.usStates.askable, GeoMapKind.US_STATES)
    }

    val capitalCountry = DrillDef(
        slug = "capital-country",
        title = "Capitals — Countries",
        blurb = "See the highlighted country — pick its capital city.",
        icon = "🏛️",
        poolSize = { countryPool(it).count { r -> GeoCapitals.country.containsKey(r.id) } },
        poolItems = { countryPool(it).filter { r -> GeoCapitals.country.containsKey(r.id) }.map { r -> r.id } },
        problemForItem = { id, _ ->
            val all = GeoAtlas.world.askable.filter { GeoCapitals.country.containsKey(it.id) }
            val r = GeoAtlas.world.region(id) ?: all.first()
            capitalProblem(r, all, GeoMapKind.WORLD, GeoCapitals.country)
        },
    ) { level ->
        // Only regions with a capital on file are asked; an omission drops the
        // region from the drill rather than asking a question with no answer.
        val pool = countryPool(level).filter { GeoCapitals.country.containsKey(it.id) }
        val all = GeoAtlas.world.askable.filter { GeoCapitals.country.containsKey(it.id) }
        val target = pick(pool, all, "capital-country-L$level")
        if (target == null) empty("Atlas unavailable.")
        else capitalProblem(target, all, GeoMapKind.WORLD, GeoCapitals.country)
    }

    val capitalState = DrillDef(
        slug = "capital-state",
        title = "Capitals — U.S. States",
        blurb = "See the highlighted state — pick its capital city.",
        icon = "🏦",
        poolSize = { statePool(it).count { r -> GeoCapitals.state.containsKey(r.id) } },
        poolItems = { statePool(it).filter { r -> GeoCapitals.state.containsKey(r.id) }.map { r -> r.id } },
        problemForItem = { id, _ ->
            val all = GeoAtlas.usStates.askable.filter { GeoCapitals.state.containsKey(it.id) }
            val r = GeoAtlas.usStates.region(id) ?: all.first()
            capitalProblem(r, all, GeoMapKind.US_STATES, GeoCapitals.state)
        },
    ) { level ->
        val pool = statePool(level).filter { GeoCapitals.state.containsKey(it.id) }
        val all = GeoAtlas.usStates.askable.filter { GeoCapitals.state.containsKey(it.id) }
        val target = pick(pool, all, "capital-state-L$level")
        if (target == null) empty("Atlas unavailable.")
        else capitalProblem(target, all, GeoMapKind.US_STATES, GeoCapitals.state)
    }
}
