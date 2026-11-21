import AVFoundation
import SwiftUI

// MARK: - Library read-aloud (shared by the Word Wizards games)
//
// On-device synthesized speech so pre-readers can play the word games: a 🔊 button repeats the
// cue, and each new item is said once automatically. Never required — every level also works
// silently. Off with the sound switch; `LUDUS_MUTE=1` (DEBUG) silences it for long bot runs.

@MainActor
enum LibraryVoice {
    private static let synth = AVSpeechSynthesizer()
    private static let voice = AVSpeechSynthesisVoice(language: "en-US")
    private static var sessionReady = false
    private static let relay = Relay()
    private static var finished: [ObjectIdentifier: () -> Void] = [:]

    /// Says `text`. A sound written between slashes — "What starts with /k/?" — is spoken as the
    /// bare sound (IPA, see `phonics`), not the letter name. `then` runs once the voice is done
    /// (finished, cut off by the next line, or — when sound is off — after a reading-time pause),
    /// so a game can start its clock AFTER the directions instead of during them.
    static func say(_ text: String, rate: Float = 0.42, then done: (() -> Void)? = nil) {
        let once = Once(done)
        // The Tabularium's sound switch silences speech too (and `LUDUS_MUTE`, via `Sfx.muted`).
        guard !Sfx.muted, !text.isEmpty else {
            DispatchQueue.main.asyncAfter(deadline: .now() + readingTime(text)) { once.run() }
            return
        }
        // Speak through the silent switch (pre-readers depend on it); mixes with other audio.
        if !sessionReady {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
            sessionReady = true
            synth.delegate = relay
        }
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let u = AVSpeechUtterance(attributedString: spoken(text))
        u.rate = rate
        u.pitchMultiplier = 1.05
        u.voice = voice
        finished[ObjectIdentifier(u)] = { once.run() }
        synth.speak(u)
        // Belt and braces: if the voice never reports back (a cold simulator can stall for
        // seconds), don't hold the game hostage.
        DispatchQueue.main.asyncAfter(deadline: .now() + readingTime(text) * 1.6 + 3) { once.run() }
    }

    static func stop() {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
    }

    /// Roughly how long `text` takes to say at the game voice's pace.
    static func readingTime(_ text: String) -> Double { max(0.8, Double(text.count) * 0.075) }

    /// Bare sounds the games ask for, as IPA. Stops need a short schwa to be heard; continuants
    /// are tripled so they're held (a length mark is ignored; a tripled /ɹ/ is silent, so r gets ə).
    static let phonics: [String: String] = [
        "b": "bə", "k": "kə", "c": "kə", "p": "pə", "t": "tə", "d": "də", "g": "gə", "h": "hə",
        "w": "wə", "j": "dʒə", "r": "ɹə", "y": "jə",
        "m": "mmm", "n": "nnn", "s": "sss", "f": "fff", "l": "lll", "v": "vvv", "z": "zzz",
        "a": "æ", "e": "ɛ", "i": "ɪ", "o": "ɑ", "u": "ʌ",
        "ă": "æ", "ĕ": "ɛ", "ĭ": "ɪ", "ŏ": "ɑ", "ŭ": "ʌ",
        "ā": "eɪ", "ē": "i", "ī": "aɪ", "ō": "oʊ", "ū": "u",
        "ch": "tʃə", "sh": "ʃʃʃ", "th": "θθθ", "ck": "kə", "ll": "lll", "ng": "ŋŋŋ",
        "br": "bɹə", "cr": "kɹə", "dr": "dɹə", "fr": "fɹə", "gr": "gɹə", "pr": "pɹə", "tr": "tɹə",
        "cl": "klə", "fl": "flə", "pl": "plə", "bl": "blə", "gl": "glə", "sl": "sllə",
        "sn": "snə", "sp": "spə", "st": "stə", "sk": "skə", "sm": "smə", "sw": "swə",
    ]

    /// The utterance for `text`, with every /sound/ marked up as IPA.
    private static func spoken(_ text: String) -> NSAttributedString {
        let out = NSMutableAttributedString()
        var rest = Substring(text)
        while let open = rest.firstIndex(of: "/"),
              let close = rest[rest.index(after: open)...].firstIndex(of: "/") {
            let key = String(rest[rest.index(after: open)..<close])
            out.append(NSAttributedString(string: String(rest[..<open])))
            if let ipa = phonics[key.lowercased()] {
                out.append(NSAttributedString(string: key, attributes: [
                    NSAttributedString.Key(AVSpeechSynthesisIPANotationAttribute): ipa]))
            } else {
                out.append(NSAttributedString(string: key))
            }
            rest = rest[rest.index(after: close)...]
        }
        out.append(NSAttributedString(string: String(rest)))
        return out
    }

    fileprivate static func done(_ u: AVSpeechUtterance) {
        finished.removeValue(forKey: ObjectIdentifier(u))?()
    }

    private final class Relay: NSObject, AVSpeechSynthesizerDelegate {
        nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) { hand(u) }
        nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel u: AVSpeechUtterance) { hand(u) }
        nonisolated private func hand(_ u: AVSpeechUtterance) {
            let box = UncheckedBox(value: u)
            Task { @MainActor in LibraryVoice.done(box.value) }
        }
    }

    /// A completion that runs at most once.
    private final class Once {
        private var f: (() -> Void)?
        init(_ f: (() -> Void)?) { self.f = f }
        func run() { let g = f; f = nil; g?() }
    }
}

private struct UncheckedBox<T>: @unchecked Sendable { let value: T }

/// The round 🔊 button that repeats a cue.
struct LibrarySpeakerButton: View {
    var size: CGFloat = 44
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(Color(hex: Lu.inkDark))
                .frame(width: size, height: size)
                .background(Circle().fill(Color(hex: Lu.gold)))
                .overlay(Circle().stroke(Color(hex: Lu.goldLine), lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Say it again")
    }
}

/// A side-to-side shake, re-triggered by bumping `shakes` (animatableData).
struct LibraryShake: GeometryEffect {
    var amount: CGFloat = 9
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(shakes * .pi * 4), y: 0))
    }
}
