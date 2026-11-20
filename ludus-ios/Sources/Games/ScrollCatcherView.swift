import SwiftUI

// MARK: - Scroll Catcher  (Word Wizards · catch)
//
// Letters tumble off the library shelf; drag the basket to catch the NEXT letter of the pictured
// word. The word's slots fill as you catch. A wrong letter is a miss (from III, so is letting the
// right one drop): the right letter glows and its slot shows it faintly, then it falls again.
//
// Continuous difficulty (GameKit `d`; 3 words a Gradus). Word kinds fade in via `tier` and the
// easier kinds stay as review:
//   CVC with a picture (d 1) → blends (2.5) → digraphs & -ck (3.8) → silent-e & vowel teams (5)
//   → two-syllable words (6.2) → tricky spellings, heard not seen (7.5)
//   faint whole word in the slots: always below d 2, gone by d 3.2
//   decoys 1 → 3 by d 5.5; look-alike decoys (b/d, m/n) phase in from d 2.5; the classic wrong
//   letter (sep-E-rate) from d 7; a picture-word flashes then hides from d 5.5 (tricky words
//   always flash first); fall time 5.2 s → 3 s by d 10; the scroll box narrows 30% → 20%.
// Letting the right letter fall costs a heart from d 2.5 (before that it just falls again).
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

private let scDecks: [[SCWord]] = [scCVC, scBlends, scDigraphs, scVowelTeams, scTwoSyllable, scTricky]
private let scTierStarts: [Double] = [1, 2.5, 3.8, 5, 6.2, 7.5]

/// How the current word plays — fixed when the word starts (the fall speed stays live).
private struct SCConfig {
    var decoys = 1
    var alike = false        // look-alike decoys (b/d…), and letters from the word itself
    var traps = false        // the classic wrong letter
    var ghost = true         // the whole word shows faintly in the slots
    var flash: Double = 0    // seconds the written word shows before hiding (0 = no flash)
}

/// The decoys falling beside `needed` (never `needed` itself).
private func scDecoys(word: SCWord, index: Int, cfg: SCConfig) -> [Character] {
    let needed = word.letters[index]
    let inWord = Set(word.letters)
    let alike = scAlike[needed] ?? []
    var out: [Character] = []
    if cfg.traps, let t = word.traps[index], t != needed { out.append(t) }
    if cfg.alike, let a = alike.shuffled().first(where: { $0 != needed && !out.contains($0) }) {
        out.append(a)
    }
    let pool = Array("abcdefghijklmnopqrstuvwxyz").shuffled().filter { c in
        c != needed && !out.contains(c) && (cfg.alike || (!inWord.contains(c) && !alike.contains(c)))
    }
    for c in pool where out.count < cfg.decoys { out.append(c) }
    return Array(out.prefix(cfg.decoys))
}

#if DEBUG
/// LUDUS_SELFCHECK=1: every deck word is plain lowercase, traps sit at real indices and differ from
/// the right letter, and no wave ever offers the right letter twice.
private func scSelfCheck() {
    var problems: [String] = []
    for (t, deck) in scDecks.enumerated() {
        for wd in deck {
            if wd.text.contains(where: { !("a"..."z").contains($0) }) { problems.append("\(wd.text) chars") }
            if t < 5 && wd.emoji.isEmpty { problems.append("\(wd.text) no picture") }
            for (i, tr) in wd.traps where i >= wd.letters.count || wd.letters[i] == tr { problems.append("\(wd.text) trap \(i)") }
            for n in 1...3 { for easy in [true, false] {
                let cfg = SCConfig(decoys: n, alike: !easy, traps: !easy, ghost: easy)
                for i in wd.letters.indices {
                    let d = scDecoys(word: wd, index: i, cfg: cfg)
                    if d.contains(wd.letters[i]) { problems.append("\(wd.text)[\(i)] decoy = answer") }
                    if d.count != n || Set(d).count != d.count { problems.append("\(wd.text)[\(i)] decoys \(d)") }
                    if easy && d.contains(where: { wd.letters.contains($0) }) { problems.append("\(wd.text) easy decoy in word") }
                    if easy && d.contains(where: { (scAlike[wd.letters[i]] ?? []).contains($0) }) { problems.append("\(wd.text) easy look-alike") }
                }
            } }
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
    var basketW: CGFloat { max(80, size.width * CGFloat(ramp(0.30, 0.20, to: 7))) }
    var tile: CGFloat { CGFloat(ramp(64, 54, from: 2, to: 6)) }
    @Published var ghostAll = true
    private var cfg = SCConfig()

    override func onBegin() {
        letters.removeAll(); sparks.removeAll()
        lastTick = nil; missRun = 0; recent = []; botTarget = nil
        basketX = -1                      // re-centred on the next frame (the play area may have changed shape)
        running = true
        newWord()
    }

    private func newWord() {
        let all = scDecks[tier(scTierStarts)]
        let deck = all.filter { !recent.contains($0.text) }
        word = (deck.isEmpty ? all : deck).randomElement()!
        var flash: Double = 0
        if word.emoji.isEmpty { flash = ramp(3.2, 2.2, from: 7.5, to: 10) }
        else if chance(1, from: 5.5, to: 7) { flash = ramp(3.2, 2.4, from: 5.5, to: 9) }
        cfg = SCConfig(decoys: rampInt(1, 3, from: 1, to: 5.5), alike: chance(1, from: 2.5, to: 4),
                       traps: chance(1, from: 7, to: 8.5), ghost: !chance(1, from: 2, to: 3.2), flash: flash)
        ghostAll = cfg.ghost
        recent = Array((recent + [word.text]).suffix(6))
        filled = 0; ghostNext = false; done = false
        wordID += 1; wordGen += 1

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
        else { basketX = min(max(basketX, basketW / 2), max(basketW / 2, size.width - basketW / 2)) }
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

        var fall = ramp(5.2, 3.0, to: 10)
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
        let chars = ([needed] + scDecoys(word: word, index: filled, cfg: cfg)).shuffled()
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
        let costs = d >= 2.5
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
        for l in letters where l.delay <= 0 || l.bad > 0 { drawLetter(&ctx, l) }
        drawBasket(&ctx)
        for s in sparks {
            ctx.opacity = Double(max(0, s.life))
            ctx.draw(Text(s.glyph).font(.system(size: 22)), at: CGPoint(x: s.x, y: s.y))
        }
        ctx.opacity = 1
    }

    /// The armarium: a row of pigeonholes stuffed with scrolls, on a heavy wooden shelf. Drawn once,
    /// behind the falling letters, and wider than the play area when it sits in the landscape column.
    func drawShelf(_ ctx: inout GraphicsContext, _ size: CGSize) {
        let holeH: CGFloat = 40, top = shelfY - holeH
        ctx.fill(Path(CGRect(x: 0, y: top - 6, width: size.width, height: holeH + 6)), with: .color(Color(hex: 0x4a2e18)))
        let n = max(4, Int(size.width / 66)), hw = size.width / CGFloat(n)
        for k in 0..<n {
            let r = CGRect(x: CGFloat(k) * hw + 4, y: top, width: hw - 8, height: holeH - 2)
            ctx.fill(Path(roundedRect: r, cornerRadius: 3), with: .color(Color(hex: 0x24160b)))
            // scroll ends, stacked
            let ends = 2 + (k * 5) % 3
            for e in 0..<ends {
                let d: CGFloat = 15
                let cx = r.minX + 10 + CGFloat(e) * (d + 2), cy = r.maxY - d / 2 - 2 - CGFloat(e % 2) * 12
                guard cx + d / 2 < r.maxX - 2 else { continue }
                let c = CGRect(x: cx - d / 2, y: cy - d / 2, width: d, height: d)
                ctx.fill(Path(ellipseIn: c), with: .color(Color(hex: [0xf1e0b8, 0xe8cf9a, 0xf6ead0][(k + e) % 3])))
                ctx.fill(Path(ellipseIn: c.insetBy(dx: 5, dy: 5)), with: .color(Color(hex: 0x8a5a2b)))
            }
            // a little red title tag on some
            if k % 3 == 1 {
                ctx.fill(Path(CGRect(x: r.maxX - 12, y: r.minY + 4, width: 6, height: 12)), with: .color(Color(hex: Lu.coral)))
            }
        }
        ctx.fill(Path(roundedRect: CGRect(x: 0, y: shelfY, width: size.width, height: 11), cornerRadius: 3),
                 with: .linearGradient(Gradient(colors: [Color(hex: 0xa8743f), Color(hex: 0x5e3a1c)]),
                                       startPoint: CGPoint(x: 0, y: shelfY), endPoint: CGPoint(x: 0, y: shelfY + 11)))
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

    /// The capsa: a round leather scroll box, open at the top, with two brass-studded straps.
    private func drawBasket(_ ctx: inout GraphicsContext) {
        let w = basketW, h: CGFloat = 50
        let cx = basketX + sin(basketShake * 30) * 10 * basketShake
        let top = basketY - 8
        let body = Path(roundedRect: CGRect(x: cx - w / 2, y: top, width: w, height: h), cornerRadius: 10)
        ctx.fill(body, with: .linearGradient(Gradient(colors: [Color(hex: 0x6e3b1d), Color(hex: 0xb06a35), Color(hex: 0x6e3b1d)]),
                                             startPoint: CGPoint(x: cx - w / 2, y: top), endPoint: CGPoint(x: cx + w / 2, y: top)))
        for f in [0.3, 0.72] as [CGFloat] {
            let y = top + h * f
            ctx.fill(Path(CGRect(x: cx - w / 2, y: y - 4, width: w, height: 8)), with: .color(Color(hex: 0x3f2210)))
            for k in 0..<5 {
                let x = cx - w / 2 + w * (CGFloat(k) + 0.5) / 5
                ctx.fill(Path(ellipseIn: CGRect(x: x - 2.5, y: y - 2.5, width: 5, height: 5)), with: .color(Color(hex: Lu.gold)))
            }
        }
        // the open mouth, with scrolls already caught peeking out
        let mouth = CGRect(x: cx - w / 2, y: top - 9, width: w, height: 18)
        ctx.fill(Path(ellipseIn: mouth), with: .color(Color(hex: basketShake > 0 ? Lu.coral : 0x8f5228)))
        ctx.fill(Path(ellipseIn: mouth.insetBy(dx: 6, dy: 4)), with: .color(Color(hex: 0x2a160a)))
        for k in 0..<min(filled, 6) {
            let x = cx - w / 2 + 16 + CGFloat(k) * (w - 32) / 5
            ctx.fill(Path(roundedRect: CGRect(x: x - 5, y: top - 18, width: 10, height: 16), cornerRadius: 4), with: .color(Color(hex: 0xf1e0b8)))
        }
    }
}

/// The library: warm plastered walls, two columns, an oil lamp's glow, a mosaic floor.
private struct LibraryHall: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0x5a3a22), Color(hex: 0x7a5232), Color(hex: 0x5c3d24)], startPoint: .top, endPoint: .bottom)
                // painted wall panels
                ForEach(0..<3, id: \.self) { k in
                    RoundedRectangle(cornerRadius: 4).stroke(Color(hex: 0xc9925a).opacity(0.25), lineWidth: 3)
                        .frame(width: w * 0.26, height: h * 0.36)
                        .position(x: w * (0.2 + CGFloat(k) * 0.3), y: h * 0.52)
                }
                // columns
                ForEach([0.0, 1.0], id: \.self) { side in
                    LinearGradient(colors: [Color(hex: 0xd9c9a8), Color(hex: 0xf4ead4), Color(hex: 0xb9a888)], startPoint: .leading, endPoint: .trailing)
                        .frame(width: 26).frame(maxHeight: .infinity)
                        .overlay(HStack(spacing: 5) { ForEach(0..<3, id: \.self) { _ in Rectangle().fill(Color.black.opacity(0.08)).frame(width: 2) } })
                        .position(x: side == 0 ? 13 : w - 13, y: h / 2)
                }
                // lamp glow
                Circle().fill(RadialGradient(colors: [Color(hex: 0xffc46b).opacity(0.35), .clear], center: .center, startRadius: 4, endRadius: 180))
                    .frame(width: 360).position(x: w * 0.5, y: h * 0.45)
                // mosaic floor
                Canvas { ctx, size in
                    let floorY = size.height * 0.86
                    ctx.fill(Path(CGRect(x: 0, y: floorY, width: size.width, height: size.height - floorY)), with: .color(Color(hex: 0xd8c39a)))
                    let t: CGFloat = 16
                    var y = floorY
                    var row = 0
                    while y < size.height {
                        var x: CGFloat = 0, col = 0
                        while x < size.width {
                            if (row + col) % 2 == 0 {
                                ctx.fill(Path(CGRect(x: x + 1, y: y + 1, width: t - 2, height: t - 2)), with: .color(Color(hex: row % 4 < 2 ? 0x9a4a2a : 0x2f3a4a).opacity(0.55)))
                            }
                            x += t; col += 1
                        }
                        y += t; row += 1
                    }
                }
            }
        }
    }
}

// MARK: - Views

struct ScrollCatcherView: View {
    let onClose: () -> Void
    @StateObject private var model = ScrollModel()

    var body: some View {
        ArcadeShell(model: model,
                    spec: GameID.scrollCatcher.spec ?? GameSpec(title: "Scroll Catcher", mechanic: "", premise: "", game: .scrollCatcher),
                    accent: Lu.mint, onClose: { LibraryVoice.stop(); onClose() },
                    backdrop: { LibraryHall() }) {
            GeometryReader { g in
                ZStack(alignment: .top) {
                    Canvas { ctx, size in model.drawShelf(&ctx, size) }
                        .ludusBleed()
                        .allowsHitTesting(false)
                    TimelineView(.animation(paused: model.phase != .playing)) { tl in
                        Canvas { ctx, size in
                            model.step(tl.date, size: size)
                            model.render(&ctx, size: size)
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onChanged { model.moveBasket(to: $0.location.x) })

                    ScrollWordPanel(model: model, width: g.size.width - 28)
                        .padding(.top, 60).padding(.horizontal, 14)
                }
            }
        }
        .onDisappear { LibraryVoice.stop() }
    }
}

/// The picture, its word slots (filling as letters are caught) and a 🔊 button.
private struct ScrollWordPanel: View {
    @ObservedObject var model: ScrollModel
    let width: CGFloat
    @State private var pulse = false

    var body: some View {
        let letters = model.word.letters
        let n = letters.count
        let slotW = min(52, (width + 28 - 150) / CGFloat(max(n, 1)) - 4)
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
            .background(Parchment(radius: 10))
            .background(
                // the scroll's wooden rollers
                HStack {
                    Capsule().fill(LinearGradient(colors: [Color(hex: 0x5e3a1c), Color(hex: 0xa8743f), Color(hex: 0x5e3a1c)], startPoint: .leading, endPoint: .trailing)).frame(width: 14)
                    Spacer()
                    Capsule().fill(LinearGradient(colors: [Color(hex: 0x5e3a1c), Color(hex: 0xa8743f), Color(hex: 0x5e3a1c)], startPoint: .leading, endPoint: .trailing)).frame(width: 14)
                }
                .padding(.vertical, -10).padding(.horizontal, -7)
            )
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
                .fill(Color(hex: isFilled ? (model.done ? Lu.mint : Lu.gold) : 0xe2cc9c))
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: isNext ? 0xd2691e : 0xa88a5a), lineWidth: isNext ? 3 : 2)
                .opacity(isNext ? (pulse ? 1 : 0.35) : 1)
            if isFilled {
                Text(String(c)).font(luFont(w * 0.72)).foregroundStyle(Color(hex: Lu.inkDark))
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
            } else if ghost {
                Text(String(c)).font(luFont(w * 0.72)).foregroundStyle(Color(hex: 0x5a3a1a).opacity(0.35))
            }
        }
        .frame(width: w, height: w * 1.2)
        .scaleEffect(isNext ? 1.08 : 1)
    }
}
