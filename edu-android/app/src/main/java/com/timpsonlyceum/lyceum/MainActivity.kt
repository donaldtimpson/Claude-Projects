package com.timpsonlyceum.lyceum

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.timpsonlyceum.lyceum.net.TokenStore
import com.timpsonlyceum.lyceum.ui.theme.LyceumTheme
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        TokenStore.init(applicationContext)
        enableEdgeToEdge()
        setContent {
            LyceumTheme { RootScaffold() }
        }
    }
}

@Composable
private fun RootScaffold() {
    Box(
        modifier = Modifier.fillMaxSize().background(Theme.parchment),
        contentAlignment = Alignment.Center,
    ) {
        Text("The Timpson\nLyceum", style = display(34).copy(color = Theme.gold300))
    }
}
