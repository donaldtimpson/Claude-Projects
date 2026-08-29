package com.timpsonlyceum.lyceum.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.timpsonlyceum.lyceum.drills.*
import com.timpsonlyceum.lyceum.ui.components.*
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display
import com.timpsonlyceum.lyceum.ui.theme.serif

data class DrillResult(val correct: Int, val total: Int, val bestStreak: Int)

/**
 * Runs one drill: [length] questions at [level].
 *
 * Questions are generated one at a time rather than up front, because the
 * generators are cheap and a bag-backed drill wants each draw to happen in
 * sequence. The recent-prompt guard keeps a small procedural drill from asking
 * the same thing twice in a row without needing the whole set in advance.
 */
@Composable
fun DrillRunner(
    def: DrillDef,
    level: Int,
    length: Int,
    onFinished: (DrillResult) -> Unit,
) {
    var index by remember(def.slug, level, length) { mutableIntStateOf(0) }
    var correct by remember(def.slug, level, length) { mutableIntStateOf(0) }
    var streak by remember(def.slug, level, length) { mutableIntStateOf(0) }
    var bestStreak by remember(def.slug, level, length) { mutableIntStateOf(0) }
    val recent = remember(def.slug, level, length) { mutableListOf<String>() }

    var problem by remember(def.slug, level, length) { mutableStateOf(nextProblem(def, level, recent)) }
    var selected by remember(def.slug, level, length) { mutableStateOf<Int?>(null) }
    var entry by remember(def.slug, level, length) { mutableStateOf("") }
    var revealed by remember(def.slug, level, length) { mutableStateOf(false) }
    var wasRight by remember(def.slug, level, length) { mutableStateOf(false) }

    fun score(right: Boolean) {
        wasRight = right
        revealed = true
        if (right) {
            correct++
            streak++
            if (streak > bestStreak) bestStreak = streak
        } else {
            streak = 0
        }
    }

    fun advance() {
        if (index + 1 >= length) {
            onFinished(DrillResult(correct, length, bestStreak))
            return
        }
        index++
        problem = nextProblem(def, level, recent)
        selected = null
        entry = ""
        revealed = false
    }

    Column(
        Modifier
            .fillMaxSize()
            .background(Theme.parchment)
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        QuizProgressBar((index + if (revealed) 1 else 0).toFloat() / length)

        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("${index + 1} of $length", style = serif(14).copy(color = Theme.inkSoft))
            StreakPill(streak)
        }

        Text(
            problem.prompt,
            style = display(24).copy(color = Theme.ink, textAlign = TextAlign.Center),
            modifier = Modifier.fillMaxWidth(),
        )

        problem.diagram?.let { DrillDiagramView(it) }

        when (val input = problem.input) {
            is DrillInput.Choice -> OptionButtons(
                options = input.options,
                correctIndex = input.correctIndex,
                selected = selected,
                revealed = revealed,
                // Short exact-value answers read better as tiles; whole sentences do not.
                grid = problem.forceGrid ||
                    (!problem.forceList && input.options.all { it.length <= 12 }),
            ) { chosen ->
                selected = chosen
                score(chosen == input.correctIndex)
            }

            is DrillInput.Numeric -> {
                NumericKeypad(entry, input.unit, enabled = !revealed) { entry = it }
                if (!revealed) {
                    PrimaryButton(
                        "Check",
                        Modifier.fillMaxWidth(),
                        enabled = entry.isNotEmpty(),
                    ) { score(entry.toIntOrNull() == input.answer) }
                }
            }

            is DrillInput.MapTap -> Text(
                "Map drills need the bundled atlas, which isn't ported yet.",
                style = serif(15).copy(color = Theme.inkSoft),
            )
        }

        if (revealed) {
            LyceumCard {
                Text(
                    if (wasRight) "Correct" else "Not quite",
                    style = display(15).copy(color = if (wasRight) Theme.success else Theme.danger),
                )
                problem.explanation?.let {
                    Spacer(Modifier.height(6.dp))
                    Text(it, style = serif(15).copy(color = Theme.ink))
                }
            }
            PrimaryButton(
                if (index + 1 >= length) "See your score" else "Next",
                Modifier.fillMaxWidth(),
            ) { advance() }
        }
    }
}

/**
 * Draws the next problem, avoiding the last few prompts.
 *
 * Ten attempts, then take what comes: a drill whose pool is smaller than the
 * window would otherwise spin forever.
 */
private fun nextProblem(def: DrillDef, level: Int, recent: MutableList<String>): DrillProblem {
    var p = def.generate(level)
    var tries = 0
    while (recent.contains(p.identity) && tries < 10) {
        p = def.generate(level)
        tries++
    }
    recent += p.identity
    if (recent.size > 4) recent.removeAt(0)
    return p
}
