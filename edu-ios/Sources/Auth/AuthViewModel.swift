import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var user: AuthUser?
    @Published var loading = true

    var isSignedIn: Bool { user != nil }

    func bootstrap() async {
        #if DEBUG
        // The signed-out UI tests need a deterministic anonymous start. A simulator's
        // Keychain survives uninstalling the app, so a token left by an earlier manual
        // sign-in would otherwise quietly sign the test in and it would assert against
        // the wrong state. DEBUG-only; never present in a shipped build.
        if ProcessInfo.processInfo.environment["UI_TEST_ANONYMOUS"] == "1" {
            TokenStore.clear()
            user = nil
            loading = false
            return
        }
        #endif
        guard TokenStore.accessToken != nil else {
            user = nil
            loading = false
            return
        }
        do {
            let me: MeResponse = try await APIClient.shared.get("/me")
            user = me.user
        } catch {
            user = nil
        }
        loading = false
    }

    func login(email: String, password: String) async throws {
        let res: AuthResponse = try await APIClient.shared.post(
            "/auth/login",
            body: CredentialsBody(email: email, password: password),
            auth: false
        )
        TokenStore.save(access: res.accessToken, refresh: res.refreshToken)
        user = res.user
    }

    func register(name: String, email: String, password: String) async throws {
        let res: AuthResponse = try await APIClient.shared.post(
            "/auth/register",
            body: RegisterBody(name: name, email: email, password: password),
            auth: false
        )
        TokenStore.save(access: res.accessToken, refresh: res.refreshToken)
        user = res.user
    }

    func loginWithApple(identityToken: String, givenName: String?, familyName: String?) async throws {
        let name = (givenName != nil || familyName != nil)
            ? AppleName(givenName: givenName, familyName: familyName) : nil
        let res: AuthResponse = try await APIClient.shared.post(
            "/auth/apple",
            body: AppleSignInBody(identityToken: identityToken, fullName: name),
            auth: false
        )
        TokenStore.save(access: res.accessToken, refresh: res.refreshToken)
        user = res.user
    }

    // Permanently delete the account, server-side and on this device. App Store
    // Review Guideline 5.1.1(v) requires this to be reachable from inside the app
    // (Profile -> Delete Account), and to actually delete rather than deactivate.
    // The password is re-sent so a stolen access token alone can't wipe an account.
    func deleteAccount(password: String) async throws {
        struct Deleted: Decodable { let deleted: Bool }
        let _: Deleted = try await APIClient.shared.delete(
            "/me", body: PasswordBody(password: password)
        )
        purgeLocalData()
        TokenStore.clear()
        user = nil
    }

    // On-device state outlives the server row, and every local store is keyed by
    // user id — so without this the next account signed in on this device would
    // inherit the deleted student's mastery boxes, ✦ marks, and high scores.
    private func purgeLocalData() {
        WriteQueueManager.shared.purgeAll()
        LessonProgress.shared.purgeAll()
        DrillMastery.shared.purgeAll()
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("rapidbest_") {
            defaults.removeObject(forKey: key)
        }
    }

    func logout() async {
        if let rt = TokenStore.refreshToken {
            struct OK: Codable { let ok: Bool? }
            let _: OK? = try? await APIClient.shared.post(
                "/auth/logout", body: ["refreshToken": rt], auth: false
            )
        }
        TokenStore.clear()
        user = nil
    }
}
