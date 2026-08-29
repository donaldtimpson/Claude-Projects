package com.timpsonlyceum.lyceum.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Layers
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.timpsonlyceum.lyceum.auth.AuthViewModel
import com.timpsonlyceum.lyceum.ui.components.*
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display
import com.timpsonlyceum.lyceum.ui.theme.serif
import kotlinx.coroutines.launch

/** The wordmark, shown while the stored token is being resolved. */
@Composable
fun SplashScreen() {
    Box(
        Modifier.fillMaxSize().background(Theme.parchment),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                "The Timpson\nLyceum",
                style = display(34).copy(color = Theme.gold300, textAlign = TextAlign.Center),
            )
            Spacer(Modifier.height(16.dp))
            CircularProgressIndicator(color = Theme.gold300)
        }
    }
}

/**
 * The one place the app asks for an account, used wherever a feature genuinely
 * needs an identity.
 *
 * The app itself is not gated — courses, lectures, notes, quizzes and drills all
 * work signed out — so this only ever stands in front of what is personal by
 * nature. It always says what signing in buys; "sign-in required" on its own is
 * the pattern that got the iOS build rejected.
 */
@Composable
fun SignInGate(
    icon: ImageVector,
    title: String,
    message: String,
    onSignIn: () -> Unit,
) {
    Column(
        Modifier.fillMaxSize().background(Theme.parchment).padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(icon, contentDescription = null, tint = Theme.gold400, modifier = Modifier.size(44.dp))
        Spacer(Modifier.height(14.dp))
        Text(title, style = display(20).copy(color = Theme.crimson, textAlign = TextAlign.Center))
        Spacer(Modifier.height(14.dp))
        Text(message, style = serif(15).copy(color = Theme.inkSoft, textAlign = TextAlign.Center))
        Spacer(Modifier.height(16.dp))
        PrimaryButton("Sign in or create an account", onClick = onSignIn)
        Spacer(Modifier.height(14.dp))
        Text(
            "Everything else in the app works without one.",
            style = serif(13).copy(color = Theme.inkSoft, textAlign = TextAlign.Center),
        )
    }
}

/** Sign in, or create an account. One screen, one toggle — as on the web. */
@Composable
fun SignInScreen(auth: AuthViewModel, onDone: () -> Unit) {
    val scope = rememberCoroutineScope()
    var registering by remember { mutableStateOf(false) }
    var name by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var busy by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    Column(
        Modifier
            .fillMaxSize()
            .background(Theme.parchment)
            .verticalScroll(rememberScrollState())
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Text(
            if (registering) "Create an account" else "Sign in",
            style = display(24).copy(color = Theme.crimson),
        )
        Text(
            if (registering)
                "An account keeps your progress, your streak, and the review deck built from what you've missed."
            else
                "Welcome back.",
            style = serif(15).copy(color = Theme.inkSoft),
        )

        if (registering) {
            LyceumField(name, "Name", onChange = { name = it })
        }
        LyceumField(
            email, "Email",
            keyboardType = KeyboardType.Email,
            onChange = { email = it },
        )
        LyceumField(
            password, "Password",
            keyboardType = KeyboardType.Password,
            isPassword = true,
            imeAction = ImeAction.Done,
            onChange = { password = it },
        )

        error?.let { Text(it, style = serif(14).copy(color = Theme.danger)) }

        PrimaryButton(
            if (registering) "Create account" else "Sign in",
            modifier = Modifier.fillMaxWidth(),
            enabled = !busy && email.isNotBlank() && password.isNotBlank() &&
                (!registering || name.isNotBlank()),
        ) {
            busy = true
            error = null
            scope.launch {
                runCatching {
                    if (registering) auth.register(name, email, password)
                    else auth.login(email, password)
                }.onSuccess {
                    busy = false
                    onDone()
                }.onFailure {
                    busy = false
                    error = it.message ?: "That didn't work. Try again."
                }
            }
        }

        if (busy) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
                CircularProgressIndicator(color = Theme.gold300, modifier = Modifier.size(22.dp), strokeWidth = 2.dp)
            }
        }

        TextButton(onClick = { registering = !registering; error = null }) {
            Text(
                if (registering) "I already have an account" else "Create an account instead",
                style = serif(15).copy(color = Theme.gold400),
            )
        }
    }
}

@Composable
fun LyceumField(
    value: String,
    label: String,
    keyboardType: KeyboardType = KeyboardType.Text,
    isPassword: Boolean = false,
    imeAction: ImeAction = ImeAction.Next,
    onChange: (String) -> Unit,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        label = { Text(label, style = serif(14).copy(color = Theme.inkSoft)) },
        singleLine = true,
        visualTransformation = if (isPassword) PasswordVisualTransformation() else androidx.compose.ui.text.input.VisualTransformation.None,
        keyboardOptions = KeyboardOptions(keyboardType = keyboardType, imeAction = imeAction),
        textStyle = serif(16).copy(color = Theme.ink),
        modifier = Modifier.fillMaxWidth(),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = Theme.gold400,
            unfocusedBorderColor = Theme.line,
            cursorColor = Theme.gold300,
            focusedContainerColor = Theme.card,
            unfocusedContainerColor = Theme.card,
        ),
    )
}
