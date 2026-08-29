package com.timpsonlyceum.lyceum.drills

import androidx.compose.ui.geometry.Rect
import kotlin.math.max
import kotlin.math.min

/**
 * Which slice of the atlas to draw for a given target.
 *
 * The whole world at once makes Romania a three-pixel speck, so the map zooms to
 * a window around the target instead. The window is sized from the *target's own*
 * span rather than a fraction of the atlas, so a far-flung inset — Alaska,
 * Hawaii — doesn't inflate the zoom for every other region.
 *
 * `focus` on a region is the bounding box of its largest landmass, deliberately
 * ignoring exclaves, which is why France doesn't frame itself around French
 * Guiana.
 */
object GeoViewport {

    /**
     * The identify drills' window: padded room for neighbours, so the answer is
     * readable but the shape still has to be recognised against its surroundings.
     */
    fun settled(map: GeoMapData, targetId: String, aspect: Float): Rect {
        val focus = map.region(targetId)?.focus ?: return map.viewBox
        return window(map.viewBox, focus, aspect, pad = 3.5f, minWidthFrac = 0.16f)
    }

    /** Per-atlas zoom knobs for tap-to-locate, in viewBox units. */
    private data class LocateZoom(val min: Float, val max: Float, val mult: Float)

    private fun locateZoom(kind: GeoMapKind) = when (kind) {
        // viewBox ~1012 wide
        GeoMapKind.WORLD -> LocateZoom(min = 380f, max = 700f, mult = 4.0f)
        // viewBox ~317 wide; the Lower 48 is ~148
        GeoMapKind.US_STATES -> LocateZoom(min = 60f, max = 240f, mult = 3.0f)
    }

    /**
     * The tap-to-locate window: a regional view that gives orienting neighbours
     * without handing over the answer.
     *
     * The target is placed deliberately OFF-centre, at a position derived from
     * its own id — because a target that is always in the middle of the screen
     * can be found without knowing any geography at all. Seeded from the id
     * rather than randomised so the same country lands in the same place every
     * time, which keeps it fair between runs.
     */
    fun locate(map: GeoMapData, targetId: String, kind: GeoMapKind, aspect: Float): Rect {
        val vb = map.viewBox
        val f = map.region(targetId)?.focus ?: return vb
        val z = locateZoom(kind)

        var w = (max(f.width, f.height * aspect) * z.mult).coerceIn(z.min, z.max)
        w = min(w, vb.width)
        var h = w / aspect
        if (h > vb.height) {
            h = vb.height
            w = min(h * aspect, vb.width)
        }

        val px = 0.30f + 0.40f * seededFrac(targetId, 1)
        val py = 0.30f + 0.40f * seededFrac(targetId, 2)
        val x = if (w >= vb.width) vb.left else (f.center.x - px * w).coerceIn(vb.left, vb.right - w)
        val y = if (h >= vb.height) vb.top else (f.center.y - py * h).coerceIn(vb.top, vb.bottom - h)
        return Rect(x, y, x + w, y + h)
    }

    /** A padded, aspect-correct window around a rect, clamped to the atlas. */
    private fun window(vb: Rect, rect: Rect, aspect: Float, pad: Float, minWidthFrac: Float): Rect {
        var w = max(rect.width, rect.height * aspect) * pad
        w = min(max(w, vb.width * minWidthFrac), vb.width)
        val h = min(w / aspect, vb.height)
        val w2 = min(w, h * aspect)   // keep the aspect if the height got capped
        val x = if (w2 >= vb.width) vb.left
        else (rect.center.x - w2 / 2f).coerceIn(vb.left, vb.right - w2)
        val y = if (h >= vb.height) vb.top
        else (rect.center.y - h / 2f).coerceIn(vb.top, vb.bottom - h)
        return Rect(x, y, x + w2, y + h)
    }

    /**
     * A stable 0..1 from a string (FNV-1a). Deliberately not [String.hashCode],
     * which is stable in practice but not contractually so.
     */
    private fun seededFrac(s: String, salt: Int): Float {
        var h = 2166136261u
        h = h xor salt.toUInt()
        h *= 16777619u
        for (c in s) {
            h = h xor c.code.toUInt()
            h *= 16777619u
        }
        return ((h % 10000u).toFloat()) / 10000f
    }
}
