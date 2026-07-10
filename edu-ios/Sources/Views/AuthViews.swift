import SwiftUI

// Shown on personal tabs (Review, Profile) when signed out.
struct AuthGate: View {
    let message: String
    @State private var showAuth = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Members only").font(.title.weight(.bold)).foregroundStyle(Theme.crimson)
            Text(message).multilineTextAlignment(.center).foregroundStyle(Theme.ink)
            PrimaryButton(title: "Sign in") { showAuth = true }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.parchment)
        .sheet(isPresented: $showAuth) { AuthView() }
    }
}

struct AuthView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode = .signIn
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var busy = false

    enum Mode { case signIn, register }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if mode == .register {
                        field("Name", text: $name)
                    }
                    field("Email", text: $email, keyboard: .emailAddress)
                    field("Password", text: $password, secure: true)

                    if let error {
                        Text(error).foregroundStyle(Theme.danger).font(.callout)
                    }

                    PrimaryButton(title: mode == .signIn ? "Sign in" : "Create account",
                                  enabled: canSubmit, loading: busy) {
                        Task { await submit() }
                    }
                    Button(mode == .signIn ? "Create an account instead" : "I already have an account") {
                        withAnimation { mode = mode == .signIn ? .register : .signIn }
                        error = nil
                    }
                    .font(.callout)
                    .tint(Theme.crimson)

                    Text("Same account as the website.")
                        .font(.footnote).foregroundStyle(Theme.inkSoft)
                }
                .padding()
            }
            .background(Theme.parchment)
            .navigationTitle(mode == .signIn ? "Welcome back" : "Create account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }

    private var canSubmit: Bool {
        !email.isEmpty && (mode == .signIn ? !password.isEmpty : (!name.isEmpty && password.count >= 8))
    }

    private func submit() async {
        busy = true
        error = nil
        do {
            if mode == .signIn {
                try await auth.login(email: email.trimmingCharacters(in: .whitespaces), password: password)
            } else {
                try await auth.register(name: name.trimmingCharacters(in: .whitespaces),
                                        email: email.trimmingCharacters(in: .whitespaces),
                                        password: password)
            }
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        busy = false
    }

    @ViewBuilder
    private func field(_ placeholder: String, text: Binding<String>,
                       keyboard: UIKeyboardType = .default, secure: Bool = false) -> some View {
        Group {
            if secure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding()
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
