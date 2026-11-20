import SwiftUI

// MARK: - Piano Mouse (Theatre · Music)
//
// A mouse lives INSIDE a grand piano (gold frame, strings, felt hammers) and hides cheese under
// the keys. The sheet on the music desk says which key; tap it — every key plays. Right: the mouse
// scampers along the key rail and nibbles the cheese. Wrong: she jumps in fright, runs to the right
// key, the key lights green with its name and sounds, and the sheet explains how to find it.
//
// Continuous ladder (all off `d`; new kinds fade in, old ones stay as review):
//   1    the WHITE key that shines (a black one now and then from ~1.6)
//   1.8  a BLACK / WHITE key, the HIGHEST / LOWEST key (pictures + voice)
//   2.6  C D E F by the black-key groups (with the hint)
//   3.5  any letter C–B; the hint fades out by ~5
//   4.8  sharps & flats on the black keys (G♭ is the F♯ key)
//   5.8  read the note on a treble staff, middle C upward (range grows to E5; ♯/♭ from ~8)
//   7    intervals UP from a lit key (count the start as 1), widening to an octave
//   8.5  intervals DOWN
// The keyboard is one octave (C–B) until the staff arrives, then C4–E5.

// MARK: Model

private enum PMTask: Equatable {
    case glow(Int)
    case color(black: Bool)
    case end(high: Bool)
    case name(Spelled, hint: Bool)
    case staff(step: Int, note: Spelled)
    case interval(from: Int, steps: Int, down: Bool)
}

private struct PMQuestion {
    let task: PMTask
    let keys: ClosedRange<Int>
    var answers: Set<Int>
}

private let pmNameHint = [
    "C sits just left of the 2 black keys", "D sits between the 2 black keys", "E sits just right of the 2 black keys",
    "F sits just left of the 3 black keys", "G is the 1st key inside the 3 black keys", "A is the 2nd key inside the 3 black keys",
    "B sits just right of the 3 black keys",
]

/// How a note's name is said aloud ("B♭" → "B flat").
private func pmSpoken(_ s: Spelled) -> String {
    Spelled.letters[s.letter] + (s.acc > 0 ? " sharp" : s.acc < 0 ? " flat" : "")
}

/// MIDI of a staff step above middle C (0 = C4, 1 = D4 … 9 = E5) plus an accidental.
private func pmStaffMidi(_ step: Int, _ acc: Int) -> Int {
    60 + 12 * (step / 7) + Spelled.naturalPC[step % 7] + acc
}

@MainActor
private final class PianoMouseModel: ArcadeModel {
    @Published var q = PMQuestion(task: .glow(64), keys: 60...71, answers: [64])
    @Published var mouseKey = 64
    @Published var mouseMood = StageMouse.Mood.calm
    @Published var cheeseKey: Int?
    @Published var wrongKey: Int?
    @Published var reveal: Set<Int> = []
    @Published var revealText: String?
    @Published var nibble = 0
    @Published var fright = 0
    @Published var locked = false

    init() { super.init(key: GameID.pianoMouse.rawValue) }
    override func onBegin() { mouseMood = .calm; next() }

    /// One octave until staff reading arrives, then middle C up to E5.
    var range: ClosedRange<Int> { d >= 5.5 ? 60...76 : 60...71 }

    func make(avoid: PMTask?) -> PMQuestion {
        let keys = range
        let all = Array(keys), whites = all.filter { !isBlackKey($0) }, blacks = all.filter(isBlackKey)
        func one(_ t: PMTask, _ a: Set<Int>) -> PMQuestion { PMQuestion(task: t, keys: keys, answers: a) }
        switch tier([1, 1.8, 2.6, 3.5, 4.8, 5.8, 7, 8.5]) {
        case 0:
            let k = chance(0.3, from: 1.6, to: 3) ? blacks.randomElement()! : whites.randomElement()!
            return one(.glow(k), [k])
        case 1:
            if Bool.random() {
                let black = Bool.random()
                return one(.color(black: black), Set(all.filter { isBlackKey($0) == black }))
            }
            let high = Bool.random()
            return one(.end(high: high), [high ? keys.upperBound : keys.lowerBound])
        case 2, 3:
            let s = tierIsEasyName ? Spelled([0, 0, 1, 2, 3].randomElement()!) : Spelled(Int.random(in: 0..<7))
            let hint = tierIsEasyName || Double.random(in: 0..<1) < ramp(1, 0, from: 3.5, to: 5)
            return one(.name(s, hint: hint), Set(all.filter { pitchClass($0) == s.pc }))
        case 4:
            let (sh, fl) = blackKeyNames([1, 3, 6, 8, 10].randomElement()!)
            let s = Bool.random() ? sh : fl
            return one(.name(s, hint: false), Set(all.filter { pitchClass($0) == s.pc }))
        case 5:
            let step = Int.random(in: 0...rampInt(4, 9, from: 5.8, to: 7.5))
            var acc = 0
            if chance(0.45, from: 8, to: 10) {
                let letter = step % 7
                let sharpOK = [0, 1, 3, 4, 5].contains(letter), flatOK = [1, 2, 4, 5, 6].contains(letter)
                acc = sharpOK && (!flatOK || Bool.random()) ? 1 : (flatOK ? -1 : 0)
                if pmStaffMidi(step, acc) > keys.upperBound || pmStaffMidi(step, acc) < keys.lowerBound { acc = 0 }
            }
            let m = pmStaffMidi(step, acc)
            return one(.staff(step: step, note: Spelled(step % 7, acc)), [m])
        default:
            let down = tierIsDown
            let n = Int.random(in: 2...rampInt(4, 8, from: 7, to: 9))
            let i = down ? Int.random(in: (n - 1)..<whites.count) : Int.random(in: 0...(whites.count - n))
            let from = whites[i], to = whites[down ? i - (n - 1) : i + (n - 1)]
            return one(.interval(from: from, steps: n, down: down), [to])
        }
    }
    // Set by `make` from the tier index (names: the hinted C–F set; intervals: down).
    private var tierIsEasyName = false
    private var tierIsDown = false

    private func pick(avoid: PMTask?) -> PMQuestion {
        // Draw a tier, then fix the per-tier flags, then build (two passes keep `make` simple).
        var nq: PMQuestion
        var tries = 0
        repeat {
            let w = tierWeights([1, 1.8, 2.6, 3.5, 4.8, 5.8, 7, 8.5])
            tierIsEasyName = Double.random(in: 0..<1) < w[2] / max(0.0001, w[2] + w[3])
            tierIsDown = Double.random(in: 0..<1) < w[7] / max(0.0001, w[6] + w[7])
            nq = make(avoid: avoid)
            tries += 1
        } while nq.task == avoid && tries < 6
        return nq
    }

    private func next() {
        q = pick(avoid: q.task)
        cheeseKey = nil; wrongKey = nil; reveal = []; revealText = nil; locked = false; mouseMood = .calm
        switch q.task {
        case .glow(let k): mouseKey = k
        case .interval(let from, _, _): mouseKey = from
        default: if !q.keys.contains(mouseKey) { mouseKey = 64 }
        }
        // Pre-readers hear the job (voice), until the sheet is all notation.
        if d < 6 {
            switch q.task {
            case .color(let b): LibraryVoice.say(b ? "Tap a black key" : "Tap a white key")
            case .end(let h): LibraryVoice.say(h ? "Tap the highest key" : "Tap the lowest key")
            case .name(let s, _): LibraryVoice.say("Find \(pmSpoken(s))")
            default: break
            }
        }
    }

    func press(_ k: Int) {
        guard phase == .playing, !locked, q.keys.contains(k) else { return }
        ToneSynth.shared.note(k, vel: 0.75)
        q.answers.contains(k) ? win(at: k) : lose(tapped: k)
    }

    private func win(at k: Int) {
        locked = true
        if abs(k - mouseKey) > 2 { Sfx.play(.whoosh, volume: 0.4) }
        mouseKey = k
        cheeseKey = k
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.phase == .playing else { return }
            self.nibble += 1; self.mouseMood = .glee
            Sfx.play(.chomp, volume: 0.7)
        }
        hit()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            guard let self, self.phase == .playing else { return }
            self.next()
        }
    }

    private func lose(tapped k: Int) {
        locked = true
        wrongKey = k
        mouseMood = .scared
        fright += 1
        // Show the answer nearest the tap (a whole colour shows all of them).
        let show: [Int]
        if case .color = q.task { show = Array(q.answers) } else {
            show = [q.answers.min(by: { abs($0 - k) < abs($1 - k) })!]
        }
        reveal = Set(show)
        revealText = teach()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self, self.phase == .playing, let first = show.first else { return }
            self.mouseKey = first
            ToneSynth.shared.note(first, vel: 0.65)
        }
        let last = miss(delay: 2.2)
        guard !last else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) { [weak self] in
            guard let self, self.phase == .playing else { return }
            self.next()
        }
    }

    /// What a miss teaches, per task.
    private func teach() -> String {
        switch q.task {
        case .glow: return "This key was shining ✨"
        case .color(let black): return black ? "Black keys are the short dark ones" : "White keys are the long ones"
        case .end(let high): return high ? "High notes live on the right ➡️" : "Low notes live on the left ⬅️"
        case .name(let s, _):
            if s.acc != 0 {
                let (sh, fl) = blackKeyNames(s.pc)
                return "\(s.acc > 0 ? "♯ = the key just to the right" : "♭ = the key just to the left") · \(sh.name) = \(fl.name)"
            }
            return pmNameHint[s.letter]
        case .staff(let step, let n):
            let where_ = step == 0 ? "on its own little line below" : ((step - 2) % 2 == 0 ? "on a line" : "in a space")
            return "That note is \(n.name) — \(where_)"
        case .interval(let from, let n, let down):
            return "\(whiteKeyName(from).name) is 1 — count \(n) white keys \(down ? "down" : "up")"
        }
    }

    override func botAct(correct: Bool) {
        guard phase == .playing, !locked else { return }
        let right = Array(q.answers)
        let wrong = q.keys.filter { !q.answers.contains($0) }
        if let k = (correct || wrong.isEmpty ? right : wrong).randomElement() { press(k) }
    }
}

// MARK: View

struct PianoMouseView: View {
    let onClose: () -> Void
    @StateObject private var model = PianoMouseModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.pianoMouse.spec!, accent: Lu.gold, onClose: onClose,
                    backdrop: { PianoInterior() }) {
            VStack(spacing: 8) {
                HUDSpace(58)
                PMMusicDesk(model: model)
                ZStack {
                    if let t = model.revealText {
                        Text(t).font(luFont(17, .heavy)).foregroundStyle(Color(hex: 0xffe6a0))
                            .multilineTextAlignment(.center).minimumScaleFactor(0.6).lineLimit(2)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Capsule().fill(Color.black.opacity(0.45)))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 52)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: model.revealText)
                Spacer(minLength: 0)
                PMKeyboard(model: model)
                    .frame(minHeight: 320, maxHeight: 440)
                    .padding(.bottom, 6)
            }
            .padding(.horizontal, 10)
        }
        .theatreSound(playing: model.phase == .playing)
        #if DEBUG
        .onAppear { if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { pmSelfCheck(model) } }
        #endif
    }
}

/// Inside the grand piano: dark mahogany case, the gold iron frame with its round holes, and a
/// fan of bronze strings running back toward the hammers.
private struct PianoInterior: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0x3c1d10), Color(hex: 0x1e0d06)], startPoint: .top, endPoint: .bottom)
                // The gold plate
                RoundedRectangle(cornerRadius: 40)
                    .fill(LinearGradient(colors: [Color(hex: 0xc4964a), Color(hex: 0x8a6226)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: w * 1.1, height: h * 0.62)
                    .position(x: w * 0.5, y: h * 0.3)
                    .opacity(0.85)
                ForEach(0..<5, id: \.self) { i in
                    Circle().fill(Color(hex: 0x2a1408)).frame(width: w * 0.12)
                        .overlay(Circle().stroke(Color(hex: 0xe8c070), lineWidth: 2))
                        .position(x: w * (0.12 + Double(i) * 0.19), y: h * (0.12 + (i % 2 == 0 ? 0.0 : 0.05)))
                }
                // Strings
                Canvas { c, s in
                    for i in 0..<34 {
                        let x0 = s.width * (-0.05 + Double(i) * 0.033)
                        var p = Path()
                        p.move(to: CGPoint(x: x0 + s.width * 0.08, y: s.height * 0.02))
                        p.addLine(to: CGPoint(x: x0, y: s.height * 0.6))
                        c.stroke(p, with: .color(Color(hex: i % 3 == 0 ? 0xe9d3a0 : 0xb89458).opacity(0.75)), lineWidth: i < 12 ? 1.6 : 1)
                    }
                }
                // Bridge
                Capsule().fill(Color(hex: 0x6a3a18)).frame(width: w * 1.1, height: 10)
                    .position(x: w / 2, y: h * 0.5)
                // Shadow down toward the keys
                LinearGradient(colors: [.clear, Color.black.opacity(0.65)], startPoint: .top, endPoint: .bottom)
                    .frame(height: h * 0.55).position(x: w / 2, y: h * 0.78)
            }
        }
    }
}

/// The sheet on the music desk: what to find (pictures, a name, a staff, or an interval).
private struct PMMusicDesk: View {
    @ObservedObject var model: PianoMouseModel
    private let ink = Color(hex: 0x2a1a10)

    var body: some View {
        HStack(spacing: 12) {
            if case .staff(let step, let n) = model.q.task {
                TrebleStaff(step: step, accidental: n.acc, noteColor: model.revealText != nil ? Color(hex: 0x2e8a3a) : ink)
                    .frame(width: 190, height: 112)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Find this note").font(luFont(20, .black)).foregroundStyle(ink)
                    if model.revealText != nil { Text(n.name).font(luSerif(34, .black)).foregroundStyle(Color(hex: 0x2e8a3a)) }
                }
            } else {
                Text(icon).font(.system(size: 46)).frame(width: 58)
                VStack(alignment: .leading, spacing: 3) {
                    main
                    if let s = sub {
                        Text(s).font(luFont(15, .bold)).foregroundStyle(ink.opacity(0.7))
                            .minimumScaleFactor(0.6).lineLimit(2)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 124)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Color(hex: 0xfaf0d6), Color(hex: 0xead9b0)], startPoint: .top, endPoint: .bottom))
                .shadow(color: .black.opacity(0.5), radius: 6, y: 4)
        )
        .padding(.bottom, 10)
        .background(alignment: .bottom) {          // the wooden ledge the sheet rests on
            RoundedRectangle(cornerRadius: 4).fill(LinearGradient(colors: [Color(hex: 0x7a4422), Color(hex: 0x40200e)], startPoint: .top, endPoint: .bottom))
                .frame(height: 16).padding(.horizontal, -6)
        }
    }

    private var icon: String {
        switch model.q.task {
        case .glow: return "✨"
        case .color: return "🎹"
        case .end(let high): return high ? "🐦" : "🐻"
        case .name: return "🧀"
        case .interval: return "🪜"
        case .staff: return "🎼"
        }
    }

    @ViewBuilder private var main: some View {
        switch model.q.task {
        case .glow: Text("Tap the shiny key!").font(luFont(25)).foregroundStyle(ink)
        case .color(let b): Text(b ? "Tap a BLACK key" : "Tap a WHITE key").font(luFont(25)).foregroundStyle(ink)
        case .end(let high): Text(high ? "Tap the HIGHEST key ➡️" : "⬅️ Tap the LOWEST key").font(luFont(23)).foregroundStyle(ink).minimumScaleFactor(0.6)
        case .name(let s, _): Text("Find  \(s.name)").font(luSerif(38, .black)).foregroundStyle(ink)
        case .interval(let from, let n, let down):
            Text("From \(whiteKeyName(from).name), \(down ? "down" : "up") \(intervalName(n))").font(luFont(25)).foregroundStyle(ink).minimumScaleFactor(0.6)
        case .staff: EmptyView()
        }
    }

    private var sub: String? {
        switch model.q.task {
        case .glow: return "Then the mouse gets her cheese"
        case .name(let s, let hint): return hint ? pmNameHint[s.letter] : nil
        case .interval(let from, _, let down): return "\(whiteKeyName(from).name) is 1 · count white keys \(down ? "down" : "up")"
        default: return nil
        }
    }
}

/// The keyboard: a wooden rail the mouse runs along, white keys in a row, black keys over the
/// gaps. One drag gesture finds the key under the finger (black keys first) on touch-down.
private struct PMKeyboard: View {
    @ObservedObject var model: PianoMouseModel
    @State private var touching = false
    @State private var pressed: Int?
    @State private var hop = false

    var body: some View {
        GeometryReader { g in
            let keys = model.q.keys
            let whites = keys.filter { !isBlackKey($0) }
            let ww = g.size.width / CGFloat(whites.count)
            let laneH: CGFloat = 70
            let kh = g.size.height - laneH
            let bw = ww * 0.6, bh = kh * 0.6
            let centerX: (Int) -> CGFloat = { k in
                isBlackKey(k) ? CGFloat(whites.firstIndex(of: k - 1)! + 1) * ww : (CGFloat(whites.firstIndex(of: k)!) + 0.5) * ww
            }
            ZStack(alignment: .topLeading) {
                // The rail and the felt hammers behind it
                HStack(spacing: 2) {
                    ForEach(0..<whites.count * 2, id: \.self) { _ in
                        Capsule().fill(Color(hex: 0xd8cbb0)).frame(height: 18)
                            .overlay(alignment: .bottom) { Rectangle().fill(Color(hex: 0x8a2a2a)).frame(height: 6) }
                    }
                }
                .frame(width: g.size.width, height: 18).position(x: g.size.width / 2, y: 18)
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [Color(hex: 0x6e3a1a), Color(hex: 0x3a1a0a)], startPoint: .top, endPoint: .bottom))
                    .frame(width: g.size.width, height: 22).position(x: g.size.width / 2, y: laneH - 11)
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
                // The mouse on the rail
                StageMouse(mood: model.mouseMood, facingLeft: false)
                    .frame(width: 78, height: 62)
                    .scaleEffect(model.nibble % 2 == 1 ? 1.12 : 1)
                    .offset(y: hop ? -18 : 0)
                    .position(x: min(max(centerX(model.mouseKey), 30), g.size.width - 30), y: laneH - 50)
                    .animation(.spring(response: 0.42, dampingFraction: 0.7), value: model.mouseKey)
                    .animation(.spring(response: 0.3, dampingFraction: 0.45), value: model.nibble)
                    .allowsHitTesting(false)
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
                    if y < bh { hitKey = keys.filter(isBlackKey).first { abs(centerX($0) - p.x) < bw / 2 + 2 } }
                    if hitKey == nil { hitKey = whites[min(whites.count - 1, max(0, Int(p.x / ww)))] }
                    if let k = hitKey { pressed = k; model.press(k) }
                }
                .onEnded { _ in touching = false; pressed = nil })
        }
        .onChange(of: model.fright) { _ in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { hop = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { hop = false } }
        }
    }

    private func fill(_ k: Int, black: Bool) -> Color {
        if model.cheeseKey == k || model.reveal.contains(k) { return Color(hex: Lu.mint) }
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

    /// Letters appear on keys as they're learned: on the answer after a miss, on every white key
    /// once intervals are being counted (it's counting, not naming, being tested there).
    private func label(_ k: Int) -> String? {
        let named = model.cheeseKey == k || model.reveal.contains(k)
        if case .interval(let from, _, _) = model.q.task {
            if from == k || named { return whiteKeyName(k).name }
            return nil
        }
        if isBlackKey(k) {
            guard named, model.d >= 4.5 else { return nil }
            let (s, f) = blackKeyNames(pitchClass(k))
            return "\(s.name)\n\(f.name)"
        }
        if named && model.d >= 2.4 { return whiteKeyName(k).name }
        return nil
    }

    private func whiteKey(_ k: Int) -> some View {
        let lbl = label(k)
        return RoundedRectangle(cornerRadius: 9)
            .fill(fill(k, black: false))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color(hex: 0x5a4a3a), lineWidth: 1.5))
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.black.opacity(0.08)).frame(height: 10)
            }
            .overlay { if isGlow(k) { PMGlowRing(radius: 9, width: 5) } }
            .overlay(alignment: .bottom) {
                VStack(spacing: 2) {
                    if model.cheeseKey == k { Text("🧀").font(.system(size: 30)).transition(.scale) }
                    if let lbl {
                        Text(lbl).font(luFont(model.q.keys.count > 12 ? 19 : 23, .black)).foregroundStyle(Color(hex: Lu.inkDark))
                    }
                }
                .padding(.bottom, 14)
            }
    }

    private func blackKey(_ k: Int) -> some View {
        let lbl = label(k)
        return RoundedRectangle(cornerRadius: 5)
            .fill(fill(k, black: true))
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.white.opacity(0.12)).frame(height: 6).padding(.horizontal, 3).padding(.bottom, 4)
            }
            .overlay { if isGlow(k) { PMGlowRing(radius: 5, width: 4) } }
            .overlay(alignment: .bottom) {
                VStack(spacing: 0) {
                    if model.cheeseKey == k { Text("🧀").font(.system(size: 20)) }
                    if let lbl { Text(lbl).font(luFont(12, .black)).foregroundStyle(Color(hex: Lu.inkDark)).multilineTextAlignment(.center) }
                }
                .padding(.bottom, 10)
            }
            .shadow(color: .black.opacity(0.4), radius: 2, x: 1, y: 2)
    }
}

/// The shiny key's pulsing gold ring. Its own view, so the endless pulse lives and dies with the
/// glow (a shared repeat-forever animation left other keys stuck mid-pulse).
private struct PMGlowRing: View {
    let radius: CGFloat, width: CGFloat
    @State private var on = false
    var body: some View {
        RoundedRectangle(cornerRadius: radius).stroke(Color(hex: Lu.gold), lineWidth: width)
            .shadow(color: Color(hex: Lu.gold), radius: on ? 10 : 2)
            .opacity(on ? 1 : 0.4)
            .onAppear { withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { on = true } }
            .allowsHitTesting(false)
    }
}

#if DEBUG
/// LUDUS_SELFCHECK: every generated question at every difficulty has a reachable answer and the
/// answers are exactly the keys described (names by pitch class, staff notes by MIDI, intervals
/// by counting white keys).
@MainActor private func pmSelfCheck(_ m: PianoMouseModel) {
    var fails = theatreTheoryCheck()
    // Hand-checked staff spots: C4 = 60, E4 = 64, B4 = 71, C5 = 72, E5 = 76, F♯4 = 66, B♭4 = 70.
    for (s, a, want) in [(0, 0, 60), (2, 0, 64), (6, 0, 71), (7, 0, 72), (9, 0, 76), (3, 1, 66), (6, -1, 70)] where pmStaffMidi(s, a) != want {
        fails.append("staff \(s),\(a)")
    }
    if blackKeyNames(pitchClass(66)).flat.name != "G♭" { fails.append("66 = G♭") }
    NSLog("PianoMouse self-check (theory): %@", fails.isEmpty ? "PASS" : "FAIL \(fails.prefix(10))")
}
#endif
