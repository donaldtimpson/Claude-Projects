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
    private var fx: AVAudioPlayer?
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

    /// The bigger "YOU READ IT!" flourish, for the one moment that earns it: a child
    /// reading a word aloud. A rising four-note sparkle that rings into a chord —
    /// loud and unmistakable on purpose. A beginning reader often has their mouth
    /// right at the speaker with their eyes off the screen, so the reward has to be
    /// something they HEAR, not only something they'd have to be looking to see.
    func celebrate() {
        guard let data = Self.fanfareWAV else { chime(); return }
        fx = try? AVAudioPlayer(data: data)
        fx?.volume = 1
        fx?.play()
    }

    /// Rendered once to an in-memory WAV so it plays through whatever route is live —
    /// including .playAndRecord while the mic is open — with no bundled asset needed.
    private static let fanfareWAV: Data? = makeFanfare()

    private static func makeFanfare() -> Data? {
        let sr = 44_100.0
        // C5 E5 G5 C6 — the same happy major arpeggio, but an octave lower than a
        // first pass that sat up at C6–C7 and came out piercing. Struck a beat apart
        // so they pile into a warm final chord, like a music box rather than a ping.
        let notes: [(f: Double, start: Double)] = [
            (523.25, 0.00), (659.25, 0.10), (783.99, 0.20), (1046.50, 0.30),
        ]
        let noteDur = 0.9
        let total = Int(((notes.last?.start ?? 0) + noteDur) * sr)
        guard total > 0 else { return nil }
        var buf = [Double](repeating: 0, count: total)
        for (i, note) in notes.enumerated() {
            let start = Int(note.start * sr)
            let n = Int(noteDur * sr)
            let amp = 0.9 - 0.12 * Double(i)                         // higher notes a touch softer
            for k in 0..<n {
                let idx = start + k
                if idx >= total { break }
                let t = Double(k) / sr
                // A raised-cosine attack (no onset click — the click is what buzzed
                // like a blown speaker), then a long smooth ring.
                let attack = t < 0.012 ? 0.5 - 0.5 * cos(.pi * t / 0.012) : 1.0
                let env = attack * exp(-t * 3.6)
                // Fundamental plus a gentle octave — sweet, no harsh partials to
                // rattle a small speaker.
                let wave = sin(2 * .pi * note.f * t) + 0.25 * sin(2 * .pi * note.f * 2 * t)
                buf[idx] += env * wave * amp
            }
        }
        // Normalise to headroom, soft-clip with tanh so peaks round over instead of
        // clipping, and fade the tail so it can't end on a click.
        var peak = 1e-9
        for v in buf { peak = max(peak, abs(v)) }
        let norm = 0.72 / peak
        let fadeN = Int(0.04 * sr)
        var pcm = [Int16](repeating: 0, count: total)
        for i in 0..<total {
            var v = tanh(buf[i] * norm)
            if i > total - fadeN { v *= Double(total - i) / Double(fadeN) }
            pcm[i] = Int16(max(-1, min(1, v)) * 32_000)
        }
        return wav(pcm, sampleRate: Int(sr))
    }

    private static func wav(_ pcm: [Int16], sampleRate: Int) -> Data {
        let bytesPerSample = 2, channels = 1
        let dataBytes = pcm.count * bytesPerSample
        var d = Data()
        func u32(_ v: UInt32) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 4)) }
        func u16(_ v: UInt16) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 2)) }
        d.append("RIFF".data(using: .ascii)!); u32(UInt32(36 + dataBytes))
        d.append("WAVE".data(using: .ascii)!)
        d.append("fmt ".data(using: .ascii)!); u32(16); u16(1); u16(UInt16(channels))
        u32(UInt32(sampleRate))
        u32(UInt32(sampleRate * channels * bytesPerSample))         // byte rate
        u16(UInt16(channels * bytesPerSample))                      // block align
        u16(16)                                                     // bits per sample
        d.append("data".data(using: .ascii)!); u32(UInt32(dataBytes))
        pcm.withUnsafeBytes { d.append(contentsOf: $0) }
        return d
    }

    /// Calls back when whatever is playing finishes — or straight away if nothing
    /// is. Callers use it to stop accepting taps while a word is being said.
    func whenIdle(_ done: @escaping () -> Void) {
        if synth.isSpeaking || (player?.isPlaying ?? false) {
            let existing = onDone
            onDone = { existing?(); done() }
            // A callback can be missed; never leave the screen dead because of it.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: done)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: done)
        }
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
