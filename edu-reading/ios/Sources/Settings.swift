import SwiftUI

// Everything a grown-up chooses. None of it appears on a child's screen, because
// a chip on the card is something to tap forever rather than a setting.
@Observable
final class Settings {
    var rimeBlending = true      // variant B by default; A is the fa/fe/fi version
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

    private static let key = "sound-it-out.settings.v1"
    struct Snapshot: Codable { var rime: Bool; var listen: Bool; var label: Bool
                               var autoTurn: Bool?; var style: String?; var ids: Bool? }

    init() {
        guard let d = UserDefaults.standard.data(forKey: Self.key),
              let s = try? JSONDecoder().decode(Snapshot.self, from: d) else { return }
        rimeBlending = s.rime; listenForVoice = s.listen; showWordOnPictures = s.label
        autoTurn = s.autoTurn ?? false
        pictureStyle = PictureStyle(rawValue: s.style ?? "") ?? .both
        showCardIds = s.ids ?? true
    }
    func save() {
        let s = Snapshot(rime: rimeBlending, listen: listenForVoice, label: showWordOnPictures,
                         autoTurn: autoTurn, style: pictureStyle.rawValue, ids: showCardIds)
        if let d = try? JSONEncoder().encode(s) { UserDefaults.standard.set(d, forKey: Self.key) }
    }
}
