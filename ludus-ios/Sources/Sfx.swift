import AVFoundation

// MARK: - Sfx — the arcade's little sound kit (asset-free)
//
// Short synthesized effects every game can use: a bright "ding" on a right answer that climbs a
// pentatonic step with each combo, a soft, friendly "bonk" on a miss (never scary for a 7-year-old),
// a fanfare on level-up, plus pops, coins, whooshes and chomps for games to sprinkle in.
//
// Each effect is synthesized once (a few sine/noise partials with envelopes) and cached; playing one
// schedules the cached buffer on the next free node of a small pool. The engine starts lazily on the
// first sound and pauses itself when idle. Session: `.ambient` (respects the silent switch, mixes
// with other audio) unless a Theatre game has the session in `.playback` — then we just ride along.
//
// Muted with `LudusSettings.sound = false` or the LUDUS_MUTE env var (DEBUG).

enum SfxKind: Hashable {
    case correct(combo: Int)
    case wrong
    case levelUp
    case win          // a laurel earned
    case pop          // bubble / balloon
    case coin         // denarii clink
    case whoosh       // swipe / throw
    case chomp        // eating
    case tick         // a tiny UI tap
    case thud         // something lands
    case sparkle      // magic / reveal
}

enum LudusSettings {
    static let soundKey = "ludus_sound_on"
    static var sound: Bool {
        get { UserDefaults.standard.object(forKey: soundKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: soundKey) }
    }
}

@MainActor
enum Sfx {
    private static let sr: Double = 44_100
    private static var engine: AVAudioEngine?
    private static var players: [AVAudioPlayerNode] = []
    private static var next = 0
    private static var cache: [SfxKind: AVAudioPCMBuffer] = [:]
    private static var idle: DispatchWorkItem?
    private static let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

    static var muted: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_MUTE"] != nil { return true }
        #endif
        return !LudusSettings.sound
    }

    static func play(_ kind: SfxKind, volume: Float = 1) {
        guard !muted else { return }
        let key: SfxKind
        if case .correct(let c) = kind { key = .correct(combo: min(max(c, 1), 8)) } else { key = kind }
        guard let buf = buffer(key) else { return }
        guard let e = ensureEngine() else { return }
        if !e.isRunning { do { try e.start() } catch { return } }
        let p = players[next]
        next = (next + 1) % players.count
        p.volume = volume
        p.scheduleBuffer(buf, at: nil, options: .interrupts)
        p.play()
        scheduleIdle()
    }

    // MARK: Engine

    private static func ensureEngine() -> AVAudioEngine? {
        if let engine { return engine }
        let s = AVAudioSession.sharedInstance()
        if s.category != .playback {
            try? s.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        }
        try? s.setActive(true)
        let e = AVAudioEngine()
        for _ in 0..<6 {
            let p = AVAudioPlayerNode()
            e.attach(p)
            e.connect(p, to: e.mainMixerNode, format: format)
            players.append(p)
        }
        e.mainMixerNode.outputVolume = 0.8
        e.prepare()
        engine = e
        return e
    }

    private static func scheduleIdle() {
        idle?.cancel()
        let w = DispatchWorkItem {
            guard let e = engine, e.isRunning else { return }
            players.forEach { $0.stop() }
            e.pause()
        }
        idle = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: w)
    }

    // MARK: Synthesis

    private static func buffer(_ k: SfxKind) -> AVAudioPCMBuffer? {
        if let b = cache[k] { return b }
        let s = synth(k)
        guard !s.isEmpty, let b = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(s.count)) else { return nil }
        b.frameLength = AVAudioFrameCount(s.count)
        s.withUnsafeBufferPointer { b.floatChannelData![0].update(from: $0.baseAddress!, count: s.count) }
        cache[k] = b
        return b
    }

    private static func hz(_ midi: Double) -> Double { 440 * pow(2, (midi - 69) / 12) }

    /// A tone: sum of (harmonic, amp) partials, attack/decay envelope, optional pitch glide.
    private static func tone(_ out: inout [Float], at t0: Double, midi: Double, dur: Double,
                             gain: Float, partials: [(Double, Double)] = [(1, 1), (2, 0.35), (3, 0.12)],
                             attack: Double = 0.004, decay: Double = 6, glide: Double = 0) {
        let start = Int(t0 * sr), n = Int(dur * sr)
        if out.count < start + n { out += [Float](repeating: 0, count: start + n - out.count) }
        var phase = [Double](repeating: 0, count: partials.count)
        for i in 0..<n {
            let t = Double(i) / sr
            let f = hz(midi + glide * t / dur)
            let env = min(1, t / attack) * exp(-decay * t) * min(1, (dur - t) / 0.01)
            var v = 0.0
            for (j, p) in partials.enumerated() {
                phase[j] += 2 * .pi * f * p.0 / sr
                v += sin(phase[j]) * p.1
            }
            out[start + i] += Float(v * env) * gain
        }
    }

    private static func noise(_ out: inout [Float], at t0: Double, dur: Double, gain: Float,
                              decay: Double = 20, lowpass: Double = 0.3) {
        let start = Int(t0 * sr), n = Int(dur * sr)
        if out.count < start + n { out += [Float](repeating: 0, count: start + n - out.count) }
        var y = 0.0
        for i in 0..<n {
            let t = Double(i) / sr
            let x = Double.random(in: -1...1)
            y += lowpass * (x - y)
            let env = min(1, t / 0.003) * exp(-decay * t)
            out[start + i] += Float(y * env) * gain
        }
    }

    private static func synth(_ k: SfxKind) -> [Float] {
        var o: [Float] = []
        // C major pentatonic, climbing with the combo.
        let penta: [Double] = [0, 2, 4, 7, 9, 12, 14, 16]
        switch k {
        case .correct(let c):
            let base = 76 + penta[min(c, 8) - 1]
            tone(&o, at: 0, midi: base, dur: 0.18, gain: 0.32, decay: 14)
            tone(&o, at: 0.07, midi: base + 7, dur: 0.28, gain: 0.28, decay: 10)
        case .wrong:
            tone(&o, at: 0, midi: 52, dur: 0.26, gain: 0.34, partials: [(1, 1), (2, 0.2)], decay: 9, glide: -5)
            noise(&o, at: 0, dur: 0.05, gain: 0.08, decay: 60)
        case .levelUp:
            for (i, m) in [72.0, 76, 79, 84].enumerated() {
                tone(&o, at: Double(i) * 0.085, midi: m, dur: i == 3 ? 0.7 : 0.22, gain: 0.26, decay: i == 3 ? 3.5 : 9)
            }
            tone(&o, at: 0.255, midi: 88, dur: 0.6, gain: 0.12, decay: 4)
        case .win:
            for (i, m) in [67.0, 72, 76, 79, 84, 88].enumerated() {
                tone(&o, at: Double(i) * 0.09, midi: m, dur: 0.9 - Double(i) * 0.05, gain: 0.2, decay: 3)
            }
            for i in 0..<6 { tone(&o, at: 0.55 + Double(i) * 0.05, midi: 96 + Double(i % 3) * 3, dur: 0.25, gain: 0.05, partials: [(1, 1)], decay: 12) }
        case .pop:
            tone(&o, at: 0, midi: 84, dur: 0.09, gain: 0.35, partials: [(1, 1)], decay: 30, glide: 10)
            noise(&o, at: 0, dur: 0.03, gain: 0.12, decay: 120, lowpass: 0.6)
        case .coin:
            tone(&o, at: 0, midi: 95, dur: 0.12, gain: 0.18, partials: [(1, 1), (2.76, 0.5), (5.4, 0.25)], decay: 25)
            tone(&o, at: 0.06, midi: 100, dur: 0.4, gain: 0.18, partials: [(1, 1), (2.76, 0.5), (5.4, 0.25)], decay: 8)
        case .whoosh:
            noise(&o, at: 0, dur: 0.25, gain: 0.3, decay: 8, lowpass: 0.08)
        case .chomp:
            noise(&o, at: 0, dur: 0.07, gain: 0.35, decay: 50, lowpass: 0.25)
            noise(&o, at: 0.11, dur: 0.07, gain: 0.3, decay: 50, lowpass: 0.25)
            tone(&o, at: 0, midi: 45, dur: 0.08, gain: 0.25, partials: [(1, 1)], decay: 40)
        case .tick:
            tone(&o, at: 0, midi: 96, dur: 0.035, gain: 0.15, partials: [(1, 1)], decay: 80)
        case .thud:
            tone(&o, at: 0, midi: 40, dur: 0.18, gain: 0.45, partials: [(1, 1), (1.5, 0.3)], decay: 22, glide: -6)
            noise(&o, at: 0, dur: 0.06, gain: 0.12, decay: 70, lowpass: 0.15)
        case .sparkle:
            for i in 0..<5 {
                tone(&o, at: Double(i) * 0.045, midi: 88 + [0, 4, 7, 11, 14][i], dur: 0.3, gain: 0.1, partials: [(1, 1), (3, 0.2)], decay: 9)
            }
        }
        // Normalize gently so nothing clips.
        let peak = o.map { abs($0) }.max() ?? 0
        if peak > 0.9 { let g = 0.9 / peak; o = o.map { $0 * g } }
        return o
    }
}
