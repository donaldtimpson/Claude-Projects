import SwiftUI

// Everything a grown-up chooses. None of it appears on a child's screen, because
// a chip on the card is something to tap forever rather than a setting.
@Observable
final class Settings {
    var listenForVoice = false   // off until a grown-up grants the microphone
    var showWordOnPictures = true // the label is for the adult, so it is theirs to hide
    // Two ways to turn a card, because "tap twice" asks for an intent a very young
    // child may not have yet. Off: tap speaks, tap again turns. On: tap speaks and
    // the card turns itself when the word finishes.
    var autoTurn = false

    // Photographs and drawings are two ways of showing the same idea, and moving
    // between them is a real step: a beagle, a labrador and a cartoon dog are all
    // "dog". So by default they INTERLEAVE rather than living in separate decks —
    // the round-dealing already puts a word's pictures a full deck apart. Younger
    // children often read a simple drawing more easily than a busy photograph,
    // which is what the other two settings are for.
    enum PictureStyle: String, Codable, CaseIterable {
        case both = "Both", photos = "Photos", drawings = "Drawings"
    }
    var pictureStyle: PictureStyle = .both

    // Card ids, for reporting a bad card without having to describe it.
    var showCardIds = true

    // Levels rather than a free range: 1–10 and 1–20 are real boundaries. English
    // teens are irregular, and past twenty the lesson becomes place value.
    var numberLevel = 10

    // Two choices is a real question for a two-year-old and four is not; this is
    // the difficulty dial for the quiz.
    var quizChoices = 2
    // False: the app says the word and the child finds it — no reading needed.
    // True: the word is printed, which is the reading test.
    var quizReads = false

    // Per-game difficulty. Build a Word's extra decoy letters, Rhyme Time's number
    // of choices, and Match Up's number of pairs.
    var spellDecoys = 2
    var rhymeChoices = 3
    var matchPairs = 4

    private static let key = "sound-it-out.settings.v1"
    struct Snapshot: Codable { var listen: Bool; var label: Bool
                               var autoTurn: Bool?; var style: String?; var ids: Bool?; var num: Int?
                               var qc: Int?; var qr: Bool?
                               var sd: Int?; var rc: Int?; var mp: Int? }

    init() {
        guard let d = UserDefaults.standard.data(forKey: Self.key),
              let s = try? JSONDecoder().decode(Snapshot.self, from: d) else { return }
        listenForVoice = s.listen; showWordOnPictures = s.label
        autoTurn = s.autoTurn ?? false
        pictureStyle = PictureStyle(rawValue: s.style ?? "") ?? .both
        showCardIds = s.ids ?? true
        numberLevel = s.num ?? 10
        quizChoices = s.qc ?? 2
        quizReads = s.qr ?? false
        spellDecoys = s.sd ?? 2
        rhymeChoices = s.rc ?? 3
        matchPairs = s.mp ?? 4
    }
    func save() {
        let s = Snapshot(listen: listenForVoice, label: showWordOnPictures,
                         autoTurn: autoTurn, style: pictureStyle.rawValue, ids: showCardIds,
                         num: numberLevel, qc: quizChoices, qr: quizReads,
                         sd: spellDecoys, rc: rhymeChoices, mp: matchPairs)
        if let d = try? JSONEncoder().encode(s) { UserDefaults.standard.set(d, forKey: Self.key) }
    }
}
