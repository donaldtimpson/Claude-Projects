import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var user: AuthUser?
    @Published var loading = true

    var isSignedIn: Bool { user != nil }

    func bootstrap() async {
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
