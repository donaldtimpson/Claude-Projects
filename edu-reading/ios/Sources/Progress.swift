import SwiftUI

// Everything the app remembers, per child, on the device. No account, no server,
// no identifier — so there is nothing to leak and nothing to ask permission for.
//
// The important change is WHAT counts. Words used to be collected by swiping past
// their card, which is attendance. A word is read when the child says it aloud
// (the on-device listener) or, with the microphone off, when the grown-up marks
// it. Both are moments, and a moment is what a badge can hang on.
@Observable
final class Progress {
    var profileID: UUID?

    private(set) var readWords: Set<String> = []
    private(set) var seenLetters: Set<String> = []
    private(set) var readSentences: Set<String> = []
    private(set) var colours: Set<String> = []
    private(set) var shapes: Set<String> = []
    private(set) var counted: Set<Int> = []
    private(set) var awards: Set<String> = []
    private(set) var worlds: Set<String> = [World.free]
    private(set) var finishedDecks: Set<String> = []
    private(set) var lastDay: String = ""

    /// Set by the engine when something is earned; the app shows it and clears it.
    var pending: [Award] = []

    struct Snapshot: Codable {
        var words: [String] = []; var letters: [String] = []; var sentences: [String] = []
        var colours: [String] = []; var shapes: [String] = []; var counted: [Int] = []
        var awards: [String] = []; var worlds: [String] = []; var decks: [String] = []
        var lastDay: String = ""
    }

    private func key(_ id: UUID?) -> String { "sound-it-out.progress.\(id?.uuidString ?? "solo")" }

    func load(profile: UUID?) {
        profileID = profile
        readWords = []; seenLetters = []; readSentences = []; colours = []; shapes = []
        counted = []; awards = []; worlds = [World.free]; finishedDecks = []; lastDay = ""
        guard let d = UserDefaults.standard.data(forKey: key(profile)),
              let s = try? JSONDecoder().decode(Snapshot.self, from: d) else { return }
        readWords = Set(s.words); seenLetters = Set(s.letters); readSentences = Set(s.sentences)
        colours = Set(s.colours); shapes = Set(s.shapes); counted = Set(s.counted)
        awards = Set(s.awards); worlds = Set(s.worlds).union([World.free])
        finishedDecks = Set(s.decks); lastDay = s.lastDay
    }

    private func save() {
        let s = Snapshot(words: Array(readWords), letters: Array(seenLetters),
                         sentences: Array(readSentences), colours: Array(colours),
                         shapes: Array(shapes), counted: Array(counted),
                         awards: Array(awards), worlds: Array(worlds),
                         decks: Array(finishedDecks), lastDay: lastDay)
        if let d = try? JSONEncoder().encode(s) { UserDefaults.standard.set(d, forKey: key(profileID)) }
    }

    // MARK: earning

    func readWord(_ w: String)      { if readWords.insert(w.lowercased()).inserted { check() } }
    func metLetter(_ l: String)     { if seenLetters.insert(l.lowercased()).inserted { check() } }
    func readSentence(_ s: String)  { if readSentences.insert(s).inserted { check() } }
    func namedColour(_ c: String)   { if colours.insert(c).inserted { check() } }
    func namedShape(_ s: String)    { if shapes.insert(s).inserted { check() } }
    func counted(_ n: Int)          { if counted.insert(n).inserted { check() } }
    func finishedDeck(_ d: String)  { if finishedDecks.insert(d).inserted { check() } }

    /// Called once when the app opens. Rewards coming back rather than never
    /// having left — there is no streak to break, so a holiday costs nothing.
    func openedToday() {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let today = f.string(from: Date())
        guard today != lastDay else { return }
        let hadBefore = !lastDay.isEmpty
        lastDay = today
        if hadBefore { grant("came-back") }
        save()
    }

    func has(_ id: String) -> Bool { awards.contains(id) }
    func opened(_ w: World) -> Bool { worlds.contains(w.id) }
    func knows(word: String) -> Bool { readWords.contains(word.lowercased()) }

    // MARK: granting

    private func grant(_ id: String) {
        guard !awards.contains(id), let a = Awards.find(id) else { return }
        awards.insert(id)
        if let w = a.unlocksWorld { worlds.insert(w) }
        pending.append(a)
    }

    private func check() {
        let c = ReadingContent.shared
        if readWords.count >= 1   { grant("first-word") }
        if readWords.count >= 10  { grant("ten-words") }
        if readWords.count >= 25  { grant("twenty-five") }
        if readWords.count >= 50  { grant("fifty") }
        if readWords.count >= 100 { grant("hundred") }
        if seenLetters.count >= 13 { grant("letters-half") }
        if seenLetters.count >= c.letters.count { grant("all-letters") }
        if !readSentences.isEmpty { grant("a-sentence") }
        if colours.count >= c.colors.count { grant("all-colours") }
        if shapes.count >= c.shapes.count { grant("all-shapes") }
        if counted.isSuperset(of: Set(1...10)) { grant("count-ten") }
        if !finishedDecks.isEmpty { grant("a-deck") }
        save()
    }

    func reset() {
        readWords = []; seenLetters = []; readSentences = []; colours = []; shapes = []
        counted = []; awards = []; worlds = [World.free]; finishedDecks = []; lastDay = ""
        save()
    }
}
