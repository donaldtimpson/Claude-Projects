package com.timpsonlyceum.lyceum.ui.screens

import android.graphics.RectF
import android.graphics.Region
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.asAndroidPath
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.timpsonlyceum.lyceum.drills.GeoAtlas
import com.timpsonlyceum.lyceum.drills.GeoMapKind
import com.timpsonlyceum.lyceum.drills.GeoRegion
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display
import com.timpsonlyceum.lyceum.ui.theme.serif
import kotlin.math.min

/**
 * The tap-to-locate map: "Find Peru", and you tap it.
 *
 * Hit-testing is done by turning each region's path into an [android.graphics.Region]
 * once and asking which one contains the tapped point. Regions are built in the
 * atlas's own viewBox coordinates and the tap is converted back into that space,
 * so the cache survives rotation and resizing — rebuilding 175 regions on every
 * layout would be visible.
 *
 * A Region is integer-only, so very small countries can round away to nothing.
 * That is what the nearest-centroid fallback is for: a tap that lands in no
 * region at all resolves to the closest one rather than being swallowed.
 */
@Composable
fun LocateMap(
    kind: GeoMapKind,
    targetId: String,
    revealed: Boolean,
    tappedId: String?,
    modifier: Modifier = Modifier,
    onTap: (String) -> Unit,
) {
    val map = if (kind == GeoMapKind.WORLD) GeoAtlas.world else GeoAtlas.usStates
    if (map.regions.isEmpty()) {
        Text("Atlas unavailable", style = serif(14).copy(color = Theme.inkSoft))
        return
    }
    val vb = map.viewBox

    // Built once per atlas and kept: this is the expensive part.
    val hitRegions = remember(kind) { buildHitRegions(map.regions, vb) }

    var canvasSize by remember(kind) { mutableStateOf(Offset.Zero) }

    Canvas(
        modifier
            .fillMaxWidth()
            .aspectRatio((vb.width / vb.height).coerceIn(0.8f, 2.4f))
            .pointerInput(kind, revealed) {
                detectTapGestures { pos ->
                    if (revealed) return@detectTapGestures
                    val scale = min(size.width / vb.width, size.height / vb.height)
                    val dx = (size.width - vb.width * scale) / 2f - vb.left * scale
                    val dy = (size.height - vb.height * scale) / 2f - vb.top * scale
                    val x = (pos.x - dx) / scale
                    val y = (pos.y - dy) / scale
                    resolveTap(hitRegions, x, y)?.let(onTap)
                }
            }
    ) {
        canvasSize = Offset(size.width, size.height)
        val scale = min(size.width / vb.width, size.height / vb.height)
        val dx = (size.width - vb.width * scale) / 2f - vb.left * scale
        val dy = (size.height - vb.height * scale) / 2f - vb.top * scale

        withTransform({
            translate(dx, dy)
            scale(scale, scale, pivot = Offset.Zero)
        }) {
            map.regions.forEach { r ->
                drawPath(r.path, Theme.parchmentDeep)
                drawPath(r.path, Theme.line, style = Stroke(width = 1f / scale))
            }
            // Only after answering does the map give anything away: the correct
            // region in gold, and the wrong tap in red beside it.
            if (revealed) {
                if (tappedId != null && tappedId != targetId) {
                    map.region(tappedId)?.let {
                        drawPath(it.path, Theme.danger.copy(alpha = 0.75f))
                    }
                }
                map.region(targetId)?.let {
                    drawPath(it.path, Theme.gold500)
                    drawPath(it.path, Theme.gold300, style = Stroke(width = 2f / scale))
                }
            }
        }
    }
}

private class HitRegion(val id: String, val region: Region, val cx: Float, val cy: Float)

private fun buildHitRegions(
    regions: List<GeoRegion>,
    vb: androidx.compose.ui.geometry.Rect,
): List<HitRegion> {
    val clip = Region(
        vb.left.toInt() - 1, vb.top.toInt() - 1,
        vb.right.toInt() + 1, vb.bottom.toInt() + 1,
    )
    val bounds = RectF()
    return regions.mapNotNull { r ->
        runCatching {
            val androidPath = r.path.asAndroidPath()
            androidPath.computeBounds(bounds, true)
            val region = Region()
            region.setPath(androidPath, clip)
            HitRegion(r.id, region, bounds.centerX(), bounds.centerY())
        }.getOrNull()
    }
}

/**
 * The region containing the point, or the nearest centroid when the tap lands in
 * a gap — better to resolve a near-miss than to swallow it.
 */
private fun resolveTap(regions: List<HitRegion>, x: Float, y: Float): String? {
    val xi = x.toInt()
    val yi = y.toInt()
    regions.firstOrNull { it.region.contains(xi, yi) }?.let { return it.id }
    return regions.minByOrNull { (it.cx - x) * (it.cx - x) + (it.cy - y) * (it.cy - y) }?.id
}
