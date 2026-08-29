package com.timpsonlyceum.lyceum.ui.components

import android.view.HapticFeedbackConstants
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.serif

// Shared building blocks for the quizzing/practice UI — the lecture quiz, the
// daily review, the course test, and the drills all draw from here so they read
// as one interface rather than four.

private val CorrectFill = Color(0xFF1E3A24)
private val WrongFill = Color(0xFF3A1E1E)

/** A slim gold progress bar, 0..1. */
@Composable
fun QuizProgressBar(fraction: Float, modifier: Modifier = Modifier) {
    val f by animateFloatAsState(
        targetValue = fraction.coerceIn(0f, 1f),
        animationSpec = tween(250),
        label = "quiz-progress",
    )
    Box(
        modifier
            .fillMaxWidth()
            .height(6.dp)
            .clip(CircleShape)
            .background(Theme.parchmentDeep)
    ) {
        Box(
            Modifier
                .fillMaxHeight()
                .fillMaxWidth(f)
                .clip(CircleShape)
                .background(Brush.horizontalGradient(listOf(Theme.gold500, Theme.gold300)))
        )
    }
}

/** A live streak pill (🔥 N), dimmed at zero. */
@Composable
fun StreakPill(streak: Int) {
    Row(
        Modifier
            .alpha(if (streak > 0) 1f else 0.4f)
            .clip(CircleShape)
            .background(Theme.parchmentDeep)
            .padding(horizontal = 10.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text("🔥", fontSize = 12.sp)
        Text("$streak", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Theme.gold300)
    }
}

/**
 * Splits a leading flag emoji off the front of an option label.
 *
 * A regional-indicator pair has to be drawn by the system emoji font; left inside
 * a run styled with our serif face it can fail to compose into a flag and shows
 * as two boxed letters instead. So the flag becomes its own text run.
 */
private fun flagSplit(s: String): Pair<String?, String> {
    val first = s.firstOrNull() ?: return null to s
    val cp = s.codePointAt(0)
    if (cp in 0x1F1E6..0x1F1FF) {
        val flagLen = Character.charCount(cp)
        return s.substring(0, flagLen) to s.substring(flagLen).trimStart()
    }
    return null to s
}

/**
 * The shared multiple-choice option list with reveal colouring. The parent owns
 * the selection and reveal state.
 *
 * [grid] lays the options out as 2×2 tiles for short answers (the drills); the
 * default list suits prose options.
 */
@Composable
fun OptionButtons(
    options: List<String>,
    correctIndex: Int,
    selected: Int?,
    revealed: Boolean,
    grid: Boolean = false,
    onSelect: (Int) -> Unit,
) {
    val view = LocalView.current

    fun tap(i: Int) {
        if (!revealed) {
            view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
            onSelect(i)
        }
    }

    fun fill(i: Int): Color = when {
        !revealed -> if (i == selected) Theme.parchmentDeep else Theme.card
        i == correctIndex -> CorrectFill
        i == selected -> WrongFill
        else -> Theme.card
    }

    fun border(i: Int): Color = when {
        !revealed -> if (i == selected) Theme.gold300 else Theme.line
        i == correctIndex -> Theme.success
        i == selected -> Theme.danger
        else -> Theme.line
    }

    if (grid) {
        // A fixed two-column layout rather than a lazy grid: option counts are
        // tiny and nesting a lazy grid inside a scrolling parent needs a height
        // it cannot work out for itself.
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            options.indices.chunked(2).forEach { pair ->
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    pair.forEach { i ->
                        OptionTile(
                            label = options[i],
                            fill = fill(i),
                            border = border(i),
                            enabled = !revealed,
                            modifier = Modifier.weight(1f),
                        ) { tap(i) }
                    }
                    if (pair.size == 1) Spacer(Modifier.weight(1f))
                }
            }
        }
    } else {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            options.indices.forEach { i ->
                OptionRow(
                    label = options[i],
                    fill = fill(i),
                    border = border(i),
                    enabled = !revealed,
                    trailing = when {
                        revealed && i == correctIndex -> Icons.Filled.CheckCircle to Theme.success
                        revealed && i == selected -> Icons.Filled.Cancel to Theme.danger
                        else -> null
                    },
                ) { tap(i) }
            }
        }
    }
}

@Composable
private fun OptionRow(
    label: String,
    fill: Color,
    border: Color,
    enabled: Boolean,
    trailing: Pair<androidx.compose.ui.graphics.vector.ImageVector, Color>?,
    onClick: () -> Unit,
) {
    val shape = RoundedCornerShape(10.dp)
    val (flag, rest) = flagSplit(label)
    Row(
        Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(fill)
            .border(1.5.dp, border, shape)
            .clickable(enabled = enabled, onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        if (flag != null) Text(flag, fontSize = 20.sp)
        Text(rest, style = serif(17).copy(color = Theme.ink), modifier = Modifier.weight(1f))
        trailing?.let { (icon, tint) -> Icon(icon, contentDescription = null, tint = tint) }
    }
}

/** Big centred tile — a larger target, harder to mis-tap. */
@Composable
private fun OptionTile(
    label: String,
    fill: Color,
    border: Color,
    enabled: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    val shape = RoundedCornerShape(14.dp)
    val (flag, rest) = flagSplit(label)
    Column(
        modifier
            .heightIn(min = if (flag == null) 76.dp else 92.dp)
            .clip(shape)
            .background(fill)
            .border(2.dp, border, shape)
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = 8.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        if (flag != null) {
            Text(flag, fontSize = 30.sp)
            Spacer(Modifier.height(5.dp))
        }
        Text(
            rest,
            fontSize = if (flag != null) 18.sp else 24.sp,
            fontWeight = FontWeight.SemiBold,
            color = Theme.ink,
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

/**
 * A custom on-screen number pad — big targets, always visible, no system
 * keyboard. Non-negative integers, which is what the arithmetic drill needs.
 */
@Composable
fun NumericKeypad(
    entry: String,
    unit: String? = null,
    enabled: Boolean = true,
    onEntryChange: (String) -> Unit,
) {
    val keys = listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "⌫")
    val view = LocalView.current

    fun tap(key: String) {
        if (!enabled) return
        view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
        when (key) {
            "C" -> onEntryChange("")
            "⌫" -> onEntryChange(entry.dropLast(1))
            else -> if (entry.length < 9) onEntryChange(entry + key)
        }
    }

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(Theme.parchmentDeep)
                .padding(vertical = 14.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.Bottom,
        ) {
            Text(
                entry.ifEmpty { "0" },
                fontSize = 40.sp,
                fontWeight = FontWeight.SemiBold,
                color = if (entry.isEmpty()) Theme.inkSoft else Theme.ink,
            )
            unit?.let {
                Spacer(Modifier.width(6.dp))
                Text(it, fontSize = 20.sp, color = Theme.inkSoft)
            }
        }
        keys.chunked(3).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                row.forEach { key ->
                    Box(
                        Modifier
                            .weight(1f)
                            .heightIn(min = 54.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(Theme.card)
                            .border(1.dp, Theme.line, RoundedCornerShape(12.dp))
                            .clickable(enabled = enabled) { tap(key) },
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            key,
                            fontSize = 26.sp,
                            color = if (key == "C") Theme.danger else Theme.ink,
                        )
                    }
                }
            }
        }
    }
}
