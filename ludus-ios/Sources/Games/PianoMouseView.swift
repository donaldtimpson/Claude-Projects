import SwiftUI

// MARK: - Piano Mouse (Theatre · Music)
//
// A mouse lives in a giant piano and hides cheese under the keys. The card says which key; tap
// it — every key plays (ToneSynth). Right: the mouse scampers over and nibbles the cheese. Wrong:
// a cat pops up, the mouse runs to the right key, and the key shows its name.
//
// Ladder (one octave C–B at I–V, C to the next E from VI):
//   I     the key that glows — tap it (no reading, no clock)
//   II    a BLACK key / a WHITE key, the HIGHEST / LOWEST key (pictures)
//   III   find C, D, E, F by the black-key groups (C sits left of the 2 black keys; hint shown)
//   IV    any white-key name, C D E F G A B (no hint)
//   V     sharps and flats on the black keys (G♭ is the F♯ key — enharmonic trap), some naturals
//   VI    white-key intervals up from a glowing key: 2nd … octave (count the start as 1)
//   VII   build a major/minor triad from its notes (C major = C E G), mixed with intervals
//   VIII+ triads by name only (incl. B♭, E♭, Cm, Gm, Fm), tunes from note names; IX+ adds
//         intervals DOWN. Endless past VIII.

// MARK: Model

private enum PMTask {
    case glow(Int)
    case color(black: Bool)
    case end(high: Bool)
    case name(Spelled, hint: Bool)
    case interval(from: Int, steps: Int, down: Bool)
    case chord(name: String, notes: [Spelled], showNotes: Bool)
    case tune(title: String, notes: [Spelled])
}

private struct PMQuestion {
    let task: PMTask
    let keys: ClosedRange<Int>
    /// For one-tap tasks: the keys that count as right.
    var answers: Set<Int>
    /// For chords/tunes: the pitch classes still to play (chord: any order; tune: in order).
    var steps: [Int] = []
}

private let pmTunes: [(String, [String])] = [
    ("Mary Had a Little Lamb", ["E", "D", "C", "D", "E", "E", "E"]),
    ("Hot Cross Buns", ["E", "D", "C"]),
    ("Twinkle, Twinkle", ["C", "C", "G", "G", "A", "A", "G"]),
    ("Ode to Joy", ["E", "E", "F", "G", "G", "F", "E", "D"]),
    ("Frère Jacques", ["C", "D", "E", "C"]),
]

/// (root, quality) pools: VII shows the notes; VIII+ adds flat keys and minor chords by name.
private let pmChordsEasy: [(String, ChordQuality)] = [("C", .major), ("F", .major), ("G", .major), ("A", .minor), ("D", .minor), ("E", .minor)]
private let pmChordsHard: [(String, ChordQuality)] = pmChordsEasy + [
    ("D", .major), ("A", .major), ("E", .major), ("B♭", .major), ("E♭", .major), ("C", .minor), ("G", .minor), ("F", .minor),
]

private func pmRange(_ level: Int) -> ClosedRange<Int> { level >= 6 ? 60...76 : 60...71 }

private func pmMake(_ level: Int, avoid: Int?) -> PMQuestion {
    let keys = pmRange(level)
    let all = Array(keys)
    let whites = all.filter { !isBlackKey($0) }
    func glow() -> PMQuestion {
        var k: Int
        repeat { k = Bool.random() && Int.random(in: 0..<4) == 0 ? all.filter(isBlackKey).randomElement()! : whites.randomElement()! } while k == avoid
        return PMQuestion(task: .glow(k), keys: keys, answers: [k])
    }
    func name(_ pool: [Spelled], hint: Bool) -> PMQuestion {
        let s = pool.randomElement()!
        return PMQuestion(task: .name(s, hint: hint), keys: keys, answers: Set(all.filter { pitchClass($0) == s.pc }))
    }
    func interval(down: Bool) -> PMQuestion {
        let n = Int.random(in: 2...8)
        let i = down ? Int.random(in: (n - 1)..<whites.count) : Int.random(in: 0...(whites.count - n))
        let from = whites[i], to = whites[down ? i - (n - 1) : i + (n - 1)]
        return PMQuestion(task: .interval(from: from, steps: n, down: down), keys: keys, answers: [to])
    }
    func chord(_ pool: [(String, ChordQuality)], show: Bool) -> PMQuestion {
        let (r, q) = pool.randomElement()!
        let notes = spellTriad(Spelled(r), q)!
        let nm = r + (q == .major ? " major" : " minor")
        return PMQuestion(task: .chord(name: nm, notes: notes, showNotes: show), keys: keys, answers: [], steps: notes.map(\.pc))
    }
    func tune() -> PMQuestion {
        let (t, n) = pmTunes.randomElement()!
        let notes = n.map { Spelled($0) }
        return PMQuestion(task: .tune(title: t, notes: notes), keys: keys, answers: [], steps: notes.map(\.pc))
    }
    let naturals = (0..<7).map { Spelled($0) }
    switch level {
    case 1:
        return glow()
    case 2:
        switch Int.random(in: 0..<8) {
        case 0, 1: return glow()
        case 2, 3, 4:
            let black = Bool.random()
            return PMQuestion(task: .color(black: black), keys: keys, answers: Set(all.filter { isBlackKey($0) == black }))
        default:
            let high = Bool.random()
            return PMQuestion(task: .end(high: high), keys: keys, answers: [high ? keys.upperBound : keys.lowerBound])
        }
    case 3:
        return name([Spelled("C"), Spelled("C"), Spelled("D"), Spelled("E"), Spelled("F")], hint: true)
    case 4:
        return name(naturals, hint: false)
    case 5:
        if Int.random(in: 0..<10) < 3 { return name(naturals, hint: false) }
        let (s, f) = blackKeyNames([1, 3, 6, 8, 10].randomElement()!)
        return name([Bool.random() ? s : f], hint: false)
    case 6:
        return interval(down: false)
    case 7:
        return Int.random(in: 0..<3) == 0 ? interval(down: false) : chord(pmChordsEasy, show: true)
    default:
        switch Int.random(in: 0..<5) {
        case 0: return interval(down: level >= 9 && Bool.random())
        case 1, 2: return chord(pmChordsHard, show: false)
        case 3: return tune()
        default: return chord(pmChordsEasy, show: level < 9)
        }
    }
}

@MainActor
private final class PianoMouseModel: ArcadeModel {
    @Published var q = PMQuestion(task: .glow(60), keys: 60...71, answers: [60])
    @Published var mouseKey = 64
    @Published var cheeseKey: Int?
    @Published var wrongKey: Int?
    @Published var reveal: Set<Int> = []
    @Published var played: [Int] = []          // keys already played toward a chord/tune
    @Published var revealText: String?
    @Published var showNames = false            // all white-key letters, briefly, after a miss
    @Published var catPop = 0
    @Published var nibble = 0
    @Published var locked = false

    init() { super.init(key: GameID.pianoMouse.rawValue) }
    override func perLevel(_ level: Int) -> Int { level >= 7 ? 5 : 6 }
    override func onBegin() { next() }

    private func next() {
        let avoid: Int? = { if case .glow(let k) = q.task { return k }; return nil }()
        let before = String(describing: q.task)
        var nq = pmMake(level, avoid: avoid)
        for _ in 0..<4 where String(describing: nq.task) == before { nq = pmMake(level, avoid: avoid) }   // no exact repeats
        q = nq
        cheeseKey = nil; wrongKey = nil; reveal = []; played = []; revealText = nil; showNames = false; locked = false
        if case .interval(let from, _, _) = q.task { mouseKey = from }
        if case .glow(let k) = q.task { mouseKey = k }          // she points at the shiny key
        if !q.keys.contains(mouseKey) { mouseKey = q.keys.lowerBound + 4 }
    }

    func press(_ k: Int) {
        guard phase == .playing, !locked, q.keys.contains(k) else { return }
        ToneSynth.shared.note(k, vel: 0.75)
        if q.steps.isEmpty {
            q.answers.contains(k) ? win(at: k) : lose(tapped: k, show: Array(q.answers))
            return
        }
        if case .chord = q.task {
            let have = Set(played.map(pitchClass))
            if have.contains(pitchClass(k)) { return }                 // same note again: no harm
            guard q.steps.contains(pitchClass(k)) else {
                return lose(tapped: k, show: q.steps.filter { !have.contains($0) }.map { pmKey(pc: $0) })
            }
            played.append(k); mouseKey = k
            if played.count == 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { ToneSynth.shared.chord(self.played, vel: 0.55, dur: 1.2) }
                win(at: k, delay: 1.4)
            }
        } else {
            let want = q.steps[played.count]
            guard pitchClass(k) == want else { return lose(tapped: k, show: [pmKey(pc: want, near: played.last)]) }
            played.append(k); mouseKey = k
            if played.count == q.steps.count { win(at: k, delay: 1.1) }
        }
    }

    /// The key in range for a pitch class (the one nearest `near`, else the lowest).
    func pmKey(pc: Int, near: Int? = nil) -> Int {
        let c = q.keys.filter { pitchClass($0) == pc }
        guard let near else { return c.first ?? q.keys.lowerBound }
        return c.min(by: { abs($0 - near) < abs($1 - near) }) ?? q.keys.lowerBound
    }

    private func win(at k: Int, delay: Double = 0.9) {
        locked = true
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { mouseKey = k }
        cheeseKey = k
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self, self.phase == .playing else { return }
            self.nibble += 1
            ToneSynth.shared.play([ToneEvent(at: 0, midi: 88, vel: 0.35, dur: 0.1), ToneEvent(at: 0.1, midi: 91, vel: 0.35, dur: 0.15)])
        }
        hit()
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.phase == .playing else { return }
            self.next()
        }
    }

    private func lose(tapped k: Int, show: [Int]) {
        locked = true
        wrongKey = k
        reveal = Set(show)
        catPop += 1
        revealText = teach()
        showNames = level >= 3
        if let first = show.first { withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.25)) { mouseKey = first } }
        if case .chord(_, let notes, _) = q.task {       // hear the right chord
            let ks = notes.map { pmKey(pc: $0.pc, near: 64) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { ToneSynth.shared.chord(ks, vel: 0.5, dur: 1.2, roll: 0.06) }
        } else if let first = show.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { ToneSynth.shared.note(first, vel: 0.6) }
        }
        let last = miss(delay: 2.0)
        guard !last else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) { [weak self] in
            guard let self, self.phase == .playing else { return }
            self.next()
        }
    }

    /// What a miss teaches, per task.
    private func teach() -> String {
        switch q.task {
        case .glow: return "This one was shining ✨"
        case .color(let black): return black ? "Black keys are the short dark ones" : "White keys are the long ones"
        case .end(let high): return high ? "High notes are on the right ➡️" : "Low notes are on the left ⬅️"
        case .name(let s, _):
            if s.acc != 0 {
                let (sh, fl) = blackKeyNames(s.pc)
                return "\(s.name): \(s.acc > 0 ? "♯ = the key just right" : "♭ = the key just left") · \(sh.name) = \(fl.name)"
            }
            return pmNameHint[s.letter]
        case .interval(let from, let n, let down):
            return "\(whiteKeyName(from).name) is 1 — count \(n) white keys \(down ? "down" : "up")"
        case .chord(let name, let notes, _): return "\(name) = " + notes.map(\.name).joined(separator: " ")
        case .tune(_, let notes): return "Next note: \(notes[played.count].name)"
        }
    }

    override func botAct(correct: Bool) {
        guard phase == .playing, !locked else { return }
        let have = Set(played.map(pitchClass))
        let right: [Int]
        if q.steps.isEmpty { right = Array(q.answers) }
        else if case .chord = q.task { right = q.keys.filter { q.steps.contains(pitchClass($0)) && !have.contains(pitchClass($0)) } }
        else { right = q.keys.filter { pitchClass($0) == q.steps[played.count] } }
        let wrong = q.keys.filter { !right.contains($0) && !have.contains(pitchClass($0)) }
        if let k = (correct || wrong.isEmpty ? right : wrong).randomElement() { press(k) }
    }
}

private let pmNameHint = [
    "C sits just left of the 2 black keys", "D sits between the 2 black keys", "E sits just right of the 2 black keys",
    "F sits just left of the 3 black keys", "G is the 1st key inside the 3 black keys", "A is the 2nd key inside the 3 black keys",
    "B sits just right of the 3 black keys",
]

// MARK: View

struct PianoMouseView: View {
    let onClose: () -> Void
    @StateObject private var model = PianoMouseModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.pianoMouse.spec!, accent: Lu.gold, onClose: onClose) {
            VStack(spacing: 10) {
                Color.clear.frame(height: 56)
                PMPromptCard(model: model)
                ZStack {
                    if let t = model.revealText {
                        Text(t).font(luFont(17, .heavy)).foregroundStyle(Color(hex: Lu.gold))
                            .multilineTextAlignment(.center).minimumScaleFactor(0.6).lineLimit(2)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 48)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: model.revealText)
                Spacer(minLength: 0)
                PMKeyboard(model: model)
                    .frame(minHeight: 330, maxHeight: 470)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 12)
        }
        .theatreSound(playing: model.phase == .playing)
        #if DEBUG
        .onAppear { if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { pmSelfCheck() } }
        #endif
    }
}

private struct PMPromptCard: View {
    @ObservedObject var model: PianoMouseModel

    var body: some View {
        HStack(spacing: 12) {
            Text(icon).font(.system(size: 52)).frame(width: 66)
            VStack(alignment: .leading, spacing: 4) {
                main
                if let s = sub {
                    Text(s).font(luFont(15, .bold)).foregroundStyle(Color(hex: Lu.inkDim))
                        .minimumScaleFactor(0.6).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(luPanelShape(20))
    }

    private var icon: String {
        switch model.q.task {
        case .glow: return "✨"
        case .color(let b): return b ? "⬛️" : "⬜️"
        case .end(let high): return high ? "🐦" : "🐻"
        case .name: return "🐭"
        case .interval: return "🪜"
        case .chord: return "🎹"
        case .tune: return "🎶"
        }
    }

    @ViewBuilder private var main: some View {
        let big = luFont(30, .black)
        switch model.q.task {
        case .glow: Text("Tap the shiny key!").font(luFont(26)).foregroundStyle(Color(hex: Lu.ink))
        case .color(let b): Text(b ? "Tap a BLACK key" : "Tap a WHITE key").font(luFont(26)).foregroundStyle(Color(hex: Lu.ink))
        case .end(let high): Text(high ? "Tap the HIGHEST key ➡️" : "⬅️ Tap the LOWEST key").font(luFont(24)).foregroundStyle(Color(hex: Lu.ink)).minimumScaleFactor(0.6)
        case .name(let s, _): Text("Find  \(s.name)").font(big).foregroundStyle(Color(hex: Lu.ink))
        case .interval(let from, let n, let down):
            Text("From \(whiteKeyName(from).name), \(down ? "down" : "up") \(intervalName(n))").font(luFont(28)).foregroundStyle(Color(hex: Lu.ink)).minimumScaleFactor(0.6)
        case .chord(let name, let notes, let show):
            Text("Build \(name)").font(luFont(26)).foregroundStyle(Color(hex: Lu.ink)).minimumScaleFactor(0.6)
            if show { noteRow(notes, any: true) }
        case .tune(let title, let notes):
            Text(title).font(luFont(20)).foregroundStyle(Color(hex: Lu.ink)).minimumScaleFactor(0.6).lineLimit(1)
            noteRow(notes, any: false)
        }
    }

    private var sub: String? {
        switch model.q.task {
        case .name(let s, let hint): return hint ? pmNameHint[s.letter] : nil
        case .interval(let from, _, let down): return "\(whiteKeyName(from).name) is 1 · white keys \(down ? "down" : "up")"
        case .chord(_, _, let show): return show ? "Tap all 3 keys" : "3 keys — which ones?"
        default: return nil
        }
    }

    /// The notes to play; a tune underlines how far you've got, a chord ticks off what's played.
    private func noteRow(_ notes: [Spelled], any: Bool) -> some View {
        let donePCs = Set(model.played.map(pitchClass))
        return HStack(spacing: 6) {
            ForEach(Array(notes.enumerated()), id: \.offset) { i, n in
                let done = any ? donePCs.contains(n.pc) : i < model.played.count
                let now = !any && i == model.played.count
                Text(n.name).font(luFont(notes.count > 5 ? 19 : 24, .black))
                    .foregroundStyle(Color(hex: done ? Lu.mint : (now ? Lu.gold : Lu.ink)))
                    .padding(.horizontal, 3)
                    .overlay(alignment: .bottom) { if now { Capsule().fill(Color(hex: Lu.gold)).frame(height: 3).offset(y: 3) } }
            }
        }
        .minimumScaleFactor(0.5).lineLimit(1)
    }
}

/// The keyboard: white keys in a row, black keys over the gaps. One drag gesture finds the key
/// under the finger (black keys first) so a touch plays on touch-down.
private struct PMKeyboard: View {
    @ObservedObject var model: PianoMouseModel
    @State private var touching = false
    @State private var pressed: Int?
    @State private var catShow = false

    var body: some View {
        GeometryReader { g in
            let keys = model.q.keys
            let whites = keys.filter { !isBlackKey($0) }
            let ww = g.size.width / CGFloat(whites.count)
            let laneH: CGFloat = 64
            let kh = g.size.height - laneH
            let bw = ww * 0.62, bh = kh * 0.6
            let centerX: (Int) -> CGFloat = { k in
                isBlackKey(k) ? CGFloat(whites.firstIndex(of: k - 1)! + 1) * ww : (CGFloat(whites.firstIndex(of: k)!) + 0.5) * ww
            }
            ZStack(alignment: .topLeading) {
                // Mouse lane
                Text("🐭").font(.system(size: 44))
                    .scaleEffect(x: -1)
                    .scaleEffect(model.nibble % 2 == 1 ? 1.25 : 1)
                    .position(x: centerX(model.mouseKey), y: laneH / 2 + (catShow ? 6 : 0))
                    .animation(.spring(response: 0.4, dampingFraction: 0.65), value: model.mouseKey)
                    .animation(.spring(response: 0.35, dampingFraction: 0.45), value: model.nibble)
                if catShow, let w = model.wrongKey {
                    Text("🙀").font(.system(size: 40))
                        .position(x: min(max(centerX(w), 30), g.size.width - 30), y: laneH / 2 - 4)
                        .transition(.scale(scale: 0.2).combined(with: .opacity))
                }
                // White keys
                ForEach(whites, id: \.self) { k in
                    whiteKey(k).frame(width: ww - 3, height: kh)
                        .position(x: centerX(k), y: laneH + kh / 2)
                }
                // Black keys
                ForEach(keys.filter(isBlackKey), id: \.self) { k in
                    blackKey(k).frame(width: bw, height: bh)
                        .position(x: centerX(k), y: laneH + bh / 2)
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { v in
                    guard !touching else { return }
                    touching = true
                    let p = v.startLocation
                    guard p.y > laneH else { return }
                    let y = p.y - laneH
                    var hitKey: Int?
                    if y < bh { hitKey = keys.filter(isBlackKey).first { abs(centerX($0) - p.x) < bw / 2 } }
                    if hitKey == nil { hitKey = whites[min(whites.count - 1, max(0, Int(p.x / ww)))] }
                    if let k = hitKey {
                        pressed = k
                        model.press(k)
                    }
                }
                .onEnded { _ in touching = false; pressed = nil })
        }
        .onChange(of: model.catPop) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { catShow = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { withAnimation(.easeIn(duration: 0.2)) { catShow = false } }
        }
    }

    private func fill(_ k: Int, black: Bool) -> Color {
        if model.cheeseKey == k || model.played.contains(k) { return Color(hex: Lu.mint) }
        if model.reveal.contains(k) { return Color(hex: Lu.mint) }
        if model.wrongKey == k { return Color(hex: Lu.coral) }
        if case .glow(let g) = model.q.task, g == k { return Color(hex: Lu.gold) }
        if case .interval(let from, _, _) = model.q.task, from == k { return Color(hex: Lu.sky) }
        if pressed == k { return black ? Color(hex: 0x4a4458) : Color(hex: 0xd8d0c0) }
        return black ? Color(hex: 0x15121c) : Color(hex: 0xfaf4e6)
    }

    private func isGlow(_ k: Int) -> Bool {
        if case .glow(let g) = model.q.task, g == k, model.cheeseKey == nil { return true }
        return false
    }

    private func label(_ k: Int) -> String? {
        let named = model.cheeseKey == k || model.reveal.contains(k) || model.played.contains(k)
        if case .interval(let from, _, _) = model.q.task, from == k { return whiteKeyName(k).name }
        if isBlackKey(k) {
            guard named, model.level >= 5 else { return nil }
            let (s, f) = blackKeyNames(pitchClass(k))
            return "\(s.name)\n\(f.name)"
        }
        if named && model.level >= 3 { return whiteKeyName(k).name }
        if model.showNames || model.level >= 6 { return whiteKeyName(k).name }
        return nil
    }

    private func whiteKey(_ k: Int) -> some View {
        let lbl = label(k)
        return RoundedRectangle(cornerRadius: 8)
            .fill(fill(k, black: false))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0x6a5a80), lineWidth: 1.5))
            .overlay { if isGlow(k) { PMGlowRing(radius: 8, width: 5) } }
            .overlay(alignment: .bottom) {
                VStack(spacing: 2) {
                    if model.cheeseKey == k { Text("🧀").font(.system(size: 30)).transition(.scale) }
                    if let lbl {
                        Text(lbl).font(luFont(model.q.keys.count > 12 ? 18 : 22, .black))
                            .foregroundStyle(Color(hex: model.showNames && !model.reveal.contains(k) && model.cheeseKey != k ? 0x9a8fb0 : Lu.inkDark))
                    }
                }
                .padding(.bottom, 10)
            }
            .offset(x: model.wrongKey == k ? 3 : 0)
    }

    private func blackKey(_ k: Int) -> some View {
        let lbl = label(k)
        return RoundedRectangle(cornerRadius: 6)
            .fill(fill(k, black: true))
            .overlay { if isGlow(k) { PMGlowRing(radius: 6, width: 4) } }
            .overlay(alignment: .bottom) {
                VStack(spacing: 0) {
                    if model.cheeseKey == k { Text("🧀").font(.system(size: 22)) }
                    if let lbl { Text(lbl).font(luFont(12, .black)).foregroundStyle(Color(hex: Lu.inkDark)).multilineTextAlignment(.center) }
                }
                .padding(.bottom, 6)
            }
            .shadow(color: .black.opacity(0.35), radius: 2, y: 2)
    }
}

/// The shiny key's pulsing gold ring. Its own view, so the endless pulse lives and dies with the
/// glow (a shared repeat-forever animation left other keys stuck mid-pulse).
private struct PMGlowRing: View {
    let radius: CGFloat, width: CGFloat
    @State private var on = false
    var body: some View {
        RoundedRectangle(cornerRadius: radius).stroke(Color(hex: Lu.gold), lineWidth: width)
            .opacity(on ? 1 : 0.3)
            .onAppear { withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { on = true } }
            .allowsHitTesting(false)
    }
}

#if DEBUG
/// LUDUS_SELFCHECK: every generated question at every level has a reachable answer, one-tap
/// answers are exactly the keys described, chords/tunes are spelled right and playable.
@MainActor private func pmSelfCheck() {
    var fails = theatreTheoryCheck()
    for level in 1...10 {
        var prev: Int?
        for _ in 0..<1500 {
            let q = pmMake(level, avoid: prev)
            let keys = Set(q.keys)
            switch q.task {
            case .glow(let k): if q.answers != [k] || !keys.contains(k) || k == prev { fails.append("glow \(k)") }; prev = k
            case .color(let b): if q.answers != keys.filter({ isBlackKey($0) == b }) || q.answers.isEmpty { fails.append("color") }
            case .end(let h): if q.answers != [h ? q.keys.upperBound : q.keys.lowerBound] { fails.append("end") }
            case .name(let s, _):
                if q.answers.isEmpty || q.answers.contains(where: { pitchClass($0) != s.pc }) { fails.append("name \(s.name)") }
                if s.acc != 0 && q.answers.contains(where: { !isBlackKey($0) }) { fails.append("accidental on white \(s.name)") }
            case .interval(let from, let n, let down):
                let ws = q.keys.filter { !isBlackKey($0) }
                guard q.answers.count == 1, let to = q.answers.first, let i = ws.firstIndex(of: from), let j = ws.firstIndex(of: to) else { fails.append("interval"); continue }
                if (down ? i - j : j - i) != n - 1 || (n == 8 && pitchClass(from) != pitchClass(to)) { fails.append("interval \(from) \(n)") }
                if (whiteKeyName(to).letter - whiteKeyName(from).letter + 7 * 4) % 7 != (down ? (7 - (n - 1) % 7) % 7 : (n - 1) % 7) { fails.append("interval letter \(from) \(n)") }
            case .chord(_, let notes, _):
                if Set(notes.map(\.pc)).count != 3 || notes.contains(where: { n in !keys.contains(where: { pitchClass($0) == n.pc }) }) { fails.append("chord") }
            case .tune(_, let notes):
                if notes.contains(where: { n in !keys.contains(where: { pitchClass($0) == n.pc }) }) { fails.append("tune") }
            }
        }
    }
    // Hand-checked spot values.
    if blackKeyNames(pitchClass(66)).flat.name != "G♭" { fails.append("66 = G♭") }
    if whiteKeyName(60).name != "C" || whiteKeyName(71).name != "B" { fails.append("white names") }
    NSLog("PianoMouse self-check: %@", fails.isEmpty ? "PASS" : "FAIL \(fails.prefix(10))")
}
#endif
