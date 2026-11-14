import AVFoundation
import SwiftUI

// MARK: - TheatreKit — shared music theory + stage chrome for the Theatre (Music) games
//
// Spelled notes (a letter + accidental, so G♭ and F♯ stay distinct names for one key), chord
// spelling by thirds, the sound-off hint, the "hear again" button, the drawn mouse and the staff.

// MARK: Notes

/// A spelled note: letter 0…6 = C D E F G A B, accidental −2…+2 (𝄫 ♭ ♮ ♯ 𝄪).
struct Spelled: Hashable {
    let letter: Int
    let acc: Int
    static let letters = ["C", "D", "E", "F", "G", "A", "B"]
    static let naturalPC = [0, 2, 4, 5, 7, 9, 11]

    init(_ letter: Int, _ acc: Int = 0) { self.letter = letter; self.acc = acc }
    /// Parses "C", "F♯", "B♭" (also "#"/"b").
    init(_ s: String) {
        let l = Spelled.letters.firstIndex(of: String(s.prefix(1))) ?? 0
        let rest = s.dropFirst()
        let a = rest.reduce(0) { $0 + ($1 == "♯" || $1 == "#" ? 1 : ($1 == "♭" || $1 == "b" ? -1 : ($1 == "𝄪" ? 2 : ($1 == "𝄫" ? -2 : 0)))) }
        self.init(l, a)
    }

    var pc: Int { ((Spelled.naturalPC[letter] + acc) % 12 + 12) % 12 }
    var name: String {
        let sym = [-2: "𝄫", -1: "♭", 0: "", 1: "♯", 2: "𝄪"][acc] ?? "?"
        return Spelled.letters[letter] + sym
    }
}

func pitchClass(_ midi: Int) -> Int { ((midi % 12) + 12) % 12 }
func isBlackKey(_ midi: Int) -> Bool { [1, 3, 6, 8, 10].contains(pitchClass(midi)) }

/// The sharp and flat names of a black key's pitch class (e.g. 6 → F♯, G♭).
func blackKeyNames(_ pc: Int) -> (sharp: Spelled, flat: Spelled) {
    let sharpLetter = [1: 0, 3: 1, 6: 3, 8: 4, 10: 5][pc]!
    return (Spelled(sharpLetter, 1), Spelled(sharpLetter + 1, -1))
}

/// The natural name of a white key.
func whiteKeyName(_ midi: Int) -> Spelled { Spelled(Spelled.naturalPC.firstIndex(of: pitchClass(midi))!, 0) }

// MARK: Chords

enum ChordQuality: Int, CaseIterable {
    case major, minor, diminished, augmented
    /// Semitones above the root of the third and the fifth.
    var third: Int { self == .major || self == .augmented ? 4 : 3 }
    var fifth: Int { [7, 7, 6, 8][rawValue] }
    /// Lead-sheet suffix: C, Cm, C°, C+.
    var suffix: String { ["", "m", "°", "+"][rawValue] }
    var word: String { ["major", "minor", "diminished", "augmented"][rawValue] }
}

/// Spells a triad by thirds (root, third = root letter + 2, fifth = root letter + 4). Returns
/// nil when that needs a double sharp/flat — games skip those.
func spellTriad(_ root: Spelled, _ q: ChordQuality) -> [Spelled]? {
    func up(_ steps: Int, _ semis: Int) -> Spelled? {
        let l = (root.letter + steps) % 7
        var a = ((root.pc + semis) - Spelled.naturalPC[l]) % 12
        if a > 6 { a -= 12 }
        if a < -6 { a += 12 }
        return abs(a) <= 1 ? Spelled(l, a) : nil
    }
    guard abs(root.acc) <= 1, let t = up(2, q.third), let f = up(4, q.fifth) else { return nil }
    return [root, t, f]
}

func chordName(_ root: Spelled, _ q: ChordQuality) -> String { root.name + q.suffix }

/// Ordinal for a generic interval number (2 → "2nd", 8 → "octave").
func intervalName(_ n: Int) -> String {
    switch n {
    case 8: return "an octave"
    case 2: return "a 2nd"
    case 3: return "a 3rd"
    default: return "a \(n)th"
    }
}

#if DEBUG
/// Spot-checks the theory helpers against hand-written spellings (LUDUS_SELFCHECK logs the result).
func theatreTheoryCheck() -> [String] {
    var fails: [String] = []
    let expect: [(String, ChordQuality, String)] = [
        ("C", .major, "C E G"), ("D", .major, "D F♯ A"), ("E", .major, "E G♯ B"), ("F", .major, "F A C"),
        ("G", .major, "G B D"), ("A", .major, "A C♯ E"), ("B♭", .major, "B♭ D F"), ("E♭", .major, "E♭ G B♭"),
        ("A♭", .major, "A♭ C E♭"), ("D♭", .major, "D♭ F A♭"), ("F♯", .major, "F♯ A♯ C♯"), ("B", .major, "B D♯ F♯"),
        ("A", .minor, "A C E"), ("D", .minor, "D F A"), ("E", .minor, "E G B"), ("C", .minor, "C E♭ G"),
        ("G", .minor, "G B♭ D"), ("F", .minor, "F A♭ C"), ("B", .minor, "B D F♯"), ("F♯", .minor, "F♯ A C♯"),
        ("C♯", .minor, "C♯ E G♯"), ("E♭", .minor, "E♭ G♭ B♭"),
        ("B", .diminished, "B D F"), ("C", .diminished, "C E♭ G♭"), ("F♯", .diminished, "F♯ A C"),
        ("C♯", .diminished, "C♯ E G"), ("D", .diminished, "D F A♭"),
        ("C", .augmented, "C E G♯"), ("F", .augmented, "F A C♯"), ("E♭", .augmented, "E♭ G B"),
        ("G", .augmented, "G B D♯"),
    ]
    for (r, q, want) in expect {
        let got = spellTriad(Spelled(r), q)?.map(\.name).joined(separator: " ") ?? "nil"
        if got != want { fails.append("\(r)\(q.suffix): got \(got), want \(want)") }
    }
    // Needs a double accidental → skipped.
    for (r, q) in [("B", ChordQuality.augmented), ("E♭", .diminished), ("G♯", .augmented)] where spellTriad(Spelled(r), q) != nil {
        fails.append("\(r)\(q.suffix) should be skipped")
    }
    // Every spelled triad stacks letters in thirds and has the right semitone shape.
    for l in 0..<7 { for a in -1...1 { for q in ChordQuality.allCases {
        let r = Spelled(l, a)
        guard let s = spellTriad(r, q) else { continue }
        if s[1].letter != (l + 2) % 7 || s[2].letter != (l + 4) % 7 { fails.append("\(r.name)\(q.suffix) letters") }
        if (s[1].pc - r.pc + 12) % 12 != q.third || (s[2].pc - r.pc + 12) % 12 != q.fifth { fails.append("\(r.name)\(q.suffix) shape") }
    } } }
    for pc in [1, 3, 6, 8, 10] {
        let (s, f) = blackKeyNames(pc)
        if s.pc != pc || f.pc != pc || s.acc != 1 || f.acc != -1 { fails.append("black key \(pc)") }
    }
    if blackKeyNames(6).sharp.name != "F♯" || blackKeyNames(6).flat.name != "G♭" || blackKeyNames(10).flat.name != "B♭" { fails.append("names") }
    return fails
}
#endif

// MARK: Sound-off hint

/// Watches the output volume so a game can show "turn sound on" when it's at zero. (The silent
/// switch can't be read; with `.ambient` audio it mutes the Theatre too.)
@MainActor
final class SoundCheck: ObservableObject {
    @Published var silent = false
    private var obs: NSKeyValueObservation?
    init() {
        let s = AVAudioSession.sharedInstance()
        silent = s.outputVolume < 0.01
        obs = s.observe(\.outputVolume) { [weak self] s, _ in
            let v = s.outputVolume
            DispatchQueue.main.async { self?.silent = v < 0.01 }
        }
    }
}

struct SoundHint: View {
    @StateObject private var check = SoundCheck()
    var body: some View {
        if check.silent {
            Text("🔇 Turn the sound on!")
                .font(luFont(15, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(Capsule().fill(Color(hex: Lu.gold)))
                .transition(.scale.combined(with: .opacity))
        }
    }
}

/// The big "hear it again" button every listening question carries.
struct ReplayButton: View {
    var enabled = true
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text("🔁").font(.system(size: 26))
                Text("Hear again").font(luFont(18, .heavy))
            }
            .foregroundStyle(Color(hex: Lu.ink))
            .padding(.horizontal, 20).frame(minHeight: 56)
            .background(Capsule().fill(Color(hex: Lu.panel2)).overlay(Capsule().stroke(Color(hex: Lu.goldLine), lineWidth: 2)))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
    }
}

extension View {
    /// Owns the synth for a Theatre game: on while the game is open, silenced between runs.
    func theatreSound(playing: Bool) -> some View {
        self
            .onAppear { ToneSynth.shared.start() }
            .onDisappear { ToneSynth.shared.stop() }
            .onChange(of: playing) { p in if !p { ToneSynth.shared.silence() } }
    }
}

// MARK: The Theatre's mouse

/// A small grey mouse drawn with shapes (side view, facing right) — Piano Mouse's cheese-hunter
/// and Maestro Mouse's conductor. `scared` widens her eyes and lifts her ears; `glee` closes her
/// eyes into happy arcs.
struct StageMouse: View {
    enum Mood { case calm, glee, scared }
    var mood: Mood = .calm
    var facingLeft = false
    var body: some View {
        Canvas { c, s in
            let w = s.width, h = s.height
            func r(_ x: Double, _ y: Double, _ rw: Double, _ rh: Double) -> CGRect {
                CGRect(x: (x - rw / 2) * w, y: (y - rh / 2) * h, width: rw * w, height: rh * h)
            }
            let fur = Color(hex: 0x9b93ad), furDark = Color(hex: 0x6f6784), pink = Color(hex: 0xf3a0b4)
            // Tail
            var tail = Path()
            tail.move(to: CGPoint(x: 0.22 * w, y: 0.74 * h))
            tail.addCurve(to: CGPoint(x: 0.03 * w, y: 0.42 * h), control1: CGPoint(x: 0.0 * w, y: 0.92 * h), control2: CGPoint(x: -0.02 * w, y: 0.55 * h))
            c.stroke(tail, with: .color(pink), style: StrokeStyle(lineWidth: max(2, w * 0.035), lineCap: .round))
            // Feet
            c.fill(Path(ellipseIn: r(0.36, 0.93, 0.16, 0.08)), with: .color(pink))
            c.fill(Path(ellipseIn: r(0.6, 0.93, 0.16, 0.08)), with: .color(pink))
            // Body + belly
            c.fill(Path(ellipseIn: r(0.45, 0.68, 0.56, 0.48)), with: .linearGradient(Gradient(colors: [fur, furDark]),
                startPoint: CGPoint(x: 0.4 * w, y: 0.45 * h), endPoint: CGPoint(x: 0.45 * w, y: 0.92 * h)))
            c.fill(Path(ellipseIn: r(0.56, 0.75, 0.26, 0.28)), with: .color(Color(hex: 0xd9d3e2)))
            // Ear (behind the head)
            let earY = mood == .scared ? 0.13 : 0.2
            c.fill(Path(ellipseIn: r(0.6, earY, 0.27, 0.3)), with: .color(fur))
            c.fill(Path(ellipseIn: r(0.6, earY + 0.01, 0.17, 0.2)), with: .color(pink))
            // Head + snout
            c.fill(Path(ellipseIn: r(0.72, 0.44, 0.36, 0.38)), with: .color(fur))
            var snout = Path()
            snout.move(to: CGPoint(x: 0.7 * w, y: 0.3 * h))
            snout.addQuadCurve(to: CGPoint(x: 0.97 * w, y: 0.5 * h), control: CGPoint(x: 0.9 * w, y: 0.33 * h))
            snout.addQuadCurve(to: CGPoint(x: 0.72 * w, y: 0.62 * h), control: CGPoint(x: 0.88 * w, y: 0.62 * h))
            snout.closeSubpath()
            c.fill(snout, with: .color(fur))
            c.fill(Path(ellipseIn: r(0.96, 0.49, 0.08, 0.09)), with: .color(Color(hex: 0xe0607e)))
            c.fill(Path(ellipseIn: r(0.76, 0.54, 0.1, 0.07)), with: .color(pink.opacity(0.6)))
            // Eye
            let ink = Color(hex: 0x1a1022)
            switch mood {
            case .calm:
                c.fill(Path(ellipseIn: r(0.79, 0.39, 0.075, 0.095)), with: .color(ink))
                c.fill(Path(ellipseIn: r(0.8, 0.37, 0.025, 0.03)), with: .color(.white))
            case .scared:
                c.fill(Path(ellipseIn: r(0.79, 0.38, 0.13, 0.15)), with: .color(.white))
                c.stroke(Path(ellipseIn: r(0.79, 0.38, 0.13, 0.15)), with: .color(furDark), lineWidth: 1)
                c.fill(Path(ellipseIn: r(0.81, 0.38, 0.045, 0.055)), with: .color(ink))
            case .glee:
                var a = Path()
                a.move(to: CGPoint(x: 0.75 * w, y: 0.41 * h))
                a.addQuadCurve(to: CGPoint(x: 0.84 * w, y: 0.41 * h), control: CGPoint(x: 0.795 * w, y: 0.32 * h))
                c.stroke(a, with: .color(ink), style: StrokeStyle(lineWidth: max(1.5, w * 0.03), lineCap: .round))
            }
            // Whiskers
            for dy in [-0.03, 0.03] {
                var p = Path()
                p.move(to: CGPoint(x: 0.88 * w, y: (0.53 + dy) * h))
                p.addLine(to: CGPoint(x: 1.06 * w, y: (0.5 + dy * 2.2) * h))
                c.stroke(p, with: .color(Color(hex: 0x3a3048).opacity(0.7)), lineWidth: 1)
            }
        }
        .scaleEffect(x: facingLeft ? -1 : 1)
    }
}

/// A treble staff with one note on it (positions from middle C = 0, one per letter step), drawn
/// with lines and an ellipse; the clef is drawn too (no music font needed).
struct TrebleStaff: View {
    /// Letter steps above middle C (0 = C4 … 9 = E5).
    let step: Int
    var accidental: Int = 0
    var ink: Color = Color(hex: 0x2a1a10)
    var noteColor: Color = Color(hex: 0x2a1a10)
    var body: some View {
        Canvas { c, s in
            let gap = s.height / 6.6
            let bottom = s.height * 0.5 + gap * 2          // E4 line
            for i in 0..<5 {
                var p = Path(); let y = bottom - CGFloat(i) * gap
                p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: s.width, y: y))
                c.stroke(p, with: .color(ink), lineWidth: 1.6)
            }
            // Clef: the G-clef glyph sized to the staff.
            let clef = Text("𝄞").font(.system(size: gap * 6.4)).foregroundColor(ink)
            c.draw(clef, at: CGPoint(x: gap * 1.6, y: bottom - gap * 1.55), anchor: .center)
            // The note
            let pos = step - 2                                // E4 = 0 on the bottom line
            let y = bottom - CGFloat(pos) * gap / 2
            let x = s.width * 0.62
            if pos <= -2 {                                    // ledger lines below (C4)
                var l = -2
                while l >= pos { var p = Path(); let ly = bottom - CGFloat(l) * gap / 2
                    p.move(to: CGPoint(x: x - gap * 1.1, y: ly)); p.addLine(to: CGPoint(x: x + gap * 1.1, y: ly))
                    c.stroke(p, with: .color(ink), lineWidth: 1.6); l -= 2 }
            }
            if pos >= 10 {
                var l = 10
                while l <= pos { var p = Path(); let ly = bottom - CGFloat(l) * gap / 2
                    p.move(to: CGPoint(x: x - gap * 1.1, y: ly)); p.addLine(to: CGPoint(x: x + gap * 1.1, y: ly))
                    c.stroke(p, with: .color(ink), lineWidth: 1.6); l += 2 }
            }
            var head = Path(ellipseIn: CGRect(x: -gap * 0.68, y: -gap * 0.48, width: gap * 1.36, height: gap * 0.96))
            head = head.applying(CGAffineTransform(rotationAngle: -0.35)).applying(CGAffineTransform(translationX: x, y: y))
            c.fill(head, with: .color(noteColor))
            // Stem: up for notes below the middle line, down from it.
            var stem = Path()
            if pos < 4 { stem.move(to: CGPoint(x: x + gap * 0.62, y: y - gap * 0.1)); stem.addLine(to: CGPoint(x: x + gap * 0.62, y: y - gap * 3.4)) }
            else { stem.move(to: CGPoint(x: x - gap * 0.62, y: y + gap * 0.1)); stem.addLine(to: CGPoint(x: x - gap * 0.62, y: y + gap * 3.4)) }
            c.stroke(stem, with: .color(noteColor), lineWidth: 1.8)
            if accidental != 0 {
                let a = Text(accidental > 0 ? "♯" : "♭").font(.system(size: gap * 2.2, weight: .bold)).foregroundColor(noteColor)
                c.draw(a, at: CGPoint(x: x - gap * 1.9, y: y - (accidental < 0 ? gap * 0.5 : 0)), anchor: .center)
            }
        }
    }
}
