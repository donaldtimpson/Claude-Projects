# Sound It Out

A native iOS app that takes a child from spoken vocabulary to reading a sentence.
Separate from Timpson Lyceum in every way: different audience, different branding,
**no accounts, no network layer, and nothing stored off the device.**

```bash
cd ios && xcodegen generate && open SoundItOut.xcodeproj
```

## The six decks

Five of them form a ladder; the sixth runs alongside it.

| | Deck | What it does |
|---|---|---|
| 1 | **Letter Sounds** | 26 letters in teaching order, no pictures |
| 2 | **Blending** | Two variants — see below |
| 3 | **Words** | 57 words across CVC → digraphs → blends → silent e |
| 4 | **Sentences** | 20 fully decodable sentences |
| 5 | **Sight Words** | The rule-breakers, as *heart words* |
| — | **Picture Words** | 39 vocabulary cards, available any time |

**Picture Words is not step one of reading.** The word under the picture is for the
adult, so they know which word the image is meant to prompt; the child is building
spoken vocabulary. Reading mode hides the picture, so the same deck becomes a
victory lap a year later. Three images per word, never one — a child shown a single
dog learns that picture, not the category.

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

## Art

Emoji are placeholders. `ReadingContent.Word.image` is the single hook — point it
at bundled assets and everything downstream follows.

**12 of the 57 words have no image and never will** (`sat`, `chat`, `mud`…). That
is the honest limit of picture-based self-check, and why the flip card falls
through to audio. Sourcing: [Pexels](https://pexels.com) and
[Pixabay](https://pixabay.com) allow commercial use with no attribution required,
and real photos suit the three-images-per-word idea better than a symbol set (a
pictogram library has exactly one dog). **Avoid ARASAAC** despite the perfect fit —
it is non-commercial.

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

## Prototype

`prototype.html` is the original clickable mockup, including variants not built
yet. Keep it — it is where pacing gets argued before it gets coded.
