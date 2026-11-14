import Network
import SwiftUI
import UIKit

@main
struct LyceumApp: App {
    // Lets the tap-to-locate map allow landscape rotation while the rest of the app stays
    // portrait (the delegate reports OrientationGate.mask).
    @UIApplicationDelegateAdaptor(OrientationAppDelegate.self) private var orientationDelegate
    @StateObject private var auth = AuthViewModel()
    @StateObject private var queue = WriteQueueManager.shared
    private let monitor = NWPathMonitor()

    @AppStorage(Appearance.storageKey) private var appearance: Appearance = .system

    init() {
        // System bars follow the theme: card-colored bars, serif titles in ink.
        let serif = { (size: CGFloat, weight: UIFont.Weight) -> UIFont in
            let base = UIFont(name: "Source Serif 4", size: size) ?? .systemFont(ofSize: size)
            let desc = base.fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
            return UIFont(descriptor: desc, size: size)
        }
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(Theme.card)
        nav.shadowColor = UIColor(Theme.line)
        nav.titleTextAttributes = [.foregroundColor: UIColor(Theme.ink), .font: serif(18, .semibold)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(Theme.ink), .font: serif(32, .bold)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(Theme.card)
        tab.shadowColor = UIColor(Theme.line)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(queue)
                .tint(Theme.link)
                .preferredColorScheme(appearance.colorScheme)
                .task { await auth.bootstrap() }
                .onAppear {
                    startNetworkFlush()
                    // Build the drill SwiftData store + catalog off the main thread now,
                    // while the splash is up waiting on auth, rather than inside the first
                    // render of the Drills tab.
                    DrillStore.warm()
                }
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
