import QuartzCore
import SwiftUI

// MARK: - Galley Drum (Theatre · Music) — steady beat & rhythm
//
// A Roman galley rows across the sunset sea, and YOU are the drummer who keeps the rowers in
// time. Captain Brutus counts you in on his woodblock — "1, 2, 3, 4!" — and you beat the big drum:
//   • KEEP THE BEAT: tap on every click, with the drum skin glowing on the beat at first;
//   • ECHO: the captain drums a rhythm, then you drum it straight back (call and response), with
//     the rhythm shown as cards in the classroom syllables (ta = 1 beat, ti-ti = 2 halves, sh = rest).
// Every tap sounds the drum; a good bar makes the oars sweep and the ship surge. A miss marks the
// beats you missed (or the extra taps), and the captain plays the rhythm again while the cards
// light up, so the ear and eye both get the answer.
//
// Timing is judged against the audio clock: ToneSynth.playTimed returns when the first click
// actually reaches the speaker (output latency included), and taps are stamped with
// CACurrentMediaTime on touch-down.
//
// Continuous ladder (all off `d`):
//   tempo 76 → 112 bpm; timing window ±0.20 s → ±0.09 s (never more than 45% of the gap);
//   1    keep a steady beat, 4 taps, the drum glows on every beat
//   ~1.8 the glow fades; 4 → 8 beats
//   2.6  echo: ta and sh (quarters and rests)
//   3.8  + ti-ti (eighths)
//   5    + ta-a (a 2-beat note), two-bar echoes fade in from 5.5
//   6    the cards start to hide (echo by ear alone, ~80% by 9)
//   7.5  + tika-tika (sixteenths)
//   8.5  + ti-ta-ti (syncopation)

private struct GDCell: Equatable {
    let label: String
    let onsets: [Double]     // within the cell, in beats
    let beats: Int
    static let ta = GDCell(label: "ta", onsets: [0], beats: 1)
    static let sh = GDCell(label: "sh", onsets: [], beats: 1)
    static let titi = GDCell(label: "ti-ti", onsets: [0, 0.5], beats: 1)
    static let taa = GDCell(label: "ta-a", onsets: [0], beats: 2)
    static let tika = GDCell(label: "tika-tika", onsets: [0, 0.25, 0.5, 0.75], beats: 1)
    static let synco = GDCell(label: "ti-ta-ti", onsets: [0, 0.5, 1.5], beats: 2)
}

private struct GDRound {
    var echo: Bool
    var cells: [GDCell]
    var bpm: Double
    var guide: Bool          // the drum glows on each beat of your turn
    var showCards: Bool
    var beatsLong: Int { cells.reduce(0) { $0 + $1.beats } }
    /// Onsets (in beats from the start of the phrase).
    var onsets: [Double] {
        var b = 0.0, out: [Double] = []
        for c in cells { out += c.onsets.map { b + $0 }; b += Double(c.beats) }
        return out
    }
}

private enum GDStage: Equatable { case idle, countIn, captain, yours, judged }

@MainActor
private final class GalleyModel: ArcadeModel {
    @Published var round = GDRound(echo: false, cells: Array(repeating: .ta, count: 4), bpm: 80, guide: true, showCards: true)
    @Published var stage = GDStage.idle
    @Published var t0 = 0.0                 // media time of the first count-in click
    @Published var hitOnsets: Set<Int> = [] // your onsets matched so far
    @Published var missedOnsets: Set<Int> = []
    @Published var extras = 0
    @Published var strokes = 0              // each good tap pulls the oars
    @Published var surge = 0                // each good bar
    @Published var skin = 0                 // each tap thumps the skin
    @Published var lesson: String?
    @Published var demo = false             // the captain is replaying the right rhythm
    @Published var demoT0 = 0.0
    @Published var distance = 0.0
    private var expected: [Double] = []     // media times of your onsets
    private var window = 0.2
    private var token = 0
    private var botPlanned = -1

    init() { super.init(key: GameID.galleyDrum.rawValue) }
    override func perLevel(_ level: Int) -> Int { 5 }
    override func onBegin() { distance = 0; next(after: 0.8) }

    var beat: Double { 60 / round.bpm }
    /// Where your turn starts (in beats from t0): after the 4-click count-in, and after the captain's phrase when echoing.
    var yourStart: Double { 4 + (round.echo ? Double(round.beatsLong) : 0) }

    func makeRound() -> GDRound {
        let bpm = ramp(76, 112, to: 9)
        let kind = tier([1, 2.6], fadeIn: 1.2, keep: 0.25)
        if kind == 0 {
            let n = rampInt(4, 8, from: 1.5, to: 3) >= 6 ? 8 : 4
            return GDRound(echo: false, cells: Array(repeating: .ta, count: n), bpm: bpm,
                           guide: Double.random(in: 0..<1) < ramp(1, 0, from: 1.6, to: 3), showCards: true)
        }
        // Echo: fill 4 (or 8) beats with cells whose kinds fade in with d.
        let bars = chance(0.6, from: 5.5, to: 8) ? 2 : 1
        var pool: [(GDCell, Double)] = [(.ta, 3), (.sh, 1.2)]
        pool.append((.titi, ramp(0, 2.5, from: 3.8, to: 5)))
        pool.append((.taa, ramp(0, 1, from: 5, to: 6)))
        pool.append((.tika, ramp(0, 1.4, from: 7.5, to: 8.5)))
        pool.append((.synco, ramp(0, 1.2, from: 8.5, to: 9.5)))
        func draw(maxBeats: Int) -> GDCell {
            let ok = pool.filter { $0.0.beats <= maxBeats && $0.1 > 0 }
            var r = Double.random(in: 0..<ok.reduce(0) { $0 + $1.1 })
            for (c, w) in ok { if r < w { return c }; r -= w }
            return .ta
        }
        var cells: [GDCell] = []
        for _ in 0..<12 {
            cells = []
            var left = 4 * bars
            while left > 0 { let c = draw(maxBeats: left); cells.append(c); left -= c.beats }
            let onsets = cells.reduce(0) { $0 + $1.onsets.count }
            let allTa = cells.allSatisfy { $0 == .ta }
            // Start on a sound while young; at least 2 sounds; not just "ta ta ta ta" once rests exist.
            if (d < 6 && cells.first == .sh) || onsets < 2 || (allTa && d > 3) || cells.filter({ $0 == .sh }).count > bars + 0 { continue }
            break
        }
        return GDRound(echo: true, cells: cells, bpm: bpm, guide: false,
                       showCards: Double.random(in: 0..<1) >= ramp(0, 0.8, from: 6, to: 9))
    }

    func next(after delay: Double) {
        token += 1
        let tok = token
        stage = .idle
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.phase == .playing, self.token == tok else { return }
            self.start()
        }
    }

    private func start() {
        round = makeRound()
        hitOnsets = []; missedOnsets = []; extras = 0; lesson = nil; demo = false
        let b = beat
        var ev: [ToneEvent] = []
        for i in 0..<4 { ev.append(ToneEvent(at: Double(i) * b, midi: i == 0 ? 88 : 81, vel: 0.9, dur: 0.08, voice: .block)) }
        if round.echo {
            for o in round.onsets { ev.append(ToneEvent(at: (4 + o) * b, midi: 43, vel: 0.9, dur: 0.5, voice: .tom)) }
            for i in 0..<round.beatsLong { ev.append(ToneEvent(at: Double(4 + i) * b, midi: i % 4 == 0 ? 88 : 81, vel: 0.35, dur: 0.08, voice: .block)) }
        }
        // The click carries on under your turn (softer), so there's always a pulse to lock to.
        let ys = Int(yourStart)
        for i in 0..<round.beatsLong { ev.append(ToneEvent(at: Double(ys + i) * b, midi: i % 4 == 0 ? 88 : 81, vel: 0.45, dur: 0.08, voice: .block)) }
        // Window: from ±0.20 s to ±0.09 s, and never so wide that two onsets share it.
        let gaps = zip(round.onsets.dropFirst(), round.onsets).map { ($0 - $1) * b }
        window = min(ramp(0.2, 0.09, to: 9), (gaps.min() ?? 1) * 0.45)
        t0 = ToneSynth.shared.playTimed(ev, lead: 0.15)
        expected = round.onsets.map { t0 + (yourStart + $0) * b }
        stage = .countIn
        let now = CACurrentMediaTime()
        let tok = token
        func at(_ t: Double, _ f: @escaping () -> Void) {
            DispatchQueue.main.asyncAfter(deadline: .now() + max(0, t - now)) { [weak self] in
                guard let self, self.phase == .playing, self.token == tok else { return }
                f()
            }
        }
        if round.echo { at(t0 + 4 * b - 0.05) { self.stage = .captain } }
        at(t0 + yourStart * b - window - 0.02) { self.stage = .yours }
        at((expected.last ?? t0) + window + 0.15) { self.judge() }
    }

    /// A tap on the drum (touch-down time on the media clock).
    func tap(at t: Double) {
        guard phase == .playing else { return }
        ToneSynth.shared.play([ToneEvent(midi: 45, vel: 0.95, dur: 0.5, voice: .tom)])
        skin += 1
        Haptics.tap(0.7)
        guard stage == .yours else { return }
        // Match the nearest not-yet-hit onset inside the window.
        var best: Int?
        for (i, e) in expected.enumerated() where !hitOnsets.contains(i) && abs(t - e) <= window {
            if best == nil || abs(t - e) < abs(t - expected[best!]) { best = i }
        }
        if let i = best {
            hitOnsets.insert(i)
            strokes += 1
        } else {
            extras += 1
        }
    }

    private func judge() {
        guard stage == .yours || stage == .countIn || stage == .captain else { return }
        stage = .judged
        let missed = Set(expected.indices).subtracting(hitOnsets)
        // Very young drummers: a stray extra tap is forgiven at first.
        let extraOK = d < 2.2 ? 1 : 0
        if missed.isEmpty && extras <= extraOK {
            surge += 1
            distance += 1
            Sfx.play(.whoosh, volume: 0.6)
            hit()
            next(after: 0.9)
            return
        }
        missedOnsets = missed
        if !missed.isEmpty {
            lesson = round.echo ? "Listen again: " + round.cells.map(\.label).joined(separator: " · ")
                                : (missed.count == expected.count ? "Tap the drum on every click!" : "Keep going on every beat — \(missed.count) missed")
        } else {
            lesson = "Too many taps — only drum on the sounds"
        }
        let lastHeart = miss(delay: 2.5)
        // The captain plays it again (cards lighting up) so the right rhythm is heard.
        let b = beat
        var ev: [ToneEvent] = []
        for o in round.onsets { ev.append(ToneEvent(at: o * b, midi: 43, vel: 0.9, dur: 0.5, voice: .tom)) }
        for i in 0..<round.beatsLong { ev.append(ToneEvent(at: Double(i) * b, midi: 81, vel: 0.3, dur: 0.08, voice: .block)) }
        let tok = token
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self, self.phase == .playing, self.token == tok else { return }
            self.demoT0 = ToneSynth.shared.playTimed(ev, lead: 0.1)
            self.demo = true
            guard !lastHeart else { return }
            self.next(after: 0.1 + Double(self.round.beatsLong) * b + 1.0)
        }
    }

    // MARK: Bot — drums the phrase on the audio clock (right, or with one beat skipped)

    override func botAct(correct: Bool) {
        guard phase == .playing, stage == .countIn || stage == .captain, botPlanned != token else { return }
        botPlanned = token
        var times = expected
        if !correct, !times.isEmpty { times.remove(at: Int.random(in: 0..<times.count)) }
        let now = CACurrentMediaTime()
        for t in times {
            let when = t + Double.random(in: -0.025...0.025)
            DispatchQueue.main.asyncAfter(deadline: .now() + max(0, when - now)) { [weak self] in
                self?.tap(at: CACurrentMediaTime())
            }
        }
    }
}

// MARK: View

struct GalleyDrumView: View {
    let onClose: () -> Void
    @StateObject private var model = GalleyModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.galleyDrum.spec!, accent: Lu.tangerine, onClose: onClose,
                    backdrop: { GDSea() }) {
            VStack(spacing: 6) {
                Color.clear.frame(height: 58)
                GDShip(model: model).frame(height: 230)
                GDCards(model: model).frame(height: 92)
                ZStack {
                    if let l = model.lesson {
                        Text(l).font(luFont(16, .heavy)).foregroundStyle(Color(hex: 0xffe6a0))
                            .multilineTextAlignment(.center).minimumScaleFactor(0.6).lineLimit(2)
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(Capsule().fill(Color.black.opacity(0.5)))
                    } else {
                        SoundHint()
                    }
                }
                .frame(height: 44)
                Spacer(minLength: 0)
                GDDrum(model: model).frame(height: 250).padding(.bottom, 4)
            }
            .padding(.horizontal, 12)
        }
        .theatreSound(playing: model.phase == .playing)
    }
}

/// The sunset sea: a warm sky, a low sun, and rolling bands of waves (they scroll with the ship).
private struct GDSea: View {
    var body: some View {
        GeometryReader { g in
            let h = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0x2a2a6a), Color(hex: 0xc06070), Color(hex: 0xf4a860)], startPoint: .top, endPoint: .init(x: 0.5, y: 0.42))
                Circle().fill(RadialGradient(colors: [Color(hex: 0xfff0b0), Color(hex: 0xffb050).opacity(0.0)], center: .center, startRadius: 20, endRadius: 90))
                    .frame(width: 180, height: 180).position(x: g.size.width * 0.72, y: h * 0.33)
                LinearGradient(colors: [Color(hex: 0x2a5a8a), Color(hex: 0x123050), Color(hex: 0x0a1a30)], startPoint: .top, endPoint: .bottom)
                    .frame(height: h * 0.6).position(x: g.size.width / 2, y: h * 0.7)
            }
        }
    }
}

/// The galley: a hull with a curled stern, a striped sail, rowers' heads along the rail, oars
/// that sweep on every good beat, and Captain Brutus on the stern deck counting you in.
private struct GDShip: View {
    @ObservedObject var model: GalleyModel
    @State private var oar = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: model.phase != .playing)) { tl in
            let now = CACurrentMediaTime()
            let t = tl.date.timeIntervalSinceReferenceDate
            GeometryReader { g in
                let w = g.size.width, h = g.size.height
                ZStack {
                    // Waves scrolling past (faster as the ship goes farther)
                    Canvas { c, s in
                        let speed = 30 + min(60, model.distance * 3)
                        for row in 0..<3 {
                            let y = s.height * (0.72 + Double(row) * 0.1)
                            let shift = (t * speed * (1 + Double(row) * 0.4)).truncatingRemainder(dividingBy: 60)
                            var p = Path()
                            var x = -60 - shift
                            p.move(to: CGPoint(x: x, y: y))
                            while x < s.width + 60 {
                                p.addQuadCurve(to: CGPoint(x: x + 30, y: y), control: CGPoint(x: x + 15, y: y - 7))
                                p.addQuadCurve(to: CGPoint(x: x + 60, y: y), control: CGPoint(x: x + 45, y: y + 5))
                                x += 60
                            }
                            c.stroke(p, with: .color(.white.opacity(0.25 - Double(row) * 0.05)), lineWidth: 2)
                        }
                    }
                    let bob = sin(t * 1.6) * 3
                    ZStack {
                        GDHull().fill(LinearGradient(colors: [Color(hex: 0x8a4a22), Color(hex: 0x4a220e)], startPoint: .top, endPoint: .bottom))
                            .frame(width: w * 0.86, height: h * 0.26)
                            .position(x: w * 0.5, y: h * 0.66)
                        // Eye on the bow (Roman ships wore one)
                        Circle().fill(.white).frame(width: 12, height: 12).overlay(Circle().fill(.black).frame(width: 6)).position(x: w * 0.86, y: h * 0.63)
                        // Mast + sail
                        Rectangle().fill(Color(hex: 0x5a3216)).frame(width: 6, height: h * 0.55).position(x: w * 0.48, y: h * 0.3)
                        GDSail().fill(LinearGradient(colors: [Color(hex: 0xf3e3c0), Color(hex: 0xd8c098)], startPoint: .top, endPoint: .bottom))
                            .overlay(GDSail().stroke(Color(hex: 0x8a5a2a), lineWidth: 1.5))
                            .overlay(HStack(spacing: 14) { ForEach(0..<3, id: \.self) { _ in Rectangle().fill(Color(hex: 0xb83a2a)).frame(width: 9) } }.mask(GDSail()))
                            .frame(width: w * 0.36, height: h * 0.36)
                            .position(x: w * 0.48, y: h * 0.27)
                        // Rowers' heads
                        HStack(spacing: w * 0.045) {
                            ForEach(0..<7, id: \.self) { i in
                                Circle().fill(Color(hex: 0xe0a070)).frame(width: 14, height: 14)
                                    .overlay(alignment: .top) { Capsule().fill(Color(hex: 0x3a2010)).frame(width: 14, height: 6) }
                                    .offset(x: oar ? 3 : -3)
                            }
                        }
                        .position(x: w * 0.47, y: h * 0.53)
                        // Oars
                        HStack(spacing: w * 0.045 + 10) {
                            ForEach(0..<7, id: \.self) { _ in
                                Capsule().fill(Color(hex: 0xc89a5a)).frame(width: 4, height: h * 0.34)
                                    .rotationEffect(.degrees(oar ? -32 : 26), anchor: .top)
                            }
                        }
                        .position(x: w * 0.47, y: h * 0.78)
                        // Captain Brutus on the stern
                        GDCaptain(calling: model.stage == .countIn || model.stage == .captain || model.demo)
                            .frame(width: 54, height: 66)
                            .position(x: w * 0.13, y: h * 0.42)
                        bubble(now: now).position(x: w * 0.25, y: h * 0.12)
                    }
                    .offset(y: bob)
                }
            }
        }
        .onChange(of: model.strokes) { _ in
            withAnimation(.easeOut(duration: 0.12)) { oar.toggle() }
        }
    }

    /// The captain's speech: the count-in numbers, "Listen!" during his phrase, "Your turn!".
    @ViewBuilder private func bubble(now: Double) -> some View {
        let b = model.beat
        let beatNow = (now - model.t0) / b
        let text: String? = {
            switch model.stage {
            case .countIn: return beatNow < 0 ? "Ready…" : "\(min(4, Int(beatNow) + 1))!"
            case .captain: return "Listen!"
            case .yours: return model.round.echo ? "Your turn!" : "Drum!"
            case .judged: return model.demo ? "Like this!" : (model.lesson == nil ? "Bene! 👍" : nil)
            case .idle: return nil
            }
        }()
        if let text {
            Text(text).font(luFont(20, .black)).foregroundStyle(Color(hex: Lu.inkDark))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 14).fill(.white))
                .overlay(alignment: .bottomLeading) {
                    Triangle().fill(.white).frame(width: 14, height: 12).rotationEffect(.degrees(180)).offset(x: 12, y: 10)
                }
        }
    }
}

private struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path(); p.move(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.closeSubpath(); return p
    }
}

private struct GDHull: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.02, y: r.minY - r.height * 0.6))     // curled stern post
        p.addQuadCurve(to: CGPoint(x: r.minX + r.width * 0.12, y: r.minY), control: CGPoint(x: r.minX - r.width * 0.04, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.02, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - r.width * 0.12, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY * 0.98))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.16, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX + r.width * 0.02, y: r.minY - r.height * 0.6), control: CGPoint(x: r.minX + r.width * 0.02, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct GDSail: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - r.width * 0.06, y: r.maxY), control: CGPoint(x: r.maxX + r.width * 0.1, y: r.midY))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.06, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY), control: CGPoint(x: r.minX + r.width * 0.16, y: r.midY))
        p.closeSubpath()
        return p
    }
}

/// Captain Brutus: a round face under a bronze helmet with a red crest; his mouth opens to call.
private struct GDCaptain: View {
    var calling: Bool
    var body: some View {
        Canvas { c, s in
            let w = s.width, h = s.height
            // Body (red tunic)
            c.fill(Path(roundedRect: CGRect(x: w * 0.18, y: h * 0.58, width: w * 0.64, height: h * 0.42), cornerRadius: 10), with: .color(Color(hex: 0xb8302a)))
            // Face
            c.fill(Path(ellipseIn: CGRect(x: w * 0.17, y: h * 0.22, width: w * 0.66, height: h * 0.44)), with: .color(Color(hex: 0xf0c090)))
            // Helmet + crest
            var helm = Path()
            helm.addArc(center: CGPoint(x: w * 0.5, y: h * 0.36), radius: w * 0.36, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            helm.closeSubpath()
            c.fill(helm, with: .linearGradient(Gradient(colors: [Color(hex: 0xf0c060), Color(hex: 0xa07020)]), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: w, y: h * 0.4)))
            var crest = Path()
            crest.addArc(center: CGPoint(x: w * 0.5, y: h * 0.2), radius: w * 0.3, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            c.stroke(crest, with: .color(Color(hex: 0xd83a2a)), style: StrokeStyle(lineWidth: w * 0.14, lineCap: .round))
            // Eyes, beard, mouth
            c.fill(Path(ellipseIn: CGRect(x: w * 0.34, y: h * 0.4, width: w * 0.08, height: h * 0.07)), with: .color(.black))
            c.fill(Path(ellipseIn: CGRect(x: w * 0.58, y: h * 0.4, width: w * 0.08, height: h * 0.07)), with: .color(.black))
            c.fill(Path(ellipseIn: CGRect(x: w * 0.24, y: h * 0.5, width: w * 0.52, height: h * 0.2)), with: .color(Color(hex: 0x6a3a1a)))
            let mh = calling ? h * 0.1 : h * 0.03
            c.fill(Path(ellipseIn: CGRect(x: w * 0.42, y: h * 0.54, width: w * 0.16, height: mh)), with: .color(Color(hex: 0x3a0a0a)))
        }
    }
}

/// The rhythm as cards: each cell is as wide as its beats, with a drum dot on every sound and its
/// syllable underneath. The cell sounding now is lit (captain's phrase, your turn, the replay).
private struct GDCards: View {
    @ObservedObject var model: GalleyModel

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: model.phase != .playing || model.stage == .idle)) { _ in
            let now = CACurrentMediaTime()
            let r = model.round
            let total = Double(r.beatsLong)
            let starts = r.cells.indices.map { i in Double(r.cells[..<i].reduce(0) { $0 + $1.beats }) }
            // Which beat (within the phrase) is sounding now, if any.
            let pos: Double? = {
                let b = model.beat
                if model.demo { return (now - model.demoT0) / b }
                switch model.stage {
                case .captain: return (now - model.t0) / b - 4
                case .yours: return (now - model.t0) / b - model.yourStart
                default: return nil
                }
            }()
            let onsetIdx = cellOnsetIndices(r)
            GeometryReader { g in
                HStack(spacing: 6) {
                    ForEach(Array(r.cells.enumerated()), id: \.offset) { i, c in
                        let lit = pos.map { $0 >= starts[i] && $0 < starts[i] + Double(c.beats) } ?? false
                        let hidden = !r.showCards && !model.demo && model.stage != .judged
                        card(c, lit: lit, hidden: hidden, onsetIdx: onsetIdx[i])
                            .frame(width: max(10, (g.size.width - 6 * CGFloat(r.cells.count - 1)) * CGFloat(Double(c.beats) / total)))
                    }
                }
            }
        }
    }

    private func cellOnsetIndices(_ r: GDRound) -> [[Int]] {
        var k = 0
        return r.cells.map { c in defer { k += c.onsets.count }; return Array(k..<(k + c.onsets.count)) }
    }

    private func card(_ c: GDCell, lit: Bool, hidden: Bool, onsetIdx: [Int]) -> some View {
        let small = model.round.cells.count > 6
        return VStack(spacing: 4) {
            if hidden {
                Text("?").font(luFont(30, .black)).foregroundStyle(Color(hex: 0x6a4a28))
            } else {
                GeometryReader { g in
                    ZStack {
                        if c == .taa {        // a long sound: the dot rings on across both beats
                            Capsule().fill(Color(hex: 0x5a3216).opacity(0.6)).frame(width: g.size.width * 0.62, height: 6)
                                .position(x: g.size.width * 0.31 + dot(c), y: g.size.height / 2)
                        }
                        if c.onsets.isEmpty {
                            Text("🤫").font(.system(size: small ? 20 : 26)).position(x: g.size.width / 2, y: g.size.height / 2)
                        }
                        ForEach(Array(c.onsets.enumerated()), id: \.offset) { j, o in
                            let idx = onsetIdx[j]
                            let missed = model.missedOnsets.contains(idx)
                            let got = model.hitOnsets.contains(idx)
                            Circle()
                                .fill(Color(hex: missed ? Lu.coral : (got ? Lu.mint : 0x5a3216)))
                                .frame(width: dot(c), height: dot(c))
                                .position(x: g.size.width * CGFloat((o + 0.5 / Double(max(1, c.onsets.count)) * (c.beats == 1 ? 1 : 0)) / Double(c.beats)) + (c.beats > 1 ? dot(c) : 0),
                                          y: g.size.height / 2)
                        }
                    }
                }
            }
            Text(hidden ? " " : c.label).font(luFont(small ? 11 : 14, .black)).foregroundStyle(Color(hex: 0x4a2a10))
                .lineLimit(1).minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 6).padding(.horizontal, 2)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: lit ? 0xffe08a : 0xf3e6c8)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: lit ? Lu.tangerine : 0x8a6a48), lineWidth: lit ? 3 : 1.5))
        .scaleEffect(lit ? 1.06 : 1)
    }

    private func dot(_ c: GDCell) -> CGFloat { c.onsets.count >= 4 ? 10 : (c.onsets.count >= 2 ? 15 : 22) }
}

/// The big drum: tap anywhere on it. The skin glows on each beat of your turn while `guide` is
/// on, and thumps (squashes) on every tap.
private struct GDDrum: View {
    @ObservedObject var model: GalleyModel
    @State private var squash = false
    @State private var down = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: model.phase != .playing || model.stage == .idle)) { _ in
            let now = CACurrentMediaTime()
            let glow: Double = {
                guard model.round.guide, model.stage == .yours || model.stage == .countIn else { return 0 }
                let p = (now - model.t0) / model.beat
                guard p >= -0.1 else { return 0 }
                let f = p - p.rounded()
                return max(0, 1 - abs(f) * 5)
            }()
            GeometryReader { g in
                let w = min(g.size.width * 0.9, 340), h = g.size.height
                ZStack {
                    // Body
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(colors: [Color(hex: 0xa8321e), Color(hex: 0x6a1a10), Color(hex: 0xa8321e)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: w, height: h * 0.55)
                        .position(x: g.size.width / 2, y: h * 0.62)
                    // Lacing
                    Canvas { c, s in
                        let n = 10
                        var p = Path()
                        for i in 0...n {
                            let x = s.width * Double(i) / Double(n)
                            p.move(to: CGPoint(x: x, y: 4)); p.addLine(to: CGPoint(x: x + s.width / Double(n) / 2, y: s.height - 4))
                            p.move(to: CGPoint(x: x + s.width / Double(n) / 2, y: s.height - 4)); p.addLine(to: CGPoint(x: x + s.width / Double(n), y: 4))
                        }
                        c.stroke(p, with: .color(Color(hex: 0xf0dcb0)), lineWidth: 2.2)
                    }
                    .frame(width: w * 0.94, height: h * 0.4).position(x: g.size.width / 2, y: h * 0.62)
                    // Bottom hoop
                    Ellipse().stroke(Color(hex: 0xd8a850), lineWidth: 6).frame(width: w, height: h * 0.16).position(x: g.size.width / 2, y: h * 0.9).mask(Rectangle().frame(height: h * 0.1).offset(y: h * 0.42))
                    // Skin
                    Ellipse()
                        .fill(RadialGradient(colors: [Color(hex: 0xfff2d0), Color(hex: 0xe0c08a)], center: .center, startRadius: 4, endRadius: w * 0.5))
                        .overlay(Ellipse().fill(Color(hex: Lu.gold).opacity(glow * 0.75)))
                        .overlay(Ellipse().stroke(Color(hex: 0xd8a850), lineWidth: 7))
                        .frame(width: w, height: h * 0.36 * (squash ? 0.9 : 1))
                        .position(x: g.size.width / 2, y: h * 0.34)
                        .shadow(color: Color(hex: Lu.gold).opacity(glow), radius: 20)
                    Text("TAP").font(luFont(22, .black)).foregroundStyle(Color(hex: 0x8a5a2a).opacity(model.stage == .yours ? 0.9 : 0.35))
                        .position(x: g.size.width / 2, y: h * 0.34)
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !down else { return }
                        down = true
                        model.tap(at: CACurrentMediaTime())
                    }
                    .onEnded { _ in down = false })
            }
        }
        .onChange(of: model.skin) { _ in
            withAnimation(.easeOut(duration: 0.05)) { squash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) { withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { squash = false } }
        }
    }
}
