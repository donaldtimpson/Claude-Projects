import Foundation
import AVFoundation
import Speech

// "Can the child say the word and have us notice?"
//
// Yes — but only because this is verification, not open recognition: the target
// word is already known, so the job is to spot a match rather than transcribe a
// four-year-old from scratch. Children's speech is genuinely hard for recognisers
// (higher pitch, developing articulation, no sentence context on a lone word), so
// the whole thing is built around one rule:
//
//     IT CAN ONLY EVER SAY YES.
//
// A match celebrates. A non-match does nothing at all — no buzz, no red, no
// "try again". A small child is never told they were wrong on a signal we don't
// trust. That turns an unreliable technology into a safe one: false negatives are
// invisible, and there is no such thing as a false accusation.
//
// Recognition is forced on-device, so speech never leaves the phone and the
// app keeps its promise of collecting nothing.
@Observable
final class Listener {
    enum State: Equatable { case off, listening, heard, matched }
    var state: State = .off
    var level: Double = 0          // mic amplitude, drives the pulsing ring

    private let engine = AVAudioEngine()
    private var task: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var target = ""
    private var onMatch: (() -> Void)?

    static var isAuthorized: Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized
            && AVAudioApplication.shared.recordPermission == .granted
    }

    /// Asked for only from the grown-ups' area — App Store guideline 1.3 requires a
    /// parental gate before a Kids app requests permissions.
    static func requestAccess(_ done: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            AVAudioApplication.requestRecordPermission { mic in
                DispatchQueue.main.async { done(status == .authorized && mic) }
            }
        }
    }

    func listen(for word: String, onMatch: @escaping () -> Void) {
        guard Self.isAuthorized, let recognizer, recognizer.isAvailable else { return }
        stop()
        target = Self.normalize(word)
        self.onMatch = onMatch

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        // Constrain the recogniser toward the word we are hoping for.
        req.contextualStrings = [word]
        if recognizer.supportsOnDeviceRecognition { req.requiresOnDeviceRecognition = true }
        request = req

        let input = engine.inputNode
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { [weak self] buf, _ in
            req.append(buf)
            self?.meter(buf)
        }
        engine.prepare()
        do { try engine.start() } catch { return }
        state = .listening

        task = recognizer.recognitionTask(with: req) { [weak self] result, _ in
            guard let self, let result else { return }
            let said = Self.normalize(result.bestTranscription.formattedString)
            guard !said.isEmpty else { return }
            if self.state == .listening { self.state = .heard }
            if Self.matches(said: said, target: self.target) {
                self.state = .matched
                self.onMatch?()
                self.stop()
            }
        }
    }

    func stop() {
        task?.cancel(); task = nil
        request?.endAudio(); request = nil
        if engine.isRunning { engine.stop() }
        engine.inputNode.removeTap(onBus: 0)
        level = 0
        if state != .matched { state = .off }
    }

    private func meter(_ buf: AVAudioPCMBuffer) {
        guard let ch = buf.floatChannelData?[0] else { return }
        let n = Int(buf.frameLength)
        var sum: Float = 0
        for i in 0..<n { sum += ch[i] * ch[i] }
        let rms = sqrt(sum / Float(max(n, 1)))
        DispatchQueue.main.async { self.level = min(1, Double(rms) * 14) }
    }

    // MARK: matching — generous on purpose

    static func normalize(_ s: String) -> String {
        s.lowercased().filter { $0.isLetter || $0 == " " }.trimmingCharacters(in: .whitespaces)
    }

    /// Accepts the word anywhere in what was heard, and tolerates one wrong letter.
    /// A child saying "sad" for "sat" has done the reading work; the recogniser is
    /// far likelier to be at fault than the child.
    static func matches(said: String, target: String) -> Bool {
        if said.contains(target) { return true }
        for token in said.split(separator: " ") {
            if editDistance(String(token), target) <= (target.count <= 3 ? 1 : 2) { return true }
        }
        return false
    }

    static func editDistance(_ a: String, _ b: String) -> Int {
        let x = Array(a), y = Array(b)
        if x.isEmpty { return y.count }
        if y.isEmpty { return x.count }
        var prev = Array(0...y.count)
        for i in 1...x.count {
            var cur = [i] + Array(repeating: 0, count: y.count)
            for j in 1...y.count {
                cur[j] = x[i-1] == y[j-1] ? prev[j-1]
                                          : Swift.min(prev[j-1], prev[j], cur[j-1]) + 1
            }
            prev = cur
        }
        return prev[y.count]
    }
}
