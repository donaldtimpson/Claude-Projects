import SwiftUI

// Several children, one phone. No password, no email, nothing to remember: a
// three-year-old signs in by pointing at their own face. That is the only
// authentication a pre-reader can perform, and it is all this needs — the app
// stores nothing worth protecting and sends nothing anywhere.
struct Profile: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var face: String            // an emoji the child picks and recognises
    var colour: UInt            // their colour, so the picker is readable pre-literacy
    /// The theme this child last chose. Worlds are earned per child (see
    /// Progress.worlds), so the place they play in should be theirs too — switch to
    /// their card and their world comes back with it. Optional so profiles saved
    /// before this existed simply decode as "no choice yet" (→ classroom).
    var world: String?
}

@Observable
final class Profiles {
    private(set) var all: [Profile] = []
    private(set) var currentID: UUID?

    var current: Profile? { all.first { $0.id == currentID } }

    // A wide, cheerful set — picking a face is half the fun, so give real choice.
    static let faces = ["🦊","🐻","🐼","🐨","🦁","🐯","🐸","🐵","🐰","🐶","🐱","🦄",
                        "🐴","🐮","🐷","🐧","🐥","🦉","🐢","🐝","🦋","🐬","🐙","🦖"]
    static let colours: [UInt] = [0xE0724E, 0x4E8FBF, 0x6FA368, 0xC77CB0,
                                  0xC98A3E, 0x7A5EA8, 0x3E8FA8, 0xD9646E,
                                  0x4CA6A0, 0x8E7CC3, 0x5B8C5A, 0xD98CA0]

    private let key = "sound-it-out.profiles.v1"
    private let currentKey = "sound-it-out.profile.current"

    init() {
        if let d = UserDefaults.standard.data(forKey: key),
           let list = try? JSONDecoder().decode([Profile].self, from: d) { all = list }
        if let s = UserDefaults.standard.string(forKey: currentKey) { currentID = UUID(uuidString: s) }
        if currentID == nil { currentID = all.first?.id }
        // A first run should just work. One child is the common case, so a default
        // player is made silently rather than gating a three-year-old behind a
        // setup screen; the picker only matters once there is a second child.
        if all.isEmpty {
            let p = Profile(name: "Me", face: Self.faces.randomElement()!,
                            colour: Self.colours.randomElement()!)
            all = [p]; currentID = p.id; save()
        }
    }

    private func save() {
        if let d = try? JSONEncoder().encode(all) { UserDefaults.standard.set(d, forKey: key) }
        UserDefaults.standard.set(currentID?.uuidString, forKey: currentKey)
    }

    @discardableResult
    func add(name: String, face: String, colour: UInt) -> Profile {
        let p = Profile(name: name, face: face, colour: colour)
        all.append(p); currentID = p.id; save(); return p
    }
    func select(_ p: Profile) { currentID = p.id; save() }
    func remove(_ p: Profile) {
        all.removeAll { $0.id == p.id }
        if currentID == p.id { currentID = all.first?.id }
        save()
    }

    /// Edit a card's look in one call — the editor changes name, face and colour
    /// together, so there is no reason to poke at them one at a time.
    func update(_ p: Profile, name: String, face: String, colour: UInt) {
        guard let i = all.firstIndex(where: { $0.id == p.id }) else { return }
        all[i].name = name; all[i].face = face; all[i].colour = colour; save()
    }

    /// Remember the world the current child is playing in, so it returns with them.
    func setWorld(_ id: String) {
        guard let i = all.firstIndex(where: { $0.id == currentID }) else { return }
        all[i].world = id; save()
    }
}
