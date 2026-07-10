import SwiftUI

struct RootView: View {
    var body: some View {
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
