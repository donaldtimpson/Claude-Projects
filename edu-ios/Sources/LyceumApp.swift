import Network
import SwiftUI

@main
struct LyceumApp: App {
    @StateObject private var auth = AuthViewModel()
    @StateObject private var queue = WriteQueueManager.shared
    private let monitor = NWPathMonitor()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(queue)
                .tint(Theme.crimson)
                .task { await auth.bootstrap() }
                .onAppear { startNetworkFlush() }
        }
    }

    private func startNetworkFlush() {
        monitor.pathUpdateHandler = { path in
            guard path.status == .satisfied else { return }
            Task { await WriteQueueManager.shared.flush() }
        }
        monitor.start(queue: DispatchQueue.global(qos: .utility))
    }
}
