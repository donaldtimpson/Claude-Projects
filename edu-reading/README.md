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
before any word appears twice. The three pictures of a pig land about a full deck
apart rather than stacked on one card — meeting an unfamiliar pig twenty cards
later asks the child to recognise the *category* from a picture they have not
seen, which is the entire reason for having three. 446 cards from 211 words.

**Letter Sounds has no pictures on purpose.** "A is for Apple" builds a
letter → picture → *name* link and trains guessing from images. This deck teaches
the sound, and it teaches it in a deliberate order (`s a t p i n` first), so after
six letters a child can read `sat, pat, tap, nap, pin, tin, sit`. Shuffle is a
review mode, not the teaching order.

**Blending ships two versions to be tried on real children.** Variant A is
consonant + vowel (`fa fe fi`), which works beautifully in Spanish but is unstable
in English — the *fa* in *fat* is not the *fa* in *fable*. Variant B builds on the
rime (`at → fat → sat`), a unit English keeps stable, and hands over a whole word
family per card.

**Sight words arrive in deck 4, not deck 5.** Without `the` and `a`, a decodable
sentence can only ever be "Sam sat."

## The Word World

The reward layer, and deliberately **not points, badges or streaks**.

Words you read become things you own. Reading a sentence *changes* the world —
"The pig is big" actually enlarges the pig. That is not a metaphor bolted on; it is
the literal truth about literacy handed over as a game, and it turns the
decodable-sentence deck from the driest rung into the one they ask for.

Three deliberate refusals:

- **No points or badges.** They are text and abstract number — the two things a
  pre-reader hasn't got. How full the world is *is* the progress bar.
- **No streaks.** A streak punishes a family holiday and hands the guilt to the
  parent. Nothing here decays or expires.
- **No shop.** A shop needs prices and item names. Themes are *places* instead
  (grass → beach → snow → night → space), opened by reading.

Tapping a collected thing replays its word, so a child who taps the frog forty
times has read *frog* forty times — the reward layer doubles as the review layer.

## Audio

`Voice.swift` has two tiers. It plays a bundled `<word>.m4a` if one exists, and
otherwise falls back to on-device synthesis so every word speaks today.

Drop recordings into `Resources/` and tier one takes over with no code change:

- **Words** — [Lingua Libre / Wikimedia Commons](https://commons.wikimedia.org/wiki/Category:Lingua_Libre_pronunciation-eng)
  has ~107,000 English pronunciations under CC BY-SA. Filter to one prolific
  speaker so the voice stays consistent.
- **The 44 letter sounds** — record by hand. Synthesis is bad at isolated phonemes,
  and the schwa matters: "buh-a-tuh" never blends into "bat". Until real audio
  exists the letter deck stays silent rather than teach the wrong sound.

## Photographs

**446 photographs across 211 words** (~23 MB), all CC0 or CC BY, sourced through
[Openverse](https://openverse.org), which needs no API key. Words with no usable
photograph fall back to emoji; a handful were removed entirely.

`tools/photos/` holds the pipeline and, more importantly, **the decisions**:
`picks.json` and `picks-requery.json` are what was chosen, `query-hints.json` the
searches that needed sharpening, and `rejected.json` the 30 words that were cut
with the reason for each.

### Why a person has to look at every one

Automated selection produces cards that teach the wrong thing, and it fails in
ways a machine cannot notice. Real results from this run:

| Query | What came back |
|---|---|
| `apple` (Wikimedia) | An Apple II computer |
| `dog` (Wikimedia) | A dhole — a wild canid |
| `sleep` (Wikipedia lead) | A Domenico Fetti painting |
| `star` (Wikipedia lead) | The Sun, byte-identical to the `sun` card |
| `teddy` | Four photographs of dogs |
| `chicken` | Raw poultry and fried chicken |
| `panda` | Red pandas |
| `pig` | Guinea pigs, and a freight train |
| `kangaroo` | Two city skylines |
| `shirt` | **A t-shirt printed with profanity** |

That last one is the argument on its own. Roughly a quarter of first-pass results
need rejecting, and for a children's app the only reliable detector is an eye.

### What cannot be photographed

Verbs mostly failed: `throw`, `catch`, `push`, `pull`, `point`, `wave`, `build`,
`draw` were all cut, because a still photograph cannot disambiguate an action
without a caption — the one thing a pre-reader cannot use. Isolated body parts
(`arm`, `leg`, `knee`, `finger`, `tongue`) and roles (`doctor`, `farmer`,
`teacher`) went the same way. **Better absent than misleading.**

Verbs that survived did so because the whole scene reads as the action:
`run`, `swim`, `climb`, `dance`, `cry`, `read`, `drink`, `paint`, `clap`, `ride`.

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
