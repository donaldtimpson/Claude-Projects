package com.timpsonlyceum.lyceum.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavHostController
import com.timpsonlyceum.lyceum.auth.AuthViewModel
import com.timpsonlyceum.lyceum.model.*
import com.timpsonlyceum.lyceum.net.AppConfig
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
 * Signed out this *is* the sign-in form, which is why the tab is always
 * reachable: it is the account, not a locked room.
 */
@Composable
fun ProgressScreen(auth: AuthViewModel, nav: NavHostController) {
    val user by auth.user.collectAsState()
    if (user == null) {
        SignInScreen(auth, onDone = { auth.refresh() })
        return
    }

    val scope = rememberCoroutineScope()
    val uriHandler = LocalUriHandler.current

    var me by remember { mutableStateOf<MeResponse?>(null) }
    var badges by remember { mutableStateOf<List<Badge>>(emptyList()) }
    var progress by remember { mutableStateOf<ProgressResponse?>(null) }
    var confirmDelete by remember { mutableStateOf(false) }
    var editHandle by remember { mutableStateOf(false) }
    var showAchievements by remember { mutableStateOf(false) }
    var expandedClass by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(user?.id) {
        me = runCatching { Repository.me() }.getOrNull()
        badges = runCatching { Repository.badges().badges }.getOrDefault(emptyList())
        progress = runCatching { Repository.progress() }.getOrNull()
    }

    if (showAchievements) {
        AchievementsScreen(badges) { showAchievements = false }
        return
    }

    val earned = badges.filter { it.unlocked }
    // The name this student actually appears under publicly: their chosen handle,
    // or the server's assigned placeholder until they pick one.
    val publicHandle = user?.handle ?: me?.handlePlaceholder ?: "Scholar"

    LazyColumn(
        Modifier.fillMaxSize().background(Theme.parchment),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        item {
            Column {
                Text(
                    user?.name ?: "Scholar",
                    style = display(26).copy(color = Theme.crimson, fontWeight = FontWeight.Bold),
                )
                Spacer(Modifier.height(2.dp))
                // The handle is the only name shown in the Hall of Scholars, so it is
                // editable here as it is on the web. A student who never picked one
                // still HAS a public name — show the assigned one, and say so.
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.clickable { editHandle = true },
                ) {
                    Text("@$publicHandle", style = serif(15).copy(color = Theme.inkSoft))
                    Spacer(Modifier.width(6.dp))
                    Icon(Icons.Filled.Edit, contentDescription = "Edit handle", tint = Theme.gold400, modifier = Modifier.size(14.dp))
                }
                if (user?.handle == null && me?.handlePlaceholder != null) {
                    Text(
                        "auto-assigned — tap to choose your own",
                        style = serif(12).copy(color = Theme.gold400),
                    )
                }
            }
        }

        item {
            LyceumCard {
                Row(Modifier.fillMaxWidth()) {
                    Stat("${me?.streak?.count ?: 0}", "day streak")
                    Stat("${earned.size}", "badges")
                    Stat("${me?.dueCount ?: 0}", "cards due")
                }
            }
        }

        item {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text("Badges", style = display(17).copy(color = Theme.ink), modifier = Modifier.weight(1f))
                if (badges.isNotEmpty()) {
                    TextButton(onClick = { showAchievements = true }) {
                        Text("View all", style = serif(15).copy(color = Theme.gold400))
                    }
                }
            }
        }
        item {
            if (earned.isEmpty()) {
                Text(
                    "No badges yet — take a quiz or run a drill to start earning.",
                    style = serif(15).copy(color = Theme.inkSoft),
                )
            } else {
                Row(
                    Modifier.horizontalScroll(rememberScrollState()).padding(vertical = 10.dp),
                    horizontalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    earned.take(10).forEach { badge ->
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            BadgeMedallion(badge, size = 60.dp)
                            Spacer(Modifier.height(5.dp))
                            Text(
                                badge.name,
                                style = serif(12).copy(color = Theme.inkSoft, textAlign = TextAlign.Center),
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.width(72.dp),
                            )
                        }
                    }
                }
            }
        }

        // The handle above only means something because of this board, so give it
        // a way through from the screen that sets it.
        item {
            LyceumCard(onClick = { nav.navigate(Routes.SCHOLARS) }) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("🏛️", fontSize = 22.sp)
                    Spacer(Modifier.width(10.dp))
                    Column(Modifier.weight(1f)) {
                        Text("Hall of Scholars", style = display(15).copy(color = Theme.ink))
                        Text("See where you stand", style = serif(13).copy(color = Theme.inkSoft))
                    }
                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = Theme.gold400)
                }
            }
        }

        val classes = progress?.classes.orEmpty()
        if (classes.isNotEmpty()) {
            item { SectionHeader("My Classes") }
            items(classes, key = { it.sectionId }) { c ->
                ClassGradeCard(c, expandedClass == c.sectionId) {
                    expandedClass = if (expandedClass == c.sectionId) null else c.sectionId
                }
            }
        }

        val inProgress = progress?.inProgress.orEmpty()
        if (inProgress.isNotEmpty()) {
            item { SectionHeader("In Progress") }
            items(inProgress, key = { "ip-" + it.id }) {
                CourseProgressCard(it) { nav.navigate(Routes.course(it.id)) }
            }
        }

        val completed = progress?.completed.orEmpty()
        if (completed.isNotEmpty()) {
            item { SectionHeader("Completed") }
            items(completed, key = { "cp-" + it.id }) {
                CourseProgressCard(it) { nav.navigate(Routes.course(it.id)) }
            }
        }

        item { SectionHeader("Account") }
        item {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                // Reachable from inside the app, not just the store listing —
                // reviewers look for these, and students shouldn't have to hunt.
                Row(
                    Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center,
                ) {
                    TextButton(onClick = { uriHandler.openUri(AppConfig.assetUrl("/privacy")) }) {
                        Text("Privacy Policy", style = serif(15).copy(color = Theme.gold400))
                    }
                    Spacer(Modifier.width(18.dp))
                    TextButton(onClick = { uriHandler.openUri(AppConfig.assetUrl("/support")) }) {
                        Text("Support", style = serif(15).copy(color = Theme.gold400))
                    }
                }
                SecondaryButton("Sign out", Modifier.fillMaxWidth()) { auth.logout() }
                // Kept quiet and last, so nobody taps it on the way to signing out.
                TextButton(onClick = { confirmDelete = true }, modifier = Modifier.fillMaxWidth()) {
                    Text("Delete Account", style = serif(15).copy(color = Theme.danger))
                }
            }
        }
    }

    if (editHandle) {
        HandleEditorDialog(
            current = user?.handle,
            assigned = me?.handlePlaceholder,
            onDismiss = { editHandle = false },
            onSave = { handle ->
                scope.launch {
                    runCatching { Repository.setHandle(handle) }.onSuccess { auth.refresh() }
                    editHandle = false
                }
            },
        )
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
private fun RowScope.Stat(value: String, label: String) {
    Column(
        Modifier.weight(1f),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(value, fontSize = 28.sp, fontWeight = FontWeight.Bold, color = Theme.crimson)
        Spacer(Modifier.height(2.dp))
        Text(label, style = serif(13).copy(color = Theme.inkSoft))
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
 * One enrolled class: the headline grade, and the six weighted categories the web
 * class hub shows, folded away until asked for.
 *
 * A category with no data reads "pending", never zero — a zero the student has
 * not earned is alarming in a way a blank is not.
 */
@Composable
private fun ClassGradeCard(grade: ClassGrade, expanded: Boolean, onToggle: () -> Unit) {
    LyceumCard(onClick = onToggle) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(grade.sectionName, style = display(16).copy(color = Theme.gold300))
                Text(
                    grade.courseTitle,
                    style = serif(14).copy(color = Theme.inkSoft),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Text(
                grade.currentGrade?.let { "${it.toInt()}%" } ?: "pending",
                style = display(20).copy(color = Theme.gold400),
            )
            Icon(
                if (expanded) Icons.Filled.ExpandLess else Icons.Filled.ExpandMore,
                contentDescription = null,
                tint = Theme.inkSoft,
            )
        }
        if (expanded) {
            Spacer(Modifier.height(10.dp))
            grade.breakdown.forEach { row ->
                Row(
                    Modifier.fillMaxWidth().padding(vertical = 3.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        "${row.label} (${row.weight}%)",
                        style = serif(14).copy(color = Theme.inkSoft),
                        modifier = Modifier.weight(1f),
                    )
                    Text(
                        row.pct?.let { "${it.toInt()}%" } ?: "pending",
                        style = display(14).copy(color = if (row.pct != null) Theme.ink else Theme.inkSoft),
                    )
                }
                Text(row.detail, style = serif(12).copy(color = Theme.inkSoft))
            }
        }
    }
}

@Composable
private fun HandleEditorDialog(
    current: String?,
    assigned: String?,
    onDismiss: () -> Unit,
    onSave: (String) -> Unit,
) {
    var handle by remember { mutableStateOf(current ?: assigned ?: "") }
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = Theme.card,
        title = { Text("Your public name", style = display(18).copy(color = Theme.crimson)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    "This is the only name shown in the Hall of Scholars.",
                    style = serif(15).copy(color = Theme.ink),
                )
                LyceumField(handle, "Handle", onChange = { handle = it })
            }
        },
        confirmButton = {
            TextButton(onClick = { onSave(handle.trim()) }, enabled = handle.isNotBlank()) {
                Text("Save", style = serif(15).copy(color = Theme.gold400))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel", style = serif(15).copy(color = Theme.inkSoft)) }
        },
    )
}

/**
 * Deleting an account is permanent, so it wants the typed word DELETE and the
 * password — the password so a stolen session alone cannot wipe an account.
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
