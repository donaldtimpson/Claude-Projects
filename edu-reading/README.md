# Sound It Out

A native iOS app that takes a child from spoken vocabulary to reading a sentence.
Separate from Timpson Lyceum in every way: different audience, different branding,
**no accounts, no network layer, and nothing stored off the device.**

```bash
cd ios && xcodegen generate && open SoundItOut.xcodeproj
```

## How a child drives it

**Tap the card, or swipe it away. That is the entire interface.** No Next button,
no Back button, no chips — a child taps whatever is on screen expecting something
to happen, so anything that is not the card is a trap. Levels advance on their own;
everything a grown-up would choose lives behind the parental gate.

**Turning a card.** Tap once and the card says what is on it; tap again and it
turns. Swiping works too, but is never required — a child who only ever taps can
finish the whole deck, which is the point: a tap that does nothing reads as
broken. The card is drawn as a visible *stack*, and on opening the top card
slides a little and springs back — a wordless demonstration that it moves
sideways, so the swipe is discoverable without being taught. For a younger child,
**Cards turn themselves** in the grown-ups' area makes one tap enough: it speaks
and then turns on its own, and tapping again just replays it.

**Voice (optional).** With it on, the card listens the whole time it is up and turns
itself when the word is read. The target word is known in advance, so this is
verification rather than open recognition — and it is built so it **can only ever
say yes**. A match celebrates; a non-match does nothing at all. A small child is
never told they were wrong on a signal we don't trust, which is what makes an
unreliable technology safe here. Recognition is forced on-device, so speech never
leaves the phone.

## The six decks

Five of them form a ladder; the sixth runs alongside it.

| | Deck | What it does |
|---|---|---|
| 1 | **Letter Sounds** | 26 letters in teaching order, no pictures |
| 2 | **Blending** | Two variants — see below |
| 3 | **Words** | 57 words across CVC → digraphs → blends → silent e |
| 4 | **Sentences** | 20 fully decodable sentences |
| 5 | **Sight Words** | The rule-breakers, as *heart words* |
| — | **Look and Say** | 211 words, 446 pictures, available any time |

**Look and Say (deck 1) is the gentlest thing in the app** and the entry point for
a child far too young for the rest of it: big picture, tap to hear it, tap again to
cycle its three images, swipe on. It is not step one of reading and never gates the
ladder. The word under the picture is for the
adult, so they know which word the image is meant to prompt; the child is building
spoken vocabulary. Reading mode hides the picture, so the same deck becomes a
victory lap a year later. Three images per word, never one — a child shown a single
dog learns that picture, not the category.

Each photograph is **its own card**, dealt in rounds so every word appears once
before any word appears twice — meeting an unfamiliar dog thirty cards later asks
the child to recognise the *category*, which is the point of having more than one.

**Both decks were audited the same way, and the drawings needed it as much as the
photographs did.** An emoji is not automatically a good card: 🦁 had been filed
under *zoo*, 🥋 under *belt*, 🧻 under *towel*, 🪜 under *stairs*. Worse, the same
glyph was serving several words — 🪑 was *chair*, *table*, *bench* and *sit* at
once. 28 drawings were removed; no glyph now appears on two words.

**Words are matched to pictures, not pictures to words.** An earlier pass tried to
find three photographs for every word and the third was always a stretch — a
lion's face ended up on "zoo", a polar bear too. Now every photograph is judged on
its own: *what does this actually show?* The word follows the picture. Some words
have four pictures, many have one, and that unevenness is correct — a forced match
teaches the wrong thing, and a word with one good picture beats a word with three
where two are guesses.

### In order, or shuffled

Decks whose order carries meaning show a toggle in the top right, mirroring the
back button: **Letters** (the teaching order *is* the lesson — s a t p i n first),
**Blending** (a rime, then the family built from it), and **Numbers** (counting).
Everywhere else there is nothing to be in order *of*, so there is no control — a
button that does nothing is worse than no button.

### Colours, shapes and numbers

Drawn rather than sourced — no photographs to hunt, nothing to audit, no licences,
and every card correct by construction. **One card per item**: an earlier version
gave each item several layouts, which made the decks longer without making them
broader. Twelve ways to look at a square is not the same as knowing twelve shapes,
so the decks grew by adding items.

| Deck | Items | The card |
|---|---|---|
| Colours | 20 | four unlike shapes in one colour |
| Shapes | 16 | one shape in four colours |
| Numbers | to 100 | a count, the numeral, and the word |

Each still applies the app's rule — vary everything except what is being taught —
since a single red circle labelled *red* teaches "circle" just as readily.

Counters group in **fives up to twenty**, because a row of seventeen cannot be
counted by eye, and in **tens above it**, which makes a hundred read as the
hundred-square a child meets later. Levels are 5 / 10 / 20 / 50 / 100 in the
grown-ups' area.

### Two decks, not one

**Photos** and **Drawings** are separate decks. They were interleaved at first —
the argument being that meeting a real dog and a drawn one teaches the category —
but testing showed the drawings are reliably legible while a fair number of the
photographs are not, and a bad photograph interrupting a good deck is worse than
either deck alone. Drawings-only is also often easiest for the youngest child:
less to look past.

### Every tinted surface is opaque

`Color.mixed(with:amount:)` blends toward another colour and stays opaque. Nothing
in the app tints with `.opacity()`, because a translucent wash composites over
whatever is behind it — in dark mode the deck's accent ground turned near-black and
swallowed the dark back chevron drawn on top of it. The app also pins
`.preferredColorScheme(.light)`: the palette is a single fixed light one, chosen
for a lit room with an adult and a child sharing a screen, and half-inheriting dark
mode only produced surfaces neither palette expected.

### No title inside a deck

A child cannot read "Photos", and in landscape the title bar eats the one
dimension that is scarce. Decks show no title in either orientation; the back
chevron is enough to say where you are.

### Landscape and the back swipe

Cards are swiped left **and** right to move through a deck, which collides with the
iOS edge-swipe meaning "go back" — a slightly-too-far-left swipe threw the child
out of the deck. There is no direction left to reserve for navigation, so the edge
gesture is disabled inside a deck (`noBackSwipe()`); the bar's back button is the
way out, and the gesture is restored on the way out.

Landscape is supported on iPhone, and **there is no landscape layout**. Branching
on orientation was tried and thrown away: it made portrait worse to serve
landscape, and a debug override for it leaked into portrait. `AdaptiveCard` instead
gives the picture whatever room is left after the word and scales it to fit, so a
tall card yields a tall picture and a short one a short picture. One layout cannot
render the wrong way round.

`UITests/LandscapeShot.swift` rotates the Simulator and captures both picture
decks, because `simctl` cannot rotate and a layout nobody looks at is a layout
that is broken.

### Card numbers

Every card carries a plain number, so a bad one can be reported without describing
it. Numbers come from **content order**, so they are stable across shuffles,
launches and devices; each deck owns a range:

| Range | Deck |
|---|---|
| 1–999 | Photos |
| 1000–1999 | Drawings |
| 2000–2999 | Words |
| 3000–3999 | Sentences |
| 4000–4099 | Letters |
| 4100–4199 | By Heart |
| 5000–5999 | Blending |

`tools/photos/card-index.md` maps every number to its word, asset and source.
Toggle the numbers off in the grown-ups' area before handing the app to anyone
who isn't testing it.

### Adding your own

Drop `dog.jpg` into `Assets.xcassets` as a **single-scale universal** imageset.
`dog-2`, `dog-3` become extra cards for the same word. No content edit, no code.

> Single-scale matters: an imageset declaring empty 2x/3x slots returns nil from
> `UIImage(named:)` on a 3x device even though the file is in `Assets.car` —
> indistinguishable from the image not being bundled.

Attribution is a legal requirement for the 406 CC BY photographs, so
`photo-credits.json` ships with them and the grown-ups' area names every
photographer.

## Content

`content/reading/reading.json` at the repo root is the source of truth. After
editing it:

```bash
./tools/sync-content.sh
```

Keeping the decks as data rather than Swift is what makes an Android port a copy
rather than a rewrite.

## App Store notes

Guideline 1.3 forbids a Kids Category app from linking out except behind a
**parental gate**. `ParentGateView` is that gate, and it covers all three
adult-facing things at once: the CC BY attributions, the one Lyceum mention, and
reset. Guideline 5.1.4 bars sending device or personal information to third
parties — there is no networking code in this app at all.

## How it looks

The first version was flat, and the cause was not the palette — it was that the
card was **mostly empty white**, with a small photograph floating in the middle of
it. The picture now bleeds to the card's edges with the word in a band beneath,
which is the shape a flashcard actually has, and the dead space is gone.

Around that, `Skin.swift` holds three directions, switchable in the grown-ups' area
so they can be judged on a device with a child rather than argued from screenshots:

| | |
|---|---|
| **Plain** | what shipped: flat white card on a flat tint |
| **Paper** | a warm card resting on a lit table — tight contact shadow under a soft ambient one, a hairline edge, and a stack that is genuinely stacked |
| **Sunroom** | brighter and warmer, the deck's colour a wash of light behind the card |

Everything is depth rather than decoration. A children's app fails by burying the
content under pattern and colour, so the work went into making the card read as an
*object* — which is on-theme, since the app is a deck of cards.

Home and hub tiles carry each deck's own colour, so a child who cannot read the
names still has somewhere to aim.

## Typography

Bundled **Andika** (SIL, OFL) is load-bearing, not decoration: single-storey `a`
and `g` matching how children are taught to write, and `I`/`l`/`1` that can't be
confused. No system font on iOS has those letterforms.

Vowels are red everywhere. That is a real phonics convention, and holding it across
all six decks is the strongest visual cue in the app.

## Icon

A single lowercase **a** in Andika, red on amber. Two reasons it is a letter and
not a mascot:

- Andika's single-storey `a` is a circle with a stem — the letterform that makes
  the app defensible is also the roundest, most toy-like shape in the alphabet, so
  the typographic argument and the kid appeal land on the same mark.
- **The letter is red because vowels are red.** The icon states the app's own rule
  rather than decorating it. The higher-contrast cream-on-red version was rejected
  for exactly this: it inverts the convention.

Six alternates sit in `icon/`, with `icon/candidates.png` showing them side by side
at home-screen size — which is the only size that decides anything.

```bash
./tools/set-icon.sh            # list
./tools/set-icon.sh bubble     # swap, then rebuild
```

## Prototype

`prototype.html` is the original clickable mockup, including variants not built
yet. Keep it — it is where pacing gets argued before it gets coded.
