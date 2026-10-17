import AVFoundation
import Accelerate

// MARK: - ToneSynth — the Theatre's little piano
//
// One shared, asset-free synth for the Music games. Each note is synthesised once (a few
// harmonics, each with a two-stage exponential decay — a plucky, piano-ish tone) and cached as
// samples; a call to `play` mixes its whole event list (a note, a chord, a tune at a tempo) into
// ONE buffer and schedules it on a free AVAudioPlayerNode. Pre-rendered buffers are cheap,
// sample-accurate and click-free, and polyphony is just mixing.
//
// Lifecycle: a Theatre game calls `start()` when it appears and `stop()` when it closes. The
// engine itself only spins up on the first sound and pauses itself after a few idle seconds, so
// nothing renders while no music is playing (zero idle CPU elsewhere in the app).
//
// Session: `.ambient` — it mixes with other audio and RESPECTS the silent switch, so a phone
// with the ringer switch on silent plays nothing (iOS gives apps no way to read the switch).
// `SoundCheck` (TheatreKit) shows a "turn sound on" hint when the volume is at zero.

enum ToneVoice: Int { case piano, drum }

/// One sound in a `play` call: `at` seconds from now, a MIDI note (60 = middle C), a velocity
/// (0…1, i.e. how hard the key is struck) and how long it's held before it's damped.
struct ToneEvent {
    var at: Double = 0
    var midi: Int
    var vel: Float = 0.7
    var dur: Double = 1.0
    var voice: ToneVoice = .piano
}

@MainActor
final class ToneSynth {
    static let shared = ToneSynth()

    /// Master level (0…1).
    var volume: Float = 0.9 { didSet { engine?.mainMixerNode.outputVolume = volume } }

    private let sr: Double = 44_100
    private let voices = 8
    private var engine: AVAudioEngine?
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private var cache: [Int: [Float]] = [:]
    private var active = false
    private var busyUntil = Date.distantPast
    private var idleCheck: DispatchWorkItem?
    private lazy var format = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1)!

    /// A Theatre game appeared: claim the audio session and build the graph (not started yet).
    func start() {
        guard !active else { return }
        active = true
        let s = AVAudioSession.sharedInstance()
        // .playback (not .ambient): these games are unplayable muted, and children often leave the
        // silent switch on. Mixes with other audio; released again in stop().
        try? s.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? s.setActive(true)
        if engine == nil { build() }
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SYNTH_TEST"] != nil { selfTest() }
        #endif
    }

    /// The game closed: silence everything, stop the engine and release the session.
    func stop() {
        guard active else { return }
        active = false
        idleCheck?.cancel()
        players.forEach { $0.stop() }
        engine?.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Cut off whatever is sounding (e.g. moving on to the next question).
    func silence() {
        guard engine?.isRunning == true else { return }
        players.forEach { $0.stop() }
        busyUntil = .distantPast
    }

    /// Is something (that this synth scheduled) still sounding?
    var isSounding: Bool { Date() < busyUntil }

    // MARK: Playing

    /// Plays a list of events as one sound. Returns the musical length in seconds (when the last
    /// held note is released — not counting the ring-out), so callers can wait for it to finish.
    @discardableResult
    func play(_ events: [ToneEvent]) -> Double {
        let length = events.map { $0.at + $0.dur }.max() ?? 0
        guard active, !events.isEmpty, let engine else { return length }
        if !engine.isRunning {
            do { try engine.start() } catch { return length }
        }
        let samples = render(events)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else { return length }
        buf.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { src in
            buf.floatChannelData![0].update(from: src.baseAddress!, count: samples.count)
        }
        let p = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        p.scheduleBuffer(buf, at: nil, options: .interrupts)
        p.play()
        busyUntil = max(busyUntil, Date().addingTimeInterval(length))
        scheduleIdlePause(after: Double(samples.count) / sr + 4)
        return length
    }

    @discardableResult
    func note(_ midi: Int, vel: Float = 0.7, dur: Double = 0.9) -> Double {
        play([ToneEvent(midi: midi, vel: vel, dur: dur)])
    }

    /// A chord; `roll` spreads the notes a little, low to high, like a strummed/rolled chord.
    @discardableResult
    func chord(_ midis: [Int], vel: Float = 0.6, dur: Double = 1.4, roll: Double = 0) -> Double {
        play(midis.sorted().enumerated().map { ToneEvent(at: Double($0.offset) * roll, midi: $0.element, vel: vel, dur: dur) })
    }

    /// A tune: one note per beat at `bpm` (`nil` = a rest).
    @discardableResult
    func sequence(_ midis: [Int?], bpm: Double, vel: Float = 0.7) -> Double {
        let beat = 60 / bpm
        var ev: [ToneEvent] = []
        for (i, m) in midis.enumerated() { if let m { ev.append(ToneEvent(at: Double(i) * beat, midi: m, vel: vel, dur: beat * 0.95)) } }
        return play(ev)
    }

    // MARK: Engine

    private func build() {
        let e = AVAudioEngine()
        for _ in 0..<voices {
            let p = AVAudioPlayerNode()
            e.attach(p)
            e.connect(p, to: e.mainMixerNode, format: format)
            players.append(p)
        }
        e.mainMixerNode.outputVolume = volume
        e.prepare()
        engine = e
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SYNTH_LOG"] != nil { installMeter(e) }
        #endif
    }

    /// Pause the engine once nothing has sounded for a while (it restarts on the next note).
    private func scheduleIdlePause(after s: Double) {
        idleCheck?.cancel()
        let w = DispatchWorkItem { [weak self] in
            guard let self, let e = self.engine, e.isRunning, !self.isSounding else { return }
            self.players.forEach { $0.stop() }
            e.pause()
            #if DEBUG
            if ProcessInfo.processInfo.environment["LUDUS_SYNTH_LOG"] != nil { NSLog("ToneSynth: idle, engine paused") }
            #endif
        }
        idleCheck = w
        DispatchQueue.main.asyncAfter(deadline: .now() + s, execute: w)
    }

    // MARK: Synthesis

    private func samples(_ voice: ToneVoice, _ midi: Int) -> [Float] {
        let k = voice.rawValue * 1000 + midi
        if let s = cache[k] { return s }
        let s = voice == .drum ? Self.synthDrum(sr: sr) : Self.synthPiano(midi: midi, sr: sr)
        cache[k] = s
        return s
    }

    /// Mixes events into one mono buffer (each note cut at its `dur` with a short damper fade).
    private func render(_ events: [ToneEvent]) -> [Float] {
        let release = 0.08
        var total = 0
        var parts: [(start: Int, n: Int, src: [Float], gain: Float)] = []
        for e in events {
            let src = samples(e.voice, e.midi)
            let n = min(src.count, Int((e.dur + release) * sr))
            let start = Int(e.at * sr)
            parts.append((start, n, src, max(0, min(1, e.vel)) * 0.32))
            total = max(total, start + n)
        }
        var out = [Float](repeating: 0, count: total)
        let fadeN = Int(release * sr)
        out.withUnsafeMutableBufferPointer { o in
            for p in parts {
                var seg = Array(p.src[0..<p.n])
                if p.n < p.src.count {        // damped early: fade the tail out
                    let f0 = max(0, p.n - fadeN)
                    for i in f0..<p.n { seg[i] *= Float(p.n - i) / Float(p.n - f0) }
                }
                var g = p.gain
                vDSP_vsma(seg, 1, &g, o.baseAddress! + p.start, 1, o.baseAddress! + p.start, 1, vDSP_Length(p.n))
            }
            var peak: Float = 0
            vDSP_maxmgv(o.baseAddress!, 1, &peak, vDSP_Length(total))
            if peak > 0.95 {
                var k = 0.95 / peak
                vDSP_vsmul(o.baseAddress!, 1, &k, o.baseAddress!, 1, vDSP_Length(total))
            }
        }
        return out
    }

    /// Piano-ish: six harmonics falling off in strength, each decaying in two stages (a quick
    /// "pluck" drop, then a slower ring; higher harmonics die faster), 3 ms attack, peak-normalised.
    nonisolated static func synthPiano(midi: Int, sr: Double) -> [Float] {
        let f = 440 * pow(2, Double(midi - 69) / 12)
        let len = Int(sr * 1.8), n = vDSP_Length(len)
        var n32 = Int32(len)
        let t = UnsafeMutablePointer<Float>.allocate(capacity: len), ph = UnsafeMutablePointer<Float>.allocate(capacity: len)
        let env = UnsafeMutablePointer<Float>.allocate(capacity: len), tmp = UnsafeMutablePointer<Float>.allocate(capacity: len)
        defer { t.deallocate(); ph.deallocate(); env.deallocate(); tmp.deallocate() }
        var out = [Float](repeating: 0, count: len)
        var t0: Float = 0, dt = Float(1 / sr)
        vDSP_vramp(&t0, &dt, t, 1, n)
        let ring = 0.75 * pow(261.6 / f, 0.4)            // low notes ring longer
        let harm: [(Double, Float)] = [(1, 1), (2, 0.5), (3, 0.25), (4, 0.14), (5, 0.07), (6, 0.035)]
        out.withUnsafeMutableBufferPointer { o in
            let op = o.baseAddress!
            for (h, a) in harm where f * h < sr * 0.45 {
                var w = Float(2 * Double.pi * f * h)
                vDSP_vsmul(t, 1, &w, tmp, 1, n)
                vvsinf(ph, tmp, &n32)
                let slow = Float(ring / (1 + 0.7 * (h - 1))), fast = Float(0.09 / (1 + 0.3 * (h - 1)))
                var ks = -1 / slow, kf = -1 / fast
                vDSP_vsmul(t, 1, &ks, tmp, 1, n); vvexpf(env, tmp, &n32)          // slow ring
                vDSP_vsmul(t, 1, &kf, tmp, 1, n); vvexpf(tmp, tmp, &n32)          // quick pluck
                var c1: Float = 0.45, c2: Float = 0.55
                vDSP_vsmul(env, 1, &c1, env, 1, n)
                vDSP_vsma(tmp, 1, &c2, env, 1, env, 1, n)
                vDSP_vmul(ph, 1, env, 1, ph, 1, n)
                var amp = a
                vDSP_vsma(ph, 1, &amp, op, 1, op, 1, n)
            }
            let att = Int(0.003 * sr), rel = Int(0.05 * sr)
            for i in 0..<att { op[i] *= Float(i) / Float(att) }
            for i in (len - rel)..<len { op[i] *= Float(len - i) / Float(rel) }
            var peak: Float = 0
            vDSP_maxmgv(op, 1, &peak, n)
            if peak > 0 { var k = 1 / peak; vDSP_vsmul(op, 1, &k, op, 1, n) }
        }
        return out
    }

    /// A soft kick drum: a sine sweeping 160 → 50 Hz under a fast decay.
    nonisolated static func synthDrum(sr: Double) -> [Float] {
        let len = Int(sr * 0.35)
        return (0..<len).map { i in
            let t = Double(i) / sr
            let phase = 2 * Double.pi * (50 * t + 110 * 0.04 * (1 - exp(-t / 0.04)))
            let a = min(1, t / 0.002) * exp(-t / 0.11)
            return Float(sin(phase) * a)
        }
    }

    // MARK: DEBUG verification (the simulator can't be listened to — prove it numerically)

    #if DEBUG
    /// LUDUS_SYNTH_LOG: a tap on the live mixer logs the RMS of what's actually being rendered.
    private func installMeter(_ e: AVAudioEngine) {
        let mixer = e.mainMixerNode
        var last = Date.distantPast
        mixer.installTap(onBus: 0, bufferSize: 4096, format: mixer.outputFormat(forBus: 0)) { buf, _ in
            guard let ch = buf.floatChannelData else { return }
            var rms: Float = 0
            vDSP_rmsqv(ch[0], 1, &rms, vDSP_Length(buf.frameLength))
            if rms > 0.002, Date().timeIntervalSince(last) > 0.25 {
                last = Date()
                NSLog("ToneSynth live mixer RMS %.4f", rms)
            }
        }
    }

    /// LUDUS_SYNTH_TEST: renders a test phrase OFFLINE through a real AVAudioEngine graph (manual
    /// rendering mode — the same player → mixer path), logs its RMS and writes it to
    /// tmp/tonesynth_selftest.wav for spectral checks (A4 alone, then a C-major chord, then a drum).
    private func selfTest() {
        let events = [ToneEvent(at: 0, midi: 69, vel: 0.8, dur: 0.9)]
            + [60, 64, 67].map { ToneEvent(at: 1.2, midi: $0, vel: 0.6, dur: 1.0) }
            + [ToneEvent(at: 2.6, midi: 0, vel: 1, dur: 0.3, voice: .drum)]
        let samples = render(events)
        let e = AVAudioEngine()
        let p = AVAudioPlayerNode()
        e.attach(p)
        e.connect(p, to: e.mainMixerNode, format: format)
        let outFmt = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1)!
        do {
            try e.enableManualRenderingMode(.offline, format: outFmt, maximumFrameCount: 4096)
            try e.start()
            let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
            buf.frameLength = AVAudioFrameCount(samples.count)
            samples.withUnsafeBufferPointer { buf.floatChannelData![0].update(from: $0.baseAddress!, count: samples.count) }
            p.scheduleBuffer(buf)
            p.play()
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("tonesynth_selftest.wav")
            let file = try AVAudioFile(forWriting: url, settings: outFmt.settings)
            let chunk = AVAudioPCMBuffer(pcmFormat: e.manualRenderingFormat, frameCapacity: 4096)!
            var sumSq: Double = 0, frames = 0
            while frames < samples.count {
                let n = AVAudioFrameCount(min(4096, samples.count - frames))
                guard try e.renderOffline(n, to: chunk) == .success else { break }
                var ss: Float = 0
                vDSP_svesq(chunk.floatChannelData![0], 1, &ss, vDSP_Length(chunk.frameLength))
                sumSq += Double(ss); frames += Int(chunk.frameLength)
                try file.write(from: chunk)
            }
            e.stop()
            NSLog("ToneSynth self-test: rendered %d frames offline, RMS %.4f, wav at %@", frames,
                  sqrt(sumSq / Double(max(frames, 1))), url.path)
        } catch {
            NSLog("ToneSynth self-test FAILED: %@", "\(error)")
        }
    }
    #endif
}
