---
description: Draft + review the next set of Linear Algebra pre-lecture notes, read directly from Lay 5e
argument-hint: "[sections, e.g. 1.3-1.4] or blank to continue from the last lecture"
---

Produce the **next** set of personal **pre-lecture notes** for the Linear Algebra course —
generated **from scratch by reading the textbook directly**, then independently reviewed.

These are the instructor's own preparation notes for *giving* the lecture — NOT the website
recap. Match the established house format exactly.

## Sources
- **Textbook (read it directly):** `~/Downloads/Linear_Algebra_and_Its_Applications_5th.pdf`
  — Lay, *Linear Algebra and Its Applications*, 5th ed. Read the actual pages for the target
  sections with the Read tool (`pages:`), including every definition, theorem, and worked
  example. Do **not** write from memory of the subject.
- **House format (match it):** the existing notes in `content/linear-algebra/notes/` — study
  `01_systems-and-row-reduction.md` before drafting.
- **Course plan / section order:** the syllabus under `edu-web/scripts/syllabi/` (27-week plan,
  all 58 sections through §8.6).

## Which sections
`$ARGUMENTS` names the sections to cover. If blank, pick up where the notes leave off: find the
highest-numbered file in `content/linear-algebra/notes/`, read its section coverage, and do the
next lecture's sections in Lay's order.

## Steps
1. **Scope.** Determine the target sections and the next lecture number `NN` (zero-padded,
   continuing the sequence). Choose a short slug from the section titles →
   `content/linear-algebra/notes/NN_<slug>.md`.
2. **Read the book.** Read those pages of the Lay PDF directly. Pull the actual definitions,
   theorems, and examples — with the book's numbering — so the notes are grounded in the text,
   not recalled.
3. **Draft** `content/linear-algebra/notes/NN_<slug>.md` in the house format:
   - Header block: text, chapter, sections covered, and a short *roadmap* blockquote.
   - `## §X.Y` sections with `### Core Definitions`, theorems, worked examples.
   - **Prove every theorem.** Chase down any proof the book defers to an appendix rather than
     omit it. (standing rule)
   - **Worked examples show start → final result** — always give the initial system/matrix AND
     the final answer; skipping intermediate algebra is fine, skipping either endpoint is not.
   - Teaching callouts as blockquotes: `⚠` watch-fors, `💡` why-it-matters.
   - LaTeX math: `$inline$`, `$$display$$`; matrices via `\begin{bmatrix}`.
   - **No meta-noise** — no provenance/typography/self-containment asides ("(boxed)", "(from the
     author)"); keep only what teaches.
4. **Independent review (required).** Spawn a fresh reviewer agent (Explore or general-purpose,
   which has NOT seen the drafting) to check the draft **against the Lay pages**:
   - every definition/theorem stated correctly and completely, with the book's numbering;
   - every theorem actually proved; no hand-waving;
   - every worked example shows both endpoints and lands on the right answer;
   - nothing important in the target sections is missing; no meta-noise crept in.
   Have it return a concrete list of corrections.
5. **Revise** the `.md` per the review until the reviewer signs off.
6. **Render** the browser view:
   `python3 tools/linear-algebra/notes/render_html.py content/linear-algebra/notes/NN_<slug>.md`
7. **Update** the lecture table in `content/linear-algebra/README.md`.
8. **Report** the sections covered, the review corrections you applied, and the two output paths.
   Do not commit/push unless asked (or on an explicit "sync").
