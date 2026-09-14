# grammar-slides

Turns a structured **lesson JSON** into a teaching **slide deck** — a `.pptx` that converts
cleanly into native, editable **Google Slides** on upload, plus a matching **HTML preview** for
quick review. Source material: *Harvey's Elementary Grammar & Composition* (1880).

## Why a pipeline (not hand-made slides)
One JSON per lesson is the source of truth. A generator renders it to any format with consistent
styling, so it scales across the whole book and can later branch into worksheets and app drills.

## Layout
```
lessons/<name>.json   # lesson content (the source of truth)
generate_deck.py      # lesson JSON -> build/NN_<name>.pptx  (python-pptx)
preview.py            # lesson JSON -> build/NN_<name>.html   (visual review)
lesson_order.py       # slug -> lesson number (the NN_ filename prefix)
build/                # generated output (gitignored)
```

## Setup (one time)
```bash
python3 -m venv .venv
./.venv/bin/pip install python-pptx
```

## Build
Output files are prefixed with the lesson's number (from `lesson_order.py`) so they sort
and are easy to find — e.g. `the-verb` → `03_the-verb.pptx`.
```bash
./.venv/bin/python generate_deck.py the-verb          # -> build/03_the-verb.pptx          (light)
./.venv/bin/python generate_deck.py the-verb lyceum   # -> build/03_the-verb-lyceum.pptx
./.venv/bin/python preview.py the-verb                # -> build/03_the-verb.html
./.venv/bin/python preview.py the-verb lyceum         # -> build/03_the-verb-lyceum.html
```

## Themes
Two production themes live in `themes.py`:
- **light** — warm cream, Harvey letterpress. Low-glare; use on a **TV screen**.
- **lyceum** — the Timpson Lyceum house brand (dark crimson + gold, Cinzel / EB Garamond,
  mirrors edu-web + edu-ios). Reads well **projected onto a chalkboard**.

Both generators take a theme name; `light` writes the plain filename, other themes add a
`-<theme>` suffix (so both coexist in `build/`). The `answer` token colors every plain-text
answer; `diagram` colors the sentence diagrams; `eyebrow`/`motto`/`head_font`/`body_font`/`fonts`
carry the brand. Add a theme by adding a dict to `THEMES`.

## Publish to Google Slides
Upload `build/<name>.pptx` through the Google Drive connection with
`contentMimeType = application/vnd.openxmlformats-officedocument.presentationml.presentation`
and default conversion on — it lands as an editable Google Slides deck.

## Adding a lesson
Copy `lessons/the-verb.json` and edit. Slide `type`s available:
`title`, `definition`, `concept`, `practice`, `questions`. Both generators read the same file.

## Design
Warm paper `#F5EFE3`, ink `#23201B`, deep-claret accent `#7B2233`, Georgia throughout (renders
reliably in both PowerPoint and Google Slides), thick-thin double rules echoing Harvey's
letterpress title pages.
