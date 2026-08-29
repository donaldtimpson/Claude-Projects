package com.timpsonlyceum.lyceum.drills

import android.content.Context
import android.content.SharedPreferences

/**
 * On-device drill state: Leitner boxes for Learn mode, aced lesson marks, Rapid
 * Fire high scores, and the recently-opened list.
 *
 * iOS keeps these in SwiftData and UserDefaults; the volumes here are small
 * (hundreds of integers) and every read happens during layout, so plain
 * preferences with an in-memory cache is the honest fit rather than a database.
 *
 * Everything is keyed by user id, which is not decoration: without it the next
 * account signed in on this device would inherit the previous student's mastery
 * and ✦ marks. [purgeAll] is wired into account deletion for the same reason.
 */
object DrillStore {
    private const val FILE = "lyceum_drills"
    private const val MASTERED_BOX = 5

    private lateinit var prefs: SharedPreferences

    fun init(context: Context) {
        prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
    }

    private val boxCache = mutableMapOf<String, MutableMap<String, Int>>()

    // ---- Learn mode: a Leitner box 0…5 per item; 5 is mastered ----

    private fun scope(userId: String, slug: String) = "$userId:$slug"

    private fun boxes(userId: String, slug: String): MutableMap<String, Int> {
        val key = scope(userId, slug)
        boxCache[key]?.let { return it }
        val prefix = "box:$key:"
        val map = mutableMapOf<String, Int>()
        // One pass over the file rather than a lookup per item: mastery counts walk
        // the Gauntlet's 601 items while a row is being laid out.
        prefs.all.forEach { (k, v) ->
            if (k.startsWith(prefix) && v is Int) map[k.removePrefix(prefix)] = v
        }
        boxCache[key] = map
        return map
    }

    fun box(userId: String, slug: String, item: String): Int = boxes(userId, slug)[item] ?: 0

    /** Correct promotes by one, wrong demotes by one. Box 5 is mastered. */
    fun grade(userId: String, slug: String, item: String, correct: Boolean) {
        val map = boxes(userId, slug)
        val next = ((map[item] ?: 0) + if (correct) 1 else -1).coerceIn(0, MASTERED_BOX)
        map[item] = next
        prefs.edit().putInt("box:${scope(userId, slug)}:$item", next).apply()
    }

    fun masteredCount(userId: String, slug: String, items: List<String>): Int {
        val map = boxes(userId, slug)
        return items.count { (map[it] ?: 0) >= MASTERED_BOX }
    }

    /**
     * The next items to show in Learn: least-mastered first, so effort goes where
     * it is needed instead of re-drilling what is already known.
     */
    fun learnQueue(userId: String, slug: String, items: List<String>, limit: Int): List<String> {
        val map = boxes(userId, slug)
        return items.sortedBy { map[it] ?: 0 }.take(limit)
    }

    // ---- Lesson homework: the ✦ ----

    private var serverAced: MutableMap<String, Set<String>> = mutableMapOf()

    fun isAced(userId: String, slug: String): Boolean =
        prefs.getBoolean("aced:$userId:$slug", false) || serverAced[userId]?.contains(slug) == true

    fun markAced(userId: String, slug: String) {
        prefs.edit().putBoolean("aced:$userId:$slug", true).apply()
    }

    /** Aced slugs the server derived from a flawless homework run elsewhere. */
    fun setServerAced(userId: String, slugs: List<String>) {
        serverAced[userId] = slugs.toSet()
    }

    fun acedCount(userId: String, slugs: List<String>): Int = slugs.count { isAced(userId, it) }

    // ---- Rapid Fire high scores ----

    private fun bestKey(userId: String, slug: String, level: Int, seconds: Int) =
        "rapidbest:$userId:$slug:$level:$seconds"

    fun rapidBest(userId: String, slug: String, level: Int, seconds: Int): Int =
        prefs.getInt(bestKey(userId, slug, level, seconds), 0)

    /** Merges by max, so a synced server score never lowers a local one. */
    fun setRapidBest(userId: String, slug: String, level: Int, seconds: Int, score: Int) {
        val key = bestKey(userId, slug, level, seconds)
        if (score > prefs.getInt(key, 0)) prefs.edit().putInt(key, score).apply()
    }

    // ---- Continue strip ----

    fun recents(): List<String> =
        prefs.getString("recents", "").orEmpty().split(",").filter { it.isNotBlank() }

    fun noteOpened(slug: String) {
        val next = (listOf(slug) + recents().filter { it != slug }).take(5)
        prefs.edit().putString("recents", next.joinToString(",")).apply()
    }

    // ---- Account deletion ----

    fun purgeAll() {
        boxCache.clear()
        serverAced.clear()
        prefs.edit().clear().apply()
    }
}
