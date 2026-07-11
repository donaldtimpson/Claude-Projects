import Foundation

struct APIError: LocalizedError {
    let status: Int
    let message: String
    var errorDescription: String? { message }
}

// Talks to edu-web's app/api/mobile/v1/* API. Injects the Bearer token and
// transparently refreshes it (single-flight) on a 401.
//
// Base URL: set the API_BASE_URL environment variable in the Xcode scheme to
// your Mac's LAN IP (e.g. http://192.168.40.189:3000) for local dev; defaults
// to production.
actor APIClient {
    static let shared = APIClient()

    private let baseURL: String
    private var refreshTask: Task<Bool, Never>?

    init() {
        baseURL = AppConfig.baseURL
    }

    private var v1: String { "\(baseURL)/api/mobile/v1" }

    private struct ErrBody: Decodable { let error: String? }

    func get<T: Decodable>(_ path: String, auth: Bool = true) async throws -> T {
        try await request(path, method: "GET", body: Optional<Int>.none, auth: auth)
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B, auth: Bool = true) async throws -> T {
        try await request(path, method: "POST", body: body, auth: auth)
    }

    func delete<T: Decodable>(_ path: String, auth: Bool = true) async throws -> T {
        try await request(path, method: "DELETE", body: Optional<Int>.none, auth: auth)
    }

    // Replays an already-encoded JSON body (used by the offline write queue).
    func postRaw(_ path: String, jsonBody: Data, retry: Bool = true) async throws {
        guard let url = URL(string: v1 + path) else { throw APIError(status: 0, message: "Bad URL") }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = jsonBody
        if let token = TokenStore.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError(status: 0, message: "No response") }
        if http.statusCode == 401, retry, await refreshAccess() {
            return try await postRaw(path, jsonBody: jsonBody, retry: false)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError(status: http.statusCode, message: errorMessage(data, http.statusCode))
        }
    }

    private func request<T: Decodable, B: Encodable>(
        _ path: String, method: String, body: B?, auth: Bool, retry: Bool = true
    ) async throws -> T {
        guard let url = URL(string: v1 + path) else { throw APIError(status: 0, message: "Bad URL") }
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(body)
        }
        if auth, let token = TokenStore.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError(status: 0, message: "No response") }

        if http.statusCode == 401, auth, retry, await refreshAccess() {
            return try await request(path, method: method, body: body, auth: auth, retry: false)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError(status: http.statusCode, message: errorMessage(data, http.statusCode))
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func errorMessage(_ data: Data, _ status: Int) -> String {
        (try? JSONDecoder().decode(ErrBody.self, from: data))?.error ?? "Request failed (\(status))"
    }

    private func refreshAccess() async -> Bool {
        if let refreshTask { return await refreshTask.value }
        let task = Task<Bool, Never> {
            guard let rt = TokenStore.refreshToken, let url = URL(string: v1 + "/auth/refresh") else {
                return false
            }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try? JSONEncoder().encode(["refreshToken": rt])
            guard let (data, resp) = try? await URLSession.shared.data(for: req),
                  let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let pair = try? JSONDecoder().decode(TokenPair.self, from: data)
            else {
                TokenStore.clear()
                return false
            }
            TokenStore.save(access: pair.accessToken, refresh: pair.refreshToken)
            return true
        }
        refreshTask = task
        let result = await task.value
        refreshTask = nil
        return result
    }
}
