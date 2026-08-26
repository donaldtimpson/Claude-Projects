import Foundation
import SwiftData

// Honor-system homework progress: a lesson drill is "aced" once the student completes a flawless
// homework run (all correct). Stored on-device (SwiftData), keyed "<userId>:<slug>", parallel to
// DrillMastery and sharing its container (see DrillStore). No backend gate — trusted students; the
// ✦ badge is the reward and their record.
@Model
final class LessonAced {
    @Attribute(.unique) var key: String
    var acedAt: Date
    init(key: String, acedAt: Date = .now) { self.key = key; self.acedAt = acedAt }
}

@MainActor
final class LessonProgress {
    static let shared = LessonProgress()

    private var ctx: ModelContext { DrillStore.container.mainContext }

    private init() {}

    private func key(_ userId: String, _ slug: String) -> String { "\(userId):\(slug)" }

    // Wipe every local aced mark (account deletion). Rows are keyed by user id, so
    // leaving them would hand the next sign-in on this device someone else's ✦.
    func purgeAll() {
        serverAced = [:]
        localAced = [:]
        try? ctx.delete(model: LessonAced.self)
        try? ctx.save()
    }

    // Local marks for one user, read with a SINGLE fetch and kept. DrillsView asks per
    // slug while laying out rows (acedCount walks all 19 lessons), so a fetch each put a
    // pile of predicate fetches inside a view body. This class is the only writer.
    private var localAced: [String: Set<String>] = [:]

    private func local(_ userId: String) -> Set<String> {
        if let cached = localAced[userId] { return cached }
        let prefix = userId + ":"
        let rows = (try? ctx.fetch(FetchDescriptor<LessonAced>(
            predicate: #Predicate { $0.key.starts(with: prefix) }))) ?? []
        let slugs = Set(rows.map { String($0.key.dropFirst(prefix.count)) })
        localAced[userId] = slugs
        return slugs
    }

    // Server truth (fetched from /me/lessons), merged with the local optimistic
    // marks so the ✦ shows instantly on a flawless run and syncs across devices.
    private var serverAced: [String: Set<String>] = [:]

    func setServerAced(userId: String, slugs: [String]) {
        serverAced[userId] = Set(slugs)
    }

    func isAced(userId: String, slug: String) -> Bool {
        if serverAced[userId]?.contains(slug) == true { return true }
        return local(userId).contains(slug)
    }

    func markAced(userId: String, slug: String) {
        guard !local(userId).contains(slug) else { return }
        ctx.insert(LessonAced(key: key(userId, slug)))
        try? ctx.save()
        localAced[userId, default: []].insert(slug)
    }

    func acedCount(userId: String, slugs: [String]) -> Int {
        let server = serverAced[userId] ?? []
        let localSlugs = local(userId)
        return slugs.reduce(0) { $0 + (server.contains($1) || localSlugs.contains($1) ? 1 : 0) }
    }
}
