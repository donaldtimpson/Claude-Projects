import SwiftUI

// Players on a shared iPad. Each child has their own save — coins, laurels, levels, best scores,
// villa — so a younger sibling never inherits an older one's rank.
//
// The FIRST player keeps `UserDefaults.standard` (where every save lived before profiles existed),
// so nothing needs migrating: the child who was already playing simply becomes player one. Every
// later player gets their own suite. Device-wide settings (sound) stay in `.standard`.
//
// All game state goes through `LudusStore.defaults`; never read `UserDefaults.standard` for it.
//
// DEBUG only: LUDUS_DEMO_PLAYERS=n swaps the whole store (player list + every save) for a throwaway
// sandbox, wiped and seeded with n demo players at launch, so captures and tests never touch a real
// install's players. LUDUS_DEMO_BANK=n gives the sandbox's pre-profiles save a bank (a "child who was
// already playing"). LUDUS_SCREEN=players opens the picker as "Switch player" does.

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
    nonisolated static let firstID = "main"
    // Append only: profiles store indices.
    static let emblems = ["🦁", "🦅", "🐺", "🐬", "🦉", "🐎", "🐘", "🦊", "🐢", "🐝", "🐙", "🐉"]
    static let waxes: [UInt] = [0xb3262d, 0x2f6fb0, 0x3f8a4a, 0x7b3fa0, 0xc9822b, 0x2a8c8c, 0xa63a6a, 0x6b4a2e]
    static let maxNameLength = 12

    private static let listKey = "ludus_profiles"
    private static let currentKey = "ludus_current_profile"

    @Published private(set) var all: [LudusProfile] = []
    @Published private(set) var currentID: String = LudusProfiles.firstID
    /// Set to show the "Who's playing?" picker (launch with 2+ players, or "Switch player").
    @Published var showPicker = false
    /// The picker can't be closed without choosing: at launch with 2+ players, or after the current
    /// player was erased. Opening it via "Switch player" leaves this false (it gets a back button).
    @Published private(set) var mustPick = false

    private init() {
        #if DEBUG
        Self.seedDemo()
        #endif
        let d = Self.root
        if let data = d.data(forKey: Self.listKey),
           let list = try? JSONDecoder().decode([LudusProfile].self, from: data), !list.isEmpty {
            all = list
        }
        currentID = d.string(forKey: Self.currentKey) ?? Self.firstID
        if !all.contains(where: { $0.id == currentID }) { currentID = all.first?.id ?? Self.firstID }
        LudusStore.defaults = Self.defaults(for: currentID)
        // More than one child on this device: ask who's playing at every launch.
        showPicker = all.count > 1
        mustPick = showPicker
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SCREEN"] == "players" { showPicker = true; mustPick = false }
        #endif
    }

    var current: LudusProfile? { all.first { $0.id == currentID } }

    /// Where the player list lives — and player one's save. `.standard`, except in a DEBUG sandbox.
    nonisolated(unsafe) static let root: UserDefaults = {
        #if DEBUG
        if sandboxed, let d = UserDefaults(suiteName: "ludus.demo") { return d }
        #endif
        return .standard
    }()

    #if DEBUG
    nonisolated static let sandboxed = ProcessInfo.processInfo.environment["LUDUS_DEMO_PLAYERS"] != nil
    #else
    nonisolated static let sandboxed = false
    #endif

    nonisolated static func suiteName(for id: String) -> String {
        (sandboxed ? "ludus.demo." : "") + "ludus.profile.\(id)"
    }

    /// The save for `id`.
    nonisolated static func defaults(for id: String) -> UserDefaults {
        id == firstID ? root : (UserDefaults(suiteName: suiteName(for: id)) ?? root)
    }

    func select(_ id: String) {
        guard all.contains(where: { $0.id == id }) else { return }
        setCurrent(id)
        mustPick = false
        showPicker = false
    }

    /// Adds a player. The very first one named takes over the existing (pre-profiles) save.
    @discardableResult
    func add(name: String, emblem: Int, wax: Int) -> LudusProfile {
        let id = all.isEmpty ? Self.firstID : UUID().uuidString
        let p = LudusProfile(id: id, name: Self.clean(name), emblem: emblem, wax: wax)
        all.append(p); save()
        // Player one IS whoever was playing: make it current (it already is, by save).
        if all.count == 1 { setCurrent(id) }
        return p
    }

    func update(_ p: LudusProfile) {
        guard let i = all.firstIndex(where: { $0.id == p.id }) else { return }
        var p = p
        p.name = Self.clean(p.name)
        all[i] = p; save()
    }

    /// Removes a player and erases their save (never the last player). Erasing the current player
    /// leaves the picker up with no way out but choosing someone.
    func remove(_ id: String) {
        guard all.count > 1, let i = all.firstIndex(where: { $0.id == id }) else { return }
        let d = Self.defaults(for: id)
        for k in d.dictionaryRepresentation().keys where k.hasPrefix("ludus_") && k != Self.listKey
            && k != Self.currentKey && k != LudusSettings.soundKey { d.removeObject(forKey: k) }
        if id != Self.firstID { UserDefaults.standard.removePersistentDomain(forName: Self.suiteName(for: id)) }
        all.remove(at: i); save()
        if currentID == id {
            setCurrent(all[0].id)
            mustPick = true
        }
    }

    /// Trimmed, single-spaced, at most `maxNameLength` characters.
    static func clean(_ s: String) -> String {
        String(s.split(whereSeparator: \.isWhitespace).joined(separator: " ").prefix(maxNameLength))
    }

    private func setCurrent(_ id: String) {
        currentID = id
        Self.root.set(id, forKey: Self.currentKey)
        LudusStore.defaults = Self.defaults(for: id)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(all) { Self.root.set(data, forKey: Self.listKey) }
    }

    #if DEBUG
    /// Wipes the sandbox (its list, player one's save and every listed player's suite) and seeds it.
    private static func seedDemo() {
        let env = ProcessInfo.processInfo.environment
        guard sandboxed, let n = Int(env["LUDUS_DEMO_PLAYERS"] ?? "") else { return }
        let d = root
        if let data = d.data(forKey: listKey), let old = try? JSONDecoder().decode([LudusProfile].self, from: data) {
            for p in old where p.id != firstID { UserDefaults.standard.removePersistentDomain(forName: suiteName(for: p.id)) }
        }
        UserDefaults.standard.removePersistentDomain(forName: "ludus.demo")
        for k in d.dictionaryRepresentation().keys where k.hasPrefix("ludus_") { d.removeObject(forKey: k) }
        if let bank = Int(env["LUDUS_DEMO_BANK"] ?? "") { d.set(bank, forKey: LudusStore.denariiKey) }
        let names = ["Marcus", "Julia", "Tiberius", "Livia", "Octavia", "Gaius", "Claudia", "Felix"]
        let demo = (0..<min(n, names.count)).map { i in
            LudusProfile(id: i == 0 ? firstID : "demo\(i)", name: names[i],
                         emblem: (i * 5) % emblems.count, wax: i % waxes.count)
        }
        if !demo.isEmpty, let data = try? JSONEncoder().encode(demo) { d.set(data, forKey: listKey) }
    }

    /// Proves the saves are separate. Runs only in the sandbox, on a fresh one (LUDUS_DEMO_PLAYERS=0)
    /// whose pre-profiles save holds LUDUS_DEMO_BANK. Returns the failures (empty = pass).
    func selfTest() -> [String] {
        var fails: [String] = []
        func check(_ ok: Bool, _ what: String) { if !ok { fails.append(what) } }
        guard Self.sandboxed, all.isEmpty else { return ["needs LUDUS_DEMO_PLAYERS=0"] }
        let preBank = LudusStore.denarii
        check(preBank > 0, "pre-existing bank seeded (LUDUS_DEMO_BANK)")

        let one = add(name: "  Prima   Ludens ", emblem: 0, wax: 0)
        check(one.id == Self.firstID, "player one takes the pre-profiles save")
        check(one.name == "Prima Ludens", "name cleaned")
        check(LudusStore.denarii == preBank, "player one still has the pre-existing bank")
        LudusProgress.record(level: 3, for: "ballista")
        LudusStore.defaults.set(["test-item"], forKey: LudusEconomy.ownedKey)

        let two = add(name: "Secunda", emblem: 1, wax: 1)
        select(two.id)
        check(LudusStore.defaults !== Self.root, "player two has a separate store")
        check(LudusStore.denarii == 0, "player two starts with an empty bank (got \(LudusStore.denarii))")
        check(LudusProgress.maxLevel("ballista") == 0 && LudusEconomy.owned.isEmpty, "player two starts fresh")
        LudusStore.award(50)
        check(LudusStore.denarii == 50, "award lands in player two's bank")

        select(one.id)
        check(LudusStore.denarii == preBank, "player one's bank untouched by player two's award")
        check(LudusProgress.maxLevel("ballista") == 3, "player one's level survives")
        LudusStore.award(5)
        select(two.id)
        check(LudusStore.denarii == 50, "player two's bank untouched by player one's award")

        remove(two.id)
        check(all.count == 1 && currentID == one.id, "erasing the current player falls back to player one")
        check(UserDefaults(suiteName: Self.suiteName(for: two.id))?.integer(forKey: LudusStore.denariiKey) == 0,
              "erased player's save is gone")
        check(LudusStore.denarii == preBank + 5, "player one's save survives erasing player two")
        remove(one.id)
        check(all.count == 1, "the last player can't be erased")
        select(one.id)
        return fails
    }
    #endif
}
