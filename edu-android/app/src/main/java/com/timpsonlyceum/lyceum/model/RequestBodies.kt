package com.timpsonlyceum.lyceum.model

import kotlinx.serialization.Serializable
import java.util.UUID

// Bodies for the write endpoints. Each carries a clientId so a replayed write is
// deduped server-side (IdempotencyKey) rather than counted twice.

fun makeClientId(): String = UUID.randomUUID().toString()

@Serializable
data class QuizAttemptBody(
    val videoId: String? = null,
    val courseId: String? = null,
    val score: Int,
    val total: Int,
    val answers: List<Int?>,
    val clientId: String,
)

@Serializable
data class VideoWatchedBody(val videoId: String, val clientId: String)

@Serializable
data class ReviewGradeBody(val questionId: String, val correct: Boolean, val clientId: String)

@Serializable
data class DrillSessionBody(
    val slug: String,
    val level: Int,
    val total: Int,
    val correct: Int,
    val bestStreak: Int,
    val mode: String,
    val durationSec: Int,
    /** Rapid Fire points; omitted for practice. */
    val score: Int? = null,
    val clientId: String,
)

@Serializable
data class CredentialsBody(val email: String, val password: String)

/** Re-authentication for a destructive action (DELETE /me). */
@Serializable
data class PasswordBody(val password: String)

@Serializable
data class RegisterBody(val name: String, val email: String, val password: String)

@Serializable
data class RefreshTokenBody(val refreshToken: String)

@Serializable
data class HandleBody(val handle: String)

@Serializable
data class DeletedResponse(val deleted: Boolean = false)

@Serializable
data class OkResponse(val ok: Boolean? = null)

/** A new lecture comment; `parentId` null means top-level. */
@Serializable
data class NewCommentBody(
    val videoId: String,
    val body: String,
    val parentId: String? = null,
)
