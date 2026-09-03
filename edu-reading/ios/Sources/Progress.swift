import SwiftUI

// Everything the app remembers lives here, on the device, in UserDefaults.
// There is no account, no server, and no identifier of any kind — so there is
// nothing to leak and nothing to ask permission for.
@Observable
final class Progress {
    var knownWords: Set<String> = []
    var knownLetters: Set<String> = []
    var castSpells: Set<String> = []
    var biomeIndex: Int = 0

    private static let key = "sound-it-out.progress.v1"

    struct Snapshot: Codable {
        var knownWords: [String]; var knownLetters: [String]
        var castSpells: [String]; var biomeIndex: Int
    }

    init() {
        guard let data = UserDefaults.standard.data(forKey: Self.key),
              let s = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        knownWords = Set(s.knownWords); knownLetters = Set(s.knownLetters)
        castSpells = Set(s.castSpells); biomeIndex = s.biomeIndex
    }

    private func save() {
        let s = Snapshot(knownWords: Array(knownWords), knownLetters: Array(knownLetters),
                         castSpells: Array(castSpells), biomeIndex: biomeIndex)
        if let d = try? JSONEncoder().encode(s) { UserDefaults.standard.set(d, forKey: Self.key) }
    }

    func learn(word: String) { if knownWords.insert(word.lowercased()).inserted { save() } }
    func learn(letter: String) { if knownLetters.insert(letter.lowercased()).inserted { save() } }
    func cast(_ spell: String) { if castSpells.insert(spell).inserted { save() } }
    func knows(word: String) -> Bool { knownWords.contains(word.lowercased()) }
    func choose(biome: Int) { biomeIndex = biome; save() }

    func unlocked(_ b: ReadingContent.Biome) -> Bool { knownWords.count >= b.unlockAt }

    /// Deliberately not a streak. A streak punishes a family holiday and hands the
    /// guilt to the parent; nothing here decays or expires.
    func reset() {
        knownWords = []; knownLetters = []; castSpells = []; biomeIndex = 0; save()
    }
}
