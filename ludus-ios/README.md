# Ludus (iOS)

The kids' arcade — the middle rung of the platform, between **Sound It Out** (ages 5–7,
learning to read) and the **Timpson Lyceum** (13+, real courses). School subjects, arcade
rules: score-chasing mini-games, an app-wide earned currency (Roman **denarii / aurei**),
and a rank you climb (**Tiro → Legionary → Centurion → Consul**).

This is an early prototype focused on nailing the theme and taking a first swing at a
spread of game mechanics. Standalone app — nothing here touches `edu-ios`.

## Run it

```bash
cd ludus-ios
xcodegen generate       # writes Ludus.xcodeproj (gitignored)
open Ludus.xcodeproj
```
In Xcode: pick your iPhone (or a simulator) as the destination and hit ⌘R. Signing is
preset to the same free Apple ID team as Lyceum. **Deployment target is iOS 16.0** so it
installs on older devices.

## What's here

- **Home hub** (`HomeView.swift`) — wordmark, currency/rank HUD, the 8 subject worlds.
- **Worlds** (`Worlds.swift`) — the catalog + the `GameID → view` routing switch. A game
  with `game: nil` is a "coming soon" tile so the whole arcade's shape is visible.
- **World screen** (`WorldView.swift`) — a subject's game list; playable games launch
  full-screen, the rest are dimmed.
- **Design system** (`LudusTheme.swift`) — palette (`Lu`), fonts (`luFont`), shared chrome
  (`LudusBackground`, `LudusButton`, `StatPill`, `HeartsRow`, `LudusGameOverView`),
  haptics, and the shared economy (`LudusStore`: one denarii bank, per-game bests).

### Playable games (first swings)

| Game | World | Mechanic | File |
|------|-------|----------|------|
| Bubble Evens | Math | pop-the-target | `BubbleEvensView.swift` |
| Times Table Ninja | Math | slash (fruit-ninja) | `TimesTableNinjaView.swift` |
| Flag Frenzy | Geography | pop (emoji flags) | `FlagFrenzyView.swift` |
| Capital Clash | Geography | quick-fire quiz | `QuickFire.swift` |
| True / False Blitz | Logic | quick-fire quiz | `QuickFire.swift` |
| Odd One Out | Logic | quick-fire quiz | `QuickFire.swift` |
| Word Sort | Language | lane-sorter | `WordSortView.swift` |

Geography content (capitals, continents, emoji flags) is an embedded deck in
`GeoData.swift` — no image/map assets. `QuickFire.swift` is one quiz engine that three
games pour a question generator into.

## Architecture notes

- Real-time games run a 60fps loop: `TimelineView(.animation)` drives a `@MainActor`
  engine's `advance(to:size:)` each frame and a `Canvas` renders it; taps hit-test via
  `SpatialTapGesture`. Game-over `@Published` flips are deferred with `DispatchQueue.main`
  to avoid mutating state mid-render. `BubbleEvensView.swift` is the reference pattern.
- Every game: 3 hearts, a combo multiplier, denarii banked on game-over, per-game best,
  and the shared `LudusGameOverView`.

## First tuning knobs (after the kid-test)

The feel lives in a few constants at the top of each engine:
- **Bubble Evens** — even frequency (`0.52`), base speed / ramp (`52 + elapsed*2.4`),
  radius (`width*0.12`).
- **Flag Frenzy** — target-continent spawn share (`0.45`), target rotate interval (`11s`).
- **QuickFire** games — per-question time (`5 → min 2.2s`, `-0.07`/point).

## Not built yet

Stubbed as "coming soon": Stack Attack, Coin Climber, Pin Drop (needs a map), Border/
Synonym Snake, Spell Sprint, Pattern Pop, all of Science / History / Money / Music, plus
the profile/avatar/shop/achievements meta-layer and sound (haptics only for now).
