package com.timpsonlyceum.lyceum.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Layers
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.timpsonlyceum.lyceum.auth.AuthViewModel
import com.timpsonlyceum.lyceum.model.ReviewGradeBody
import com.timpsonlyceum.lyceum.model.ReviewDeckResponse
import com.timpsonlyceum.lyceum.model.makeClientId
import com.timpsonlyceum.lyceum.net.Repository
import com.timpsonlyceum.lyceum.ui.components.*
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display
import com.timpsonlyceum.lyceum.ui.theme.serif
import kotlinx.coroutines.launch

/**
 * The daily spaced-repetition deck.
 *
 * This is the one tab that cannot be anonymous, and not by policy: the deck *is*
 * the student's own history of missed questions, scheduled per person. There is
 * nothing to show a visitor, so the gate explains that rather than just refusing.
 */
@Composable
fun ReviewScreen(auth: AuthViewModel, onSignIn: () -> Unit) {
    val user by auth.user.collectAsState()
    if (user == null) {
        SignInGate(
            icon = Icons.Filled.Layers,
            title = "Daily Review",
            message = "Review builds a deck from the questions you've missed and brings each one back " +
                "just before you'd forget it. That needs an account to remember what you've seen.",
            onSignIn = onSignIn,
        )
        return
    }

    val scope = rememberCoroutineScope()
    var deck by remember { mutableStateOf<ReviewDeckResponse?>(null) }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }
    var running by remember { mutableStateOf(false) }
    var finished by remember { mutableStateOf<Pair<Int, Int>?>(null) }

    suspend fun load() {
        loading = true
        runCatching { Repository.reviewDeck() }
            .onSuccess { deck = it; error = null }
            .onFailure { error = it.message ?: "Couldn't reach the server." }
        loading = false
    }

    LaunchedEffect(Unit) { load() }

    val cards = deck?.cards.orEmpty()

    Column(
        Modifier
            .fillMaxSize()
            .background(Theme.parchment)
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text("Daily Review", style = display(22).copy(color = Theme.crimson))

        when {
            loading -> LoadingScreen()
            error != null && cards.isEmpty() -> ErrorScreen("Couldn't load", error)

            finished != null -> {
                val (right, total) = finished!!
                LyceumCard {
                    Column(
                        Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Text("$right / $total", style = display(30).copy(color = Theme.crimson))
                        Text(
                            "Deck finished. What you missed comes back sooner; what you got right comes back later.",
                            style = serif(15).copy(color = Theme.inkSoft, textAlign = TextAlign.Center),
                        )
                        SecondaryButton("Reload the deck") {
                            finished = null
                            scope.launch { load() }
                        }
                    }
                }
            }

            running -> QuizRunner(
                items = cards.map { QuizItem(it.id, it.prompt, it.options, it.correctIndex, it.explanation) },
                onAnswered = { i, _, correct ->
                    // Each grade is posted as it happens rather than batched at the
                    // end, so a deck abandoned halfway still counts what was done.
                    val card = cards[i]
                    scope.launch {
                        runCatching {
                            Repository.gradeReview(ReviewGradeBody(card.id, correct, makeClientId()))
                        }
                    }
                },
            ) { score, _ ->
                running = false
                finished = score to cards.size
                scope.launch {
                    runCatching { Repository.finishReview() }
                    auth.refresh()
                }
            }

            else -> LyceumCard {
                val due = deck?.dueCount ?: 0
                Text(
                    if (due > 0) "$due card${if (due == 1) "" else "s"} due today across your courses."
                    else "You're all caught up — no cards due right now.",
                    style = serif(16).copy(color = Theme.ink),
                )
                Spacer(Modifier.height(12.dp))
                PrimaryButton("Start review", Modifier.fillMaxWidth(), enabled = cards.isNotEmpty()) {
                    running = true
                }
            }
        }
    }
}
