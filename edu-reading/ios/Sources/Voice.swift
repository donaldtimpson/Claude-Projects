import AVFoundation
import AudioToolbox
import UIKit

// Speech has two tiers, and the order matters.
//
// 1. A bundled recording, if one exists. This is where real human audio lands:
//    Lingua Libre / Wikimedia Commons publishes ~107k English word recordings
//    under CC BY-SA, and the 44 letter sounds are worth recording by hand so the
//    schwa is controlled ("/b/", never "buh").
// 2. On-device synthesis, so every word speaks today, before any audio is sourced.
//
// Drop `<word>.m4a` into Resources/Recordings and tier 1 takes over with no code change.
final class Voice: NSObject {
    static let shared = Voice()
    private let synth = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?
    /// Called when the current utterance or recording finishes, so a caller can
    /// hold off on accepting input until the word has actually been said.
    private var onDone: (() -> Void)?

    private override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        synth.delegate = self
    }

    func say(_ text: String, then done: (() -> Void)? = nil) {
        onDone = done
        let key = text.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".!?, "))
        if let url = Bundle.main.url(forResource: key, withExtension: "m4a") {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
            return
        }
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.rate = 0.36           // a beginning reader needs it slow
        u.pitchMultiplier = 1.05
        u.postUtteranceDelay = 0
        synth.speak(u)
    }

    private func finish() {
        let d = onDone; onDone = nil
        DispatchQueue.main.async { d?() }
    }

    /// A short rising tone for "you read it". Deliberately not a voice saying
    /// "well done" — that gets old by the fifth card, and it talks over the child.
    func chime() {
        let n = 1
        AudioServicesPlaySystemSound(SystemSoundID(1103 + n))
    }

    /// Whether any phoneme recordings are bundled at all. Until they are, the
    /// letters deck has nothing to play and should not ask for two taps.
    var hasAnyLetterAudio: Bool {
        ReadingContent.shared.letters.contains { hasRecording($0.sound) }
    }

    /// True when real recorded audio backs this word. The letter-sounds deck uses
    /// it to stay honest: synthesis is bad at isolated phonemes, so it stays silent
    /// rather than teaching the wrong sound.
    func hasRecording(_ text: String) -> Bool {
        Bundle.main.url(forResource: text.lowercased(), withExtension: "m4a") != nil
    }
}


extension Voice: AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) { finish() }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel u: AVSpeechUtterance) { finish() }
    func audioPlayerDidFinishPlaying(_ p: AVAudioPlayer, successfully f: Bool) { finish() }
}

/// A small physical yes and no. Feedback a child feels is more definite than
/// anything on screen, and unlike a buzzer it carries no scolding.
enum Buzz {
    static func yes() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func no()  { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
}
