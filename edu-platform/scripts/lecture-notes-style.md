# Lecture-notes style guide (STEM / proof courses)

You are writing student-facing **study notes** for one lecture of an online course, generated from that
lecture's YouTube auto-caption transcript. Follow this guide exactly.

## Reading the transcript
The transcript file has very long lines and your first Read may be truncated. Page through it with
offset/limit or grep so you understand ALL topics actually covered before writing.

## Required structure — exactly these four headers, in this order
An importer validates their presence, so use them verbatim:

```
## Overview
## Key Concepts
## Worked Example
## Summary
```

## What goes in each section
- **Overview** — 3–6 sentences: what the lecture teaches and why it matters.
- **Key Concepts** — the substance: definitions, theorems, rules, formulas. Organize with **bold term
  labels** and bullet points; use bold sub-section labels if the lecture has distinct parts.
- **Worked Example** — one (or two short) representative problem(s)/proof(s) from the lecture. State the
  symbolic rule/formula FIRST, then put the numeric/algebraic work on a NEW line. Use a single
  `$$\begin{aligned} ... \end{aligned}$$` block: symbolic form on line 1, the substitution/steps on the
  following line(s), aligned on `=` (or another relation). For a proof-based lecture, a short
  representative derivation/proof sketch is fine.
- **Summary** — 4–6 bullet takeaways.

## Style
- Audience: students studying the material. Accurate, clear, well-organized.
- Comprehensive but NOT bloated — cover the lecture's real topics; do not pad.
- Focus on THIS lecture's actual subject. If the transcript drifts into a preview of a later lecture's
  topic, keep the notes on the current lecture (mention a preview in at most one phrase).

## Math / KaTeX (rendered with remark-math + rehype-katex)
- Inline math `$...$`, display math `$$...$$`.
- NEVER stack multiple consecutive `$$...$$` blocks — they render run-together with no visible break.
  Put any set of related equations/steps in ONE display block using
  `\begin{aligned} ... \\[4pt] ... \end{aligned}`, aligned on `=` (or another relation).
- Inverse trig functions: always write `\tan^{-1}`, `\sin^{-1}`, `\cos^{-1}` — never `\arctan` etc.
- Use standard notation for the subject (e.g. `\lim_{x \to a}`, `\frac{d}{dx}`, `\int_a^b`, `\sum`, set
  and logic symbols, etc.).

## Critical corrections
- The speaker (the instructor) frequently misspeaks/swaps terms or numbers (and sometimes self-corrects).
  SILENTLY correct such verbal slips against well-established, correct results — state the concept
  correctly. Do NOT add any disclaimer / "heads up" / note explaining that the lecture misspoke.
- Do NOT mention the instructor by name. Do NOT reference "the transcript", "the video", or
  "the lecture said" — write the notes as standalone study material.
