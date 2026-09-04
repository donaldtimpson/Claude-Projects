import SwiftUI

// Everything a grown-up chooses. None of it appears on a child's screen, because
// a chip on the card is something to tap forever rather than a setting.
@Observable
final class Settings {
    var rimeBlending = true      // variant B by default; A is the fa/fe/fi version
    var listenForVoice = false   // off until a grown-up grants the microphone
    var showWordOnPictures = true // the label is for the adult, so it is theirs to hide

    private static let key = "sound-it-out.settings.v1"
    struct Snapshot: Codable { var rime: Bool; var listen: Bool; var label: Bool }

    init() {
        guard let d = UserDefaults.standard.data(forKey: Self.key),
              let s = try? JSONDecoder().decode(Snapshot.self, from: d) else { return }
        rimeBlending = s.rime; listenForVoice = s.listen; showWordOnPictures = s.label
    }
    func save() {
        let s = Snapshot(rime: rimeBlending, listen: listenForVoice, label: showWordOnPictures)
        if let d = try? JSONEncoder().encode(s) { UserDefaults.standard.set(d, forKey: Self.key) }
    }
}
