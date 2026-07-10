import Foundation
import SwiftData

// SwiftData-backed offline write queue. Engagement writes (quiz attempts, review
// grades, drill sessions, watch progress) go through WriteQueueManager: it tries
// the network first and, on a transient failure, persists the request to replay
// on reconnect. Each row carries a clientId so the server dedups replays.
@Model
final class QueuedWrite {
    @Attribute(.unique) var clientId: String
    var path: String
    var bodyJSON: String
    var createdAt: Date

    init(clientId: String, path: String, bodyJSON: String, createdAt: Date = .now) {
        self.clientId = clientId
        self.path = path
        self.bodyJSON = bodyJSON
        self.createdAt = createdAt
    }
}

@MainActor
final class WriteQueueManager: ObservableObject {
    static let shared = WriteQueueManager()

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }
    @Published private(set) var pending: Int = 0

    private init() {
        do {
            container = try ModelContainer(for: QueuedWrite.self)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
        refreshCount()
    }

    /// Try a write now; queue it on a transient failure. Returns the server
    /// result when it went through, or nil when queued / dropped.
    func submit<B: Encodable>(path: String, body: B, clientId: String) async -> WriteResult? {
        do {
            return try await APIClient.shared.post(path, body: body)
        } catch let e as APIError where e.status >= 400 && e.status < 500 && e.status != 429 {
            return nil // permanent client error — nothing to retry
        } catch {
            enqueue(path: path, body: body, clientId: clientId)
            return nil
        }
    }

    func enqueue<B: Encodable>(path: String, body: B, clientId: String) {
        guard let data = try? JSONEncoder().encode(body),
              let json = String(data: data, encoding: .utf8) else { return }
        context.insert(QueuedWrite(clientId: clientId, path: path, bodyJSON: json))
        try? context.save()
        refreshCount()
    }

    func flush() async {
        let descriptor = FetchDescriptor<QueuedWrite>(sortBy: [SortDescriptor(\.createdAt)])
        let items = (try? context.fetch(descriptor)) ?? []
        for item in items {
            guard let bodyData = item.bodyJSON.data(using: .utf8) else {
                context.delete(item)
                continue
            }
            do {
                try await APIClient.shared.postRaw(item.path, jsonBody: bodyData)
                context.delete(item)
            } catch let e as APIError where e.status >= 400 && e.status < 500 && e.status != 429 {
                context.delete(item) // permanent — drop
            } catch {
                // transient — keep for the next flush
            }
        }
        try? context.save()
        refreshCount()
    }

    private func refreshCount() {
        pending = (try? context.fetchCount(FetchDescriptor<QueuedWrite>())) ?? 0
    }
}
