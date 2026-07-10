import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        if auth.loading {
            SplashView()
        } else if auth.user == nil {
            AuthView()
        } else {
            TabView {
                NavigationStack { LearnView() }
                    .tabItem { Label("Learn", systemImage: "books.vertical") }
                NavigationStack { ReviewView() }
                    .tabItem { Label("Review", systemImage: "square.stack.3d.up") }
                NavigationStack { DrillsView() }
                    .tabItem { Label("Drills", systemImage: "figure.strengthtraining.traditional") }
                NavigationStack { ProfileView() }
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("The Lyceum")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(Theme.crimson)
            ProgressView().tint(Theme.crimson)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.parchment)
    }
}
