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

struct MeResponse: Codable {
    let user: AuthUser
    let streak: Streak
    let dueCount: Int
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
    let attachmentUrl: String?
}

struct CourseResourceItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let url: String
    let kind: String
}

struct CourseDetail: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let thumbnailUrl: String
    let videoCount: Int
    let isCurrent: Bool
    let updatedAt: String
    let videos: [VideoListItem]
    let problemSets: [ProblemSetItem]
    let resources: [CourseResourceItem]
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

struct VideoDetailResponse: Codable {
    let video: VideoMeta
    let note: LectureNote?
    let quiz: [QuizQuestion]
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

struct WriteResult: Codable {
    let duplicate: Bool
    let badges: [Badge]
}
