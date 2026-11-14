import SwiftUI

// MARK: - Caesar's Wheel (Forum · History)
//
// A secret message from Caesar arrives in code, in his command tent by lamplight. Turn the
// cipher wheel (drag it round, or tap the ↺ ↻ buttons) so the real letters line up under the code
// letters, then pick what the message says. The outer ring holds the CODE letters, the inner disc
// the REAL letters; the key is where the inner A sits (A→D = shift 3). Tapping a letter tile
// lights it and its partner on the wheel.
//
// Difficulty runs on `d` (GameKit), no level tables:
//   • choices 2 → 4 (rampInt); words 3 letters → 4–5 letters as d climbs;
//   • puzzle kinds — tier([1, 3.5, 4.8, 5.8, 7, 8.5]), each new kind fading in while the old ones
//     stay as review: told key with live read-out (shift 1 = Augustus, then 3 = Caesar) → find
//     the key yourself (the wheel glows when it's right) → Roman orders, no glow → ENCODE a word
//     with a told key → no live read-out (tap each tile to read it) → phrases, either way;
//   • "Tap ↻ once!" hand-holding only at the very start.
// Facts used: Suetonius says Julius Caesar wrote D for A (shift 3) and Augustus B for A (shift 1).

// MARK: Cipher

private let cwAlphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

private func cwIndex(_ c: Character) -> Int? { cwAlphabet.firstIndex(of: c) }
private func cwLetter(_ i: Int) -> Character { cwAlphabet[((i % 26) + 26) % 26] }

/// Shift every letter by `k` (spaces etc. stay put).
private func caesar(_ s: String, _ k: Int) -> String {
    String(s.map { c in cwIndex(c).map { cwLetter($0 + k) } ?? c })
}

/// True when `b` is some Caesar shift of `a` (same shape, one constant letter offset).
private func isShift(_ a: String, _ b: String) -> Bool {
    guard a.count == b.count else { return false }
    var k: Int?
    for (x, y) in zip(a, b) {
        switch (cwIndex(x), cwIndex(y)) {
        case let (i?, j?):
            let d = ((j - i) % 26 + 26) % 26
            if let k, k != d { return false }
            k = d
        case (nil, nil): if x != y { return false }
        default: return false
        }
    }
    return true
}

// MARK: Content

private struct CWWord { let word: String; let emoji: String? }

private func cwWords(_ s: String) -> [CWWord] {
    s.split(separator: " ").map { p in
        let parts = p.split(separator: ":")
        return CWWord(word: String(parts[0]), emoji: parts.count > 1 ? String(parts[1]) : nil)
    }
}

private let cwPic3 = cwWords("CAT:🐱 DOG:🐶 PIG:🐷 COW:🐮 BUS:🚌 SUN:☀️ HAT:🎩 BED:🛏️ FOX:🦊 BEE:🐝 EGG:🥚 CAR:🚗 OWL:🦉 ANT:🐜 BAT:🦇 HEN:🐔 CUP:☕️ KEY:🔑 BOX:📦 BUG:🐛 PIE:🥧 RAM:🐏 MAP:🗺️")
private let cwPic4 = cwWords("FISH:🐟 BEAR:🐻 FROG:🐸 DUCK:🦆 LION:🦁 MOON:🌙 STAR:⭐️ CAKE:🎂 SHIP:🚢 BOOK:📖 TREE:🌳 BOAT:⛵️ MILK:🥛 GOAT:🐐 DEER:🦌 WOLF:🐺 KITE:🪁 BELL:🔔 DRUM:🥁 CRAB:🦀 RAIN:🌧️ LEAF:🍃 CORN:🌽 SOCK:🧦 SEAL:🦭")
private let cwPic5 = cwWords("HORSE:🐎 TIGER:🐯 SNAKE:🐍 APPLE:🍎 CROWN:👑 SWORD:🗡️ WHALE:🐋 SHEEP:🐑 MOUSE:🐭 ZEBRA:🦓 CAMEL:🐫 HOUSE:🏠 TRAIN:🚂 GRAPE:🍇 LEMON:🍋 PIZZA:🍕 ROBOT:🤖 EAGLE:🦅 SHARK:🦈 PANDA:🐼 KOALA:🐨 TRUCK:🚚 BREAD:🍞 CHAIR:🪑 HEART:❤️ CLOUD:☁️")
private let cwRoman = cwWords("ROME ARMY GOLD WALL ROAD CAMP GATE FORT HILL SPEAR TENT SHIELD LEGION ARROW RIVER TOWER BRIDGE CHARIOT SENATE TEMPLE FORUM")
private let cwPhrases = [
    "MEET AT DAWN", "HOLD THE BRIDGE", "SEND MORE GRAIN", "MARCH TO ROME", "CROSS THE RIVER",
    "GUARD THE GATE", "BRING THE HORSES", "WAIT FOR ME", "HIDE THE GOLD", "LIGHT THE FIRES",
    "ROME IS SAFE", "ATTACK AT NOON", "BUILD A ROAD", "FEED THE HORSES", "SAIL AT NIGHT",
    "STAY ON THE HILL", "THE EAGLE FLIES", "OPEN THE GATES", "COUNT THE SHIPS", "REST AT CAMP",
    "RAIN IS COMING", "BRING MORE BREAD", "WE WON THE RACE", "LOCK THE DOOR",
    "FIND THE SHIP", "MEET AT NOON", "HOLD THE HILL", "GUARD THE ROAD", "WATCH THE RIVER",
    "CLOSE THE GATES", "BRING THE SHIPS", "FEED THE TROOPS", "WAIT AT CAMP", "SAIL AT DAWN",
]

/// How different two messages look before decoding (word count and word lengths).
private func cwShapeGap(_ a: String, _ b: String) -> Int {
    let x = a.split(separator: " ").map(\.count), y = b.split(separator: " ").map(\.count)
    return abs(x.count - y.count) * 6 + zip(x, y).map { abs($0 - $1) }.reduce(0, +) + abs(a.count - b.count)
}

private enum CWMode { case decode, encode }

private struct CWChoice: Hashable { let text: String; let emoji: String? }

private struct CWPuzzle {
    let mode: CWMode
    let plain: String
    let shift: Int
    let told: Bool          // the key is given
    let live: Bool          // the read-out row follows the wheel
    let glow: Bool          // the wheel glows when the key is right
    let turnHint: Bool      // show "turn ↻ n"
    let choices: [CWChoice]
    let correct: Int

    var coded: String { caesar(plain, shift) }
    /// The letters on the tiles: the code to read, or (encoding) the word to write.
    var shown: String { mode == .decode ? coded : plain }
    var answer: String { mode == .decode ? plain : coded }
    var pictured: Bool { choices.contains { $0.emoji != nil } }
}

// MARK: Generator

private enum CWGen {
    /// A puzzle of kind `k` (see the header) with `n` choices; `d` tunes word length and shift.
    static func puzzle(kind k: Int, d: Double, n: Int, avoid: String?) -> CWPuzzle {
        let words: [CWWord] = d < 1.8 ? cwPic3 : d < 3 ? cwPic3 + cwPic4 : cwPic4 + cwPic5
        switch k {
        case 0:
            // Augustus's shift of 1 first, then 2, then mostly Caesar's own 3.
            let shift = d < 1.7 ? 1 : d < 2.6 ? Int.random(in: 1...2) : [3, 3, 3, 1, 2].randomElement()!
            return decode(pool: words, shift: shift, told: true, live: true, glow: true, n: n, pics: true, hint: d < 3.5, avoid: avoid)
        case 1:
            return decode(pool: cwPic4 + cwPic5, shift: Int.random(in: 1...25), told: false, live: true, glow: true, n: n, pics: true, hint: false, avoid: avoid)
        case 2:
            return decode(pool: phrasePool, shift: Int.random(in: 1...25), told: false, live: true, glow: false, n: max(3, n), pics: false, hint: false, avoid: avoid)
        case 3:
            return encode(pool: cwPic4 + cwPic5, shift: Int.random(in: 4...12), n: max(3, n), avoid: avoid)
        case 4:
            return decode(pool: cwPic4 + cwPic5 + cwRoman, shift: Int.random(in: 4...22), told: true, live: false, glow: false, n: n, pics: false, hint: false, avoid: avoid)
        default:
            return Bool.random()
                ? decode(pool: phrasePool, shift: Int.random(in: 2...24), told: true, live: false, glow: false, n: n, pics: false, hint: false, avoid: avoid)
                : encode(pool: phrasePool, shift: Int.random(in: 2...24), n: n, avoid: avoid)
        }
    }

    static let phrasePool = cwPhrases.map { CWWord(word: $0, emoji: nil) }

    /// Decode: the answer plus real-word distractors, closest in shape first (so word lengths
    /// alone rarely give it away), never a Caesar shift of the answer (that would be a 2nd answer).
    static func decode(pool: [CWWord], shift: Int, told: Bool, live: Bool, glow: Bool, n: Int,
                       pics: Bool, hint: Bool, avoid: String?) -> CWPuzzle {
        let ans = pool.filter { $0.word != avoid }.randomElement()!
        let others = pool.filter { $0.word != ans.word && !isShift(ans.word, $0.word) }
            .shuffled()
            .sorted { cwShapeGap($0.word, ans.word) < cwShapeGap($1.word, ans.word) }
        let picks = [ans] + others.prefix(n - 1)
        let choices = picks.map { CWChoice(text: $0.word, emoji: pics ? $0.emoji : nil) }.shuffled()
        return CWPuzzle(mode: .decode, plain: ans.word, shift: shift, told: told, live: live, glow: glow,
                        turnHint: hint && told && shift <= 3, choices: choices,
                        correct: choices.firstIndex { $0.text == ans.word }!)
    }

    /// Encode: the right code plus the usual slips — one click off either way, or turned backwards.
    static func encode(pool: [CWWord], shift: Int, n: Int, avoid: String?) -> CWPuzzle {
        let ans = pool.filter { $0.word != avoid }.randomElement()!
        let right = caesar(ans.word, shift)
        var opts = [right]
        for k in [shift + 1, shift - 1, -shift, shift + 2, shift - 2] where opts.count < n {
            let s = caesar(ans.word, k)
            if !opts.contains(s) && s != ans.word { opts.append(s) }
        }
        let choices = opts.shuffled().map { CWChoice(text: $0, emoji: nil) }
        return CWPuzzle(mode: .encode, plain: ans.word, shift: shift, told: true, live: false, glow: false,
                        turnHint: false, choices: choices, correct: choices.firstIndex { $0.text == right }!)
    }

    #if DEBUG
    /// Every puzzle has exactly one right choice; a decode's distractors can't be read from the
    /// code under ANY key; an encode's right choice is the only one made with the given key.
    static func selfCheck() {
        var problems: [String] = [], count = 0
        for k in 0...5 {
            for _ in 0..<1500 {
                let d = Double.random(in: 1...11), n = Int.random(in: 2...4)
                let p = puzzle(kind: k, d: d, n: n, avoid: nil); count += 1
                let lv = k
                let texts = p.choices.map(\.text)
                var ok = Set(texts).count == texts.count && texts[p.correct] == p.answer
                    && texts.filter { $0 == p.answer }.count == 1 && p.shift % 26 != 0
                switch p.mode {
                case .decode:
                    ok = ok && caesar(p.coded, -p.shift) == p.plain
                        && texts.indices.allSatisfy { $0 == p.correct || !isShift(p.coded, texts[$0]) }
                case .encode:
                    ok = ok && texts.indices.allSatisfy { $0 == p.correct || caesar(p.plain, p.shift) != texts[$0] }
                }
                if !ok { problems.append("L\(lv) \(p.plain) k\(p.shift) \(texts)") }
            }
        }
        print("CW-SELFCHECK puzzles=\(count) problems=\(problems.count) \(problems.prefix(5))"); fflush(stdout)
    }
    #endif
}

// MARK: Model

@MainActor
private final class CaesarWheelModel: ArcadeModel {
    enum Stage: Equatable { case asking, right, wrong(Int) }

    @Published var puzzle = CWGen.puzzle(kind: 0, d: 1, n: 2, avoid: nil)
    @Published var stage: Stage = .asking
    @Published var turn: Double = 0           // wheel position in clicks (unbounded; snaps to whole)
    @Published var lit: Int?                  // the tile last tapped
    @Published var read: Set<Int> = []        // tiles read through the wheel (no-read-out levels)
    @Published var puzzleNo = 0

    init() {
        super.init(key: GameID.caesarWheel.rawValue)
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { CWGen.selfCheck() }
        #endif
    }

    override func perLevel(_ level: Int) -> Int { 5 }
    override func onBegin() { next() }

    /// The key the wheel is set to now (0…25): the inner A sits under code letter `rot`.
    var rot: Int { ((Int(turn.rounded()) % 26) + 26) % 26 }
    var keyed: Bool { rot == puzzle.shift }

    /// What a tile's partner on the wheel is right now.
    func partner(of c: Character) -> Character {
        guard let i = cwIndex(c) else { return c }
        return cwLetter(puzzle.mode == .decode ? i - rot : i + rot)
    }

    func next() {
        puzzle = CWGen.puzzle(kind: tier([1, 3.5, 4.8, 5.8, 7, 8.5]), d: d, n: rampInt(2, 4, to: 6.5), avoid: puzzle.plain)
        stage = .asking
        lit = nil; read = []
        puzzleNo += 1
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { turn = 0 }
    }

    // Wheel input — the drag, the ↺ ↻ buttons and the bot all come through here.
    func drag(to t: Double) {
        guard phase == .playing, stage == .asking else { return }
        let before = rot
        turn = t
        if rot != before { Haptics.tap(0.35); Sfx.play(.tick, volume: 0.6); clickedTo() }
    }
    func release() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { turn = turn.rounded() }
    }
    func step(_ d: Int) {
        guard phase == .playing, stage == .asking else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) { turn = turn.rounded() + Double(d) }
        Haptics.tap(0.35); Sfx.play(.tick, volume: 0.6); clickedTo()
    }
    private func clickedTo() {
        if puzzle.glow && keyed { Haptics.success(); Sfx.play(.sparkle, volume: 0.6) }
    }

    func tapTile(_ i: Int) {
        guard phase == .playing, stage == .asking else { return }
        lit = i
        let c = Array(puzzle.shown)[i]
        if cwIndex(c) != nil { read.insert(i) }
        Haptics.light()
    }

    func choose(_ i: Int) {
        guard phase == .playing, stage == .asking else { return }
        if i == puzzle.correct {
            stage = .right
            hit()
            Sfx.play(.sparkle)
            after(1.7) { $0.next() }
        } else {
            stage = .wrong(i)
            // Show the way: turn the wheel to the real key and read the whole thing out.
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { turn = nearestTurn(to: puzzle.shift) }
            read = Set(Array(puzzle.shown).indices)
            let last = miss(delay: 2.8)
            if !last { after(3.0) { $0.next() } }
        }
    }

    /// The whole-click position for key `k` closest to where the wheel is.
    private func nearestTurn(to k: Int) -> Double {
        let base = Int(turn.rounded())
        let d = ((k - base) % 26 + 39) % 26 - 13
        return Double(base + d)
    }

    override func botAct(correct: Bool) {
        guard stage == .asking else { return }
        // Turn first (a slip turns to the wrong key — no harm done), then answer (a slip there is a miss).
        if !keyed {
            let k = correct ? puzzle.shift : Int.random(in: 1...25)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { drag(to: nearestTurn(to: k)) }
            release()
        } else {
            choose(correct ? puzzle.correct : puzzle.choices.indices.filter { $0 != puzzle.correct }.randomElement()!)
        }
    }

    private func after(_ s: Double, _ f: @escaping (CaesarWheelModel) -> Void) {
        let n = puzzleNo
        DispatchQueue.main.asyncAfter(deadline: .now() + s) { [weak self] in
            guard let self, self.phase == .playing, self.puzzleNo == n else { return }
            f(self)
        }
    }
}

// MARK: View

struct CaesarWheelView: View {
    let onClose: () -> Void
    @StateObject private var model = CaesarWheelModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.caesarWheel.spec!, accent: Lu.coral, onClose: onClose,
                    backdrop: { CWTent() }) {
            VStack(spacing: 10) {
                Color.clear.frame(height: 56)
                CWHeader(model: model)
                CWTiles(model: model)
                GeometryReader { g in
                    let d = min(g.size.width - 8, g.size.height)
                    ZStack {
                        CWWheel(model: model, size: d)
                            .frame(width: d, height: d)
                        CWTurnButtons(model: model, size: d)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                CWChoices(model: model)
            }
            .padding(.horizontal, 14).padding(.bottom, 8)
        }
    }
}

/// The messenger, the job and the key.
private struct CWHeader: View {
    @ObservedObject var model: CaesarWheelModel

    var body: some View {
        let p = model.puzzle
        HStack(spacing: 8) {
            ForumPerson(mood: face, hat: .helmet, tunic: 0xa82820, skin: 0xe8b88e, size: 70)
                .scaleEffect(model.stage == .right ? 1.1 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.4), value: model.stage)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(luFont(bigTitle ? 28 : 17, .heavy)).foregroundStyle(Color(hex: titleHex))
                    .lineLimit(2).minimumScaleFactor(0.7)
                Text(sub).font(luFont(12, .bold)).foregroundStyle(Color(hex: 0x6a5a48))
                    .lineLimit(2).minimumScaleFactor(0.7)
            }
            Spacer(minLength: 4)
            if p.told {
                VStack(spacing: 1) {
                    Text("KEY").font(luFont(9, .heavy)).tracking(1.4).foregroundStyle(Color(hex: 0xf3d9a8))
                    Text("A→\(String(cwLetter(p.shift)))").font(luSerif(20, .black)).foregroundStyle(Color(hex: Lu.gold))
                    if p.turnHint {
                        Text("↻ \(p.shift)").font(luFont(13, .heavy)).foregroundStyle(Color(hex: Lu.mint))
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0x7a2a1a))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: Lu.goldLine), lineWidth: 2)))
            }
        }
        .padding(.trailing, 10).padding(.vertical, 4)
        .frame(minHeight: 72)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0xf3e3c0))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: Lu.goldLine), lineWidth: 2)))
        .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
    }

    private var face: ForumPerson.Mood {
        switch model.stage {
        case .asking: return model.keyed && model.puzzle.glow ? .happy : .talk
        case .right: return .cheer
        case .wrong: return .oops
        }
    }
    private var titleHex: UInt {
        switch model.stage {
        case .asking: return Lu.inkDark
        case .right: return 0x2f6a2a
        case .wrong: return 0x9a3a1a
        }
    }
    /// Gradus I asks for one thing only, in big letters.
    private var bigTitle: Bool { model.puzzle.turnHint && model.puzzle.shift == 1 && model.d < 2 && model.stage == .asking }
    private var title: String {
        let p = model.puzzle
        switch model.stage {
        case .right: return "Ave! You cracked it!"
        case .wrong: return p.mode == .decode ? "It said: \(p.plain)" : "In code: \(p.coded)"
        case .asking:
            if bigTitle { return "Tap ↻ once!" }
            if p.mode == .encode { return "Write \(p.plain) in code!" }
            return p.told ? "Turn the wheel to the key!" : "Find the key! Turn till it's a word"
        }
    }
    private var sub: String {
        let p = model.puzzle
        if case .wrong = model.stage { return "The key was A→\(cwLetter(p.shift)) — a shift of \(p.shift)." }
        if p.told && p.live && p.shift == 1 { return "Emperor Augustus wrote B for A — a shift of 1!" }
        if p.told && p.live && p.shift == 3 { return "Julius Caesar wrote D for A — a shift of 3!" }
        if p.mode == .encode { return "Find each letter inside, read the code outside." }
        if !p.told { return p.glow ? "The wheel glows when the key is right." : "Turn until the bottom row makes sense." }
        return p.live ? "The real words read out under the code." : "Tap each code letter to read it."
    }
}

/// The message as letter tiles (tap one to light it and its partner on the wheel), and under
/// them what the wheel reads them as.
private struct CWTiles: View {
    @ObservedObject var model: CaesarWheelModel

    /// Words packed into at most two lines (long phrases wrap), as (tile index, letter) runs.
    private var lines: [[(Int, Character)]] {
        let chars = Array(model.puzzle.shown)
        guard chars.count > 11 else { return [Array(chars.enumerated()).map { ($0.offset, $0.element) }] }
        var words: [[(Int, Character)]] = [[]]
        for (i, c) in chars.enumerated() { if c == " " { words.append([]) } else { words[words.count - 1].append((i, c)) } }
        // Split where the two lines come out most even.
        var best = 1, bestDiff = Int.max
        for k in 1..<words.count {
            let a = words[..<k].map(\.count).reduce(0, +) + k - 1
            let b = words[k...].map(\.count).reduce(0, +) + words.count - k - 1
            if abs(a - b) < bestDiff { bestDiff = abs(a - b); best = k }
        }
        func join(_ ws: ArraySlice<[(Int, Character)]>) -> [(Int, Character)] {
            var out: [(Int, Character)] = []
            for (n, w) in ws.enumerated() { if n > 0 { out.append((-1, " ")) }; out += w }
            return out
        }
        return [join(words[..<best]), join(words[best...])]
    }

    var body: some View {
        let ls = lines
        GeometryReader { g in
            let longest = ls.map(\.count).max() ?? 1
            let w = min(ls.count > 1 ? 34 : 46, (g.size.width - CGFloat(longest - 1) * 4) / CGFloat(max(longest, 1)))
            VStack(spacing: 6) {
                ForEach(Array(ls.enumerated()), id: \.offset) { _, line in
                    HStack(spacing: 4) {
                        ForEach(Array(line.enumerated()), id: \.offset) { _, t in
                            if t.1 == " " {
                                Color.clear.frame(width: w * 0.5, height: 1)
                            } else {
                                tile(t.0, t.1, w)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .frame(height: ls.count > 1 ? 168 : 112)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0x3a2616))
                .overlay(RoundedRectangle(cornerRadius: 10).fill(LinearGradient(colors: [Color(hex: 0x5a4224), Color(hex: 0x4a3418)],
                                                                                 startPoint: .top, endPoint: .bottom)).padding(6))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0x8a5a34), lineWidth: 3))
                .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
        )
    }

    private func tile(_ i: Int, _ c: Character, _ w: CGFloat) -> some View {
        let p = model.puzzle
        let showPartner = p.live || model.read.contains(i) || model.stage != .asking
        let partner = model.partner(of: c)
        let good = (p.glow && model.keyed) || model.stage == .right
        let lit = model.lit == i
        let codeHex: UInt = p.mode == .decode ? Lu.coral : 0xefe4cc
        return Button { model.tapTile(i) } label: {
            VStack(spacing: 4) {
                Text(String(c)).font(luSerif(w * 0.62, .black))
                    .foregroundStyle(Color(hex: p.mode == .decode ? Lu.ink : Lu.inkDark))
                    .frame(width: w, height: w * 1.05)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: codeHex)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: lit ? Lu.gold : Lu.line), lineWidth: lit ? 3 : 1.5))
                Text(showPartner ? String(partner) : "?")
                    .font(luSerif(w * 0.6, .black))
                    .foregroundStyle(Color(hex: good ? Lu.mint : (showPartner ? Lu.gold : 0x8a6a44)))
                    .frame(width: w, height: w * 0.9)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: good ? Lu.mint : 0x8a6a44), lineWidth: 1.5))
                    .scaleEffect(good ? 1.08 : 1)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: good)
    }
}

/// The cipher wheel: the fixed outer ring holds the CODE letters, the inner disc (dragged round)
/// the REAL letters. Letters stay upright; the inner A carries a red dot — its spot is the key.
private struct CWWheel: View {
    @ObservedObject var model: CaesarWheelModel
    let size: CGFloat
    @State private var dragStart: (turn: Double, angle: Double, acc: Double)?

    private let step = 2 * Double.pi / 26

    var body: some View {
        let r = size / 2
        let t = model.turn
        let p = model.puzzle
        let glowing = (p.glow && model.keyed) || model.stage == .right
        let litAngle: Double? = model.lit.flatMap { i -> Double? in
            let c = Array(p.shown)[i]
            guard let idx = cwIndex(c) else { return nil }
            // decode: the code letter is on the outer ring; encode: the real letter is inside.
            return p.mode == .decode ? Double(idx) * step : (Double(idx) + t) * step
        }
        ZStack {
            // Outer ring (code).
            Circle().fill(LinearGradient(colors: [Color(hex: 0x5a2a2a), Color(hex: 0x3a1a24)], startPoint: .top, endPoint: .bottom))
            Circle().stroke(Color(hex: glowing ? Lu.mint : Lu.goldLine), lineWidth: glowing ? 6 : 3)
                .shadow(color: glowing ? Color(hex: Lu.mint) : .clear, radius: glowing ? 10 : 0)
            // Inner disc (real letters).
            Circle().fill(RadialGradient(colors: [Color(hex: 0xf8e7b0), Color(hex: 0xd9b25a)], center: .center,
                                         startRadius: 0, endRadius: r * 0.78))
                .frame(width: r * 1.56, height: r * 1.56)
            Circle().stroke(Color(hex: 0x9c7b33), lineWidth: 2).frame(width: r * 1.56, height: r * 1.56)
            // Key window: the inner A and the code letter over it.
            pill(angle: (t.rounded()) * step, r: r, hex: Lu.gold, width: 4)
            if let a = litAngle { pill(angle: a, r: r, hex: Lu.mint, width: 5) }
            ForEach(0..<26, id: \.self) { i in
                let a = Double(i) * step
                Text(String(cwAlphabet[i])).font(luSerif(r * 0.13, .black))
                    .foregroundStyle(Color(hex: 0xffb39a))
                    .position(pt(a, r * 0.89, r))
            }
            ForEach(0..<26, id: \.self) { j in
                let a = (Double(j) + t) * step
                ZStack {
                    if j == 0 { Circle().fill(Color(hex: Lu.coral)).frame(width: r * 0.06).offset(y: -r * 0.085) }
                    Text(String(cwAlphabet[j])).font(luSerif(r * 0.12, .black))
                        .foregroundStyle(Color(hex: Lu.inkDark))
                }
                .position(pt(a, r * 0.66, r))
            }
            // Hub.
            Circle().fill(RadialGradient(colors: [Color(hex: 0x6a3a1e), Color(hex: 0x3a1e0e)], center: .center, startRadius: 0, endRadius: r * 0.31))
                .frame(width: r * 0.62, height: r * 0.62)
                .overlay(Circle().stroke(Color(hex: Lu.goldLine), lineWidth: 2))
            VStack(spacing: 0) {
                Text("A→\(String(cwLetter(model.rot)))").font(luSerif(r * 0.15, .black))
                    .foregroundStyle(Color(hex: glowing ? Lu.mint : Lu.gold))
                Text(glowing ? "✨" : "🏛️").font(.system(size: r * 0.11))
            }
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(DragGesture(minimumDistance: 2)
            .onChanged { v in
                let a = atan2(v.location.y - r, v.location.x - r)
                if dragStart == nil { dragStart = (model.turn, a, 0) }
                guard var s = dragStart else { return }
                var d = a - s.angle
                while d > .pi { d -= 2 * .pi }
                while d < -.pi { d += 2 * .pi }
                s.acc += d; s.angle = a; dragStart = s
                model.drag(to: s.turn + s.acc / step)
            }
            .onEnded { _ in dragStart = nil; model.release() })
    }

    /// Point at clockwise-from-top angle `a`, radius `rad`, about the centre (r, r).
    private func pt(_ a: Double, _ rad: CGFloat, _ r: CGFloat) -> CGPoint {
        CGPoint(x: r + rad * CGFloat(sin(a)), y: r - rad * CGFloat(cos(a)))
    }

    /// A capsule spanning both rings at angle `a` (pairs a code letter with its real letter).
    private func pill(angle a: Double, r: CGFloat, hex: UInt, width: CGFloat) -> some View {
        Capsule().stroke(Color(hex: hex), lineWidth: width)
            .frame(width: r * 0.2, height: r * 0.44)
            .rotationEffect(.radians(a))
            .position(pt(a, r * 0.775, r))
    }
}

/// Big ↺ ↻ buttons in the wheel's lower corners (one click each).
private struct CWTurnButtons: View {
    @ObservedObject var model: CaesarWheelModel
    let size: CGFloat
    var body: some View {
        VStack {
            Spacer()
            HStack {
                button("arrow.counterclockwise", -1)
                Spacer()
                button("arrow.clockwise", 1)
            }
        }
        .frame(width: size + 8, height: size)
    }
    private func button(_ icon: String, _ d: Int) -> some View {
        let hint = model.puzzle.turnHint && d == 1 && !model.keyed && model.stage == .asking
        return Button { model.step(d) } label: {
            Image(systemName: icon).font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Color(hex: hint ? Lu.inkDark : 0xfdf0d0))
                .frame(width: 64, height: 64)
                .background(Circle().fill(hint ? AnyShapeStyle(Color(hex: Lu.mint))
                                               : AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xc08a4a), Color(hex: 0x7a4a22)],
                                                                              startPoint: .top, endPoint: .bottom)))
                    .overlay(Circle().stroke(Color(hex: 0x4a2c16), lineWidth: 2.5)))
                .shadow(color: .black.opacity(0.35), radius: 4, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.2), value: hint)
    }
}

/// The answer buttons: pictures (with the word) early on, then words, phrases or codes.
private struct CWChoices: View {
    @ObservedObject var model: CaesarWheelModel

    var body: some View {
        let p = model.puzzle
        let cols = p.pictured ? p.choices.count : 2
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: cols), spacing: 10) {
            ForEach(Array(p.choices.enumerated()), id: \.offset) { i, c in
                Button { model.choose(i) } label: { label(i, c) }
                    .buttonStyle(.plain)
            }
        }
    }

    private func label(_ i: Int, _ c: CWChoice) -> some View {
        let p = model.puzzle
        let fill: UInt = {
            switch model.stage {
            case .asking: return 0xf3e3c0
            case .right: return i == p.correct ? Lu.mint : 0xf3e3c0
            case .wrong(let w): return i == p.correct ? Lu.mint : (i == w ? Lu.coral : 0xf3e3c0)
            }
        }()
        let dark = true
        return VStack(spacing: 2) {
            if let e = c.emoji { Text(e).font(.system(size: 44)) }
            Text(c.text).font(luSerif(c.emoji != nil ? 17 : 16, .black)).tracking(1)
                .foregroundStyle(Color(hex: dark ? Lu.inkDark : Lu.ink))
                .lineLimit(2).minimumScaleFactor(0.6).multilineTextAlignment(.center)
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, minHeight: c.emoji != nil ? 96 : 58)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: fill))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: Lu.goldLine), lineWidth: 2)))
        .shadow(color: .black.opacity(0.3), radius: 4, y: 3)
        .scaleEffect(model.stage != .asking && i == p.correct ? 1.05 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: model.stage)
    }
}

/// Caesar's command tent at night: striped canvas walls, a hanging lamp's warm glow, a map table.
private struct CWTent: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Color(hex: 0x3a1a14)
                // Canvas stripes, falling from the ridge.
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { i in
                        Rectangle().fill(Color(hex: i.isMultiple(of: 2) ? 0x8a2a1e : 0xb89a6a))
                    }
                }
                .opacity(0.85)
                // Tent folds: darker toward the edges.
                LinearGradient(colors: [.black.opacity(0.55), .clear, .clear, .black.opacity(0.55)], startPoint: .leading, endPoint: .trailing)
                // The ridge pole and drape.
                ForumTriangle().fill(Color(hex: 0x2a120c)).frame(width: w * 1.3, height: h * 0.12).rotationEffect(.degrees(180))
                    .position(x: w / 2, y: h * 0.04)
                // Lamp glow.
                RadialGradient(colors: [Color(hex: 0xffc46a).opacity(0.55), .clear], center: UnitPoint(x: 0.5, y: 0.42),
                               startRadius: 0, endRadius: w * 0.9)
                // A map table along the bottom.
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0x7a4a26), Color(hex: 0x4a2a14)], startPoint: .top, endPoint: .bottom))
                    .frame(height: h * 0.2).position(x: w / 2, y: h * 0.9)
                Rectangle().fill(Color(hex: 0x9a6a3a)).frame(height: 4).position(x: w / 2, y: h * 0.8)
            }
        }
    }
}
