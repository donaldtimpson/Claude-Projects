package com.timpsonlyceum.lyceum.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.timpsonlyceum.lyceum.model.Badge
import com.timpsonlyceum.lyceum.ui.components.*
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display
import com.timpsonlyceum.lyceum.ui.theme.serif

/**
 * The full badge catalogue: medallions grouped by category, with the Omniscient
 * capstone pulled out on top.
 *
 * Locked badges are shown by default rather than hidden — seeing what is still
 * out there is most of the point of a catalogue — with a toggle to narrow to
 * what has been earned.
 */
@Composable
fun AchievementsScreen(badges: List<Badge>, onBack: () -> Unit) {
    var showAll by remember { mutableStateOf(true) }
    var detail by remember { mutableStateOf<Badge?>(null) }

    val rest = badges.filter { it.tier != "omniscient" }
    val omniscient = badges.firstOrNull { it.tier == "omniscient" }
    val earnedCount = rest.count { it.unlocked }

    fun rank(b: Badge) = BadgeMeta.tierRank[b.tier] ?: 0

    Column(Modifier.fillMaxSize().background(Theme.parchment)) {
        Row(
            Modifier.fillMaxWidth().padding(start = 16.dp, end = 8.dp, top = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("Achievements", style = display(22).copy(color = Theme.crimson), modifier = Modifier.weight(1f))
            TextButton(onClick = onBack) { Text("Back", style = serif(15).copy(color = Theme.gold400)) }
        }

        Row(
            Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                "$earnedCount / ${rest.size} earned",
                style = serif(16).copy(color = Theme.ink),
                modifier = Modifier.weight(1f),
            )
            Box(Modifier.width(170.dp)) {
                SegmentedRow(
                    options = listOf("All" to true, "Earned" to false),
                    selected = showAll,
                ) { showAll = it }
            }
        }

        LazyColumn(
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            omniscient?.let { cap ->
                item {
                    LyceumCard(onClick = { detail = cap }) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            BadgeMedallion(cap, size = 64.dp)
                            Spacer(Modifier.width(14.dp))
                            Column(Modifier.weight(1f)) {
                                Text(cap.name, style = display(17).copy(color = Theme.gold300))
                                Spacer(Modifier.height(2.dp))
                                Text(cap.blurb, style = serif(14).copy(color = Theme.inkSoft))
                            }
                        }
                    }
                }
            }

            BadgeMeta.categoryOrder.forEach { category ->
                val list = rest.filter { it.category == category }.sortedBy { rank(it) }
                val visible = if (showAll) list else list.filter { it.unlocked }
                if (visible.isNotEmpty()) {
                    item(key = "h-$category") {
                        Column {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    BadgeMeta.categoryIcon(category),
                                    contentDescription = null,
                                    tint = Theme.gold400,
                                    modifier = Modifier.size(18.dp),
                                )
                                Spacer(Modifier.width(8.dp))
                                Text(
                                    BadgeMeta.categoryLabel(category),
                                    style = display(16).copy(color = Theme.ink),
                                    modifier = Modifier.weight(1f),
                                )
                                Text(
                                    "${list.count { it.unlocked }}/${list.size}",
                                    style = serif(14).copy(color = Theme.inkSoft),
                                )
                            }
                            Spacer(Modifier.height(2.dp))
                            Text(
                                BadgeMeta.categoryBlurb(category),
                                style = serif(13).copy(color = Theme.inkSoft),
                            )
                        }
                    }
                    // Three to a row: a medallion plus its name needs about a third
                    // of a phone's width before the name starts truncating.
                    items(visible.chunked(3), key = { it.first().key }) { row ->
                        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            row.forEach { badge ->
                                Column(
                                    Modifier.weight(1f).clickable { detail = badge },
                                    horizontalAlignment = Alignment.CenterHorizontally,
                                ) {
                                    BadgeMedallion(badge, size = 64.dp)
                                    Spacer(Modifier.height(6.dp))
                                    Text(
                                        badge.name,
                                        style = serif(13).copy(
                                            color = if (badge.unlocked) Theme.ink else Theme.inkSoft,
                                            textAlign = TextAlign.Center,
                                        ),
                                        maxLines = 2,
                                        overflow = TextOverflow.Ellipsis,
                                    )
                                }
                            }
                            repeat(3 - row.size) { Spacer(Modifier.weight(1f)) }
                        }
                    }
                }
            }
        }
    }

    detail?.let { badge ->
        AlertDialog(
            onDismissRequest = { detail = null },
            containerColor = Theme.card,
            icon = { BadgeMedallion(badge, size = 72.dp) },
            title = {
                Text(
                    badge.name,
                    style = display(18).copy(color = Theme.ink, textAlign = TextAlign.Center),
                    modifier = Modifier.fillMaxWidth(),
                )
            },
            text = {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                    Text(
                        badge.blurb,
                        style = serif(15).copy(color = Theme.ink, textAlign = TextAlign.Center),
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        "${BadgeMeta.tierLabel(badge.tier)} · ${BadgeMeta.categoryLabel(badge.category)}" +
                            if (badge.unlocked) "" else " · locked",
                        style = serif(13).copy(color = Theme.gold400),
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = { detail = null }) {
                    Text("Close", style = serif(15).copy(color = Theme.gold400))
                }
            },
        )
    }
}

