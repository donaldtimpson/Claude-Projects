import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        if auth.loading {
            SplashView()
        } else if auth.user == nil {
            AuthView()
        } else {
            // A bottom tab bar on iPhone and an expandable sidebar on iPad, from
            // one TabView — scales cleanly as we add destinations (search,
            // leaderboard, course map, settings…). See .sidebarAdaptable.
            TabView {
                Tab("Learn", systemImage: "books.vertical") {
                    NavigationStack { LearnView() }
                }
                Tab("Review", systemImage: "square.stack.3d.up") {
                    NavigationStack { ReviewView() }
                }
                Tab("Drills", systemImage: "figure.strengthtraining.traditional") {
                    NavigationStack { DrillsView() }
                }
                Tab("Profile", systemImage: "person.crop.circle") {
                    NavigationStack { ProfileView() }
                }
            }
            .tabViewStyle(.sidebarAdaptable)
        }
    }
}

struct SplashView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("The Lyceum")
                .font(.display(38))
                .kerning(2)
                .foregroundStyle(Theme.gold300)
            ProgressView().tint(Theme.gold300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.parchment)
    }
}
