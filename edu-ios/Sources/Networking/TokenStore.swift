import Foundation
import Security

// Access + refresh tokens live in the iOS Keychain (never UserDefaults).
enum TokenStore {
    private static let service = "com.timpsonlyceum.Lyceum"
    private static let accessKey = "accessToken"
    private static let refreshKey = "refreshToken"

    static var accessToken: String? { read(accessKey) }
    static var refreshToken: String? { read(refreshKey) }

    static func save(access: String, refresh: String) {
        write(accessKey, access)
        write(refreshKey, refresh)
    }

    static func clear() {
        delete(accessKey)
        delete(refreshKey)
    }

    private static func baseQuery(_ key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }

    private static func write(_ key: String, _ value: String) {
        delete(key)
        var attrs = baseQuery(key)
        attrs[kSecValueData as String] = Data(value.utf8)
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attrs as CFDictionary, nil)
    }

    private static func read(_ key: String) -> String? {
        var query = baseQuery(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let str = String(data: data, encoding: .utf8)
        else { return nil }
        return str
    }

    private static func delete(_ key: String) {
        SecItemDelete(baseQuery(key) as CFDictionary)
    }
}
