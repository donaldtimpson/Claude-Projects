import SwiftUI

// MARK: - Comedy & Tragedy (Theatre · Music)
//
// The actors wait for the music. A chord (or a little tune) plays; is it HAPPY or SAD? Tap the
// comedy mask 😀 (major) or the tragedy mask 😢 (minor). The right mask's actor takes the stage
// and performs — the comedian dances, the tragedian weeps buckets — to applause. A miss lights
// the right mask, says what it was, and plays the music again so the ear connects the two.
// There's always a 🔁 hear-again button, and the next piece never starts before the last ends.
//
// Ladder (no clock):
//   I     C major vs C minor, block chords voiced wide; the first 3 pieces light the right mask
//   II    the same from any root (C … B, with flats and sharps)
//   III   broken chords (arpeggios, up and back down)
//   IV    short tunes in a major or a minor key (only the 3rd of the scale differs)
//   V     + 😱 SPOOKY = diminished (three masks)
//   VI    + 😵‍💫 DREAMY = augmented (four masks)
//   VII   the masks carry chord names for the root shown: D · Dm · D° · D+
//   VIII+ the chord's notes are spelled out too (D F♯ A → D); endless.

private enum CTMood: Int, CaseIterable {
    case happy, sad, spooky, dreamy
    var quality: ChordQuality { ChordQuality(rawValue: rawValue)! }
    var mask: String { ["😀", "😢", "😱", "😵‍💫"][rawValue] }
    var word: String { ["HAPPY", "SAD", "SPOOKY", "DREAMY"][rawValue] }
    var actor: String { ["🥳", "😭", "👻", "🦄"][rawValue] }
    var hex: UInt { [Lu.gold, Lu.sky, Lu.grape, Lu.mint][rawValue] }
}

private enum CTKind { case block, arpeggio, melody }

private struct CTItem {
    var mood: CTMood
    var root: Spelled
    var kind: CTKind
    var events: [ToneEvent]
    var options: [CTMood]
    var names: Bool             // VII+: masks show chord names
    var spelled: [Spelled]?     // VIII+: the chord's notes on show
    var name: String { chordName(root, mood.quality) }
}

private let ctRoots = ["C", "D♭", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"].map { Spelled($0) }
/// Minor and diminished chords take the sharp name for those two keys (C♯m, not D♭m — which would need F♭).
private let ctRootsMinor = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "G♯", "A", "B♭", "B"].map { Spelled($0) }
/// Notes a young reader shouldn't meet in a spelling: F♭, C♭, E♯, B♯.
private let ctOddNotes: Set<Spelled> = [Spelled("F♭"), Spelled("C♭"), Spelled("E♯"), Spelled("B♯")]
/// The answer's root is usable if every option's chord spells, and the answer's own spelling
/// has no F♭ / C♭ / E♯ / B♯.
private func ctRootOK(_ root: Spelled, _ q: ChordQuality, _ moods: [CTMood]) -> Bool {
    guard !moods.contains(where: { spellTriad(root, $0.quality) == nil }), let notes = spellTriad(root, q) else { return false }
    return ctOddNotes.isDisjoint(with: notes)
}
/// Scale-degree tunes (0 = tonic … 4 = 5th); every one uses the 3rd, the note that makes it major or minor.
private let ctTunes: [[Int]] = [[0, 1, 2, 1, 0], [0, 2, 4, 2, 0], [4, 3, 2, 1, 0], [0, 1, 2, 3, 4, 2, 0], [2, 1, 0, 1, 2, 2, 2], [0, 2, 1, 3, 2, 0]]

private func ctMake(_ level: Int, last: CTMood?) -> CTItem {
    var moods: [CTMood] = [.happy, .sad]
    if level >= 5 { moods.append(.spooky) }
    if level >= 6 { moods.append(.dreamy) }
    let names = level >= 7
    var mood = moods.randomElement()!
    if mood == last && Bool.random() { mood = moods.randomElement()! }   // fewer long runs of one answer
    // A root whose chords (all the options' qualities) spell without double sharps/flats, and
    // whose answer chord spells without F♭ / C♭ / E♯ / B♯.
    var root = Spelled("C")
    if level >= 2 {
        let pool = mood.quality == .minor || mood.quality == .diminished ? ctRootsMinor : ctRoots
        repeat { root = pool.randomElement()! } while !ctRootOK(root, mood.quality, moods)
    }
    let r = root.pc <= 6 ? 60 + root.pc : 48 + root.pc          // G3 … F♯4
    let q = mood.quality
    var kind = CTKind.block
    switch level {
    case 1, 2: kind = .block
    case 3: kind = Int.random(in: 0..<10) < 7 ? .arpeggio : .block
    default:
        let tune = level == 4 ? 5 : 3
        let k = Int.random(in: 0..<10)
        kind = k < tune && q.rawValue <= 1 ? .melody : (k % 2 == 0 ? .arpeggio : .block)
    }
    var ev: [ToneEvent] = []
    switch kind {
    case .block:
        ev = [r - 12, r - 12 + q.fifth, r + q.third, r + 12].enumerated()
            .map { ToneEvent(at: Double($0.offset) * 0.03, midi: $0.element, vel: 0.6, dur: 1.6) }
    case .arpeggio:
        let notes = [r, r + q.third, r + q.fifth, r + 12, r + q.fifth, r + q.third, r]
        let beat = 0.26, total = Double(notes.count) * beat + 0.5
        ev = notes.enumerated().map { ToneEvent(at: Double($0.offset) * beat, midi: $0.element, vel: 0.6, dur: total - Double($0.offset) * beat) }
        ev.append(ToneEvent(at: 0, midi: r - 12, vel: 0.4, dur: total))
    case .melody:
        let scale = q == .major ? [0, 2, 4, 5, 7] : [0, 2, 3, 5, 7]
        let tune = ctTunes.randomElement()!
        let beat = 0.36
        ev = tune.enumerated().map { ToneEvent(at: Double($0.offset) * beat, midi: r + 12 + scale[$0.element], vel: 0.65,
                                               dur: $0.offset == tune.count - 1 ? 1.1 : beat * 0.95) }
        let end = Double(tune.count - 1) * beat
        ev += [r - 12, r, r + q.third, r + q.fifth].map { ToneEvent(at: end, midi: $0, vel: 0.32, dur: 1.1) }
    }
    return CTItem(mood: mood, root: root, kind: kind, events: ev, options: moods, names: names,
                  spelled: level >= 8 ? spellTriad(root, q) : nil)
}

@MainActor
private final class ComedyModel: ArcadeModel {
    @Published var item = ctMake(1, last: nil)
    @Published var revealed = false
    @Published var chosen: CTMood?
    @Published var listening = false
    @Published var heard = false            // the piece has started at least once
    @Published var performer: CTMood?
    @Published var lesson: String?
    @Published var shows = 0
    private var seenAtOne = 0
    private var soundUntil = Date.distantPast
    private var playToken = 0

    init() { super.init(key: GameID.comedyTragedy.rawValue) }
    override func onBegin() { seenAtOne = 0; next() }

    /// Level I's first three pieces light the right mask.
    var hint: Bool { level == 1 && seenAtOne <= 3 && !revealed }

    private func next() {
        item = ctMake(level, last: item.mood)
        if level == 1 { seenAtOne += 1 }
        revealed = false; chosen = nil; lesson = nil; performer = nil; heard = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
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
        let right = m == item.mood
        let wait = max(0, soundUntil.timeIntervalSinceNow)
        if right {
            performer = m; shows += 1
            hit()
            // Never move on before the music has finished.
            DispatchQueue.main.asyncAfter(deadline: .now() + max(1.3, wait + 0.5)) { [weak self] in
                guard let self, self.phase == .playing else { return }
                self.next()
            }
        } else {
            performer = item.mood
            lesson = item.names ? "It was \(item.name) — \(item.root.name) \(item.mood.quality.word)"
                                : "It was \(item.mood.word) \(item.mood.mask) — \(item.mood.quality.word)"
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
        ArcadeShell(model: model, spec: GameID.comedyTragedy.spec!, accent: Lu.gold, onClose: onClose) {
            VStack(spacing: 10) {
                Color.clear.frame(height: 56)
                CTStage(model: model).frame(height: 220)
                caption.frame(height: 44)
                HStack(spacing: 10) {
                    ReplayButton(enabled: !model.listening && !model.revealed && model.heard) { model.replay() }
                    SoundHint()
                }
                .frame(height: 58)
                ZStack {
                    if let l = model.lesson {
                        Text(l).font(luFont(18, .heavy)).foregroundStyle(Color(hex: Lu.gold))
                            .multilineTextAlignment(.center).minimumScaleFactor(0.6).lineLimit(2)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 46)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: model.lesson)
                Spacer(minLength: 0)
                CTMasks(model: model).padding(.bottom, 10)
            }
            .padding(.horizontal, 14)
        }
        .theatreSound(playing: model.phase == .playing)
        #if DEBUG
        .onAppear { if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { ctSelfCheck() } }
        #endif
    }

    @ViewBuilder private var caption: some View {
        if let s = model.item.spelled {
            HStack(spacing: 14) {
                ForEach(Array(s.enumerated()), id: \.offset) { _, n in
                    Text(n.name).font(luSerif(32, .black)).foregroundStyle(Color(hex: Lu.ink))
                }
            }
        } else if model.item.names {
            Text("Root: \(model.item.root.name)").font(luSerif(28, .black)).foregroundStyle(Color(hex: Lu.ink))
        } else {
            Text(model.listening ? "👂 Listen…" : (model.revealed ? "" : "Happy or sad?"))
                .font(luFont(20, .heavy)).foregroundStyle(Color(hex: Lu.inkDim))
        }
    }
}

/// The stage: an actor waits (🎭), music notes drift while it plays, then the chosen mood's actor
/// performs — bounces for comedy, tears for tragedy, floats for the spooky and dreamy ones.
private struct CTStage: View {
    @ObservedObject var model: ComedyModel
    @State private var perform = false

    var body: some View {
        let m = model.performer
        ZStack {
            TheatreCurtains(light: Color(hex: m?.hex ?? (model.hint ? model.item.mood.hex : Lu.gold)))
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    if model.listening && m == nil {
                        Text("🎵  🎶").font(.system(size: 30)).offset(y: -70)
                            .transition(.opacity)
                    }
                    Text(m?.actor ?? "🎭").font(.system(size: 92))
                        .offset(y: m == .happy && perform ? -22 : (m == .spooky || m == .dreamy) && perform ? -12 : 0)
                        .rotationEffect(.degrees(m == .happy && perform ? 10 : (m == .dreamy && perform ? -8 : 0)))
                        .scaleEffect(m == .sad && perform ? 0.92 : 1)
                    if m == .sad {
                        HStack(spacing: 60) {
                            Text("💧").font(.system(size: 22)).offset(y: perform ? 50 : 0).opacity(perform ? 0 : 1)
                            Text("💧").font(.system(size: 22)).offset(y: perform ? 50 : 0).opacity(perform ? 0 : 1)
                        }
                    }
                    if model.revealed && model.chosen == model.item.mood {
                        Text("👏 👏 👏").font(.system(size: 24)).offset(y: 70)
                    }
                }
                .padding(.bottom, 34)
            }
        }
        .onChange(of: model.performer) { p in
            perform = false
            guard p != nil else { return }
            withAnimation(.easeInOut(duration: 0.32).repeatCount(5, autoreverses: true)) { perform = true }
        }
        .animation(.easeInOut(duration: 0.3), value: model.listening)
    }
}

/// The mask buttons: 2 side by side, then 3, then a 2×2 grid. They bob while the run plays.
private struct CTMasks: View {
    @ObservedObject var model: ComedyModel
    @State private var bob = false

    var body: some View {
        let opts = model.item.options
        let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: opts.count == 3 ? 3 : 2)
        LazyVGrid(columns: cols, spacing: 12) {
            ForEach(Array(opts.enumerated()), id: \.element) { i, m in
                maskButton(m, height: opts.count <= 2 ? 220 : (opts.count == 3 ? 190 : 150))
                    .offset(y: bob ? (i % 2 == 0 ? -5 : 5) : 0)
            }
        }
        .onAppear { setBob(model.phase == .playing) }
        .onChange(of: model.phase) { setBob($0 == .playing) }
    }

    private func setBob(_ on: Bool) {
        if on { withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { bob = true } }
        else { withAnimation(.easeOut(duration: 0.2)) { bob = false } }
    }

    private func maskButton(_ m: CTMood, height: CGFloat) -> some View {
        let it = model.item
        let right = model.revealed && m == it.mood
        let wrong = model.revealed && model.chosen == m && m != it.mood
        let hinted = model.hint && m == it.mood
        let small = it.options.count > 2
        return Button { model.choose(m) } label: {
            VStack(spacing: 4) {
                Text(m.mask).font(.system(size: small ? 58 : 92))
                if it.names {
                    Text(chordName(it.root, m.quality)).font(luSerif(small ? 28 : 34, .black)).foregroundStyle(Color(hex: Lu.ink))
                }
                Text(m.word).font(luFont(small ? 15 : 22, .black)).foregroundStyle(Color(hex: m.hex))
            }
            .frame(maxWidth: .infinity, minHeight: height)
            .background(RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: right ? Lu.mint : (wrong ? Lu.coral : Lu.panel)).opacity(right || wrong ? 0.55 : 1))
                .overlay(RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(hex: right || hinted ? (right ? Lu.mint : m.hex) : Lu.line), lineWidth: right || hinted ? 5 : 2)))
            .scaleEffect(right ? 1.05 : (hinted ? 1.03 : 1))
            .opacity(model.revealed && !right && !wrong ? 0.45 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: model.revealed)
        }
        .buttonStyle(.plain)
        .disabled(model.revealed || !model.heard)
    }
}

#if DEBUG
/// LUDUS_SELFCHECK: each piece's notes really are the answer's chord quality (pitch-class shape
/// above the root), tunes use the scale's 3rd, options are distinct and contain the answer, and
/// chord names/spellings exist and match.
@MainActor private func ctSelfCheck() {
    var fails = theatreTheoryCheck()
    for level in 1...10 {
        var last: CTMood?
        for _ in 0..<1000 {
            let it = ctMake(level, last: last); last = it.mood
            if !it.options.contains(it.mood) || Set(it.options).count != it.options.count { fails.append("options") }
            if it.options.count != min(4, level >= 6 ? 4 : level >= 5 ? 3 : 2) { fails.append("option count L\(level)") }
            let q = it.mood.quality
            let rootPC = it.root.pc
            let pcs = Set(it.events.filter { $0.voice == .piano }.map { (pitchClass($0.midi) - rootPC + 12) % 12 })
            switch it.kind {
            case .block, .arpeggio:
                if pcs != [0, q.third, q.fifth] { fails.append("chord shape \(it.name) \(pcs.sorted())") }
            case .melody:
                if q.rawValue > 1 || !pcs.contains(q.third) || pcs.contains(q == .major ? 3 : 4) { fails.append("tune \(it.name)") }
            }
            for o in it.options where spellTriad(it.root, o.quality) == nil { fails.append("unspellable \(it.root.name)\(o.quality.suffix)") }
            if let notes = spellTriad(it.root, q), !ctOddNotes.isDisjoint(with: notes) { fails.append("odd spelling \(it.name)") }
            if (q == .minor || q == .diminished) && [Spelled("D♭"), Spelled("A♭")].contains(it.root) { fails.append("flat minor \(it.name)") }
            if level >= 8, it.spelled?.first != it.root { fails.append("spelled") }
            if level == 1 && it.root != Spelled("C") { fails.append("L1 root") }
        }
    }
    NSLog("ComedyTragedy self-check: %@", fails.isEmpty ? "PASS" : "FAIL \(Array(Set(fails)).prefix(10))")
}
#endif
