# Grammar course content

Single source of truth for the Grammar course, shared by both apps and the slide decks.
Source: *Harvey's Elementary Grammar & Composition* (1880). 19 lessons, ordered by the
book's page sequence (L1 Foundations … L19 Irregular Verbs & Capitals).

## What's here

- **`lessons/lesson-01..19.json`** — the *teaching* content of each lesson (concept slides +
  worked practice with answers). This is the origin: it drives the slide decks **and** grounds
  the drill banks (every drill item was authored from, and audited against, its lesson).
- **`drills/lesson-01..19.json`** — the *homework* MC banks (40–45 items each). Each runs as a
  30-question homework set in the apps; a flawless run earns the lesson's ✦. Same item schema
  the app loaders expect: `{slug,lesson,title,blurb,icon,layout,order,tier,items:[{id,level,
  prompt,options,answer,explain}]}`. Options must be **distinct per item** (the players shuffle
  option order and key on text).

> The ✒️ *practice* drills (its/it's, a/an, who/whom…) currently live only in
> `edu-ios/Resources/Grammar/grammar.json`; they move here under `practice/` when web parity
> lands (Phase 2).

## How it's consumed (generators live in `tools/grammar/`)

| Target | Tool | Output |
|---|---|---|
| iOS + web apps | `tools/grammar/build_app_content.py` | bundled `lessons.json` (drills → each app's Resources) |
| Slide decks | `tools/grammar/slides/generate_deck.py <lesson> [lyceum]` | `.pptx` (converts to Google Slides on upload) |
| Deck HTML preview | `tools/grammar/slides/preview.py <lesson> [lyceum]` | standalone HTML |
| Drill-bank review | `tools/grammar/preview_drills.py [lesson-NN]` | HTML listing every item with the answer marked |

Edit the JSON here, never the generated `lessons.json` in an app's Resources. Slide decks are
published to Google Slides (see `tools/grammar/slides/README.md`); the pipeline is otherwise
dormant now that the decks are live there.
