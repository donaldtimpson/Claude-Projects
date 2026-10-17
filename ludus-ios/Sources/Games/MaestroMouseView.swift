import SwiftUI

// MARK: - Maestro Mouse (Theatre · Music)
//
// You conduct an animal band. The composer's sign says how to play; swipe the baton UP or DOWN
// (or tap the top/bottom pad) and the band plays the way you conducted — loud or soft, fast or
// slow. A wrong wave: the mouse conductor tumbles off her box, the right pad lights up, the band
// plays it the right way and the sign's meaning is spelled out.
//
// Ladder (no clock anywhere; the band always finishes before the next sign):
//   I     the sign is a picture: 🦁 = LOUD (up) / 🐭💤 = soft (down); the pads show the same pictures
//   II    + tempo signs: 🐆 = FAST (up) / 🐌 = slow (down)
//   III   + listen first: the band plays, was it loud or soft / fast or slow? (🔁 hear again)
//   IV    Italian words: forte · piano · allegro · adagio
//   V     marks: pp p f ff, and hairpins (crescendo < = getting louder, decrescendo > = softer)
//   VI    + which is LOUDER/SOFTER (pp p mp mf f ff) or FASTER/SLOWER (largo adagio andante
//         allegro presto); fortissimo, pianissimo, presto, largo, crescendo, diminuendo
//   VII+  a score of 3 marks in a row: conduct each one in turn (4 marks from IX). Endless.

// MARK: Content

private enum MMMusic: Equatable {
    case dyn(Float)          // velocity at a normal tempo
    case tempo(Double)       // seconds per note
    case swell(Bool)         // true = crescendo, false = decrescendo
}

private enum MMSign: Equatable {
    case emoji(String)
    case word(String)
    case mark(String)        // a dynamics mark (bold italic serif)
    case hairpin(Bool)       // true = crescendo <
    case ear                 // listen first
    case ask(String, String) // "Which is LOUDER?" with an emoji
}

private struct MMPad: Equatable {
    var icon: String
    var text: String
    var mark: String? = nil  // shows a mark/word big instead of the icon (compare questions)
}

private struct MMCard: Equatable {
    let sign: MMSign
    let up: MMPad, down: MMPad
    let answerUp: Bool
    let upMusic: MMMusic, downMusic: MMMusic
    let lesson: String       // what a miss teaches
    var rightMusic: MMMusic { answerUp ? upMusic : downMusic }
}

private struct MMQuestion {
    var cards: [MMCard]
    var listen: Bool
}

private let padLoud = MMPad(icon: "🦁", text: "LOUD"), padSoft = MMPad(icon: "🐭", text: "soft")
private let padFast = MMPad(icon: "🐆", text: "FAST"), padSlow = MMPad(icon: "🐌", text: "slow")
private let padCresc = MMPad(icon: "📈", text: "getting LOUDER"), padDecresc = MMPad(icon: "📉", text: "getting softer")
private let loud = MMMusic.dyn(1.0), soft = MMMusic.dyn(0.13), fast = MMMusic.tempo(0.17), slow = MMMusic.tempo(0.6)

/// Dynamics, softest first, with their meaning and the velocity the band plays them at.
private let mmDynamics: [(mark: String, word: String, meaning: String, vel: Float)] = [
    ("pp", "pianissimo", "very soft", 0.07), ("p", "piano", "soft", 0.15), ("mp", "mezzo-piano", "medium soft", 0.28),
    ("mf", "mezzo-forte", "medium loud", 0.45), ("f", "forte", "loud", 0.75), ("ff", "fortissimo", "very loud", 1.0),
]
/// Tempo words, slowest first (seconds per note). Largo vs adagio is left out of comparisons —
/// musicians don't agree which is slower.
private let mmTempi: [(word: String, meaning: String, beat: Double)] = [
    ("largo", "very slow", 0.75), ("adagio", "slow", 0.6), ("andante", "walking pace", 0.4),
    ("allegro", "fast", 0.22), ("presto", "very fast", 0.15),
]

private func dynCard(_ sign: MMSign, loudAnswer: Bool, lesson: String) -> MMCard {
    MMCard(sign: sign, up: padLoud, down: padSoft, answerUp: loudAnswer, upMusic: loud, downMusic: soft, lesson: lesson)
}
private func tempoCard(_ sign: MMSign, fastAnswer: Bool, lesson: String) -> MMCard {
    MMCard(sign: sign, up: padFast, down: padSlow, answerUp: fastAnswer, upMusic: fast, downMusic: slow, lesson: lesson)
}
private func swellCard(_ sign: MMSign, cresc: Bool, lesson: String) -> MMCard {
    MMCard(sign: sign, up: padCresc, down: padDecresc, answerUp: cresc, upMusic: .swell(true), downMusic: .swell(false), lesson: lesson)
}

private func emojiCard(tempo: Bool) -> MMCard {
    let up = Bool.random()
    return tempo ? tempoCard(.emoji(up ? "🐆" : "🐌"), fastAnswer: up, lesson: up ? "🐆 = play FAST" : "🐌 = play slow")
                 : dynCard(.emoji(up ? "🦁" : "🐭💤"), loudAnswer: up, lesson: up ? "🦁 = play LOUD" : "🐭💤 = play soft")
}

private func wordCard(extended: Bool) -> MMCard {
    var pool: [MMCard] = [
        dynCard(.word("forte"), loudAnswer: true, lesson: "forte = loud"), dynCard(.word("piano"), loudAnswer: false, lesson: "piano = soft"),
        tempoCard(.word("allegro"), fastAnswer: true, lesson: "allegro = fast"), tempoCard(.word("adagio"), fastAnswer: false, lesson: "adagio = slow"),
    ]
    if extended {
        pool += [
            dynCard(.word("fortissimo"), loudAnswer: true, lesson: "fortissimo = very loud"),
            dynCard(.word("pianissimo"), loudAnswer: false, lesson: "pianissimo = very soft"),
            tempoCard(.word("presto"), fastAnswer: true, lesson: "presto = very fast"),
            tempoCard(.word("largo"), fastAnswer: false, lesson: "largo = very slow"),
            swellCard(.word("crescendo"), cresc: true, lesson: "crescendo = getting louder"),
            swellCard(.word("decrescendo"), cresc: false, lesson: "decrescendo = getting softer"),
            swellCard(.word("diminuendo"), cresc: false, lesson: "diminuendo = getting softer"),
        ]
    }
    return pool.randomElement()!
}

private func markCard() -> MMCard {
    switch Int.random(in: 0..<6) {
    case 0: return dynCard(.mark("pp"), loudAnswer: false, lesson: "pp = pianissimo = very soft")
    case 1: return dynCard(.mark("p"), loudAnswer: false, lesson: "p = piano = soft")
    case 2: return dynCard(.mark("f"), loudAnswer: true, lesson: "f = forte = loud")
    case 3: return dynCard(.mark("ff"), loudAnswer: true, lesson: "ff = fortissimo = very loud")
    case 4: return swellCard(.hairpin(true), cresc: true, lesson: "< crescendo = getting louder")
    default: return swellCard(.hairpin(false), cresc: false, lesson: "> decrescendo = getting softer")
    }
}

private func listenCard(swells: Bool) -> MMCard {
    let up = Bool.random()
    switch Int.random(in: 0..<(swells ? 3 : 2)) {
    case 0: return dynCard(.ear, loudAnswer: up, lesson: up ? "That was LOUD 🦁" : "That was soft 🐭")
    case 1: return tempoCard(.ear, fastAnswer: up, lesson: up ? "That was FAST 🐆" : "That was slow 🐌")
    default: return swellCard(.ear, cresc: up, lesson: up ? "It got LOUDER — crescendo" : "It got softer — decrescendo")
    }
}

private func compareCard() -> MMCard {
    let louderQ = Bool.random(), askMore = Bool.random()
    if louderQ {
        var a = 0, b = 0
        while a == b { a = Int.random(in: 0..<6); b = Int.random(in: 0..<6) }
        let da = mmDynamics[a], db = mmDynamics[b]
        let aWins = askMore ? a > b : a < b
        let w = aWins ? da : db
        return MMCard(sign: .ask(askMore ? "🦁" : "🐭", askMore ? "Which is LOUDER?" : "Which is SOFTER?"),
                      up: MMPad(icon: "", text: da.meaning, mark: da.mark), down: MMPad(icon: "", text: db.meaning, mark: db.mark),
                      answerUp: aWins, upMusic: .dyn(da.vel), downMusic: .dyn(db.vel),
                      lesson: "\(w.mark) = \(w.word) = \(w.meaning)")
    }
    var a = 0, b = 0
    while a == b || Set([a, b]) == [0, 1] { a = Int.random(in: 0..<5); b = Int.random(in: 0..<5) }
    let ta = mmTempi[a], tb = mmTempi[b]
    let aWins = askMore ? a > b : a < b
    let w = aWins ? ta : tb
    return MMCard(sign: .ask(askMore ? "🐆" : "🐌", askMore ? "Which is FASTER?" : "Which is SLOWER?"),
                  up: MMPad(icon: "", text: ta.meaning, mark: ta.word), down: MMPad(icon: "", text: tb.meaning, mark: tb.word),
                  answerUp: aWins, upMusic: .tempo(ta.beat), downMusic: .tempo(tb.beat),
                  lesson: "\(w.word) = \(w.meaning)")
}

private func mmMake(_ level: Int) -> MMQuestion {
    let r = Int.random(in: 0..<20)
    func one(_ c: MMCard, listen: Bool = false) -> MMQuestion { MMQuestion(cards: [c], listen: listen) }
    switch level {
    case 1: return one(emojiCard(tempo: false))
    case 2: return one(emojiCard(tempo: Bool.random()))
    case 3: return r < 12 ? one(listenCard(swells: false), listen: true) : one(emojiCard(tempo: Bool.random()))
    case 4: return r < 12 ? one(wordCard(extended: false)) : r < 17 ? one(listenCard(swells: false), listen: true) : one(emojiCard(tempo: Bool.random()))
    case 5: return r < 10 ? one(markCard()) : r < 15 ? one(wordCard(extended: false)) : one(listenCard(swells: true), listen: true)
    case 6: return r < 8 ? one(compareCard()) : r < 14 ? one(wordCard(extended: true)) : r < 17 ? one(markCard()) : one(listenCard(swells: true), listen: true)
    default:
        if level >= 8 && r < 5 { return one(compareCard()) }
        let n = level >= 9 ? 4 : 3
        var cards: [MMCard] = []
        while cards.count < n {
            let c = Bool.random() ? markCard() : wordCard(extended: true)
            if cards.last.map({ $0.sign == c.sign }) != true { cards.append(c) }
        }
        return MMQuestion(cards: cards, listen: false)
    }
}

// MARK: Band sound

/// The band's tune (C major), as events, with the per-note loudness for the bouncing animals.
private func bandTune(_ m: MMMusic, short: Bool) -> (events: [ToneEvent], beat: Double, vels: [Float]) {
    let melody = [72, 76, 79, 76, 71, 74, 77, 74]
    var beat = 0.28, vels = [Float](repeating: 0.6, count: 8)
    switch m {
    case .dyn(let v): vels = vels.map { _ in v }
    case .tempo(let b): beat = b
    case .swell(let up): vels = (0..<8).map { i in let x = Float(i) / 7; return 0.08 + 0.92 * (up ? x : 1 - x) }
    }
    var n = 8
    if case .tempo(let b) = m, b >= 0.5 { n = 4 }                 // slow tunes: half as many notes
    if short { n = min(n, beat >= 0.5 ? 3 : 4) }
    if case .swell = m, short { n = 8 }
    vels = Array(vels.prefix(n))
    if case .swell = m, n < 8 { vels = (0..<n).map { i in vels[min(7, i * 8 / n)] } }
    var ev: [ToneEvent] = []
    for i in 0..<n {
        let t = Double(i) * beat, v = vels[i]
        ev.append(ToneEvent(at: t, midi: melody[i % 8], vel: v, dur: beat * 1.5))
        if i % 4 == 0 { ev.append(ToneEvent(at: t, midi: i % 8 < 4 ? 48 : 43, vel: v * 0.8, dur: beat * 3.8)) }
        if i % 2 == 0 { ev.append(ToneEvent(at: t, midi: 0, vel: v * 0.8, dur: 0.3, voice: .drum)) }
    }
    let end = Double(n) * beat, lv = vels.last ?? 0.6
    ev += [48, 60, 64, 67, 72].map { ToneEvent(at: end, midi: $0, vel: lv * 0.7, dur: 0.7) }
    ev.append(ToneEvent(at: end, midi: 0, vel: lv, dur: 0.3, voice: .drum))
    return (ev, beat, vels + [lv])
}

// MARK: Model

@MainActor
private final class MaestroModel: ArcadeModel {
    @Published var q = MMQuestion(cards: [emojiCard(tempo: false)], listen: false)
    @Published var idx = 0
    @Published var busy = false
    @Published var revealed = false
    @Published var chosenUp: Bool?
    @Published var lesson: String?
    @Published var tumble = 0
    @Published var baton = 0.0                  // −1 down … +1 up
    @Published var bandStart = Date.distantPast
    @Published var bandBeat = 0.3
    @Published var bandVels: [Float] = []
    @Published var bandOn = false
    @Published var ovation = 0
    private var bandToken = 0

    init() { super.init(key: GameID.maestroMouse.rawValue) }
    override func perLevel(_ level: Int) -> Int { level >= 7 ? 4 : 6 }
    override func onBegin() { next() }

    var card: MMCard { q.cards[min(idx, q.cards.count - 1)] }

    private var recent: [Bool] = []

    private func next() {
        // No more than two of the same direction in a row (single-sign questions).
        var nq = mmMake(level)
        for _ in 0..<6 where nq.cards.count == 1 && recent.suffix(2) == [nq.cards[0].answerUp, nq.cards[0].answerUp] { nq = mmMake(level) }
        if nq.cards.count == 1 { recent.append(nq.cards[0].answerUp) }
        q = nq
        idx = 0; revealed = false; chosenUp = nil; lesson = nil; baton = 0
        busy = false
        if q.listen {
            busy = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self, self.phase == .playing else { return }
                self.listen()
            }
        }
    }

    /// Plays the band; returns its length. `then` runs once it has finished.
    @discardableResult
    private func band(_ m: MMMusic, short: Bool = false, then: (() -> Void)? = nil) -> Double {
        let (ev, beat, vels) = bandTune(m, short: short)
        let d = ToneSynth.shared.play(ev)
        bandToken += 1
        let tok = bandToken
        bandStart = Date(); bandBeat = beat; bandVels = vels; bandOn = true
        DispatchQueue.main.asyncAfter(deadline: .now() + d) { [weak self] in
            guard let self, self.bandToken == tok else { return }
            self.bandOn = false
            then?()
        }
        return d
    }

    func listen() {
        guard phase == .playing, q.listen, !revealed, !bandOn else { return }
        busy = true
        band(card.rightMusic) { [weak self] in self?.busy = false }
    }

    func choose(up: Bool) {
        guard phase == .playing, !busy, !revealed else { return }
        let c = card
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { baton = up ? 1 : -1 }
        busy = true
        chosenUp = up
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SYNTH_LOG"] != nil { NSLog("Maestro choose up=%d answerUp=%d level=%d", up ? 1 : 0, c.answerUp ? 1 : 0, level) }
        #endif
        if up == c.answerUp {
            let seq = q.cards.count > 1
            let last = idx == q.cards.count - 1
            if !seq || last { hit(); ovation += 1 }
            band(up ? c.upMusic : c.downMusic, short: seq) { [weak self] in
                guard let self, self.phase == .playing else { return }
                if seq && !last {
                    self.idx += 1; self.chosenUp = nil; self.baton = 0; self.busy = false
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                        guard let self, self.phase == .playing else { return }
                        self.next()
                    }
                }
            }
        } else {
            revealed = true
            lesson = c.lesson
            tumble += 1
            let lastHeart = miss(delay: 2.6)
            // The band plays it the RIGHT way, so the miss is heard as well as seen.
            band(c.rightMusic, short: true) { [weak self] in
                guard let self, self.phase == .playing, !lastHeart else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    guard let self, self.phase == .playing else { return }
                    self.next()
                }
            }
        }
    }

    override func botAct(correct: Bool) {
        guard phase == .playing, !busy, !revealed else { return }
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SYNTH_LOG"] != nil { NSLog("Maestro bot correct=%d", correct ? 1 : 0) }
        #endif
        choose(up: correct ? card.answerUp : !card.answerUp)
    }
}

// MARK: View

struct MaestroMouseView: View {
    let onClose: () -> Void
    @StateObject private var model = MaestroModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.maestroMouse.spec!, accent: Lu.coral, onClose: onClose) {
            VStack(spacing: 10) {
                Color.clear.frame(height: 56)
                MMSignBoard(model: model).frame(height: 132)
                ZStack {
                    if let l = model.lesson {
                        Text(l).font(luFont(19, .heavy)).foregroundStyle(Color(hex: Lu.gold))
                            .multilineTextAlignment(.center).minimumScaleFactor(0.6).lineLimit(2)
                            .transition(.scale.combined(with: .opacity))
                    } else if model.q.listen {
                        Text(model.busy ? "👂 Listen to the band…" : "Now wave your baton!")
                            .font(luFont(17, .heavy)).foregroundStyle(Color(hex: Lu.inkDim))
                    }
                }
                .frame(height: 40)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: model.lesson)
                MMBand(model: model).frame(height: 170)
                HStack(spacing: 10) {
                    ReplayButton(enabled: model.q.listen && !model.busy && !model.revealed) { model.listen() }
                        .opacity(model.q.listen ? 1 : 0)
                    SoundHint()
                }
                .frame(height: 58)
                MMPads(model: model)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 14)
        }
        .theatreSound(playing: model.phase == .playing)
        #if DEBUG
        .onAppear { if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { mmSelfCheck() } }
        #endif
    }
}

/// The composer's sign: a wooden board with the instruction (a score of marks at VII+).
private struct MMSignBoard: View {
    @ObservedObject var model: MaestroModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [Color(hex: 0xa8743e), Color(hex: 0x6e4220)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: Lu.gold), lineWidth: 3))
            if model.q.cards.count > 1 {
                HStack(spacing: 8) {
                    ForEach(Array(model.q.cards.enumerated()), id: \.offset) { i, c in
                        signFace(c.sign, compact: true)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0xf3e6c8).opacity(i == model.idx ? 1 : 0.55)))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: i == model.idx ? Lu.coral : 0x00000000), lineWidth: 3))
                            .overlay(alignment: .topTrailing) { if i < model.idx { Text("✅").font(.system(size: 16)).padding(3) } }
                            .scaleEffect(i == model.idx ? 1.06 : 0.94)
                    }
                }
                .padding(12)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: model.idx)
            } else {
                RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0xf3e6c8)).padding(12)
                signFace(model.card.sign, compact: false)
            }
        }
        .offset(x: model.revealed ? -4 : 0)
        .animation(.spring(response: 0.12, dampingFraction: 0.2), value: model.tumble)
    }

    @ViewBuilder private func signFace(_ s: MMSign, compact: Bool) -> some View {
        let ink = Color(hex: Lu.inkDark)
        switch s {
        case .emoji(let e): Text(e).font(.system(size: compact ? 40 : 76))
        case .word(let w): Text(w).font(.system(size: compact ? 20 : 44, weight: .bold, design: .serif).italic()).foregroundStyle(ink).minimumScaleFactor(0.4).lineLimit(1).padding(.horizontal, 6)
        case .mark(let m): Text(m).font(.system(size: compact ? 40 : 76, weight: .black, design: .serif).italic()).foregroundStyle(ink)
        case .hairpin(let c): Hairpin(cresc: c).stroke(ink, style: StrokeStyle(lineWidth: compact ? 3 : 5, lineCap: .round)).frame(width: compact ? 60 : 150, height: compact ? 26 : 50)
        case .ear: Text("👂 ❓").font(.system(size: compact ? 36 : 64))
        case .ask(let e, let t):
            HStack(spacing: 10) {
                Text(e).font(.system(size: 50))
                Text(t).font(luFont(26, .black)).foregroundStyle(ink).minimumScaleFactor(0.5).lineLimit(1)
            }.padding(.horizontal, 18)
        }
    }
}

/// A hairpin: < (crescendo) or > (decrescendo).
private struct Hairpin: Shape {
    let cresc: Bool
    func path(in r: CGRect) -> Path {
        var p = Path()
        let tip = CGPoint(x: cresc ? r.minX : r.maxX, y: r.midY)
        let open = cresc ? r.maxX : r.minX
        p.move(to: CGPoint(x: open, y: r.minY)); p.addLine(to: tip); p.addLine(to: CGPoint(x: open, y: r.maxY))
        return p
    }
}

/// The band on stage: each animal bounces with the beat, higher when the band plays louder.
private struct MMBand: View {
    @ObservedObject var model: MaestroModel
    private let players = [("🐘", "🎺"), ("🐻", "🥁"), ("🐸", "🎻"), ("🐷", "🎷")]

    var body: some View {
        ZStack {
            TheatreCurtains(light: Color(hex: Lu.gold))
            TimelineView(.animation(minimumInterval: 1 / 30, paused: !model.bandOn || model.phase != .playing)) { tl in
                let (amp, beatFrac) = pulse(tl.date)
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Array(players.enumerated()), id: \.offset) { j, p in
                        let bounce = model.bandOn ? abs(sin(.pi * (beatFrac + Double(j) * 0.25))) * Double(4 + 26 * amp) : 0
                        VStack(spacing: -6) {
                            Text(p.0).font(.system(size: 40))
                            Text(p.1).font(.system(size: 24))
                        }
                        .offset(y: -bounce)
                        .scaleEffect(1 + (model.bandOn ? CGFloat(amp) * 0.12 : 0))
                        .rotationEffect(.degrees(model.revealed ? Double([-25, 18, -12, 30][j]) : 0))
                        .frame(maxWidth: .infinity)
                    }
                    // The conductor on her box.
                    VStack(spacing: -4) {
                        Text("🪄").font(.system(size: 26))
                            .rotationEffect(.degrees(-45 - model.baton * 50), anchor: .bottomLeading)
                        Text("🐭").font(.system(size: 42))
                            .rotationEffect(.degrees(model.revealed ? 80 : 0))
                            .offset(y: model.revealed ? 16 : 0)
                        RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0x8a5a30)).frame(width: 40, height: 12)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 40).padding(.bottom, 14)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.45), value: model.revealed)
            if model.ovation > 0 { Ovation(trigger: model.ovation) }
        }
    }

    private func pulse(_ now: Date) -> (Double, Double) {
        let t = now.timeIntervalSince(model.bandStart) / max(model.bandBeat, 0.05)
        let i = min(max(0, Int(t)), max(0, model.bandVels.count - 1))
        let v = model.bandVels.isEmpty ? 0.5 : Double(model.bandVels[i])
        return (v, t - floor(t))
    }
}

/// A burst of applause emoji that pops up and fades on every right answer.
private struct Ovation: View {
    let trigger: Int
    @State private var up = false
    var body: some View {
        HStack(spacing: 16) { ForEach(0..<4, id: \.self) { i in Text(["👏", "🌹", "👏", "⭐️"][i]).font(.system(size: 26)) } }
            .offset(y: up ? -50 : 10).opacity(up ? 0 : 1)
            .onChange(of: trigger) { _ in
                up = false
                withAnimation(.easeOut(duration: 1.1)) { up = true }
            }
            .onAppear { withAnimation(.easeOut(duration: 1.1)) { up = true } }
            .allowsHitTesting(false)
    }
}

/// The conducting pad: swipe up / down anywhere on it, or tap the top or bottom half.
private struct MMPads: View {
    @ObservedObject var model: MaestroModel

    var body: some View {
        let c = model.card
        GeometryReader { g in
            VStack(spacing: 10) {
                pad(c.up, arrow: "arrow.up", isUp: true)
                pad(c.down, arrow: "arrow.down", isUp: false)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onEnded { v in
                let dy = v.translation.height
                if dy < -25 { model.choose(up: true) }
                else if dy > 25 { model.choose(up: false) }
                else { model.choose(up: v.startLocation.y < g.size.height / 2) }
            })
        }
        .opacity(model.busy && model.q.listen && !model.revealed && model.chosenUp == nil ? 0.5 : 1)
    }

    private func pad(_ p: MMPad, arrow: String, isUp: Bool) -> some View {
        let c = model.card
        let right = model.revealed && c.answerUp == isUp
        let wrong = model.revealed && model.chosenUp == isUp
        let picked = !model.revealed && model.chosenUp == isUp
        return HStack(spacing: 14) {
            Image(systemName: arrow).font(.system(size: 30, weight: .black))
                .foregroundStyle(Color(hex: isUp ? Lu.gold : Lu.sky))
            if let m = p.mark {
                Text(m).font(.system(size: m.count <= 2 ? 48 : 34, weight: .bold, design: .serif).italic())
                    .foregroundStyle(Color(hex: Lu.ink)).minimumScaleFactor(0.5).lineLimit(1)
                if model.revealed { Text(p.text).font(luFont(15, .bold)).foregroundStyle(Color(hex: Lu.inkDim)) }
            } else {
                Text(p.icon).font(.system(size: 50))
                Text(p.text).font(luFont(p.text.count > 6 ? 22 : 30, .black)).foregroundStyle(Color(hex: Lu.ink))
                    .minimumScaleFactor(0.5).lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: arrow).font(.system(size: 30, weight: .black))
                .foregroundStyle(Color(hex: isUp ? Lu.gold : Lu.sky))
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 22)
            .fill(Color(hex: right ? Lu.mint : (wrong ? Lu.coral : (picked ? Lu.panel2 : Lu.panel))).opacity(right || wrong ? 0.85 : 1))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: right ? Lu.mint : Lu.line), lineWidth: right ? 4 : 2)))
        .scaleEffect(right ? 1.03 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: model.revealed)
    }
}

#if DEBUG
/// LUDUS_SELFCHECK: every card's answer pad matches its sign's meaning (mark/word tables), and
/// every comparison has a strictly louder/faster side and never pits largo against adagio.
@MainActor private func mmSelfCheck() {
    var fails: [String] = []
    let loudWords: Set<String> = ["forte", "fortissimo", "f", "ff", "🦁"], softWords: Set<String> = ["piano", "pianissimo", "p", "pp", "🐭💤"]
    let fastWords: Set<String> = ["allegro", "presto", "🐆"], slowWords: Set<String> = ["adagio", "largo", "🐌"]
    for level in 1...10 {
        for _ in 0..<1000 {
            let q = mmMake(level)
            if q.cards.isEmpty || (q.listen && q.cards.count != 1) { fails.append("shape L\(level)") }
            for c in q.cards {
                var key: String?
                switch c.sign {
                case .emoji(let s), .word(let s), .mark(let s): key = s
                case .hairpin(let cr): if c.answerUp != cr || c.up != padCresc { fails.append("hairpin") }
                case .ear: if c.rightMusic != (c.answerUp ? c.upMusic : c.downMusic) { fails.append("ear") }
                case .ask(_, let t):
                    let louderAsk = t.contains("LOUDER") || t.contains("SOFTER")
                    let more = t.contains("LOUDER") || t.contains("FASTER")
                    guard let a = louderAsk ? mmDynamics.firstIndex(where: { $0.mark == c.up.mark }) : mmTempi.firstIndex(where: { $0.word == c.up.mark }),
                          let b = louderAsk ? mmDynamics.firstIndex(where: { $0.mark == c.down.mark }) : mmTempi.firstIndex(where: { $0.word == c.down.mark }),
                          a != b else { fails.append("ask \(t)"); continue }
                    if c.answerUp != (more ? a > b : a < b) { fails.append("ask answer \(t)") }
                    if !louderAsk && Set([a, b]) == [0, 1] { fails.append("largo/adagio") }
                }
                if let k = key {
                    if loudWords.contains(k) && !(c.answerUp && c.up == padLoud) { fails.append("loud \(k)") }
                    if softWords.contains(k) && !(!c.answerUp && c.down == padSoft) { fails.append("soft \(k)") }
                    if fastWords.contains(k) && !(c.answerUp && c.up == padFast) { fails.append("fast \(k)") }
                    if slowWords.contains(k) && !(!c.answerUp && c.down == padSlow) { fails.append("slow \(k)") }
                    if k == "crescendo" && !(c.answerUp && c.up == padCresc) { fails.append(k) }
                    if (k == "decrescendo" || k == "diminuendo") && !(!c.answerUp && c.down == padDecresc) { fails.append(k) }
                }
            }
        }
    }
    NSLog("MaestroMouse self-check: %@", fails.isEmpty ? "PASS" : "FAIL \(Array(Set(fails)).prefix(10))")
}
#endif
