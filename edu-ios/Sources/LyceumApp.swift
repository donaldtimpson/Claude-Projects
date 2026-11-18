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
        // Navigation bars: clear at the top of a screen (over a leather masthead or
        // the page), a blurred page-tone bar once content scrolls under it. Serif
        // titles in ink. The tab bar is left to the system (Liquid Glass on iOS 26).
        let serif = { (size: CGFloat, weight: UIFont.Weight) -> UIFont in
            let base = UIFont(name: "Source Serif 4", size: size) ?? .systemFont(ofSize: size)
            let desc = base.fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
            return UIFont(descriptor: desc, size: size)
        }
        let titles: (UINavigationBarAppearance) -> Void = { nav in
            nav.titleTextAttributes = [.foregroundColor: UIColor(Theme.ink), .font: serif(17, .semibold)]
            nav.largeTitleTextAttributes = [.foregroundColor: UIColor(Theme.ink), .font: serif(32, .bold)]
        }
        let scrolled = UINavigationBarAppearance()
        scrolled.configureWithDefaultBackground()
        scrolled.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        scrolled.backgroundColor = UIColor(Theme.page).withAlphaComponent(0.72)
        scrolled.shadowColor = UIColor(Theme.line)
        titles(scrolled)
        let edge = UINavigationBarAppearance()
        edge.configureWithTransparentBackground()
        titles(edge)
        UINavigationBar.appearance().standardAppearance = scrolled
        UINavigationBar.appearance().compactAppearance = scrolled
        UINavigationBar.appearance().scrollEdgeAppearance = edge

        // Segmented controls: the selection is a leather thumb (crimson by day, oxblood
        // by night) lettered in cream or gold, on the page's quiet track.
        let seg = UISegmentedControl.appearance()
        seg.selectedSegmentTintColor = UIColor(Color(light: 0x8e2424, dark: 0x4a1a1a))
        seg.backgroundColor = UIColor(Theme.tint)
        let inter = { (weight: UIFont.Weight) -> UIFont in
            let base = UIFont(name: "Inter", size: 14) ?? .systemFont(ofSize: 14)
            return UIFont(descriptor: base.fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]]), size: 14)
        }
        seg.setTitleTextAttributes([.foregroundColor: UIColor(Theme.inkSoft), .font: inter(.medium)], for: .normal)
        seg.setTitleTextAttributes([.foregroundColor: UIColor(Color(light: 0xf7eedb, dark: 0xddb954)),
                                    .font: inter(.semibold)], for: .selected)
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
