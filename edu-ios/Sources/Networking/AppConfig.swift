import Foundation

// Single source of truth for the backend base URL, shared by APIClient (which
// appends /api/mobile/v1) and by views that load site assets like category
// images from the site root (/categories/<slug>.png).
enum AppConfig {
    static let baseURL: String = {
        if let env = ProcessInfo.processInfo.environment["API_BASE_URL"], !env.isEmpty {
            return env
        }
        // Key off the environment, not the build config: the Simulator can reach the
        // Mac's dev server at localhost, but a physical device cannot — it needs the
        // deployed production API (works over any network, no LAN IP needed).
        #if targetEnvironment(simulator)
        return "http://localhost:3000" // Simulator -> Mac's `npm run dev`
        #else
        return "https://timpson-lyceum.vercel.app" // Physical device (+ Release) -> production
        #endif
    }()

    /// URL for a static asset served from the site root, e.g. "/categories/history.png".
    static func assetURL(_ path: String) -> URL? {
        URL(string: baseURL + path)
    }
}
