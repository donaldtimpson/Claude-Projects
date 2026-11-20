import SwiftUI

// MARK: - Stepping Stones  (Word Wizards · build a sentence, punctuation, figurative language)
//
// Rana the frog wants to cross the river. Hear a sentence; tap its word-stones on the bank IN
// ORDER and each one splashes into the river as the next stepping stone — Rana hops on. Finish
// the sentence (with the right end mark) and she leaps home to her lily pad. A wrong stone sinks
// with a "blub", Rana shakes her head, and the right stone glows and drops into place itself.
// Tapping a stone says its word, so a non-reader can play by ear.
//
// Continuous difficulty (GameKit `d`), content kinds fade in via `tier` and stay as review:
//   tier 0  3-word picture sentences; first stone capitalised, full stop already there (d 1)
//   tier 1  4–6 words, choose the end mark . or ?                                         (2.4)
//   tier 2  lower-case stones (capitals are YOUR job), . ? !, homophone traps there/their   (3.8)
//   tier 3  commas: lists, "First,", "Mom,", "When…, "                                       (5.2)
//   tier 4  apostrophes: it's/its, you're/your, can't, the dog's                             (6.6)
//   tier 5  similes & idioms: "as busy as a bee", "a piece of cake" (meaning shown after)    (8)
// Faint "ghost" words in the river fade out between d 1.6 and 2.6; trap stones 0 → 2 from
// d 3 → 8 (only where the sentence has a real trap); stones get smaller as sentences grow.

private struct WBSentence {
    let words: [String]       // lower-case except names and "I"; last = end mark
    let pic: String
    let traps: [String]
    var alts: [[String]] = []
    var note: String = ""      // shown after a figurative sentence: what it means
}

private func wb(_ s: String, _ pic: String = "", traps: [String] = [], alt: [String] = [], note: String = "") -> WBSentence {
    WBSentence(words: s.split(separator: " ").map(String.init), pic: pic, traps: traps,
               alts: alt.map { $0.split(separator: " ").map(String.init) }, note: note)
}

private let wbTiers: [[WBSentence]] = [
    [wb("the cat naps .", "🐱💤"), wb("the dog digs .", "🐶🕳️"), wb("a bird sings .", "🐦🎵"), wb("the sun shines .", "☀️"),
     wb("fish can swim .", "🐟"), wb("the baby cries .", "👶😭"), wb("I see you .", "👀"), wb("we like cake .", "🍰"),
     wb("frogs eat flies .", "🐸🪰"), wb("pigs love mud .", "🐷"), wb("the bus stops .", "🚌🛑"), wb("bees make honey .", "🐝🍯"),
     wb("mom hugs me .", "🤗")],
    [wb("can you see the moon ?", "🌙"), wb("where is my hat ?", "🎩"), wb("the frog is green .", "🐸"),
     wb("do you like apples ?", "🍎"), wb("we play in the park .", "🛝"), wb("is it time for bed ?", "🛏️"),
     wb("the red ball is mine .", "🔴"), wb("what is your name ?", "📛"), wb("my cat has soft fur .", "🐱"),
     wb("who ate the last cookie ?", "🍪"), wb("the owl sleeps all day .", "🦉"), wb("can a fish climb a tree ?", "🐟🌳")],
    [wb("we went to the beach .", traps: ["two", "too"]), wb("there is a frog in the pond .", traps: ["their"]),
     wb("the dogs wagged their tails .", traps: ["there"]), wb("I ate two big apples .", traps: ["to", "too"]),
     wb("she knew the right answer .", traps: ["new", "write"]), wb("can we eat our lunch now ?", traps: ["hour"]),
     wb("I can hear the sea .", traps: ["here", "see"]), wb("the wind blew the leaves away .", traps: ["blue"], alt: ["the wind blew away the leaves ."]),
     wb("the knight rode a white horse .", traps: ["night", "road"]), wb("did you see the shooting star ?", traps: ["sea"]),
     wb("the bear ate the berries .", traps: ["bare"]), wb("she swam faster than her brother .", traps: ["then"]),
     wb("we ran to the shop .", traps: ["runned", "two"]), wb("where are your shoes ?", traps: ["were", "wear"]),
     wb("watch out for the bee !", traps: ["be"])],
    [wb("we need eggs, milk and bread .", traps: ["eggs"], alt: ["we need eggs, bread and milk ."]), wb("yes, I would like some tea .", traps: ["yes"]),
     wb("after lunch, we went swimming .", traps: ["lunch"]), wb("Mom, can we go to the park ?", traps: ["Mom"]),
     wb("wow, that cake is huge !", traps: ["wow"]), wb("first, wash your hands .", traps: ["first"]),
     wb("Rome, Athens and Paris are cities .", traps: ["Rome"], alt: ["Rome, Paris and Athens are cities ."]), wb("when the bell rang, we ran outside .", traps: ["rung"]),
     wb("oh no, the milk spilled !", traps: ["no"])],
    [wb("it's raining again .", traps: ["its"]), wb("the cat licked its paw .", traps: ["it's"]),
     wb("you're my best friend .", traps: ["your"]), wb("is that your coat ?", traps: ["you're"]),
     wb("the dog's bone is buried .", traps: ["dogs"]), wb("we can't find the key .", traps: ["cant"]),
     wb("they're going to the games .", traps: ["their", "there"]), wb("I don't like rainy days .", traps: ["dont"]),
     wb("who's knocking at the door ?", traps: ["whose"])],
    [wb("she is as busy as a bee .", traps: ["snail"], note: "busy as a bee = working hard"),
     wb("he is as brave as a lion .", traps: ["mouse"], note: "brave as a lion = very brave"),
     wb("the baby slept like a log .", traps: ["drum"], note: "slept like a log = slept very deeply"),
     wb("it is raining cats and dogs .", traps: ["frogs"], note: "raining cats and dogs = raining very hard"),
     wb("her hands were as cold as ice .", traps: ["fire"], note: "cold as ice = very cold"),
     wb("that test was a piece of cake .", traps: ["pie"], note: "a piece of cake = very easy"),
     wb("don't let the cat out of the bag .", traps: ["dog"], note: "let the cat out of the bag = tell a secret"),
     wb("the whole class was all ears .", traps: ["eyes"], note: "all ears = listening closely"),
     wb("time flies when you are having fun .", traps: ["walks"], note: "time flies = time seems to pass quickly"),
     wb("he was as quiet as a mouse .", traps: ["lion"], note: "quiet as a mouse = very quiet"),
     wb("my uncle is a couch potato .", traps: ["carrot"], note: "a couch potato = someone who sits around a lot")],
]
private let wbTierStarts: [Double] = [1, 2.4, 3.8, 5.2, 6.6, 8]
private let wbMarks = [".", "?", "!"]

// MARK: - Model

private struct WBStone: Identifiable, Hashable {
    let id: Int
    let text: String
}

@MainActor
private final class BridgeModel: ArcadeModel {
    @Published var sentence = wbTiers[0][0]
    @Published var tierNow = 0
    @Published var pile: [WBStone] = []
    @Published var placed: [WBStone] = []
    @Published var sinking: WBStone?
    @Published var glow: Int?
    @Published var frogAt = -1               // index of the stone Rana stands on; -1 = start pad
    @Published var home = false              // Rana reached the far bank
    @Published var roundID = 0
    @Published var busy = false
    @Published var lesson: String?
    @Published var ghost = false
    @Published var nod = 0                   // bumps on a wrong stone (Rana shakes her head)
    @Published var markGiven = false         // the end mark is laid already (tier 0)

    private var gen = 0
    private var recent: [String] = []

    init() {
        super.init(key: GameID.wordBridge.rawValue)
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { wbSelfCheck() }
        #endif
    }

    /// One correct stone is one step; ten steps climb a Gradus (about two sentences).
    override func perLevel(_ level: Int) -> Int { 10 }

    /// Every accepted order (the sentence and any alternates).
    var orders: [[String]] { [sentence.words] + sentence.alts }
    /// The slots to fill (the end mark counts unless it was laid for you).
    var slots: Int { sentence.words.count }

    override func onBegin() { recent = []; next() }

    private func next() {
        gen += 1
        let t = tier(wbTierStarts)
        let deck = wbTiers[t].filter { !recent.contains($0.words.joined()) }
        sentence = (deck.isEmpty ? wbTiers[t] : deck).randomElement()!
        recent = Array((recent + [sentence.words.joined()]).suffix(10))
        tierNow = t
        ghost = !chance(1, from: 1.6, to: 2.6)
        markGiven = t == 0
        var stones = sentence.words
        if markGiven { stones.removeLast() }
        let trapN = min(sentence.traps.count, rampInt(0, 2, from: 3, to: 8))
        stones += sentence.traps.shuffled().prefix(trapN)
        if !markGiven {
            let others = wbMarks.filter { $0 != sentence.words.last! }
            stones += t == 1 ? others.filter { $0 != "!" } : others
        }
        var id = 0
        pile = stones.shuffled().map { s in id += 1; return WBStone(id: id, text: s) }
        placed = []
        sinking = nil; glow = nil; frogAt = -1; home = false; lesson = nil; busy = false
        roundID += 1
        say()
    }

    /// The sentence read aloud (with a question lilt the synthesiser takes from the "?").
    func say() {
        let words = sentence.words.dropLast().joined(separator: " ")
        LibraryVoice.say(words + (sentence.words.last == "?" ? "?" : "."), rate: 0.4)
    }

    /// What the stone looks like: names and "I" keep their capitals; at tier 0–1 the first word
    /// is capitalised in the pile as a clue; in the river the first stone always gets its capital.
    func display(_ s: WBStone, placedAt: Int? = nil) -> String {
        if placedAt == 0 || (tierNow <= 1 && placedAt == nil && s.text == sentence.words.first && pileFirstClue(s)) {
            return s.text.prefix(1).uppercased() + s.text.dropFirst()
        }
        return s.text
    }
    private func pileFirstClue(_ s: WBStone) -> Bool {
        // Only one pile stone gets the clue capital, even if the first word repeats ("the … the").
        placed.isEmpty && pile.first { $0.text == sentence.words.first } == s
    }

    /// The stone the river wants next, if `text` would fit (any accepted order).
    private func fits(_ text: String) -> Bool {
        let done = placed.map(\.text)
        return orders.contains { o in o.count > done.count && Array(o.prefix(done.count)) == done && o[done.count] == text }
    }
    private var rightNext: WBStone? {
        let done = placed.map(\.text)
        guard let o = orders.first(where: { $0.count > done.count && Array($0.prefix(done.count)) == done }) else { return nil }
        return pile.first { $0.text == o[done.count] }
    }
    private var filledAll: Bool { placed.count + (markGiven ? 1 : 0) >= sentence.words.count }

    private func later(_ t: Double, _ step: @escaping (BridgeModel) -> Void) {
        let g = gen
        DispatchQueue.main.asyncAfter(deadline: .now() + t) { [weak self] in
            guard let self, self.gen == g, self.phase == .playing else { return }
            step(self)
        }
    }

    func tap(_ s: WBStone) {
        guard phase == .playing, !busy, pile.contains(s) else { return }
        if fits(s.text) {
            lay(s, scoring: true)
        } else {
            busy = true
            pile.removeAll { $0 == s }
            sinking = s
            nod += 1
            Sfx.play(.thud, volume: 0.7)
            lesson = whyNot(s)
            miss(delay: 2.6)
            later(0.9) { m in
                m.sinking = nil
                guard let r = m.rightNext else { return }
                m.glow = r.id
                m.later(0.9) { m in
                    m.glow = nil
                    if m.dying { return }
                    m.lay(r, scoring: false)
                    m.lesson = nil
                }
            }
        }
    }

    private func whyNot(_ s: WBStone) -> String {
        guard let r = rightNext else { return "Not that one" }
        if wbMarks.contains(r.text) && wbMarks.contains(s.text) {
            let kind = r.text == "?" ? "a question — it asks" : (r.text == "!" ? "a strong feeling or warning" : "a telling sentence")
            return "This is \(kind): *\(r.text)*"
        }
        if r.text.lowercased() == s.text.lowercased().replacingOccurrences(of: ",", with: "") || s.text.filter({ $0.isLetter }) == r.text.filter({ $0.isLetter }) {
            return "Look closely: *\(r.text)* not \(s.text)"
        }
        if sentence.traps.contains(s.text) { return "Sounds right, but here it's *\(r.text)*" }
        return "Next comes *\(display(r, placedAt: placed.count))*"
    }

    private func lay(_ s: WBStone, scoring: Bool) {
        busy = true
        pile.removeAll { $0 == s }
        placed.append(s)
        Sfx.play(.thud)
        Haptics.tap(0.5)
        if scoring { hit() }
        later(0.25) { m in
            m.frogAt = m.placed.count - 1
            Sfx.play(.pop, volume: 0.5)
            if m.filledAll { m.later(0.45) { $0.finishSentence() } } else { m.busy = false }
        }
    }

    private func finishSentence() {
        home = true
        Sfx.play(.sparkle)
        say()
        if !sentence.note.isEmpty { lesson = sentence.note }
        // Leftover trap stones sink.
        later(0.5) { m in withAnimation(.easeIn(duration: 0.4)) { m.pile = [] } }
        later(sentence.note.isEmpty ? 1.8 : 3.0) { $0.next() }
    }

    override func botAct(correct: Bool) {
        guard !busy else { return }
        let wrong = pile.filter { !fits($0.text) }
        if correct || wrong.isEmpty { if let r = rightNext { tap(r) } } else { tap(wrong.randomElement()!) }
    }
}

#if DEBUG
private func wbSelfCheck() {
    var problems: [String] = []
    for (t, deck) in wbTiers.enumerated() { for s in deck {
        let line = s.words.joined(separator: " ")
        if !wbMarks.contains(s.words.last!) { problems.append("no end mark: \(line)") }
        for tr in s.traps where s.words.contains(tr) { problems.append("trap \(tr) is in \(line)") }
        if t == 0 && s.words.count != 4 { problems.append("tier 0 length: \(line)") }
        if t >= 1 && s.pic.isEmpty && t <= 1 { problems.append("tier 1 picture: \(line)") }
        if t >= 2 && s.traps.isEmpty { problems.append("no trap: \(line)") }
        if t == 5 && s.note.isEmpty { problems.append("no meaning: \(line)") }
    } }
    print("BRIDGE SELFCHECK: \(problems.isEmpty ? "OK" : problems.joined(separator: " | "))")
}
#endif

// MARK: - Views

struct WordBridgeView: View {
    let onClose: () -> Void
    @StateObject private var model = BridgeModel()

    var body: some View {
        ArcadeShell(model: model,
                    spec: GameID.wordBridge.spec ?? GameSpec(title: "Stepping Stones", mechanic: "", premise: "", game: .wordBridge),
                    accent: 0x7fd6c2, onClose: { LibraryVoice.stop(); onClose() },
                    backdrop: { RiverScene() }) {
            BridgePlay(model: model)
        }
        .onDisappear { LibraryVoice.stop() }
    }
}

/// Behind everything (full screen): sky above, sandy bank below. The river itself is drawn in
/// the play area's own coordinates (`RiverBand`) so the stones always sit on the water.
private struct RiverScene: View {
    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [Color(hex: 0x8fd0f0), Color(hex: 0xd6eef5)], startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [Color(hex: 0xc9a46a), Color(hex: 0x9c7a48)], startPoint: .top, endPoint: .bottom)
        }
    }
}

/// Far bank with reeds and hills, the flowing river, the near bank's grassy lip and pebbles.
private struct RiverBand: View {
    let size: CGSize
    let top: CGFloat, bottom: CGFloat     // the river's edges
    var body: some View {
        let w = size.width
        ZStack(alignment: .topLeading) {
            // distant hills + far bank
            Ellipse().fill(Color(hex: 0x9fcf86)).frame(width: w * 0.9, height: 120).position(x: w * 0.2, y: top - 30)
            Ellipse().fill(Color(hex: 0x8cc47a)).frame(width: w * 0.8, height: 100).position(x: w * 0.85, y: top - 22)
            Rectangle().fill(LinearGradient(colors: [Color(hex: 0x7fbf5a), Color(hex: 0x5a9c3f)], startPoint: .top, endPoint: .bottom))
                .frame(width: w, height: 64).position(x: w / 2, y: top - 26)
            // the river
            Rectangle().fill(LinearGradient(colors: [Color(hex: 0x46a6cf), Color(hex: 0x2a7fb0), Color(hex: 0x2b6f9f)], startPoint: .top, endPoint: .bottom))
                .frame(width: w, height: bottom - top).position(x: w / 2, y: (top + bottom) / 2)
            TimelineView(.animation(minimumInterval: 1 / 20)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                Canvas { ctx, _ in
                    for i in 0..<24 {
                        let y = top + 12 + libHash(i, 7) * (bottom - top - 24)
                        let x = (libHash(i, 8) * (w + 120) + CGFloat(t * 18 * (0.6 + Double(libHash(i, 9))))).truncatingRemainder(dividingBy: w + 120) - 60
                        var p = Path()
                        p.move(to: CGPoint(x: x, y: y)); p.addQuadCurve(to: CGPoint(x: x + 34, y: y), control: CGPoint(x: x + 17, y: y - 5))
                        ctx.stroke(p, with: .color(.white.opacity(0.28)), lineWidth: 2)
                    }
                }
            }
            .frame(width: w, height: size.height)
            // banks' edges
            Capsule().fill(Color(hex: 0x4f8a35)).frame(width: w + 20, height: 10).position(x: w / 2, y: top)
            Capsule().fill(Color(hex: 0x6aa84a)).frame(width: w + 20, height: 14).position(x: w / 2, y: bottom)
            // reeds on the far bank
            ForEach(0..<6, id: \.self) { k in
                let x = w * (0.04 + CGFloat(k) * 0.13)
                Capsule().fill(Color(hex: 0x3f7a2f)).frame(width: 5, height: 36)
                    .rotationEffect(.degrees(Double(k % 3) * 6 - 6)).position(x: x, y: top - 14)
                Capsule().fill(Color(hex: 0x7a4a24)).frame(width: 8, height: 16).position(x: x + 1, y: top - 32)
            }
            // pebbles and flowers on the near bank
            ForEach(0..<10, id: \.self) { k in
                let x = libHash(k, 21) * w, y = bottom + 30 + libHash(k, 22) * (size.height - bottom - 40)
                if k % 3 == 0 {
                    Text(["🌼", "🌸", "🌿"][k % 3 == 0 ? (k / 3) % 3 : 0]).font(.system(size: 16)).position(x: x, y: y)
                } else {
                    Ellipse().fill(Color(hex: 0x8a6a40).opacity(0.6)).frame(width: 10 + libHash(k, 23) * 10, height: 7).position(x: x, y: y)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}

private struct BridgePlay: View {
    @ObservedObject var model: BridgeModel
    @Environment(\.ludusColumnBleed) private var bleed
    @State private var shakes: CGFloat = 0
    @State private var hop = false

    var body: some View {
        GeometryReader { g in
            let size = g.size
            let slots = slotCenters(in: size)
            let start = CGPoint(x: 34, y: (slots.first?.y ?? size.height * 0.35))
            let homeP = CGPoint(x: size.width - 58, y: riverTop(size) - 30)
            ZStack {
                // The river runs on past the column's edges when sideways.
                RiverBand(size: CGSize(width: size.width + bleed * 2, height: size.height), top: riverTop(size), bottom: riverBottom(size))
                    .frame(width: size.width, height: size.height)
                // home lily pad on the far bank
                LilyPad(size: 70).position(homeP)
                LilyPad(size: 56).position(start)
                ForEach(0..<model.slots, id: \.self) { i in slot(i, at: slots[i]) }
                // sinking stone
                if let s = model.sinking, let p = slots[safe: model.placed.count] {
                    StoneView(text: s.text, small: small, sunk: true)
                        .position(p)
                        .transition(.asymmetric(insertion: .scale(scale: 1.4).combined(with: .opacity), removal: .offset(y: 30).combined(with: .opacity)))
                }
                frog(slots: slots, start: start, home: homeP)
                pileView(size: size)
                banner.frame(maxHeight: .infinity, alignment: .top).padding(.top, 58).padding(.horizontal, 14)
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.7), value: model.placed)
            .animation(.easeInOut(duration: 0.3), value: model.sinking)
        }
        .onChange(of: model.nod) { _ in withAnimation(.linear(duration: 0.5)) { shakes += 1 } }
        .onChange(of: model.frogAt) { _ in
            withAnimation(.easeOut(duration: 0.14)) { hop = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { withAnimation(.easeIn(duration: 0.16)) { hop = false } }
        }
        .onChange(of: model.home) { h in
            if h {
                withAnimation(.easeOut(duration: 0.18)) { hop = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { withAnimation(.easeIn(duration: 0.2)) { hop = false } }
            }
        }
    }

    private var small: Bool { model.sentence.words.count > 6 }
    private func riverTop(_ s: CGSize) -> CGFloat { max(210, s.height * 0.3) }
    private func riverBottom(_ s: CGSize) -> CGFloat { s.height * 0.68 }
    private func stoneW(_ s: String) -> CGFloat { CGFloat(max(s.count, 1)) * (small ? 10.5 : 12) + (small ? 22 : 28) }

    /// Slots flow like text across the river, centred row by row.
    private func slotCenters(in size: CGSize) -> [CGPoint] {
        let words = model.sentence.words
        let maxW = size.width - 74
        var rows: [[Int]] = [[]], widths: [CGFloat] = [0]
        for i in words.indices {
            let w = stoneW(words[i]) + 8
            if widths[widths.count - 1] + w > maxW && !rows[rows.count - 1].isEmpty { rows.append([]); widths.append(0) }
            rows[rows.count - 1].append(i); widths[widths.count - 1] += w
        }
        let mid = (riverTop(size) + riverBottom(size)) / 2
        let gap = min(78, (riverBottom(size) - riverTop(size) - 60) / CGFloat(max(1, rows.count - 1)))
        var out = [CGPoint](repeating: .zero, count: words.count)
        for (r, row) in rows.enumerated() {
            let y = mid + (CGFloat(r) - CGFloat(rows.count - 1) / 2) * gap
            var x = 66 + (maxW - widths[r]) / 2
            for i in row { let w = stoneW(words[i]) + 8; out[i] = CGPoint(x: x + w / 2, y: y); x += w }
        }
        return out
    }

    @ViewBuilder private func slot(_ i: Int, at p: CGPoint) -> some View {
        let word = model.sentence.words[i]
        let isMark = i == model.sentence.words.count - 1
        if i < model.placed.count {
            StoneView(text: model.display(model.placed[i], placedAt: i), small: small)
                .position(p)
                .transition(.scale(scale: 1.5).combined(with: .opacity))
        } else if isMark && model.markGiven {
            StoneView(text: word, small: small).position(p)
        } else {
            // An empty ripple where the next stone goes (a faint ghost word while it's easy).
            let next = i == model.placed.count
            Text(model.ghost ? (i == 0 ? word.prefix(1).uppercased() + word.dropFirst() : word) : " ")
                .font(luFont(small ? 17 : 20, .heavy)).foregroundStyle(.white.opacity(0.45))
                .frame(width: stoneW(word), height: small ? 40 : 46)
                .background(Ellipse().stroke(Color.white.opacity(next ? 0.75 : 0.3), style: StrokeStyle(lineWidth: next ? 3 : 2, dash: [6, 6])))
                .position(p)
        }
    }

    private func frog(slots: [CGPoint], start: CGPoint, home: CGPoint) -> some View {
        let p: CGPoint = {
            if model.home { return home }
            if model.frogAt >= 0, slots.indices.contains(model.frogAt) { return slots[model.frogAt] }
            return start
        }()
        return FrogView(happy: model.home, sad: model.lesson != nil && !model.home)
            .modifier(LibraryShake(amount: 7, shakes: shakes))
            .scaleEffect(0.82)
            .offset(y: hop ? -54 : -42)      // perched on the stone's top edge, so its word stays readable
            .position(p)
            .animation(.spring(response: 0.42, dampingFraction: 0.72), value: model.frogAt)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: model.home)
    }

    private func pileView(size: CGSize) -> some View {
        VStack {
            Spacer()
            FlowRows(spacing: 10, items: model.pile) { s in
                Button {
                    LibraryVoice.say(s.text == "?" ? "question mark" : (s.text == "!" ? "exclamation mark" : (s.text == "." ? "full stop" : s.text.replacingOccurrences(of: ",", with: ""))))
                    model.tap(s)
                } label: {
                    StoneView(text: model.display(s), small: small, glow: model.glow == s.id)
                        .frame(minHeight: 48)
                }
                .buttonStyle(.plain)
                .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
            .frame(width: size.width - 24)
            .frame(height: size.height * 0.27, alignment: .center)
            .padding(.bottom, 10)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: model.pile)
    }

    private var banner: some View {
        HStack(spacing: 12) {
            if !model.sentence.pic.isEmpty {
                Text(model.sentence.pic).font(.system(size: 40)).lineLimit(1).minimumScaleFactor(0.5).frame(width: 74)
            }
            ZStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.home ? "HOP HOME!" : "BUILD WHAT YOU HEAR").font(luFont(11, .heavy)).tracking(1.4)
                        .foregroundStyle(Color(hex: 0x6a4a22))
                    Text(model.home ? fullSentence : "Tap the stones in order")
                        .font(luFont(model.home ? 18 : 16, .heavy)).foregroundStyle(Color(hex: 0x2a1d10))
                        .lineLimit(2).minimumScaleFactor(0.6)
                }
                .opacity(model.lesson == nil ? 1 : 0)
                if let l = model.lesson {
                    libMarked(l, base: 0x2a1d10, mark: 0xb0371c).font(luFont(17, .heavy))
                        .lineLimit(2).minimumScaleFactor(0.6)
                }
            }
            Spacer(minLength: 0)
            LibrarySpeakerButton(size: 46) { model.say() }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(minHeight: 72)
        .background(Parchment(radius: 18))
        .animation(.easeOut(duration: 0.2), value: model.lesson)
    }

    private var fullSentence: String {
        let w = model.sentence.words
        guard let first = w.first else { return "" }
        let body = ([first.prefix(1).uppercased() + first.dropFirst()] + w.dropFirst().dropLast()).joined(separator: " ")
        return body + (w.last ?? "")
    }
}

/// A river stone with a word chiselled into it.
private struct StoneView: View {
    let text: String
    var small = false
    var glow = false
    var sunk = false

    var body: some View {
        Text(text)
            .font(luFont(small ? 17 : 20, .heavy))
            .foregroundStyle(Color(hex: 0x2b2620))
            .lineLimit(1).fixedSize()
            .padding(.horizontal, small ? 11 : 14)
            .frame(minWidth: 40, minHeight: small ? 40 : 46)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: 0x6f6a60)).offset(y: 4)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: 0xe9e2d2), Color(hex: 0xb9b09c)], startPoint: .top, endPoint: .bottom))
                    Circle().fill(Color.white.opacity(0.25)).frame(width: 10).offset(x: -12, y: -10)
                }
            )
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: glow ? 0xffd23f : 0x6f6a60), lineWidth: glow ? 4 : 1.5))
            .shadow(color: glow ? Color(hex: 0xffd23f).opacity(0.9) : .black.opacity(0.25), radius: glow ? 12 : 3, y: 2)
            .scaleEffect(glow ? 1.1 : 1)
            .opacity(sunk ? 0.55 : 1)
            .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: glow)
    }
}

private struct LilyPad: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Color(hex: 0x6cbf4f), Color(hex: 0x3f8a33)], startPoint: .top, endPoint: .bottom))
                .mask(Circle().overlay(Rectangle().frame(width: size * 0.5, height: size * 0.12).rotationEffect(.degrees(-30))
                    .offset(x: size * 0.22, y: -size * 0.12).blendMode(.destinationOut)).compositingGroup())
            Circle().fill(Color(hex: 0xf3a6c8)).frame(width: size * 0.18).offset(x: -size * 0.2, y: size * 0.12)
        }
        .frame(width: size, height: size * 0.62)
        .scaleEffect(x: 1, y: 0.62 / 0.62)
    }
}

/// Rana the frog: round body, big eye bumps, a wide smile.
private struct FrogView: View {
    let happy: Bool
    let sad: Bool
    var body: some View {
        ZStack {
            // back legs
            Ellipse().fill(Color(hex: 0x3f9a3a)).frame(width: 24, height: 16).offset(x: -24, y: 14)
            Ellipse().fill(Color(hex: 0x3f9a3a)).frame(width: 24, height: 16).offset(x: 24, y: 14)
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0x7ed957), Color(hex: 0x3f9a3a)], startPoint: .top, endPoint: .bottom))
                .frame(width: 58, height: 44)
            Ellipse().fill(Color(hex: 0xd9f5b0)).frame(width: 34, height: 20).offset(y: 10)
            ForEach([-1.0, 1.0], id: \.self) { s in
                ZStack {
                    Circle().fill(Color(hex: 0x6cc94a)).frame(width: 24)
                    Circle().fill(.white).frame(width: 17)
                    if happy { Text("^").font(.system(size: 14, weight: .black)).foregroundStyle(.black).offset(y: 2) }
                    else { Circle().fill(.black).frame(width: 8).offset(y: sad ? 3 : 0) }
                }
                .offset(x: s * 14, y: -20)
            }
            // mouth
            Path { p in
                p.move(to: CGPoint(x: -12, y: 0))
                p.addQuadCurve(to: CGPoint(x: 12, y: 0), control: CGPoint(x: 0, y: sad ? -6 : 8))
            }
            .stroke(Color(hex: 0x1f4f1a), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .frame(width: 0, height: 0).offset(y: 0)
            Circle().fill(Color(hex: 0xf28b82).opacity(0.6)).frame(width: 8).offset(x: -18, y: -2)
            Circle().fill(Color(hex: 0xf28b82).opacity(0.6)).frame(width: 8).offset(x: 18, y: -2)
        }
        .frame(width: 70, height: 64)
        .shadow(color: .black.opacity(0.25), radius: 3, y: 3)
    }
}

/// Wraps its items into centred rows.
private struct FlowRows<Item: Identifiable & Hashable, V: View>: View {
    let spacing: CGFloat
    let items: [Item]
    let content: (Item) -> V
    var body: some View {
        FlowLayout(spacing: spacing) { ForEach(items) { content($0) } }
    }
}

@available(iOS 16.0, *)
private struct FlowLayout: Layout {
    let spacing: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(proposal.width ?? 360, subviews)
        let h = rows.map(\.h).reduce(0, +) + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? 360, height: h)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(bounds.width, subviews)
        var y = bounds.minY
        for r in rows {
            var x = bounds.minX + (bounds.width - r.w) / 2
            for i in r.idx {
                let s = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: y + (r.h - s.height) / 2), proposal: .unspecified)
                x += s.width + spacing
            }
            y += r.h + spacing
        }
    }
    private func arrange(_ width: CGFloat, _ subviews: Subviews) -> [(idx: [Int], w: CGFloat, h: CGFloat)] {
        var rows: [(idx: [Int], w: CGFloat, h: CGFloat)] = [([], 0, 0)]
        for i in subviews.indices {
            let s = subviews[i].sizeThatFits(.unspecified)
            let add = (rows[rows.count - 1].idx.isEmpty ? 0 : spacing) + s.width
            if rows[rows.count - 1].w + add > width && !rows[rows.count - 1].idx.isEmpty { rows.append(([], 0, 0)) }
            let extra = (rows[rows.count - 1].idx.isEmpty ? 0 : spacing) + s.width
            rows[rows.count - 1].idx.append(i); rows[rows.count - 1].w += extra
            rows[rows.count - 1].h = max(rows[rows.count - 1].h, s.height)
        }
        return rows
    }
}

private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
