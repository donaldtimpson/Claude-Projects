import SwiftUI

// MARK: - Worlds catalog + game routing
//
// The arcade is organised into subject "worlds" (one per landmark on the map), each holding a
// handful of games. A game with a non-nil `game: GameID` is playable; nil = not built yet (the
// landing page hides it). Each entry carries what the landing page and intro card show: an
// emblem, a one-line premise, 2–3 picture-led "how to play" lines and the laurel goals (GameKit).

enum GameID: String, Identifiable, Hashable {
    // Temple · Math
    case bubbleEvens, timesTableNinja, stackAttack, lupaChomp, omnibus
    // Lighthouse · Geography
    case flagFrenzy, nameCountry, pharosBeam, zooFerry
    // Library · Language Arts
    case wordSort, synonymSnake, polyphemus, scrollCatcher
    // Colosseum · Logic
    case trueFalseBlitz, oddOneOut, patternPop, portaCustos, torches
    // Vesuvius · Science
    case critterSort, dressMarcus, zookeeper
    // Forum · History
    case timeline, timeGuard, caesarWheel
    // Market · Money
    case coinCount, figStall, porcus
    // Theatre · Music
    case pianoMouse, maestroMouse, comedyTragedy
    var id: String { rawValue }
}

/// Maps a game id to its full-screen view. The per-game best-score key is the raw value.
@ViewBuilder
func ludusGame(_ id: GameID, onClose: @escaping () -> Void) -> some View {
    switch id {
    case .bubbleEvens:     BubbleEvensView(onClose: onClose)
    case .timesTableNinja: TimesTableNinjaView(onClose: onClose)
    case .stackAttack:     StackAttackView(onClose: onClose)
    case .lupaChomp:       LupaChompView(onClose: onClose)
    case .omnibus:         OmnibusView(onClose: onClose)
    case .flagFrenzy:      FlagFrenzyView(onClose: onClose)
    case .nameCountry:     NameCountryView(onClose: onClose)
    case .pharosBeam:      PharosBeamView(onClose: onClose)
    case .zooFerry:        ZooFerryView(onClose: onClose)
    case .wordSort:        WordSortView(onClose: onClose)
    case .synonymSnake:    SynonymSnakeView(onClose: onClose)
    case .polyphemus:      ComingSoonGame(id: id, onClose: onClose)
    case .scrollCatcher:   ComingSoonGame(id: id, onClose: onClose)
    case .trueFalseBlitz:  TrueFalseBlitzView(onClose: onClose)
    case .oddOneOut:       OddOneOutView(onClose: onClose)
    case .patternPop:      PatternPopView(onClose: onClose)
    case .portaCustos:     PortaCustosView(onClose: onClose)
    case .torches:         TorchesView(onClose: onClose)
    case .critterSort:     CritterSortView(onClose: onClose)
    case .dressMarcus:     ComingSoonGame(id: id, onClose: onClose)
    case .zookeeper:       ComingSoonGame(id: id, onClose: onClose)
    case .timeline:        TimeOrderView(onClose: onClose)
    case .timeGuard:       ComingSoonGame(id: id, onClose: onClose)
    case .caesarWheel:     ComingSoonGame(id: id, onClose: onClose)
    case .coinCount:       CoinCountView(onClose: onClose)
    case .figStall:        FigStallView(onClose: onClose)
    case .porcus:          PorcusView(onClose: onClose)
    case .pianoMouse:      ComingSoonGame(id: id, onClose: onClose)
    case .maestroMouse:    ComingSoonGame(id: id, onClose: onClose)
    case .comedyTragedy:   ComingSoonGame(id: id, onClose: onClose)
    }
}

/// Placeholder for a game whose id exists but whose view isn't built yet.
struct ComingSoonGame: View {
    let id: GameID
    let onClose: () -> Void
    var body: some View {
        ZStack {
            LudusBackground().ignoresSafeArea()
            VStack(spacing: 16) {
                Text(id.spec?.icon ?? "🚧").font(.system(size: 64))
                Text("Coming soon").font(luSerif(28, .black)).foregroundStyle(Color(hex: Lu.ink))
                LudusButton(title: "Back", action: onClose)
            }
        }
    }
}

struct GameSpec: Identifiable, Hashable {
    let title: String
    let mechanic: String
    let premise: String
    let game: GameID?     // nil = not built yet
    var icon: String = "🎲"               // the game's emblem (landing page, intro card)
    var howTo: [HowTo] = []               // 2–3 short lines for the intro card
    var goal: GameGoal = .standard        // laurel levels (GameKit)
    var id: String { title }
    var playable: Bool { game != nil }
    /// Won = the bronze laurel (reached `goal.won`) — what gilds a seal-ring segment.
    var won: Bool { game.map { LudusProgress.won($0.rawValue, goal: goal) } ?? false }
    var medal: Medal { game.map { LudusProgress.medal($0.rawValue, goal: goal) } ?? .none }
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

private func how(_ pairs: (String, String)...) -> [HowTo] { pairs.map { HowTo(icon: $0.0, text: $0.1) } }

let ludusWorlds: [LudusWorld] = [
    LudusWorld(name: "Number Crunchers", subject: "Math", emoji: "🔢", colorHex: Lu.coral, games: [
        .init(title: "Lupa Chomp", mechanic: "compare", premise: "The she-wolf always eats the bigger pile.", game: .lupaChomp,
              icon: "🐺", howTo: how(("👀", "Look at the two piles"), ("👆", "Tap the BIGGER one"), ("🐺", "Feed the wolf!"))),
        .init(title: "Omnibus Driver", mechanic: "story-sum", premise: "Passengers hop on and off — how many are riding?", game: .omnibus,
              icon: "🚌", howTo: how(("🫏", "Watch the bus stop"), ("👀", "Who gets on? Who gets off?"), ("🔢", "Tap how many are riding"))),
        .init(title: "Bubble Evens", mechanic: "pop", premise: "Pop the evens before they escape.", game: .bubbleEvens,
              icon: "🫧", howTo: how(("👆", "Pop the EVEN numbers"), ("🙅", "Let the odd ones float away"))),
        .init(title: "Times Table Ninja", mechanic: "slash", premise: "Slice the correct multiples, dodge the bombs.", game: .timesTableNinja,
              icon: "🥷", howTo: how(("👉", "Swipe through the right numbers"), ("💣", "Don't slice the bombs"))),
        .init(title: "Stack Attack", mechanic: "stacker", premise: "Answer to stack blocks — how high can you go?", game: .stackAttack,
              icon: "🧱", howTo: how(("🔢", "Tap the right answer"), ("🧱", "Each one stacks a block"))),
    ]),
    LudusWorld(name: "Globe Trotters", subject: "Geography", emoji: "🌍", colorHex: Lu.sky, games: [
        .init(title: "Pharos Beam", mechanic: "spinner", premise: "Swing the lighthouse beam to the ship that calls.", game: .pharosBeam,
              icon: "🔦", howTo: how(("⛵️", "A ship calls for light"), ("👆", "Drag the beam to it"), ("📯", "Let go — toot toot!"))),
        .init(title: "Lost Zoo Ferry", mechanic: "ferry", premise: "Sail each animal home to the right land.", game: .zooFerry,
              icon: "🦒", howTo: how(("🦘", "An animal is lost"), ("👆", "Drag it to a ferry"), ("⛴️", "Sail it home!"))),
        .init(title: "Flag Frenzy", mechanic: "pop", premise: "Tap the flags from the called-out continent.", game: .flagFrenzy,
              icon: "🚩", howTo: how(("👂", "Read the continent"), ("👆", "Tap its flags"))),
        .init(title: "Orbis", mechanic: "map", premise: "Name the country from its outline.", game: .nameCountry,
              icon: "🗺️", howTo: how(("👀", "Look at the shape"), ("👆", "Tap the country's name"))),
    ]),
    LudusWorld(name: "Word Wizards", subject: "Language Arts", emoji: "✏️", colorHex: Lu.mint, games: [
        .init(title: "Polyphemus Is Hungry", mechanic: "feed", premise: "Feed the Cyclops only foods with his sound.", game: nil,
              icon: "👁️", howTo: how(("👂", "Hear the sound he wants"), ("🍌", "Drag him the right food"))),
        .init(title: "Scroll Catcher", mechanic: "catch", premise: "Catch the falling letters to spell the picture.", game: nil,
              icon: "📜", howTo: how(("🐱", "Look at the picture"), ("🧺", "Catch its letters in order"))),
        .init(title: "Word Sort", mechanic: "lane-sorter", premise: "Drop each word into noun or verb.", game: .wordSort,
              icon: "📚", howTo: how(("📖", "Read the word"), ("👈", "Send it to the right bin"))),
        .init(title: "Synonym Snake", mechanic: "snake", premise: "Eat the synonyms, avoid the antonyms.", game: .synonymSnake,
              icon: "🐍", howTo: how(("👆", "Swipe to steer"), ("😋", "Eat words that mean the same"))),
    ]),
    LudusWorld(name: "Brain Benders", subject: "Logic & Puzzles", emoji: "🧩", colorHex: Lu.grape, games: [
        .init(title: "Porta Custos", mechanic: "gatekeeper", premise: "Only gladiators who follow the rule may enter.", game: .portaCustos,
              icon: "🛡️", howTo: how(("🛡️", "Look at the rule"), ("🚪", "OPEN if he fits it"), ("✋", "SHUT if he doesn't"))),
        .init(title: "Torches of the Arena", mechanic: "lights-out", premise: "Light every torch — but each tap flips its neighbours.", game: .torches,
              icon: "🔥", howTo: how(("👆", "Tap a torch"), ("↔️", "Its neighbours flip too"), ("🔥", "Light them all!"))),
        .init(title: "True / False Blitz", mechanic: "quick-fire", premise: "Snap-judge each statement, true or false.", game: .trueFalseBlitz,
              icon: "⚖️", howTo: how(("📖", "Read the sentence"), ("✅", "Is it true or false?"))),
        .init(title: "Odd One Out", mechanic: "quick-fire", premise: "Tap the one that doesn't belong.", game: .oddOneOut,
              icon: "🔍", howTo: how(("👀", "Look at them all"), ("👆", "Tap the one that doesn't fit"))),
        .init(title: "Pattern Pop", mechanic: "quick-fire", premise: "Tap what comes next in the pattern.", game: .patternPop,
              icon: "🔮", howTo: how(("👀", "Find the pattern"), ("👆", "Tap what comes next"))),
    ]),
    LudusWorld(name: "Lab Rats", subject: "Science", emoji: "🔬", colorHex: Lu.tangerine, games: [
        .init(title: "Dress Marcus", mechanic: "dress-up", premise: "Dress Marcus for the weather — or he'll freeze!", game: nil,
              icon: "🧥", howTo: how(("🌦️", "Look at the weather"), ("🧣", "Drag on the right clothes"))),
        .init(title: "Zookeeper's Breakfast", mechanic: "feed", premise: "Give every animal the food it really eats.", game: nil,
              icon: "🦁", howTo: how(("🐼", "An animal is hungry"), ("🎋", "Drag it the right food"))),
        .init(title: "Critter Sort", mechanic: "lane-sorter", premise: "Sort each animal — mammal, bird, or reptile.", game: .critterSort,
              icon: "🦎", howTo: how(("👀", "Look at the animal"), ("👆", "Tap its group"))),
    ]),
    LudusWorld(name: "Time Travelers", subject: "History", emoji: "🏛️", colorHex: Lu.gold, games: [
        .init(title: "Time Guard", mechanic: "spot", premise: "Something in old Rome doesn't belong. Catch it!", game: nil,
              icon: "⏳", howTo: how(("👀", "Look at the old scene"), ("📱", "Tap what's from the wrong time"))),
        .init(title: "Caesar's Wheel", mechanic: "cipher", premise: "Turn Caesar's secret wheel to read the message.", game: nil,
              icon: "🔐", howTo: how(("🎡", "Turn the wheel"), ("🔤", "Swap each letter"), ("📜", "Read the secret!"))),
        .init(title: "Timeline", mechanic: "order", premise: "Which came first? Put history in order.", game: .timeline,
              icon: "🏺", howTo: how(("👀", "Look at the events"), ("👆", "Tap the oldest one"))),
    ]),
    LudusWorld(name: "The Money Stall", subject: "Money & Life Skills", emoji: "🪙", colorHex: Lu.gold, games: [
        .init(title: "The Fig Stall", mechanic: "shop", premise: "Bag exactly what each customer asks for.", game: .figStall,
              icon: "🧺", howTo: how(("👵", "Look at the order"), ("🍎", "Tap fruit into the bag"), ("🤝", "Give it to them!"))),
        .init(title: "Porcus the Piggy Bank", mechanic: "save", premise: "Save up with Porcus to buy the prize.", game: .porcus,
              icon: "🐷", howTo: how(("🪙", "Drag coins into Porcus"), ("🔢", "Count up to the price"), ("🪁", "Then buy the prize!"))),
        .init(title: "Coin Count", mechanic: "count", premise: "Add up the coins — how much?", game: .coinCount,
              icon: "🪙", howTo: how(("👀", "Count the coins"), ("👆", "Tap how much money"))),
    ]),
    LudusWorld(name: "Sound Lab", subject: "Music", emoji: "🎵", colorHex: Lu.coral, games: [
        .init(title: "Piano Mouse", mechanic: "keyboard", premise: "Find the key where the mouse hid her cheese.", game: nil,
              icon: "🐭", howTo: how(("🎹", "Listen to the mouse"), ("👆", "Tap the right key"))),
        .init(title: "Maestro Mouse", mechanic: "conduct", premise: "Conduct the animal band: loud, soft, fast, slow.", game: nil,
              icon: "🎼", howTo: how(("🦁", "Read the sign"), ("👆", "Swipe up for LOUD, down for soft"))),
        .init(title: "Comedy & Tragedy", mechanic: "ear", premise: "Is the music happy or sad? Catch it with the mask.", game: nil,
              icon: "🎭", howTo: how(("👂", "Listen to the music"), ("😀", "Happy or sad? Pick the mask"))),
    ]),
]
