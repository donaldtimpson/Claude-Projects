import SwiftUI

// MARK: - Polyphemus Is Hungry  (Word Wizards · feed)
//
// A big, dim, lovable Cyclops only eats things that have the sound on his bib. Drag a plate into
// his mouth: the right one he chomps; a wrong one turns him green — "BLEH!" — he spits it across
// the room, then the right plate glows and he gulps it, so every miss shows the answer. A 🔊
// button (and once per round, automatically) says the cue; tapping a plate says its word — and at
// I–II a tap also feeds it to him (dragging works at every level).
//
// Ladder:
//   I    first sound: bib letter + a picture with that sound ("B like 🐻"), 2 picture foods, no words
//   II   first sound, 3 foods with their names; more letters (vowels, c/k, look-alike sounds)
//   III  blends & digraphs at the start (ch, sh, br, st…), traps share the first letter (cake ≠ ch)
//   IV   ending sounds (-ck, -sh, -ll, -ch) and long vowels (cake vs cat)
//   V    rhymes, words only, spelling traps (height ✓, eight ✗); a patience bar appears (15 s)
//   VI   prefixes & suffixes by meaning (un-, re-, pre-, -ful, -less, -er, -able, mis-), 13 s
//   VII  rhymes + affixes, 4 choices, 11 s
//   VIII+ everything from III up as words only, 4 choices, 10 s easing to 7 s

// MARK: Word data

private struct PFood: Hashable {
    let word: String
    let emoji: String
}
private func f(_ w: String, _ e: String) -> PFood { PFood(word: w, emoji: e) }

/// A first-sound group (levels I–II). `sound` joins letters that start the same way (c / k).
/// `easy` foods are the ones a 7-year-old names on sight (level I is pictures only).
private struct PLetter {
    let letter: String, sound: String
    let cue: PFood
    let easy: [PFood], more: [PFood]
    var all: [PFood] { easy + more }
}

private let pLetters: [PLetter] = [
    PLetter(letter: "b", sound: "b", cue: f("bear", "🐻"),
            easy: [f("banana", "🍌"), f("bread", "🍞")],
            more: [f("burger", "🍔"), f("broccoli", "🥦"), f("bagel", "🥯")]),
    PLetter(letter: "c", sound: "k", cue: f("cat", "🐱"),
            easy: [f("carrot", "🥕"), f("cake", "🍰"), f("cookie", "🍪"), f("corn", "🌽"), f("cupcake", "🧁")],
            more: [f("coconut", "🥥")]),
    PLetter(letter: "p", sound: "p", cue: f("pig", "🐷"),
            easy: [f("pizza", "🍕"), f("pear", "🍐"), f("pie", "🥧"), f("popcorn", "🍿")],
            more: [f("peach", "🍑"), f("potato", "🥔"), f("pineapple", "🍍"), f("pancakes", "🥞")]),
    PLetter(letter: "m", sound: "m", cue: f("monkey", "🐵"),
            easy: [f("milk", "🥛"), f("mushroom", "🍄")],
            more: [f("mango", "🥭"), f("melon", "🍈")]),
    PLetter(letter: "t", sound: "t", cue: f("tiger", "🐯"),
            easy: [f("tomato", "🍅"), f("taco", "🌮")], more: []),
    PLetter(letter: "h", sound: "h", cue: f("horse", "🐴"),
            easy: [f("hot dog", "🌭")], more: [f("honey", "🍯")]),
    PLetter(letter: "l", sound: "l", cue: f("lion", "🦁"),
            easy: [f("lemon", "🍋")], more: [f("lollipop", "🍭")]),
    PLetter(letter: "w", sound: "w", cue: f("wolf", "🐺"),
            easy: [f("watermelon", "🍉"), f("waffle", "🧇")], more: []),
    PLetter(letter: "s", sound: "s", cue: f("sun", "☀️"),
            easy: [f("sandwich", "🥪"), f("salad", "🥗")], more: [f("sushi", "🍣")]),
    PLetter(letter: "d", sound: "d", cue: f("dog", "🐶"),
            easy: [], more: [f("donut", "🍩"), f("dumpling", "🥟")]),
    PLetter(letter: "f", sound: "f", cue: f("fox", "🦊"),
            easy: [], more: [f("fries", "🍟"), f("fish", "🐟")]),
    PLetter(letter: "g", sound: "g", cue: f("goat", "🐐"),
            easy: [], more: [f("grapes", "🍇"), f("garlic", "🧄")]),
    PLetter(letter: "n", sound: "n", cue: f("nose", "👃"),
            easy: [], more: [f("noodles", "🍜")]),
    PLetter(letter: "r", sound: "r", cue: f("rabbit", "🐰"),
            easy: [], more: [f("rice", "🍚")]),
    PLetter(letter: "k", sound: "k", cue: f("key", "🔑"),
            easy: [], more: [f("kiwi", "🥝")]),
    PLetter(letter: "a", sound: "a", cue: f("ant", "🐜"),
            easy: [], more: [f("apple", "🍎"), f("avocado", "🥑")]),
    PLetter(letter: "e", sound: "e", cue: f("elephant", "🐘"),
            easy: [], more: [f("egg", "🥚")]),
    PLetter(letter: "o", sound: "o", cue: f("octopus", "🐙"),
            easy: [], more: [f("olive", "🫒")]),
]

/// Sounds too alike to pit against each other at level I.
private let pAlike: [Set<String>] = [["b", "p", "d"], ["m", "n"], ["k", "g"], ["t", "d"], ["f", "v"], ["a", "e", "o"]]
private func pConfusable(_ a: String, _ b: String) -> Bool { pAlike.contains { $0.contains(a) && $0.contains(b) } }

private enum PKind { case letter, start, end, vowel, rhyme, affix }

/// A level III+ deck: what he wants (`bib`), an example (`cue`), right answers (`yes`) and
/// look-alike wrong ones (`no`). The two lists never overlap, so each round has one right plate.
private struct PSet {
    let kind: PKind
    let bib: String
    let cue: PFood            // for an affix: word = the meaning ("NOT"), emoji = ""
    let yes: [PFood], no: [PFood]
}

private func w(_ list: String) -> [PFood] { list.split(separator: ",").map { f($0.trimmingCharacters(in: .whitespaces), "") } }

// III — the start of the word.
private let pStarts: [PSet] = [
    PSet(kind: .start, bib: "ch", cue: f("chair", "🪑"),
         yes: [f("cheese", "🧀"), f("cherries", "🍒"), f("chocolate", "🍫"), f("chicken", "🍗")],
         no: [f("carrot", "🥕"), f("cake", "🍰"), f("cookie", "🍪"), f("corn", "🌽"), f("cupcake", "🧁"), f("honey", "🍯")]),
    PSet(kind: .start, bib: "sh", cue: f("shark", "🦈"),
         yes: [f("shoe", "👞"), f("shirt", "👕"), f("shell", "🐚"), f("shrimp", "🍤")],
         no: [f("sandwich", "🥪"), f("salad", "🥗"), f("sushi", "🍣"), f("sock", "🧦"), f("soap", "🧼"), f("hot dog", "🌭")]),
    PSet(kind: .start, bib: "br", cue: f("brick", "🧱"),
         yes: [f("bread", "🍞"), f("broccoli", "🥦"), f("broom", "🧹"), f("brush", "🖌️")],
         no: [f("banana", "🍌"), f("burger", "🍔"), f("bagel", "🥯"), f("bell", "🔔"), f("rice", "🍚")]),
    PSet(kind: .start, bib: "cr", cue: f("crab", "🦀"),
         yes: [f("crown", "👑"), f("crayon", "🖍️"), f("croissant", "🥐")],
         no: [f("carrot", "🥕"), f("cake", "🍰"), f("cookie", "🍪"), f("corn", "🌽"), f("cupcake", "🧁"), f("rice", "🍚")]),
    PSet(kind: .start, bib: "cl", cue: f("clown", "🤡"),
         yes: [f("clock", "⏰"), f("cloud", "☁️")],
         no: [f("carrot", "🥕"), f("cake", "🍰"), f("cookie", "🍪"), f("corn", "🌽"), f("lemon", "🍋"), f("lollipop", "🍭")]),
    PSet(kind: .start, bib: "dr", cue: f("dragon", "🐉"),
         yes: [f("drum", "🥁"), f("dress", "👗")],
         no: [f("donut", "🍩"), f("dumpling", "🥟"), f("dice", "🎲"), f("rice", "🍚")]),
    PSet(kind: .start, bib: "tr", cue: f("train", "🚂"),
         yes: [f("tree", "🌳"), f("truck", "🚚"), f("trumpet", "🎺"), f("trophy", "🏆")],
         no: [f("tomato", "🍅"), f("taco", "🌮"), f("tent", "⛺"), f("tooth", "🦷"), f("rice", "🍚")]),
    PSet(kind: .start, bib: "sn", cue: f("snake", "🐍"),
         yes: [f("snowman", "⛄"), f("snail", "🐌"), f("sneaker", "👟")],
         no: [f("sandwich", "🥪"), f("salad", "🥗"), f("sushi", "🍣"), f("sock", "🧦"), f("soap", "🧼"), f("noodles", "🍜")]),
    PSet(kind: .start, bib: "sp", cue: f("spider", "🕷️"),
         yes: [f("spoon", "🥄"), f("spaghetti", "🍝"), f("sponge", "🧽")],
         no: [f("sandwich", "🥪"), f("salad", "🥗"), f("sushi", "🍣"), f("sock", "🧦"), f("pizza", "🍕"), f("pie", "🥧")]),
    PSet(kind: .start, bib: "st", cue: f("star", "⭐"),
         yes: [f("strawberry", "🍓"), f("steak", "🥩")],
         no: [f("sandwich", "🥪"), f("salad", "🥗"), f("sushi", "🍣"), f("sock", "🧦"), f("taco", "🌮"), f("tomato", "🍅")]),
    PSet(kind: .start, bib: "pl", cue: f("plane", "✈️"),
         yes: [f("plate", "🍽️"), f("plant", "🪴")],
         no: [f("pizza", "🍕"), f("pear", "🍐"), f("pie", "🥧"), f("popcorn", "🍿"), f("lemon", "🍋")]),
    PSet(kind: .start, bib: "fl", cue: f("flower", "🌸"),
         yes: [f("flag", "🚩"), f("flashlight", "🔦")],
         no: [f("fries", "🍟"), f("fish", "🐟"), f("lemon", "🍋"), f("lollipop", "🍭")]),
    PSet(kind: .start, bib: "fr", cue: f("frog", "🐸"),
         yes: [f("fries", "🍟")],
         no: [f("fish", "🐟"), f("flag", "🚩"), f("rice", "🍚"), f("flashlight", "🔦")]),
]

// IV — the end of the word, and long vowels. No "no" word ends in (or has) the wanted sound.
private let pEnds: [PSet] = [
    PSet(kind: .end, bib: "-ck", cue: f("duck", "🦆"),
         yes: [f("sock", "🧦"), f("lock", "🔒"), f("clock", "⏰"), f("rock", "🪨"), f("truck", "🚚"), f("brick", "🧱")],
         no: [f("soap", "🧼"), f("sun", "☀️"), f("bell", "🔔"), f("fish", "🐟"), f("bus", "🚌"), f("hat", "🎩"), f("drum", "🥁"), f("ring", "💍")]),
    PSet(kind: .end, bib: "-sh", cue: f("fish", "🐟"),
         yes: [f("brush", "🖌️"), f("toothbrush", "🪥")],
         no: [f("sock", "🧦"), f("bus", "🚌"), f("bell", "🔔"), f("hat", "🎩"), f("drum", "🥁"), f("peach", "🍑")]),
    PSet(kind: .end, bib: "-ll", cue: f("bell", "🔔"),
         yes: [f("ball", "⚽"), f("shell", "🐚")],
         no: [f("sock", "🧦"), f("bus", "🚌"), f("hat", "🎩"), f("drum", "🥁"), f("fish", "🐟"), f("sun", "☀️")]),
    PSet(kind: .end, bib: "-ch", cue: f("beach", "🏖️"),
         yes: [f("peach", "🍑"), f("watch", "⌚"), f("church", "⛪")],
         no: [f("pear", "🍐"), f("sun", "☀️"), f("bell", "🔔"), f("sock", "🧦"), f("fish", "🐟"), f("hat", "🎩"), f("drum", "🥁")]),
    PSet(kind: .vowel, bib: "long a", cue: f("cake", "🍰"),
         yes: [f("grapes", "🍇"), f("train", "🚂"), f("snail", "🐌"), f("rain", "🌧️"), f("plane", "✈️"), f("snake", "🐍"), f("whale", "🐋"), f("skate", "⛸️")],
         no: [f("cat", "🐱"), f("hat", "🎩"), f("bat", "🦇"), f("apple", "🍎"), f("map", "🗺️"), f("crab", "🦀"), f("ant", "🐜"), f("can", "🥫"), f("van", "🚐")]),
    PSet(kind: .vowel, bib: "long i", cue: f("kite", "🪁"),
         yes: [f("bike", "🚲"), f("pie", "🥧"), f("ice", "🧊"), f("five", "5️⃣"), f("spider", "🕷️"), f("tiger", "🐯"), f("slide", "🛝")],
         no: [f("pig", "🐷"), f("fish", "🐟"), f("milk", "🥛"), f("gift", "🎁"), f("chick", "🐥"), f("six", "6️⃣"), f("pin", "📌")]),
    PSet(kind: .vowel, bib: "long o", cue: f("goat", "🐐"),
         yes: [f("boat", "⛵"), f("rose", "🌹"), f("nose", "👃"), f("phone", "☎️"), f("bone", "🦴")],
         no: [f("dog", "🐶"), f("fox", "🦊"), f("sock", "🧦"), f("lock", "🔒"), f("frog", "🐸"), f("rock", "🪨"), f("clock", "⏰"), f("box", "📦")]),
    PSet(kind: .vowel, bib: "long e", cue: f("bee", "🐝"),
         yes: [f("tree", "🌳"), f("key", "🔑"), f("cheese", "🧀"), f("peach", "🍑"), f("sheep", "🐑"), f("three", "3️⃣"), f("seal", "🦭"), f("leaf", "🍃")],
         no: [f("egg", "🥚"), f("bed", "🛏️"), f("bell", "🔔"), f("tent", "⛺"), f("pen", "🖊️"), f("ten", "🔟"), f("web", "🕸️")]),
]

// V — rhymes (words only). Spelling traps on both sides: "height" rhymes with night, "eight" doesn't.
// The bib shows the word itself, never a spelling pattern (kite rhymes with night but isn't -ight).
private let pRhymes: [PSet] = [
    PSet(kind: .rhyme, bib: "night", cue: f("night", "🌙"),
         yes: w("kite, light, white, bright, bite, height, fight"), no: w("eight, weight, net, knit, nut, nice, nine, neat")),
    PSet(kind: .rhyme, bib: "cat", cue: f("cat", "🐱"),
         yes: w("hat, bat, mat, flat, that, rat"), no: w("cut, kit, cap, cot, can, coat")),
    PSet(kind: .rhyme, bib: "cake", cue: f("cake", "🍰"),
         yes: w("lake, snake, make, bake, break, steak"), no: w("cook, back, kick, cape, cane, cap")),
    PSet(kind: .rhyme, bib: "bee", cue: f("bee", "🐝"),
         yes: w("tree, three, key, sea, me, ski"), no: w("bye, bay, bow, bed, buy, boy")),
    PSet(kind: .rhyme, bib: "sock", cue: f("sock", "🧦"),
         yes: w("clock, rock, knock, block, lock"), no: w("sack, sick, stuck, soak, sing")),
    PSet(kind: .rhyme, bib: "ring", cue: f("ring", "💍"),
         yes: w("king, sing, swing, wing, thing, spring"), no: w("rang, rung, ran, rain, rug")),
    PSet(kind: .rhyme, bib: "boat", cue: f("boat", "⛵"),
         yes: w("goat, coat, note, wrote, float, throat"), no: w("boot, bat, but, bought, bone")),
    PSet(kind: .rhyme, bib: "blue", cue: f("blue", "🔵"),
         yes: w("shoe, two, glue, flew, zoo, you, through"), no: w("blow, low, toe, bee, bell")),
    PSet(kind: .rhyme, bib: "sun", cue: f("sun", "☀️"),
         yes: w("fun, run, bun, one, done, won, ton"), no: w("sin, fan, soon, gone, on, seen")),
    PSet(kind: .rhyme, bib: "bear", cue: f("bear", "🐻"),
         yes: w("chair, hair, pear, square, where, there, air"), no: w("deer, bar, here, ear, fear")),
    PSet(kind: .rhyme, bib: "door", cue: f("door", "🚪"),
         yes: w("four, more, floor, store, roar, snore"), no: w("deer, dare, hour, star, dog")),
]

// VI — word parts by meaning. The "no" words merely LOOK like they have the part (uncle, ready).
private let pAffixes: [PSet] = [
    PSet(kind: .affix, bib: "un- im- in- dis-", cue: f("NOT", ""),
         yes: w("unhappy, unkind, unsafe, unfair, untrue, impossible, impolite, incorrect, dislike"),
         no: w("uncle, under, unicorn, insect, invite, inside, important, island, dish")),
    PSet(kind: .affix, bib: "re-", cue: f("AGAIN", ""),
         yes: w("redo, rewrite, refill, replay, reread, retell, rebuild"), no: w("ready, real, reach, red, river, rest")),
    PSet(kind: .affix, bib: "pre-", cue: f("BEFORE", ""),
         yes: w("preview, preheat, pretest, preschool"), no: w("pretty, press, prize, pray, prince")),
    PSet(kind: .affix, bib: "-ful", cue: f("FULL OF", ""),
         yes: w("joyful, helpful, careful, hopeful, playful, colorful, thankful"), no: w("bully, pull, fuel, follow, flute")),
    PSet(kind: .affix, bib: "-less", cue: f("WITHOUT", ""),
         yes: w("fearless, helpless, careless, sleepless, endless, toothless"), no: w("bless, unless, lesson, dress, chess")),
    PSet(kind: .affix, bib: "-er", cue: f("A PERSON WHO", ""),
         yes: w("teacher, baker, painter, farmer, singer, swimmer, writer"), no: w("water, river, under, never, paper, after, corner")),
    PSet(kind: .affix, bib: "-able", cue: f("CAN BE", ""),
         yes: w("washable, readable, breakable, bendable, fixable, drinkable"), no: w("table, cable, stable, fable, vegetable")),
    PSet(kind: .affix, bib: "mis-", cue: f("WRONGLY", ""),
         yes: w("misspell, misread, misplace, misbehave, misprint"), no: w("mist, mister, mitten, mixture, minute")),
]

// MARK: Rounds

private struct PRound {
    var kind: PKind = .letter
    var bib = ""
    var cue = f("", "")
    var foods: [PFood] = []
    var correct = 0
    var pictures = true      // show the food pictures
    var labels = false       // show the food names
    var key = ""             // repeat guard

    var right: PFood { foods.indices.contains(correct) ? foods[correct] : f("", "") }

    /// Spoken cue (auto once per round, and on 🔊).
    var say: String {
        switch kind {
        case .letter, .start: return "Feed me something that starts like… \(cue.word)!"
        case .end: return "Feed me something that ends like… \(cue.word)!"
        case .vowel: return "Feed me something with the \(bib) sound, like… \(cue.word)!"
        case .rhyme: return "Feed me a word that rhymes with… \(cue.word)!"
        case .affix: return "Feed me the word with a part that means… \(cue.word.lowercased())!"
        }
    }

    /// The bubble's small heading.
    var heading: String {
        switch kind {
        case .letter, .start: return "STARTS LIKE"
        case .end: return "ENDS LIKE"
        case .vowel: return "HAS THE VOWEL SOUND IN"
        case .rhyme: return "RHYMES WITH"
        case .affix: return "HAS A PART THAT MEANS"
        }
    }

    /// Shown after a miss: why the right plate was right.
    var why: String {
        let r = right
        let pic = pictures && !r.emoji.isEmpty ? r.emoji + " " : ""
        let cuePic = cue.emoji.isEmpty ? "" : cue.emoji + " "
        switch kind {
        case .letter, .start: return "\(pic)\(r.word) starts like \(cuePic)\(cue.word)"
        case .end: return "\(pic)\(r.word) ends like \(cuePic)\(cue.word)"
        case .vowel: return "\(pic)\(r.word) has the \(bib), like \(cuePic)\(cue.word)"
        case .rhyme: return "\(r.word) rhymes with \(cue.word)"
        case .affix:
            let part = bib.split(separator: " ").map(String.init).first { p in
                p.hasSuffix("-") ? r.word.hasPrefix(p.dropLast()) : r.word.hasSuffix(p.dropFirst())
            } ?? bib
            return "\(r.word): \(part) means \(cue.word)"
        }
    }
}

/// Choices per level: 2, then 3, then 4 from VII.
private func pChoices(_ level: Int) -> Int { level <= 1 ? 2 : level <= 6 ? 3 : 4 }

/// Seconds of patience per round (0 = none): none through IV, then 15 s easing to 7 s.
private func pPatience(_ level: Int) -> Double {
    switch level {
    case ...4: return 0
    case 5: return 15
    case 6: return 13
    case 7: return 11
    default: return max(7, 10 - Double(level - 8) * 0.5)
    }
}

private func pRound(level: Int, avoid: String) -> PRound {
    let n = pChoices(level)
    for _ in 0..<40 {
        let r = pRoundTry(level: level, n: n)
        if r.key != avoid && r.foods.count == n { return r }
    }
    return pRoundTry(level: level, n: n)
}

private func pRoundTry(level: Int, n: Int) -> PRound {
    if level <= 2 { return pLetterRound(level: level, n: n) }
    let sets: [PSet]
    switch level {
    case 3: sets = pStarts
    case 4: sets = pEnds
    case 5: sets = pRhymes
    case 6: sets = pAffixes
    case 7: sets = pRhymes + pAffixes
    default: sets = pStarts + pEnds + pRhymes + pAffixes
    }
    let s = sets.randomElement()!
    let right = s.yes.filter { $0.word != s.cue.word }.randomElement()!
    var foods = [right] + Array(s.no.filter { $0.word != s.cue.word }.shuffled().prefix(n - 1))
    foods.shuffle()
    let pictured = level <= 4 && s.kind != .rhyme && s.kind != .affix
    return PRound(kind: s.kind, bib: s.bib, cue: s.cue, foods: foods,
                  correct: foods.firstIndex(of: right) ?? 0,
                  pictures: pictured, labels: true, key: s.bib)
}

/// Levels I–II: the first sound. Wrong plates start with another letter AND another sound.
private func pLetterRound(level: Int, n: Int) -> PRound {
    let pool = level <= 1 ? pLetters.filter { !$0.easy.isEmpty } : pLetters
    let target = pool.randomElement()!
    let right = (level <= 1 ? target.easy : target.all).randomElement()!
    var others = pool.filter { $0.letter != target.letter && $0.sound != target.sound }
    if level <= 1 { others = others.filter { !pConfusable($0.sound, target.sound) } }
    var foods = [right]
    for o in others.shuffled() where foods.count < n {
        if let food = (level <= 1 ? o.easy : o.all).randomElement() { foods.append(food) }
    }
    foods.shuffle()
    return PRound(kind: .letter, bib: target.letter, cue: target.cue, foods: foods,
                  correct: foods.firstIndex(of: right) ?? 0,
                  pictures: true, labels: level >= 2, key: target.letter)
}

#if DEBUG
/// Self-check of the decks and the generator: run with LUDUS_SELFCHECK=1 (prints to the console).
private func pSelfCheck() {
    var problems: [String] = []
    for g in pLetters {
        for food in g.all where !food.word.hasPrefix(g.letter) { problems.append("\(food.word) not \(g.letter)") }
        for food in g.all where ["ch", "sh", "th", "wh", "ph"].contains(where: { food.word.hasPrefix($0) }) {
            problems.append("\(food.word) starts with a digraph")
        }
        if !g.cue.word.hasPrefix(g.letter) { problems.append("cue \(g.cue.word)") }
    }
    for s in pStarts + pEnds + pRhymes + pAffixes {
        let yes = Set(s.yes.map(\.word)), no = Set(s.no.map(\.word))
        if !yes.isDisjoint(with: no) { problems.append("\(s.bib) overlap \(yes.intersection(no))") }
        if s.no.count < 3 { problems.append("\(s.bib) needs ≥3 wrong words") }
        switch s.kind {
        case .start:
            for y in yes where !y.hasPrefix(s.bib) { problems.append("\(y) !\(s.bib)") }
            for x in no where x.hasPrefix(s.bib) { problems.append("trap \(x) is \(s.bib)") }
            if !s.cue.word.hasPrefix(s.bib) { problems.append("cue \(s.cue.word)") }
        case .end:
            let tail = String(s.bib.dropFirst())
            for y in yes where !y.hasSuffix(tail) { problems.append("\(y) !\(s.bib)") }
            for x in no where x.hasSuffix(tail) || (tail == "ck" && x.hasSuffix("k")) { problems.append("trap \(x) is \(s.bib)") }
        case .affix:
            let parts = s.bib.split(separator: " ").map(String.init)
            for y in yes where !parts.contains(where: { $0.hasSuffix("-") ? y.hasPrefix($0.dropLast()) : y.hasSuffix($0.dropFirst()) }) {
                problems.append("\(y) lacks \(s.bib)")
            }
        default: break
        }
    }
    // Every generated round: n distinct plates, exactly the one marked right is from the right list.
    for level in 1...10 {
        for _ in 0..<500 {
            let r = pRound(level: level, avoid: "")
            if r.foods.count != pChoices(level) { problems.append("L\(level) \(r.bib) has \(r.foods.count) plates") }
            if Set(r.foods.map(\.word)).count != r.foods.count || Set(r.foods.map(\.emoji)).count != r.foods.count && r.pictures {
                problems.append("L\(level) duplicate plate \(r.foods.map(\.word))")
            }
            let rights: Int
            if r.kind == .letter {
                let g = pLetters.first { $0.letter == r.bib }!
                rights = r.foods.filter { food in pLetters.contains { $0.sound == g.sound && $0.all.contains(food) } }.count
            } else {
                let s = (pStarts + pEnds + pRhymes + pAffixes).first { $0.bib == r.bib }!
                rights = r.foods.filter { s.yes.contains($0) }.count
                if r.foods.contains(where: { $0.word == s.cue.word }) { problems.append("cue offered \(s.cue.word)") }
            }
            if rights != 1 { problems.append("L\(level) \(r.bib) has \(rights) right plates: \(r.foods.map(\.word))") }
        }
    }
    print("POLY SELFCHECK: \(problems.isEmpty ? "OK" : problems.joined(separator: " | "))")
}
#endif

// MARK: - Model

@MainActor
private final class PolyModel: ArcadeModel {
    enum Stage { case waiting, chomp, yuck, spit, reveal, gulp }

    @Published var round = PRound()
    @Published var roundID = 0
    @Published var stage: Stage = .waiting
    @Published var fed: Int?
    @Published var deadline: Date?
    @Published var tooSlow = false

    private var gen = 0
    private var timeout: DispatchWorkItem?

    init() {
        super.init(key: GameID.polyphemus.rawValue)
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { pSelfCheck() }
        #endif
    }

    var patience: Double { pPatience(level) }

    override func onBegin() { next() }

    private func next() {
        gen += 1
        timeout?.cancel(); timeout = nil
        round = pRound(level: level, avoid: round.key)
        roundID += 1
        fed = nil; tooSlow = false
        stage = .waiting
        if patience > 0 {
            deadline = Date().addingTimeInterval(patience)
            let g = gen
            let item = DispatchWorkItem { [weak self] in
                guard let self, self.gen == g, self.phase == .playing, self.stage == .waiting else { return }
                self.timedOut()
            }
            timeout = item
            DispatchQueue.main.asyncAfter(deadline: .now() + patience, execute: item)
        } else {
            deadline = nil
        }
        LibraryVoice.say(round.say)
    }

    /// Run `step` after `t` s, unless the round or run has moved on.
    private func later(_ t: Double, _ step: @escaping (PolyModel) -> Void) {
        let g = gen
        DispatchQueue.main.asyncAfter(deadline: .now() + t) { [weak self] in
            guard let self, self.gen == g, self.phase == .playing else { return }
            step(self)
        }
    }

    /// Feed plate `i` (a drag's drop, a tap at I–II, and the bot all land here).
    func feed(_ i: Int) {
        guard phase == .playing, stage == .waiting, round.foods.indices.contains(i) else { return }
        timeout?.cancel(); deadline = nil
        fed = i
        if i == round.correct {
            stage = .chomp
            hit()
            later(1.0) { $0.next() }
        } else {
            stage = .yuck
            miss(delay: 3.1)
            LibraryVoice.say("Bleh!", rate: 0.5)
            reveal(after: 0.6)
        }
    }

    private func timedOut() {
        deadline = nil
        tooSlow = true
        stage = .yuck
        miss(reason: "Too slow!", delay: 2.6)
        reveal(after: 0.1)
    }

    /// Spit the wrong plate, then show and gulp the right one.
    private func reveal(after t: Double) {
        later(t) { $0.stage = .spit }
        later(t + 0.5) { m in m.stage = .reveal; LibraryVoice.say(m.round.why.filter { $0.isLetter || $0 == " " || $0 == "-" || $0 == ":" }) }
        later(t + 1.9) { $0.stage = .gulp }
        later(t + 2.6) { m in if !m.dying { m.next() } }
    }

    func sayCue() { LibraryVoice.say(round.say) }

    override func botAct(correct: Bool) {
        guard stage == .waiting, !round.foods.isEmpty else { return }
        let wrong = round.foods.indices.filter { $0 != round.correct }
        feed(correct || wrong.isEmpty ? round.correct : wrong.randomElement()!)
    }
}

// MARK: - Views

struct PolyphemusView: View {
    let onClose: () -> Void
    @StateObject private var model = PolyModel()

    var body: some View {
        ArcadeShell(model: model,
                    spec: GameID.polyphemus.spec ?? GameSpec(title: "Polyphemus Is Hungry", mechanic: "", premise: "", game: .polyphemus),
                    accent: Lu.mint, onClose: { LibraryVoice.stop(); onClose() }) {
            PolyPlay(model: model)
        }
        .onDisappear { LibraryVoice.stop() }
    }
}

private struct PolyFrames: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}
private let pMouthKey = -1, pBodyKey = -2

private struct PolyPlay: View {
    @ObservedObject var model: PolyModel

    @State private var frames: [Int: CGRect] = [:]
    @State private var dragIndex: Int?
    @State private var dragOffset: CGSize = .zero
    @State private var dragPoint: CGPoint?
    @State private var chew = false
    @State private var shakes: CGFloat = 0
    @State private var hop = false

    private var mouth: CGRect { frames[pMouthKey] ?? .zero }
    private var bodyFrame: CGRect { frames[pBodyKey] ?? .zero }
    private var r: PRound { model.round }

    var body: some View {
        VStack(spacing: 8) {
            Color.clear.frame(height: 56)
            patienceBar
            bubble
            cyclops
                .frame(maxHeight: .infinity)
            plates
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 14)
        .coordinateSpace(name: "poly")
        .onPreferenceChange(PolyFrames.self) { frames = $0 }
        .onChange(of: model.stage) { s in
            if s == .chomp || s == .gulp { chewSequence() }
            if s == .yuck { withAnimation(.linear(duration: 0.5)) { shakes += 1 } }
            if s == .chomp { withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { hop = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { withAnimation(.spring()) { hop = false } } }
        }
        .onChange(of: model.roundID) { _ in dragIndex = nil; dragOffset = .zero; dragPoint = nil }
    }

    private func chewSequence() {
        for k in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + Double(k) * 0.13) {
                withAnimation(.easeInOut(duration: 0.11)) { chew = k % 2 == 0 }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) { chew = false }
    }

    // MARK: Patience

    @ViewBuilder private var patienceBar: some View {
        let per = model.patience
        TimelineView(.animation(minimumInterval: 0.1, paused: model.phase != .playing || model.deadline == nil)) { tl in
            let left = model.deadline.map { max(0, $0.timeIntervalSince(tl.date)) } ?? 0
            let frac = per > 0 ? CGFloat(left / per) : 0
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: Lu.panel))
                    Capsule().fill(Color(hex: frac < 0.3 ? Lu.coral : Lu.mint))
                        .frame(width: max(0, g.size.width * frac))
                }
            }
        }
        .frame(height: 8)
        .opacity(per > 0 ? 1 : 0)
    }

    // MARK: Speech bubble — the cue

    private var bubble: some View {
        ZStack {
            HStack(spacing: 12) {
                if r.kind == .letter {
                    Text(r.bib.uppercased() + r.bib)
                        .font(luSerif(44, .black)).foregroundStyle(Color(hex: Lu.inkDark))
                        .lineLimit(1).minimumScaleFactor(0.6)
                        .padding(.horizontal, 12)
                        .frame(minWidth: 84, minHeight: 70)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: Lu.gold)))
                } else if r.kind != .affix && r.kind != .rhyme {
                    Text(r.bib).font(luSerif(r.bib.count > 4 ? 26 : 38, .black)).foregroundStyle(Color(hex: Lu.inkDark))
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .padding(.horizontal, 10)
                        .frame(minWidth: 70, minHeight: 64)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: Lu.gold)))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.level <= 1 ? "LIKE" : r.heading)
                        .font(luFont(11, .heavy)).tracking(1.2).foregroundStyle(Color(hex: Lu.inkDim))
                    HStack(spacing: 8) {
                        if !r.cue.emoji.isEmpty { Text(r.cue.emoji).font(.system(size: 50)) }
                        if model.level >= 2 || r.cue.emoji.isEmpty {
                            Text(r.cue.word)
                                .font(luFont(r.kind == .affix ? 26 : 24)).foregroundStyle(Color(hex: Lu.ink))
                                .lineLimit(2).minimumScaleFactor(0.6)
                        }
                    }
                    if r.kind == .affix {
                        Text(r.bib).font(luFont(15, .bold)).foregroundStyle(Color(hex: Lu.gold))
                    }
                }
                Spacer(minLength: 0)
                LibrarySpeakerButton(size: 48) { model.sayCue() }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .opacity(showWhy ? 0 : 1)

            if showWhy {
                Text(model.tooSlow ? "Too slow! " + r.why : r.why)
                    .font(luFont(20, .heavy)).foregroundStyle(Color(hex: Lu.mint))
                    .multilineTextAlignment(.center).minimumScaleFactor(0.6).lineLimit(2)
                    .padding(.horizontal, 12)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(luPanelShape(20))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showWhy)
    }

    private var showWhy: Bool { model.stage == .reveal || model.stage == .gulp }

    // MARK: The Cyclops

    private var cyclops: some View {
        let mood: CyclopsFace.Mood = {
            switch model.stage {
            case .chomp, .gulp: return .happy
            case .yuck, .spit: return .yuck
            case .reveal: return .sad
            case .waiting: return dragIndex != nil ? .hungry : .idle
            }
        }()
        let open: CGFloat = {
            switch model.stage {
            case .chomp, .gulp: return chew ? 0.15 : 0.9
            case .yuck: return 0.55
            case .spit: return 1
            case .reveal: return 0.2
            case .waiting:
                guard let p = dragPoint else { return 0.25 }
                let d = hypot(p.x - mouth.midX, p.y - mouth.midY)
                return d < 160 ? 1 : 0.6
            }
        }()
        let look: CGPoint = {
            guard let p = dragPoint, mouth != .zero else { return CGPoint(x: 0, y: 0.6) }
            let dx = p.x - mouth.midX, dy = p.y - (mouth.midY - 70)
            let len = max(1, hypot(dx, dy))
            return CGPoint(x: dx / len, y: dy / len)
        }()
        return ZStack(alignment: .top) {
            CyclopsFace(mood: mood, open: open, look: look, belly: 1 + CGFloat(min(model.combo, 5)) * 0.045,
                        bib: r.kind == .letter ? r.bib.uppercased() + r.bib : r.bib)
                .modifier(LibraryShake(amount: 10, shakes: shakes))
                .scaleEffect(x: hop ? 1.06 : 1, y: hop ? 0.94 : 1, anchor: .bottom)
                .background(GeometryReader { g in
                    Color.clear.preference(key: PolyFrames.self, value: [pBodyKey: g.frame(in: .named("poly"))])
                })
            exclaim
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: model.combo)
    }

    @ViewBuilder private var exclaim: some View {
        let text: String? = {
            switch model.stage {
            case .chomp: return model.combo > 0 && model.combo % 5 == 0 ? "BURP!" : ["YUM!", "MMM!", "CHOMP!"][model.roundID % 3]
            case .yuck, .spit: return "BLEH!"
            case .gulp: return "GULP!"
            default: return nil
            }
        }()
        if let text {
            Text(text)
                .font(luFont(30)).foregroundStyle(Color(hex: text == "BLEH!" ? Lu.mint : Lu.gold))
                .rotationEffect(.degrees(-10))
                .offset(x: 92, y: 4)
                .transition(.scale(scale: 0.3).combined(with: .opacity))
                .id(text + "\(model.roundID)")
        }
    }

    // MARK: Plates

    private var plates: some View {
        let n = r.foods.count
        let rows: [[Int]] = n == 4 ? [[0, 1], [2, 3]] : [Array(0..<n)]
        let tall: CGFloat = n == 2 ? 132 : (n == 3 ? (r.pictures ? 124 : 96) : (r.pictures ? 100 : 76))
        return VStack(spacing: 10) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { i in plate(i, height: tall).zIndex(dragIndex == i ? 2 : 0) }
                }
                .zIndex(row.contains(dragIndex ?? -9) ? 2 : 0)
            }
        }
        .id(model.roundID)
    }

    private func plate(_ i: Int, height: CGFloat) -> some View {
        let food = r.foods[i]
        let isRight = i == r.correct
        let glow = (model.stage == .reveal || model.stage == .gulp) && isRight
        return PlateView(food: food, pictures: r.pictures, labels: r.labels, height: height, glow: glow,
                         wrong: model.fed == i && !isRight)
            .scaleEffect(plateScale(i))
            .rotationEffect(.degrees(model.fed == i && !isRight && (model.stage == .spit || model.stage == .reveal || model.stage == .gulp) ? 540 : 0))
            .offset(plateOffset(i))
            .opacity(plateOpacity(i))
            .animation(model.stage == .spit ? .easeIn(duration: 0.55) : .spring(response: 0.42, dampingFraction: 0.78), value: model.stage)
            .animation(.interactiveSpring(), value: dragOffset)
            .onTapGesture {
                LibraryVoice.say(food.word)
                // Gradus I–II: a tap feeds the plate too (small hands needn't drag).
                if model.level <= 2 && model.stage == .waiting && model.phase == .playing {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { model.feed(i) }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 4, coordinateSpace: .named("poly"))
                    .onChanged { v in
                        guard model.stage == .waiting, model.phase == .playing else { return }
                        if dragIndex == nil { Haptics.light() }
                        dragIndex = i; dragOffset = v.translation; dragPoint = v.location
                    }
                    .onEnded { v in
                        guard dragIndex == i else { return }
                        dragPoint = nil
                        if model.stage == .waiting && bodyFrame.insetBy(dx: -28, dy: -28).contains(v.location) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                dragIndex = nil
                                model.feed(i)
                            }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { dragIndex = nil; dragOffset = .zero }
                        }
                    }
            )
            .allowsHitTesting(model.stage == .waiting)
            // Measured on an untransformed wrapper, so the fly-to-mouth offset can't feed back into it.
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
            .background(GeometryReader { g in
                Color.clear.preference(key: PolyFrames.self, value: [i: g.frame(in: .named("poly"))])
            })
    }

    private func toMouth(_ i: Int) -> CGSize {
        guard let fr = frames[i], mouth != .zero else { return .zero }
        return CGSize(width: mouth.midX - fr.midX, height: mouth.midY - fr.midY)
    }

    private func plateOffset(_ i: Int) -> CGSize {
        let isFed = model.fed == i, isRight = i == r.correct
        switch model.stage {
        case .waiting: return dragIndex == i ? dragOffset : .zero
        case .chomp: return isFed ? toMouth(i) : .zero
        case .yuck: return isFed ? toMouth(i) : .zero
        case .spit, .reveal:
            if isFed { let fr = frames[i] ?? .zero; return CGSize(width: (fr.midX < mouth.midX ? -1 : 1) * 560, height: -420) }
            return .zero
        case .gulp:
            if isRight { return toMouth(i) }
            if isFed { return CGSize(width: 560, height: -420) }
            return .zero
        }
    }

    private func plateScale(_ i: Int) -> CGFloat {
        let isFed = model.fed == i, isRight = i == r.correct
        switch model.stage {
        case .waiting: return dragIndex == i ? 1.08 : 1
        case .chomp: return isFed ? 0.1 : 1
        case .yuck: return isFed ? 0.45 : 1
        case .spit, .reveal: return isFed ? 0.6 : (isRight && model.stage == .reveal ? 1.08 : 1)
        case .gulp: return isRight ? 0.1 : 1
        }
    }

    private func plateOpacity(_ i: Int) -> Double {
        let isFed = model.fed == i, isRight = i == r.correct
        switch model.stage {
        case .chomp: return isFed ? 0 : 0.5
        case .gulp: return isRight ? 0 : 0.4
        case .reveal: return isRight || isFed ? 1 : 0.4
        default: return 1
        }
    }
}

/// One food on a plate: a big picture and/or its name.
private struct PlateView: View {
    let food: PFood
    let pictures: Bool, labels: Bool
    let height: CGFloat
    let glow: Bool, wrong: Bool

    var body: some View {
        VStack(spacing: 2) {
            if pictures && !food.emoji.isEmpty {
                Text(food.emoji).font(.system(size: labels ? height * 0.46 : height * 0.56))
            }
            if labels {
                Text(food.word)
                    .font(luFont(pictures ? 17 : 22, .heavy)).foregroundStyle(Color(hex: Lu.ink))
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22).fill(LinearGradient(colors: [Color(hex: Lu.panel2), Color(hex: Lu.panel)],
                                                                        startPoint: .top, endPoint: .bottom))
                Ellipse().stroke(Color(hex: Lu.ink).opacity(0.12), lineWidth: 3).padding(10)   // the plate rim
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: glow ? Lu.mint : (wrong ? Lu.coral : Lu.line)), lineWidth: glow ? 5 : 2))
        .shadow(color: glow ? Color(hex: Lu.mint).opacity(0.7) : .clear, radius: 12)
        .contentShape(Rectangle())
    }
}

/// Polyphemus, built from shapes: one huge eye, a unibrow, a mouth that gapes and chews, a
/// tunic with his bib (the sound he wants), and a belly that swells as the streak grows.
private struct CyclopsFace: View {
    enum Mood { case idle, hungry, happy, yuck, sad }
    let mood: Mood
    let open: CGFloat            // mouth 0 … 1
    let look: CGPoint            // pupil direction (unit-ish)
    let belly: CGFloat
    let bib: String

    private var skin: [Color] {
        mood == .yuck ? [Color(hex: 0xb9d98c), Color(hex: 0x7fae5e)] : [Color(hex: 0xf6caa0), Color(hex: 0xd9976a)]
    }

    var body: some View {
        ZStack {
            // Body + tunic + bib
            ZStack {
                Ellipse().fill(LinearGradient(colors: skin, startPoint: .top, endPoint: .bottom))
                    .frame(width: 200 * belly, height: 140)
                Ellipse().fill(LinearGradient(colors: [Color(hex: Lu.coral), luShade(Lu.coral, -40)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 200 * belly, height: 140)
                    .mask(Rectangle().frame(height: 96).offset(y: 30))
                // Arms
                Capsule().fill(LinearGradient(colors: skin, startPoint: .top, endPoint: .bottom))
                    .frame(width: 34, height: 92).rotationEffect(.degrees(mood == .happy ? -40 : 18))
                    .offset(x: -104 * belly, y: -6)
                Capsule().fill(LinearGradient(colors: skin, startPoint: .top, endPoint: .bottom))
                    .frame(width: 34, height: 92).rotationEffect(.degrees(mood == .happy ? 40 : -18))
                    .offset(x: 104 * belly, y: -6)
                // Bib
                Text(bib)
                    .font(luSerif(bib.count > 4 ? 15 : 28, .black)).foregroundStyle(Color(hex: Lu.inkDark))
                    .lineLimit(1).minimumScaleFactor(0.4)
                    .frame(width: 92, height: 54)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0xfdf6e3)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: Lu.goldLine), lineWidth: 2))
                    .offset(y: -8)
            }
            .offset(y: 92)

            // Head
            ZStack {
                // Hair tufts
                ForEach(0..<3) { k in
                    Ellipse().fill(Color(hex: 0x4a2f1e)).frame(width: 34, height: 26)
                        .rotationEffect(.degrees(Double(k - 1) * 28))
                        .offset(x: CGFloat(k - 1) * 26, y: -78)
                }
                // Ears
                Circle().fill(skin[1]).frame(width: 34).offset(x: -80, y: 4)
                Circle().fill(skin[1]).frame(width: 34).offset(x: 80, y: 4)
                Circle().fill(LinearGradient(colors: skin, startPoint: .top, endPoint: .bottom)).frame(width: 172)
                // Cheeks
                Circle().fill(Color(hex: Lu.coral).opacity(0.35)).frame(width: 30).offset(x: -54, y: 30)
                Circle().fill(Color(hex: Lu.coral).opacity(0.35)).frame(width: 30).offset(x: 54, y: 30)
                eye.offset(y: -18)
                // Unibrow
                Capsule().fill(Color(hex: 0x4a2f1e)).frame(width: 96, height: 13)
                    .rotationEffect(.degrees(mood == .yuck ? 8 : (mood == .sad ? -8 : 0)))
                    .offset(y: mood == .hungry ? -76 : -66)
                mouthView.offset(y: 46)
            }
            .offset(y: -52)
        }
        .frame(width: 260, height: 300)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: mood)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: open)
    }

    @ViewBuilder private var eye: some View {
        if mood == .happy {
            // A closed, smiling eye: ^
            HappyEyeArc().stroke(Color(hex: 0x3a2412), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 70, height: 30)
        } else {
            ZStack {
                Ellipse().fill(Color.white).frame(width: 88, height: 80)
                Circle().fill(RadialGradient(colors: [Color(hex: 0x8a5a2b), Color(hex: 0x4a2f1e)], center: .center, startRadius: 2, endRadius: 22))
                    .frame(width: 42)
                    .overlay(Circle().fill(Color.black).frame(width: mood == .hungry ? 26 : 18))
                    .overlay(Circle().fill(Color.white).frame(width: 8).offset(x: -6, y: -7))
                    .offset(x: look.x * 16, y: look.y * 14)
                if mood == .yuck || mood == .sad {
                    // a droopy lid
                    Rectangle().fill(skin[0]).frame(width: 92, height: 34).offset(y: -26)
                }
            }
            .frame(width: 88, height: 80)
            .clipShape(Ellipse())
            .overlay(Ellipse().stroke(Color(hex: 0x3a2412).opacity(0.5), lineWidth: 3))
        }
    }

    private var mouthView: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x5a1a1a))
                .frame(width: 66 + open * 18, height: 10 + open * 40)
            // Teeth
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2).fill(Color.white).frame(width: 12, height: 10)
                RoundedRectangle(cornerRadius: 2).fill(Color.white).frame(width: 12, height: 10)
            }
            .offset(y: -(open * 20) + 1)
            .opacity(open > 0.3 ? 1 : 0)
            if mood == .yuck {
                Ellipse().fill(Color(hex: 0xe77f8f)).frame(width: 26, height: 22).offset(x: 6, y: 18 + open * 10)
            }
        }
        .background(GeometryReader { g in
            Color.clear.preference(key: PolyFrames.self, value: [pMouthKey: g.frame(in: .named("poly"))])
        })
    }
}

private struct HappyEyeArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.6))
        return p
    }
}
