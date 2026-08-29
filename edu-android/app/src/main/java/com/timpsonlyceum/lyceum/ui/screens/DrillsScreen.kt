package com.timpsonlyceum.lyceum.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.timpsonlyceum.lyceum.ui.components.LyceumCard
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display
import com.timpsonlyceum.lyceum.ui.theme.serif

/**
 * Practice drills.
 *
 * Placeholder while the generator engine is ported: the iOS drills are 800-odd
 * lines of pure Swift (procedural arithmetic, unit circle, vectors, plus the
 * bundled grammar and geography banks) and they deserve a faithful port rather
 * than a thin imitation. Nothing else in the app depends on this screen.
 */
@Composable
fun DrillsScreen() {
    Column(
        Modifier.fillMaxSize().background(Theme.parchment).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("Practice Drills", style = display(22).copy(color = Theme.crimson))
        LyceumCard {
            Text("Not ported yet", style = display(16).copy(color = Theme.gold300))
            Spacer(Modifier.height(6.dp))
            Text(
                "The 62 drills run entirely on-device, so they are a straight port of the " +
                    "generators rather than anything the server can supply. Next up.",
                style = serif(15).copy(color = Theme.inkSoft),
            )
        }
    }
}
