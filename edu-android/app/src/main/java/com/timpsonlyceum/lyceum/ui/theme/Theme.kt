package com.timpsonlyceum.lyceum.ui.theme

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.timpsonlyceum.lyceum.R

// Palette mirrors edu-web's globals.css and the iOS app's Theme.swift — a dark,
// classical "lyceum" look: near-black crimson field, crimson surfaces, gold
// accents, parchment text. Names are kept identical to the iOS side on purpose,
// so a screen can be ported across without renaming a single colour.
object Theme {
    // Raw palette
    val crimson950 = Color(0xFF0F0404)
    val crimson900 = Color(0xFF190808)
    val crimson800 = Color(0xFF2D1212)
    val crimson700 = Color(0xFF4A1A1A)
    val gold500 = Color(0xFFB8860B)
    val gold400 = Color(0xFFCFA135)
    val gold300 = Color(0xFFDDB954)

    // Semantic aliases
    val parchment = crimson950      // screen background
    val card = crimson900           // surfaces / cards
    val parchmentDeep = crimson800  // secondary surfaces / selection
    val line = crimson700           // borders / dividers
    val ink = Color(0xFFF5ECD8)     // primary text
    val inkSoft = Color(0xFFC4AF8E) // secondary text
    val crimson = gold300           // brand accent
    val gold = gold500
    val accent = gold500
    val onAccent = crimson950
    val success = Color(0xFF5CB85C)
    val danger = Color(0xFFE06666)
}

// Brand fonts, the same TTFs the iOS app bundles: Cinzel for display, EB
// Garamond for body.
val Cinzel = FontFamily(Font(R.font.cinzel))
val EBGaramond = FontFamily(Font(R.font.eb_garamond))

/** Display face at an explicit size — the equivalent of iOS `.display(_:)`. */
fun display(size: Int) = TextStyle(fontFamily = Cinzel, fontSize = size.sp)

/** Body face at an explicit size — the equivalent of iOS `.serif(_:)`. */
fun serif(size: Int) = TextStyle(fontFamily = EBGaramond, fontSize = size.sp)

private val LyceumColors = darkColorScheme(
    primary = Theme.gold300,
    onPrimary = Theme.onAccent,
    secondary = Theme.gold500,
    background = Theme.parchment,
    onBackground = Theme.ink,
    surface = Theme.card,
    onSurface = Theme.ink,
    error = Theme.danger,
)

private val LyceumTypography = Typography(
    bodyLarge = TextStyle(fontFamily = EBGaramond, fontSize = 16.sp, color = Theme.ink),
    bodyMedium = TextStyle(fontFamily = EBGaramond, fontSize = 15.sp, color = Theme.ink),
    titleLarge = TextStyle(fontFamily = Cinzel, fontSize = 22.sp, color = Theme.ink),
    titleMedium = TextStyle(fontFamily = Cinzel, fontSize = 17.sp, color = Theme.ink),
    labelLarge = TextStyle(fontFamily = Cinzel, fontSize = 14.sp, color = Theme.ink),
)

@Composable
fun LyceumTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = LyceumColors,
        typography = LyceumTypography,
        content = content,
    )
}

/** Standard card surface used throughout the app — the `lyceumCard()` modifier. */
fun Modifier.lyceumCard(radius: Int = 12) = this
    .clip(RoundedCornerShape(radius.dp))
    .background(Theme.card)
    .border(1.dp, Theme.line, RoundedCornerShape(radius.dp))
    .padding(16.dp)
