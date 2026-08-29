package com.timpsonlyceum.lyceum.drills

import android.content.Context
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.asComposePath
import androidx.core.graphics.PathParser
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

// Bundled vector geography for the map drills — simplified Natural Earth
// boundaries, projected equirectangular into a normalised viewBox and stored as
// SVG path strings (assets/drills/*.json, the same files the iOS app ships).
//
// A full world map is ~175 filled shapes: no image assets, no network, and it
// scales to any screen. The paths are parsed once and cached, because
// PathParser over 175 shapes is not something to redo per frame.

@Serializable
private data class RegionJson(
    val id: String,
    val name: String,
    val continent: String = "",
    val rank: Int = 7,
    val askable: Boolean = true,
    val iso: String? = null,
    val focus: List<Float> = emptyList(),
    val path: String = "",
)

@Serializable
private data class WorldJson(val viewBox: List<Float> = emptyList(), val countries: List<RegionJson> = emptyList())

@Serializable
private data class StatesJson(
    val viewBox: List<Float> = emptyList(),
    val states: List<RegionJson> = emptyList(),
    val rivers: List<RiverJson> = emptyList(),
)

@Serializable
private data class RiverJson(val name: String = "", val path: String = "")

class GeoRegion(
    val id: String,
    val name: String,
    val continent: String,
    /** Prominence: 2 (most famous) … 7 (obscure). */
    val rank: Int,
    /** False for disputed or dependent territories — still drawn, never asked. */
    val askable: Boolean,
    val iso: String?,
    val pathData: String,
    val focus: Rect?,
) {
    /** Parsed lazily: a drill touches a handful of regions, not all 175. */
    val path: Path by lazy {
        try {
            PathParser.createPathFromPathData(pathData).asComposePath()
        } catch (e: Exception) {
            Path()
        }
    }

    /**
     * The national flag as an emoji, built from the ISO code's regional-indicator
     * letters (🇨🇳 from "CN") — rendered natively, with no bundled flag images.
     * Empty when there is no code, which is the case for US states: their `iso`
     * is a postal abbreviation, not a country code.
     */
    val flag: String
        get() {
            val code = iso ?: return ""
            if (code.length != 2) return ""
            val base = 0x1F1E6
            val sb = StringBuilder()
            for (ch in code.uppercase()) {
                if (ch !in 'A'..'Z') return ""
                sb.appendCodePoint(base + (ch - 'A'))
            }
            return sb.toString()
        }
}

class GeoMapData(
    val viewBox: Rect,
    val regions: List<GeoRegion>,
    val rivers: List<Pair<String, String>> = emptyList(),
) {
    val askable: List<GeoRegion> = regions.filter { it.askable }
    private val byId = regions.associateBy { it.id }
    fun region(id: String): GeoRegion? = byId[id]
}

object GeoAtlas {
    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }

    var world: GeoMapData = GeoMapData(Rect(0f, 0f, 1000f, 500f), emptyList())
        private set
    var usStates: GeoMapData = GeoMapData(Rect(0f, 0f, 1000f, 600f), emptyList())
        private set

    val loaded: Boolean get() = world.regions.isNotEmpty()

    fun load(context: Context) {
        if (loaded) return
        world = runCatching {
            val text = context.assets.open("drills/world-countries.json").bufferedReader().use { it.readText() }
            val w = json.decodeFromString(WorldJson.serializer(), text)
            GeoMapData(rect(w.viewBox), w.countries.map { it.toRegion() })
        }.getOrElse { world }

        usStates = runCatching {
            val text = context.assets.open("drills/us-states.json").bufferedReader().use { it.readText() }
            val s = json.decodeFromString(StatesJson.serializer(), text)
            GeoMapData(
                rect(s.viewBox),
                s.states.map { it.toRegion() },
                s.rivers.map { it.name to it.path },
            )
        }.getOrElse { usStates }
    }

    private fun rect(v: List<Float>): Rect =
        if (v.size == 4) Rect(v[0], v[1], v[0] + v[2], v[1] + v[3]) else Rect(0f, 0f, 1000f, 500f)

    private fun RegionJson.toRegion() = GeoRegion(
        id = id,
        name = name,
        continent = continent,
        rank = rank,
        askable = askable,
        iso = iso,
        pathData = path,
        focus = if (focus.size == 4) Rect(focus[0], focus[1], focus[0] + focus[2], focus[1] + focus[3]) else null,
    )
}

/** Capital cities, keyed by atlas region id. */
object GeoCapitals {
    private val json = Json { ignoreUnknownKeys = true }

    @Serializable
    private data class CapitalsJson(
        val country: Map<String, String> = emptyMap(),
        val state: Map<String, String> = emptyMap(),
    )

    var country: Map<String, String> = emptyMap()
        private set
    var state: Map<String, String> = emptyMap()
        private set

    fun load(context: Context) {
        if (country.isNotEmpty()) return
        runCatching {
            val text = context.assets.open("drills/capitals.json").bufferedReader().use { it.readText() }
            val c = json.decodeFromString(CapitalsJson.serializer(), text)
            country = c.country
            state = c.state
        }
    }
}
