package com.timpsonlyceum.lyceum.net

import kotlinx.coroutines.Deferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.KSerializer
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.contentOrNull
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.concurrent.TimeUnit
import com.timpsonlyceum.lyceum.model.TokenPair

class ApiException(val status: Int, message: String) : Exception(message)

/**
 * Talks to edu-web's app/api/mobile/v1/… API. Injects the Bearer token and
 * transparently refreshes it — single-flight, as on iOS — when a call comes back
 * 401. A direct port of the Swift `APIClient` actor; the single-flight refresh is
 * the part worth keeping faithful, since several screens load at once on launch
 * and a naive implementation fires a refresh per call and races itself.
 */
object ApiClient {
    val json = Json {
        ignoreUnknownKeys = true
        explicitNulls = false
        coerceInputValues = true
    }

    private val http = OkHttpClient.Builder()
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    private val jsonMedia = "application/json".toMediaType()

    private val refreshLock = Mutex()
    private var refreshInFlight: Deferred<Boolean>? = null

    private val v1: String get() = AppConfig.baseUrl + "/api/mobile/v1"

    suspend fun <T> get(path: String, serializer: KSerializer<T>, auth: Boolean = true): T =
        request(path, "GET", null, serializer, auth)

    suspend fun <T> post(path: String, body: String?, serializer: KSerializer<T>, auth: Boolean = true): T =
        request(path, "POST", body, serializer, auth)

    suspend fun <T> put(path: String, body: String?, serializer: KSerializer<T>, auth: Boolean = true): T =
        request(path, "PUT", body, serializer, auth)

    suspend fun <T> delete(path: String, body: String? = null, serializer: KSerializer<T>, auth: Boolean = true): T =
        request(path, "DELETE", body, serializer, auth)

    private suspend fun <T> request(
        path: String,
        method: String,
        body: String?,
        serializer: KSerializer<T>,
        auth: Boolean,
        retry: Boolean = true,
    ): T = withContext(Dispatchers.IO) {
        val builder = Request.Builder().url(v1 + path)
        val rb = body?.toRequestBody(jsonMedia)
        when (method) {
            "GET" -> builder.get()
            "DELETE" -> if (rb != null) builder.delete(rb) else builder.delete()
            else -> builder.method(method, rb ?: "".toRequestBody(jsonMedia))
        }
        if (auth) TokenStore.accessToken?.let { builder.header("Authorization", "Bearer $it") }

        val response = http.newCall(builder.build()).execute()
        val text = response.body?.string().orEmpty()
        val code = response.code
        response.close()

        if (code == 401 && auth && retry && refreshAccess()) {
            return@withContext request(path, method, body, serializer, auth, retry = false)
        }
        if (code !in 200..299) throw ApiException(code, errorMessage(text, code))

        // Endpoints that answer 204, and the handful that return a bare body we
        // don't model, still have to decode to *something*.
        val payload = if (text.isBlank()) "{}" else text
        json.decodeFromString(serializer, payload)
    }

    private fun errorMessage(text: String, status: Int): String = try {
        (json.parseToJsonElement(text) as? JsonObject)
            ?.get("error")?.jsonPrimitive?.contentOrNull
            ?: "Request failed ($status)"
    } catch (e: Exception) {
        "Request failed ($status)"
    }

    /**
     * Refreshes the access token, at most once at a time. Concurrent callers all
     * await the same attempt rather than each starting their own.
     */
    private suspend fun refreshAccess(): Boolean {
        val existing = refreshLock.withLock { refreshInFlight }
        if (existing != null) return existing.await()

        val task = refreshLock.withLock {
            refreshInFlight ?: CoroutineScope(Dispatchers.IO).async { doRefresh() }.also {
                refreshInFlight = it
            }
        }
        val ok = task.await()
        refreshLock.withLock { refreshInFlight = null }
        return ok
    }

    private fun doRefresh(): Boolean {
        val rt = TokenStore.refreshToken ?: return false
        return try {
            val req = Request.Builder()
                .url("$v1/auth/refresh")
                .post(json.encodeToString(RefreshBody.serializer(), RefreshBody(rt)).toRequestBody(jsonMedia))
                .build()
            val resp = http.newCall(req).execute()
            val text = resp.body?.string().orEmpty()
            val code = resp.code
            resp.close()
            if (code !in 200..299) {
                TokenStore.clear()
                return false
            }
            val pair = json.decodeFromString(TokenPair.serializer(), text)
            TokenStore.save(pair.accessToken, pair.refreshToken)
            true
        } catch (e: Exception) {
            TokenStore.clear()
            false
        }
    }
}

@kotlinx.serialization.Serializable
private data class RefreshBody(val refreshToken: String)
