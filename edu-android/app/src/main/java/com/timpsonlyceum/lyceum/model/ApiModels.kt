package com.timpsonlyceum.lyceum.model

import kotlinx.serialization.Serializable

// Serializable mirrors of the JSON returned by edu-web's app/api/mobile/v1/…
// routes. Field-for-field the same contract the iOS app's APIModels.swift
// describes; where a field is optional there it is nullable here, for the same
// reason — resilience against a server build older than this client.

@Serializable
data class AuthUser(
    val id: String,
    val name: String? = null,
    val email: String,
    val handle: String? = null,
)

@Serializable
data class AuthResponse(
    val user: AuthUser,
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Int,
)

@Serializable
data class TokenPair(
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Int,
)

@Serializable
data class Streak(val count: Int, val activeToday: Boolean)

@Serializable
data class DrillBest(
    val slug: String,
    val level: Int,
    val durationSec: Int,
    val best: Int,
)

@Serializable
data class MeResponse(
    val user: AuthUser,
    val streak: Streak,
    val dueCount: Int,
    val drillBests: List<DrillBest>? = null,
    /** What the Hall of Scholars calls this student when [AuthUser.handle] is null. */
    val handlePlaceholder: String? = null,
)

@Serializable
data class Badge(
    val key: String,
    val name: String,
    val blurb: String,
    val tier: String,
    val category: String,
    val unlocked: Boolean,
)

@Serializable
data class CourseListItem(
    val id: String,
    val title: String,
    val shortTitle: String? = null,
    val description: String,
    val thumbnailUrl: String,
    val videoCount: Int,
    val isCurrent: Boolean,
    val updatedAt: String,
)

@Serializable
data class CoursesResponse(val courses: List<CourseListItem>)

@Serializable
data class CategoryItem(
    val id: String,
    val name: String,
    val slug: String,
    val courseCount: Int? = null,
)

@Serializable
data class CategoriesResponse(val categories: List<CategoryItem>)

@Serializable
data class CategoryDetailResponse(
    val category: CategoryItem,
    val courses: List<CourseListItem>,
)

// Search (mirrors lib/search.ts)
@Serializable
data class CourseHit(
    val id: String,
    val title: String,
    val description: String,
    val thumbnailUrl: String,
)

@Serializable
data class LectureHit(
    val videoId: String,
    val courseId: String,
    val title: String,
    val courseTitle: String,
    val snippet: String? = null,
    val startSeconds: Int? = null,
)

@Serializable
data class SearchResults(
    val courses: List<CourseHit> = emptyList(),
    val lectures: List<LectureHit> = emptyList(),
    val fuzzy: Boolean? = null,
)

@Serializable
data class VideoListItem(
    val id: String,
    val youtubeVideoId: String,
    val title: String,
    val position: Int,
    val durationSeconds: Int,
    val thumbnailUrl: String,
)

@Serializable
data class ProblemSetItem(
    val id: String,
    val title: String,
    val points: Int,
    val attachmentUrl: String? = null,
    val hasSolutions: Boolean? = null,
    /** Lecture positions this set covers, ascending — renders as "Lectures 4–5". */
    val lecturePositions: List<Int>? = null,
) {
    val lectureSpan: String?
        get() {
            val p = lecturePositions ?: return null
            val first = p.firstOrNull() ?: return null
            val last = p.lastOrNull() ?: return null
            return if (first == last) "Lecture $first" else "Lectures $first–$last"
        }
}

/** One problem paired with the worked solution that answers it; solution is null when withheld. */
@Serializable
data class ProblemPart(
    val key: String,
    val label: String,
    val problem: String,
    val solution: String? = null,
) {
    /** Named sections (Extra Credit) are set apart from the numbered problems. */
    val isSection: Boolean get() = key.startsWith("section:")
}

@Serializable
data class ProblemSetContent(
    val mode: String,
    val problemsPreamble: String? = null,
    val solutionPreamble: String? = null,
    val parts: List<ProblemPart>? = null,
    val body: String? = null,
    val solution: String? = null,
) {
    val isPaired: Boolean get() = mode == "paired"
}

@Serializable
data class ProblemSetLecture(val id: String, val title: String, val position: Int)

@Serializable
data class ProblemSetDetail(
    val id: String,
    val title: String,
    val points: Int,
    val extraCreditPoints: Int,
    val attachmentUrl: String? = null,
    val solutionsAvailable: Boolean,
    val lectures: List<ProblemSetLecture>? = null,
    val content: ProblemSetContent,
)

@Serializable
data class ProblemSetDetailResponse(val problemSet: ProblemSetDetail)

@Serializable
data class CourseResourceItem(
    val id: String,
    val title: String,
    val url: String,
    val kind: String,
)

@Serializable
data class CourseOffering(val id: String, val title: String, val year: Int? = null)

@Serializable
data class CourseDetail(
    val id: String,
    val title: String,
    val shortTitle: String? = null,
    val description: String,
    val thumbnailUrl: String,
    val videoCount: Int,
    val isCurrent: Boolean,
    val updatedAt: String,
    val videos: List<VideoListItem> = emptyList(),
    val problemSets: List<ProblemSetItem> = emptyList(),
    val resources: List<CourseResourceItem> = emptyList(),
    val offerings: List<CourseOffering>? = null,
    /** 0 ⇒ this course has no test yet, so nothing is offered. */
    val testQuestionCount: Int? = null,
)

@Serializable
data class CourseDetailResponse(val course: CourseDetail)

@Serializable
data class QuizQuestion(
    val id: String,
    val prompt: String,
    val options: List<String>,
    val correctIndex: Int,
    val explanation: String,
    val position: Int,
)

@Serializable
data class QuizResponse(val questions: List<QuizQuestion>)

@Serializable
data class LectureNote(val content: String, val updatedAt: String)

@Serializable
data class VideoMeta(
    val id: String,
    val youtubeVideoId: String,
    val title: String,
    val description: String,
    val position: Int,
    val durationSeconds: Int,
    val updatedAt: String,
)

@Serializable
data class QuizAce(val userId: String, val handle: String)

@Serializable
data class VideoDetailResponse(
    val video: VideoMeta,
    val note: LectureNote? = null,
    val quiz: List<QuizQuestion> = emptyList(),
    val aces: List<QuizAce>? = null,
    val problemSets: List<ProblemSetItem>? = null,
    /** Lesson-drill slugs; a slug this build doesn't know is dropped, not rendered. */
    val lessonSlugs: List<String>? = null,
)

// MARK: - Course map (the web /map)

@Serializable
data class MapCourse(
    val id: String,
    val title: String,
    val shortTitle: String? = null,
    val isCurrent: Boolean? = null,
) {
    /**
     * A node label has about 85dp to live in, so the full title won't do. Takes the
     * part before a dash subtitle and drops a trailing parenthetical.
     */
    val nodeLabel: String
        get() {
            var t = shortTitle ?: title
            for (sep in listOf(" – ", " — ", " - ")) {
                val i = t.indexOf(sep)
                if (i >= 0) { t = t.substring(0, i); break }
            }
            val open = t.lastIndexOf('(')
            if (open > 0 && t.endsWith(")")) t = t.substring(0, open)
            return t.trim()
        }
}

@Serializable
data class MapLink(
    val fromCourseId: String,
    val toCourseId: String,
    val kind: String,
) {
    val isRecommended: Boolean get() = kind == "RECOMMENDED"
}

@Serializable
data class CourseMapResponse(
    val courses: List<MapCourse> = emptyList(),
    val links: List<MapLink> = emptyList(),
)

// MARK: - Hall of Scholars (the web /leaderboard)

@Serializable
data class Scholar(
    val handle: String,
    val lectures: Int,
    val quizPts: Int,
    val completions: Int,
    val badgePts: Int,
    val standing: Int,
    val house: Boolean? = null,
    val note: String? = null,
    /** Absent for the house scholars (Aristotle and company), who aren't real users. */
    val userId: String? = null,
)

@Serializable
data class ScholarEntry(
    val scholar: Scholar,
    val badges: List<Badge>? = null,
    val house: Boolean? = null,
    val note: String? = null,
) {
    val id: String get() = scholar.userId ?: "house:" + scholar.handle
    val isHouse: Boolean get() = house ?: scholar.house ?: false
    val blurb: String? get() = note ?: scholar.note
}

@Serializable
data class ScoringRules(
    val lecture: Int,
    val quizPerCorrect: Int,
    val testPerCorrect: Int,
    val completion: Int,
    val badgeMin: Int,
    val badgeMax: Int,
)

@Serializable
data class LeaderboardResponse(
    val scholars: List<ScholarEntry> = emptyList(),
    val scoring: ScoringRules? = null,
)

// MARK: - Progress screen (mobile half of the web /dashboard)

@Serializable
data class GradeWeights(
    val attendance: Int,
    val quizzes: Int,
    val test: Int,
    val homework: Int,
    val midterm: Int,
    val final: Int,
)

/** One category row of a class grade: label, percentage (null = pending), weight, denominator. */
data class GradeBreakdownRow(
    val label: String,
    val pct: Double?,
    val weight: Int,
    val detail: String,
)

@Serializable
data class ClassGrade(
    val sectionId: String,
    val sectionName: String,
    val courseId: String,
    val courseTitle: String,
    val currentGrade: Double? = null,
    val attendancePct: Double? = null,
    val quizAvgPct: Double? = null,
    val hwPct: Double? = null,
    val testPct: Double? = null,
    val midtermPct: Double? = null,
    val finalPct: Double? = null,
    val watchedCount: Int,
    val totalLectures: Int,
    val quizzesTaken: Int,
    val totalQuizzes: Int,
    val hwGradedCount: Int,
    val totalAssignments: Int,
    val hasTest: Boolean,
    val weights: GradeWeights,
) {
    /** The six categories in the web's order, with their weights and denominators. */
    val breakdown: List<GradeBreakdownRow>
        get() = listOf(
            GradeBreakdownRow("Attendance", attendancePct, weights.attendance, "$watchedCount/$totalLectures lectures"),
            GradeBreakdownRow("Quizzes", quizAvgPct, weights.quizzes, "$quizzesTaken/$totalQuizzes taken"),
            GradeBreakdownRow("Homework", hwPct, weights.homework, "$hwGradedCount/$totalAssignments graded"),
            GradeBreakdownRow("Course Test", testPct, weights.test, if (hasTest) "best attempt" else "no test yet"),
            GradeBreakdownRow("Midterm", midtermPct, weights.midterm, "in class"),
            GradeBreakdownRow("Final", finalPct, weights.final, "in class"),
        )
}

@Serializable
data class CourseProgressItem(
    val id: String,
    val title: String,
    val watchedCount: Int,
    val totalCount: Int,
) {
    val fraction: Double get() = if (totalCount > 0) watchedCount.toDouble() / totalCount else 0.0
}

@Serializable
data class ProgressResponse(
    val classes: List<ClassGrade> = emptyList(),
    val inProgress: List<CourseProgressItem> = emptyList(),
    val completed: List<CourseProgressItem> = emptyList(),
)

@Serializable
data class HandleResponse(val user: AuthUser)

@Serializable
data class DueCard(
    val id: String,
    val prompt: String,
    val options: List<String>,
    val correctIndex: Int,
    val explanation: String,
    val source: String,
)

@Serializable
data class ReviewDeckResponse(
    val cards: List<DueCard> = emptyList(),
    val dueCount: Int = 0,
)

@Serializable
data class BadgesResponse(val badges: List<Badge> = emptyList())

@Serializable
data class LessonsResponse(val acedSlugs: List<String> = emptyList())

@Serializable
data class WriteResult(
    val duplicate: Boolean = false,
    val badges: List<Badge> = emptyList(),
)

// MARK: - Lecture discussion (comments)

@Serializable
data class CommentAuthor(val id: String, val name: String)

@Serializable
data class CommentItem(
    val id: String,
    val body: String,
    val createdAt: String,
    val parentId: String? = null,
    val deleted: Boolean = false,
    val user: CommentAuthor,
    val replies: List<CommentItem> = emptyList(),
)

@Serializable
data class CommentsResponse(val comments: List<CommentItem> = emptyList())

@Serializable
data class DeleteCommentResult(val ok: Boolean, val mode: String)

/** A bare `{}` for endpoints whose body we don't model. */
@Serializable
class EmptyResponse
