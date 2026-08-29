package com.timpsonlyceum.lyceum.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Hub
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
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
 * My Progress — the mobile half of the web dashboard, and the account screen.
 *
 * Signed out this *is* the sign-in screen, which is why the tab is always
 * reachable: it is the account, not a locked room.
 */
@Composable
fun ProgressScreen(auth: AuthViewModel, nav: NavHostController) {
    val user by auth.user.collectAsState()
    val streak by auth.streak.collectAsState()
    val dueCount by auth.dueCount.collectAsState()

    if (user == null) {
        SignInScreen(auth, onDone = { auth.refresh() })
        return
    }

    val scope = rememberCoroutineScope()
    var progress by remember { mutableStateOf<ProgressResponse?>(null) }
    var badges by remember { mutableStateOf<List<Badge>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }
    var confirmDelete by remember { mutableStateOf(false) }

    LaunchedEffect(user?.id) {
        loading = true
        progress = runCatching { Repository.progress() }.getOrNull()
        badges = runCatching { Repository.badges().badges }.getOrDefault(emptyList())
        loading = false
    }

    LazyColumn(
        Modifier.fillMaxSize().background(Theme.parchment),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            Column {
                Text("My Progress", style = display(22).copy(color = Theme.crimson))
                Spacer(Modifier.height(4.dp))
                Text(user?.name ?: user?.email.orEmpty(), style = serif(15).copy(color = Theme.inkSoft))
            }
        }

        item {
            LyceumCard {
                StatRow("Streak", "${streak?.count ?: 0} day" + if ((streak?.count ?: 0) == 1) "" else "s")
                StatRow("Due for review today", "$dueCount", valueColor = Theme.gold400)
                StatRow("Badges earned", "${badges.count { it.unlocked }} of ${badges.size}")
            }
        }

        item {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                SecondaryButton("Course Map", Modifier.weight(1f)) { nav.navigate(Routes.MAP) }
                SecondaryButton("Hall of Scholars", Modifier.weight(1f)) { nav.navigate(Routes.SCHOLARS) }
            }
        }

        if (loading) {
            item { Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
                CircularProgressIndicator(color = Theme.gold300, modifier = Modifier.size(22.dp), strokeWidth = 2.dp)
            } }
        }

        val classes = progress?.classes.orEmpty()
        if (classes.isNotEmpty()) {
            item { SectionHeader("My Classes") }
            items(classes, key = { it.sectionId }) { ClassGradeCard(it) }
        }

        val inProgress = progress?.inProgress.orEmpty()
        if (inProgress.isNotEmpty()) {
            item { SectionHeader("In Progress") }
            items(inProgress, key = { "ip-" + it.id }) { CourseProgressCard(it) { nav.navigate(Routes.course(it.id)) } }
        }

        val completed = progress?.completed.orEmpty()
        if (completed.isNotEmpty()) {
            item { SectionHeader("Completed") }
            items(completed, key = { "cp-" + it.id }) { CourseProgressCard(it) { nav.navigate(Routes.course(it.id)) } }
        }

        val earned = badges.filter { it.unlocked }
        if (earned.isNotEmpty()) {
            item { SectionHeader("Badges") }
            items(earned, key = { it.key }) { badge ->
                LyceumCard {
                    Text(badge.name, style = display(15).copy(color = Theme.gold300))
                    Spacer(Modifier.height(4.dp))
                    Text(badge.blurb, style = serif(14).copy(color = Theme.inkSoft))
                }
            }
        }

        item { SectionHeader("Account") }
        item {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                SecondaryButton("Sign out", Modifier.fillMaxWidth()) { auth.logout() }
                TextButton(onClick = { confirmDelete = true }, modifier = Modifier.fillMaxWidth()) {
                    Text("Delete account", style = serif(15).copy(color = Theme.danger))
                }
            }
        }
    }

    if (confirmDelete) {
        DeleteAccountDialog(
            onDismiss = { confirmDelete = false },
            onConfirm = { password ->
                scope.launch {
                    runCatching { auth.deleteAccount(password) }
                    confirmDelete = false
                }
            },
        )
    }
}

@Composable
private fun CourseProgressCard(item: CourseProgressItem, onClick: () -> Unit) {
    LyceumCard(onClick = onClick) {
        Text(item.title, style = display(15).copy(color = Theme.ink))
        Spacer(Modifier.height(8.dp))
        QuizProgressBar(item.fraction.toFloat())
        Spacer(Modifier.height(6.dp))
        Text(
            "${item.watchedCount} of ${item.totalCount} lectures",
            style = serif(14).copy(color = Theme.inkSoft),
        )
    }
}

/**
 * A live class's grade. Percentages are shown as "pending", not zero, until a
 * category has data — matching the web exactly, because a zero a student hasn't
 * earned is alarming in a way a blank is not.
 */
@Composable
private fun ClassGradeCard(grade: ClassGrade) {
    LyceumCard {
        Text(grade.sectionName, style = display(16).copy(color = Theme.gold300))
        Text(grade.courseTitle, style = serif(14).copy(color = Theme.inkSoft))
        Spacer(Modifier.height(10.dp))
        StatRow(
            "Current grade",
            grade.currentGrade?.let { "${it.toInt()}%" } ?: "pending",
            valueColor = Theme.gold400,
        )
        Spacer(Modifier.height(6.dp))
        grade.breakdown.forEach { row ->
            StatRow(
                "${row.label} (${row.weight}%)",
                (row.pct?.let { "${it.toInt()}%" } ?: "pending") + " · ${row.detail}",
            )
        }
    }
}

/**
 * Deleting an account is permanent, so it asks for the typed word DELETE and the
 * password — the same two confirmations the iOS app requires, and the password
 * so a stolen session alone cannot wipe an account.
 */
@Composable
private fun DeleteAccountDialog(onDismiss: () -> Unit, onConfirm: (String) -> Unit) {
    var typed by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = Theme.card,
        title = { Text("Delete account", style = display(18).copy(color = Theme.danger)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    "This permanently removes your account and all of its coursework, " +
                        "on the server and on this device. It cannot be undone.",
                    style = serif(15).copy(color = Theme.ink),
                )
                LyceumField(typed, "Type DELETE to confirm", onChange = { typed = it })
                LyceumField(
                    password, "Password",
                    keyboardType = androidx.compose.ui.text.input.KeyboardType.Password,
                    isPassword = true,
                    onChange = { password = it },
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onConfirm(password) },
                enabled = typed.trim() == "DELETE" && password.isNotBlank(),
            ) { Text("Delete", style = serif(15).copy(color = Theme.danger)) }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel", style = serif(15).copy(color = Theme.inkSoft)) }
        },
    )
}
