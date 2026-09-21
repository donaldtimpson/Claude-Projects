---
description: Review-and-refine (or author) the next grammar slide deck from Harvey's Grammar
argument-hint: "[lesson slug, e.g. the-adverb] or blank to take the next un-reviewed lesson"
---

Advance the grammar slide decks. **Key difference from the Linear Algebra notes:** the decks
already had an initial generation with **little review**. So the default job here is a careful
**review-and-refinement** pass over an existing lesson's content — not a from-scratch draft —
followed by a rebuild. Author a brand-new lesson only if one is explicitly requested.

## Sources
- **Source of truth:** `content/grammar/lessons/<slug>.json` — the lesson content that drives the
  deck. Edit the JSON here, never the generated files.
- **Origin text:** *Harvey's Elementary Grammar & Composition* (1880). Keep **Harvey's own
  terminology** — gloss archaic terms, don't replace them; stretch vocabulary; "avoid dated
  slang" ≠ avoid hard words.
- **Generators & format:** `tools/grammar/slides/` (`generate_deck.py`, `preview.py`, `README.md`,
  slide `type`s: `title`, `definition`, `concept`, `practice`, `questions`; themes `light` +
  `lyceum`).

## Which lesson
`$ARGUMENTS` names the lesson slug. If blank, pick the next lesson in book order
(`content/grammar/README.md` lists L1…L19) that hasn't yet had a review pass.

## Steps
1. **Load** `content/grammar/lessons/<slug>.json` and skim the current deck via
   `python3 tools/grammar/slides/preview.py <slug> lyceum` so you see what's actually on the slides.
2. **Review against the rigor + layout standards** and note every issue before editing:
   - **Rigor:** subject/predicate are *notions*, not words; the copula is separate (Harvey's
     `Iron | is : heavy`); go beyond the elementary book but stay consistent with it (audience is
     9th graders). Foreground proposition / subject / predicate / copula / true-false where the
     lesson touches them (this feeds the later Logic course).
   - **Layout:** ≤ 6 examples per definition/concept slide; balance the *kinds* of example (don't
     stack near-identical ones); use `answerInline` where it reads better; no orphaned "Model."
     left on a concept slide; **anti-giveaway practice** — practice prompts must not hand back the
     answer.
   - **Terseness:** slide bullets carry only the core point — cut wordy or meta framing even when
     accurate.
   - **Fidelity:** content faithful to Harvey; keep his verbiage.
3. **Independent review (required).** Spawn a fresh reviewer agent that has NOT done the edits to
   audit the lesson JSON against Harvey and against the standards above, returning a concrete
   fix list. (standing rule: always review generated educational content before shipping)
4. **Apply** the refinements to `content/grammar/lessons/<slug>.json`.
5. **Rebuild** both themes and the preview:
   ```bash
   ./tools/grammar/slides/.venv/bin/python tools/grammar/slides/generate_deck.py <slug>          # light
   ./tools/grammar/slides/.venv/bin/python tools/grammar/slides/generate_deck.py <slug> lyceum
   ./tools/grammar/slides/.venv/bin/python tools/grammar/slides/preview.py <slug> lyceum
   ```
   (Output lands in `tools/grammar/slides/build/`, which is gitignored.) If the deck feeds the
   apps' lesson/drill content, also run `tools/grammar/build_app_content.py`.
6. **Report** the lesson, the review findings you applied, and the rebuilt file paths. To publish,
   upload the `.pptx` through the Google Drive connection with conversion on (see the slides
   README). Don't commit/push unless asked (or on an explicit "sync").
