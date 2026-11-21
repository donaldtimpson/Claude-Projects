import Foundation

// Mirrors content/reading/reading.json. That file is the source of truth for all
// six decks; this app only ever reads it.
struct ReadingContent: Codable {
    struct PictureWord: Codable, Hashable { let word: String; let category: String; let images: [String] }
    struct Letter: Codable, Hashable {
        let upper: String; let lower: String
        let sound: String; let asIn: String; let avoid: String; let set: Int
    }
    struct Rime: Codable, Hashable { let rime: String; let words: [String] }
    /// `parts` are the word's graphemes in order, each optionally "grapheme:phoneme"
    /// when it isn't that grapheme's usual sound ("c", "a:ay", "k", "e:_" — "_" is
    /// silent). Written and checked by tools/phonics.py.
    struct Word: Codable, Hashable {
        let word: String; let level: String; let image: String?; let parts: [String]?
    }
    /// `level` ramps the deck the way word levels ramp Words: a CVC reader meets
    /// CVC sentences first. Optional so a sentence saved before levels existed still
    /// decodes (it sorts to the end).
    struct Sentence: Codable, Hashable { let text: String; let level: Int? }
    struct HeartPart: Codable, Hashable { let grapheme: String; let regular: Bool }
    /// `level` is the sentence level a heart word is first needed at — the deck
    /// teaches them in that order, just in time.
    struct HeartWord: Codable, Hashable {
        let word: String; let parts: [HeartPart]; let sentence: String; let level: Int?
    }
    /// Picturable rhyme families for Rhyme Time — every word has a drawing, so the
    /// game needs no reading at all.
    struct RhymeSet: Codable, Hashable { let words: [Pic] }
    struct Pic: Codable, Hashable { let word: String; let image: String }
    struct Spell: Codable, Hashable { let text: String; let target: String; let effect: String }
    struct Biome: Codable, Hashable { let id: String; let icon: String; let unlockAt: Int }
    struct World: Codable { let spells: [Spell]; let biomes: [Biome] }

    let pictureWords: [PictureWord]
    let letters: [Letter]
    let rimes: [Rime]
    let words: [Word]
    let sentences: [Sentence]
    /// The consonants the Blending deck pairs with each vowel (b→ba be bi bo bu …).
    /// "qu" is one unit and gets a single sound-dot. Optional so older content
    /// without the field still decodes, falling back to the default set.
    let blendConsonants: [String]?
    let heartWords: [HeartWord]
    let world: World
    let sightWords: [String]
    let deckOrder: [String]
    let colors: [Swatch]
    let shapes: [Shape2]
    let numbers: Numbers
    /// Each grapheme's usual phoneme (the audio clip id), exported by phonics.py.
    let phonemeDefaults: [String: String]?
    let rhymeSets: [RhymeSet]?

    struct Swatch: Codable, Hashable { let word: String; let hex: String }
    struct Shape2: Codable, Hashable { let word: String }
    struct Numbers: Codable { let levels: [Int]; let words: [String] }

    static let shared: ReadingContent = {
        guard let url = Bundle.main.url(forResource: "reading", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(ReadingContent.self, from: data)
        else { fatalError("reading.json missing or malformed — run edu-reading/tools/sync-content.sh") }
        return decoded
    }()

    var sightSet: Set<String> { Set(sightWords.map { $0.lowercased() }) }

    /// A word's sounds in order: (the letters as written, the phoneme clip id).
    /// Silent letters come back with phoneme "_".
    func sounds(of w: Word) -> [(grapheme: String, phoneme: String)] {
        (w.parts ?? w.word.map(String.init)).map { part in
            let bits = part.split(separator: ":", maxSplits: 1).map(String.init)
            let g = bits[0]
            return (g, bits.count > 1 ? bits[1] : (phonemeDefaults?[g.lowercased()] ?? g.lowercased()))
        }
    }
    /// The five short vowels, in teaching order, painted red everywhere in the app.
    var blendVowels: [String] { ["a", "e", "i", "o", "u"] }
    var syllableConsonants: [String] {
        blendConsonants ?? ["b","d","f","g","h","j","k","l","m","n",
                            "p","qu","r","s","t","v","w","y","z"]
    }
    /// The phonics ladder, in teaching order. Words and Sentences both order by a
    /// word's position here, so a beginner never meets "strength" on card three.
    /// Adding a stage is an edit to this list plus content tagged with its name.
    var wordLevels: [String] {
        ["CVC", "Digraphs", "Blends", "SilentE",
         "VowelTeams", "RControlled", "Diphthongs", "Endings"]
    }
    /// Deck order comes from the content file, so re-ordering the decks is an edit
    /// to content rather than to code.
    var pictureCategories: [String] {
        deckOrder.filter { d in pictureWords.contains { $0.category == d } }
    }
    func words(in deck: String) -> [PictureWord] { pictureWords.filter { $0.category == deck } }
    /// The collectible objects in the world are exactly the words that have art.
    /// One asset set, two jobs — the flip-card reveal and the reward.
    var collectibles: [Word] { words.filter { $0.image != nil } }
}
