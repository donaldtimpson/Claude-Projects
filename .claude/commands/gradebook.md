---
description: Sync edu-web Linear Algebra grades into the school's cagradebook.com gradebook
argument-hint: "[blank = full sync, or e.g. 'dry run' / 'only homework' / 'skip Lecture 9']"
---

Push the latest Linear Algebra grades from edu-web into **cagradebook.com** (Centennial
Academy's gradebook, section *Linear Algebra — 2027 S1*). There's no import or API, so
Playwright drives the real UI. Tooling: `edu-web/scripts/cagradebook/`. Run everything from
`edu-web/`.

Request: $ARGUMENTS

## Steps

1. **Export** (read-only on the DB):
   `npx tsx scripts/cagradebook/export-la.ts` → `scripts/cagradebook/output/la-grades.json`.
2. **Dry run**: `node scripts/cagradebook/push-grades.mjs --dry-run`. It lists the columns it
   would create and the cells it would change. Narrow with `--only "<regex>"` /
   `--skip "<regex>"` on column names when the request asks for that.
   - Before going live, sanity-check the plan. New columns should be recent work (a new
     lecture's attendance/quiz, newly graded problem sets, a new test). Changed cells on
     **old** columns mean a grade was edited in edu-web. Push those too, but name them in the
     report.
   - If the newest lecture came out in the last day or two, most students will show Z for its
     attendance and quiz. Donald said to push those anyway (they'll update on the next sync),
     but mention it.
3. **Push**: rerun without `--dry-run`, unless the request was only a dry run. The script
   creates missing columns, writes only cells that differ, then reloads and verifies every
   targeted cell. It's idempotent, so after a failure just rerun it and it resumes.
4. **Report**: columns added, cells changed, and the verified status. Read
   `scripts/cagradebook/output/push-verified.png` and quote each student's cagradebook Total.

## When something breaks

- **"session expired"**: run `node scripts/cagradebook/probe.mjs` in the background and tell
  Donald to log in to the Chromium window it opens. It waits up to 10 minutes for the grid,
  then saves the session to `.session/`. Then retry.
- **"Grid rows missing from mapping.json"**: the school roster changed. Add the new student to
  `scripts/cagradebook/mapping.json` (gitignored: `gradebookName` exactly as the grid shows it,
  plus their edu-web email). Ask Donald who it is if the edu-web match isn't obvious.
- **Error screenshots** land in `scripts/cagradebook/output/` (`push-error.png`, `ERROR-*.png`).
  Look before guessing.

## Mapping rules (decided 2026-11-14, don't relitigate)

- **Attendance**: one 1-pt column per lecture. Present/late = 1, absent = Z, excused = X.
  edu-web derives attendance from watches, with manual marks overriding.
- **Quizzes**: one column per lecture quiz, out of its question count. **Untaken = Z.** This
  deliberately differs from edu-web, which leaves untaken quizzes out of the average.
- **Homework**: one column per problem set that has at least one score. Blank stays blank
  (unscored). Extra-credit scores above max are allowed.
- **Unit Tests**: edu-web's custom *Tests* items, only once scored. edu-web stores no test
  dates; set them in `TEST_DATES` in `export-la.ts`. Ask Donald for the date, or estimate it
  from the lectures as was done for Test 1.
- edu-web's course test (generated from the quizzes) is **not** used. Tests are problem sets.
- **Roster**: edu-web students with no mapping (Ayrion Pledger, dropped; "Bob", test account)
  are ignored. edu-web "Ashyss Timpson" = grid "Timpson, Alexander".
- **Midterm**: if a midterm score is entered in edu-web, `export-la.ts` doesn't export it yet.
  Add a Midterm column (category *Midterm*) before syncing it.

Never delete or rename columns in cagradebook without asking. Commit any script changes per the
usual sync workflow.
