package com.timpsonlyceum.lyceum.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.timpsonlyceum.lyceum.model.*
import com.timpsonlyceum.lyceum.net.Repository
import com.timpsonlyceum.lyceum.ui.components.*
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display
import com.timpsonlyceum.lyceum.ui.theme.serif
import kotlinx.coroutines.delay

/**
 * The catalog — the app's front door, signed in or not.
 *
 * Search is deliberately hybrid, as on iOS: course and category titles filter
 * instantly from what is already loaded, while the lecture search needs the
 * server (it reads notes and transcripts) and fills in underneath after a
 * debounce. Typing therefore never feels like it is waiting on a round trip.
 */
@Composable
fun CatalogScreen(
    onOpenCourse: (String) -> Unit,
    onOpenCategory: (CategoryItem) -> Unit,
    onOpenLecture: (courseId: String, videoId: String) -> Unit,
) {
    var courses by remember { mutableStateOf<List<CourseListItem>>(emptyList()) }
    var categories by remember { mutableStateOf<List<CategoryItem>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }

    var query by remember { mutableStateOf("") }
    var results by remember { mutableStateOf<SearchResults?>(null) }
    var searching by remember { mutableStateOf(false) }

    suspend fun loadCatalog() {
        loading = courses.isEmpty()
        val c = runCatching { Repository.courses() }.getOrNull()
        val cats = runCatching { Repository.categories() }.getOrNull()
        if (c != null) {
            courses = c.courses
            error = null
        } else if (courses.isEmpty()) {
            error = "Couldn't reach the server."
        }
        categories = cats?.categories ?: emptyList()
        loading = false
    }

    LaunchedEffect(Unit) { if (courses.isEmpty()) loadCatalog() }

    // Debounced server search. Re-running on every keystroke cancels the previous
    // effect, which is the debounce.
    LaunchedEffect(query) {
        val q = query.trim()
        if (q.isEmpty()) {
            results = null
            searching = false
            return@LaunchedEffect
        }
        searching = true
        delay(300)
        results = runCatching { Repository.search(q) }.getOrElse { SearchResults() }
        searching = false
    }

    Column(Modifier.fillMaxSize().background(Theme.parchment)) {
        SearchField(query, onChange = { query = it })

        when {
            query.isNotBlank() -> SearchResultsList(
                query = query,
                courses = courses,
                categories = categories,
                lectureHits = results?.lectures ?: emptyList(),
                searching = searching,
                onOpenCourse = onOpenCourse,
                onOpenCategory = onOpenCategory,
                onOpenLecture = onOpenLecture,
            )
            loading -> LoadingScreen()
            error != null -> ErrorScreen("Couldn't load courses", error)
            else -> CatalogList(courses, categories, onOpenCourse, onOpenCategory)
        }
    }
}

@Composable
private fun SearchField(query: String, onChange: (String) -> Unit) {
    OutlinedTextField(
        value = query,
        onValueChange = onChange,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        placeholder = { Text("Search courses & lectures", style = serif(15).copy(color = Theme.inkSoft)) },
        leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null, tint = Theme.gold400) },
        singleLine = true,
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
        textStyle = serif(16).copy(color = Theme.ink),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = Theme.gold400,
            unfocusedBorderColor = Theme.line,
            cursorColor = Theme.gold300,
            focusedContainerColor = Theme.card,
            unfocusedContainerColor = Theme.card,
        ),
    )
}

@Composable
private fun CatalogList(
    courses: List<CourseListItem>,
    categories: List<CategoryItem>,
    onOpenCourse: (String) -> Unit,
    onOpenCategory: (CategoryItem) -> Unit,
) {
    val current = courses.filter { it.isCurrent }
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (current.isNotEmpty()) {
            item { SectionHeader("Currently Teaching") }
            items(current, key = { "current-" + it.id }) { CourseRow(it) { onOpenCourse(it.id) } }
        }
        if (categories.isNotEmpty()) {
            item { SectionHeader("Browse by Category") }
            items(categories, key = { "cat-" + it.id }) { CategoryRow(it) { onOpenCategory(it) } }
        }
        item { SectionHeader("All Courses") }
        items(courses, key = { "all-" + it.id }) { CourseRow(it) { onOpenCourse(it.id) } }
    }
}

@Composable
private fun SearchResultsList(
    query: String,
    courses: List<CourseListItem>,
    categories: List<CategoryItem>,
    lectureHits: List<LectureHit>,
    searching: Boolean,
    onOpenCourse: (String) -> Unit,
    onOpenCategory: (CategoryItem) -> Unit,
    onOpenLecture: (String, String) -> Unit,
) {
    val q = query.trim().lowercase()
    val courseHits = courses.filter { it.title.lowercase().contains(q) }
    val categoryHits = categories.filter { it.name.lowercase().contains(q) }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (courseHits.isNotEmpty()) {
            item { SectionHeader("Courses") }
            items(courseHits, key = { "sc-" + it.id }) {
                CourseRow(it, highlight = query) { onOpenCourse(it.id) }
            }
        }
        if (categoryHits.isNotEmpty()) {
            item { SectionHeader("Categories") }
            items(categoryHits, key = { "sg-" + it.id }) {
                CategoryRow(it, highlight = query) { onOpenCategory(it) }
            }
        }
        if (searching || lectureHits.isNotEmpty()) {
            item { SectionHeader("In Lectures") }
            if (searching) {
                item {
                    Row(
                        Modifier.fillMaxWidth().padding(vertical = 8.dp),
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        CircularProgressIndicator(Modifier.size(18.dp), color = Theme.gold300, strokeWidth = 2.dp)
                        Spacer(Modifier.width(8.dp))
                        Text("Searching lectures…", style = serif(14).copy(color = Theme.inkSoft))
                    }
                }
            } else {
                items(lectureHits, key = { "sl-" + it.videoId }) { hit ->
                    LectureHitRow(hit) { onOpenLecture(hit.courseId, hit.videoId) }
                }
            }
        }
        if (courseHits.isEmpty() && categoryHits.isEmpty() && lectureHits.isEmpty() && !searching) {
            item {
                Text(
                    "No results for “$query”.",
                    style = serif(16).copy(color = Theme.inkSoft, textAlign = TextAlign.Center),
                    modifier = Modifier.fillMaxWidth().padding(top = 32.dp),
                )
            }
        }
    }
}

@Composable
private fun LectureHitRow(hit: LectureHit, onClick: () -> Unit) {
    LyceumCard(onClick = onClick) {
        Text(
            hit.title,
            style = display(14).copy(color = Theme.ink, letterSpacing = 0.3.sp),
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        Spacer(Modifier.height(4.dp))
        Text(hit.courseTitle, style = serif(13).copy(color = Theme.gold400))
        val snippet = hit.snippet?.replace("[[hl]]", "")?.replace("[[/hl]]", "")
        if (!snippet.isNullOrBlank()) {
            Spacer(Modifier.height(4.dp))
            Text(
                snippet,
                style = serif(14).copy(color = Theme.inkSoft),
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}
