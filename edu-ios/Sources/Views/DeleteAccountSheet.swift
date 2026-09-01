import SwiftUI

// Permanent account deletion, initiated in the app as App Store Review Guideline
// 5.1.1(v) requires.
//
// One gate: the student types DELETE. There used to be a password field too, and
// App Review rejected 1.0 (3) over it — 5.1.1(v) says the flow must not require
// the user to "add a password to complete account deletion", and a reviewer reads
// a password field on this screen as that barrier whether or not the account
// already has one. The typed phrase stays, because the guideline explicitly
// allows confirmation steps to prevent an accident, and this is the one screen in
// the app with no undo.
struct DeleteAccountSheet: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var confirmation = ""
    @State private var error: String?
    @State private var busy = false

    private static let phrase = "DELETE"

    private var canSubmit: Bool {
        confirmation.trimmingCharacters(in: .whitespaces).uppercased() == Self.phrase
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("This cannot be undone.")
                        .font(.display(22))
                        .foregroundStyle(Theme.danger)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Deleting your account permanently removes:")
                            .font(.serif(16))
                            .foregroundStyle(Theme.ink)
                        ForEach(Self.losses, id: \.self) { item in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("•").foregroundStyle(Theme.inkSoft)
                                Text(item).font(.serif(15)).foregroundStyle(Theme.inkSoft)
                            }
                        }
                    }
                    .lyceumCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Type \(Self.phrase) to confirm")
                            .font(.caption).foregroundStyle(Theme.inkSoft)
                        field(Self.phrase, text: $confirmation)
                    }

                    if let error {
                        Text(error).font(.callout).foregroundStyle(Theme.danger)
                    }

                    PrimaryButton(title: "Delete my account", enabled: canSubmit, loading: busy) {
                        Task { await submit() }
                    }
                }
                .padding()
            }
            .background(Theme.parchment)
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.tint(Theme.gold300)
                }
            }
        }
    }

    private static let losses = [
        "Your progress through every lecture",
        "Your quiz and drill history, and your high scores",
        "Your review queue, streak, and badges",
        "Your place in the Hall of Scholars",
        "Any comments you have posted",
        "Your class enrollment and homework submissions",
    ]

    private func submit() async {
        busy = true
        error = nil
        do {
            // On success the auth model clears the session, so RootView swaps back to
            // the sign-in screen and this sheet goes away with it — no dismiss needed.
            try await auth.deleteAccount()
        } catch {
            self.error = error.localizedDescription
        }
        busy = false
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
        .padding()
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
