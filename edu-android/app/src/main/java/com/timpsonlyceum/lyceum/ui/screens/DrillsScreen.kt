package com.timpsonlyceum.lyceum.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
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

/**
 * Practice drills.
 *
 * Everything here runs on-device and offline: the generators are pure functions,
 * so a drill needs no network at any point. Signing in only adds the saved score.
 */
@Composable
fun DrillsScreen(auth: AuthViewModel, onSignIn: () -> Unit) {
    var openSlug by remember { mutableStateOf<String?>(null) }
    var query by remember { mutableStateOf("") }

    val slug = openSlug
    if (slug != null) {
        val def = DrillEngine.drill(slug)
        if (def == null) {
            openSlug = null
        } else {
            DrillSetupAndRun(def, auth, onSignIn) { openSlug = null }
            return
        }
    }

    val q = query.trim().lowercase()
    val matching = DrillEngine.all.filter {
        q.isEmpty() || it.title.lowercase().contains(q) || it.blurb.lowercase().contains(q)
    }
    val byCategory = matching.groupBy { it.category }

    Column(Modifier.fillMaxSize().background(Theme.parchment)) {
        Text(
            "Practice Drills",
            style = display(22).copy(color = Theme.crimson),
            modifier = Modifier.padding(start = 16.dp, top = 16.dp),
        )
        OutlinedTextField(
            value = query,
            onValueChange = { query = it },
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

        LazyColumn(
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            DrillCategory.entries.forEach { category ->
                val drills = byCategory[category].orEmpty()
                if (drills.isNotEmpty()) {
                    item(key = "h-" + category.name) { SectionHeader(category.label) }
                    items(drills, key = { it.slug }) { def ->
                        LyceumCard(onClick = { openSlug = def.slug }) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(def.icon, fontSize = 26.sp)
                                Spacer(Modifier.width(12.dp))
                                Column(Modifier.weight(1f)) {
                                    Text(def.title, style = display(15).copy(color = Theme.ink))
                                    Spacer(Modifier.height(2.dp))
                                    Text(def.blurb, style = serif(14).copy(color = Theme.inkSoft))
                                }
                            }
                        }
                    }
                }
            }
            if (matching.isEmpty()) {
                item {
                    Text(
                        "No drills match “$query”.",
                        style = serif(16).copy(color = Theme.inkSoft, textAlign = TextAlign.Center),
                        modifier = Modifier.fillMaxWidth().padding(top = 32.dp),
                    )
                }
            }
        }
    }
}

private enum class Phase { SETUP, RUNNING, DONE }

/** Difficulty and length, then the run itself, then the score. */
@Composable
private fun DrillSetupAndRun(
    def: DrillDef,
    auth: AuthViewModel,
    onSignIn: () -> Unit,
    onBack: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    val user by auth.user.collectAsState()
    val signedIn = user != null

    var phase by remember(def.slug) { mutableStateOf(Phase.SETUP) }
    var level by remember(def.slug) { mutableIntStateOf(if (def.difficultyTiers) 1 else 3) }
    var length by remember(def.slug) { mutableIntStateOf(10) }
    var result by remember(def.slug) { mutableStateOf<DrillResult?>(null) }
    var startedAt by remember(def.slug) { mutableLongStateOf(0L) }

    when (phase) {
        Phase.SETUP -> Column(
            Modifier
                .fillMaxSize()
                .background(Theme.parchment)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(def.icon, fontSize = 30.sp)
                Spacer(Modifier.width(12.dp))
                Column {
                    Text(def.title, style = display(22).copy(color = Theme.crimson))
                    Text(def.blurb, style = serif(15).copy(color = Theme.inkSoft))
                }
            }

            if (def.difficultyTiers) {
                SectionHeader("Difficulty")
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    listOf(1 to "Easy", 2 to "Medium", 3 to "Hard").forEach { (value, label) ->
                        ChoiceChip(label, level == value, Modifier.weight(1f)) { level = value }
                    }
                }
            }

            SectionHeader("Length")
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                listOf(10, 20, 30).forEach { n ->
                    ChoiceChip("$n", length == n, Modifier.weight(1f)) { length = n }
                }
            }

            PrimaryButton("Start", Modifier.fillMaxWidth()) {
                DrillEngine.resetBag(def.slug, level)
                startedAt = System.currentTimeMillis()
                phase = Phase.RUNNING
            }
            SecondaryButton("Back to drills", Modifier.fillMaxWidth(), onClick = onBack)
        }

        Phase.RUNNING -> DrillRunner(def, level, length) { r ->
            result = r
            phase = Phase.DONE
            if (signedIn) {
                val seconds = ((System.currentTimeMillis() - startedAt) / 1000).toInt()
                scope.launch {
                    runCatching {
                        Repository.recordDrillSession(
                            DrillSessionBody(
                                slug = def.slug,
                                level = level,
                                total = r.total,
                                correct = r.correct,
                                bestStreak = r.bestStreak,
                                mode = "practice",
                                durationSec = seconds,
                                clientId = makeClientId(),
                            )
                        )
                    }
                    auth.refresh()
                }
            }
        }

        Phase.DONE -> {
            val r = result
            Column(
                Modifier
                    .fillMaxSize()
                    .background(Theme.parchment)
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                Text(def.title, style = display(22).copy(color = Theme.crimson))
                if (r != null) {
                    LyceumCard {
                        Column(
                            Modifier.fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(10.dp),
                        ) {
                            Text("${r.correct} / ${r.total}", style = display(34).copy(color = Theme.crimson))
                            Text("Best streak ${r.bestStreak}", style = serif(15).copy(color = Theme.inkSoft))
                            if (!signedIn) {
                                SignInPrompt(
                                    message = "This run isn't saved. An account keeps your scores and streak.",
                                    onSignIn = onSignIn,
                                )
                            }
                        }
                    }
                }
                PrimaryButton("Run it again", Modifier.fillMaxWidth()) {
                    DrillEngine.resetBag(def.slug, level)
                    startedAt = System.currentTimeMillis()
                    phase = Phase.RUNNING
                }
                SecondaryButton("Back to drills", Modifier.fillMaxWidth(), onClick = onBack)
            }
        }
    }
}

@Composable
private fun ChoiceChip(label: String, selected: Boolean, modifier: Modifier = Modifier, onClick: () -> Unit) {
    val shape = RoundedCornerShape(10.dp)
    Box(
        modifier
            .heightIn(min = 44.dp)
            .clip(shape)
            .background(if (selected) Theme.parchmentDeep else Theme.card)
            .border(1.5.dp, if (selected) Theme.gold300 else Theme.line, shape)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Text(label, style = display(15).copy(color = if (selected) Theme.gold300 else Theme.inkSoft))
    }
}
