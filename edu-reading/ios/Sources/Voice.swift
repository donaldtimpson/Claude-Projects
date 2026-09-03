import AVFoundation

// Speech has two tiers, and the order matters.
//
// 1. A bundled recording, if one exists. This is where real human audio lands:
//    Lingua Libre / Wikimedia Commons publishes ~107k English word recordings
//    under CC BY-SA, and the 44 letter sounds are worth recording by hand so the
//    schwa is controlled ("/b/", never "buh").
// 2. On-device synthesis, so every word speaks today, before any audio is sourced.
//
// Drop `<word>.m4a` into Resources/Recordings and tier 1 takes over with no code change.
final class Voice {
    static let shared = Voice()
    private let synth = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func say(_ text: String) {
        let key = text.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".!?, "))
        if let url = Bundle.main.url(forResource: key, withExtension: "m4a") {
            player = try? AVAudioPlayer(contentsOf: url)
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

    /// True when real recorded audio backs this word. The letter-sounds deck uses
    /// it to stay honest: synthesis is bad at isolated phonemes, so it stays silent
    /// rather than teaching the wrong sound.
    func hasRecording(_ text: String) -> Bool {
        Bundle.main.url(forResource: text.lowercased(), withExtension: "m4a") != nil
    }
}
