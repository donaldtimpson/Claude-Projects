import Foundation
import SwiftData

// Honor-system homework progress: a lesson drill is "aced" once the student completes a flawless
// homework run (all correct). Stored on-device (SwiftData), keyed "<userId>:<slug>", parallel to
// DrillMastery. No backend gate — trusted students; the ✦ badge is the reward and their record.
@Model
final class LessonAced {
    @Attribute(.unique) var key: String
    var acedAt: Date
    init(key: String, acedAt: Date = .now) { self.key = key; self.acedAt = acedAt }
}

@MainActor
final class LessonProgress {
    static let shared = LessonProgress()

    private let container: ModelContainer
    private var ctx: ModelContext { container.mainContext }

    private init() {
        do { container = try ModelContainer(for: LessonAced.self) }
        catch { fatalError("LessonProgress SwiftData container: \(error)") }
    }

    private func key(_ userId: String, _ slug: String) -> String { "\(userId):\(slug)" }

    private func row(_ key: String) -> LessonAced? {
        var d = FetchDescriptor<LessonAced>(predicate: #Predicate { $0.key == key })
        d.fetchLimit = 1
        return try? ctx.fetch(d).first
    }

    // Server truth (fetched from /me/lessons), merged with the local optimistic
    // marks so the ✦ shows instantly on a flawless run and syncs across devices.
    private var serverAced: [String: Set<String>] = [:]

    func setServerAced(userId: String, slugs: [String]) {
        serverAced[userId] = Set(slugs)
    }

    func isAced(userId: String, slug: String) -> Bool {
        if serverAced[userId]?.contains(slug) == true { return true }
        return row(key(userId, slug)) != nil
    }

    func markAced(userId: String, slug: String) {
        let k = key(userId, slug)
        guard row(k) == nil else { return }
        ctx.insert(LessonAced(key: k))
        try? ctx.save()
    }

    func acedCount(userId: String, slugs: [String]) -> Int {
        slugs.reduce(0) { $0 + (isAced(userId: userId, slug: $1) ? 1 : 0) }
    }
}
