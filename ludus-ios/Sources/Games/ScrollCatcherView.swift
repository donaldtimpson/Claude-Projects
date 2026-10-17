import SwiftUI

// MARK: - Scroll Catcher  (Word Wizards · catch)
//
// Letters tumble off the library shelf; drag the basket to catch the NEXT letter of the pictured
// word. The word's slots fill as you catch. A wrong letter is a miss (from III, so is letting the
// right one drop): the right letter glows and its slot shows it faintly, then it falls again.
//
// Ladder (3 words a level):
//   I    3-letter CVC with a picture, all slots show the word faintly; next letter + 1 unlike decoy;
//        slow (6.5 s fall), wide basket
//   II   CVC, the faint word still shown; 2 unlike decoys; 6 s
//   III  blends (frog, stop, milk), no faint word; 2 decoys incl. a look-alike (b/d, m/n…); 5.5 s
//   IV   digraphs & -ck (ship, chick, duck), 2 decoys, 5 s
//   V    silent-e & vowel teams (cake, boat, rain), 3 decoys, 4.7 s
//   VI   two-syllable words; the word shows for 3 s then hides (picture stays); 4.4 s
//   VII+ tricky spellings (separate, rhythm…), heard 🔊 + shown 2.5 s; a decoy is the classic wrong
//        letter (sep-e-rate); 4.1 s easing to 3.2 s
// After 2 misses in a row the fall slows and the right letter glows (any level).

private struct SCWord: Hashable {
    let text: String
    let emoji: String                 // "" = no picture (tricky words: hear it instead)
    var traps: [Int: Character] = [:]  // index → the classic wrong letter there
    var letters: [Character] { Array(text) }
}

private func sw(_ list: [(String, String)]) -> [SCWord] { list.map { SCWord(text: $0.0, emoji: $0.1) } }

private let scCVC = sw([
    ("cat", "🐱"), ("dog", "🐶"), ("sun", "☀️"), ("pig", "🐷"), ("bus", "🚌"), ("hat", "🎩"), ("bed", "🛏️"),
    ("box", "📦"), ("fox", "🦊"), ("bat", "🦇"), ("pen", "🖊️"), ("map", "🗺️"), ("ten", "🔟"), ("can", "🥫"),
    ("leg", "🦵"), ("web", "🕸️"),
])
private let scBlends = sw([
    ("frog", "🐸"), ("stop", "🛑"), ("milk", "🥛"), ("crab", "🦀"), ("drum", "🥁"), ("flag", "🚩"), ("sled", "🛷"),
    ("swim", "🏊"), ("tent", "⛺"), ("hand", "✋"), ("plant", "🪴"), ("clap", "👏"), ("skunk", "🦨"),
    ("plug", "🔌"), ("ant", "🐜"),
])
private let scDigraphs = sw([
    ("duck", "🦆"), ("fish", "🐟"), ("shell", "🐚"), ("chick", "🐥"), ("sock", "🧦"), ("lock", "🔒"),
    ("ring", "💍"), ("brush", "🖌️"), ("truck", "🚚"), ("clock", "⏰"), ("brick", "🧱"), ("watch", "⌚"),
])
private let scVowelTeams = sw([
    ("cake", "🍰"), ("boat", "⛵"), ("kite", "🪁"), ("bike", "🚲"), ("rose", "🌹"), ("nose", "👃"),
    ("bone", "🦴"), ("snake", "🐍"), ("whale", "🐋"), ("tree", "🌳"), ("bee", "🐝"), ("sheep", "🐑"), ("cheese", "🧀"),
    ("goat", "🐐"), ("train", "🚂"), ("snail", "🐌"), ("moon", "🌙"), ("spoon", "🥄"), ("five", "5️⃣"),
    ("mouse", "🐁"), ("house", "🏠"), ("cloud", "☁️"), ("book", "📖"),
])
private let scTwoSyllable = sw([
    ("pencil", "✏️"), ("basket", "🧺"), ("robot", "🤖"), ("rocket", "🚀"), ("tiger", "🐯"),
    ("lemon", "🍋"), ("apple", "🍎"), ("carrot", "🥕"), ("window", "🪟"), ("candle", "🕯️"), ("monkey", "🐵"),
    ("turtle", "🐢"), ("dragon", "🐉"), ("magnet", "🧲"), ("zebra", "🦓"), ("panda", "🐼"),
    ("camel", "🐫"), ("spider", "🕷️"), ("pizza", "🍕"), ("cactus", "🌵"),
])
private let scTricky: [SCWord] = [
    SCWord(text: "because", emoji: "", traps: [3: "o", 5: "z"]),
    SCWord(text: "friend", emoji: "", traps: [2: "e", 3: "n"]),
    SCWord(text: "said", emoji: "", traps: [1: "e"]),
    SCWord(text: "people", emoji: "", traps: [2: "p"]),
    SCWord(text: "again", emoji: "", traps: [2: "e", 3: "n"]),
    SCWord(text: "beautiful", emoji: "", traps: [2: "u", 7: "e"]),
    SCWord(text: "separate", emoji: "", traps: [3: "e"]),
    SCWord(text: "necessary", emoji: "", traps: [3: "c", 5: "a"]),
    SCWord(text: "rhythm", emoji: "", traps: [1: "y", 4: "m"]),
    SCWord(text: "island", emoji: "", traps: [1: "l"]),
    SCWord(text: "knight", emoji: "", traps: [0: "n", 3: "t"]),
    SCWord(text: "believe", emoji: "", traps: [3: "e"]),
    SCWord(text: "receive", emoji: "", traps: [2: "s", 3: "i"]),
    SCWord(text: "answer", emoji: "", traps: [3: "e"]),
    SCWord(text: "laugh", emoji: "", traps: [2: "f"]),
    SCWord(text: "enough", emoji: "", traps: [2: "u", 3: "f"]),
    SCWord(text: "listen", emoji: "", traps: [3: "e"]),
    SCWord(text: "castle", emoji: "", traps: [3: "l"]),
    SCWord(text: "science", emoji: "", traps: [1: "i", 5: "s"]),
    SCWord(text: "write", emoji: "", traps: [0: "r"]),
    SCWord(text: "could", emoji: "", traps: [3: "d"]),
    SCWord(text: "busy", emoji: "", traps: [1: "i", 2: "z"]),
]

/// Letters that look or sound alike — the decoys that make a child look twice.
private let scAlike: [Character: [Character]] = [
    "a": ["e", "o", "u"], "b": ["d", "p"], "c": ["k", "s", "e"], "d": ["b", "p"], "e": ["a", "i"], "f": ["t", "v"],
    "g": ["j", "q"], "h": ["n"], "i": ["e", "l", "j"], "j": ["g", "i"], "k": ["c"], "l": ["i", "t"], "m": ["n", "w"],
    "n": ["m", "h", "u"], "o": ["a", "u"], "p": ["b", "q", "d"], "q": ["p", "g"], "r": ["n"], "s": ["c", "z"],
    "t": ["f", "l"], "u": ["n", "o"], "v": ["w", "f"], "w": ["v", "m"], "x": ["z"], "y": ["i"], "z": ["s"],
]

private func scDeck(_ level: Int) -> [SCWord] {
    switch level {
    case ...2: return scCVC
    case 3: return scBlends
    case 4: return scDigraphs
    case 5: return scVowelTeams
    case 6: return scTwoSyllable
    default: return scTricky
    }
}
private func scDecoyCount(_ level: Int) -> Int { level <= 1 ? 1 : level <= 4 ? 2 : 3 }
/// Seconds for a letter to fall from the shelf to the basket.
private func scFall(_ level: Int) -> Double {
    let t: [Double] = [6.5, 6.0, 5.5, 5.0, 4.7, 4.4, 4.1]
    return level <= 7 ? t[level - 1] : max(3.2, 4.1 - Double(level - 7) * 0.15)
}
private func scBasketFrac(_ level: Int) -> CGFloat { [0.30, 0.28, 0.26, 0.24, 0.22][min(level, 5) - 1] - (level >= 6 ? 0.02 : 0) }
private func scTile(_ level: Int) -> CGFloat { level <= 2 ? 64 : level <= 4 ? 58 : 54 }

/// The decoys falling beside `needed` (never `needed` itself).
private func scDecoys(word: SCWord, index: Int, level: Int) -> [Character] {
    let needed = word.letters[index]
    let inWord = Set(word.letters)
    let alike = scAlike[needed] ?? []
    var out: [Character] = []
    if level >= 7, let t = word.traps[index], t != needed { out.append(t) }
    if level >= 3, let a = alike.shuffled().first(where: { $0 != needed && !out.contains($0) && (level >= 3 || !inWord.contains($0)) }) {
        out.append(a)
    }
    let pool = Array("abcdefghijklmnopqrstuvwxyz").shuffled().filter { c in
        c != needed && !out.contains(c) && (level >= 3 || !inWord.contains(c)) && (level >= 3 || !alike.contains(c))
    }
    for c in pool where out.count < scDecoyCount(level) { out.append(c) }
    return Array(out.prefix(scDecoyCount(level)))
}

#if DEBUG
/// LUDUS_SELFCHECK=1: every deck word is plain lowercase, traps sit at real indices and differ from
/// the right letter, and no wave ever offers the right letter twice.
private func scSelfCheck() {
    var problems: [String] = []
    for lv in 1...9 {
        for wd in scDeck(lv) {
            if wd.text.contains(where: { !("a"..."z").contains($0) }) { problems.append("\(wd.text) chars") }
            if lv < 7 && wd.emoji.isEmpty { problems.append("\(wd.text) no picture") }
            for (i, t) in wd.traps where i >= wd.letters.count || wd.letters[i] == t { problems.append("\(wd.text) trap \(i)") }
            for i in wd.letters.indices {
                let d = scDecoys(word: wd, index: i, level: lv)
                if d.contains(wd.letters[i]) { problems.append("\(wd.text)[\(i)] decoy = answer") }
                if d.count != scDecoyCount(lv) || Set(d).count != d.count { problems.append("\(wd.text)[\(i)] decoys \(d)") }
                if lv <= 2 && d.contains(where: { wd.letters.contains($0) }) { problems.append("\(wd.text) L\(lv) decoy in word") }
                if lv <= 2 && d.contains(where: { (scAlike[wd.letters[i]] ?? []).contains($0) }) { problems.append("\(wd.text) L\(lv) look-alike decoy") }
            }
        }
    }
    for wd in scCVC where wd.text.count != 3 { problems.append("\(wd.text) not CVC") }
    print("SCROLL SELFCHECK: \(problems.isEmpty ? "OK" : problems.joined(separator: " | "))")
}
#endif

// MARK: - Model

private struct SCFalling {
    let ch: Character
    var x: CGFloat, y: CGFloat
    var delay: Double
    let needed: Bool
    var bad: CGFloat = 0          // > 0: caught by mistake, flashing out
}
private struct SCSpark { var x, y, vx, vy, life: CGFloat; let glyph: String }

@MainActor
private final class ScrollModel: ArcadeModel {
    @Published var word = SCWord(text: "cat", emoji: "🐱")
    @Published var filled = 0
    @Published var ghostNext = false
    @Published var showWord = false
    @Published var wordID = 0
    @Published var done = false

    // Frame-loop state (not published — the Canvas redraws every frame).
    private(set) var letters: [SCFalling] = []
    private(set) var sparks: [SCSpark] = []
    private(set) var basketX: CGFloat = -1
    private(set) var basketShake: CGFloat = 0
    private(set) var glow = false
    private var size: CGSize = .zero
    private var lastTick: Date?
    private var waveIn: Double = 0.4
    private var running = false
    private var missRun = 0
    private var recent: [String] = []
    private var botTarget: CGFloat?
    private var wave = 0, botWave = -1
    private var wordGen = 0

    init() {
        super.init(key: GameID.scrollCatcher.rawValue)
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { scSelfCheck() }
        #endif
    }

    override func perLevel(_ level: Int) -> Int { 3 }

    // Geometry (in the play area's coordinates).
    var shelfY: CGFloat { 196 }
    var spawnY: CGFloat { shelfY + 26 }
    var basketY: CGFloat { size.height - 64 }
    var basketW: CGFloat { max(80, size.width * scBasketFrac(level)) }
    var tile: CGFloat { scTile(level) }
    var ghostAll: Bool { level <= 2 }

    override func onBegin() {
        letters.removeAll(); sparks.removeAll()
        lastTick = nil; missRun = 0; recent = []; botTarget = nil
        running = true
        newWord()
    }

    private func newWord() {
        let deck = scDeck(level).filter { !recent.contains($0.text) }
        word = (deck.isEmpty ? scDeck(level) : deck).randomElement()!
        recent = Array((recent + [word.text]).suffix(6))
        filled = 0; ghostNext = false; done = false
        wordID += 1; wordGen += 1
        let flash = level >= 7 ? 2.5 : (level == 6 ? 3.0 : 0)
        letters.removeAll(); waveIn = flash > 0 ? flash - 0.6 : 0.5   // read it before letters fall
        showWord = flash > 0
        if flash > 0 {
            let g = wordGen
            DispatchQueue.main.asyncAfter(deadline: .now() + flash) { [weak self] in
                guard let self, self.wordGen == g else { return }
                withAnimation(.easeOut(duration: 0.3)) { self.showWord = false }
            }
        }
        LibraryVoice.say(word.text, rate: 0.38)
    }

    func sayWord() { LibraryVoice.say(word.text, rate: 0.38) }

    /// The child's drag (and the bot's steering) move the basket here.
    func moveBasket(to x: CGFloat) {
        guard size.width > 0 else { return }
        basketX = min(max(x, basketW / 2), size.width - basketW / 2)
    }

    /// One frame: steer, fall, catch, spawn. Published changes are deferred (we're inside a draw).
    func step(_ date: Date, size: CGSize) {
        self.size = size
        if basketX < 0 { basketX = size.width / 2 }
        guard let prev = lastTick else { lastTick = date; return }
        lastTick = date
        let dt = min(max(date.timeIntervalSince(prev), 0), 0.05)
        stepSparks(dt)
        if basketShake > 0 { basketShake = max(0, basketShake - CGFloat(dt) * 2.5) }
        guard running, phase == .playing, size.width > 0 else { return }

        if let t = botTarget {
            let maxStep = CGFloat(820 * dt)
            moveBasket(to: basketX + max(-maxStep, min(maxStep, t - basketX)))
        }

        if !done && !letters.contains(where: { $0.bad == 0 }) {
            waveIn -= dt
            if waveIn <= 0 { spawnWave() }
        }

        var fall = scFall(level)
        if missRun >= 2 { fall *= 1.25 }
        let speed = (basketY - spawnY) / CGFloat(fall)
        let reach = basketW / 2 + 4
        var caughtIndex: Int?, fellNeeded = false
        for i in letters.indices {
            if letters[i].bad > 0 { letters[i].bad += CGFloat(dt) * 2.2; continue }
            if letters[i].delay > 0 { letters[i].delay -= dt; continue }
            let before = letters[i].y
            letters[i].y += speed * CGFloat(dt)
            // Caught when it crosses the basket's rim inside the basket's width.
            if caughtIndex == nil, before < basketY - 8, letters[i].y >= basketY - 8, abs(letters[i].x - basketX) <= reach {
                caughtIndex = i
            }
            if letters[i].needed && letters[i].y > size.height + tile { fellNeeded = true }
        }
        letters.removeAll { $0.bad >= 1 || (!$0.needed && $0.y > size.height + tile) }

        if let i = caughtIndex {
            if letters[i].needed { caughtRight(i) } else { caughtWrong(i) }
        } else if fellNeeded {
            dropped()
        }
    }

    private func spawnWave() {
        guard filled < word.letters.count else { return }
        let needed = word.letters[filled]
        let chars = ([needed] + scDecoys(word: word, index: filled, level: level)).shuffled()
        let n = chars.count
        let spacing = min(0.56, 0.76 / CGFloat(max(1, n - 1)))
        letters = chars.enumerated().map { k, c in
            let fx = 0.5 + (CGFloat(k) - CGFloat(n - 1) / 2) * spacing
            return SCFalling(ch: c, x: size.width * fx + CGFloat.random(in: -8...8), y: spawnY,
                             delay: Double.random(in: 0...1.0), needed: c == needed)
        }
        wave += 1
        glow = missRun >= 2 || ghostNext
    }

    private func caughtRight(_ i: Int) {
        let l = letters[i]
        burst(at: CGPoint(x: l.x, y: basketY - 10), glyph: "✨", n: 7)
        letters.removeAll()
        missRun = 0
        waveIn = 0.35
        let complete = filled + 1 >= word.letters.count
        if complete { done = true }
        DispatchQueue.main.async { [self] in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { filled += 1; ghostNext = false }
            Haptics.tap(0.5)
            if complete { finishWord() }
        }
    }

    private func finishWord() {
        burst(at: CGPoint(x: size.width / 2, y: 130), glyph: "⭐️", n: 9)
        LibraryVoice.say(word.text, rate: 0.4)
        hit(points: word.letters.count)
        let g = wordGen
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            guard let self, self.wordGen == g, self.phase == .playing else { return }
            self.newWord()
        }
    }

    private func caughtWrong(_ i: Int) {
        letters[i].bad = 0.01
        basketShake = 1
        botWave = -1          // like a child, the bot then chases the glowing right letter
        missRun += 1
        glow = true
        DispatchQueue.main.async { [self] in
            withAnimation(.easeOut(duration: 0.2)) { ghostNext = true }
            if miss(delay: 1.2) { running = false }
        }
    }

    /// The right letter fell past. Through level II it just falls again (with its hint); from III
    /// it costs a heart.
    private func dropped() {
        letters.removeAll()
        missRun += 1
        waveIn = 0.7
        let costs = level >= 3
        DispatchQueue.main.async { [self] in
            withAnimation(.easeOut(duration: 0.2)) { ghostNext = true }
            if costs, miss(reason: "Out of hearts!", delay: 1.2) { running = false }
        }
    }

    private func burst(at p: CGPoint, glyph: String, n: Int) {
        for _ in 0..<n {
            let a = Double.random(in: 0..<(2 * .pi)), v = Double.random(in: 90...220)
            sparks.append(SCSpark(x: p.x, y: p.y, vx: CGFloat(cos(a) * v), vy: CGFloat(sin(a) * v - 120), life: 1, glyph: glyph))
        }
    }

    private func stepSparks(_ dt: Double) {
        for i in sparks.indices {
            sparks[i].life -= CGFloat(dt) * 1.4
            sparks[i].vy += CGFloat(320 * dt)
            sparks[i].x += sparks[i].vx * CGFloat(dt)
            sparks[i].y += sparks[i].vy * CGFloat(dt)
        }
        sparks.removeAll { $0.life <= 0 }
    }

    /// One decision per wave, like a child picking a letter to chase; the basket then glides there.
    override func botAct(correct: Bool) {
        let live = letters.filter { $0.bad == 0 }
        guard botWave != wave, let right = live.first(where: { $0.needed }) else { return }
        botWave = wave
        if correct {
            botTarget = right.x
        } else if let d = live.filter({ !$0.needed }).max(by: { $0.y < $1.y }) {
            botTarget = d.x
        } else {
            botTarget = right.x < size.width / 2 ? size.width - 20 : 20
        }
    }

    // MARK: Drawing

    func render(_ ctx: inout GraphicsContext, size: CGSize) {
        drawShelf(&ctx, size)
        for l in letters where l.delay <= 0 || l.bad > 0 { drawLetter(&ctx, l) }
        drawBasket(&ctx)
        for s in sparks {
            ctx.opacity = Double(max(0, s.life))
            ctx.draw(Text(s.glyph).font(.system(size: 22)), at: CGPoint(x: s.x, y: s.y))
        }
        ctx.opacity = 1
    }

    private func drawShelf(_ ctx: inout GraphicsContext, _ size: CGSize) {
        let hexes: [UInt] = [Lu.coral, Lu.sky, Lu.mint, Lu.grape, Lu.tangerine, Lu.gold]
        var x: CGFloat = 4, k = 0
        while x < size.width - 4 {
            let w = CGFloat(12 + (k * 7) % 9), h = CGFloat(22 + (k * 5) % 12)
            let r = CGRect(x: x, y: shelfY - h, width: w, height: h)
            ctx.fill(Path(roundedRect: r, cornerRadius: 2), with: .color(Color(hex: hexes[k % hexes.count]).opacity(0.75)))
            x += w + 2; k += 1
            if k % 7 == 3 { x += 16 }
        }
        ctx.fill(Path(roundedRect: CGRect(x: 0, y: shelfY, width: size.width, height: 9), cornerRadius: 3),
                 with: .linearGradient(Gradient(colors: [Color(hex: 0x9a6a3c), Color(hex: 0x5e3a1c)]),
                                       startPoint: CGPoint(x: 0, y: shelfY), endPoint: CGPoint(x: 0, y: shelfY + 9)))
    }

    private func drawLetter(_ ctx: inout GraphicsContext, _ l: SCFalling) {
        let s = tile * (l.bad > 0 ? 1 - l.bad * 0.5 : 1)
        let rect = CGRect(x: l.x - s / 2, y: l.y - s / 2, width: s, height: s)
        ctx.opacity = l.bad > 0 ? Double(1 - l.bad) : 1
        if l.needed && glow {
            let g = rect.insetBy(dx: -12, dy: -12)
            ctx.fill(Path(ellipseIn: g), with: .radialGradient(Gradient(colors: [Color(hex: Lu.gold).opacity(0.85), .clear]),
                                                               center: CGPoint(x: l.x, y: l.y), startRadius: s * 0.3, endRadius: s * 0.85))
        }
        let face = Path(roundedRect: rect, cornerRadius: s * 0.22)
        ctx.fill(face, with: .color(Color(hex: l.bad > 0 ? Lu.coral : 0xfbf3df)))
        ctx.stroke(face, with: .color(Color(hex: l.bad > 0 ? 0x8a2a1a : Lu.goldLine)), lineWidth: 3)
        ctx.draw(Text(String(l.ch)).font(luFont(s * 0.62)).foregroundColor(Color(hex: Lu.inkDark)),
                 at: CGPoint(x: l.x, y: l.y - s * 0.03))
        if l.bad > 0 {
            ctx.draw(Text("✗").font(luFont(s * 0.5)).foregroundColor(.white), at: CGPoint(x: l.x + s * 0.42, y: l.y - s * 0.42))
        }
        ctx.opacity = 1
    }

    private func drawBasket(_ ctx: inout GraphicsContext) {
        let w = basketW, h: CGFloat = 46
        let cx = basketX + sin(basketShake * 30) * 10 * basketShake
        let top = basketY - 8
        var body = Path()
        body.move(to: CGPoint(x: cx - w / 2, y: top))
        body.addLine(to: CGPoint(x: cx + w / 2, y: top))
        body.addLine(to: CGPoint(x: cx + w / 2 - 12, y: top + h))
        body.addLine(to: CGPoint(x: cx - w / 2 + 12, y: top + h))
        body.closeSubpath()
        ctx.fill(body, with: .linearGradient(Gradient(colors: [Color(hex: 0xd8a35c), Color(hex: 0x8f5a2a)]),
                                             startPoint: CGPoint(x: cx, y: top), endPoint: CGPoint(x: cx, y: top + h)))
        // Weave
        var weave = Path()
        for k in 1..<4 {
            let y = top + h * CGFloat(k) / 4
            let inset = 12 * CGFloat(k) / 4
            weave.move(to: CGPoint(x: cx - w / 2 + inset, y: y)); weave.addLine(to: CGPoint(x: cx + w / 2 - inset, y: y))
        }
        var x = cx - w / 2 + 14
        while x < cx + w / 2 - 10 { weave.move(to: CGPoint(x: x, y: top)); weave.addLine(to: CGPoint(x: x + (x - cx) * -0.1, y: top + h)); x += 16 }
        ctx.stroke(weave, with: .color(Color(hex: 0x5e3a1c).opacity(0.55)), lineWidth: 2)
        // Rim
        ctx.fill(Path(roundedRect: CGRect(x: cx - w / 2 - 5, y: top - 6, width: w + 10, height: 11), cornerRadius: 5.5),
                 with: .color(Color(hex: basketShake > 0 ? Lu.coral : Lu.gold)))
    }
}

// MARK: - Views

struct ScrollCatcherView: View {
    let onClose: () -> Void
    @StateObject private var model = ScrollModel()

    var body: some View {
        ArcadeShell(model: model,
                    spec: GameID.scrollCatcher.spec ?? GameSpec(title: "Scroll Catcher", mechanic: "", premise: "", game: .scrollCatcher),
                    accent: Lu.mint, onClose: { LibraryVoice.stop(); onClose() }) {
            ZStack(alignment: .top) {
                TimelineView(.animation(paused: model.phase != .playing)) { tl in
                    Canvas { ctx, size in
                        model.step(tl.date, size: size)
                        model.render(&ctx, size: size)
                    }
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { model.moveBasket(to: $0.location.x) })

                ScrollWordPanel(model: model)
                    .padding(.top, 60).padding(.horizontal, 14)
            }
        }
        .onDisappear { LibraryVoice.stop() }
    }
}

/// The picture, its word slots (filling as letters are caught) and a 🔊 button.
private struct ScrollWordPanel: View {
    @ObservedObject var model: ScrollModel
    @State private var pulse = false

    var body: some View {
        let letters = model.word.letters
        let n = letters.count
        let slotW = min(52, (UIScreen.main.bounds.width - 150) / CGFloat(max(n, 1)) - 4)
        VStack(spacing: 4) {
            HStack(spacing: 10) {
                Button { model.sayWord() } label: {
                    if model.word.emoji.isEmpty {
                        Image(systemName: "speaker.wave.2.fill").font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color(hex: Lu.inkDark))
                            .frame(width: 64, height: 64).background(Circle().fill(Color(hex: Lu.gold)))
                    } else {
                        Text(model.word.emoji).font(.system(size: 58)).frame(width: 70, height: 70)
                    }
                }
                .buttonStyle(.plain)

                HStack(spacing: 4) {
                    ForEach(0..<n, id: \.self) { i in slot(i, letters[i], w: slotW) }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(luPanelShape(20))
            .overlay(alignment: .bottom) {
                if model.showWord {
                    Text(model.word.text)
                        .font(luSerif(30, .black)).tracking(3).foregroundStyle(Color(hex: Lu.inkDark))
                        .padding(.horizontal, 16).padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: Lu.gold)))
                        .offset(y: 26)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .scaleEffect(model.done ? 1.05 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: model.done)
        }
        .id(model.wordID)
        .onAppear { withAnimation(.easeInOut(duration: 0.6).repeatForever()) { pulse = true } }
    }

    @ViewBuilder private func slot(_ i: Int, _ c: Character, w: CGFloat) -> some View {
        let isFilled = i < model.filled
        let isNext = i == model.filled && !model.done
        let ghost = !isFilled && (model.ghostAll || (isNext && model.ghostNext))
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: isFilled ? (model.done ? Lu.mint : Lu.gold) : Lu.ground))
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: isNext ? Lu.gold : Lu.line), lineWidth: isNext ? 3 : 2)
                .opacity(isNext ? (pulse ? 1 : 0.35) : 1)
            if isFilled {
                Text(String(c)).font(luFont(w * 0.72)).foregroundStyle(Color(hex: Lu.inkDark))
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
            } else if ghost {
                Text(String(c)).font(luFont(w * 0.72)).foregroundStyle(Color(hex: Lu.ink).opacity(0.35))
            }
        }
        .frame(width: w, height: w * 1.2)
        .scaleEffect(isNext ? 1.08 : 1)
    }
}
