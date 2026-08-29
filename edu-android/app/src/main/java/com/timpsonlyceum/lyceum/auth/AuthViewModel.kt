package com.timpsonlyceum.lyceum.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.timpsonlyceum.lyceum.model.AuthUser
import com.timpsonlyceum.lyceum.model.Streak
import com.timpsonlyceum.lyceum.net.Repository
import com.timpsonlyceum.lyceum.net.TokenStore
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Who, if anyone, is signed in.
 *
 * The app opens on the catalog whether or not this resolves to a user — the
 * signed-out path is the normal one, not an error state. Only the Review deck
 * and saved progress need an identity.
 */
class AuthViewModel : ViewModel() {

    private val _user = MutableStateFlow<AuthUser?>(null)
    val user: StateFlow<AuthUser?> = _user.asStateFlow()

    private val _loading = MutableStateFlow(true)
    val loading: StateFlow<Boolean> = _loading.asStateFlow()

    private val _streak = MutableStateFlow<Streak?>(null)
    val streak: StateFlow<Streak?> = _streak.asStateFlow()

    private val _dueCount = MutableStateFlow(0)
    val dueCount: StateFlow<Int> = _dueCount.asStateFlow()

    val isSignedIn: Boolean get() = _user.value != null

    init { bootstrap() }

    /**
     * Resolves the stored token to a user, or to nobody. An access token is a
     * stateless one-hour JWT and so outlives the account it names; /me answers
     * 401 when the row is gone, which lands here as "signed out" rather than a
     * ghost session.
     */
    fun bootstrap() {
        viewModelScope.launch {
            if (TokenStore.accessToken == null) {
                _user.value = null
                _loading.value = false
                return@launch
            }
            try {
                val me = Repository.me()
                _user.value = me.user
                _streak.value = me.streak
                _dueCount.value = me.dueCount
            } catch (e: Exception) {
                _user.value = null
            }
            _loading.value = false
        }
    }

    /** Re-reads /me — the streak and due count after finishing something. */
    fun refresh() {
        if (!isSignedIn) return
        viewModelScope.launch {
            try {
                val me = Repository.me()
                _user.value = me.user
                _streak.value = me.streak
                _dueCount.value = me.dueCount
            } catch (e: Exception) {
                // A failed refresh leaves the last good values on screen.
            }
        }
    }

    suspend fun login(email: String, password: String) {
        val res = Repository.login(email.trim(), password)
        TokenStore.save(res.accessToken, res.refreshToken)
        _user.value = res.user
        refresh()
    }

    suspend fun register(name: String, email: String, password: String) {
        val res = Repository.register(name.trim(), email.trim(), password)
        TokenStore.save(res.accessToken, res.refreshToken)
        _user.value = res.user
        refresh()
    }

    /**
     * Permanently deletes the account, server-side and on this device.
     *
     * The local purge matters as much as the server call: every on-device store
     * is keyed by user id, so without it the next account signed in on this
     * device would inherit the deleted student's progress.
     */
    suspend fun deleteAccount(password: String) {
        Repository.deleteAccount(password)
        purgeLocalData()
        TokenStore.clear()
        _user.value = null
        _streak.value = null
        _dueCount.value = 0
    }

    fun logout() {
        viewModelScope.launch {
            TokenStore.refreshToken?.let { rt ->
                try { Repository.logout(rt) } catch (e: Exception) { /* local sign-out regardless */ }
            }
            TokenStore.clear()
            _user.value = null
            _streak.value = null
            _dueCount.value = 0
        }
    }

    private fun purgeLocalData() {
        LocalStores.purgeAll()
    }
}

/**
 * On-device state that outlives a server row and has to go when an account is
 * deleted. Populated as the drill and lesson stores land; kept as one seam so
 * account deletion never has to remember a list.
 */
object LocalStores {
    fun purgeAll() {
        com.timpsonlyceum.lyceum.drills.DrillStore.purgeAll()
    }
}
