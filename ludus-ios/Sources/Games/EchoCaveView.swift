import SwiftUI

// MARK: - Echo's Cave (Theatre · Music) — high/low, melody memory
//
// Deep in a cave lives Echo, a little glowing spirit who can only repeat what she hears — and who
// loves to be echoed back. Singing crystals grow from the cave pool, BIG ones low and small ones
// high. Echo sings a tune (she floats to each crystal and it lights and rings); then you play it
// back by tapping the crystals in order. A right tune: she twirls and the cave sparkles. A wrong
// crystal: she flies to the right one, it lights and sings, and she sings the whole tune again
// with the crystals lit, so the miss is heard as well as seen.
//
// Continuous ladder (all off `d`):
//   crystals   2 (C4 and C5: plainly LOW and HIGH) → 3 → … → 8 (a C-major octave) by ~6.5;
//              early sets are spread wide, later ones step by step (harder to tell apart)
//   tune       1 note (which one did she sing? = high or low) → 6–7 notes by ~9.5
//   tempo      0.7 s → 0.32 s between notes
//   melody     random jumps early; mostly steps and repeats later (real tunes move by step)
//   colour     each crystal has its own colour and lights as she sings — from ~6 the lights
//              start going out (ear alone, ~85% of tunes by 9.5) and the crystals turn to ice
//   names      letter names under the crystals from ~4 (C D E …), tying the sound to the name

private let ecHues: [UInt] = [0xff5a5a, 0xff9a3a, 0xffd23a, 0x6ad86a, 0x3ad0c8, 0x4a9aff, 0x9a6aff, 0xff6ad0]

/// The crystal pitches for a set of `n` (MIDI), low → high: wide spreads early, a full scale later.
private func ecPitches(_ n: Int) -> [Int] {
    switch n {
    case 2: return [60, 72]
    case 3: return [60, 67, 72]
    case 4: return [60, 64, 67, 72]
    case 5: return [60, 62, 64, 67, 69]
    case 6: return [60, 62, 64, 67, 69, 72]
    case 7: return [60, 62, 64, 65, 67, 69, 71]
    default: return [60, 62, 64, 65, 67, 69, 71, 72]
    }
}

private enum ECStage: Equatable { case idle, singing, yours, done }

@MainActor
private final class EchoModel: ArcadeModel {
    @Published var pitches: [Int] = [60, 72]
    @Published var tune: [Int] = []          // crystal indices
    @Published var stage = ECStage.idle
    @Published var lit: Int?                 // the crystal ringing now
    @Published var echoAt: Int?              // which crystal Echo hovers over (nil = centre)
    @Published var played = 0                // how many notes of the tune you've got right
    @Published var wrong: Int?
    @Published var dark = false              // ear only: crystals don't light while she sings
    @Published var showNames = false
    @Published var twirl = 0
    @Published var sad = false
    @Published var lesson: String?
    private var gap = 0.7
    private var token = 0

    init() { super.init(key: GameID.echoCave.rawValue) }
    override func onBegin() { next(after: 0.7) }

    func makeTune(n: Int) -> [Int] {
        let len = max(1, min(8, rampInt(1, 6, from: 1, to: 9.5) + (chance(0.5, from: 2, to: 4) && Bool.random() ? 1 : 0)))
        let stepwise = ramp(0, 0.8, from: 3, to: 7)
        var t = [Int.random(in: 0..<n)]
        while t.count < len {
            let last = t.last!
            var nx: Int
            if Double.random(in: 0..<1) < stepwise {
                nx = last + [-2, -1, -1, 0, 1, 1, 2].randomElement()!
            } else {
                nx = Int.random(in: 0..<n)
            }
            nx = max(0, min(n - 1, nx))
            if n == 2 && t.count == len - 1 && Set(t + [nx]).count == 1 && len > 1 { nx = 1 - nx }   // not all one note
            t.append(nx)
        }
        return t
    }

    func next(after delay: Double) {
        token += 1
        let tok = token
        stage = .idle
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.phase == .playing, self.token == tok else { return }
            let n = self.rampInt(2, 8, from: 1, to: 6.5)
            self.pitches = ecPitches(n)
            self.tune = self.makeTune(n: n)
            self.gap = self.ramp(0.7, 0.32, to: 9)
            self.dark = Double.random(in: 0..<1) < self.ramp(0, 0.85, from: 6, to: 9.5)
            self.showNames = self.d >= 4
            self.played = 0; self.wrong = nil; self.sad = false; self.lesson = nil
            self.sing(lights: !self.dark) { [weak self] in self?.stage = .yours; self?.echoAt = nil }
        }
    }

    /// Echo sings the tune; crystals light (unless `lights` is off) and she floats along.
    func sing(lights: Bool, then: @escaping () -> Void) {
        stage = .singing
        let tok = token
        let ev = tune.enumerated().map { ToneEvent(at: Double($0.offset) * gap, midi: pitches[$0.element], vel: 0.7, dur: gap * 1.6, voice: .chime) }
        ToneSynth.shared.play(ev)
        for (i, c) in tune.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * gap) { [weak self] in
                guard let self, self.phase == .playing, self.token == tok else { return }
                if lights { self.lit = c; self.echoAt = c } else { self.lit = nil; self.echoAt = nil }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(tune.count) * gap + 0.15) { [weak self] in
            guard let self, self.phase == .playing, self.token == tok else { return }
            self.lit = nil
            then()
        }
    }

    func tap(_ i: Int) {
        guard phase == .playing, stage == .yours, i < pitches.count else { return }
        ToneSynth.shared.play([ToneEvent(midi: pitches[i], vel: 0.75, dur: 0.9, voice: .chime)])
        flash(i)
        if tune[played] == i {
            played += 1
            if played == tune.count {
                stage = .done
                twirl += 1
                Sfx.play(.sparkle, volume: 0.6)
                hit()
                next(after: 1.3)
            }
        } else {
            stage = .done
            wrong = i
            sad = true
            let want = tune[played]
            lesson = ecLesson(tapped: i, want: want)
            let lastHeart = miss(delay: 3.0)
            let tok = token
            // Show the right crystal, then sing the whole tune again with the lights on.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self, self.phase == .playing, self.token == tok else { return }
                self.echoAt = want; self.lit = want
                ToneSynth.shared.play([ToneEvent(midi: self.pitches[want], vel: 0.75, dur: 0.9, voice: .chime)])
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self, self.phase == .playing, self.token == tok else { return }
                self.lit = nil
                self.sing(lights: true) { [weak self] in
                    guard let self, !lastHeart else { return }
                    self.stage = .done
                    self.next(after: 0.8)
                }
            }
        }
    }

    private func ecLesson(tapped: Int, want: Int) -> String {
        let higher = pitches[want] > pitches[tapped]
        if tune.count == 1 || pitches.count == 2 { return higher ? "She sang HIGH — the small crystal" : "She sang LOW — the big crystal" }
        return "Note \(played + 1) was \(higher ? "higher ⬆️" : "lower ⬇️")" + (showNames ? " — \(whiteKeyName(pitches[want]).name)" : "")
    }

    @Published var flashKey = 0
    @Published var flashIdx: Int?
    private func flash(_ i: Int) {
        flashIdx = i; flashKey += 1
        let k = flashKey
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in if self?.flashKey == k { self?.flashIdx = nil } }
    }

    override func botAct(correct: Bool) {
        guard phase == .playing, stage == .yours, played < tune.count else { return }
        let want = tune[played]
        let wrongs = pitches.indices.filter { $0 != want }
        tap(correct || wrongs.isEmpty ? want : wrongs.randomElement()!)
    }
}

// MARK: View

struct EchoCaveView: View {
    let onClose: () -> Void
    @StateObject private var model = EchoModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.echoCave.spec!, accent: Lu.sky, onClose: onClose,
                    backdrop: { ECCave() }) {
            GeometryReader { g in
                VStack(spacing: 0) {
                    HUDSpace(64)
                    ECStatus(model: model).frame(height: 44)
                    ZStack(alignment: .bottom) {
                        ECCrystals(model: model)
                        ECSpirit(model: model, width: g.size.width)
                    }
                    .frame(maxHeight: .infinity)
                    ZStack {
                        if let l = model.lesson {
                            Text(l).font(luFont(17, .heavy)).foregroundStyle(Color(hex: 0xd8f0ff))
                                .multilineTextAlignment(.center).minimumScaleFactor(0.6).lineLimit(2)
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .background(Capsule().fill(Color.black.opacity(0.45)))
                        } else { SoundHint() }
                    }
                    .frame(height: 50).padding(.bottom, 10)
                }
            }
            .padding(.horizontal, 8)
        }
        .theatreSound(playing: model.phase == .playing)
    }
}

/// "Listen…" / your progress through the tune as dots.
private struct ECStatus: View {
    @ObservedObject var model: EchoModel
    var body: some View {
        HStack(spacing: 10) {
            Text(model.stage == .singing ? "👂 Listen…" : (model.stage == .yours ? "Your turn!" : " "))
                .font(luFont(20, .black)).foregroundStyle(Color(hex: Lu.ink))
            HStack(spacing: 5) {
                ForEach(0..<model.tune.count, id: \.self) { i in
                    Circle().fill(Color(hex: i < model.played ? Lu.mint : 0x3a4a7a))
                        .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
                        .frame(width: 13, height: 13)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 6)
        .background(Capsule().fill(Color.black.opacity(0.3)))
    }
}

/// The cave: a blue-violet hollow, stalactites hanging from the roof, and a dark still pool.
private struct ECCave: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                RadialGradient(colors: [Color(hex: 0x2a3a7a), Color(hex: 0x141a40), Color(hex: 0x080a1c)], center: .init(x: 0.5, y: 0.45), startRadius: 20, endRadius: h * 0.7)
                Canvas { c, s in
                    // Stalactites
                    let tips: [(Double, Double, Double)] = [(0.04, 0.1, 0.16), (0.14, 0.06, 0.24), (0.27, 0.08, 0.13), (0.38, 0.05, 0.19), (0.52, 0.07, 0.1),
                                                          (0.63, 0.06, 0.21), (0.75, 0.09, 0.14), (0.86, 0.05, 0.26), (0.96, 0.08, 0.12)]
                    for (x, hw, len) in tips {
                        var p = Path()
                        p.move(to: CGPoint(x: (x - hw) * s.width, y: 0))
                        p.addQuadCurve(to: CGPoint(x: x * s.width, y: len * s.height), control: CGPoint(x: (x - hw * 0.3) * s.width, y: len * 0.6 * s.height))
                        p.addQuadCurve(to: CGPoint(x: (x + hw) * s.width, y: 0), control: CGPoint(x: (x + hw * 0.3) * s.width, y: len * 0.6 * s.height))
                        p.closeSubpath()
                        c.fill(p, with: .linearGradient(Gradient(colors: [Color(hex: 0x1a1a3a), Color(hex: 0x3a4a8a)]),
                                                        startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: len * s.height)))
                        c.fill(Path(ellipseIn: CGRect(x: x * s.width - 2, y: len * s.height + 6, width: 4, height: 6)), with: .color(Color(hex: 0x8ad0ff).opacity(0.6)))
                    }
                    // Back wall rocks
                    var rock = Path()
                    rock.move(to: CGPoint(x: 0, y: s.height * 0.62))
                    rock.addCurve(to: CGPoint(x: s.width, y: s.height * 0.6), control1: CGPoint(x: s.width * 0.3, y: s.height * 0.52), control2: CGPoint(x: s.width * 0.7, y: s.height * 0.68))
                    rock.addLine(to: CGPoint(x: s.width, y: s.height)); rock.addLine(to: CGPoint(x: 0, y: s.height)); rock.closeSubpath()
                    c.fill(rock, with: .color(Color(hex: 0x10142e)))
                }
                // The pool
                Ellipse().fill(LinearGradient(colors: [Color(hex: 0x1a3a6a), Color(hex: 0x0a1630)], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 1.3, height: h * 0.2).position(x: w / 2, y: h * 0.86)
                Ellipse().stroke(Color(hex: 0x6ab0ff).opacity(0.25), lineWidth: 2)
                    .frame(width: w * 1.1, height: h * 0.14).position(x: w / 2, y: h * 0.86)
            }
        }
    }
}

/// The crystals: one tall-to-small row, each a faceted gem standing in the pool. They glow in their
/// own colour when they ring (or icy white in the ear-only tunes).
private struct ECCrystals: View {
    @ObservedObject var model: EchoModel

    var body: some View {
        GeometryReader { g in
            let n = model.pitches.count
            let cw = g.size.width / CGFloat(n)
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(0..<n, id: \.self) { i in
                    let frac = n == 1 ? 0 : CGFloat(i) / CGFloat(n - 1)
                    let ch = g.size.height * (0.62 - 0.3 * frac)      // big = low
                    let on = model.lit == i || model.flashIdx == i
                    let isWrong = model.wrong == i
                    let hue: UInt = model.dark ? 0xbfe6ff : ecHues[(i * 8 / max(1, n)) % 8]
                    VStack(spacing: 4) {
                        ECGem()
                            .fill(LinearGradient(colors: [Color(hex: hue).opacity(on ? 1 : 0.55), Color(hex: hue).opacity(on ? 0.8 : 0.25)],
                                                 startPoint: .top, endPoint: .bottom))
                            .overlay(ECGem().stroke(Color.white.opacity(on ? 0.95 : 0.45), lineWidth: on ? 3 : 1.5))
                            .overlay(ECFacets().stroke(Color.white.opacity(0.3), lineWidth: 1))
                            .overlay(isWrong ? Text("✗").font(luFont(28, .black)).foregroundStyle(Color(hex: Lu.coral)) : nil)
                            .frame(width: min(cw * 0.78, 70), height: ch)
                            .shadow(color: Color(hex: hue).opacity(on ? 1 : 0), radius: on ? 22 : 0)
                            .scaleEffect(on ? 1.07 : 1, anchor: .bottom)
                            .animation(.spring(response: 0.18, dampingFraction: 0.5), value: on)
                        Text(model.showNames ? whiteKeyName(model.pitches[i]).name : " ")
                            .font(luSerif(20, .black)).foregroundStyle(Color(hex: 0xd8ecff))
                    }
                    .frame(width: cw)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .contentShape(Rectangle())
                    .onTapGesture { model.tap(i) }
                }
            }
        }
        .padding(.bottom, 6)
    }
}

private struct ECGem: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.width * 0.55))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.08, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.08, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.width * 0.55))
        p.closeSubpath()
        return p
    }
}

private struct ECFacets: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.midX - r.width * 0.12, y: r.maxY))
        p.move(to: CGPoint(x: r.minX, y: r.minY + r.width * 0.55)); p.addLine(to: CGPoint(x: r.midX - r.width * 0.12, y: r.minY + r.width * 0.9))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.width * 0.55))
        return p
    }
}

/// Echo: a round glowing spirit with big eyes, a wispy tail, and a mouth that opens into an "o"
/// as she sings. She floats over the crystal she's singing, twirls when echoed right, droops on
/// a miss.
private struct ECSpirit: View {
    @ObservedObject var model: EchoModel
    let width: CGFloat
    @State private var spin = 0.0

    var body: some View {
        GeometryReader { g in
            let n = model.pitches.count
            let cw = g.size.width / CGFloat(max(1, n))
            let x = model.echoAt.map { (CGFloat($0) + 0.5) * cw } ?? g.size.width / 2
            let singing = model.stage == .singing && model.lit != nil
            TimelineView(.animation(minimumInterval: 1 / 30, paused: model.phase != .playing)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                Canvas { c, s in
                    let w = s.width, h = s.height
                    let glow = Color(hex: model.lit.map { model.dark ? 0xbfe6ff : ecHues[($0 * 8 / max(1, n)) % 8] } ?? 0xbfe6ff)
                    // Halo
                    c.fill(Path(ellipseIn: CGRect(x: 0, y: 0, width: w, height: h * 0.85)),
                           with: .radialGradient(Gradient(colors: [glow.opacity(0.55), .clear]), center: CGPoint(x: w / 2, y: h * 0.42), startRadius: 4, endRadius: w * 0.5))
                    // Wispy tail
                    var tail = Path()
                    tail.move(to: CGPoint(x: w * 0.32, y: h * 0.55))
                    tail.addQuadCurve(to: CGPoint(x: w * 0.5 + sin(t * 3) * 10, y: h * 0.98), control: CGPoint(x: w * 0.3, y: h * 0.85))
                    tail.addQuadCurve(to: CGPoint(x: w * 0.68, y: h * 0.55), control: CGPoint(x: w * 0.7, y: h * 0.8))
                    c.fill(tail, with: .color(Color(hex: 0xe8f6ff).opacity(0.85)))
                    // Body
                    c.fill(Path(ellipseIn: CGRect(x: w * 0.22, y: h * 0.14, width: w * 0.56, height: h * 0.52)),
                           with: .radialGradient(Gradient(colors: [.white, Color(hex: 0xcfeaff)]), center: CGPoint(x: w * 0.42, y: h * 0.3), startRadius: 2, endRadius: w * 0.4))
                    // Eyes
                    let eyeY = h * 0.34
                    if model.sad {
                        for ex in [0.4, 0.6] {
                            var a = Path(); a.move(to: CGPoint(x: (ex - 0.05) * w, y: eyeY - 2)); a.addLine(to: CGPoint(x: (ex + 0.05) * w, y: eyeY + 3))
                            c.stroke(a, with: .color(Color(hex: 0x1a2048)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        }
                    } else {
                        for ex in [0.4, 0.6] {
                            c.fill(Path(ellipseIn: CGRect(x: ex * w - 6, y: eyeY - 8, width: 12, height: 16)), with: .color(Color(hex: 0x1a2048)))
                            c.fill(Path(ellipseIn: CGRect(x: ex * w - 3, y: eyeY - 6, width: 5, height: 5)), with: .color(.white))
                        }
                    }
                    // Cheeks
                    c.fill(Path(ellipseIn: CGRect(x: w * 0.3, y: h * 0.42, width: 10, height: 6)), with: .color(Color(hex: 0xffa0c0).opacity(0.7)))
                    c.fill(Path(ellipseIn: CGRect(x: w * 0.7 - 10, y: h * 0.42, width: 10, height: 6)), with: .color(Color(hex: 0xffa0c0).opacity(0.7)))
                    // Mouth: "o" while singing, smile otherwise, wobble when sad
                    if singing {
                        c.fill(Path(ellipseIn: CGRect(x: w * 0.5 - 6, y: h * 0.45, width: 12, height: 13)), with: .color(Color(hex: 0x6a2a4a)))
                    } else {
                        var m = Path()
                        m.move(to: CGPoint(x: w * 0.45, y: h * (model.sad ? 0.5 : 0.47)))
                        m.addQuadCurve(to: CGPoint(x: w * 0.55, y: h * (model.sad ? 0.5 : 0.47)), control: CGPoint(x: w * 0.5, y: h * (model.sad ? 0.45 : 0.52)))
                        c.stroke(m, with: .color(Color(hex: 0x6a2a4a)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    }
                    if singing {
                        let note = Text("♪").font(.system(size: 22, weight: .bold)).foregroundColor(glow)
                        c.draw(note, at: CGPoint(x: w * 0.85, y: h * 0.12 - CGFloat(sin(t * 6)) * 4))
                    }
                }
                .frame(width: 110, height: 120)
                .rotationEffect(.degrees(spin))
                .offset(y: model.sad ? 14 : CGFloat(sin(t * 2)) * 6)
            }
            .position(x: min(max(x, 55), g.size.width - 55), y: g.size.height * 0.2)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: model.echoAt)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: model.sad)
        }
        .allowsHitTesting(false)
        .onChange(of: model.twirl) { _ in
            withAnimation(.easeInOut(duration: 0.7)) { spin += 360 }
        }
    }
}
