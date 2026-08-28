import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        if auth.loading {
            SplashView()
        } else {
            // The app opens straight into the catalog, signed in or not. Everything
            // that doesn't need an identity — browsing courses, lectures, notes,
            // quizzes, drills — works signed out, and only the tabs and actions that
            // are inherently personal ask for an account, at the moment they need it.
            // App Review rejected the old behaviour (the whole app behind a login)
            // under Guideline 5.1.1(i); the website has always worked this way.
            //
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
                // "Progress", not "Profile": this is the same screen the web calls
                // My Progress, and showing one name on each platform for one set of
                // data is just confusing. The tab label is the short form because
                // "My Progress" truncates in a four-item tab bar; the screen title
                // inside matches the web exactly.
                Tab("Progress", systemImage: "chart.line.uptrend.xyaxis") {
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
            Text("The Timpson\nLyceum")
                .font(.display(38))
                .kerning(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.gold300)
            ProgressView().tint(Theme.gold300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.parchment)
    }
}
