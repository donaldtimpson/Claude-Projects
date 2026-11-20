import SwiftUI

// Players on a shared iPad. Each child has their own save — coins, laurels, levels, best scores,
// villa — so a younger sibling never inherits an older one's rank.
//
// The FIRST player keeps `UserDefaults.standard` (where every save lived before profiles existed),
// so nothing needs migrating: the child who was already playing simply becomes player one. Every
// later player gets their own suite. Device-wide settings (sound) stay in `.standard`.
//
// All game state goes through `LudusStore.defaults`; never read `UserDefaults.standard` for it.

struct LudusProfile: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var emblem: Int          // index into `LudusProfiles.emblems`
    var wax: Int             // index into `LudusProfiles.waxes`
}

@MainActor
final class LudusProfiles: ObservableObject {
    static let shared = LudusProfiles()

    /// The id whose save is `UserDefaults.standard` (the pre-profiles player).
    static let firstID = "main"
    static let emblems = ["🦁", "🦅", "🐺", "🐬", "🦉", "🐎", "🐘", "🦊"]
    static let waxes: [UInt] = [0xb3262d, 0x2f6fb0, 0x3f8a4a, 0x7b3fa0, 0xc9822b, 0x2a8c8c]

    private static let listKey = "ludus_profiles"
    private static let currentKey = "ludus_current_profile"

    @Published private(set) var all: [LudusProfile] = []
    @Published private(set) var currentID: String = LudusProfiles.firstID
    /// Set to show the "Who's playing?" picker (launch with 2+ players, or "Switch player").
    @Published var showPicker = false

    private init() {
        let d = UserDefaults.standard
        if let data = d.data(forKey: Self.listKey),
           let list = try? JSONDecoder().decode([LudusProfile].self, from: data), !list.isEmpty {
            all = list
        }
        currentID = d.string(forKey: Self.currentKey) ?? Self.firstID
        if !all.contains(where: { $0.id == currentID }) { currentID = all.first?.id ?? Self.firstID }
        // More than one child on this device: ask who's playing at every launch.
        showPicker = all.count > 1
    }

    var current: LudusProfile? { all.first { $0.id == currentID } }

    /// The save for `id`.
    nonisolated static func defaults(for id: String) -> UserDefaults {
        id == firstID ? .standard : (UserDefaults(suiteName: "ludus.profile.\(id)") ?? .standard)
    }

    func select(_ id: String) {
        guard all.contains(where: { $0.id == id }) else { return }
        currentID = id
        UserDefaults.standard.set(id, forKey: Self.currentKey)
        LudusStore.defaults = Self.defaults(for: id)
        showPicker = false
    }

    /// Adds a player. The very first one named takes over the existing (pre-profiles) save.
    @discardableResult
    func add(name: String, emblem: Int, wax: Int) -> LudusProfile {
        let id = all.isEmpty ? Self.firstID : UUID().uuidString
        let p = LudusProfile(id: id, name: name, emblem: emblem, wax: wax)
        all.append(p); save()
        return p
    }

    func update(_ p: LudusProfile) {
        guard let i = all.firstIndex(where: { $0.id == p.id }) else { return }
        all[i] = p; save()
    }

    /// Removes a player and erases their save (never the last player).
    func remove(_ id: String) {
        guard all.count > 1, let i = all.firstIndex(where: { $0.id == id }) else { return }
        let d = Self.defaults(for: id)
        for k in d.dictionaryRepresentation().keys where k.hasPrefix("ludus_") && k != Self.listKey
            && k != Self.currentKey && k != LudusSettings.soundKey { d.removeObject(forKey: k) }
        all.remove(at: i); save()
        if currentID == id { select(all[0].id) }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(all) { UserDefaults.standard.set(data, forKey: Self.listKey) }
    }
}
