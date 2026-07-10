# Problem-set authoring style guide (Linear Algebra — Lay 5e)

House style for the per-section problem sets in `scripts/problem-sets/{section}.md`, imported by
`scripts/import-problem-sets.ts` as draft `ProblemSet` rows (same draft-gate convention as the quiz
and notes pipelines). One file per Lay 5e section; **58 sections across Chapters 1–8**.

## Audience & sourcing

- Course: an **introductory** Linear Algebra course taught to **strong students**. Problems should
  build from routine fluency up to genuine challenge — do not stay at the mechanical level.
- Problems are **original**, written to match each section's topics/learning objectives — **not**
  Lay's verbatim exercises. Topic coverage follows the book; wording and numbers are ours.
- Correct silently any slip (this is authored content, not a transcript). No disclaimers, no
  meta-commentary.

## File format

```markdown
---
section: "5.6"
title: "5.6 Exercises"
points: 20
extraCreditPoints: 4
attachmentUrl: ""        # optional; omit or leave "" if none
---
_Discrete Dynamical Systems_

**1.** (3 pts) First problem statement …

**2.** (3 pts) …

<!-- SOLUTIONS -->

**1.** Worked solution …

**2.** …
```

- **Frontmatter** (between the `---` fences): `section` (string `"N.N"`, drives ordering), `title`
  (literal `"N.N Exercises"`), `points` (integer — the graded core total; = sum of all core
  per-problem point tags), `extraCreditPoints` (integer — sum of all `••` extra-credit tags),
  optional `attachmentUrl`.
- The **body** (problems, shown publicly) and the **solution** (instructor-only) are separated by a
  line containing exactly `<!-- SOLUTIONS -->`.
- Start the body with the **section topic name** in italics (`_Discrete Dynamical Systems_`) as a
  lead line, since the public title is only `"5.6 Exercises"`.

## Per-set structure

- **6–10 problems** per section (lighter for the shorter application sections, e.g. 3.x, 4.8, 4.9,
  5.6–5.8, 6.6, 6.8, 7.5, 8.5–8.6).
- Difficulty arc within each set: **routine → conceptual/True–False → proof/challenge**.
  - Include at least one **True/False with justification** item (Lay's signature — trains precise
    reading of definitions and theorems). "State whether each is true or false and justify."
  - Include at least one **proof or "explain why"** item for the strong-student stretch. Mark the
    hardest as extra credit (`••`) where appropriate.
- **Point tags** on every problem: `(3 pts)` for core, `(3 pts ••)` for extra credit. Core tags sum
  to the frontmatter `points`; `••` tags sum to `extraCreditPoints`. Aim for `points` ≈ 20 per set.
- **Multi-part items** (a problem with `(a)`, `(b)`, `(c)`, …): put each labelled part on its **own
  line**, and separate the parts (and the stem) with a **blank line** so each renders on a separate
  line (the renderer collapses single newlines, so parts on consecutive lines would run together).
  This applies to the **solutions** too — each part's solution on its own blank-line-separated line.
  Do **not** string parts inline in one sentence (`… (a) X and (b) Y`). Example:

  ```markdown
  **6.** (3 pts) State whether each is true or false, and justify.

  (a) …

  (b) …

  (c) …
  ```

## Solutions

- Every problem gets a **complete worked solution** (not just the answer): show the reasoning/steps,
  and for T/F items state the verdict + the definition/theorem that settles it.
- Number solutions to match the problems (`**1.**`, `**2.**`, …).

## Math / KaTeX conventions

- Inline math `$…$`; display math `$$…$$` with the `$$` delimiters **on their own lines** (an
  indented `$$` inside a list item breaks remark-math — see `lecture-notes-style.md`). To keep a
  display block associated with a numbered problem, put the `$$…$$` on its own lines *after* the
  prose, not indented under the list marker.
- Matrices: `\begin{bmatrix} 1 & 2 \\ 3 & 4 \end{bmatrix}`. Augmented systems: use
  `\left[\begin{array}{cc|c} … \end{array}\right]`.
- Vectors as columns via `bmatrix`; use `\mathbf{v}`, `\mathbf{x}` for named vectors. Transpose
  `A^{\mathsf T}` (or `A^\top`). Inverse `A^{-1}`. Determinant `\det A`.
- Inverse trig (if it ever appears): `\tan^{-1}`, never `\arctan` (see [[math-notation]]).
- The validator renders every file through the real MarkdownNotes KaTeX pipeline and fails on any
  parse error — keep math well-formed.

## Voice

- No instructor name and no first person in public-facing text (validator rejects "Donald" /
  "I "). Address the student in the imperative ("Find…", "Show that…", "Determine whether…").
  (See [[feedback-transcript-corrections]].)

---

## Canonical section list (Lay 5e, Chapters 1–8) — 58 sets

Titles are `"N.N Exercises"`; the italic topic name below is the body lead line.

**Chapter 1 — Linear Equations in Linear Algebra**
- 1.1 Systems of Linear Equations
- 1.2 Row Reduction and Echelon Forms
- 1.3 Vector Equations
- 1.4 The Matrix Equation Ax = b
- 1.5 Solution Sets of Linear Systems
- 1.6 Applications of Linear Systems
- 1.7 Linear Independence
- 1.8 Introduction to Linear Transformations
- 1.9 The Matrix of a Linear Transformation
- 1.10 Linear Models in Business, Science, and Engineering

**Chapter 2 — Matrix Algebra**
- 2.1 Matrix Operations
- 2.2 The Inverse of a Matrix
- 2.3 Characterizations of Invertible Matrices
- 2.4 Partitioned Matrices
- 2.5 Matrix Factorizations
- 2.6 The Leontief Input–Output Model
- 2.7 Applications to Computer Graphics
- 2.8 Subspaces of ℝⁿ
- 2.9 Dimension and Rank

**Chapter 3 — Determinants**
- 3.1 Introduction to Determinants
- 3.2 Properties of Determinants
- 3.3 Cramer's Rule, Volume, and Linear Transformations

**Chapter 4 — Vector Spaces**
- 4.1 Vector Spaces and Subspaces
- 4.2 Null Spaces, Column Spaces, and Linear Transformations
- 4.3 Linearly Independent Sets; Bases
- 4.4 Coordinate Systems
- 4.5 The Dimension of a Vector Space
- 4.6 Rank
- 4.7 Change of Basis
- 4.8 Applications to Difference Equations
- 4.9 Applications to Markov Chains

**Chapter 5 — Eigenvalues and Eigenvectors**
- 5.1 Eigenvectors and Eigenvalues
- 5.2 The Characteristic Equation
- 5.3 Diagonalization
- 5.4 Eigenvectors and Linear Transformations
- 5.5 Complex Eigenvalues
- 5.6 Discrete Dynamical Systems
- 5.7 Applications to Differential Equations
- 5.8 Iterative Estimates for Eigenvalues

**Chapter 6 — Orthogonality and Least Squares**
- 6.1 Inner Product, Length, and Orthogonality
- 6.2 Orthogonal Sets
- 6.3 Orthogonal Projections
- 6.4 The Gram–Schmidt Process
- 6.5 Least-Squares Problems
- 6.6 Applications to Linear Models
- 6.7 Inner Product Spaces
- 6.8 Applications of Inner Product Spaces

**Chapter 7 — Symmetric Matrices and Quadratic Forms**
- 7.1 Diagonalization of Symmetric Matrices
- 7.2 Quadratic Forms
- 7.3 Constrained Optimization
- 7.4 The Singular Value Decomposition
- 7.5 Applications to Image Processing and Statistics

**Chapter 8 — The Geometry of Vector Spaces**
- 8.1 Affine Combinations
- 8.2 Affine Independence
- 8.3 Convex Combinations
- 8.4 Hyperplanes
- 8.5 Polytopes
- 8.6 Curves and Surfaces
