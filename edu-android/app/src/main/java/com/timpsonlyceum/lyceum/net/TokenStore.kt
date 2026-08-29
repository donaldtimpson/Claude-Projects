package com.timpsonlyceum.lyceum.net

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

/**
 * Access + refresh tokens, held the way the iOS app holds them in the Keychain:
 * encrypted at rest and never in plain preferences.
 *
 * Falls back to ordinary SharedPreferences only if the keystore-backed store
 * cannot be opened (a wiped or corrupted master key, which does happen on some
 * OEM builds). Losing the tokens signs the user out; refusing to start does not
 * seem like the better trade.
 */
object TokenStore {
    private const val FILE = "lyceum_tokens"
    private const val ACCESS = "accessToken"
    private const val REFRESH = "refreshToken"

    private lateinit var prefs: SharedPreferences

    fun init(context: Context) {
        prefs = try {
            val key = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            EncryptedSharedPreferences.create(
                context,
                FILE,
                key,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
            )
        } catch (e: Exception) {
            context.getSharedPreferences(FILE + "_plain", Context.MODE_PRIVATE)
        }
    }

    val accessToken: String? get() = prefs.getString(ACCESS, null)
    val refreshToken: String? get() = prefs.getString(REFRESH, null)

    fun save(access: String, refresh: String) {
        prefs.edit().putString(ACCESS, access).putString(REFRESH, refresh).apply()
    }

    fun clear() {
        prefs.edit().remove(ACCESS).remove(REFRESH).apply()
    }
}
