import AuthenticationServices
import SwiftUI

// The app's entry screen when signed out (the whole app is gated behind auth).
// On success it sets auth.user, and RootView swaps in the TabView automatically.
struct AuthView: View {
    @EnvironmentObject private var auth: AuthViewModel

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
                VStack(spacing: 8) {
                    Text("The Timpson Lyceum")
                        .font(.display(38))
                        .kerning(2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.gold300)
                    Text(mode == .signIn ? "Sign in to continue" : "Create your account")
                        .font(.serif(17))
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.top, 48)

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
            // Success: auth.user is now set; RootView swaps to the TabView.
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
