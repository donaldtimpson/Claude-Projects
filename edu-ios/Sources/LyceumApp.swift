import Network
import SwiftUI
import UIKit

@main
struct LyceumApp: App {
    @StateObject private var auth = AuthViewModel()
    @StateObject private var queue = WriteQueueManager.shared
    private let monitor = NWPathMonitor()

    init() {
        // Theme the system bars to match the web (crimson-900 with gold Cinzel titles).
        let cinzel = { (size: CGFloat) in UIFont(name: "Cinzel", size: size) ?? .systemFont(ofSize: size, weight: .semibold) }
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(Theme.crimson900)
        nav.shadowColor = UIColor(Theme.crimson700)
        nav.titleTextAttributes = [.foregroundColor: UIColor(Theme.gold300), .font: cinzel(17)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(Theme.gold300), .font: cinzel(30)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(Theme.crimson900)
        tab.shadowColor = UIColor(Theme.crimson700)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(queue)
                .tint(Theme.gold300)
                .preferredColorScheme(.dark)
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
