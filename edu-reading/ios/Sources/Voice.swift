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

    /// The "YOU READ IT!" reward, for the one moment that earns it: a child saying a
    /// word aloud. iOS system sound 1322 — chosen by ear from the audition (SoundLab):
    /// cheerful, and it holds up to being heard over and over without grating. A
    /// beginning reader often has their mouth at the speaker with eyes off the screen,
    /// so the reward has to be heard, not only seen.
    func celebrate() {
        AudioServicesPlaySystemSound(SystemSoundID(1322))
    }

    /// Play rendered audio through the live route (retained so it finishes even when
    /// the mic session is open). Used by the sound audition (SoundLab).
    func playEffect(_ data: Data) {
        fx = try? AVAudioPlayer(data: data)
        fx?.volume = 1
        fx?.play()
    }

    /// One note struck at a time.
    struct Tone { let f: Double; let start: Double; let dur: Double; let amp: Double }

    /// Additive synth shared by every candidate sound: a click-free raised-cosine
    /// attack, a smooth exponential ring, then normalise-to-headroom + tanh soft-clip
    /// + tail-fade so nothing rattles a phone speaker. Rendered to an in-memory WAV,
    /// so it needs no bundled asset and plays on whatever route is live.
    static func render(_ tones: [Tone], partials: [(Double, Double)] = [(1, 1), (2, 0.25)],
                       decay: Double = 3.6) -> Data? {
        let sr = 44_100.0
        guard let end = tones.map({ $0.start + $0.dur }).max(), end > 0 else { return nil }
        let total = Int(end * sr)
        var buf = [Double](repeating: 0, count: total)
        for tone in tones {
            let start = Int(tone.start * sr), n = Int(tone.dur * sr)
            for k in 0..<n {
                let i = start + k
                if i >= total { break }
                let t = Double(k) / sr
                let attack = t < 0.012 ? 0.5 - 0.5 * cos(.pi * t / 0.012) : 1.0
                let env = attack * exp(-t * decay)
                var w = 0.0
                for (h, a) in partials { w += a * sin(2 * .pi * tone.f * h * t) }
                buf[i] += env * w * tone.amp
            }
        }
        var peak = 1e-9
        for v in buf { peak = max(peak, abs(v)) }
        let norm = 0.72 / peak, fadeN = Int(0.04 * sr)
        var pcm = [Int16](repeating: 0, count: total)
        for i in 0..<total {
            var v = tanh(buf[i] * norm)
            if i > total - fadeN { v *= Double(total - i) / Double(fadeN) }
            pcm[i] = Int16(max(-1, min(1, v)) * 32_000)
        }
        return wav(pcm, sampleRate: Int(sr))
    }

    /// A major-pentatonic run up just over an octave — the classic success sweep.
    static func harpGliss() -> Data? {
        let freqs = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.50, 1174.66, 1318.51]
        let tones = freqs.enumerated().map { i, f in
            Tone(f: f, start: Double(i) * 0.05, dur: 0.9, amp: 0.85)
        }
        return render(tones, partials: [(1, 1), (2, 0.2)], decay: 4.2)
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

    // MARK: phonemes

    /// Whether the phoneme clips are bundled. Until they are, the letters deck has
    /// nothing to play and should not ask for two taps.
    var hasAnyLetterAudio: Bool { hasPhoneme("s") }

    /// A phoneme clip is `ph_<id>.m4a`, one per sound the app teaches, from the
    /// Phonicademy 44 Sounds pack (see tools/phoneme-clips-LICENSES.md). Synthesis
    /// can't make an isolated stop consonant — it gives silence or "kuh" — and
    /// stretched synthesis came out at lengths all over the place, so a sound with
    /// no clip is never faked.
    func hasPhoneme(_ id: String) -> Bool {
        id.split(separator: "+").allSatisfy {
            Bundle.main.url(forResource: "ph_\($0)", withExtension: "m4a") != nil
        }
    }

    /// Play one phoneme. "ng+k" plays two clips back to back; "_" (a silent letter)
    /// plays nothing and finishes straight away.
    func phoneme(_ id: String, then done: (() -> Void)? = nil) {
        let clips = id.split(separator: "+").map(String.init).filter { $0 != "_" }
        playClips(clips, gap: 0, then: done)
    }

    private func playClips(_ clips: [String], gap: Double, then done: (() -> Void)?) {
        guard let first = clips.first else {
            DispatchQueue.main.async { done?() }
            return
        }
        guard let url = Bundle.main.url(forResource: "ph_\(first)", withExtension: "m4a") else {
            playClips(Array(clips.dropFirst()), gap: gap, then: done)
            return
        }
        synth.stopSpeaking(at: .immediate)
        onDone = { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + gap) {
                self?.playClips(Array(clips.dropFirst()), gap: gap, then: done)
            }
        }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        if player?.play() != true { finish() }
    }

    private var soundOutRun = 0

    /// Sound a word out: each grapheme's phoneme in turn (onStep lights it up),
    /// a breath, then the whole word. Silent letters light up with their partner
    /// but make no sound. A new call cancels one in progress.
    func soundOut(_ sounds: [(grapheme: String, phoneme: String)], word: String,
                  onStep: @escaping (Int?) -> Void, then done: (() -> Void)? = nil) {
        soundOutRun += 1
        let run = soundOutRun
        // Only sound a word out when every sound in it has a real recording. A word
        // with a sound we have no clip for (sh, ee …) is simply said whole: better
        // than sounding out three letters and skipping the fourth.
        guard sounds.allSatisfy({ $0.phoneme == "_" || hasPhoneme($0.phoneme) }) else {
            onStep(nil)
            say(word, then: done)
            return
        }
        func step(_ i: Int) {
            guard run == soundOutRun else { return }
            guard i < sounds.count else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                    guard let self, run == self.soundOutRun else { return }
                    onStep(nil)
                    self.say(word, then: done)
                }
                return
            }
            if sounds[i].phoneme == "_" { step(i + 1); return }
            onStep(i)
            phoneme(sounds[i].phoneme) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { step(i + 1) }
            }
        }
        step(0)
    }

    /// Stop any sounding-out in progress (leaving a card, starting another).
    func cancelSoundOut() { soundOutRun += 1 }
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
    /// A small tick under the finger while choosing — a face, a colour. Lighter than
    /// yes/no: it marks a choice, it does not judge it.
    static func pick() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}
