package com.timpsonlyceum.lyceum.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display
import com.timpsonlyceum.lyceum.ui.theme.serif

/** One question, however it reached the screen: a lecture quiz, a course test, a review card. */
data class QuizItem(
    val id: String,
    val prompt: String,
    val options: List<String>,
    val correctIndex: Int,
    val explanation: String,
)

/**
 * The question-at-a-time runner shared by the lecture quiz, the course test, and
 * the daily review.
 *
 * Answering reveals immediately and shows the explanation — every question in
 * this app carries one, and reading it at the moment of being wrong is the whole
 * point of the exercise. [onAnswered] fires once per question with the chosen
 * index, so a caller that records progress does not have to track it separately.
 */
@Composable
fun QuizRunner(
    items: List<QuizItem>,
    modifier: Modifier = Modifier,
    onAnswered: (index: Int, chosen: Int, correct: Boolean) -> Unit = { _, _, _ -> },
    onFinished: (score: Int, answers: List<Int?>) -> Unit,
) {
    var index by remember(items) { mutableIntStateOf(0) }
    var selected by remember(items) { mutableStateOf<Int?>(null) }
    var revealed by remember(items) { mutableStateOf(false) }
    val answers = remember(items) { mutableStateListOf<Int?>().apply { repeat(items.size) { add(null) } } }
    var score by remember(items) { mutableIntStateOf(0) }

    if (items.isEmpty()) {
        Text(
            "No questions for this lecture yet.",
            style = serif(15).copy(color = Theme.inkSoft),
        )
        return
    }

    val item = items[index]

    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        QuizProgressBar((index + if (revealed) 1 else 0).toFloat() / items.size)

        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("Question ${index + 1} of ${items.size}", style = serif(14).copy(color = Theme.inkSoft))
            Text("$score correct", style = display(13).copy(color = Theme.gold400))
        }

        Text(item.prompt, style = serif(18).copy(color = Theme.ink))

        OptionButtons(
            options = item.options,
            correctIndex = item.correctIndex,
            selected = selected,
            revealed = revealed,
        ) { chosen ->
            selected = chosen
            revealed = true
            answers[index] = chosen
            val right = chosen == item.correctIndex
            if (right) score++
            onAnswered(index, chosen, right)
        }

        if (revealed) {
            val right = selected == item.correctIndex
            Column(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(if (right) Theme.success.copy(alpha = 0.12f) else Theme.danger.copy(alpha = 0.12f))
                    .padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Text(
                    if (right) "Correct" else "Not quite",
                    style = display(15).copy(color = if (right) Theme.success else Theme.danger),
                )
                if (item.explanation.isNotBlank()) {
                    Text(item.explanation, style = serif(15).copy(color = Theme.ink))
                }
            }

            PrimaryButton(
                if (index == items.lastIndex) "See your score" else "Next question",
                modifier = Modifier.fillMaxWidth(),
            ) {
                if (index == items.lastIndex) {
                    onFinished(score, answers.toList())
                } else {
                    index++
                    selected = null
                    revealed = false
                }
            }
        }
    }
}

/** The score card shown when a run ends. */
@Composable
fun ScoreCard(
    score: Int,
    total: Int,
    signedIn: Boolean,
    savedMessage: String,
    signedOutMessage: String,
    onRetake: () -> Unit,
    onSignIn: () -> Unit,
) {
    LyceumCard {
        Column(
            Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text("$score / $total", fontSize = 34.sp, color = Theme.crimson, style = display(34).copy(color = Theme.crimson))
            val pct = if (total > 0) (score * 100.0 / total).toInt() else 0
            Text(
                "$pct%",
                style = serif(16).copy(color = if (pct >= 70) Theme.success else Theme.inkSoft),
            )
            Text(
                if (signedIn) savedMessage else signedOutMessage,
                style = serif(14).copy(color = Theme.inkSoft, textAlign = TextAlign.Center),
            )
            if (!signedIn) {
                PrimaryButton("Sign in", onClick = onSignIn)
            }
            SecondaryButton("Try again", onClick = onRetake)
        }
    }
}
