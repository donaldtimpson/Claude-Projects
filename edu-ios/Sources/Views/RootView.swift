import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var router = Router()

    var body: some View {
        if auth.loading {
            SplashView()
        } else {
            // The app opens straight into the catalog, signed in or not. Everything
            // that doesn't need an identity (browsing, lectures, notes, quizzes,
            // drills) works signed out; only inherently personal tabs and actions
            // ask for an account, when they need it (App Review, Guideline 5.1.1(i)).
            //
            // A bottom tab bar on iPhone and a sidebar on iPad, from one TabView.
            TabView(selection: $router.tab) {
                // "Courses" and "Progress" match the web nav's names.
                Tab("Courses", systemImage: "books.vertical", value: AppTab.courses) {
                    NavigationStack(path: $router.courses) { LearnView().lyceumDestinations() }
                }
                Tab("Review", systemImage: "square.stack.3d.up", value: AppTab.review) {
                    NavigationStack(path: $router.review) { ReviewView().lyceumDestinations() }
                }
                Tab("Drills", systemImage: "figure.strengthtraining.traditional", value: AppTab.drills) {
                    NavigationStack(path: $router.drills) { DrillsView().lyceumDestinations() }
                }
                Tab("Progress", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.progress) {
                    NavigationStack(path: $router.progress) { ProfileView().lyceumDestinations() }
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            .overlay(alignment: .top) { CelebrationToast() }
            .environmentObject(router)
            .onOpenURL { router.open($0) }
            #if DEBUG && targetEnvironment(simulator)
            // Screenshot runs open a screen directly (simctl openurl asks first).
            .task {
                if let s = ProcessInfo.processInfo.environment["DEBUG_OPEN_URL"], let url = URL(string: s) {
                    router.open(url)
                }
            }
            #endif
        }
    }
}

struct SplashView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.columns.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.gilt)
            Text("The Timpson\nLyceum")
                .font(.display(36))
                .kerning(1.5)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.onLeather)
            HStack(spacing: 10) {
                Rectangle().fill(Theme.giltBar).frame(width: 40, height: 1)
                GiltDiamond(size: 6)
                Rectangle().fill(Theme.giltBar).frame(width: 40, height: 1)
            }
            ProgressView().tint(Theme.giltText).padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { LeatherBackground().ignoresSafeArea() }
    }
}
