package com.timpsonlyceum.lyceum.ui.components

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display
import com.timpsonlyceum.lyceum.ui.theme.serif

/**
 * Press feedback for tappable cards and rows: a gold border, a faint gold wash,
 * and a tiny press-in. The iOS `LyceumPressStyle` lights instantly on touch-down
 * and eases out on release, so a quick tap still registers before navigation
 * takes the screen away; [animateFloatAsState] with a zero-length "in" does the
 * same thing here.
 */
@Composable
fun LyceumCard(
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    radius: Int = 12,
    content: @Composable ColumnScope.() -> Unit,
) {
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val glow by animateFloatAsState(
        targetValue = if (pressed) 1f else 0f,
        animationSpec = tween(durationMillis = if (pressed) 0 else 220),
        label = "press-glow",
    )
    val shape = RoundedCornerShape(radius.dp)

    var m = modifier
        .fillMaxWidth()
        .scale(if (pressed) 0.985f else 1f)
        .clip(shape)
        .background(Theme.card)
        .border(
            width = if (glow > 0f) 1.5.dp else 1.dp,
            color = if (glow > 0f) Theme.gold300.copy(alpha = glow) else Theme.line,
            shape = shape,
        )
    if (onClick != null) {
        m = m.then(
            Modifier.clickable(
                interactionSource = interaction,
                indication = null,
                onClick = onClick,
            )
        )
    }
    Column(modifier = m.background(Theme.gold300.copy(alpha = 0.07f * glow)).padding(16.dp)) {
        content()
    }
}

/**
 * Cinzel, uppercase, wide tracking, gold with a hairline rule — mirrors the web's
 * section headings and the iOS `SectionHeader`.
 */
@Composable
fun SectionHeader(title: String, modifier: Modifier = Modifier) {
    Column(modifier = modifier.padding(top = 8.dp)) {
        Text(
            text = title.uppercase(),
            style = display(15).copy(color = Theme.gold400, letterSpacing = 3.sp),
        )
        Spacer(Modifier.height(8.dp))
        Box(Modifier.fillMaxWidth().height(1.dp).background(Theme.line))
    }
}

/** Tints every case-insensitive occurrence of [query] within [text]. */
fun searchHighlighted(text: String, query: String?, color: Color = Theme.gold300): AnnotatedString {
    val q = query?.trim().orEmpty()
    if (q.isEmpty()) return AnnotatedString(text)
    return buildAnnotatedString {
        var idx = 0
        while (true) {
            val found = text.indexOf(q, idx, ignoreCase = true)
            if (found < 0) break
            append(text.substring(idx, found))
            withStyle(SpanStyle(color = color)) { append(text.substring(found, found + q.length)) }
            idx = found + q.length
        }
        append(text.substring(idx))
    }
}

/** "2:05:16", or "5:42" under an hour. */
fun formatDuration(seconds: Int): String {
    val h = seconds / 3600
    val m = (seconds % 3600) / 60
    val s = seconds % 60
    return if (h > 0) String.format("%d:%02d:%02d", h, m, s) else String.format("%d:%02d", m, s)
}

/** The gold pill on a currently-taught course. */
@Composable
fun LivePill() {
    Text(
        "Live",
        style = display(10).copy(color = Theme.onAccent, letterSpacing = 1.sp),
        modifier = Modifier
            .clip(CircleShape)
            .background(Theme.gold500)
            .padding(horizontal = 8.dp, vertical = 3.dp),
    )
}

/** Full-screen spinner on the app's field, so a load never flashes white. */
@Composable
fun LoadingScreen() {
    Box(
        Modifier.fillMaxSize().background(Theme.parchment),
        contentAlignment = Alignment.Center,
    ) { CircularProgressIndicator(color = Theme.gold300) }
}

/** The iOS `ContentUnavailableView` shape: a title, and the reason under it. */
@Composable
fun ErrorScreen(title: String, detail: String?, onRetry: (() -> Unit)? = null) {
    Column(
        Modifier.fillMaxSize().background(Theme.parchment).padding(32.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(title, style = display(18).copy(color = Theme.ink, textAlign = TextAlign.Center))
        if (!detail.isNullOrBlank()) {
            Spacer(Modifier.height(8.dp))
            Text(detail, style = serif(15).copy(color = Theme.inkSoft, textAlign = TextAlign.Center))
        }
        if (onRetry != null) {
            Spacer(Modifier.height(20.dp))
            PrimaryButton("Try again", onClick = onRetry)
        }
    }
}

@Composable
fun PrimaryButton(title: String, modifier: Modifier = Modifier, enabled: Boolean = true, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier,
        shape = RoundedCornerShape(10.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = Theme.accent,
            contentColor = Theme.onAccent,
            disabledContainerColor = Theme.accent.copy(alpha = 0.4f),
            disabledContentColor = Theme.onAccent.copy(alpha = 0.6f),
        ),
    ) { Text(title, style = display(15).copy(color = Theme.onAccent)) }
}

@Composable
fun SecondaryButton(title: String, modifier: Modifier = Modifier, onClick: () -> Unit) {
    OutlinedButton(
        onClick = onClick,
        modifier = modifier,
        shape = RoundedCornerShape(10.dp),
        border = BorderStroke(1.dp, Theme.line),
        colors = ButtonDefaults.outlinedButtonColors(contentColor = Theme.ink),
    ) { Text(title, style = display(15).copy(color = Theme.ink)) }
}

/**
 * The prompt shown where an account genuinely buys something — a saved score, a
 * place on the board. It says what signing in is for and offers to do it, rather
 * than being a dead end; the iOS app learned that the hard way when the result
 * screens carried "Sign in to save your score" with no way to act on it.
 */
@Composable
fun SignInPrompt(
    message: String,
    actionTitle: String = "Sign in",
    onSignIn: () -> Unit,
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
        Text(
            message,
            style = serif(14).copy(color = Theme.inkSoft, textAlign = TextAlign.Center),
        )
        Spacer(Modifier.height(10.dp))
        PrimaryButton(actionTitle, onClick = onSignIn)
    }
}

/** One-line label + value row used through the progress and grade screens. */
@Composable
fun StatRow(label: String, value: String, valueColor: Color = Theme.ink) {
    Row(
        Modifier.fillMaxWidth().padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, style = serif(15).copy(color = Theme.inkSoft), maxLines = 1, overflow = TextOverflow.Ellipsis)
        Text(value, style = display(15).copy(color = valueColor))
    }
}
