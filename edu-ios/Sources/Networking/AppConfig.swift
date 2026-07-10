import Foundation

// Single source of truth for the backend base URL, shared by APIClient (which
// appends /api/mobile/v1) and by views that load site assets like category
// images from the site root (/categories/<slug>.png).
enum AppConfig {
    static let baseURL: String = {
        if let env = ProcessInfo.processInfo.environment["API_BASE_URL"], !env.isEmpty {
            return env
        }
        #if DEBUG
        return "http://localhost:3000" // Simulator -> Mac's `npm run dev`
        #else
        return "https://timpson-lyceum.vercel.app"
        #endif
    }()

    /// URL for a static asset served from the site root, e.g. "/categories/history.png".
    static func assetURL(_ path: String) -> URL? {
        URL(string: baseURL + path)
    }
}
