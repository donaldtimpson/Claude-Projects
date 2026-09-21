# Linear Algebra course content

Personal **pre-lecture notes** for the Linear Algebra course, worked up directly from the
textbook to prepare and deliver each lecture.

> These are the instructor's own preparation notes — **not** the recap/summary that gets
> uploaded to the website after a lecture. They exist to help actually *give* the lecture:
> full definitions, every theorem **with its proof**, worked examples shown start → final
> result, and teaching callouts.

**Text:** Lay, *Linear Algebra and Its Applications*, 5th ed.
**Plan:** 27-week front-loaded schedule covering all 58 sections through §8.6 (see the course
syllabus under `edu-web/scripts/syllabi/`).

## What's here

- **`notes/NN_<slug>.md`** — one file per lecture, numbered in teaching order (`01_…`, `02_…`).
  Markdown with LaTeX math (`$inline$` / `$$display$$`). This is the source of truth.
- **`notes/NN_<slug>.html`** — a standalone browser view of the same notes (marked.js + MathJax,
  Lyceum styling), regenerable from the `.md`. Committed so the notes open with one click on any
  machine.

| Lecture | Sections | File |
|---|---|---|
| 01 | 1.1 Systems of Linear Equations · 1.2 Row Reduction & Echelon Forms | `notes/01_systems-and-row-reduction.md` |

## How it's consumed (generator lives in `tools/linear-algebra/`)

| Target | Tool | Output |
|---|---|---|
| Browser view | `tools/linear-algebra/notes/render_html.py <notes.md>` | standalone `.html` next to the `.md` |

## Adding the next lecture

Run `/linear-algebra-notes` — it reads the next uncovered sections of Lay directly, drafts the
notes in the house format, runs an independent reviewer pass against the book, and renders the
HTML. See `.claude/commands/linear-algebra-notes.md`.
