import SwiftUI

// The one place the app asks for an account, used wherever a feature genuinely needs
// an identity. The app itself is NOT gated — courses, lectures, notes, quizzes, and
// drills all work signed out — so this only ever stands in front of the things that
// are personal by nature (your review queue, your grades, your saved progress).
//
// Always says what signing in buys, never just "sign in required".
struct SignInGate: View {
    let icon: String
    let title: String
    let message: String
    /// Passed to AuthView so the ask is tied to what the student was doing.
    var reason: String?

    @State private var showAuth = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Masthead(overlap: 40) {
                    VStack(spacing: 10) {
                        Image(systemName: icon)
                            .font(.system(size: 38))
                            .foregroundStyle(Theme.gilt)
                        Text(title)
                            .font(.serif(28, .bold, relativeTo: .title)).foregroundStyle(Theme.onLeather)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
                VStack(spacing: 14) {
                    Text(message)
                        .font(.serif(16.5)).foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    PrimaryButton(title: "Sign in or create an account") { showAuth = true }
                }
                .lyceumCard(padding: 18)
                .shadow(color: Color(hex: 0x2a0a0a).opacity(0.14), radius: 14, y: 6)
                .padding(.top, -40)
                .padding(.horizontal)
                .frame(maxWidth: 520)

                Text("Everything else in the app works without one.")
                    .font(.ui(13)).foregroundStyle(Theme.inkSoft)
                    .padding(.top, 14)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Theme.page)
        .mastheadChrome(title, crest: true)
        .sheet(isPresented: $showAuth) {
            AuthSheet(reason: reason)
        }
    }
}

// AuthView in a sheet, with a way out. Used by SignInGate and by the inline "save this"
// prompts on the quiz and drill result screens.
struct AuthSheet: View {
    var reason: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AuthView(reason: reason) { dismiss() }
                .mastheadChrome("Account", leading: ChromeAction(systemImage: "xmark", label: "Not now") { dismiss() })
        }
    }
}

// A compact inline prompt for result screens — "your score isn't saved, here's how to
// keep it" — replacing the dead-end footnotes that stated the same thing with no way
// to act on it.
struct SignInPrompt: View {
    let message: String
    var reason: String?
    /// "…save it" fits a result screen with a score on it; elsewhere there's nothing
    /// to save and the phrase reads as a bug.
    var actionTitle: String = "Sign in to save it"
    @State private var showAuth = false

    var body: some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.ui(14)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            Button(actionTitle) { showAuth = true }
                .font(.ui(15, .semibold))
                .tint(Theme.link)
        }
        .sheet(isPresented: $showAuth) { AuthSheet(reason: reason) }
    }
}
