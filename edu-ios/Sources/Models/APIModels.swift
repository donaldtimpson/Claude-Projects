import Foundation

// Codable mirrors of the JSON returned by edu-web's app/api/mobile/v1/* routes.

struct AuthUser: Codable, Identifiable, Hashable {
    let id: String
    let name: String?
    let email: String
    var handle: String?
}

struct AuthResponse: Codable {
    let user: AuthUser
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

struct TokenPair: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

struct Streak: Codable, Hashable {
    let count: Int
    let activeToday: Bool
}

struct DrillBest: Codable, Hashable {
    let slug: String
    let level: Int
    let durationSec: Int
    let best: Int
}

struct MeResponse: Codable {
    let user: AuthUser
    let streak: Streak
    let dueCount: Int
    var drillBests: [DrillBest]? = nil   // synced Rapid Fire high scores
    /// What the Hall of Scholars calls this student when `user.handle` is nil. The
    /// leaderboard has always shown an auto-assigned name in that case; this is it, so
    /// the profile can show the same one instead of a blank. Optional for older servers.
    var handlePlaceholder: String? = nil
}

struct Badge: Codable, Identifiable, Hashable {
    var id: String { key }
    let key: String
    let name: String
    let blurb: String
    let tier: String
    let category: String
    let unlocked: Bool
}

struct CourseListItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    var shortTitle: String?
    let description: String
    let thumbnailUrl: String
    let videoCount: Int
    let isCurrent: Bool
    let updatedAt: String
}

struct CoursesResponse: Codable {
    let courses: [CourseListItem]
}

struct CategoryItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let slug: String
    var courseCount: Int?
}

struct CategoriesResponse: Codable {
    let categories: [CategoryItem]
}

struct CategoryDetailResponse: Codable {
    let category: CategoryItem
    let courses: [CourseListItem]
}

// Search (mirrors lib/search.ts)
struct CourseHit: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let thumbnailUrl: String
}

struct LectureHit: Codable, Identifiable, Hashable {
    var id: String { videoId }
    let videoId: String
    let courseId: String
    let title: String
    let courseTitle: String
    let snippet: String?
    let startSeconds: Int?
}

struct SearchResults: Codable {
    let courses: [CourseHit]
    let lectures: [LectureHit]
    let fuzzy: Bool?
}

struct VideoListItem: Codable, Identifiable, Hashable {
    let id: String
    let youtubeVideoId: String
    let title: String
    let position: Int
    let durationSeconds: Int
    let thumbnailUrl: String
}

struct ProblemSetItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let points: Int
    var attachmentUrl: String?
    // Optional for resilience against older server builds that predate solutions.
    var hasSolutions: Bool?
    /// Lecture positions this set covers, ascending — renders as "Lectures 4–5".
    var lecturePositions: [Int]?

    var lectureSpan: String? {
        guard let p = lecturePositions, let first = p.first, let last = p.last else { return nil }
        return first == last ? "Lecture \(first)" : "Lectures \(first)–\(last)"
    }
}

/// One problem paired with the worked solution that answers it. The server does
/// the pairing (see app/api/mobile/v1/.../problems/[problemSetId]) so the split
/// rules live in exactly one place; `solution` is nil when withheld.
struct ProblemPart: Codable, Identifiable, Hashable {
    let key: String
    let label: String
    let problem: String
    let solution: String?

    var id: String { key }
    /// Named sections (Extra Credit) are set apart from the numbered problems.
    var isSection: Bool { key.hasPrefix("section:") }
}

/// Mirrors the server's PairedProblemSet union: "paired" carries per-problem
/// parts; "blocks" means the two halves didn't line up and the solutions come
/// as one appended lump.
struct ProblemSetContent: Codable, Hashable {
    let mode: String
    var problemsPreamble: String?
    var solutionPreamble: String?
    var parts: [ProblemPart]?
    var body: String?
    var solution: String?

    var isPaired: Bool { mode == "paired" }
}

struct ProblemSetLecture: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let position: Int
}

struct ProblemSetDetail: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let points: Int
    let extraCreditPoints: Int
    var attachmentUrl: String?
    let solutionsAvailable: Bool
    var lectures: [ProblemSetLecture]?
    let content: ProblemSetContent
}

struct ProblemSetDetailResponse: Codable {
    let problemSet: ProblemSetDetail
}

struct CourseResourceItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let url: String
    let kind: String
}

struct CourseOffering: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let year: Int?
}

struct CourseDetail: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    var shortTitle: String?
    let description: String
    let thumbnailUrl: String
    let videoCount: Int
    let isCurrent: Bool
    let updatedAt: String
    let videos: [VideoListItem]
    let problemSets: [ProblemSetItem]
    let resources: [CourseResourceItem]
    var offerings: [CourseOffering]?
    /// Published course-level questions (the course test). 0 ⇒ this course has no
    /// test yet, so nothing is offered. Optional for older servers.
    var testQuestionCount: Int? = nil
}

struct CourseDetailResponse: Codable {
    let course: CourseDetail
}

struct QuizQuestion: Codable, Identifiable, Hashable {
    let id: String
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
    let position: Int
}

/// GET /quiz?courseId= — the course test's published questions.
struct QuizResponse: Codable {
    let questions: [QuizQuestion]
}

struct LectureNote: Codable, Hashable {
    let content: String
    let updatedAt: String
}

struct VideoMeta: Codable, Identifiable, Hashable {
    let id: String
    let youtubeVideoId: String
    let title: String
    let description: String
    let position: Int
    let durationSeconds: Int
    let updatedAt: String
}

struct QuizAce: Codable, Identifiable, Hashable {
    let userId: String
    let handle: String
    var id: String { userId }
}

struct VideoDetailResponse: Codable {
    let video: VideoMeta
    let note: LectureNote?
    let quiz: [QuizQuestion]
    let aces: [QuizAce]?  // optional for resilience against pre-aces server builds
    // Problem sets tagged as covering this lecture; optional for the same reason.
    var problemSets: [ProblemSetItem]?
    // Lesson drills tagged as covering this lecture. Slugs only — title and blurb
    // come from the bundled catalog, so a slug this build doesn't know is simply
    // dropped rather than rendering a row that can't open. Optional for the same
    // resilience reason as the fields above.
    var lessonSlugs: [String]?
}

// MARK: - Hall of Scholars (the web /leaderboard)

struct Scholar: Codable, Hashable {
    let handle: String
    let lectures: Int
    let quizPts: Int
    let completions: Int
    let badgePts: Int
    let standing: Int
    var house: Bool? = nil
    var note: String? = nil
    /// Absent for the house scholars (Aristotle and company), who aren't real users.
    var userId: String? = nil
}

struct ScholarEntry: Codable, Identifiable, Hashable {
    let scholar: Scholar
    var badges: [Badge]? = nil
    var house: Bool? = nil
    var note: String? = nil

    var id: String { scholar.userId ?? "house:" + scholar.handle }
    var isHouse: Bool { house ?? scholar.house ?? false }
    var blurb: String? { note ?? scholar.note }
}

/// The scoring rules, sent with the board so the app's explainer can't drift from
/// the totals it sits under. Optional for older servers.
struct ScoringRules: Codable, Hashable {
    let lecture: Int
    let quizPerCorrect: Int
    let testPerCorrect: Int
    let completion: Int
    let badgeMin: Int
    let badgeMax: Int
}

struct LeaderboardResponse: Codable {
    let scholars: [ScholarEntry]
    var scoring: ScoringRules? = nil
}

// MARK: - Progress screen (mobile half of the web /dashboard)

/// One enrolled class with this student's own grade. Percentages are nil until a
/// category has data — "pending", not zero, exactly as the web renders it.
struct ClassGrade: Codable, Identifiable, Hashable {
    let sectionId: String
    let sectionName: String
    let courseId: String
    let courseTitle: String
    let currentGrade: Double?
    let attendancePct: Double?
    let quizAvgPct: Double?
    let hwPct: Double?
    let testPct: Double?
    let midtermPct: Double?
    let finalPct: Double?
    let watchedCount: Int
    let totalLectures: Int
    let quizzesTaken: Int
    let totalQuizzes: Int
    let hwGradedCount: Int
    let totalAssignments: Int
    let hasTest: Bool
    let weights: GradeWeights

    var id: String { sectionId }

    /// The six categories in the web's order, with their weights and denominators.
    var breakdown: [(label: String, pct: Double?, weight: Int, detail: String)] {
        [
            ("Attendance", attendancePct, weights.attendance, "\(watchedCount)/\(totalLectures) lectures"),
            ("Quizzes", quizAvgPct, weights.quizzes, "\(quizzesTaken)/\(totalQuizzes) taken"),
            ("Homework", hwPct, weights.homework, "\(hwGradedCount)/\(totalAssignments) graded"),
            ("Course Test", testPct, weights.test, hasTest ? "best attempt" : "no test yet"),
            ("Midterm", midtermPct, weights.midterm, "in class"),
            ("Final", finalPct, weights.final, "in class"),
        ]
    }
}

struct GradeWeights: Codable, Hashable {
    let attendance: Int
    let quizzes: Int
    let test: Int
    let homework: Int
    let midterm: Int
    let final: Int
}

struct CourseProgressItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let watchedCount: Int
    let totalCount: Int

    var fraction: Double { totalCount > 0 ? Double(watchedCount) / Double(totalCount) : 0 }
}

struct ProgressResponse: Codable {
    let classes: [ClassGrade]
    let inProgress: [CourseProgressItem]
    let completed: [CourseProgressItem]
}

struct HandleResponse: Codable {
    let user: AuthUser
}

struct DueCard: Codable, Identifiable, Hashable {
    let id: String
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
    let source: String
}

struct ReviewDeckResponse: Codable {
    let cards: [DueCard]
    let dueCount: Int
}

struct BadgesResponse: Codable {
    let badges: [Badge]
}

// Aced grammar-lesson slugs for the current user, derived server-side from a
// flawless homework run (see edu-web lib/lessons.ts). Merged into LessonProgress.
struct LessonsResponse: Codable {
    let acedSlugs: [String]
}

struct WriteResult: Codable {
    let duplicate: Bool
    let badges: [Badge]
}

// MARK: - Lecture discussion (comments)

struct CommentAuthor: Codable, Hashable {
    let id: String
    let name: String
}

// Single-level threaded: top-level comments carry their replies. Deleted comments
// come back with `deleted: true`, an empty author, and a placeholder body.
struct CommentItem: Codable, Identifiable, Hashable {
    let id: String
    let body: String
    let createdAt: String
    let parentId: String?
    let deleted: Bool
    let user: CommentAuthor
    let replies: [CommentItem]
}

struct CommentsResponse: Codable {
    let comments: [CommentItem]
}

struct NewCommentBody: Encodable {
    let videoId: String
    let body: String
    let parentId: String?  // nil => top-level comment
}

struct DeleteCommentResult: Codable {
    let ok: Bool
    let mode: String  // "soft" (kept as placeholder) or "hard" (removed)
}
