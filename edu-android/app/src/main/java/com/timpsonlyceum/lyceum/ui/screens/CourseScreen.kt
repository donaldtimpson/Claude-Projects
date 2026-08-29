package com.timpsonlyceum.lyceum.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavHostController
import com.timpsonlyceum.lyceum.model.CourseDetail
import com.timpsonlyceum.lyceum.model.ProblemSetItem
import com.timpsonlyceum.lyceum.net.Repository
import com.timpsonlyceum.lyceum.ui.Routes
import com.timpsonlyceum.lyceum.ui.components.*
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display
import com.timpsonlyceum.lyceum.ui.theme.serif

/**
 * One course: its description, the course test if it has one, its lectures, its
 * problem sets, and the other years it has been taught.
 */
@Composable
fun CourseScreen(courseId: String, nav: NavHostController) {
    var course by remember(courseId) { mutableStateOf<CourseDetail?>(null) }
    var loading by remember(courseId) { mutableStateOf(true) }
    var error by remember(courseId) { mutableStateOf<String?>(null) }

    LaunchedEffect(courseId) {
        loading = true
        runCatching { Repository.course(courseId) }
            .onSuccess { course = it.course; error = null }
            .onFailure { error = it.message ?: "Couldn't reach the server." }
        loading = false
    }

    when {
        loading -> LoadingScreen()
        course == null -> ErrorScreen("Couldn't load", error)
        else -> CourseBody(course!!, nav)
    }
}

@Composable
private fun CourseBody(course: CourseDetail, nav: NavHostController) {
    LazyColumn(
        Modifier.fillMaxSize().background(Theme.parchment),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            Text(
                course.shortTitle ?: course.title,
                style = display(20).copy(color = Theme.ink, letterSpacing = 0.5.sp),
            )
        }
        if (course.description.isNotBlank()) {
            item { Text(course.description, style = serif(15).copy(color = Theme.inkSoft)) }
        }

        // The course test only exists once questions are published; 0 means there
        // is nothing to offer, so nothing is shown.
        val testCount = course.testQuestionCount ?: 0
        if (testCount > 0) {
            item {
                LyceumCard(onClick = { nav.navigate(Routes.courseTest(course.id, course.title)) }) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("📜", fontSize = 26.sp)
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text("Course Test", style = display(15).copy(color = Theme.ink))
                            Text(
                                "$testCount questions covering the whole course",
                                style = serif(14).copy(color = Theme.inkSoft),
                            )
                        }
                    }
                }
            }
        }

        if (course.videos.isNotEmpty()) {
            item { SectionHeader("Lectures") }
            items(course.videos, key = { it.id }) { video ->
                LectureRow(video) { nav.navigate(Routes.lecture(course.id, video.id)) }
            }
        }

        if (course.problemSets.isNotEmpty()) {
            item { SectionHeader("Practice") }
            items(course.problemSets, key = { it.id }) { set ->
                ProblemSetRow(set) { nav.navigate(Routes.problemSet(course.id, set.id)) }
            }
        }

        val offerings = course.offerings.orEmpty()
        if (offerings.isNotEmpty()) {
            item { SectionHeader("Other Years") }
            items(offerings, key = { it.id }) { offering ->
                LyceumCard(onClick = { nav.navigate(Routes.course(offering.id)) }) {
                    Text(
                        offering.title,
                        style = display(15).copy(color = Theme.ink, letterSpacing = 0.5.sp),
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                    offering.year?.let {
                        Spacer(Modifier.height(4.dp))
                        Text("$it", style = serif(14).copy(color = Theme.inkSoft))
                    }
                }
            }
        }
    }
}

@Composable
fun ProblemSetRow(set: ProblemSetItem, onClick: () -> Unit) {
    LyceumCard(onClick = onClick) {
        Text(
            set.title,
            style = display(15).copy(color = Theme.ink, letterSpacing = 0.5.sp),
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        val bits = buildList {
            set.lectureSpan?.let { add(it) }
            add("${set.points} points")
            if (set.hasSolutions == true) add("solutions")
        }
        Spacer(Modifier.height(4.dp))
        Text(bits.joinToString(" · "), style = serif(14).copy(color = Theme.inkSoft))
    }
}

/** A category's courses. */
@Composable
fun CategoryScreen(slug: String, name: String, onOpenCourse: (String) -> Unit) {
    var courses by remember(slug) { mutableStateOf<List<com.timpsonlyceum.lyceum.model.CourseListItem>>(emptyList()) }
    var loading by remember(slug) { mutableStateOf(true) }
    var error by remember(slug) { mutableStateOf<String?>(null) }

    LaunchedEffect(slug) {
        loading = true
        runCatching { Repository.category(slug) }
            .onSuccess { courses = it.courses; error = null }
            .onFailure { error = it.message ?: "Couldn't reach the server." }
        loading = false
    }

    when {
        loading -> LoadingScreen()
        error != null && courses.isEmpty() -> ErrorScreen("Couldn't load $name", error)
        else -> LazyColumn(
            Modifier.fillMaxSize().background(Theme.parchment),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item { SectionHeader(name) }
            items(courses, key = { it.id }) { CourseRow(it) { onOpenCourse(it.id) } }
        }
    }
}
