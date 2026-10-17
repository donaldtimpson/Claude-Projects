import AVFoundation
import SwiftUI

// MARK: - TheatreKit — shared music theory + stage chrome for the Theatre (Music) games
//
// Spelled notes (a letter + accidental, so G♭ and F♯ stay distinct names for one key), chord
// spelling by thirds, the sound-off hint, the "hear again" button and the theatre curtains.

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

// MARK: Stage

/// Red velvet curtains with a gold valance — the Theatre's set, drawn with shapes.
struct TheatreCurtains: View {
    var light: Color = .clear
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 18).fill(LinearGradient(colors: [Color(hex: 0x2a1530), Color(hex: 0x14091e)], startPoint: .top, endPoint: .bottom))
                Ellipse().fill(RadialGradient(colors: [light.opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: w * 0.45))
                    .frame(width: w * 0.9, height: h * 0.8).offset(y: h * 0.15)
                // Stage floor
                VStack { Spacer(); Rectangle().fill(LinearGradient(colors: [Color(hex: 0x7a4a2a), Color(hex: 0x4a2a16)], startPoint: .top, endPoint: .bottom)).frame(height: h * 0.16) }
                // Drapes
                HStack(spacing: 0) {
                    drape(flip: false).frame(width: w * 0.17)
                    Spacer()
                    drape(flip: true).frame(width: w * 0.17)
                }
                // Valance
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { _ in
                        Ellipse().fill(LinearGradient(colors: [Color(hex: 0xc0303a), Color(hex: 0x7a1220)], startPoint: .top, endPoint: .bottom))
                            .frame(height: 34).offset(y: -12)
                    }
                }
                .overlay(alignment: .top) { Rectangle().fill(Color(hex: Lu.gold)).frame(height: 4).offset(y: 18) }
                .clipped()
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: Lu.goldLine), lineWidth: 2))
        }
    }

    private func drape(flip: Bool) -> some View {
        LinearGradient(colors: [Color(hex: 0xa01c2c), Color(hex: 0xd8404c), Color(hex: 0x8a1424), Color(hex: 0xc8323e), Color(hex: 0x6a0c1a)],
                       startPoint: flip ? .trailing : .leading, endPoint: flip ? .leading : .trailing)
            .clipShape(DrapeShape(flip: flip))
    }
}

private struct DrapeShape: Shape {
    let flip: Bool
    func path(in r: CGRect) -> Path {
        var p = Path()
        if !flip {
            p.move(to: CGPoint(x: r.minX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
            p.addQuadCurve(to: CGPoint(x: r.minX + r.width * 0.35, y: r.maxY), control: CGPoint(x: r.maxX * 0.55, y: r.height * 0.55))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        } else {
            p.move(to: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.minX, y: r.minY))
            p.addQuadCurve(to: CGPoint(x: r.maxX - r.width * 0.35, y: r.maxY), control: CGPoint(x: r.width * 0.45, y: r.height * 0.55))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        }
        p.closeSubpath()
        return p
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
