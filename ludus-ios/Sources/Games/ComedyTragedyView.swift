import SwiftUI

// MARK: - Comedy & Tragedy (Theatre · Music)
//
// An open-air Roman theatre at dusk. The great masks hang on the stage wall, waiting for the
// music. A chord (or a little tune) plays: is it HAPPY or SAD? Tap the mask that fits — comedy
// (major) or tragedy (minor). The right mask comes alive (comedy laughs and bounces, tragedy
// weeps) and the crowd's lamps flare. A miss lights the right mask, says what it was, and plays
// the music again so the ear connects the two. A 🔁 hear-again button is always there, and the
// next piece never starts before the last one ends.
//
// Continuous ladder (all off `d`):
//   1     C major vs C minor, wide block chords; the right mask glows for the first answers
//   ~2.2  any root (C … B, with flats and sharps) fades in
//   2.4   broken chords (arpeggios, up and back down) fade in
//   3.6   short tunes in a major or a minor key (only the 3rd of the scale differs)
//   5     + 😱 SPOOKY = diminished (a third mask)
//   6.5   + 😵‍💫 DREAMY = augmented (a fourth mask)
//   7     the masks carry chord names for the root shown: D · Dm · D° · D+
//   8     the chord's notes are spelled out too; close voicings creep in (harder to hear)

private enum CTMood: Int, CaseIterable {
    case happy, sad, spooky, dreamy
    var quality: ChordQuality { ChordQuality(rawValue: rawValue)! }
    var word: String { ["HAPPY", "SAD", "SPOOKY", "DREAMY"][rawValue] }
    var emoji: String { ["😀", "😢", "😱", "😵‍💫"][rawValue] }
    var hex: UInt { [Lu.gold, Lu.sky, Lu.grape, Lu.mint][rawValue] }
    /// The mask's colour (gilded comedy, silver-blue tragedy, violet spook, sea-green dream).
    var face: (UInt, UInt) { [(0xffe38a, 0xd89a2a), (0xcfe4f2, 0x6f9ab8), (0xd9c2f0, 0x8a5cb8), (0xc6f0d4, 0x4fa078)][rawValue] }
}

private enum CTKind { case block, arpeggio, melody }

private struct CTItem {
    var mood: CTMood
    var root: Spelled
    var kind: CTKind
    var events: [ToneEvent]
    var options: [CTMood]
    var names: Bool             // the masks show chord names
    var spelled: [Spelled]?     // the chord's notes on show
    var name: String { chordName(root, mood.quality) }
}

private let ctRoots = ["C", "D♭", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"].map { Spelled($0) }
/// Minor and diminished chords take the sharp name for those two keys (C♯m, not D♭m — which would need F♭).
private let ctRootsMinor = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "G♯", "A", "B♭", "B"].map { Spelled($0) }
/// Notes a young reader shouldn't meet in a spelling: F♭, C♭, E♯, B♯.
private let ctOddNotes: Set<Spelled> = [Spelled("F♭"), Spelled("C♭"), Spelled("E♯"), Spelled("B♯")]
private func ctRootOK(_ root: Spelled, _ q: ChordQuality, _ moods: [CTMood]) -> Bool {
    guard !moods.contains(where: { spellTriad(root, $0.quality) == nil }), let notes = spellTriad(root, q) else { return false }
    return ctOddNotes.isDisjoint(with: notes)
}
/// Scale-degree tunes (0 = tonic … 4 = 5th); every one uses the 3rd, the note that makes it major or minor.
private let ctTunes: [[Int]] = [[0, 1, 2, 1, 0], [0, 2, 4, 2, 0], [4, 3, 2, 1, 0], [0, 1, 2, 3, 4, 2, 0], [2, 1, 0, 1, 2, 2, 2], [0, 2, 1, 3, 2, 0]]

@MainActor
private final class ComedyModel: ArcadeModel {
    @Published var item: CTItem
    @Published var revealed = false
    @Published var chosen: CTMood?
    @Published var listening = false
    @Published var heard = false
    @Published var performer: CTMood?
    @Published var lesson: String?
    @Published var hint = false
    @Published var shows = 0
    private var soundUntil = Date.distantPast
    private var playToken = 0

    init() {
        item = CTItem(mood: .happy, root: Spelled("C"), kind: .block, events: [], options: [.happy, .sad], names: false, spelled: nil)
        super.init(key: GameID.comedyTragedy.rawValue)
    }
    override func onBegin() { item.mood = .happy; next() }
    override func perLevel(_ level: Int) -> Int { level <= 2 ? 4 : 6 }

    /// Builds the next piece off `d`.
    func make(last: CTMood?) -> CTItem {
        var moods: [CTMood] = [.happy, .sad]
        if d >= 5 { moods.append(.spooky) }
        if d >= 6.5 { moods.append(.dreamy) }
        var mood: CTMood
        switch tier([1, 5, 6.5], fadeIn: 1.2, keep: 0.5) {
        case 1: mood = .spooky
        case 2: mood = .dreamy
        default: mood = Bool.random() ? .happy : .sad
        }
        if mood == last && Bool.random() { mood = moods.randomElement()! }   // fewer long runs
        let names = chance(1, from: 7, to: 8)
        var root = Spelled("C")
        if Double.random(in: 0..<1) < ramp(0, 0.85, from: 2.2, to: 3.5) {
            let pool = mood.quality == .minor || mood.quality == .diminished ? ctRootsMinor : ctRoots
            repeat { root = pool.randomElement()! } while !ctRootOK(root, mood.quality, moods)
        }
        let r = root.pc <= 6 ? 60 + root.pc : 48 + root.pc          // G3 … F♯4
        let q = mood.quality
        var kind: CTKind = [.block, .arpeggio, .melody][tier([1, 2.4, 3.6])]
        if kind == .melody && q.rawValue > 1 { kind = .arpeggio }
        let close = chance(0.5, from: 8, to: 10)
        var ev: [ToneEvent] = []
        switch kind {
        case .block:
            let notes = close ? [r, r + q.third, r + q.fifth] : [r - 12, r - 12 + q.fifth, r + q.third, r + 12]
            ev = notes.enumerated().map { ToneEvent(at: Double($0.offset) * 0.03, midi: $0.element, vel: 0.6, dur: close ? 1.1 : 1.6) }
        case .arpeggio:
            let notes = [r, r + q.third, r + q.fifth, r + 12, r + q.fifth, r + q.third, r]
            let beat = ramp(0.3, 0.2, from: 2.4, to: 8), total = Double(notes.count) * beat + 0.5
            ev = notes.enumerated().map { ToneEvent(at: Double($0.offset) * beat, midi: $0.element, vel: 0.6, dur: total - Double($0.offset) * beat) }
            ev.append(ToneEvent(at: 0, midi: r - 12, vel: 0.4, dur: total))
        case .melody:
            let scale = q == .major ? [0, 2, 4, 5, 7] : [0, 2, 3, 5, 7]
            let tune = ctTunes.randomElement()!
            let beat = ramp(0.4, 0.28, from: 3.6, to: 9)
            ev = tune.enumerated().map { ToneEvent(at: Double($0.offset) * beat, midi: r + 12 + scale[$0.element], vel: 0.65,
                                                   dur: $0.offset == tune.count - 1 ? 1.1 : beat * 0.95) }
            let end = Double(tune.count - 1) * beat
            ev += [r - 12, r, r + q.third, r + q.fifth].map { ToneEvent(at: end, midi: $0, vel: 0.32, dur: 1.1) }
        }
        return CTItem(mood: mood, root: root, kind: kind, events: ev, options: moods, names: names,
                      spelled: names && chance(1, from: 8, to: 9.5) ? spellTriad(root, q) : nil)
    }

    private func next() {
        item = make(last: item.mood)
        hint = Double.random(in: 0..<1) < ramp(1, 0, from: 1, to: 1.8)
        revealed = false; chosen = nil; lesson = nil; performer = nil; heard = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self, self.phase == .playing else { return }
            self.play()
        }
    }

    func play(then: (() -> Void)? = nil) {
        guard phase == .playing, !listening else { return }
        let d = ToneSynth.shared.play(item.events)
        heard = true; listening = true
        soundUntil = Date().addingTimeInterval(d)
        playToken += 1
        let tok = playToken
        DispatchQueue.main.asyncAfter(deadline: .now() + d) { [weak self] in
            guard let self, self.playToken == tok else { return }
            self.listening = false
            then?()
        }
    }

    func replay() { if !revealed { play() } }

    func choose(_ m: CTMood) {
        guard phase == .playing, heard, !revealed else { return }
        revealed = true; chosen = m
        hint = false
        let wait = max(0, soundUntil.timeIntervalSinceNow)
        if m == item.mood {
            performer = m; shows += 1
            Sfx.play(.sparkle, volume: 0.6)
            hit()
            DispatchQueue.main.asyncAfter(deadline: .now() + max(1.5, wait + 0.5)) { [weak self] in
                guard let self, self.phase == .playing else { return }
                self.next()
            }
        } else {
            performer = item.mood
            lesson = item.names ? "It was \(item.name) — \(item.root.name) \(item.mood.quality.word)"
                                : "It was \(item.mood.word) \(item.mood.emoji) — \(item.mood.quality.word)"
            let lastHeart = miss(delay: wait + 3.2)
            // Hear it again, now knowing what it was; move on once it has finished.
            DispatchQueue.main.asyncAfter(deadline: .now() + wait + 0.4) { [weak self] in
                guard let self, self.phase == .playing else { return }
                self.listening = false
                self.play { [weak self] in
                    guard let self, self.phase == .playing, !lastHeart else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                        guard let self, self.phase == .playing else { return }
                        self.next()
                    }
                }
            }
        }
    }

    override func botAct(correct: Bool) {
        guard phase == .playing, heard, !revealed else { return }
        let wrong = item.options.filter { $0 != item.mood }
        choose(correct || wrong.isEmpty ? item.mood : wrong.randomElement()!)
    }
}

// MARK: View

struct ComedyTragedyView: View {
    let onClose: () -> Void
    @StateObject private var model = ComedyModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.comedyTragedy.spec!, accent: Lu.gold, onClose: onClose,
                    backdrop: { CTTheatre(lit: model.performer.map { Color(hex: $0.hex) }) }) {
            VStack(spacing: 8) {
                HUDSpace(58)
                caption.frame(height: 50)
                CTMasks(model: model)
                ZStack {
                    if let l = model.lesson {
                        Text(l).font(luFont(18, .heavy)).foregroundStyle(Color(hex: 0xffe6a0))
                            .multilineTextAlignment(.center).minimumScaleFactor(0.6).lineLimit(2)
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(Capsule().fill(Color.black.opacity(0.5)))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 52)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: model.lesson)
                Spacer(minLength: 0)
                HStack(spacing: 10) {
                    ReplayButton(enabled: !model.listening && !model.revealed && model.heard) { model.replay() }
                    SoundHint()
                }
                .frame(height: 58)
                .padding(.bottom, 14)
            }
            .padding(.horizontal, 14)
        }
        .theatreSound(playing: model.phase == .playing)
        #if DEBUG
        .onAppear { if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { ctSelfCheck(model) } }
        #endif
    }

    @ViewBuilder private var caption: some View {
        Group {
            if let s = model.item.spelled {
                HStack(spacing: 14) {
                    ForEach(Array(s.enumerated()), id: \.offset) { _, n in
                        Text(n.name).font(luSerif(30, .black)).foregroundStyle(Color(hex: Lu.ink))
                    }
                }
            } else if model.item.names {
                Text("Root: \(model.item.root.name)").font(luSerif(28, .black)).foregroundStyle(Color(hex: Lu.ink))
            } else {
                HStack(spacing: 8) {
                    if model.listening { CTNotes() }
                    Text(model.listening ? "Listen…" : (model.revealed ? " " : (model.item.options.count > 2 ? "Which mood?" : "Happy or sad?")))
                        .font(luFont(22, .heavy)).foregroundStyle(Color(hex: Lu.ink))
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 6)
        .background(Capsule().fill(Color.black.opacity(0.35)))
    }
}

/// Little notes bouncing while the music plays.
private struct CTNotes: View {
    @State private var up = false
    var body: some View {
        HStack(spacing: 2) {
            Text("♪").offset(y: up ? -4 : 3)
            Text("♫").offset(y: up ? 3 : -4)
        }
        .font(.system(size: 24, weight: .bold)).foregroundStyle(Color(hex: Lu.gold))
        .onAppear { withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) { up = true } }
    }
}

/// The theatre: a dusk sky, the stone stage wall (scaenae frons) with columns and arches, the
/// semicircle of stone seats, and oil lamps along the stage edge that flare when a mask performs.
private struct CTTheatre: View {
    var lit: Color?
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0x1b1b4a), Color(hex: 0x5a3a6e), Color(hex: 0xe08a5a)], startPoint: .top, endPoint: .bottom)
                // Stars
                Canvas { c, s in
                    var rng = SeededRNG(seed: 7)
                    for _ in 0..<40 {
                        let x = Double(rng.next() % 1000) / 1000 * s.width, y = Double(rng.next() % 1000) / 1000 * s.height * 0.3
                        c.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)), with: .color(.white.opacity(0.7)))
                    }
                }
                // Stage wall
                Canvas { c, s in
                    let top = s.height * 0.16, bottom = s.height * 0.78
                    let stone = Color(hex: 0xc9a77c), dark = Color(hex: 0x8a6a48)
                    c.fill(Path(CGRect(x: 0, y: top, width: s.width, height: bottom - top)), with: .linearGradient(
                        Gradient(colors: [stone, dark]), startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: bottom)))
                    // Cornice
                    c.fill(Path(CGRect(x: -10, y: top - 14, width: s.width + 20, height: 18)), with: .color(Color(hex: 0xe0c49a)))
                    c.fill(Path(CGRect(x: -10, y: top + 4, width: s.width + 20, height: 4)), with: .color(dark))
                    // Arched doorways and columns
                    let n = 4
                    for i in 0..<n {
                        let cx = s.width * (Double(i) + 0.5) / Double(n)
                        let aw = s.width / Double(n) * 0.5
                        var arch = Path()
                        arch.move(to: CGPoint(x: cx - aw / 2, y: bottom))
                        arch.addLine(to: CGPoint(x: cx - aw / 2, y: top + s.height * 0.22))
                        arch.addArc(center: CGPoint(x: cx, y: top + s.height * 0.22), radius: aw / 2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                        arch.addLine(to: CGPoint(x: cx + aw / 2, y: bottom))
                        c.fill(arch, with: .color(Color(hex: 0x2a1a24).opacity(0.85)))
                    }
                    for i in 0...n {
                        let x = s.width * Double(i) / Double(n)
                        let cw = 16.0
                        c.fill(Path(CGRect(x: x - cw / 2, y: top + 10, width: cw, height: bottom - top - 10)), with: .color(Color(hex: 0xf0dcb8)))
                        for f in 0..<3 {
                            c.fill(Path(CGRect(x: x - cw / 2 + 3 + Double(f) * 4, y: top + 14, width: 1.2, height: bottom - top - 18)), with: .color(dark.opacity(0.6)))
                        }
                        c.fill(Path(CGRect(x: x - cw / 2 - 4, y: top + 8, width: cw + 8, height: 7)), with: .color(Color(hex: 0xe0c49a)))
                    }
                    // Stage floor
                    c.fill(Path(CGRect(x: 0, y: bottom, width: s.width, height: s.height * 0.06)), with: .linearGradient(
                        Gradient(colors: [Color(hex: 0x7a4a2a), Color(hex: 0x4a2a16)]), startPoint: CGPoint(x: 0, y: bottom), endPoint: CGPoint(x: 0, y: bottom + s.height * 0.06)))
                    // Seats: stone arcs in the foreground
                    for i in 0..<4 {
                        let y = s.height * (0.86 + Double(i) * 0.05)
                        var p = Path()
                        p.move(to: CGPoint(x: -20, y: y - 18))
                        p.addQuadCurve(to: CGPoint(x: s.width + 20, y: y - 18), control: CGPoint(x: s.width / 2, y: y + 22))
                        p.addLine(to: CGPoint(x: s.width + 20, y: s.height + 40)); p.addLine(to: CGPoint(x: -20, y: s.height + 40)); p.closeSubpath()
                        c.fill(p, with: .color(Color(hex: i % 2 == 0 ? 0x8f7356 : 0x7a6048)))
                    }
                }
                // Lamps along the stage edge
                HStack {
                    ForEach(0..<5, id: \.self) { _ in
                        VStack(spacing: 0) {
                            Ellipse().fill(RadialGradient(colors: [Color(hex: 0xfff2b0), (lit ?? Color(hex: 0xffa040)).opacity(0.6), .clear],
                                                          center: .center, startRadius: 0, endRadius: lit == nil ? 14 : 26))
                                .frame(width: 52, height: 52)
                            Capsule().fill(Color(hex: 0x3a2414)).frame(width: 18, height: 7).offset(y: -18)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .position(x: w / 2, y: h * 0.77)
                .animation(.easeInOut(duration: 0.4), value: lit == nil)
            }
        }
    }
}

/// A tiny deterministic RNG so the stars don't jump between redraws.
private struct SeededRNG {
    var state: UInt64
    init(seed: UInt64) { state = seed &* 0x9E3779B97F4A7C15 | 1 }
    mutating func next() -> UInt64 { state ^= state << 13; state ^= state >> 7; state ^= state << 17; return state }
}

/// The masks hang on the wall: 2 big ones, then 3, then a 2×2. They sway while the run plays;
/// the performing one bounces (comedy), droops and weeps (tragedy) or floats.
private struct CTMasks: View {
    @ObservedObject var model: ComedyModel
    @State private var sway = false

    var body: some View {
        let opts = model.item.options
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: opts.count == 3 ? 3 : 2)
        LazyVGrid(columns: cols, spacing: 12) {
            ForEach(Array(opts.enumerated()), id: \.element) { i, m in
                maskButton(m, height: opts.count <= 2 ? 250 : (opts.count == 3 ? 200 : 170))
                    .rotationEffect(.degrees(sway ? (i % 2 == 0 ? -3 : 3) : 0), anchor: .top)
            }
        }
        .onAppear { setSway(model.phase == .playing) }
        .onChange(of: model.phase) { setSway($0 == .playing) }
    }

    private func setSway(_ on: Bool) {
        if on { withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { sway = true } }
        else { withAnimation(.easeOut(duration: 0.2)) { sway = false } }
    }

    private func maskButton(_ m: CTMood, height: CGFloat) -> some View {
        let it = model.item
        let right = model.revealed && m == it.mood
        let wrong = model.revealed && model.chosen == m && m != it.mood
        let hinted = model.hint && m == it.mood && !model.revealed
        let small = it.options.count > 2
        return Button { model.choose(m) } label: {
            VStack(spacing: 2) {
                // Hanging cord
                Rectangle().fill(Color(hex: 0x5a3a20)).frame(width: 3, height: 14)
                CTMaskFace(mood: m, performing: model.performer == m, dim: model.revealed && !right && !wrong)
                    .frame(width: small ? 98 : 164, height: small ? 112 : 188)
                    .shadow(color: hinted || right ? Color(hex: m.hex) : .black.opacity(0.5), radius: hinted || right ? 16 : 6)
                    .overlay(alignment: .topTrailing) {
                        if wrong { Text("✗").font(luFont(30, .black)).foregroundStyle(Color(hex: Lu.coral)) }
                    }
                VStack(spacing: 0) {
                    if it.names {
                        Text(chordName(it.root, m.quality)).font(luSerif(small ? 24 : 30, .black)).foregroundStyle(Color(hex: Lu.inkDark))
                    }
                    Text(m.word).font(luFont(small ? 14 : 19, .black)).foregroundStyle(Color(hex: Lu.inkDark))
                }
                .padding(.horizontal, 10).padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: right ? 0xb8f0b0 : 0xf3e6c8)))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: 0x6a4a28), lineWidth: 1.5))
            }
            .frame(maxWidth: .infinity, minHeight: height)
            .contentShape(Rectangle())
            .scaleEffect(right ? 1.06 : (hinted ? 1.04 : 1))
            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: model.revealed)
        }
        .buttonStyle(.plain)
    }
}

/// A theatre mask drawn with a Canvas: a shield-shaped face with carved eye holes and an open
/// mouth whose shape is the mood. Performing: comedy bounces, tragedy weeps, the others float.
private struct CTMaskFace: View {
    let mood: CTMood
    var performing = false
    var dim = false
    @State private var t = false

    var body: some View {
        Canvas { c, s in
            let w = s.width, h = s.height
            // Face: a rounded shield
            var face = Path()
            face.move(to: CGPoint(x: w * 0.5, y: h * 0.02))
            face.addCurve(to: CGPoint(x: w * 0.98, y: h * 0.32), control1: CGPoint(x: w * 0.82, y: h * 0.02), control2: CGPoint(x: w * 0.98, y: h * 0.12))
            face.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.99), control1: CGPoint(x: w * 0.98, y: h * 0.7), control2: CGPoint(x: w * 0.75, y: h * 0.99))
            face.addCurve(to: CGPoint(x: w * 0.02, y: h * 0.32), control1: CGPoint(x: w * 0.25, y: h * 0.99), control2: CGPoint(x: w * 0.02, y: h * 0.7))
            face.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.02), control1: CGPoint(x: w * 0.02, y: h * 0.12), control2: CGPoint(x: w * 0.18, y: h * 0.02))
            let (hi, lo) = mood.face
            c.fill(face, with: .linearGradient(Gradient(colors: [Color(hex: hi), Color(hex: lo)]),
                                               startPoint: CGPoint(x: w * 0.3, y: 0), endPoint: CGPoint(x: w * 0.7, y: h)))
            c.stroke(face, with: .color(Color(hex: 0x3a2414).opacity(0.6)), lineWidth: 2)
            let hole = Color(hex: 0x1a0e16)
            // Brows + eyes
            func eye(_ cx: Double, _ flip: Double) {
                var e = Path()
                switch mood {
                case .happy:   // crescent eyes, smiling
                    e.move(to: CGPoint(x: (cx - 0.12) * w, y: 0.4 * h))
                    e.addQuadCurve(to: CGPoint(x: (cx + 0.12) * w, y: 0.4 * h), control: CGPoint(x: cx * w, y: 0.26 * h))
                    e.addQuadCurve(to: CGPoint(x: (cx - 0.12) * w, y: 0.4 * h), control: CGPoint(x: cx * w, y: 0.34 * h))
                case .sad:     // eyes sloping down at the outside
                    e.move(to: CGPoint(x: (cx - 0.12 * flip) * w, y: 0.42 * h))
                    e.addQuadCurve(to: CGPoint(x: (cx + 0.12 * flip) * w, y: 0.34 * h), control: CGPoint(x: (cx - 0.02 * flip) * w, y: 0.48 * h))
                    e.addQuadCurve(to: CGPoint(x: (cx - 0.12 * flip) * w, y: 0.42 * h), control: CGPoint(x: cx * w, y: 0.33 * h))
                case .spooky:  // big round staring eyes
                    e.addEllipse(in: CGRect(x: (cx - 0.1) * w, y: 0.27 * h, width: 0.2 * w, height: 0.17 * h))
                case .dreamy:  // sleepy half-closed
                    e.move(to: CGPoint(x: (cx - 0.12) * w, y: 0.37 * h))
                    e.addQuadCurve(to: CGPoint(x: (cx + 0.12) * w, y: 0.37 * h), control: CGPoint(x: cx * w, y: 0.46 * h))
                    e.closeSubpath()
                }
                c.fill(e, with: .color(hole))
                var brow = Path()
                let by: Double = mood == .spooky ? 0.2 : 0.25
                switch mood {
                case .sad:
                    brow.move(to: CGPoint(x: (cx + 0.1 * flip) * w, y: by * h - 7))
                    brow.addLine(to: CGPoint(x: (cx - 0.12 * flip) * w, y: by * h + 5))
                default:
                    brow.move(to: CGPoint(x: (cx - 0.12) * w, y: by * h))
                    brow.addQuadCurve(to: CGPoint(x: (cx + 0.12) * w, y: by * h), control: CGPoint(x: cx * w, y: (by - 0.06) * h))
                }
                c.stroke(brow, with: .color(Color(hex: lo).opacity(0.9)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            eye(0.32, 1); eye(0.68, -1)
            // Mouth
            var m = Path()
            switch mood {
            case .happy:
                m.move(to: CGPoint(x: 0.24 * w, y: 0.6 * h))
                m.addQuadCurve(to: CGPoint(x: 0.76 * w, y: 0.6 * h), control: CGPoint(x: 0.5 * w, y: 0.64 * h))
                m.addQuadCurve(to: CGPoint(x: 0.24 * w, y: 0.6 * h), control: CGPoint(x: 0.5 * w, y: (performing && t ? 0.98 : 0.9) * h))
            case .sad:
                m.move(to: CGPoint(x: 0.26 * w, y: 0.8 * h))
                m.addQuadCurve(to: CGPoint(x: 0.74 * w, y: 0.8 * h), control: CGPoint(x: 0.5 * w, y: 0.56 * h))
                m.addQuadCurve(to: CGPoint(x: 0.26 * w, y: 0.8 * h), control: CGPoint(x: 0.5 * w, y: 0.72 * h))
            case .spooky:
                m.addEllipse(in: CGRect(x: 0.38 * w, y: 0.6 * h, width: 0.24 * w, height: (performing && t ? 0.3 : 0.24) * h))
            case .dreamy:
                m.move(to: CGPoint(x: 0.3 * w, y: 0.7 * h))
                m.addCurve(to: CGPoint(x: 0.7 * w, y: 0.7 * h), control1: CGPoint(x: 0.43 * w, y: 0.62 * h), control2: CGPoint(x: 0.57 * w, y: 0.78 * h))
                m.addCurve(to: CGPoint(x: 0.3 * w, y: 0.7 * h), control1: CGPoint(x: 0.57 * w, y: 0.84 * h), control2: CGPoint(x: 0.43 * w, y: 0.7 * h))
            }
            c.fill(m, with: .color(hole))
            // Cheeks
            if mood == .happy || mood == .dreamy {
                c.fill(Path(ellipseIn: CGRect(x: 0.12 * w, y: 0.5 * h, width: 0.14 * w, height: 0.08 * h)), with: .color(Color(hex: 0xf08a7a).opacity(0.5)))
                c.fill(Path(ellipseIn: CGRect(x: 0.74 * w, y: 0.5 * h, width: 0.14 * w, height: 0.08 * h)), with: .color(Color(hex: 0xf08a7a).opacity(0.5)))
            }
            // Tears while weeping
            if mood == .sad && performing {
                for (x, off) in [(0.24, 0.0), (0.72, 0.5)] {
                    let y = 0.45 + ((t ? 0.35 : 0.05) + off * 0.1)
                    var d = Path()
                    d.move(to: CGPoint(x: x * w, y: (y - 0.07) * h))
                    d.addQuadCurve(to: CGPoint(x: x * w, y: (y + 0.04) * h), control: CGPoint(x: (x + 0.07) * w, y: (y + 0.02) * h))
                    d.addQuadCurve(to: CGPoint(x: x * w, y: (y - 0.07) * h), control: CGPoint(x: (x - 0.07) * w, y: (y + 0.02) * h))
                    c.fill(d, with: .color(Color(hex: 0x6ac0f0)))
                }
            }
        }
        .offset(y: performing ? (mood == .happy ? (t ? -14 : 0) : (mood == .sad ? 4 : (t ? -8 : 0))) : 0)
        .rotationEffect(.degrees(performing ? (mood == .happy ? (t ? 8 : -8) : (mood == .dreamy ? (t ? -6 : 6) : 0)) : 0))
        .opacity(dim ? 0.45 : 1)
        .onChange(of: performing) { p in
            t = false
            if p { withAnimation(.easeInOut(duration: 0.3).repeatCount(6, autoreverses: true)) { t = true } }
        }
    }
}

#if DEBUG
/// LUDUS_SELFCHECK: across the whole difficulty range each piece's notes really are the answer's
/// chord quality, tunes use the scale's 3rd, options are distinct and contain the answer, and
/// chord names/spellings exist and match.
@MainActor private func ctSelfCheck(_ model: ComedyModel) {
    var fails = theatreTheoryCheck()
    var last: CTMood?
    for _ in 0..<3000 {
        let it = model.make(last: last); last = it.mood
        if !it.options.contains(it.mood) || Set(it.options).count != it.options.count { fails.append("options") }
        let q = it.mood.quality
        let pcs = Set(it.events.filter { $0.voice == .piano }.map { (pitchClass($0.midi) - it.root.pc + 12) % 12 })
        switch it.kind {
        case .block, .arpeggio: if pcs != [0, q.third, q.fifth] { fails.append("chord shape \(it.name) \(pcs.sorted())") }
        case .melody: if q.rawValue > 1 || !pcs.contains(q.third) || pcs.contains(q == .major ? 3 : 4) { fails.append("tune \(it.name)") }
        }
        for o in it.options where spellTriad(it.root, o.quality) == nil { fails.append("unspellable \(it.root.name)\(o.quality.suffix)") }
        if let notes = spellTriad(it.root, q), !ctOddNotes.isDisjoint(with: notes) { fails.append("odd spelling \(it.name)") }
    }
    NSLog("ComedyTragedy self-check: %@", fails.isEmpty ? "PASS" : "FAIL \(Array(Set(fails)).prefix(10))")
}
#endif
