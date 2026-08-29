package com.timpsonlyceum.lyceum.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.Explore
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.timpsonlyceum.lyceum.model.Badge
import com.timpsonlyceum.lyceum.ui.theme.Theme

/**
 * Category and tier metadata for badges, mirroring the web gamification catalogue.
 *
 * The [Badge] model only carries `category` and `tier` as strings; this maps them
 * to labels, glyphs, and the metal palette each medallion is minted from.
 */
object BadgeMeta {
    val categoryOrder = listOf("milestones", "mastery", "completion", "consistency", "exploration", "special")

    fun categoryLabel(key: String): String = when (key) {
        "milestones" -> "Milestones"
        "mastery" -> "Mastery"
        "completion" -> "Completion"
        "consistency" -> "Consistency"
        "exploration" -> "Exploration"
        "special" -> "Special"
        else -> key.replaceFirstChar { it.uppercase() }
    }

    /** The glyph struck into the face of the medallion, one per category. */
    fun categoryIcon(key: String): ImageVector = when (key) {
        "milestones" -> Icons.Filled.DirectionsRun
        "mastery" -> Icons.Filled.GpsFixed
        "completion" -> Icons.Filled.AccountBalance
        "consistency" -> Icons.Filled.LocalFireDepartment
        "exploration" -> Icons.Filled.Explore
        "special" -> Icons.Filled.AutoAwesome
        else -> Icons.Filled.Star
    }

    fun categoryBlurb(key: String): String = when (key) {
        "milestones" -> "Volume — the steady climb."
        "mastery" -> "Quality — proof you learned it."
        "completion" -> "Finishing what you start."
        "consistency" -> "Showing up, day after day."
        "exploration" -> "Breadth across subjects."
        "special" -> "Seasonal, rare, and just for fun."
        else -> ""
    }

    val tierRank = mapOf("bronze" to 0, "silver" to 1, "gold" to 2, "platinum" to 3, "omniscient" to 4)

    fun tierLabel(t: String): String =
        if (t == "omniscient") "Omniscient" else t.replaceFirstChar { it.uppercase() }

    /** Metal face gradient, highlight to shadow, per tier. */
    fun tierMetal(t: String): List<Color> = when (t) {
        "bronze" -> listOf(Color(0xFFE6B877), Color(0xFF8F5F2C))
        "silver" -> listOf(Color(0xFFF2F2F6), Color(0xFF96969F))
        "gold" -> listOf(Color(0xFFF4DA8A), Color(0xFFB8860B))
        "platinum" -> listOf(Color(0xFFEAF5FF), Color(0xFF9DC6E6))
        "omniscient" -> listOf(Color(0xFFF8ECB8), Color(0xFFDDB954))
        else -> listOf(Color(0xFFF4DA8A), Color(0xFFB8860B))
    }

    fun tierGlow(t: String): Color = when (t) {
        "gold", "omniscient" -> Color(0xFFDDB954)
        "platinum" -> Color(0xFF9DC6E6)
        else -> Color(0xFFB8860B)
    }
}

/**
 * A procedurally-minted medallion: a metal face in the tier's gradient inside a
 * shimmering gold rim, with the category glyph struck in the centre. Locked
 * badges become a dark disc with a padlock. No image assets — the same approach
 * the iOS app takes, so a new badge needs no artwork.
 */
@Composable
fun BadgeMedallion(badge: Badge, size: Dp = 68.dp) {
    val unlocked = badge.unlocked
    val face = if (unlocked) BadgeMeta.tierMetal(badge.tier)
    else listOf(Color(0xFF3A2C2C), Color(0xFF201414))
    val rim = if (unlocked) listOf(
        Color(0xFFF8ECB8), Color(0xFFB8860B), Color(0xFFF8ECB8),
        Color(0xFF9A7209), Color(0xFFF8ECB8),
    ) else listOf(Theme.line, Theme.crimson800, Theme.line)

    Box(
        Modifier.size(size).alpha(if (unlocked) 1f else 0.5f),
        contentAlignment = Alignment.Center,
    ) {
        Canvas(Modifier.size(size)) {
            val r = this.size.minDimension / 2f
            // The highlight sits up and to the left, so the disc reads as struck
            // metal catching a light rather than a flat filled circle.
            drawCircle(
                brush = Brush.radialGradient(
                    colors = face,
                    center = Offset(this.size.width * 0.35f, this.size.height * 0.3f),
                    radius = r * 1.56f,
                ),
                radius = r,
            )
            val rimWidth = this.size.minDimension * 0.075f
            drawCircle(
                brush = Brush.sweepGradient(rim),
                radius = r - rimWidth / 2f,
                style = Stroke(width = rimWidth),
            )
        }
        Icon(
            imageVector = if (unlocked) BadgeMeta.categoryIcon(badge.category) else Icons.Filled.Lock,
            contentDescription = null,
            tint = if (unlocked) Color(0xFF2A1A0E).copy(alpha = 0.82f) else Theme.inkSoft,
            modifier = Modifier.size(size * 0.38f),
        )
    }
}
