import SwiftUI

// MARK: - Word Sort  (Word Wizards · lane-sorter, parts of speech)
//
// A word tile drifts down; tap the bin for its part of speech. Built on the shared lane sorter
// (Games/LaneSorter.swift) and GameKit. A miss flies the word to its right bin and names it.
//
// Level ladder:
//   I    NOUN vs VERB, every word with a picture (🐱 cat / 🏃 run) — very slow fall (15 s)
//   II   NOUN vs VERB, short words, about half still with a picture; verbs are concrete actions
//   III  + ADJECTIVE ("a describing word": big, sleepy, fluffy); less concrete verbs (obey, enjoy)
//   IV   + ADVERB ("how? when? how much?": quickly, softly, never, very) and some longer words
//   V    words that can be either, decided by a short phrase: "a *run* in the park" → NOUN
//   VI+  phrases + tricky endings (friendly = adjective, belly = noun, apply = verb); faster
//
// Words in the plain banks are chosen so their everyday use is clearly one part of speech;
// words with two common uses only appear inside a phrase that decides them.

private let wsBins: [SortBin] = [
    SortBin(id: "noun", title: "NOUN", icon: "🧸", tint: Lu.sky, hint: "person, place, thing"),
    SortBin(id: "verb", title: "VERB", icon: "🤸", tint: Lu.mint, hint: "doing"),
    SortBin(id: "adj", title: "ADJECTIVE", icon: "🌈", tint: Lu.tangerine, hint: "what kind?"),
    SortBin(id: "adv", title: "ADVERB", icon: "⏱️", tint: Lu.grape, hint: "how? when? how much?"),
]

private let wsNames = ["noun": "noun", "verb": "verb", "adj": "adjective", "adv": "adverb"]
private let wsHints = ["noun": "a person, place or thing", "verb": "a doing word", "adj": "a describing word", "adv": "how, when or how much"]

// Level I — with pictures (and half of Level II). The picture decides, so a person-doing-it
// emoji may carry a verb that is also a noun (run, swim); those stay out of the plain banks.
private let wsPictures: [(String, String, String)] = [
    ("🐱", "cat", "noun"), ("🍎", "apple", "noun"), ("🍌", "banana", "noun"), ("🐸", "frog", "noun"),
    ("🐝", "bee", "noun"), ("🍕", "pizza", "noun"), ("🚗", "car", "noun"), ("🐘", "elephant", "noun"),
    ("🦁", "lion", "noun"), ("🌈", "rainbow", "noun"), ("🦒", "giraffe", "noun"), ("🥕", "carrot", "noun"),
    ("🐯", "tiger", "noun"), ("☂️", "umbrella", "noun"), ("🍓", "strawberry", "noun"), ("🐧", "penguin", "noun"),
    ("🏃", "run", "verb"), ("🏊", "swim", "verb"), ("🧗", "climb", "verb"), ("💃", "dance", "verb"),
    ("🤸", "tumble", "verb"), ("🏋️", "lift", "verb"), ("😂", "laugh", "verb"), ("👏", "clap", "verb"),
    ("✍️", "write", "verb"), ("😋", "eat", "verb"), ("🤾", "throw", "verb"), ("🤔", "think", "verb"),
    ("🧎", "kneel", "verb"), ("🤧", "sneeze", "verb"), ("🚴", "ride", "verb"), ("🙈", "hide", "verb"),
]

// Plain words (II+).
private let wsNouns1 = ["cat", "girl", "boy", "desk", "apple", "bird", "lamp", "car", "frog", "hen", "hat",
                        "sofa", "lion", "zoo", "tooth", "ear", "bee", "ant", "owl", "goat", "door", "uncle", "aunt"]
// Short, concrete actions (II+); the less concrete ones join at III.
private let wsVerbs1 = ["eat", "sing", "lend", "sell", "see", "give", "come", "write",
                        "sit", "bring", "think", "teach", "speak", "tell", "learn", "fetch"]
private let wsVerbsMid = ["obey", "agree", "enjoy", "pretend"]
private let wsAdjs1 = ["big", "tiny", "happy", "sad", "tall", "soft", "hot", "funny", "sleepy", "shiny",
                       "fluffy", "angry", "hungry", "noisy", "huge", "sticky", "lazy", "silly", "grumpy", "scary"]
private let wsAdvs1 = ["quickly", "slowly", "softly", "loudly", "happily", "sadly", "gently", "quietly",
                       "carefully", "bravely", "always", "never", "often", "soon", "suddenly", "finally",
                       "sometimes", "safely", "very", "almost", "nearly", "neatly", "politely"]
// Longer words (IV+).
private let wsNouns2 = ["village", "kingdom", "island", "library", "dinosaur", "mountain", "teacher",
                        "window", "planet", "octopus", "ocean", "river", "palace", "wizard", "cousin"]
private let wsVerbs2 = ["explore", "borrow", "arrive", "describe", "imagine", "discover", "remember",
                        "choose", "begin", "forget", "carry", "gather"]
private let wsAdjs2 = ["ancient", "enormous", "gentle", "curious", "fierce", "clever", "busy", "muddy",
                       "delicious", "famous", "invisible"]
// Tricky endings (VI+): -ly words that are NOT adverbs; -ness/-ment nouns; -ify/-ise verbs.
private let wsTricky: [(String, String)] = [
    ("friendly", "adj"), ("lovely", "adj"), ("lonely", "adj"), ("ugly", "adj"), ("silly", "adj"),
    ("curly", "adj"), ("chilly", "adj"), ("belly", "noun"), ("jelly", "noun"), ("family", "noun"),
    ("lily", "noun"), ("rely", "verb"), ("apply", "verb"), ("multiply", "verb"), ("happiness", "noun"),
    ("kindness", "noun"), ("excitement", "noun"), ("simplify", "verb"), ("beautiful", "adj"),
    ("dangerous", "adj"), ("sometimes", "adv"),
]
// Phrases (V+): the *marked* word's job in this phrase.
private let wsPhrases: [(String, String)] = [
    ("a *run* in the park", "noun"), ("we *run* to school", "verb"),
    ("a big *smile*", "noun"), ("*smile* for the camera", "verb"),
    ("my new *watch*", "noun"), ("*watch* the bird", "verb"),
    ("the *play* was fun", "noun"), ("let's *play* tag", "verb"),
    ("a *walk* to the shop", "noun"), ("we *walk* to the shop", "verb"),
    ("wet *paint*", "noun"), ("*paint* the fence", "verb"),
    ("a *fish* swam by", "noun"), ("we *fish* in the lake", "verb"),
    ("the *light* is on", "noun"), ("*light* the candle", "verb"), ("a *light* bag", "adj"),
    ("a *cold* drink", "adj"), ("I have a *cold*", "noun"),
    ("a *clean* shirt", "adj"), ("*clean* your room", "verb"),
    ("an *empty* box", "adj"), ("*empty* the bin", "verb"),
    ("a *dry* towel", "adj"), ("*dry* the dishes", "verb"),
    ("a *fast* car", "adj"), ("she runs *fast*", "adv"),
    ("a *hard* rock", "adj"), ("work *hard*", "adv"),
    ("an *early* train", "adj"), ("we left *early*", "adv"),
    ("a *late* bus", "adj"), ("she came *late*", "adv"),
    ("a *high* wall", "adj"), ("jump *high*", "adv"),
    ("a *straight* line", "adj"), ("go *straight* home", "adv"),
    ("my *back* hurts", "noun"), ("come *back* soon", "adv"),
    ("a *kind* word", "adj"), ("what *kind* of dog?", "noun"),
    ("a *fine* day", "adj"), ("pay a *fine*", "noun"),
    ("a *rock* fell", "noun"), ("*rock* the baby", "verb"),
    ("a *round* ball", "adj"), ("the last *round*", "noun"),
    ("*kick* the ball", "verb"), ("a long *kick*", "noun"),
    ("*open* the door", "verb"), ("an *open* door", "adj"),
    ("*warm* your hands", "verb"), ("a *warm* coat", "adj"),
    ("you sang *well*", "adv"), ("the *well* is deep", "noun"),
]

private func wsBinsFor(_ level: Int) -> [SortBin] { Array(wsBins.prefix(level <= 2 ? 2 : (level == 3 ? 3 : 4))) }

private func wsFall(_ level: Int) -> Double {
    let table: [Double] = [15, 13, 12, 11, 12, 10, 9, 8]
    return level <= table.count ? table[level - 1] : max(6, 8 - Double(level - 8) * 0.3)
}

private func wsWord(_ w: String, _ pos: String, emoji: String = "") -> SortItem {
    SortItem(emoji: emoji, text: w, bin: pos,
             lesson: "*\(w)* is \(pos == "adj" || pos == "adv" ? "an" : "a") \(wsNames[pos]!.uppercased()) — \(wsHints[pos]!)")
}

private func wsPhrase(_ p: (String, String)) -> SortItem {
    let word = p.0.components(separatedBy: "*").dropFirst().first ?? p.0
    let pos = wsNames[p.1]!
    return SortItem(text: p.0, bin: p.1,
                    lesson: "Here *\(word)* is \(p.1 == "adj" || p.1 == "adv" ? "an" : "a") \(pos.uppercased())")
}

private func wsMake(_ level: Int) -> SortItem {
    func plain(_ pos: String, long: Bool) -> SortItem {
        let bank: [String]
        switch pos {
        case "noun": bank = long ? wsNouns1 + wsNouns2 : wsNouns1
        case "verb": bank = (level >= 3 ? wsVerbs1 + wsVerbsMid : wsVerbs1) + (long ? wsVerbs2 : [])
        case "adj": bank = long ? wsAdjs1 + wsAdjs2 : wsAdjs1
        default: bank = wsAdvs1
        }
        return wsWord(bank.randomElement()!, pos)
    }
    let r = Double.random(in: 0..<1)
    switch level {
    case 1:
        let p = wsPictures.randomElement()!
        return wsWord(p.1, p.2, emoji: p.0)
    case 2:
        if r < 0.5 { let p = wsPictures.randomElement()!; return wsWord(p.1, p.2, emoji: p.0) }
        return plain(["noun", "verb"].randomElement()!, long: false)
    case 3: return plain(r < 0.4 ? "adj" : ["noun", "verb", "adj"].randomElement()!, long: false)
    case 4: return plain(r < 0.4 ? "adv" : ["noun", "verb", "adj", "adv"].randomElement()!, long: true)
    case 5: return r < 0.6 ? wsPhrase(wsPhrases.randomElement()!) : plain(["noun", "verb", "adj", "adv"].randomElement()!, long: true)
    default:
        if r < 0.5 { return wsPhrase(wsPhrases.randomElement()!) }
        if r < 0.8 { let t = wsTricky.randomElement()!; return wsWord(t.0, t.1) }
        return plain(["noun", "verb", "adj", "adv"].randomElement()!, long: true)
    }
}

#if DEBUG
/// No plain word sits in two banks; every phrase marks exactly one word; every level's items land
/// in a bin that's on screen.
private func wsSelfCheck() {
    var seen: [String: String] = [:]
    let plain = wsPictures.map { ($0.1, $0.2) } + wsNouns1.map { ($0, "noun") } + wsNouns2.map { ($0, "noun") }
        + wsVerbs1.map { ($0, "verb") } + wsVerbsMid.map { ($0, "verb") } + wsVerbs2.map { ($0, "verb") } + wsAdjs1.map { ($0, "adj") }
        + wsAdjs2.map { ($0, "adj") } + wsAdvs1.map { ($0, "adv") } + wsTricky
    for (w, p) in plain {
        precondition(seen[w] == nil || seen[w] == p, "Word Sort: \(w) in two bins")
        seen[w] = p
    }
    for p in wsPhrases { precondition(p.0.filter { $0 == "*" }.count == 2, "Word Sort: bad phrase \(p.0)") }
    for lv in 1...12 {
        let ids = Set(wsBinsFor(lv).map(\.id))
        for _ in 0..<400 {
            let it = wsMake(lv)
            precondition(ids.contains(it.bin), "Word Sort: off-screen bin at \(lv)")
            precondition(lv >= 3 || !wsVerbsMid.contains(it.text), "Word Sort: abstract verb \(it.text) at \(lv)")
        }
    }
    // Gradus II keeps a picture on about half its words.
    let pics = (0..<1000).filter { _ in !wsMake(2).emoji.isEmpty }.count
    precondition((350...650).contains(pics), "Word Sort: L2 pictures \(pics)/1000")
    print("SELFCHECK wordSort OK")
}
#endif

struct WordSortView: View {
    let onClose: () -> Void
    @StateObject private var model = LaneSortModel(key: GameID.wordSort.rawValue, bins: wsBinsFor, make: wsMake, fall: wsFall)

    var body: some View {
        LaneSorterView(model: model,
                       spec: GameID.wordSort.spec ?? GameSpec(title: "Word Sort", mechanic: "", premise: "", game: .wordSort),
                       accent: Lu.mint, prompt: "What kind of word?", onClose: onClose)
            .onAppear {
                #if DEBUG
                wsSelfCheck()
                #endif
            }
    }
}
