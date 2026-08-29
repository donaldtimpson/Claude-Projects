package com.timpsonlyceum.lyceum.net

/**
 * Single source of truth for the backend base URL, shared by [ApiClient] (which
 * appends /api/mobile/v1) and by screens that load site assets from the site
 * root (/categories/<slug>.png).
 *
 * The iOS app keys off the simulator and points at the Mac's dev server; here we
 * default to production instead, because it works from an emulator, a physical
 * device, and CI alike with no LAN address to keep in sync. Point [override] at
 * http://10.0.2.2:3000 to reach `npm run dev` on the host from an emulator.
 */
object AppConfig {
    var override: String? = null

    val baseUrl: String
        get() = override ?: "https://timpson-lyceum.vercel.app"

    /** URL for a static asset served from the site root, e.g. "/categories/history.png". */
    fun assetUrl(path: String): String = baseUrl + path
}
