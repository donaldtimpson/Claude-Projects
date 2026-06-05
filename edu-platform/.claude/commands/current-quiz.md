---
description: Generate a 10-question draft quiz for the latest video in the current course
---

# /current-quiz

Generate a 10-question draft quiz for the newest video in Donald's currently-active course, then import it as drafts into the admin UI.

The "current course" is the `Course` row with `isCurrent: true`. The target video is the one in that course with the most recent `publishedAt`.

## Steps

1. **Locate the target video.** Run a small Prisma query (e.g. via `npx tsx scripts/_one-off.ts`, then delete the file) that selects the `isCurrent: true` course and its newest video by `publishedAt desc`. Capture both the Prisma `Video.id` and `youtubeVideoId`. If multiple courses are flagged `isCurrent`, stop and ask Donald which one.

2. **Pre-flight checks.**
   - If `scripts/drafts/{videoId}.json` exists OR `scripts/drafts/_imported/{videoId}.json` exists OR the DB already has any QuizQuestion rows for this video — stop and report. Don't silently overwrite or duplicate.

3. **Fetch the transcript.** Run `npx tsx scripts/fetch-transcripts.ts {courseId}` to cache transcripts for the current course (idempotent — skips ones already cached). Read `scripts/transcripts/{youtubeVideoId}.txt`. If the transcript is empty or missing, stop and report.

4. **Generate 10 questions** following the house style in [[feedback-quiz-drafting]] (auto-memory):
   - Mostly conceptual; numerical only when the lecture itself worked a clean example.
   - **Distractor parity:** every option in a row should match the others in length, specificity, and grammatical shape. Read the four options as a row; if one stands out, normalize.
   - **Length parity:** correct option must not be the longest. Target option lengths within ~15-20% of each other. Move nuance/caveats into the `explanation` field if the correct answer is getting too long.
   - **Honest framing:** describe what happened/what is true, not what an action was "supposed" to accomplish.
   - **No personal-name attribution.** Don't write "Donald says X" or "Per Donald, …" — restate as the position the course takes.
   - **Pronoun convention.** Use **masculine** pronouns (he/him/his) for an arbitrary/generic individual ("a student", "a skater", "an observer"). Reserve the **feminine** for personification (Lady Justice, or a nation/city as *her* — e.g. "Rome") and for an actual specific woman (named or clearly real historical figure). Don't blind-replace — judge by context.
   - **Dates use BC/AD**, never BCE/CE.
   - Spread `correctIndex` across 0–3 (don't pile them all on one index).
   - Match the tone of existing published questions for this course. For University Physics, `explanation` has been left empty — keep it `""` unless Donald asks for explanations.

5. **Write the draft file** to `scripts/drafts/{videoId}.json` (videoId = Prisma `Video.id`, NOT the YouTube id):
   ```json
   {
     "scope": "video",
     "videoId": "<Prisma Video.id>",
     "questions": [
       { "prompt": "...", "options": ["A","B","C","D"], "correctIndex": 0, "explanation": "" }
     ]
   }
   ```

6. **Dry-run, then import.**
   - `npx tsx scripts/import-drafts.ts --dry-run` — verify the file validates and `would insert 10`.
   - `npx tsx scripts/import-drafts.ts` — commit the inserts (as `isDraft: true`).
   - Move the file: `mv scripts/drafts/{videoId}.json scripts/drafts/_imported/{videoId}.json` so it doesn't get re-imported.

7. **Report back** with the course title, video title, count inserted, and the admin URL to review/publish: `https://timpson-lyceum.vercel.app/admin/courses/{courseId}` (or `http://localhost:3000/admin/courses/{courseId}` for local).

## Notes

- The pipeline is the same one documented in `edu-platform/CLAUDE.md` under "Quiz-draft generation pipeline" — this command is just the per-lecture autopilot for it.
- `yt-dlp` must be installed (`brew install yt-dlp`).
- Don't auto-commit the import; Donald reviews and publishes from the admin UI before anything goes live to students (drafts are hidden from public reads).
