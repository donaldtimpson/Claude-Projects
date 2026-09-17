package com.timpsonlyceum.lyceum.offline

import android.content.Context
import android.content.SharedPreferences
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkRequest
import com.timpsonlyceum.lyceum.model.EmptyResponse
import com.timpsonlyceum.lyceum.net.ApiClient
import com.timpsonlyceum.lyceum.net.ApiException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer

/**
 * Offline write queue — the Android side of the parity gap where a drill finished
 * without a connection was silently lost. Engagement writes (quiz attempts, review
 * grades, drill sessions, watch progress) go through [WriteQueue]: it tries the
 * network first and, on a transient failure, persists the request to replay on
 * reconnect. Each row carries a `clientId` so the server dedups replays
 * (`lib/mobile/idempotency.ts` + the `IdempotencyKey` table).
 *
 * A direct port of iOS `Sources/Offline/WriteQueue.swift` (`WriteQueueManager`).
 * iOS backs the queue with SwiftData; the volumes here are a handful of pending
 * rows, and every other on-device store in this app (DrillStore, TokenStore) is a
 * SharedPreferences file, so the honest fit is the same: one JSON blob under a
 * dedicated preferences file, cached in memory. No new dependency, no Room/KSP.
 *
 * Semantics mirror the Swift original exactly:
 *  - [submit] posts now; on a permanent 4xx (except 429) it drops the write, on any
 *    other failure it enqueues for replay.
 *  - [flush] replays in creation order; a row is removed on success or on a
 *    permanent 4xx, and kept on a transient failure for the next flush.
 *  - dedup is by `clientId` (unique), so the same logical event is never queued
 *    twice even if the enqueue path runs again.
 *  - [purgeAll] drops everything, wired into account deletion for the same reason
 *    iOS does it: unsent progress belongs to the account being deleted and must not
 *    be replayed under the next sign-in on this device.
 */
object WriteQueue {
    private const val FILE = "lyceum_write_queue"
    private const val KEY = "pending"

    private val json = ApiClient.json
    private val mutex = Mutex()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private lateinit var prefs: SharedPreferences
    private var connectivity: ConnectivityManager? = null

    /** In-memory mirror of the persisted queue; the file is the source of truth on disk. */
    private var items: MutableList<QueuedWrite> = mutableListOf()

    @Serializable
    data class QueuedWrite(
        val clientId: String,
        val path: String,
        val bodyJson: String,
        val createdAt: Long,
    )

    /**
     * Wire up persistence and a reconnect trigger. Registering a
     * [ConnectivityManager] callback flushes the queue the moment a network comes
     * back, matching the iOS `flush()` on reconnect; app-start flush is a separate
     * call (see [flush]).
     */
    fun init(context: Context) {
        prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
        items = load().toMutableList()

        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
        connectivity = cm
        cm?.registerNetworkCallback(
            NetworkRequest.Builder().build(),
            object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    scope.launch { flush() }
                }
            },
        )
    }

    private fun load(): List<QueuedWrite> =
        prefs.getString(KEY, null)?.let {
            runCatching { json.decodeFromString(ListSerializer(QueuedWrite.serializer()), it) }.getOrNull()
        } ?: emptyList()

    private fun persist() {
        prefs.edit()
            .putString(KEY, json.encodeToString(ListSerializer(QueuedWrite.serializer()), items))
            .apply()
    }

    /**
     * Try a write now; queue it on a transient failure. Returns true when the write
     * reached the server (or was a permanent client error not worth retrying) and
     * false only in the impossible-to-classify case — callers that need the server
     * result (badges) should read it before this, but every current call site only
     * needs the write to be durable.
     *
     * The always-try-then-queue shape is deliberately uniform, exactly as iOS
     * `submit`: online it's a plain POST, offline it lands in the queue.
     */
    suspend fun submit(path: String, bodyJson: String, clientId: String) {
        try {
            ApiClient.post(path, bodyJson, EmptyResponse.serializer())
        } catch (e: ApiException) {
            if (isPermanent(e)) return // permanent client error — nothing to retry
            enqueue(path, bodyJson, clientId)
        } catch (e: Exception) {
            enqueue(path, bodyJson, clientId) // offline / transient — replay later
        }
    }

    private suspend fun enqueue(path: String, bodyJson: String, clientId: String) = mutex.withLock {
        // Client-side dedup: the same logical event is never queued twice.
        if (items.any { it.clientId == clientId }) return@withLock
        items.add(QueuedWrite(clientId, path, bodyJson, System.currentTimeMillis()))
        persist()
    }

    /**
     * Replay every queued write in creation order. A row is removed on success or on
     * a permanent 4xx (except 429) and kept on a transient failure for the next
     * flush. Called on app start and whenever the network comes back.
     */
    suspend fun flush() = mutex.withLock {
        if (items.isEmpty()) return@withLock
        // Snapshot and sort oldest-first, matching iOS's createdAt ordering.
        val ordered = items.sortedBy { it.createdAt }
        val survivors = mutableListOf<QueuedWrite>()
        for (item in ordered) {
            val keep = try {
                ApiClient.post(item.path, item.bodyJson, EmptyResponse.serializer())
                false // sent — drop
            } catch (e: ApiException) {
                if (isPermanent(e)) false else true // permanent 4xx → drop; else keep
            } catch (e: Exception) {
                true // transient — keep for the next flush
            }
            if (keep) survivors.add(item)
        }
        items = survivors
        persist()
    }

    /**
     * Drop every queued write. Used when an account is deleted: unsent progress
     * belongs to an account that no longer exists, and replaying it under the next
     * sign-in on this device would attribute it to the wrong student.
     */
    fun purgeAll() {
        // No suspend context on the deletion path; the queue is tiny and this is rare.
        items = mutableListOf()
        if (::prefs.isInitialized) prefs.edit().remove(KEY).apply()
    }

    val pending: Int get() = items.size

    /** A 4xx other than 429 is a permanent client error — a replay can't fix it. */
    private fun isPermanent(e: ApiException): Boolean =
        e.status in 400..499 && e.status != 429
}
