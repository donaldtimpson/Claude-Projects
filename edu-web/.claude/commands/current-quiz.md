---
description: Generate a draft quiz, lecture notes, AND YouTube chapter timestamps for the latest video in the current course
---

# /current-quiz

For the newest video in Donald's currently-active course, generate a 10-question draft quiz, draft
lecture notes, **and** draft YouTube chapter timestamps. The quiz and notes import as hidden drafts
into the admin UI for review; the chapters are previewed with a dry-run and pushed live to the
video's YouTube description **only on Donald's confirmation** (chapters have no hidden-draft state).
Scheduling the quiz as YouTube Community Quiz posts is a **deferred** follow-on (step 10) that runs
later — only after Donald has published the quiz — since it needs the published questions.

The "current course" is the `Course` row with `isCurrent: true`. The target video is the one in that
course with the most recent `publishedAt`.

## Steps

1. **Locate the target video.** Run a small Prisma query (e.g. via `npx tsx scripts/_one-off.ts`, then delete the file) that selects the `isCurrent: true` course and its newest video by `publishedAt desc`. Capture both the Prisma `Video.id` and `youtubeVideoId`. If multiple courses are flagged `isCurrent`, stop and ask Donald which one.

2. **Pre-flight checks.** Check the quiz, notes, and chapters targets independently, and only generate the one(s) that don't already exist (report what you skip; if ALL THREE already exist, stop):
   - **Quiz exists if:** `scripts/drafts/{videoId}.json` or `scripts/drafts/_imported/{videoId}.json` exists, OR the DB has any `QuizQuestion` rows for this video.
   - **Notes exist if:** `scripts/notes/{videoId}.md` exists, OR the DB has a `LectureNote` row for this video.
   - **Chapters exist if:** `scripts/chapters/{youtubeVideoId}.txt` exists (chapter files are keyed by **youtubeVideoId**, not the Prisma `Video.id`). Chapters aren't stored in the DB, so this file is the only local marker.

3. **Fetch the transcript(s).** Run `npx tsx scripts/fetch-transcripts.ts {courseId}` to cache the plaintext transcript (for the quiz + notes). Read `scripts/transcripts/{youtubeVideoId}.txt`. If empty or missing, stop and report. If generating chapters, ALSO run `npx tsx scripts/fetch-timed-transcripts.ts --video {youtubeVideoId}` to cache the TIMED transcript (`scripts/transcripts-timed/{youtubeVideoId}.json`, with cue start times) — chapter generation needs the timecodes that the plaintext transcript strips out. Both are idempotent.

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

6. **Generate chapter timestamps.** Read `scripts/lecture-chapters-style.md` and follow it. From the TIMED transcript (`scripts/transcripts-timed/{youtubeVideoId}.json`), pick ~10–12 genuine topic-shift breakpoints (up to ~14–16 for long, example-dense lectures), in spoken order. First chapter MUST be `0:00`; titles terse (~2–6 words), sentence case, plain unicode math (e.g. `τ = Iα`, `r × F`) never LaTeX, drop "Worked example:" prefixes. Strictly ascending, each ≥ ~10s (aim ≥ ~45s), nothing in the last ~3 minutes. Base titles ONLY on what is actually said — **never** mirror the description's textbook `VIDEO CONTENTS` outline (it follows the book and often doesn't match the lecture's order/coverage). Write one `M:SS Title` / `H:MM:SS Title` per line to `scripts/chapters/{youtubeVideoId}.txt` (filename = **youtubeVideoId**). Unlike notes, chapters work for any discipline, so the humanities caveat in step 5 does NOT block them.

7. **Write the quiz draft file** to `scripts/drafts/{videoId}.json` (videoId = Prisma `Video.id`, NOT the YouTube id):
   ```json
   {
     "scope": "video",
     "videoId": "<Prisma Video.id>",
     "questions": [
       { "prompt": "...", "options": ["A","B","C","D"], "correctIndex": 0, "explanation": "" }
     ]
   }
   ```

8. **Validate, dry-run, and import/preview all three.** Run all `npx tsx` commands from the **edu-platform repo root** (the importers use `process.cwd()`):
   - **Quiz:** `npx tsx scripts/import-drafts.ts --dry-run` (verify it validates and `would insert 10`), then `npx tsx scripts/import-drafts.ts` to commit (as `isDraft: true`), then `mv scripts/drafts/{videoId}.json scripts/drafts/_imported/{videoId}.json` so it isn't re-imported.
   - **Notes:** `npx tsx scripts/validate-notes.ts` (structure check), then `npx tsx scripts/import-notes.ts` to insert the note (as `isDraft: true`). No move needed — `import-notes.ts` is idempotent against any existing `LectureNote` row, so the `.md` is simply skipped on future runs.
   - **Chapters:** `npx tsx scripts/validate-chapters.ts` (YouTube-rules + duration check), then `npx tsx scripts/push-chapters.ts --video {youtubeVideoId} --dry-run` to preview the merged description. **Do NOT push live automatically** — chapters edit the public YouTube description with no hidden-draft state. Show Donald the dry-run output and the exact live command, and push (`npx tsx scripts/push-chapters.ts --video {youtubeVideoId}`) only after he confirms (or let him run it). Requires the one-time OAuth setup (`YOUTUBE_OAUTH_*` in `.env`); if it's missing, generate + validate the chapters and tell him to run `scripts/youtube-auth.ts` first.
   - **Transcript (for search):** `npx tsx scripts/import-transcripts.ts --video {youtubeVideoId}` — upserts the plaintext (+ timed segments, if `fetch-timed-transcripts` ran) into the `Transcript` model so the new lecture shows up in catalog search. Idempotent, no review gate (captions are public); just needs the transcript fetched in step 3.

9. **Report back** with the course title, video title, quiz count inserted, notes status (inserted/skipped), chapters status (generated + dry-run shown, awaiting Donald's OK to push live — or pushed if he already confirmed), transcript imported (searchable: yes/no), and the admin URL to review/publish quiz + notes: `https://timpson-lyceum.vercel.app/admin/courses/{courseId}` (or `http://localhost:3000/admin/courses/{courseId}` for local). In the admin course hub, expand the lecture's row to find the Notes editor (with Edit/Preview) and the quiz editor. **Remind Donald** that once he publishes the quiz, step 10 (community quiz posts) is available.

10. **(Deferred — only after the quiz is PUBLISHED) Schedule community quiz posts.** This step is outward-facing and reads the **published** quiz (`isDraft: false`), so it does NOT run in the same pass as the draft import above — the quiz is still a draft here. Once Donald has reviewed and **published** the quiz in admin, schedule its 10 questions as YouTube Community Quiz posts, 12h apart:
   - **Dry-run first:** `npx tsx scripts/post-quiz-community.ts --video {youtubeVideoId} --dry-run` — composes the first post, sets its schedule, screenshots to `scripts/community-debug/`, and posts **nothing**. Show Donald the schedule plan + screenshot.
   - **On his explicit OK, run live** (drop `--dry-run`) to schedule all 10. Posts are **scheduled**, so he reviews/deletes them in YouTube Studio (Content → Posts → Scheduled) before they publish. `--from <n>` resumes if it aborts mid-run (pin `--start "YYYY-MM-DD HH:mm"` to keep spacing aligned with already-scheduled posts); a marker `scripts/community-posts/{youtubeVideoId}.json` makes it idempotent (`--force` to override).
   - Requires the one-time login `npx tsx scripts/yt-community-auth.ts`; if the session is missing, generate nothing and tell Donald to run that first. This is browser automation (no API for community posts) — selectors are fragile; see CLAUDE.md "Community quiz-post scheduler".

## Notes

- Same pipelines documented in `edu-platform/CLAUDE.md` ("Quiz-draft generation pipeline", "Lecture-notes generation pipeline", "YouTube chapters pipeline", "Catalog search", and "Community quiz-post scheduler") — this command is the per-lecture autopilot for all of them (quiz + notes + chapters draft, plus the transcript import that makes the lecture searchable; community quiz posts are the deferred step 10).
- `yt-dlp` must be installed (`brew install yt-dlp`).
- Don't auto-commit the quiz/notes imports; Donald reviews and publishes from the admin UI before anything goes live to students (drafts are hidden from public reads).
- **Chapters are the one outward-facing step:** they edit the public YouTube description directly. Always dry-run and get Donald's explicit OK before the live `push-chapters` (the push is idempotent — it replaces a managed `Chapters` block and leaves the rest of the description untouched).
- **Community quiz posts (step 10) are deferred AND outward-facing:** they need the quiz *published* (not draft) and post to the public channel, so they never run automatically in the draft-generation pass — only later, after Donald publishes, and only on his explicit OK after a dry-run. Same caution as chapters.
