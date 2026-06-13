---
description: Generate a draft quiz AND lecture notes for the latest video in the current course
---

# /current-quiz

For the newest video in Donald's currently-active course, generate **both** a 10-question draft quiz
**and** draft lecture notes, then import each as drafts into the admin UI for review.

The "current course" is the `Course` row with `isCurrent: true`. The target video is the one in that
course with the most recent `publishedAt`.

## Steps

1. **Locate the target video.** Run a small Prisma query (e.g. via `npx tsx scripts/_one-off.ts`, then delete the file) that selects the `isCurrent: true` course and its newest video by `publishedAt desc`. Capture both the Prisma `Video.id` and `youtubeVideoId`. If multiple courses are flagged `isCurrent`, stop and ask Donald which one.

2. **Pre-flight checks.** Check the quiz and the notes targets independently, and only generate the one(s) that don't already exist (report what you skip; if BOTH already exist, stop):
   - **Quiz exists if:** `scripts/drafts/{videoId}.json` or `scripts/drafts/_imported/{videoId}.json` exists, OR the DB has any `QuizQuestion` rows for this video.
   - **Notes exist if:** `scripts/notes/{videoId}.md` exists, OR the DB has a `LectureNote` row for this video.

3. **Fetch the transcript.** Run `npx tsx scripts/fetch-transcripts.ts {courseId}` to cache transcripts for the current course (idempotent — skips ones already cached). Read `scripts/transcripts/{youtubeVideoId}.txt`. If the transcript is empty or missing, stop and report.

4. **Generate 10 quiz questions** following the house style in [[feedback-quiz-drafting]] (auto-memory):
   - Mostly conceptual; numerical only when the lecture itself worked a clean example.
   - **Distractor parity:** every option in a row should match the others in length, specificity, and grammatical shape. Read the four options as a row; if one stands out, normalize.
   - **Length parity:** correct option must not be the longest. Target option lengths within ~15-20% of each other. Move nuance/caveats into the `explanation` field if the correct answer is getting too long.
   - **Honest framing:** describe what happened/what is true, not what an action was "supposed" to accomplish.
   - **No personal-name attribution.** Don't write "Donald says X" or "Per Donald, …" — restate as the position the course takes.
   - **Pronoun convention.** Use **masculine** pronouns (he/him/his) for an arbitrary/generic individual ("a student", "a skater", "an observer"). Reserve the **feminine** for personification (Lady Justice, or a nation/city as *her* — e.g. "Rome") and for an actual specific woman (named or clearly real historical figure). Don't blind-replace — judge by context.
   - **Dates use BC/AD**, never BCE/CE.
   - Spread `correctIndex` across 0–3 (don't pile them all on one index).
   - Match the tone of existing published questions for this course. For University Physics, `explanation` has been left empty — keep it `""` unless Donald asks for explanations.

5. **Generate the lecture notes.** Read `scripts/lecture-notes-style.md` and follow it EXACTLY (four sections `## Overview` / `## Key Concepts` / `## Worked Example` / `## Summary`; aligned equation blocks, never stacked `$$`; `\tan^{-1}` not `\arctan`; equation-first-then-substitution in the worked example; silently correct the speaker's verbal slips with no disclaimer; no instructor name / no meta-references). See also [[feedback_math_notation]] and [[feedback_transcript_corrections]]. Write the notes to `scripts/notes/{videoId}.md` (filename = Prisma `Video.id`).
   - **Humanities caveat:** the style guide and the `## Worked Example` section assume a STEM/proof course. If the current course is a humanities course (e.g. History), the section template needs the discipline-adapted variant (Overview / Key Themes & Figures / Notable Episode / Summary) and `validate-notes.ts` must be relaxed first — stop and flag this rather than forcing a "Worked Example."

6. **Write the quiz draft file** to `scripts/drafts/{videoId}.json` (videoId = Prisma `Video.id`, NOT the YouTube id):
   ```json
   {
     "scope": "video",
     "videoId": "<Prisma Video.id>",
     "questions": [
       { "prompt": "...", "options": ["A","B","C","D"], "correctIndex": 0, "explanation": "" }
     ]
   }
   ```

7. **Validate, dry-run, and import both.** Run all `npx tsx` commands from the **edu-platform repo root** (the importers use `process.cwd()`):
   - **Quiz:** `npx tsx scripts/import-drafts.ts --dry-run` (verify it validates and `would insert 10`), then `npx tsx scripts/import-drafts.ts` to commit (as `isDraft: true`), then `mv scripts/drafts/{videoId}.json scripts/drafts/_imported/{videoId}.json` so it isn't re-imported.
   - **Notes:** `npx tsx scripts/validate-notes.ts` (structure check), then `npx tsx scripts/import-notes.ts` to insert the note (as `isDraft: true`). No move needed — `import-notes.ts` is idempotent against any existing `LectureNote` row, so the `.md` is simply skipped on future runs.

8. **Report back** with the course title, video title, quiz count inserted, notes status (inserted/skipped), and the admin URL to review/publish both: `https://timpson-lyceum.vercel.app/admin/courses/{courseId}` (or `http://localhost:3000/admin/courses/{courseId}` for local). In the admin course hub, expand the lecture's row to find the Notes editor (with Edit/Preview) and the quiz editor.

## Notes

- Same pipelines documented in `edu-platform/CLAUDE.md` ("Quiz-draft generation pipeline" and "Lecture-notes generation pipeline") — this command is the per-lecture autopilot for both.
- `yt-dlp` must be installed (`brew install yt-dlp`).
- Don't auto-commit the imports; Donald reviews and publishes from the admin UI before anything goes live to students (drafts are hidden from public reads).
