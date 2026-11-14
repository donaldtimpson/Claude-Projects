import SwiftUI

// MARK: - Worlds catalog + game routing
//
// The arcade is organised into subject "worlds" (one per landmark on the map), each holding a
// handful of games. A game with a non-nil `game: GameID` is playable; nil = not built yet (the
// landing page hides it). Each entry carries what the landing page and intro card show: an
// emblem, a one-line premise, 2–3 picture-led "how to play" lines and the laurel goals (GameKit).

enum GameID: String, Identifiable, Hashable {
    // Temple · Math
    case ballista, omnibus, timesTableNinja, fountain, libra
    // Lighthouse · Geography
    case flagFrenzy, nameCountry, pharosBeam, zooFerry, pigeonPost, agrippaMap
    // Library · Language Arts
    case wordSort, synonymSnake, polyphemus, scrollCatcher
    // Colosseum · Logic  (trueFalseBlitz / oddOneOut / patternPop are retired — QuickFire still names them)
    case portaCustos, torches, chariotCode, whereLeo, mosaicMender, trueFalseBlitz, oddOneOut, patternPop
    // Vesuvius · Science
    case critterSort, dressMarcus, zookeeper
    // Forum · History
    case timeline, timeGuard, caesarWheel
    // Market · Money (coinCount: retired — its view still lives in QuickFire.swift)
    case coinCount, figStall, porcus, clockTower, bakery, donkeyDeal
    // Theatre · Music
    case pianoMouse, maestroMouse, comedyTragedy, galleyDrum, echoCave
    var id: String { rawValue }
}

/// Maps a game id to its full-screen view. The per-game best-score key is the raw value.
@ViewBuilder
func ludusGame(_ id: GameID, onClose: @escaping () -> Void) -> some View {
    switch id {
    case .ballista:        TempleBallistaView(onClose: onClose)
    case .omnibus:         OmnibusView(onClose: onClose)
    case .timesTableNinja: TimesTableNinjaView(onClose: onClose)
    case .fountain:        TempleFountainView(onClose: onClose)
    case .libra:           TempleLibraView(onClose: onClose)
    case .flagFrenzy:      FlagFrenzyView(onClose: onClose)
    case .nameCountry:     NameCountryView(onClose: onClose)
    case .pharosBeam:      PharosBeamView(onClose: onClose)
    case .zooFerry:        ZooFerryView(onClose: onClose)
    case .pigeonPost:      PigeonPostView(onClose: onClose)
    case .agrippaMap:      AgrippaMapView(onClose: onClose)
    case .wordSort:        WordSortView(onClose: onClose)
    case .synonymSnake:    SynonymSnakeView(onClose: onClose)
    case .polyphemus:      PolyphemusView(onClose: onClose)
    case .scrollCatcher:   ScrollCatcherView(onClose: onClose)
    case .trueFalseBlitz:  TrueFalseBlitzView(onClose: onClose)
    case .oddOneOut:       OddOneOutView(onClose: onClose)
    case .patternPop:      PatternPopView(onClose: onClose)
    case .portaCustos:     PortaCustosView(onClose: onClose)
    case .torches:         TorchesView(onClose: onClose)
    case .chariotCode:     ChariotCodeView(onClose: onClose)
    case .whereLeo:        WhereLeoView(onClose: onClose)
    case .mosaicMender:    MosaicMenderView(onClose: onClose)
    case .critterSort:     CritterSortView(onClose: onClose)
    case .dressMarcus:     DressMarcusView(onClose: onClose)
    case .zookeeper:       ZookeeperView(onClose: onClose)
    case .timeline:        TimeOrderView(onClose: onClose)
    case .timeGuard:       TimeGuardView(onClose: onClose)
    case .caesarWheel:     CaesarWheelView(onClose: onClose)
    case .coinCount:       CoinCountView(onClose: onClose)
    case .figStall:        FigStallView(onClose: onClose)
    case .porcus:          PorcusView(onClose: onClose)
    case .clockTower:      ClockTowerView(onClose: onClose)
    case .bakery:          BakeryView(onClose: onClose)
    case .donkeyDeal:      DonkeyDealView(onClose: onClose)
    case .pianoMouse:      PianoMouseView(onClose: onClose)
    case .maestroMouse:    MaestroMouseView(onClose: onClose)
    case .comedyTragedy:   ComedyTragedyView(onClose: onClose)
    case .galleyDrum:      GalleyDrumView(onClose: onClose)
    case .echoCave:        EchoCaveView(onClose: onClose)
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
        .init(title: "Ballista", mechanic: "aim", premise: "Aim the legion's ballista at the number on the long number line.", game: .ballista,
              icon: "🎯", howTo: how(("📣", "Hear the number"), ("👉", "Drag to aim along the line"), ("🏺", "Let go — smash the pot!"))),
        .init(title: "Omnibus Driver", mechanic: "story-sum", premise: "Passengers hop on and off — how many are riding?", game: .omnibus,
              icon: "🚌", howTo: how(("👀", "Watch who gets on and off"), ("🧠", "Keep count in your head"), ("👆", "Tap how many are riding"))),
        .init(title: "Times Table Ninja", mechanic: "slash", premise: "Slice the fruit from the right times table, dodge the bombs.", game: .timesTableNinja,
              icon: "🥷", howTo: how(("👀", "Look at the table on the banner"), ("👉", "Swipe fruit from that table"), ("💣", "Never slice a bomb"))),
        .init(title: "Leo's Fountain", mechanic: "pour", premise: "Fill each jug to just the right level — ½, ¾, 0.7, 40%.", game: .fountain,
              icon: "🦁", howTo: how(("🏺", "Look at how full"), ("✋", "HOLD to pour"), ("💧", "Let go at just the right level"))),
        .init(title: "Libra", mechanic: "balance", premise: "Fill the sack until the great scales balance.", game: .libra,
              icon: "⚖️", howTo: how(("🍎", "Look at the other pan"), ("👆", "Tap weights into the sack"), ("⚖️", "Weigh it — make it level!"))),
    ]),
    LudusWorld(name: "Globe Trotters", subject: "Geography", emoji: "🌍", colorHex: Lu.sky, games: [
        .init(title: "Pigeon Post", mechanic: "map-tap", premise: "Pippa the pigeon flies your letters anywhere on the real world map.", game: .pigeonPost,
              icon: "🕊️", howTo: how(("✉️", "Read where the letter goes"), ("👆", "Tap that place on the map"), ("🕊️", "Pippa flies it there!"))),
        .init(title: "Agrippa's Map", mechanic: "jigsaw", premise: "Finish Agrippa's great map — drag each land into its place.", game: .agrippaMap,
              icon: "🧩", howTo: how(("🧩", "Pick a piece from the tray"), ("👆", "Drag it to its place"), ("🗺️", "Finish the map!"))),
        .init(title: "Pharos Beam", mechanic: "compass", premise: "Swing the lighthouse beam to the ship that calls.", game: .pharosBeam,
              icon: "🗼", howTo: how(("⛵️", "A ship calls from the fog"), ("👆", "Drag the beam to it"), ("🧭", "N is up — until it isn't!"))),
        .init(title: "Lost Zoo Ferry", mechanic: "ferry", premise: "Sail each lost animal home to the right land.", game: .zooFerry,
              icon: "🦒", howTo: how(("🦘", "An animal is lost"), ("👆", "Drag it onto a ferry"), ("⛴️", "Sail it home!"))),
        .init(title: "Flag Festival", mechanic: "pop", premise: "Pop the balloon with the flag the herald calls — then names, continents and capitals.", game: .flagFrenzy,
              icon: "🎈", howTo: how(("🚩", "Look at the herald's flag"), ("🎈", "Pop the balloon with it"), ("🌍", "Later: names and capitals"))),
    ]),
    LudusWorld(name: "Word Wizards", subject: "Language Arts", emoji: "✏️", colorHex: Lu.mint, games: [
        .init(title: "Polyphemus Is Hungry", mechanic: "feed", premise: "Feed the Cyclops only foods with his sound.", game: .polyphemus,
              icon: "👁️", howTo: how(("🅱️", "Look at his letter"), ("🍌", "Drag him a food with it"), ("🔊", "Tap to hear it"))),
        .init(title: "Scroll Catcher", mechanic: "catch", premise: "Catch the falling letters to spell the picture.", game: .scrollCatcher,
              icon: "📜", howTo: how(("🐱", "Look at the picture"), ("👉", "Drag the basket"), ("🔤", "Catch its letters in order"))),
        .init(title: "Word Sort", mechanic: "lane-sorter", premise: "Drop each word in its bin — noun, verb and more.", game: .wordSort,
              icon: "📚", howTo: how(("📖", "Read the word"), ("👆", "Tap its bin"), ("🧸", "Noun = a thing, verb = doing"))),
        .init(title: "Synonym Snake", mechanic: "snake", premise: "Eat the words that mean the same — dodge the opposites.", game: .synonymSnake,
              icon: "🐍", howTo: how(("👆", "Tap where to turn"), ("😋", "Eat the ones that match"), ("🚫", "Dodge the others"))),
    ]),
    LudusWorld(name: "Brain Benders", subject: "Logic & Puzzles", emoji: "🧩", colorHex: Lu.grape, games: [
        .init(title: "Where's Leo?", mechanic: "track", premise: "Leo the lion cub hides — follow his helmet through the shuffle!", game: .whereLeo,
              icon: "🦁", howTo: how(("👋", "Leo hides under a helmet"), ("👀", "Watch it as they shuffle"), ("👆", "Tap Leo's helmet!"))),
        .init(title: "Mosaic Mender", mechanic: "pattern", premise: "Mus the mouse pinched a tile — find the one that fits the pattern.", game: .mosaicMender,
              icon: "🐭", howTo: how(("🔴", "Look at the pattern"), ("🧺", "Pick the tile that fits"), ("☝️", "Drag it up into the gap"))),
        .init(title: "Chariot Code", mechanic: "coding", premise: "Plan the chariot's route with arrows, then press GO.", game: .chariotCode,
              icon: "🏇", howTo: how(("⬆️", "Tap arrows to plan the route"), ("🍎", "Eat every apple"), ("🏁", "Press GO — reach the flag!"))),
        .init(title: "Porta Custos", mechanic: "gatekeeper", premise: "Only gladiators who follow the rule may enter.", game: .portaCustos,
              icon: "🛡️", howTo: how(("🛡️", "Look at the rule"), ("🚪", "OPEN if he fits it"), ("✋", "SHUT if he doesn't"))),
        .init(title: "Torches of the Arena", mechanic: "lights-out", premise: "Light every torch — but each tap flips its neighbours.", game: .torches,
              icon: "🔥", howTo: how(("👆", "Tap a torch"), ("↔️", "Its neighbours flip too"), ("🔥", "Light them all!"))),
    ]),
    LudusWorld(name: "Lab Rats", subject: "Science", emoji: "🔬", colorHex: Lu.tangerine, games: [
        .init(title: "Dress Marcus", mechanic: "dress-up", premise: "Dress Marcus for the weather — or he'll freeze!", game: .dressMarcus,
              icon: "🧥", howTo: how(("🌦️", "Look out the window"), ("🧣", "Drag clothes onto Marcus"), ("😄", "Keep him comfy!"))),
        .init(title: "Zookeeper's Breakfast", mechanic: "feed", premise: "Give every animal the food it really eats.", game: .zookeeper,
              icon: "🦁", howTo: how(("🐼", "An animal is hungry"), ("🎋", "Drag it the right food"), ("😋", "Watch it munch!"))),
        .init(title: "Critter Sort", mechanic: "lane-sorter", premise: "Sort each animal into its group — mammal, bird, fish and more.", game: .critterSort,
              icon: "🦎", howTo: how(("👀", "Look at the animal"), ("👆", "Tap its group"), ("🦇", "Watch for tricky ones!"))),
    ]),
    LudusWorld(name: "Time Travelers", subject: "History", emoji: "🏛️", colorHex: Lu.gold, games: [
        .init(title: "Time Guard", mechanic: "spot", premise: "Something in old Rome doesn't belong. Catch it!", game: .timeGuard,
              icon: "⏳", howTo: how(("👀", "Look at the old scene"), ("📱", "Tap the wrong-time thing"), ("🌀", "Zap it home!"))),
        .init(title: "Caesar's Wheel", mechanic: "cipher", premise: "Turn Caesar's secret wheel to read the message.", game: .caesarWheel,
              icon: "🔐", howTo: how(("🔄", "Turn the wheel"), ("🔤", "Watch the word appear"), ("👆", "Tap what it says!"))),
        .init(title: "Timeline", mechanic: "order", premise: "Which came first? Put history in order.", game: .timeline,
              icon: "🏺", howTo: how(("👀", "Look at the events"), ("👆", "Tap the oldest one"))),
    ]),
    LudusWorld(name: "The Money Stall", subject: "Money & Life Skills", emoji: "🪙", colorHex: Lu.gold, games: [
        .init(title: "Porcus the Piggy Bank", mechanic: "drag coins", premise: "Feed Porcus real coins — exactly the price of the prize.", game: .porcus,
              icon: "🐷", howTo: how(("🪁", "Look at the price tag"), ("🪙", "Drag coins into Porcus"), ("🎉", "Exactly right? He buys it!"))),
        .init(title: "The Fig Stall", mechanic: "make change", premise: "Run the fruit stall — count up and give the right change.", game: .figStall,
              icon: "🧺", howTo: how(("💵", "They pay you"), ("👆", "Tap coins from the till"), ("➡️", "Count up to what they paid"))),
        .init(title: "The Clock Tower", mechanic: "turn the hands", premise: "Set the town clock to the time people need.", game: .clockTower,
              icon: "🕰️", howTo: how(("👀", "Look at the time they want"), ("👆", "Turn the clock hands"), ("🔔", "Ring the bell!"))),
        .init(title: "Ursa's Bakery", mechanic: "pour", premise: "Measure just right for the baker bear's recipes.", game: .bakery,
              icon: "🥧", howTo: how(("📜", "Read the recipe"), ("👇", "HOLD to pour, let go at the line"), ("🥣", "Into the bowl!"))),
        .init(title: "Donkey Deals", mechanic: "swipe", premise: "Steer the donkey cart to the cheaper stall, the better deal, the thing you need.", game: .donkeyDeal,
              icon: "🛒", howTo: how(("🪧", "Read the shopping sign"), ("👈", "Swipe the donkey to a stall 👉"), ("🏷️", "Pick the best one!"))),
    ]),
    LudusWorld(name: "Sound Lab", subject: "Music", emoji: "🎵", colorHex: Lu.coral, games: [
        .init(title: "Echo's Cave", mechanic: "echo", premise: "Echo sings on the crystals — sing her tune back.", game: .echoCave,
              icon: "💎", howTo: how(("👂", "Listen to Echo sing"), ("💎", "Big crystal LOW, small one HIGH"), ("👆", "Tap her tune back"))),
        .init(title: "Galley Drum", mechanic: "rhythm", premise: "Drum the beat so the rowers keep time.", game: .galleyDrum,
              icon: "🥁", howTo: how(("🔢", "The captain counts 1-2-3-4"), ("🥁", "Tap the drum on every beat"), ("🔁", "Then drum his rhythm back"))),
        .init(title: "Maestro Mouse", mechanic: "conduct", premise: "Conduct the animal band: loud, soft, fast, slow.", game: .maestroMouse,
              icon: "🎼", howTo: how(("🪧", "Look at the sign"), ("⬆️", "🦁 Swipe UP for LOUD"), ("⬇️", "🐭 Swipe DOWN for soft"))),
        .init(title: "Piano Mouse", mechanic: "keyboard", premise: "Find the key where the mouse hid her cheese.", game: .pianoMouse,
              icon: "🐭", howTo: how(("✨", "Look for the shiny key"), ("👆", "Tap it to play it"), ("🧀", "Find the mouse's cheese!"))),
        .init(title: "Comedy & Tragedy", mechanic: "ear", premise: "Is the music happy or sad? Pick the mask that fits.", game: .comedyTragedy,
              icon: "🎭", howTo: how(("👂", "Listen to the music"), ("😀", "Happy? Tap the smiling mask"), ("😢", "Sad? Tap the crying mask"))),
    ]),
]
