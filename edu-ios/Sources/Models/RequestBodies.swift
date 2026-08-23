import Foundation

// Encodable bodies for the write endpoints. Each carries a clientId so an
// offline replay is deduped server-side (IdempotencyKey).

func makeClientId() -> String { UUID().uuidString }

struct QuizAttemptBody: Encodable {
    let videoId: String?
    let courseId: String?
    let score: Int
    let total: Int
    let answers: [Int?]
    let clientId: String
}

struct VideoWatchedBody: Encodable {
    let videoId: String
    let clientId: String
}

struct ReviewGradeBody: Encodable {
    let questionId: String
    let correct: Bool
    let clientId: String
}

struct DrillSessionBody: Encodable {
    let slug: String
    let level: Int
    let total: Int
    let correct: Int
    let bestStreak: Int
    let mode: String
    let durationSec: Int
    var score: Int? = nil   // Rapid Fire points; omitted for practice
    let clientId: String
}

struct CredentialsBody: Encodable {
    let email: String
    let password: String
}

// Re-authentication for a destructive action (DELETE /me).
struct PasswordBody: Encodable {
    let password: String
}

struct RegisterBody: Encodable {
    let name: String
    let email: String
    let password: String
}

struct AppleName: Encodable {
    let givenName: String?
    let familyName: String?
}

struct AppleSignInBody: Encodable {
    let identityToken: String
    let fullName: AppleName?
}
