package com.timpsonlyceum.lyceum.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.timpsonlyceum.lyceum.auth.AuthViewModel
import com.timpsonlyceum.lyceum.drills.*
import com.timpsonlyceum.lyceum.model.DrillSessionBody
import com.timpsonlyceum.lyceum.model.makeClientId
import com.timpsonlyceum.lyceum.net.Repository
import com.timpsonlyceum.lyceum.ui.components.*
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display
import com.timpsonlyceum.lyceum.ui.theme.serif
import kotlinx.coroutines.launch

enum class DrillMode { PRACTICE, LEARN, RAPID_FIRE }

private enum class Phase { SETUP, RUNNING, DONE }

/**
 * A drill's setup screen, then the run, then the summary.
 *
 * The three modes are the same three iOS offers, and they are not cosmetic:
 * Practice is a fixed-length run, Learn walks the least-mastered items and
 * records Leitner boxes, and Rapid Fire is a timed sprint against a stored best.
 * A drill only offers what it can honestly support — Learn needs per-item
 * identity, "All" needs a finite pool — so the picker never sits on a value the
 * drill cannot deliver.
 */
@Composable
fun DrillSetupAndRun(
    def: DrillDef,
    auth: AuthViewModel,
    onSignIn: () -> Unit,
    onBack: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    val user by auth.user.collectAsState()
    val signedIn = user != null
    val userId = user?.id ?: "guest"

    val isHomework = def.homeworkLength != null
    val canLearn = def.poolItems != null
    val canAll = def.poolSize != null

    var phase by remember(def.slug) { mutableStateOf(Phase.SETUP) }
    var mode by remember(def.slug) { mutableStateOf(DrillMode.PRACTICE) }
    var practiceLen by remember(def.slug) { mutableIntStateOf(10) }   // 0 = All
    var rapidSeconds by remember(def.slug) { mutableIntStateOf(60) }
    // A lesson offers the homework run or a short practice. Defaults to homework,
    // deliberately not remembered — the point of opening a lesson is the homework.
    var lessonHomework by remember(def.slug) { mutableStateOf(true) }
    var level by remember(def.slug) { mutableIntStateOf(if (def.difficultyTiers) 1 else 3) }
    var result by remember(def.slug) { mutableStateOf<DrillResult?>(null) }
    var runCount by remember(def.slug) { mutableIntStateOf(10) }
    var startedAt by remember(def.slug) { mutableLongStateOf(0L) }

    /**
     * A homework drill has exactly one shape — the fixed-length run that earns the
     * ✦ — so Practice/Learn/Rapid Fire is a choice with no meaning there.
     */
    val activeMode = if (isHomework) DrillMode.PRACTICE else mode

    fun record(r: DrillResult, modeName: String, seconds: Int, score: Int?) {
        if (!signedIn) return
        scope.launch {
            runCatching {
                Repository.recordDrillSession(
                    DrillSessionBody(
                        slug = def.slug, level = level, total = r.total, correct = r.correct,
                        bestStreak = r.bestStreak, mode = modeName, durationSec = seconds,
                        score = score, clientId = makeClientId(),
                    )
                )
            }
            auth.refresh()
        }
    }

    fun startRun(chosenLevel: Int) {
        level = chosenLevel
        DrillEngine.resetBag(def.slug, chosenLevel)
        runCount = when {
            isHomework && lessonHomework -> def.homeworkLength ?: 30
            isHomework -> 10
            practiceLen == 0 -> def.poolSize?.invoke(chosenLevel) ?: 10
            else -> practiceLen
        }
        startedAt = System.currentTimeMillis()
        phase = Phase.RUNNING
    }

    when (phase) {
        Phase.SETUP -> Column(
            Modifier
                .fillMaxSize()
                .background(Theme.parchment)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                TextButton(onClick = onBack) {
                    Text("Back", style = serif(15).copy(color = Theme.gold400))
                }
                Spacer(Modifier.weight(1f))
            }
            Text(def.icon, fontSize = 64.sp)
            Text(def.title, style = display(22).copy(color = Theme.crimson, textAlign = TextAlign.Center))
            Text(
                def.blurb,
                style = serif(16).copy(color = Theme.ink, textAlign = TextAlign.Center),
            )

            if (!isHomework) {
                SegmentedRow(
                    options = buildList {
                        add("Practice" to DrillMode.PRACTICE)
                        if (canLearn) add("Learn" to DrillMode.LEARN)
                        add("Rapid Fire" to DrillMode.RAPID_FIRE)
                    },
                    selected = mode,
                ) { mode = it }
            }

            when (activeMode) {
                DrillMode.RAPID_FIRE -> SegmentedRow(
                    options = listOf("60s" to 60, "120s" to 120),
                    selected = rapidSeconds,
                ) { rapidSeconds = it }

                DrillMode.PRACTICE -> if (isHomework) {
                    SegmentedRow(
                        options = listOf(
                            "Homework · ${def.homeworkLength}" to true,
                            "Practice · 10" to false,
                        ),
                        selected = lessonHomework,
                    ) { lessonHomework = it }
                } else {
                    SegmentedRow(
                        options = buildList {
                            add("10" to 10)
                            add("20" to 20)
                            if (canAll) add("All" to 0)
                        },
                        selected = practiceLen,
                    ) { practiceLen = it }
                }

                DrillMode.LEARN -> Unit
            }

            Text(
                modeBlurb(def, activeMode, practiceLen, lessonHomework),
                style = serif(14).copy(color = Theme.inkSoft, textAlign = TextAlign.Center),
            )

            // Drills with a meaningful Easy/Medium/Hard axis get three buttons;
            // single-concept drills get one Start and always run the full pool.
            if (def.difficultyTiers) {
                Text(
                    "CHOOSE A DIFFICULTY",
                    style = display(13).copy(color = Theme.gold400, letterSpacing = 1.sp),
                )
                listOf(1 to "Easy", 2 to "Medium", 3 to "Hard").forEach { (value, label) ->
                    Column(
                        Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        SecondaryButton(label, Modifier.fillMaxWidth()) { startRun(value) }
                        DifficultyStat(def, activeMode, value, rapidSeconds, userId)
                    }
                }
            } else {
                Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
                    PrimaryButton("Start", Modifier.fillMaxWidth()) { startRun(3) }
                    DifficultyStat(def, activeMode, 3, rapidSeconds, userId)
                }
            }
        }

        Phase.RUNNING -> when (activeMode) {
            DrillMode.RAPID_FIRE -> RapidFireRunner(def, level, rapidSeconds, userId) { r, score ->
                result = r
                runCount = r.total
                phase = Phase.DONE
                DrillStore.setRapidBest(userId, def.slug, level, rapidSeconds, score)
                record(r, "rapid", rapidSeconds, score)
            }

            DrillMode.LEARN -> LearnRunner(def, level, userId) { r ->
                result = r
                runCount = r.total
                phase = Phase.DONE
                record(r, "learn", ((System.currentTimeMillis() - startedAt) / 1000).toInt(), null)
            }

            DrillMode.PRACTICE -> DrillRunner(def, level, runCount) { r ->
                result = r
                phase = Phase.DONE
                // The ✦ is honour-system, exactly as on iOS: a flawless full-length
                // homework run earns it. A short practice run deliberately cannot.
                if (isHomework && lessonHomework && r.correct == r.total && r.total > 0) {
                    DrillStore.markAced(userId, def.slug)
                }
                record(r, "practice", ((System.currentTimeMillis() - startedAt) / 1000).toInt(), null)
            }
        }

        Phase.DONE -> SummaryScreen(
            def = def,
            result = result,
            signedIn = signedIn,
            homeworkRun = isHomework && lessonHomework,
            onAgain = { phase = Phase.SETUP },
            onBack = onBack,
            onSignIn = onSignIn,
        )
    }
}

private fun modeBlurb(
    def: DrillDef,
    mode: DrillMode,
    practiceLen: Int,
    lessonHomework: Boolean,
): String = when (mode) {
    DrillMode.RAPID_FIRE -> "Beat the clock — build a combo for a high score."
    DrillMode.LEARN -> "Practice until you've mastered them all — weak ones come back more."
    DrillMode.PRACTICE -> {
        val hl = def.homeworkLength
        when {
            hl != null && lessonHomework ->
                "A random $hl from the pool. Get every one right to earn the ✦ — full credit if this lesson is assigned in your class."
            hl != null ->
                "10 questions at your pace. Practice only — the ✦ needs the full $hl."
            practiceLen == 0 -> "Every one, once, at your pace."
            else -> "$practiceLen problems at your pace."
        }
    }
}

/** The per-mode line under a difficulty button: a Rapid Fire best, or Learn mastery. */
@Composable
private fun DifficultyStat(
    def: DrillDef,
    mode: DrillMode,
    level: Int,
    rapidSeconds: Int,
    userId: String,
) {
    when (mode) {
        DrillMode.RAPID_FIRE -> {
            val best = DrillStore.rapidBest(userId, def.slug, level, rapidSeconds)
            Text(
                if (best > 0) "${rapidSeconds}s best · $best" else "No ${rapidSeconds}s score yet",
                style = serif(13).copy(color = if (best > 0) Theme.gold400 else Theme.inkSoft),
                modifier = Modifier.padding(top = 4.dp),
            )
        }
        DrillMode.LEARN -> {
            val items = def.poolItems?.invoke(level).orEmpty()
            val m = DrillStore.masteredCount(userId, def.slug, items)
            Text(
                "$m / ${items.size} mastered",
                style = serif(13).copy(color = if (m > 0) Theme.gold400 else Theme.inkSoft),
                modifier = Modifier.padding(top = 4.dp),
            )
        }
        DrillMode.PRACTICE -> Spacer(Modifier.height(4.dp))
    }
}

@Composable
private fun SummaryScreen(
    def: DrillDef,
    result: DrillResult?,
    signedIn: Boolean,
    homeworkRun: Boolean,
    onAgain: () -> Unit,
    onBack: () -> Unit,
    onSignIn: () -> Unit,
) {
    val correct = result?.correct ?: 0
    val total = result?.total ?: 0
    val pct = if (total > 0) Math.round(correct * 100.0 / total).toInt() else 0

    Column(
        Modifier
            .fillMaxSize()
            .background(Theme.parchment)
            .verticalScroll(rememberScrollState())
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        Text(if (pct == 100) "✦" else "✓", fontSize = 52.sp, color = Theme.gold400)
        Text(
            if (pct == 100) "Flawless" else "Nice work",
            style = display(24).copy(color = Theme.crimson),
        )
        Text("$correct / $total correct · $pct%", style = serif(16).copy(color = Theme.ink))

        if (homeworkRun && pct < 100) {
            Text(
                "Homework needs a flawless run — try again for the ✦.",
                style = serif(14).copy(color = Theme.inkSoft, textAlign = TextAlign.Center),
            )
        }

        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Text("Best streak", style = serif(14).copy(color = Theme.inkSoft))
            StreakPill(result?.bestStreak ?: 0)
        }

        if (!signedIn) {
            SignInPrompt(
                message = "This run isn't saved. An account keeps your drill progress, streak, and badges.",
                onSignIn = onSignIn,
            )
        }

        PrimaryButton("Practice again", Modifier.fillMaxWidth(), onClick = onAgain)
        SecondaryButton("Back to drills", Modifier.fillMaxWidth(), onClick = onBack)
    }
}

/** A segmented control: the same shape as the iOS `.pickerStyle(.segmented)` rows. */
@Composable
fun <T> SegmentedRow(
    options: List<Pair<String, T>>,
    selected: T,
    onSelect: (T) -> Unit,
) {
    val shape = RoundedCornerShape(10.dp)
    Row(
        Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        options.forEach { (label, value) ->
            val on = value == selected
            Box(
                Modifier
                    .weight(1f)
                    .heightIn(min = 44.dp)
                    .clip(shape)
                    .background(if (on) Theme.parchmentDeep else Theme.card)
                    .border(1.5.dp, if (on) Theme.gold300 else Theme.line, shape)
                    .clickable { onSelect(value) },
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    label,
                    style = display(14).copy(
                        color = if (on) Theme.gold300 else Theme.inkSoft,
                        textAlign = TextAlign.Center,
                    ),
                    modifier = Modifier.padding(horizontal = 6.dp),
                )
            }
        }
    }
}
