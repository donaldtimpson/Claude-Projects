package com.timpsonlyceum.lyceum.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.timpsonlyceum.lyceum.auth.AuthViewModel
import com.timpsonlyceum.lyceum.drills.*
import com.timpsonlyceum.lyceum.net.Repository
import com.timpsonlyceum.lyceum.ui.components.*
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display
import com.timpsonlyceum.lyceum.ui.theme.serif

/**
 * The drills hub.
 *
 * Two levels, as on iOS: a Continue strip of what you last opened, then seven
 * category rows you drill into. Sixty-one drills in one flat list is a wall, and
 * the categories are also what make the search results meaningful — a drill
 * matches on its category name as well as its own title and blurb.
 */
@Composable
fun DrillsScreen(auth: AuthViewModel, onSignIn: () -> Unit) {
    val user by auth.user.collectAsState()
    val userId = user?.id ?: "guest"

    var query by remember { mutableStateOf("") }
    var openSlug by remember { mutableStateOf<String?>(null) }
    var openCategory by remember { mutableStateOf<DrillCategoryRoute?>(null) }
    // Bumped after /me/lessons lands so the ✦ marks re-render.
    var acedRefresh by remember { mutableIntStateOf(0) }

    // The server derives ✦ from a flawless homework run; merge it in so the marks
    // follow the student across devices. A local mark still shows instantly.
    LaunchedEffect(userId) {
        if (user != null) {
            runCatching { Repository.lessons() }.onSuccess {
                DrillStore.setServerAced(userId, it.acedSlugs)
                acedRefresh++
            }
        }
    }

    val slug = openSlug
    if (slug != null) {
        val def = DrillEngine.drill(slug)
        if (def != null) {
            DrillSetupAndRun(def, auth, onSignIn) { openSlug = null }
            return
        }
        openSlug = null
    }

    fun open(s: String) {
        DrillStore.noteOpened(s)
        openSlug = s
    }

    val category = openCategory
    if (category != null) {
        CategoryDrillsScreen(category, userId, acedRefresh, onOpen = ::open) { openCategory = null }
        return
    }

    Column(Modifier.fillMaxSize().background(Theme.parchment)) {
        Text(
            "Practice Drills",
            style = display(22).copy(color = Theme.crimson),
            modifier = Modifier.padding(start = 16.dp, top = 16.dp),
        )
        DrillSearchField(query) { query = it }

        if (query.isBlank()) {
            BrowseList(userId, acedRefresh, onOpen = ::open) { openCategory = it }
        } else {
            SearchList(query, userId, acedRefresh, onOpen = ::open) { openCategory = it }
        }
    }
}

@Composable
private fun DrillSearchField(query: String, onChange: (String) -> Unit) {
    OutlinedTextField(
        value = query,
        onValueChange = onChange,
        modifier = Modifier.fillMaxWidth().padding(16.dp),
        placeholder = { Text("Search drills", style = serif(15).copy(color = Theme.inkSoft)) },
        leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null, tint = Theme.gold400) },
        singleLine = true,
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
private fun BrowseList(
    userId: String,
    acedRefresh: Int,
    onOpen: (String) -> Unit,
    onCategory: (DrillCategoryRoute) -> Unit,
) {
    val recents = remember(acedRefresh) { DrillStore.recents().mapNotNull { DrillEngine.drill(it) } }
    val categories = remember(acedRefresh) { DrillCategories.all }

    LazyColumn(
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        if (recents.isNotEmpty()) {
            item { DrillSectionHeader("Continue") }
            item {
                Row(
                    Modifier.horizontalScroll(rememberScrollState()).padding(bottom = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    recents.forEach { RecentTile(it, userId) { onOpen(it.slug) } }
                }
            }
        }
        item { DrillSectionHeader("Categories") }
        items(categories, key = { it.title }) { cat ->
            CategoryRow(cat, userId) { onCategory(cat) }
        }
    }
}

@Composable
private fun SearchList(
    query: String,
    userId: String,
    acedRefresh: Int,
    onOpen: (String) -> Unit,
    onCategory: (DrillCategoryRoute) -> Unit,
) {
    val q = query.trim()
    val cats = DrillCategories.all.filter { it.title.contains(q, ignoreCase = true) }
    // Matching on the category name too is why "geography" finds Name the Country.
    val drills = DrillEngine.all.filter { d ->
        "${d.title} ${d.blurb} ${DrillCategories.titleFor(d.slug)}".contains(q, ignoreCase = true)
    }

    LazyColumn(
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        if (cats.isEmpty() && drills.isEmpty()) {
            item {
                Text(
                    "No matches for “$query”.",
                    style = serif(16).copy(color = Theme.inkSoft, textAlign = TextAlign.Center),
                    modifier = Modifier.fillMaxWidth().padding(top = 40.dp),
                )
            }
        }
        if (cats.isNotEmpty()) {
            item { DrillSectionHeader("Categories") }
            items(cats, key = { "c-" + it.title }) { cat ->
                CategoryRow(cat, userId, query) { onCategory(cat) }
            }
        }
        if (drills.isNotEmpty()) {
            item { DrillSectionHeader("Drills") }
            items(drills, key = { "d-" + it.slug }) { d ->
                DrillRow(d, userId, query) { onOpen(d.slug) }
            }
        }
    }
}

/** One category's drills, as full-width rows. */
@Composable
private fun CategoryDrillsScreen(
    route: DrillCategoryRoute,
    userId: String,
    acedRefresh: Int,
    onOpen: (String) -> Unit,
    onBack: () -> Unit,
) {
    val drills = remember(route.title, acedRefresh) { DrillCategories.drills(route) }
    Column(Modifier.fillMaxSize().background(Theme.parchment)) {
        Row(
            Modifier.fillMaxWidth().padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(route.icon, fontSize = 26.sp)
            Spacer(Modifier.width(10.dp))
            Text(route.title, style = display(22).copy(color = Theme.crimson), modifier = Modifier.weight(1f))
            TextButton(onClick = onBack) {
                Text("Back", style = serif(15).copy(color = Theme.gold400))
            }
        }
        LazyColumn(
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            items(drills, key = { it.slug }) { d -> DrillRow(d, userId) { onOpen(d.slug) } }
        }
    }
}

@Composable
private fun DrillSectionHeader(title: String) {
    Text(
        title,
        style = display(15).copy(color = Theme.gold400, letterSpacing = 1.sp),
        modifier = Modifier.padding(top = 12.dp),
    )
}

@Composable
private fun CategoryRow(
    cat: DrillCategoryRoute,
    userId: String,
    query: String = "",
    onClick: () -> Unit,
) {
    LyceumCard(onClick = onClick, modifier = Modifier.testTag("drillCategoryRow")) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(cat.icon, fontSize = 32.sp)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    searchHighlighted(cat.title, query),
                    style = display(16).copy(color = Theme.ink),
                )
                Spacer(Modifier.height(2.dp))
                // The lessons row counts ✦ earned, not drills available — that is
                // the number a student actually wants from it.
                if (DrillCategories.isLessons(cat)) {
                    val aced = DrillStore.acedCount(userId, cat.slugs)
                    Text(
                        if (aced > 0) "✦ $aced/${cat.slugs.size} aced" else "${cat.slugs.size} lessons",
                        style = serif(14).copy(color = if (aced > 0) Theme.gold400 else Theme.inkSoft),
                    )
                } else {
                    Text("${cat.slugs.size} drills", style = serif(14).copy(color = Theme.inkSoft))
                }
            }
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = Theme.inkSoft)
        }
    }
}

/** The shared full-width drill row: icon, title, blurb, and its ✦ or mastery line. */
@Composable
fun DrillRow(drill: DrillDef, userId: String, query: String = "", onClick: () -> Unit) {
    LyceumCard(onClick = onClick, modifier = Modifier.testTag("drillRow")) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(drill.icon, fontSize = 34.sp)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(searchHighlighted(drill.title, query), style = display(16).copy(color = Theme.ink))
                Spacer(Modifier.height(2.dp))
                Text(
                    searchHighlighted(drill.blurb, query),
                    style = serif(14).copy(color = Theme.inkSoft),
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                DrillSubtitle(drill, userId)
            }
        }
    }
}

/** "✦ Aced" for a finished lesson, else "n/N mastered" for a Learnable drill. */
@Composable
private fun DrillSubtitle(drill: DrillDef, userId: String) {
    if (DrillStore.isAced(userId, drill.slug)) {
        Spacer(Modifier.height(2.dp))
        Text("✦ Aced", style = serif(13).copy(color = Theme.gold300))
        return
    }
    val sub = masterySubtitle(drill, userId) ?: return
    Spacer(Modifier.height(2.dp))
    Text(sub, style = serif(13).copy(color = Theme.gold400))
}

/**
 * A drill's Learn pool, built once per slug.
 *
 * `poolItems` rebuilds its list on every call, and for the map drills that is
 * what forces the atlas to parse — so calling it straight from a composable
 * redid that work on every recomposition.
 */
private val poolItemsCache = mutableMapOf<String, List<String>>()

fun masterySubtitle(d: DrillDef, userId: String): String? {
    val pool = d.poolItems ?: return null
    val items = poolItemsCache.getOrPut(d.slug) { pool(3) }
    val m = DrillStore.masteredCount(userId, d.slug, items)
    return if (m > 0) "$m/${items.size} mastered" else null
}

@Composable
private fun RecentTile(d: DrillDef, userId: String, onClick: () -> Unit) {
    val shape = RoundedCornerShape(12.dp)
    Column(
        Modifier
            .size(width = 128.dp, height = 124.dp)
            .clip(shape)
            .background(Theme.card)
            .border(1.dp, Theme.line, shape)
            .clickable(onClick = onClick)
            .padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(d.icon, fontSize = 40.sp)
        Spacer(Modifier.height(6.dp))
        Text(
            d.title,
            style = serif(14).copy(color = Theme.ink, textAlign = TextAlign.Center),
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        if (DrillStore.isAced(userId, d.slug)) {
            Text("✦ Aced", style = serif(12).copy(color = Theme.gold300))
        } else {
            masterySubtitle(d, userId)?.let {
                Text(it, style = serif(12).copy(color = Theme.gold400))
            }
        }
    }
}
