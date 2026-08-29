package com.timpsonlyceum.lyceum.net

import com.timpsonlyceum.lyceum.model.*
import java.net.URLEncoder

/**
 * Every call the app makes, in one place, so a path or a body shape is written
 * once. Mirrors the endpoints the iOS app uses against
 * edu-web/app/api/mobile/v1.
 *
 * `auth = false` marks the endpoints that are public. That flag is not a
 * convenience: it is what lets the whole browse half of the app work with no
 * account, which is the behaviour App Review required under 5.1.1.
 */
object Repository {
    private val json = ApiClient.json
    private fun enc(s: String): String = URLEncoder.encode(s, "UTF-8")

    // ---- catalog (public) ----

    suspend fun courses(): CoursesResponse =
        ApiClient.get("/courses", CoursesResponse.serializer(), auth = false)

    suspend fun categories(): CategoriesResponse =
        ApiClient.get("/categories", CategoriesResponse.serializer(), auth = false)

    suspend fun category(slug: String): CategoryDetailResponse =
        ApiClient.get("/categories/$slug", CategoryDetailResponse.serializer(), auth = false)

    suspend fun course(courseId: String): CourseDetailResponse =
        ApiClient.get("/courses/$courseId", CourseDetailResponse.serializer(), auth = false)

    suspend fun video(courseId: String, videoId: String): VideoDetailResponse =
        ApiClient.get("/courses/$courseId/videos/$videoId", VideoDetailResponse.serializer(), auth = false)

    suspend fun problemSet(courseId: String, problemSetId: String): ProblemSetDetailResponse =
        ApiClient.get("/courses/$courseId/problems/$problemSetId", ProblemSetDetailResponse.serializer(), auth = false)

    suspend fun courseTest(courseId: String): QuizResponse =
        ApiClient.get("/quiz?courseId=$courseId", QuizResponse.serializer(), auth = false)

    suspend fun search(query: String): SearchResults =
        ApiClient.get("/search?q=${enc(query)}", SearchResults.serializer(), auth = false)

    suspend fun courseMap(): CourseMapResponse =
        ApiClient.get("/map", CourseMapResponse.serializer(), auth = false)

    suspend fun leaderboard(): LeaderboardResponse =
        ApiClient.get("/leaderboard", LeaderboardResponse.serializer(), auth = false)

    // ---- account ----

    suspend fun login(email: String, password: String): AuthResponse = ApiClient.post(
        "/auth/login",
        json.encodeToString(CredentialsBody.serializer(), CredentialsBody(email, password)),
        AuthResponse.serializer(),
        auth = false,
    )

    suspend fun register(name: String, email: String, password: String): AuthResponse = ApiClient.post(
        "/auth/register",
        json.encodeToString(RegisterBody.serializer(), RegisterBody(name, email, password)),
        AuthResponse.serializer(),
        auth = false,
    )

    suspend fun logout(refreshToken: String): OkResponse = ApiClient.post(
        "/auth/logout",
        json.encodeToString(RefreshTokenBody.serializer(), RefreshTokenBody(refreshToken)),
        OkResponse.serializer(),
        auth = false,
    )

    suspend fun me(): MeResponse = ApiClient.get("/me", MeResponse.serializer())

    /**
     * Permanently deletes the account, server-side. The password is re-sent so a
     * stolen access token alone cannot wipe an account.
     */
    suspend fun deleteAccount(password: String): DeletedResponse = ApiClient.delete(
        "/me",
        json.encodeToString(PasswordBody.serializer(), PasswordBody(password)),
        DeletedResponse.serializer(),
    )

    suspend fun setHandle(handle: String): HandleResponse = ApiClient.put(
        "/me/handle",
        json.encodeToString(HandleBody.serializer(), HandleBody(handle)),
        HandleResponse.serializer(),
    )

    suspend fun badges(): BadgesResponse = ApiClient.get("/me/badges", BadgesResponse.serializer())

    suspend fun progress(): ProgressResponse = ApiClient.get("/me/progress", ProgressResponse.serializer())

    suspend fun lessons(): LessonsResponse = ApiClient.get("/me/lessons", LessonsResponse.serializer())

    // ---- writes ----

    suspend fun recordQuizAttempt(body: QuizAttemptBody): WriteResult = ApiClient.post(
        "/quiz/attempt",
        json.encodeToString(QuizAttemptBody.serializer(), body),
        WriteResult.serializer(),
    )

    suspend fun recordVideoWatched(body: VideoWatchedBody): WriteResult = ApiClient.post(
        "/progress/video-watched",
        json.encodeToString(VideoWatchedBody.serializer(), body),
        WriteResult.serializer(),
    )

    suspend fun recordDrillSession(body: DrillSessionBody): WriteResult = ApiClient.post(
        "/drills/session",
        json.encodeToString(DrillSessionBody.serializer(), body),
        WriteResult.serializer(),
    )

    // ---- spaced repetition ----

    suspend fun reviewDeck(): ReviewDeckResponse =
        ApiClient.get("/review/deck", ReviewDeckResponse.serializer())

    suspend fun gradeReview(body: ReviewGradeBody): WriteResult = ApiClient.post(
        "/review/grade",
        json.encodeToString(ReviewGradeBody.serializer(), body),
        WriteResult.serializer(),
    )

    suspend fun finishReview(): WriteResult =
        ApiClient.post("/review/finish", "{}", WriteResult.serializer())

    // ---- lecture discussion ----
    // Off in 1.0 on iOS (no report/block, so Guideline 1.2 applies); the calls are
    // kept so turning the feature on is a UI change, not a networking one.

    suspend fun comments(videoId: String): CommentsResponse =
        ApiClient.get("/comments?videoId=${enc(videoId)}", CommentsResponse.serializer(), auth = false)

    suspend fun addComment(body: NewCommentBody): EmptyResponse = ApiClient.post(
        "/comments",
        json.encodeToString(NewCommentBody.serializer(), body),
        EmptyResponse.serializer(),
    )

    suspend fun deleteComment(id: String): DeleteCommentResult =
        ApiClient.delete("/comments/$id", null, DeleteCommentResult.serializer())
}
