# Ludus (iOS)

The kids' arcade — the middle rung of the platform, between **Sound It Out** (ages 5–7,
learning to read) and the **Timpson Lyceum** (13+, real courses). Eight subject worlds on a
painted Roman province, **5 games each (40 in all)**, pitched so a 7-year-old can start every
one and a sharp 12-year-old still finds the top hard. Standalone app — nothing here touches `edu-ios`.

## Run it

```bash
cd ludus-ios
xcodegen generate       # writes Ludus.xcodeproj (gitignored)
open Ludus.xcodeproj
```
Pick an iPhone or simulator and ⌘R. Deployment target iOS 16. First launch of a game that
speaks (Library, Market…) can take a few seconds in the simulator while speech warms up.

## The shape of the app

- **Home** (`HomeView.swift`, `Map*.swift`) — the painted province. Tap a landmark: the
  traveler walks the road, a scroll unfurls, PLAY zooms into that world's landing page
  (`WorldView.swift`). The seals' gilt ring segments = games won in that world.
- **Coins on the home bar → the Villa** (`VillaView.swift`): where the arcade's money goes.
- **Rank on the home bar → the Tabularium** (`TabulariumView.swift`): rank ladder, every
  game's laurels, the sound switch.
- **Worlds catalog** (`Worlds.swift`) — every game's title, premise, how-to and routing.

## The economy (`Economy.swift`)

- **Denarii** (silver) — spending money. Every game pays the same: 1 per right answer,
  +5 per level climbed. (Score is each game's own business.)
- **Aurei** (gold) — earned only by **laurels**: bronze 1, silver +2, gold +3 per game (up to
  6 a game, 240 in all). Computed from progress — never bought, never stored separately.
- **Rank** = aurei *earned* (not the balance), so spending never demotes:
  Tiro → Legionary (5) → Centurion (20) → Consul (50).
- **The Villa** — a Pompeian-fresco villa the child furnishes: garden, water, statues, pets
  (that wander the lawn) for denarii; grand works (golden eagle, chariot, golden roof,
  elephant) for aurei. Catalog: `villaCatalog` in `VillaView.swift`.

## GameKit — how every game is built (`GameKit.swift`)

A game = an `ArcadeModel` subclass + its play view inside `ArcadeShell`, which owns the HUD,
the intro card (how to play, laurel goals, start level), the level-up banner and game-over.

- **Continuous difficulty.** Tune everything off `model.d` — a smooth number that climbs a
  little with every right answer (2.5 = halfway through Gradus II) and eases back after a
  miss. Helpers: `ramp(a, b, to:)`, `rampInt`, `chance(p, from:, to:)`, and
  `tier([1, 2.5, 4, …])` which picks a content *kind* — new kinds fade in over ~1.5 levels
  and old ones stay as review. **No per-level tables, no rule switches at a Gradus.**
- **Gradus / laurels** are milestones: a level per 6 right answers; bronze/silver/gold at
  III/V/VIII by default. Level I is practice (misses cost no heart). Reached laurel levels
  become start options.
- **Own scene.** `ArcadeShell(…, backdrop: { MyScene() }) { play }` — the backdrop sits behind
  play, the intro and the game-over card. HUD and cards are smoked glass (`luGlass`) so they
  sit on any scene.
- **Sound.** `Sfx.play(.pop/.coin/.whoosh/.chomp/…)` — asset-free synthesized effects;
  right/wrong/level-up/laurel play automatically. Music games use `ToneSynth`; speech uses
  `LibraryVoice`.
- **Every miss shows the right answer.** Every game implements `botAct(correct:)`.

### Debug hooks (DEBUG builds, via env / `SIMCTL_CHILD_…`)

`LUDUS_GAME=<id>` open a game · `LUDUS_AUTOPLAY=1` skip the intro · `LUDUS_BOT=0.9`
(+`LUDUS_BOT_EVERY`) autoplay · `LUDUS_START_LEVEL=n` · `LUDUS_WORLD=<subject>` ·
`LUDUS_SCREEN=villa|records` · `LUDUS_GRANT=n` denarii · `LUDUS_OWN=all|id,id` villa items ·
`LUDUS_MUTE=1` · `LUDUS_SELFCHECK=1` (per-game content checks) · `LUDUS_TOUR` (map tour).

## The games

### The Temple — Math

| Game | Premise | id |
|---|---|---|
| Ballista | Aim the legion's ballista at the number on the long number line. | `ballista` |
| Omnibus Driver | Passengers hop on and off — how many are riding? | `omnibus` |
| Times Table Ninja | Slice the fruit from the right times table, dodge the bombs. | `timesTableNinja` |
| Leo's Fountain | Fill each jug to just the right level — ½, ¾, 0.7, 40%. | `fountain` |
| Libra | Fill the sack until the great scales balance. | `libra` |

### The Lighthouse — Geography

| Game | Premise | id |
|---|---|---|
| Pigeon Post | Pippa the pigeon flies your letters anywhere on the real world map. | `pigeonPost` |
| Agrippa's Map | Finish Agrippa's great map — drag each land into its place. | `agrippaMap` |
| Pharos Beam | Swing the lighthouse beam to the ship that calls. | `pharosBeam` |
| Lost Zoo Ferry | Sail each lost animal home to the right land. | `zooFerry` |
| Flag Festival | Pop the balloon with the flag the herald calls — then names, continents and capitals. | `flagFrenzy` |

### The Library — Language Arts

| Game | Premise | id |
|---|---|---|
| Polyphemus Is Hungry | Feed the Cyclops only foods with his sound. | `polyphemus` |
| Scroll Catcher | Catch the falling letters to spell the word. | `scrollCatcher` |
| Minerva's Owl | Aim the owl at the moth with the right kind of word. | `minervaOwl` |
| Stepping Stones | Lay the word stones in sentence order so the frog can hop home. | `wordBridge` |
| Synonym Snake | Eat the words that fit the sign — dodge the rest. | `synonymSnake` |

### The Colosseum — Logic & Puzzles

| Game | Premise | id |
|---|---|---|
| Where's Leo? | Leo the lion cub hides — follow his helmet through the shuffle! | `whereLeo` |
| Mosaic Mender | Mus the mouse pinched a tile — find the one that fits the pattern. | `mosaicMender` |
| Chariot Code | Plan the chariot's route with arrows, then press GO. | `chariotCode` |
| Porta Custos | Only gladiators who follow the rule may enter. | `portaCustos` |
| Torches of the Arena | Light every torch — but each tap flips its neighbours. | `torches` |

### Mount Vesuvius — Science

| Game | Premise | id |
|---|---|---|
| Vulcan's Forge | Melt, boil and freeze things in the fire inside Vesuvius. | `forge` |
| Dress Marcus | Dress Marcus for the weather — or he'll freeze! | `dressMarcus` |
| Archimedes' Seesaw | Put the weight on the right peg to balance the beam. | `seesaw` |
| Zookeeper's Breakfast | Give every animal the food it really eats. | `zookeeper` |
| Critter Sort | Fling each animal into its house — mammal, bird, fish and more. | `critterSort` |

### The Forum — History

| Game | Premise | id |
|---|---|---|
| Milestone Mason | Carve Roman numerals on the milestones of the Via Appia. | `milestone` |
| The Dig | Bury each find in its layer — the deeper, the older. | `dig` |
| Time Guard | Something in the old scene is from the wrong time. Zap it home! | `timeGuard` |
| Circus Maximus | Steer your chariot through the right gate. | `chariot` |
| Caesar's Wheel | Turn Caesar's secret wheel to read the message. | `caesarWheel` |

### The Market — Money & Life Skills

| Game | Premise | id |
|---|---|---|
| Porcus the Piggy Bank | Feed Porcus real coins — exactly the price of the prize. | `porcus` |
| The Fig Stall | Run the fruit stall — count up and give the right change. | `figStall` |
| The Clock Tower | Set the town clock to the time people need. | `clockTower` |
| Ursa's Bakery | Measure just right for the baker bear's recipes. | `bakery` |
| Donkey Deals | Steer the donkey cart to the cheaper stall, the better deal, the thing you need. | `donkeyDeal` |

### The Theatre — Music

| Game | Premise | id |
|---|---|---|
| Echo's Cave | Echo sings on the crystals — sing her tune back. | `echoCave` |
| Galley Drum | Drum the beat so the rowers keep time. | `galleyDrum` |
| Maestro Mouse | Conduct the animal band: loud, soft, fast, slow. | `maestroMouse` |
| Piano Mouse | Find the key where the mouse hid her cheese. | `pianoMouse` |
| Comedy & Tragedy | Is the music happy or sad? Pick the mask that fits. | `comedyTragedy` |
## Art & tools

- `tools/icon_build.swift` — renders the app icon (wax seal + Cinzel L + laurel over the
  painted province): `swift tools/icon_build.swift tools/art/province_original.png Resources/Fonts/Cinzel-Black.ttf Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png 0.62`
- `tools/chrome/`, `tools/ambient_build.py`, `tools/map_trace.py` — the home map's baked
  chrome, living-painting ambience and road tracing.
- Everything inside the games is drawn in code (SwiftUI shapes, Canvas, SF Symbols, emoji).
