package com.timpsonlyceum.lyceum.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavHostController
import com.timpsonlyceum.lyceum.auth.AuthViewModel
import com.timpsonlyceum.lyceum.model.*
import com.timpsonlyceum.lyceum.net.Repository
import com.timpsonlyceum.lyceum.ui.Routes
import com.timpsonlyceum.lyceum.ui.components.*
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display
import com.timpsonlyceum.lyceum.ui.theme.serif
import kotlinx.coroutines.launch

/**
 * A lecture: the video, its written notes, and its quiz.
 *
 * Everything here works signed out. An account only changes what is *kept* — the
 * watched mark and the quiz score — which is why the sign-in prompt lives on the
 * result card rather than in front of the screen.
 *
 * Lecture discussion is deliberately absent, as on iOS: comments are
 * user-generated content and Guideline 1.2 wants reporting and blocking, which
 * does not exist yet. The endpoints are in [Repository] ready for when it does.
 */
@Composable
fun LectureScreen(
    courseId: String,
    videoId: String,
    auth: AuthViewModel,
    nav: NavHostController,
) {
    val scope = rememberCoroutineScope()
    val user by auth.user.collectAsState()
    val signedIn = user != null

    var detail by remember(videoId) { mutableStateOf<VideoDetailResponse?>(null) }
    var loading by remember(videoId) { mutableStateOf(true) }
    var error by remember(videoId) { mutableStateOf<String?>(null) }
    var videoError by remember(videoId) { mutableStateOf<Int?>(null) }
    var tab by remember(videoId) { mutableIntStateOf(0) }

    var quizRunning by remember(videoId) { mutableStateOf(false) }
    var quizScore by remember(videoId) { mutableStateOf<Pair<Int, Int>?>(null) }

    LaunchedEffect(courseId, videoId) {
        loading = true
        runCatching { Repository.video(courseId, videoId) }
            .onSuccess { detail = it; error = null }
            .onFailure { error = it.message ?: "Couldn't reach the server." }
        loading = false

        // Watching is recorded on open, the same moment the iOS app records it.
        // Signed out there is nowhere to record it to, so it is simply skipped.
        if (signedIn) {
            runCatching {
                Repository.recordVideoWatched(VideoWatchedBody(videoId, makeClientId()))
            }
        }
    }

    val d = detail
    when {
        loading -> LoadingScreen()
        d == null -> ErrorScreen("Couldn't load lecture", error)
        else -> LazyColumn(
            Modifier.fillMaxSize().background(Theme.parchment).testTag("lectureScreen"),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                Text(
                    d.video.title,
                    style = display(20).copy(color = Theme.ink, letterSpacing = 0.5.sp),
                )
            }
            item {
                YouTubePlayer(
                    videoId = d.video.youtubeVideoId,
                    modifier = Modifier
                        .fillMaxWidth()
                        .aspectRatio(16f / 9f)
                        .clip(androidx.compose.foundation.shape.RoundedCornerShape(12.dp)),
                    onError = { videoError = it },
                )
            }
            videoError?.let { code ->
                item {
                    Text(youtubeErrorMessage(code), style = serif(13).copy(color = Theme.inkSoft))
                }
            }

            // Practice sits above the tabs rather than becoming a third segment:
            // it is navigation to another screen, not another view of this
            // lecture's own content.
            val sets = d.problemSets.orEmpty()
            if (sets.isNotEmpty()) {
                item { SectionHeader("Practice") }
                items(sets, key = { it.id }) { set ->
                    ProblemSetRow(set) { nav.navigate(Routes.problemSet(courseId, set.id)) }
                }
            }

            item {
                TabRow(
                    selectedTabIndex = tab,
                    containerColor = Theme.card,
                    contentColor = Theme.gold300,
                ) {
                    Tab(
                        selected = tab == 0,
                        onClick = { tab = 0 },
                        text = { Text("Notes", style = display(14).copy(color = if (tab == 0) Theme.gold300 else Theme.inkSoft)) },
                    )
                    Tab(
                        selected = tab == 1,
                        onClick = { tab = 1 },
                        text = { Text("Quiz (${d.quiz.size})", style = display(14).copy(color = if (tab == 1) Theme.gold300 else Theme.inkSoft)) },
                    )
                }
            }

            if (tab == 0) {
                item {
                    val note = d.note
                    if (note == null || note.content.isBlank()) {
                        Text(
                            "No notes for this lecture yet.",
                            style = serif(15).copy(color = Theme.inkSoft),
                        )
                    } else {
                        MathWebView(note.content)
                    }
                }
            } else {
                item {
                    val score = quizScore
                    when {
                        score != null -> ScoreCard(
                            score = score.first,
                            total = score.second,
                            signedIn = signedIn,
                            savedMessage = "Saved. Questions you missed will come back in your daily review.",
                            signedOutMessage = "This score isn't saved. An account keeps your scores and feeds them into daily review.",
                            onRetake = { quizScore = null; quizRunning = true },
                            onSignIn = { nav.navigate(Routes.SIGN_IN) },
                        )
                        quizRunning -> QuizRunner(
                            items = d.quiz.map {
                                QuizItem(it.id, it.prompt, it.options, it.correctIndex, it.explanation)
                            },
                        ) { s, answers ->
                            quizScore = s to d.quiz.size
                            quizRunning = false
                            if (signedIn) {
                                scope.launch {
                                    runCatching {
                                        Repository.recordQuizAttempt(
                                            QuizAttemptBody(
                                                videoId = d.video.id,
                                                courseId = courseId,
                                                score = s,
                                                total = d.quiz.size,
                                                answers = answers,
                                                clientId = makeClientId(),
                                            )
                                        )
                                    }
                                    auth.refresh()
                                }
                            }
                        }
                        d.quiz.isEmpty() -> Text(
                            "No quiz for this lecture yet.",
                            style = serif(15).copy(color = Theme.inkSoft),
                        )
                        else -> Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            Text(
                                "${d.quiz.size} questions, with an explanation on every answer.",
                                style = serif(15).copy(color = Theme.inkSoft),
                            )
                            PrimaryButton("Start the quiz", Modifier.fillMaxWidth()) { quizRunning = true }
                        }
                    }
                }
            }
        }
    }
}
