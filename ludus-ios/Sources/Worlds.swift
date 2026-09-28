import SwiftUI

// MARK: - Worlds catalog + game routing
//
// The arcade is organised into subject "worlds", each holding a handful of games. A game
// with a non-nil `game: GameID` is playable now; nil is a "coming soon" tile so the whole
// shape of the arcade is visible even before every mechanic exists.

enum GameID: String, Identifiable, Hashable {
    case bubbleEvens, timesTableNinja, stackAttack
    case flagFrenzy, nameCountry
    case wordSort, synonymSnake
    case trueFalseBlitz, oddOneOut, patternPop
    case critterSort
    case timeline
    case coinCount
    var id: String { rawValue }
}

/// Maps a game id to its full-screen view. The per-game best-score key is the raw value.
@ViewBuilder
func ludusGame(_ id: GameID, onClose: @escaping () -> Void) -> some View {
    switch id {
    case .bubbleEvens:     BubbleEvensView(onClose: onClose)
    case .timesTableNinja: TimesTableNinjaView(onClose: onClose)
    case .stackAttack:     StackAttackView(onClose: onClose)
    case .flagFrenzy:      FlagFrenzyView(onClose: onClose)
    case .nameCountry:     NameCountryView(onClose: onClose)
    case .wordSort:        WordSortView(onClose: onClose)
    case .synonymSnake:    SynonymSnakeView(onClose: onClose)
    case .trueFalseBlitz:  TrueFalseBlitzView(onClose: onClose)
    case .oddOneOut:       OddOneOutView(onClose: onClose)
    case .patternPop:      PatternPopView(onClose: onClose)
    case .critterSort:     CritterSortView(onClose: onClose)
    case .timeline:        TimeOrderView(onClose: onClose)
    case .coinCount:       CoinCountView(onClose: onClose)
    }
}

struct GameSpec: Identifiable, Hashable {
    let title: String
    let mechanic: String
    let premise: String
    let game: GameID?     // nil = coming soon
    var id: String { title }
    var playable: Bool { game != nil }
}

struct LudusWorld: Identifiable, Hashable {
    let name: String
    let subject: String
    let emoji: String
    let colorHex: UInt
    let games: [GameSpec]
    var id: String { name }
    var playableCount: Int { games.filter { $0.playable }.count }
}

let ludusWorlds: [LudusWorld] = [
    LudusWorld(name: "Number Crunchers", subject: "Math", emoji: "🔢", colorHex: Lu.coral, games: [
        .init(title: "Bubble Evens", mechanic: "pop", premise: "Pop the evens before they escape.", game: .bubbleEvens),
        .init(title: "Times Table Ninja", mechanic: "slash", premise: "Slice the correct multiples, dodge the bombs.", game: .timesTableNinja),
        .init(title: "Stack Attack", mechanic: "stacker", premise: "Answer to stack blocks — how high can you go?", game: .stackAttack),
        .init(title: "Coin Climber", mechanic: "elevator", premise: "Solve to climb; miss and you drop.", game: nil),
    ]),
    LudusWorld(name: "Globe Trotters", subject: "Geography", emoji: "🌍", colorHex: Lu.sky, games: [
        .init(title: "Flag Frenzy", mechanic: "pop", premise: "Tap the flags from the called-out continent.", game: .flagFrenzy),
        .init(title: "Orbis", mechanic: "map", premise: "Name the country from its outline.", game: .nameCountry),
        .init(title: "Pin Drop", mechanic: "map-dart", premise: "Tap the country on the map, fast.", game: nil),
        .init(title: "Border Snake", mechanic: "snake", premise: "Eat every country that borders the target.", game: nil),
    ]),
    LudusWorld(name: "Word Wizards", subject: "Language Arts", emoji: "✏️", colorHex: Lu.mint, games: [
        .init(title: "Word Sort", mechanic: "lane-sorter", premise: "Drop each word into noun or verb.", game: .wordSort),
        .init(title: "Synonym Snake", mechanic: "snake", premise: "Eat the synonyms, avoid the antonyms.", game: .synonymSnake),
        .init(title: "Spell Sprint", mechanic: "runner", premise: "Run through the correct next letter.", game: nil),
    ]),
    LudusWorld(name: "Brain Benders", subject: "Logic & Puzzles", emoji: "🧩", colorHex: Lu.grape, games: [
        .init(title: "True / False Blitz", mechanic: "quick-fire", premise: "Snap-judge each statement, true or false.", game: .trueFalseBlitz),
        .init(title: "Odd One Out", mechanic: "quick-fire", premise: "Tap the one that doesn't belong.", game: .oddOneOut),
        .init(title: "Pattern Pop", mechanic: "quick-fire", premise: "Tap what comes next in the sequence.", game: .patternPop),
    ]),
    LudusWorld(name: "Lab Rats", subject: "Science", emoji: "🔬", colorHex: Lu.tangerine, games: [
        .init(title: "Critter Sort", mechanic: "lane-sorter", premise: "Sort each animal — mammal, bird, or reptile.", game: .critterSort),
        .init(title: "Planet Dash", mechanic: "catch", premise: "Catch the planets in order from the sun.", game: nil),
    ]),
    LudusWorld(name: "Time Travelers", subject: "History", emoji: "🏛️", colorHex: Lu.gold, games: [
        .init(title: "Timeline", mechanic: "order", premise: "Which came first? Put history in order.", game: .timeline),
    ]),
    LudusWorld(name: "The Money Stall", subject: "Money & Life Skills", emoji: "🪙", colorHex: Lu.gold, games: [
        .init(title: "Coin Count", mechanic: "count", premise: "Add up the coins — how much?", game: .coinCount),
        .init(title: "Coin Rain", mechanic: "lane-sorter", premise: "Sort the coins by value as they fall.", game: nil),
    ]),
    LudusWorld(name: "Sound Lab", subject: "Music", emoji: "🎵", colorHex: Lu.coral, games: [
        .init(title: "Note Ninja", mechanic: "slash", premise: "Slice the named note on the staff.", game: nil),
        .init(title: "Rhythm Tap", mechanic: "rhythm", premise: "Tap the beat as it scrolls by.", game: nil),
    ]),
]
