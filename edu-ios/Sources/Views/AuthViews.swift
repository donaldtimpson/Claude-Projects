import AuthenticationServices
import SwiftUI

// Sign in / create an account. NOT a gate: the app opens straight into the catalog
// and everything that doesn't need an identity works signed out (Guideline 5.1.1(i),
// and the website behaves the same way). This appears as the Profile tab's body while
// signed out, and as a sheet from the places where signing in actually buys something —
// saving a quiz score, keeping drill progress, opening Review.
struct AuthView: View {
    @EnvironmentObject private var auth: AuthViewModel

    /// Shown above the form when raised from a specific action, so the ask is tied to
    /// what the student was doing rather than being a generic wall.
    var reason: String?
    /// Set when presented as a sheet, to dismiss on success and offer a way out.
    var onDismiss: (() -> Void)?

    // Sign in with Apple needs a paid Developer account + entitlement; hidden so
    // the app builds to a device with a free Apple ID. Flip to true when the
    // entitlement is re-enabled in project.yml.
    private let appleSignInAvailable = false

    @State private var mode: Mode = .signIn
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var busy = false

    enum Mode { case signIn, register }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // One line above the form, not four. This used to be the app's entry
                // screen, where a full wordmark and a "Sign in to continue" line earned
                // their space; it's a tab inside the app now, so the reader already
                // knows where they are and isn't being stopped from doing anything.
                // The nav bar carries the title, so all that's left to say is what an
                // account gets you — the reason from wherever this was raised, or the
                // general case.
                Text(reason ?? "Keep your progress, quiz scores, streak, and badges across your devices.")
                    .font(.serif(16))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.top, 24)

                VStack(spacing: 12) {
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
                    Button(mode == .signIn ? "New here? Create an account" : "I already have an account") {
                        withAnimation { mode = mode == .signIn ? .register : .signIn }
                        error = nil
                    }
                    .font(.callout)
                    .tint(Theme.crimson)

                    if appleSignInAvailable {
                        HStack {
                            Rectangle().fill(Theme.line).frame(height: 1)
                            Text("or").font(.footnote).foregroundStyle(Theme.inkSoft)
                            Rectangle().fill(Theme.line).frame(height: 1)
                        }
                        .padding(.vertical, 4)

                        SignInWithAppleButton(.continue) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handleApple(result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .disabled(busy)
                    }
                }

                Text("Uses the same account as the website.")
                    .font(.footnote).foregroundStyle(Theme.inkSoft)
            }
            .padding()
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.parchment)
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
            // Success: auth.user is set. As the Profile tab's body the view simply
            // swaps to the profile; as a sheet it has to close itself.
            onDismiss?()
        } catch {
            self.error = error.localizedDescription
        }
        busy = false
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else {
                error = "Apple sign-in didn't return a token. Please try again."
                return
            }
            let fullName = credential.fullName
            Task {
                busy = true
                error = nil
                do {
                    try await auth.loginWithApple(
                        identityToken: token,
                        givenName: fullName?.givenName,
                        familyName: fullName?.familyName
                    )
                    onDismiss?()
                } catch {
                    self.error = error.localizedDescription
                }
                busy = false
            }
        case .failure(let err):
            // Swallow the user-cancelled case; surface real errors.
            if (err as? ASAuthorizationError)?.code != .canceled {
                error = err.localizedDescription
            }
        }
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
