import SwiftUI

// MARK: - Minerva's Owl  (Word Wizards · aim & swoop, parts of speech in a real sentence)
//
// Night over Minerva's temple. A sentence flutters past as a line of moths, one word on each.
// The owl on the olive branch is told which KIND of word to catch ("the DOING word"). Pull the
// owl back like a slingshot, aim the dotted line at the right moth and let go — she swoops and
// snatches it. A wrong moth makes her spit it out, hoot why ("*runs* is a VERB — a doing word"),
// and then swoop for the right one herself, so every miss shows the answer. Tapping a moth says
// its word; while the game is easy (d < 2.5) a tap also sends the owl, for small hands.
//
// Continuous difficulty (GameKit `d`):
//   parts fade in   noun & verb (d 1) → adjective (2.3) → adverb (3.5) → pronoun & preposition
//                   (4.6) → conjunction & interjection (5.8) → subject & object (7.2); old parts
//                   stay as review
//   sentence length 3 words at d 1 → up to 10 by d 8
//   "catch ALL"     chance of having to catch every one of several targets ramps in from d 3
//   moths drift     bob 3 → 14 pt, sideways drift 0 → 24 pt from d 3.5 → 9 (aim + timing)
//   aim preview     the moth the line would hit glows until d 4; then only the dotted line
//   dawn bar        none until d 5, then 18 s → 8 s by d 10

private struct OPart {
    let tag: Character
    let name: String         // "NOUN"
    let kid: String          // "naming word"
    let hint: String         // "a person, place or thing"
    let icon: String
}

private let oParts: [Character: OPart] = [
    "n": OPart(tag: "n", name: "NOUN", kid: "naming word", hint: "a person, place or thing", icon: "🧸"),
    "v": OPart(tag: "v", name: "VERB", kid: "doing word", hint: "an action, or a being word like is", icon: "🏃"),
    "a": OPart(tag: "a", name: "ADJECTIVE", kid: "describing word", hint: "tells what kind or how many", icon: "🌈"),
    "r": OPart(tag: "r", name: "ADVERB", kid: "how-word", hint: "tells how, when or where", icon: "⏱️"),
    "p": OPart(tag: "p", name: "PRONOUN", kid: "stand-in word", hint: "takes a noun's place: he, she, it, we", icon: "👉"),
    "e": OPart(tag: "e", name: "PREPOSITION", kid: "where-word", hint: "shows where or when: in, on, under", icon: "📦"),
    "c": OPart(tag: "c", name: "CONJUNCTION", kid: "joining word", hint: "joins words or ideas: and, but, or", icon: "🔗"),
    "i": OPart(tag: "i", name: "INTERJECTION", kid: "feeling word", hint: "a burst of feeling: Wow! Ouch!", icon: "❗"),
    "s": OPart(tag: "s", name: "SUBJECT", kid: "who-or-what word", hint: "who or what the sentence is about", icon: "🎯"),
    "o": OPart(tag: "o", name: "OBJECT", kid: "receiving word", hint: "who or what gets the action", icon: "🎁"),
]

/// Parts in the order they fade in (each entry: the tags of that tier).
private let oTiers: [[Character]] = [["n", "v"], ["a"], ["r"], ["p", "e"], ["c", "i"], ["s", "o"]]
private let oTierStarts: [Double] = [1, 2.3, 3.5, 4.6, 5.8, 7.2]

private struct OToken: Hashable {
    let text: String
    let tags: Set<Character>
    var bare: String { text.filter { $0.isLetter || $0 == "'" } }
}

/// "The|d dog|ns runs.|v" — each word with its tags (d = article: never a target).
private func oParse(_ s: String) -> [OToken] {
    s.split(separator: " ").map { part in
        let bits = part.split(separator: "|", maxSplits: 1)
        return OToken(text: String(bits[0]), tags: Set(bits.count > 1 ? Array(bits[1]) : []))
    }
}

// Every word is tagged; there are no possessive determiners (my, his…) so pronoun rounds have
// one honest answer set. n noun · v verb · a adjective · r adverb · p pronoun · e preposition ·
// c conjunction · i interjection · s simple subject · o direct object · d article.
private let oSentences: [[OToken]] = [
    "The|d dog|ns runs.|v", "The|d cat|ns naps.|v", "Birds|ns sing.|v", "Fish|ns swim.|v",
    "The|d baby|ns cries.|v", "A|d frog|ns jumps.|v", "The|d sun|ns shines.|v", "Ducks|ns quack.|v",
    "The|d bell|ns rings.|v", "Bees|ns buzz.|v", "Lions|ns roar.|v", "Mom|ns bakes|v bread.|no",
    "Sam|ns reads|v books.|no", "Dogs|ns dig|v holes.|no", "Cows|ns eat|v grass.|no", "Tom|ns kicks|v the|d ball.|no",
    // adjectives
    "The|d big|a dog|ns barks.|v", "A|d red|a kite|ns flies.|v", "The|d tiny|a ant|ns works.|v",
    "Sam|ns has|v a|d green|a hat.|no", "The|d soup|ns is|v hot.|a", "Three|a ducks|ns swim.|v",
    "The|d fluffy|a cat|ns purrs.|v", "Tall|a trees|ns sway.|v", "The|d hungry|a bear|ns ate|v honey.|no",
    "Kim|ns found|v a|d shiny|a shell.|no",
    // adverbs
    "The|d snail|ns moves|v slowly.|r", "Dogs|ns bark|v loudly.|r", "We|ps ate|v lunch|no early.|r",
    "The|d baby|ns sleeps|v quietly.|r", "She|ps sings|v sweetly.|r", "The|d rabbit|ns hopped|v away.|r",
    "Tom|ns always|r eats|v carrots.|no", "The|d fox|ns ran|v very|r fast.|r", "The|d old|a dog|ns slept|v peacefully.|r",
    "Yesterday|r we|ps visited|v Grandma.|no", "The|d team|ns played|v well.|r",
    // pronouns & prepositions
    "She|ps hid|v under|e the|d bed.|n", "He|ps sat|v on|e the|d bench.|n", "They|ps swam|v in|e the|d lake.|n",
    "The|d cat|ns slept|v under|e a|d warm|a blanket.|n", "It|ps rolled|v down|e the|d hill.|n",
    "We|ps walked|v to|e school|n together.|r", "I|ps put|v the|d book|no on|e the|d shelf.|n",
    "The|d bird|ns flew|v over|e the|d wall.|n", "After|e lunch,|n we|ps played|v outside.|r",
    "Mia|ns helped|v him.|po", "Dad|ns called|v us|po for|e dinner.|n", "The|d puppy|ns followed|v them|po home.|r",
    "The|d keys|ns are|v behind|e the|d door.|n",
    // conjunctions & interjections
    "Cats|ns and|c dogs|ns play.|v", "I|ps wanted|v cake,|no but|c we|ps had|v pie.|no",
    "Wow,|i the|d cake|ns is|v huge!|a", "Oops!|i The|d milk|ns spilled.|v", "Hooray!|i We|ps won!|v",
    "Ouch!|i That|ps hurt.|v", "Do|v you|ps want|v tea|no or|c juice?|no",
    "We|ps stayed|v inside|r because|c it|ps rained.|v", "Sam|ns ran,|v but|c he|ps missed|v the|d bus.|no",
    "Hey,|i wait|v for|e me!|p", "The|d sky|ns was|v gray|a and|c cold.|a", "Lena|ns sang|v and|c danced.|v",
    // longer sentences: subjects, objects, words that change jobs
    "The|d tall|a girl|ns kicked|v the|d red|a ball.|no",
    "A|d clever|a crow|ns dropped|v pebbles|no into|e the|d jar.|n",
    "The|d brave|a knight|ns rescued|v the|d frightened|a dragon.|no",
    "The|d old|a sailor|ns told|v stories|no about|e the|d sea.|n",
    "Marcus|ns carefully|r carried|v the|d heavy|a scroll|no to|e the|d library.|n",
    "Under|e the|d bridge,|n a|d grumpy|a troll|ns counted|v coins.|no",
    "The|d children|ns quickly|r cleaned|v the|d messy|a classroom.|no",
    "After|e the|d storm,|n the|d farmers|ns repaired|v the|d broken|a fence.|no",
    "Julia|ns wrote|v a|d long|a letter|no to|e Cicero.|n",
    "The|d curious|a students|ns asked|v many|a questions.|no",
    "Suddenly,|r the|d little|a mouse|ns squeaked|v loudly.|r",
    "Wow!|i The|d ancient|a temple|ns has|v forty|a columns.|no",
    "We|ps fish|v in|e the|d river.|n", "The|d fish|ns swam|v away.|r",
    "Light|v the|d candle.|no", "The|d light|ns is|v bright.|a",
    "Paint|v the|d fence|no white.|a", "The|d paint|ns is|v wet.|a",
    "She|ps runs|v fast.|r", "The|d fast|a car|ns zoomed|v past.|r",
    "We|ps worked|v hard.|r", "The|d hard|a rock|ns cracked.|v",
    "The|d hungry|a owl|ns quietly|r watched|v the|d field|no below.|r",
    "Before|e sunrise,|n the|d busy|a baker|ns sold|v warm|a bread|no and|c sweet|a figs.|no",
].map(oParse)

// MARK: - Model

@MainActor
private final class OwlModel: ArcadeModel {
    @Published var tokens: [OToken] = []
    @Published var target: Character = "n"
    @Published var need = 1
    @Published var caught: Set<Int> = []
    @Published var roundID = 0
    @Published var owlAt: CGPoint?          // nil = on the branch
    @Published var carrying: Int?
    @Published var spat: Int?
    @Published var glow: Int?
    @Published var lesson: String?
    @Published var busy = false
    @Published var deadline: Date?
    @Published var roundPatience: Double = 0
    @Published var hoot = 0                 // bumps when the owl is confused

    /// Moth centres in the play area, written by the view whenever it lays the sentence out.
    var centers: [CGPoint] = []
    var perch: CGPoint = .zero
    /// Called on every drawn frame with where the moths are now (not published: no redraw loop).
    func track(_ live: [CGPoint], perch: CGPoint) { if live.count == tokens.count { centers = live }; self.perch = perch }
    private var gen = 0
    private var recent: [Int] = []

    init() {
        super.init(key: GameID.minervaOwl.rawValue)
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { oSelfCheck() }
        #endif
    }

    override func perLevel(_ level: Int) -> Int { 6 }

    var part: OPart { oParts[target]! }
    var tapFlies: Bool { d < 2.5 }
    var showAimTarget: Bool { d < 4 }
    var bob: CGFloat { CGFloat(ramp(3, 14, to: 9)) }
    var drift: CGFloat { CGFloat(ramp(0, 24, from: 3.5, to: 9)) }
    var targets: [Int] { tokens.indices.filter { tokens[$0].tags.contains(target) } }
    var done: Bool { caught.intersection(targets).count >= need }

    override func onBegin() { recent = []; next() }

    private func next() {
        gen += 1
        let tags = oTiers[tier(oTierStarts)]
        let want = tags.randomElement()!
        let maxLen = rampInt(3, 10, from: 1, to: 8)
        // Sentences with this part, not too long, preferring ones near the length cap so they grow.
        var pool = oSentences.indices.filter { i in
            oSentences[i].contains { $0.tags.contains(want) } && oSentences[i].count <= maxLen && !recent.contains(i)
        }
        if pool.isEmpty { pool = oSentences.indices.filter { i in oSentences[i].contains { $0.tags.contains(want) } } }
        let long = pool.filter { oSentences[$0].count >= maxLen - 3 }
        let pick = (long.isEmpty || Double.random(in: 0..<1) < 0.3 ? pool : long).randomElement()!
        recent = Array((recent + [pick]).suffix(8))
        tokens = oSentences[pick]
        target = want
        let count = tokens.filter { $0.tags.contains(want) }.count
        need = count > 1 && chance(0.7, from: 3, to: 7) ? count : 1
        caught = []; carrying = nil; spat = nil; glow = nil; lesson = nil; owlAt = nil; busy = false
        roundID += 1
        let p = d < 5 ? 0 : ramp(18, 8, from: 5, to: 10)
        roundPatience = p
        deadline = p > 0 ? Date().addingTimeInterval(p) : nil
        if p > 0 {
            let g = gen
            DispatchQueue.main.asyncAfter(deadline: .now() + p) { [weak self] in
                guard let self, self.gen == g, self.phase == .playing, !self.busy, !self.done else { return }
                self.timedOut()
            }
        }
        sayCue()
    }

    var cueText: String {
        let what = need > 1 ? "all the \(part.kid)s" : "the \(part.kid)"
        let name = need > 1 ? part.name.lowercased() + "s" : part.name.lowercased()
        return "Catch \(what)! The \(name)."
    }

    func sayCue() {
        let sentence = tokens.map(\.text).joined(separator: " ")
        LibraryVoice.say("Catch \(need > 1 ? "every" : "the") \(part.name.lowercased()). \(sentence)")
    }

    private func later(_ t: Double, _ step: @escaping (OwlModel) -> Void) {
        let g = gen
        DispatchQueue.main.asyncAfter(deadline: .now() + t) { [weak self] in
            guard let self, self.gen == g, self.phase == .playing else { return }
            step(self)
        }
    }

    /// The owl flies to `point`; if `moth` is set she snatches it there.
    func launch(moth: Int?, toward point: CGPoint) {
        guard phase == .playing, !busy else { return }
        busy = true
        spat = nil
        Sfx.play(.whoosh)
        Haptics.tap(0.4)
        owlAt = point
        later(0.42) { m in
            if let i = moth { m.snatch(i) } else { m.owlAt = nil; m.later(0.45) { $0.busy = false } }
        }
    }

    private func snatch(_ i: Int) {
        if tokens[i].tags.contains(target) && !caught.contains(i) {
            carrying = i
            caught.insert(i)
            Sfx.play(.pop)
            hit()
            owlAt = nil
            later(0.5) { m in
                m.carrying = nil
                Sfx.play(.chomp, volume: 0.6)
                if m.done { m.deadline = nil; m.later(0.6) { $0.next() } } else { m.busy = false }
            }
        } else {
            spat = i
            hoot += 1
            deadline = nil
            let t = tokens[i]
            lesson = whyNot(t)
            miss(delay: 2.8)
            LibraryVoice.say("Hoo? " + lesson!.replacingOccurrences(of: "*", with: ""), rate: 0.46)
            owlAt = nil
            later(0.9) { $0.reveal() }
        }
    }

    private func whyNot(_ t: OToken) -> String {
        let real = oParts.values.filter { $0.tag != "s" && $0.tag != "o" }.first { t.tags.contains($0.tag) }
        if t.tags.contains("d") { return "*\(t.bare)* is an article — find the \(part.kid)" }
        if target == "s" || target == "o" {
            return "*\(t.bare)* isn't the \(part.name.lowercased()) — that's who or what \(target == "s" ? "the sentence is about" : "gets the action")"
        }
        if let real { return "*\(t.bare)* is \(real.name.first.map { "AEIOU".contains($0) } == true ? "an" : "a") \(real.name) — \(real.hint)" }
        return "*\(t.bare)* isn't the \(part.name.lowercased())"
    }

    private func timedOut() {
        deadline = nil
        busy = true
        lesson = "Dawn! The \(part.name.lowercased()) flew off"
        miss(reason: "The sun came up!", delay: 2.6)
        later(0.4) { $0.reveal() }
    }

    /// Show the right moth, then swoop for it (no points).
    private func reveal() {
        guard let right = targets.first(where: { !caught.contains($0) }) else { next(); return }
        busy = true
        glow = right
        later(1.1) { m in
            guard m.centers.indices.contains(right) else { m.next(); return }
            Sfx.play(.whoosh)
            m.owlAt = m.centers[right]
            m.later(0.42) { m in
                m.carrying = right
                m.caught.insert(right)
                m.owlAt = nil
                m.later(0.6) { m in
                    m.carrying = nil; m.glow = nil
                    if m.dying { return }
                    m.lesson = nil
                    if m.done { m.next() } else { m.busy = false }
                }
            }
        }
    }

    override func botAct(correct: Bool) {
        guard !busy, centers.count == tokens.count else { return }
        let open = targets.filter { !caught.contains($0) }
        let wrong = tokens.indices.filter { !tokens[$0].tags.contains(target) }
        guard let i = (correct || wrong.isEmpty ? open.randomElement() : wrong.randomElement()) else { return }
        launch(moth: i, toward: centers[i])
    }
}

#if DEBUG
private func oSelfCheck() {
    var problems: [String] = []
    for s in oSentences {
        let line = s.map(\.text).joined(separator: " ")
        for t in s where t.tags.isEmpty { problems.append("untagged \(t.text) in \(line)") }
        for t in s where t.tags.contains("s") && !t.tags.contains("n") && !t.tags.contains("p") { problems.append("subject \(t.text)") }
        for t in s where ["the", "a", "an"].contains(t.bare.lowercased()) && t.tags != ["d"] { problems.append("article \(t.text)") }
        for t in s where ["my", "his", "her", "your", "their", "our", "its"].contains(t.bare.lowercased()) { problems.append("possessive \(t.text)") }
    }
    for tier in oTiers { for tag in tier where !oSentences.contains(where: { $0.contains { $0.tags.contains(tag) } }) { problems.append("no \(tag)") } }
    print("OWL SELFCHECK: \(problems.isEmpty ? "OK" : problems.joined(separator: " | "))")
}
#endif

// MARK: - Views

struct MinervaOwlView: View {
    let onClose: () -> Void
    @StateObject private var model = OwlModel()

    var body: some View {
        ArcadeShell(model: model,
                    spec: GameID.minervaOwl.spec ?? GameSpec(title: "Minerva's Owl", mechanic: "", premise: "", game: .minervaOwl),
                    accent: 0x9fc6ff, onClose: { LibraryVoice.stop(); onClose() },
                    backdrop: { OwlNight() }) {
            OwlPlay(model: model)
        }
        .onDisappear { LibraryVoice.stop() }
    }
}

/// The night sky over Minerva's temple: stars, the moon, the temple roofline, an olive tree.
private struct OwlNight: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0x0b1030), Color(hex: 0x1b2456), Color(hex: 0x3a3a72)],
                               startPoint: .top, endPoint: .bottom)
                Canvas { ctx, size in
                    for i in 0..<90 {
                        let x = libHash(i, 1) * size.width, y = libHash(i, 2) * size.height * 0.75
                        let r = 0.6 + libHash(i, 3) * 1.6
                        ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                                 with: .color(.white.opacity(0.35 + Double(libHash(i, 4)) * 0.6)))
                    }
                }
                // Moon
                Circle().fill(RadialGradient(colors: [Color(hex: 0xfffbe6), Color(hex: 0xf1e2a8)], center: .center, startRadius: 4, endRadius: 40))
                    .frame(width: 74).shadow(color: Color(hex: 0xfff2b0).opacity(0.7), radius: 30)
                    .position(x: w * 0.84, y: h * 0.64)
                // Temple roofline (dark silhouette)
                OwlTemple().fill(Color(hex: 0x0d1029).opacity(0.9))
                    .frame(width: w, height: h * 0.32)
                    .position(x: w / 2, y: h - h * 0.16)
            }
        }
    }
}

private struct OwlTemple: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let baseY = r.maxY, top = r.minY + r.height * 0.18
        let left = r.minX + r.width * 0.08, right = r.maxX - r.width * 0.08
        p.move(to: CGPoint(x: left - 10, y: top + 30)); p.addLine(to: CGPoint(x: r.midX, y: top))
        p.addLine(to: CGPoint(x: right + 10, y: top + 30)); p.closeSubpath()
        p.addRect(CGRect(x: left - 6, y: top + 30, width: right - left + 12, height: 12))
        let n = 6
        for k in 0..<n {
            let x = left + (right - left) * CGFloat(k) / CGFloat(n - 1)
            p.addRect(CGRect(x: x - 9, y: top + 42, width: 18, height: baseY - top - 42))
        }
        p.addRect(CGRect(x: r.minX, y: baseY - 18, width: r.width, height: 18))
        return p
    }
}

/// The olive branch the owl perches on (Minerva's tree), in the play area's coordinates.
private struct OliveBranch: View {
    let width: CGFloat
    var body: some View {
        ZStack {
            OwlBranch().fill(LinearGradient(colors: [Color(hex: 0x4a3322), Color(hex: 0x2b1d13)], startPoint: .top, endPoint: .bottom))
                .frame(width: width, height: 60)
            ForEach(0..<10, id: \.self) { k in
                Ellipse().fill(Color(hex: k % 2 == 0 ? 0x5f7d4a : 0x7f9a62))
                    .frame(width: 30, height: 11)
                    .rotationEffect(.degrees(Double(k % 3) * 25 - 25))
                    .offset(x: width * (CGFloat(k) / 9 - 0.5) * 0.92 + (k == 4 || k == 5 ? (k == 4 ? -50 : 50) : 0),
                            y: -10 + CGFloat(k % 2) * 16)
            }
            // a few olives
            ForEach(0..<4, id: \.self) { k in
                Ellipse().fill(Color(hex: 0x2f3a1f)).frame(width: 9, height: 12)
                    .offset(x: width * [-0.38, -0.22, 0.26, 0.41][k], y: 12)
            }
        }
        .frame(width: width, height: 60)
        .allowsHitTesting(false)
    }
}

private struct OwlBranch: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY - 4))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY - 10), control: CGPoint(x: r.midX, y: r.midY + 14))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY + 6))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.midY + 12), control: CGPoint(x: r.midX, y: r.midY + 30))
        p.closeSubpath()
        return p
    }
}

private struct OwlPlay: View {
    @ObservedObject var model: OwlModel
    @State private var pull: CGSize = .zero
    @State private var aiming = false
    @State private var bursts: [(UUID, CGPoint)] = []
    @State private var shake: CGFloat = 0
    @State private var flap = false

    var body: some View {
        GeometryReader { g in
            let size = g.size
            let perch = CGPoint(x: size.width / 2, y: size.height - 150)
            let base = layout(in: size)
            TimelineView(.animation(paused: model.phase != .playing)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                let live = base.indices.map { i in moving(base[i], i, t) }
                let _ = model.track(live, perch: perch)
                ZStack {
                    OliveBranch(width: size.width).position(x: size.width / 2, y: perch.y + 66)
                    if aiming { aimLine(from: perch, live: live, size: size) }
                    ForEach(model.tokens.indices, id: \.self) { i in moth(i, at: live[i], perch: perch, t: t) }
                    OwlBird(look: lookDir(perch, live), flying: model.owlAt != nil, flap: flap,
                            confused: model.spat != nil, full: model.carrying != nil)
                        .modifier(LibraryShake(amount: 8, shakes: shake))
                        .position(owlPos(perch))
                        .animation(.easeInOut(duration: 0.4), value: model.owlAt)
                    ForEach(bursts, id: \.0) { b in LibraryBurst().position(b.1) }
                }
            }
            .contentShape(Rectangle())
            .gesture(slingshot(perch: perch, base: base))
            .overlay(alignment: .top) { banner.padding(.top, 58).padding(.horizontal, 14) }
        }
        .onChange(of: model.hoot) { _ in withAnimation(.linear(duration: 0.5)) { shake += 1 } }
        .onChange(of: model.carrying) { c in
            if let c, model.centers.indices.contains(c) {
                flap.toggle()
                let id = UUID()
                bursts.append((id, model.centers[c]))
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { bursts.removeAll { $0.0 == id } }
            }
        }
    }

    // MARK: Layout — the sentence wraps into rows of moths, in reading order.

    private func wordWidth(_ s: String) -> CGFloat { CGFloat(s.count) * 12.5 + 30 }

    private func layout(in size: CGSize) -> [CGPoint] {
        let maxW = size.width - 40
        var rows: [[Int]] = [[]], widths: [CGFloat] = [0]
        for i in model.tokens.indices {
            let w = wordWidth(model.tokens[i].text) + 26
            if widths[widths.count - 1] + w > maxW && !rows[rows.count - 1].isEmpty { rows.append([]); widths.append(0) }
            rows[rows.count - 1].append(i); widths[widths.count - 1] += w
        }
        var out = [CGPoint](repeating: .zero, count: model.tokens.count)
        let top: CGFloat = 230, gap: CGFloat = 84
        let span = max(1, min(CGFloat(rows.count - 1) * gap, size.height - 150 - 140 - top))
        for (r, row) in rows.enumerated() {
            var x = (size.width - widths[r]) / 2
            let y = rows.count == 1 ? top + 40 : top + span * CGFloat(r) / CGFloat(rows.count - 1)
            for i in row {
                let w = wordWidth(model.tokens[i].text) + 26
                out[i] = CGPoint(x: x + w / 2, y: y + (r % 2 == 0 ? 0 : 0))
                x += w
            }
        }
        return out
    }

    private func moving(_ p: CGPoint, _ i: Int, _ t: Double) -> CGPoint {
        if model.carrying == i { return p }
        let b = model.bob, dr = model.drift
        return CGPoint(x: p.x + dr * CGFloat(sin(t * 0.9 + Double(i) * 1.7)),
                       y: p.y + b * CGFloat(sin(t * 2.1 + Double(i) * 0.9)))
    }

    private func owlPos(_ perch: CGPoint) -> CGPoint {
        if let p = model.owlAt { return CGPoint(x: p.x, y: p.y + 30) }
        let k: CGFloat = 0.35
        return CGPoint(x: perch.x + pull.width * k, y: perch.y + pull.height * k)
    }

    private func lookDir(_ perch: CGPoint, _ live: [CGPoint]) -> CGPoint {
        if aiming { let l = max(1, hypot(pull.width, pull.height)); return CGPoint(x: -pull.width / l, y: -pull.height / l) }
        if let g = model.glow, live.indices.contains(g) {
            let v = CGPoint(x: live[g].x - perch.x, y: live[g].y - perch.y); let l = max(1, hypot(v.x, v.y))
            return CGPoint(x: v.x / l, y: v.y / l)
        }
        return CGPoint(x: 0, y: -0.4)
    }

    // MARK: Aiming

    /// The first moth a ray from the perch along `dir` passes through (slab test on each card).
    private func firstHit(from o: CGPoint, dir: CGSize, live: [CGPoint]) -> Int? {
        let l = hypot(dir.width, dir.height); guard l > 1 else { return nil }
        let dx = dir.width / l, dy = dir.height / l
        var best: (Int, CGFloat)?
        for i in live.indices where !model.caught.contains(i) {
            let halfW = (wordWidth(model.tokens[i].text) + 10) / 2, halfH: CGFloat = 30
            let c = live[i]
            var tmin: CGFloat = 0, tmax: CGFloat = 4000
            for (o1, d1, lo, hi) in [(o.x, dx, c.x - halfW, c.x + halfW), (o.y, dy, c.y - halfH, c.y + halfH)] {
                if abs(d1) < 1e-6 { if o1 < lo || o1 > hi { tmin = 1; tmax = 0 } ; continue }
                var t1 = (lo - o1) / d1, t2 = (hi - o1) / d1
                if t1 > t2 { swap(&t1, &t2) }
                tmin = max(tmin, t1); tmax = min(tmax, t2)
            }
            if tmin <= tmax, best == nil || tmin < best!.1 { best = (i, tmin) }
        }
        return best?.0
    }

    @ViewBuilder private func aimLine(from perch: CGPoint, live: [CGPoint], size: CGSize) -> some View {
        let dir = CGSize(width: -pull.width, height: -pull.height)
        let l = max(1, hypot(dir.width, dir.height))
        let end = CGPoint(x: perch.x + dir.width / l * 900, y: perch.y + dir.height / l * 900)
        Path { p in p.move(to: perch); p.addLine(to: end) }
            .stroke(Color.white.opacity(0.75), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 12]))
            .allowsHitTesting(false)
    }

    private func slingshot(perch: CGPoint, base: [CGPoint]) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                guard model.phase == .playing, !model.busy else { return }
                let moved = hypot(v.translation.width, v.translation.height)
                if moved > 12 {
                    if !aiming { Haptics.light(); Sfx.play(.tick) }
                    aiming = true
                    let l = max(1, moved), k = min(moved, 160) / l
                    pull = CGSize(width: v.translation.width * k, height: v.translation.height * k)
                }
            }
            .onEnded { v in
                defer { withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { pull = .zero }; aiming = false }
                guard model.phase == .playing, !model.busy else { return }
                let now = Date().timeIntervalSinceReferenceDate
                let live = base.indices.map { moving(base[$0], $0, now) }
                if aiming {
                    guard hypot(pull.width, pull.height) > 30 else { return }
                    let dir = CGSize(width: -pull.width, height: -pull.height)
                    if let i = firstHit(from: perch, dir: dir, live: live) {
                        model.centers = live
                        model.launch(moth: i, toward: live[i])
                    } else {
                        let l = hypot(dir.width, dir.height)
                        model.launch(moth: nil, toward: CGPoint(x: perch.x + dir.width / l * 420, y: perch.y + dir.height / l * 420))
                    }
                } else if let i = live.indices.first(where: { j in
                    !model.caught.contains(j) && abs(live[j].x - v.location.x) < (wordWidth(model.tokens[j].text) + 16) / 2 && abs(live[j].y - v.location.y) < 32
                }) {
                    // A tap on a moth: say its word; while it's easy, the owl flies to it too.
                    LibraryVoice.say(model.tokens[i].bare)
                    if model.tapFlies { model.centers = live; model.launch(moth: i, toward: live[i]) }
                }
            }
    }

    // MARK: Moths

    @ViewBuilder private func moth(_ i: Int, at p: CGPoint, perch: CGPoint, t: Double) -> some View {
        let tok = model.tokens[i]
        let carried = model.carrying == i
        let gone = model.caught.contains(i) && !carried
        let aimed: Bool = {
            guard aiming, model.showAimTarget else { return false }
            let now = Date().timeIntervalSinceReferenceDate
            let base = layout(in: CGSize(width: perch.x * 2, height: perch.y + 150))
            let live = base.indices.map { moving(base[$0], $0, now) }
            return firstHit(from: perch, dir: CGSize(width: -pull.width, height: -pull.height), live: live) == i
        }()
        let flutter = CGFloat(abs(sin(t * 9 + Double(i))))
        MothView(word: tok.text, flutter: flutter, glow: model.glow == i || aimed,
                 wrong: model.spat == i, tint: [0xf7c6e0, 0xc6e3f7, 0xf7e7a8, 0xd6f0c2, 0xe3d0f7][i % 5])
            .scaleEffect(carried ? 0.6 : (gone ? 0.2 : 1))
            .opacity(gone ? 0 : 1)
            .position(carried ? CGPoint(x: owlPos(perch).x, y: owlPos(perch).y + 46) : p)
            .animation(.easeInOut(duration: 0.4), value: model.owlAt)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: model.spat)
            .animation(.easeOut(duration: 0.3), value: gone)
    }

    // MARK: Banner — what to catch

    private var banner: some View {
        let part = model.part
        return HStack(spacing: 12) {
            Text(part.icon).font(.system(size: 38))
                .frame(width: 58, height: 58)
                .background(Circle().fill(Color(hex: 0x24305e)))
            ZStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(model.need > 1 ? "CATCH EVERY" : "CATCH THE").font(luFont(11, .heavy)).tracking(1.5)
                        .foregroundStyle(Color(hex: 0xb9c7ef))
                    HStack(spacing: 6) {
                        Text(part.name + (model.need > 1 ? "  ×\(model.need)" : ""))
                            .font(luSerif(24, .black)).foregroundStyle(Color(hex: 0xfff3c4))
                            .lineLimit(1).minimumScaleFactor(0.6)
                    }
                    Text(part.hint).font(luFont(13, .bold)).foregroundStyle(Color(hex: 0xd8e0f7))
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                .opacity(model.lesson == nil ? 1 : 0)
                if let lesson = model.lesson {
                    libMarked(lesson, base: 0xfff3c4, mark: 0xffb37a)
                        .font(luFont(17, .heavy)).lineLimit(3).minimumScaleFactor(0.6)
                        .transition(.opacity)
                }
            }
            Spacer(minLength: 0)
            LibrarySpeakerButton(size: 46) { model.sayCue() }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(hex: 0x141b42).opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color(hex: 0x9fb2e8).opacity(0.5), lineWidth: 2))
        )
        .overlay(alignment: .bottom) { dawnBar.padding(.horizontal, 18).offset(y: 8) }
        .animation(.easeOut(duration: 0.25), value: model.lesson)
    }

    @ViewBuilder private var dawnBar: some View {
        let per = model.roundPatience
        if per > 0 {
            TimelineView(.animation(minimumInterval: 0.1, paused: model.phase != .playing || model.deadline == nil)) { tl in
                let left = model.deadline.map { max(0, $0.timeIntervalSince(tl.date)) } ?? 0
                let frac = CGFloat(left / per)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: 0x0b1030))
                        Capsule().fill(LinearGradient(colors: [Color(hex: 0x9fc6ff), Color(hex: frac < 0.3 ? 0xffa64d : 0xdfe8ff)],
                                                      startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, g.size.width * frac))
                    }
                }
            }
            .frame(height: 6)
        }
    }
}

/// A moth carrying one word: pastel wings that flutter behind a little card.
private struct MothView: View {
    let word: String
    let flutter: CGFloat
    let glow: Bool, wrong: Bool
    let tint: UInt

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                wing.scaleEffect(x: 0.55 + flutter * 0.45, y: 1, anchor: .trailing)
                Spacer(minLength: 0)
                wing.scaleEffect(x: -(0.55 + flutter * 0.45), y: 1, anchor: .leading)
            }
            .frame(width: CGFloat(word.count) * 12.5 + 64, height: 52)
            // antennae
            Path { p in
                p.move(to: CGPoint(x: -4, y: 0)); p.addQuadCurve(to: CGPoint(x: -12, y: -14), control: CGPoint(x: -4, y: -10))
                p.move(to: CGPoint(x: 4, y: 0)); p.addQuadCurve(to: CGPoint(x: 12, y: -14), control: CGPoint(x: 4, y: -10))
            }
            .stroke(Color(hex: 0x3a2a1a), lineWidth: 2)
            .frame(width: 0, height: 0).offset(y: -18)
            Text(word)
                .font(luFont(21, .heavy)).foregroundStyle(Color(hex: 0x2a1d10))
                .lineLimit(1).fixedSize()
                .padding(.horizontal, 12).frame(height: 40)
                .background(Capsule().fill(LinearGradient(colors: [Color(hex: 0xfff8e4), Color(hex: 0xead8b0)], startPoint: .top, endPoint: .bottom)))
                .overlay(Capsule().stroke(Color(hex: wrong ? Lu.coral : (glow ? 0xffe27a : 0x8a6a3a)), lineWidth: glow || wrong ? 4 : 2))
        }
        .shadow(color: glow ? Color(hex: 0xffe27a).opacity(0.95) : Color(hex: 0xbfd4ff).opacity(0.35), radius: glow ? 16 : 8)
        .rotationEffect(.degrees(wrong ? 14 : 0))
    }

    private var wing: some View {
        ZStack {
            Ellipse().fill(Color(hex: tint).opacity(0.92)).frame(width: 34, height: 40).offset(y: -6)
            Ellipse().fill(luShade(tint, -30).opacity(0.9)).frame(width: 24, height: 24).offset(x: 2, y: 14)
            Circle().fill(Color.white.opacity(0.7)).frame(width: 9).offset(x: -4, y: -10)
        }
        .frame(width: 34)
    }
}

/// Minerva's little owl, drawn from shapes: big round eyes that follow the aim, ear tufts,
/// a feathered belly, wings that spread in flight.
private struct OwlBird: View {
    let look: CGPoint
    let flying: Bool
    let flap: Bool
    let confused: Bool
    let full: Bool

    var body: some View {
        ZStack {
            // Wings
            ForEach([-1.0, 1.0], id: \.self) { s in
                Ellipse()
                    .fill(LinearGradient(colors: [Color(hex: 0x8a6440), Color(hex: 0x5a3e26)], startPoint: .top, endPoint: .bottom))
                    .frame(width: flying ? 70 : 34, height: flying ? 40 : 74)
                    .rotationEffect(.degrees(flying ? s * -18 : s * 8))
                    .offset(x: s * (flying ? 58 : 40), y: flying ? -6 : 12)
            }
            // Body
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0xa57a4f), Color(hex: 0x6f4c2d)], startPoint: .top, endPoint: .bottom))
                .frame(width: 96, height: 112).offset(y: 10)
            // Belly with chevron feathers
            Ellipse().fill(Color(hex: 0xe9d6b0)).frame(width: 62, height: 70).offset(y: 24)
            ForEach(0..<3, id: \.self) { r in
                ForEach(0..<(3 - r % 2), id: \.self) { c in
                    Text("v").font(.system(size: 12, weight: .bold)).foregroundStyle(Color(hex: 0x9a7a52))
                        .offset(x: CGFloat(c) * 14 - CGFloat(2 - r % 2) * 7, y: 14 + CGFloat(r) * 14)
                }
            }
            // Ear tufts
            ForEach([-1.0, 1.0], id: \.self) { s in
                Triangle().fill(Color(hex: 0x6f4c2d)).frame(width: 22, height: 26)
                    .rotationEffect(.degrees(s * 18)).offset(x: s * 32, y: -50)
            }
            // Face disc + eyes
            HStack(spacing: 4) { eye; eye }.offset(y: -22)
            Triangle().fill(Color(hex: 0xf0a83a)).frame(width: 14, height: 14).rotationEffect(.degrees(180)).offset(y: -4)
            // Feet
            if !flying {
                HStack(spacing: 18) {
                    Capsule().fill(Color(hex: 0xf0a83a)).frame(width: 16, height: 8)
                    Capsule().fill(Color(hex: 0xf0a83a)).frame(width: 16, height: 8)
                }
                .offset(y: 64)
            }
            if confused {
                Text("?").font(luFont(34)).foregroundStyle(Color(hex: 0xfff3c4)).offset(x: 46, y: -64)
            }
        }
        .frame(width: 150, height: 150)
        .scaleEffect(full ? 1.06 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: flying)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: full)
    }

    private var eye: some View {
        ZStack {
            Circle().fill(Color(hex: 0xf6ead0)).frame(width: 40)
            Circle().fill(Color(hex: confused ? 0xd88a2a : 0xf3b630)).frame(width: 26)
                .offset(x: look.x * 6, y: look.y * 6)
            Circle().fill(Color.black).frame(width: 13).offset(x: look.x * 7, y: look.y * 7)
            Circle().fill(Color.white).frame(width: 5).offset(x: look.x * 7 - 3, y: look.y * 7 - 3)
        }
        .overlay(Circle().stroke(Color(hex: 0x5a3e26), lineWidth: 3))
    }
}

private struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath(); return p
    }
}
