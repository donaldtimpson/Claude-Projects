import Foundation

// Mirrors content/reading/reading.json. That file is the source of truth for all
// six decks; this app only ever reads it.
struct ReadingContent: Codable {
    struct PictureWord: Codable, Hashable { let word: String; let category: String; let images: [String] }
    struct Letter: Codable, Hashable {
        let upper: String; let lower: String
        let sound: String; let asIn: String; let avoid: String; let set: Int
    }
    struct CV: Codable, Hashable { let text: String }
    struct Rime: Codable, Hashable { let rime: String; let words: [String] }
    struct Word: Codable, Hashable { let word: String; let level: String; let image: String? }
    struct Sentence: Codable, Hashable { let text: String }
    struct HeartPart: Codable, Hashable { let grapheme: String; let regular: Bool }
    struct HeartWord: Codable, Hashable { let word: String; let parts: [HeartPart]; let sentence: String }
    struct Spell: Codable, Hashable { let text: String; let target: String; let effect: String }
    struct Biome: Codable, Hashable { let id: String; let icon: String; let unlockAt: Int }
    struct World: Codable { let spells: [Spell]; let biomes: [Biome] }

    let pictureWords: [PictureWord]
    let letters: [Letter]
    let cvBlends: [CV]
    let rimes: [Rime]
    let words: [Word]
    let sentences: [Sentence]
    let heartWords: [HeartWord]
    let world: World
    let sightWords: [String]

    static let shared: ReadingContent = {
        guard let url = Bundle.main.url(forResource: "reading", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(ReadingContent.self, from: data)
        else { fatalError("reading.json missing or malformed — run edu-reading/tools/sync-content.sh") }
        return decoded
    }()

    var sightSet: Set<String> { Set(sightWords) }
    var wordLevels: [String] { ["CVC", "Digraphs", "Blends", "SilentE"] }
    var pictureCategories: [String] {
        var seen: [String] = []
        for p in pictureWords where !seen.contains(p.category) { seen.append(p.category) }
        return seen
    }
    /// The collectible objects in the world are exactly the words that have art.
    /// One asset set, two jobs — the flip-card reveal and the reward.
    var collectibles: [Word] { words.filter { $0.image != nil } }
}
