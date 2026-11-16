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
        // A simulator build made with -DLIVE_API talks to production too, for a
        // hands-on build that doesn't need the dev server running.
        #if targetEnvironment(simulator) && !LIVE_API
        return "http://localhost:3000" // Simulator -> Mac's `npm run dev`
        #else
        return "https://timpson-lyceum.vercel.app" // Physical device (+ Release) -> production
        #endif
    }()

    /// The production site's origin. Web content (the YouTube embed, KaTeX) loads
    /// against it even in development, because YouTube checks the embedding origin.
    static let siteOrigin = "https://timpson-lyceum.vercel.app"

    /// URL for a static asset served from the site root, e.g. "/categories/history.png".
    static func assetURL(_ path: String) -> URL? {
        URL(string: baseURL + path)
    }
}
