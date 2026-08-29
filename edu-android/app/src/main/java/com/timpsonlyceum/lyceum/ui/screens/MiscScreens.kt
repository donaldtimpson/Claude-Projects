package com.timpsonlyceum.lyceum.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.timpsonlyceum.lyceum.auth.AuthViewModel
import com.timpsonlyceum.lyceum.model.*
import com.timpsonlyceum.lyceum.net.Repository
import com.timpsonlyceum.lyceum.ui.components.*
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display
import com.timpsonlyceum.lyceum.ui.theme.serif
import kotlinx.coroutines.launch

/**
 * The Hall of Scholars.
 *
 * The board itself is public and stays readable signed out; only "your standing"
 * needs an account, and it says what signing in buys rather than hiding the
 * rankings behind a wall.
 */
@Composable
fun ScholarsScreen(auth: AuthViewModel, onSignIn: () -> Unit) {
    val user by auth.user.collectAsState()
    var board by remember { mutableStateOf<LeaderboardResponse?>(null) }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        loading = true
        runCatching { Repository.leaderboard() }
            .onSuccess { board = it; error = null }
            .onFailure { error = it.message ?: "Couldn't reach the server." }
        loading = false
    }

    val entries = board?.scholars.orEmpty()
    val myIndex = entries.indexOfFirst { it.scholar.userId != null && it.scholar.userId == user?.id }

    when {
        loading -> LoadingScreen()
        entries.isEmpty() -> ErrorScreen("Couldn't load the Hall", error)
        else -> LazyColumn(
            Modifier.fillMaxSize().background(Theme.parchment),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item { Text("Hall of Scholars", style = display(22).copy(color = Theme.crimson)) }

            item { SectionHeader("Your Standing") }
            item {
                when {
                    myIndex >= 0 -> ScholarRow(entries[myIndex], myIndex + 1, isMe = true)
                    user != null -> LyceumCard {
                        Text(
                            "You're not on the board yet. Watch a lecture or take a quiz and you'll claim your place in the Hall.",
                            style = serif(15).copy(color = Theme.inkSoft),
                        )
                    }
                    else -> LyceumCard {
                        SignInPrompt(
                            message = "Sign in to earn a place in the Hall of Scholars.",
                            onSignIn = onSignIn,
                        )
                    }
                }
            }

            item { SectionHeader("The Board") }
            items(entries.size) { i -> ScholarRow(entries[i], i + 1, isMe = i == myIndex) }
        }
    }
}

@Composable
private fun ScholarRow(entry: ScholarEntry, rank: Int, isMe: Boolean) {
    LyceumCard {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("$rank", style = display(16).copy(color = Theme.gold400), modifier = Modifier.width(34.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    entry.scholar.handle + if (isMe) " · you" else "",
                    style = display(15).copy(color = if (isMe) Theme.gold300 else Theme.ink),
                )
                entry.blurb?.let {
                    Spacer(Modifier.height(2.dp))
                    Text(it, style = serif(13).copy(color = Theme.inkSoft))
                }
            }
            Text("${entry.scholar.standing}", style = display(16).copy(color = Theme.gold300))
        }
    }
}

/**
 * The course map — which courses lead into which.
 *
 * The iOS app draws this as a pannable graph; here it is grouped by course with
 * its prerequisites listed underneath, which carries the same information a
 * student actually acts on ("what should I take before this?") without a custom
 * canvas. A graph rendering is the obvious next step.
 */
@Composable
fun CourseMapScreen(onOpenCourse: (String) -> Unit) {
    var map by remember { mutableStateOf<CourseMapResponse?>(null) }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        loading = true
        runCatching { Repository.courseMap() }
            .onSuccess { map = it; error = null }
            .onFailure { error = it.message ?: "Couldn't reach the server." }
        loading = false
    }

    val courses = map?.courses.orEmpty()
    val links = map?.links.orEmpty()
    val byId = courses.associateBy { it.id }

    when {
        loading -> LoadingScreen()
        courses.isEmpty() -> ErrorScreen("Couldn't load the map", error)
        else -> LazyColumn(
            Modifier.fillMaxSize().background(Theme.parchment),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item { Text("Course Map", style = display(22).copy(color = Theme.crimson)) }
            item {
                Text(
                    "What leads into what. These are logical dependencies, not college prerequisites.",
                    style = serif(15).copy(color = Theme.inkSoft),
                )
            }
            items(courses, key = { it.id }) { course ->
                val leadsIn = links.filter { it.toCourseId == course.id }
                    .mapNotNull { byId[it.fromCourseId]?.nodeLabel }
                LyceumCard(onClick = { onOpenCourse(course.id) }) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(course.nodeLabel, style = display(16).copy(color = Theme.ink), modifier = Modifier.weight(1f))
                        if (course.isCurrent == true) LivePill()
                    }
                    if (leadsIn.isNotEmpty()) {
                        Spacer(Modifier.height(6.dp))
                        Text(
                            "After: " + leadsIn.joinToString(", "),
                            style = serif(14).copy(color = Theme.inkSoft),
                        )
                    }
                }
            }
        }
    }
}

/** The course test: the whole course's published questions in one run. */
@Composable
fun CourseTestScreen(
    courseId: String,
    title: String,
    auth: AuthViewModel,
    onSignIn: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    val user by auth.user.collectAsState()
    val signedIn = user != null

    var questions by remember(courseId) { mutableStateOf<List<QuizQuestion>>(emptyList()) }
    var loading by remember(courseId) { mutableStateOf(true) }
    var error by remember(courseId) { mutableStateOf<String?>(null) }
    var running by remember(courseId) { mutableStateOf(false) }
    var score by remember(courseId) { mutableStateOf<Pair<Int, Int>?>(null) }

    LaunchedEffect(courseId) {
        loading = true
        runCatching { Repository.courseTest(courseId) }
            .onSuccess { questions = it.questions; error = null }
            .onFailure { error = it.message ?: "Couldn't reach the server." }
        loading = false
    }

    Column(
        Modifier
            .fillMaxSize()
            .background(Theme.parchment)
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text("Course Test", style = display(22).copy(color = Theme.crimson))
        Text(title, style = serif(15).copy(color = Theme.inkSoft))

        when {
            loading -> LoadingScreen()
            questions.isEmpty() -> ErrorScreen("No test yet", error ?: "This course has no published test.")

            score != null -> ScoreCard(
                score = score!!.first,
                total = score!!.second,
                signedIn = signedIn,
                savedMessage = "Saved. Your best attempt counts toward your standing.",
                signedOutMessage = "This result isn't saved. An account keeps your best attempt and counts it toward your standing.",
                onRetake = { score = null; running = true },
                onSignIn = onSignIn,
            )

            running -> QuizRunner(
                items = questions.map { QuizItem(it.id, it.prompt, it.options, it.correctIndex, it.explanation) },
            ) { s, answers ->
                score = s to questions.size
                running = false
                if (signedIn) {
                    scope.launch {
                        runCatching {
                            Repository.recordQuizAttempt(
                                QuizAttemptBody(
                                    videoId = null,
                                    courseId = courseId,
                                    score = s,
                                    total = questions.size,
                                    answers = answers,
                                    clientId = makeClientId(),
                                )
                            )
                        }
                        auth.refresh()
                    }
                }
            }

            else -> LyceumCard {
                Text(
                    "${questions.size} questions covering the whole course. " +
                        "70% is the pass mark the standing engine uses.",
                    style = serif(15).copy(color = Theme.ink),
                )
                Spacer(Modifier.height(12.dp))
                PrimaryButton("Start the test", Modifier.fillMaxWidth()) { running = true }
            }
        }
    }
}

/**
 * A problem set: the problems, and the worked solutions where they are released.
 *
 * The server does the pairing, so the split rules live in one place; "paired"
 * carries per-problem parts, "blocks" means the two halves didn't line up and
 * the solutions arrive as one appended lump.
 */
@Composable
fun ProblemSetScreen(courseId: String, problemSetId: String) {
    var detail by remember(problemSetId) { mutableStateOf<ProblemSetDetail?>(null) }
    var loading by remember(problemSetId) { mutableStateOf(true) }
    var error by remember(problemSetId) { mutableStateOf<String?>(null) }
    var showSolutions by remember(problemSetId) { mutableStateOf(false) }

    LaunchedEffect(problemSetId) {
        loading = true
        runCatching { Repository.problemSet(courseId, problemSetId) }
            .onSuccess { detail = it.problemSet; error = null }
            .onFailure { error = it.message ?: "Couldn't reach the server." }
        loading = false
    }

    val d = detail
    when {
        loading -> LoadingScreen()
        d == null -> ErrorScreen("Couldn't load", error)
        else -> LazyColumn(
            Modifier.fillMaxSize().background(Theme.parchment),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item {
                Column {
                    Text(d.title, style = display(20).copy(color = Theme.ink))
                    Spacer(Modifier.height(4.dp))
                    val bits = buildList {
                        add("${d.points} points")
                        if (d.extraCreditPoints > 0) add("${d.extraCreditPoints} extra credit")
                    }
                    Text(bits.joinToString(" · "), style = serif(14).copy(color = Theme.inkSoft))
                }
            }

            if (d.solutionsAvailable) {
                item {
                    SecondaryButton(
                        if (showSolutions) "Hide solutions" else "Show solutions",
                        Modifier.fillMaxWidth(),
                    ) { showSolutions = !showSolutions }
                }
            }

            d.content.problemsPreamble?.takeIf { it.isNotBlank() }?.let {
                item { MathWebView(it) }
            }

            if (d.content.isPaired) {
                val parts = d.content.parts.orEmpty()
                items(parts, key = { it.key }) { part ->
                    LyceumCard {
                        Text(part.label, style = display(15).copy(color = Theme.gold400))
                        Spacer(Modifier.height(6.dp))
                        MathWebView(part.problem)
                        if (showSolutions) {
                            part.solution?.takeIf { it.isNotBlank() }?.let { sol ->
                                Spacer(Modifier.height(10.dp))
                                Text("Solution", style = display(14).copy(color = Theme.success))
                                MathWebView(sol)
                            }
                        }
                    }
                }
            } else {
                d.content.body?.takeIf { it.isNotBlank() }?.let { item { MathWebView(it) } }
                if (showSolutions) {
                    d.content.solution?.takeIf { it.isNotBlank() }?.let {
                        item { SectionHeader("Solutions") }
                        item { MathWebView(it) }
                    }
                }
            }
        }
    }
}
