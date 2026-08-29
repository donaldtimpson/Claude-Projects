package com.timpsonlyceum.lyceum.ui.screens

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.timpsonlyceum.lyceum.drills.*
import com.timpsonlyceum.lyceum.ui.components.*
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display
import com.timpsonlyceum.lyceum.ui.theme.serif
import kotlinx.coroutines.delay

/**
 * Rapid Fire: as many as you can before the clock runs out.
 *
 * No reveal to read and no button to press — an answer scores and the next
 * question is already there, because stopping to explain would defeat a sprint.
 * The screen flashes green or red instead, which is feedback you can take at
 * speed. A combo multiplier rewards a run of correct answers.
 */
@Composable
fun RapidFireRunner(
    def: DrillDef,
    level: Int,
    seconds: Int,
    userId: String,
    onFinished: (DrillResult, score: Int) -> Unit,
) {
    var remaining by remember(def.slug, level, seconds) { mutableIntStateOf(seconds) }
    var answered by remember(def.slug, level, seconds) { mutableIntStateOf(0) }
    var correct by remember(def.slug, level, seconds) { mutableIntStateOf(0) }
    var streak by remember(def.slug, level, seconds) { mutableIntStateOf(0) }
    var bestStreak by remember(def.slug, level, seconds) { mutableIntStateOf(0) }
    var score by remember(def.slug, level, seconds) { mutableIntStateOf(0) }
    var flash by remember(def.slug, level, seconds) { mutableStateOf<Boolean?>(null) }
    val recent = remember(def.slug, level, seconds) { mutableListOf<String>() }
    var problem by remember(def.slug, level, seconds) { mutableStateOf(nextProblem(def, level, recent)) }

    val best = remember(def.slug, level, seconds) {
        DrillStore.rapidBest(userId, def.slug, level, seconds)
    }

    LaunchedEffect(def.slug, level, seconds) {
        while (remaining > 0) {
            delay(1000)
            remaining--
        }
        onFinished(DrillResult(correct, answered.coerceAtLeast(1), bestStreak), score)
    }

    val flashColor by animateColorAsState(
        targetValue = when (flash) {
            true -> Theme.success.copy(alpha = 0.22f)
            false -> Theme.danger.copy(alpha = 0.22f)
            null -> Color.Transparent
        },
        animationSpec = tween(150),
        label = "rapid-flash",
    )

    fun answer(isCorrect: Boolean) {
        answered++
        if (isCorrect) {
            correct++
            streak++
            if (streak > bestStreak) bestStreak = streak
            // The combo is the whole point of a sprint: 10 in a row is worth more
            // than 10 scattered. Capped so a long run doesn't run away with it.
            score += 10 * (1 + (streak - 1).coerceAtMost(4))
        } else {
            streak = 0
        }
        flash = isCorrect
        problem = nextProblem(def, level, recent)
    }

    // Clear the flash shortly after it lights, so consecutive answers each blink.
    LaunchedEffect(answered) {
        if (answered > 0) {
            delay(220)
            flash = null
        }
    }

    Box(Modifier.fillMaxSize().background(Theme.parchment)) {
        Box(Modifier.fillMaxSize().background(flashColor))
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    "${remaining}s",
                    style = display(20).copy(
                        color = if (remaining <= 10) Theme.danger else Theme.gold300,
                    ),
                )
                Text("$score", style = display(20).copy(color = Theme.gold400))
                StreakPill(streak)
            }
            QuizProgressBar(remaining.toFloat() / seconds)
            Text(
                if (best > 0) "Best · $best" else "No score yet",
                style = serif(13).copy(color = Theme.inkSoft),
            )

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
                    selected = null,
                    revealed = false,
                    grid = problem.forceGrid ||
                        (!problem.forceList && input.options.all { it.length <= 12 }),
                ) { chosen -> answer(chosen == input.correctIndex) }

                is DrillInput.Numeric -> RapidNumeric(input) { answer(it) }

                is DrillInput.MapTap -> Text(
                    "Map drills need tap-to-locate, which isn't ported yet.",
                    style = serif(15).copy(color = Theme.inkSoft),
                )
            }
        }
    }
}

/** A keypad that scores the moment the typed value can only be right or wrong. */
@Composable
private fun RapidNumeric(input: DrillInput.Numeric, onAnswer: (Boolean) -> Unit) {
    var entry by remember(input) { mutableStateOf("") }
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        NumericKeypad(entry, input.unit) { entry = it }
        PrimaryButton("Check", Modifier.fillMaxWidth(), enabled = entry.isNotEmpty()) {
            onAnswer(entry.toIntOrNull() == input.answer)
            entry = ""
        }
    }
}

/**
 * Learn: work the pool until it is mastered, weakest first.
 *
 * Each item carries a Leitner box 0–5; a correct answer promotes it, a wrong one
 * demotes it, and 5 is mastered. The queue is sorted by box, so effort lands on
 * what is not yet known rather than on what already is — which is the whole
 * difference between Learn and Practice.
 */
@Composable
fun LearnRunner(
    def: DrillDef,
    level: Int,
    userId: String,
    onFinished: (DrillResult) -> Unit,
) {
    val poolItems = remember(def.slug, level) { def.poolItems?.invoke(level).orEmpty() }
    val forItem = def.problemForItem

    if (poolItems.isEmpty() || forItem == null) {
        Column(
            Modifier.fillMaxSize().background(Theme.parchment).padding(24.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text("This drill can't be learned item by item.", style = serif(16).copy(color = Theme.inkSoft))
        }
        return
    }

    // A session is a bite of the weakest items, not the whole pool — the Gauntlet's
    // 601 items would never end.
    val queue = remember(def.slug, level) {
        DrillStore.learnQueue(userId, def.slug, poolItems, limit = 12)
    }

    var index by remember(def.slug, level) { mutableIntStateOf(0) }
    var correct by remember(def.slug, level) { mutableIntStateOf(0) }
    var streak by remember(def.slug, level) { mutableIntStateOf(0) }
    var bestStreak by remember(def.slug, level) { mutableIntStateOf(0) }
    var selected by remember(def.slug, level) { mutableStateOf<Int?>(null) }
    var entry by remember(def.slug, level) { mutableStateOf("") }
    var revealed by remember(def.slug, level) { mutableStateOf(false) }
    var wasRight by remember(def.slug, level) { mutableStateOf(false) }

    val itemId = queue.getOrNull(index) ?: run {
        LaunchedEffect(Unit) { onFinished(DrillResult(correct, queue.size, bestStreak)) }
        return
    }
    val problem = remember(def.slug, level, index) { forItem(itemId, level) }
    val mastered = remember(def.slug, level, index) {
        DrillStore.masteredCount(userId, def.slug, poolItems)
    }

    fun score(right: Boolean) {
        wasRight = right
        revealed = true
        DrillStore.grade(userId, def.slug, itemId, right)
        if (right) {
            correct++
            streak++
            if (streak > bestStreak) bestStreak = streak
        } else {
            streak = 0
        }
    }

    Column(
        Modifier
            .fillMaxSize()
            .background(Theme.parchment)
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        QuizProgressBar((index + if (revealed) 1 else 0).toFloat() / queue.size)
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("${index + 1} of ${queue.size}", style = serif(14).copy(color = Theme.inkSoft))
            Text(
                "$mastered/${poolItems.size} mastered",
                style = serif(13).copy(color = Theme.gold400),
            )
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
                grid = problem.forceGrid ||
                    (!problem.forceList && input.options.all { it.length <= 12 }),
            ) { chosen ->
                selected = chosen
                score(chosen == input.correctIndex)
            }

            is DrillInput.Numeric -> {
                NumericKeypad(entry, input.unit, enabled = !revealed) { entry = it }
                if (!revealed) {
                    PrimaryButton("Check", Modifier.fillMaxWidth(), enabled = entry.isNotEmpty()) {
                        score(entry.toIntOrNull() == input.answer)
                    }
                }
            }

            is DrillInput.MapTap -> Text(
                "Map drills need tap-to-locate, which isn't ported yet.",
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
                if (index + 1 >= queue.size) "Finish" else "Next",
                Modifier.fillMaxWidth(),
            ) {
                if (index + 1 >= queue.size) {
                    onFinished(DrillResult(correct, queue.size, bestStreak))
                } else {
                    index++
                    selected = null
                    entry = ""
                    revealed = false
                }
            }
        }
    }
}
