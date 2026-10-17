import AVFoundation
import SwiftUI

// MARK: - Library read-aloud (shared by the Word Wizards games)
//
// On-device synthesized speech so pre-readers can play the word games: a 🔊 button repeats the
// cue, and each new item is said once automatically. Never required — every level also works
// silently. `LUDUS_MUTE=1` (DEBUG) silences it for long bot runs.

@MainActor
enum LibraryVoice {
    private static let synth = AVSpeechSynthesizer()
    private static let voice = AVSpeechSynthesisVoice(language: "en-US")
    private static var sessionReady = false

    static func say(_ text: String, rate: Float = 0.42) {
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_MUTE"] != nil { return }
        #endif
        guard !text.isEmpty else { return }
        // Speak through the silent switch (pre-readers depend on it); mixes with other audio.
        if !sessionReady {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
            sessionReady = true
        }
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let u = AVSpeechUtterance(string: text)
        u.rate = rate
        u.pitchMultiplier = 1.05
        u.voice = voice
        synth.speak(u)
    }

    static func stop() {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
    }
}

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
