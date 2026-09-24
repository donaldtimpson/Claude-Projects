---
description: End-to-end for the newest lecture — quiz, lecture notes, transcript, YouTube chapters, and community quiz posts, all published
argument-hint: "[course name, e.g. \"Grammar\" or \"Linear Algebra\"]"
---

# /current-quiz

For the newest video in one of Donald's current courses, run the **whole per-lecture pipeline and publish
everything**:

1. a 10-question quiz — imported, then **published**
2. lecture notes — imported, then **published**
3. the transcript — imported into catalog search
4. YouTube chapter timestamps — **pushed live** to the video description
5. the quiz as 10 YouTube Community Quiz posts, 12h apart — **scheduled live**

Donald has authorized this command to publish end to end (decided 2026-09-24). Don't stop to ask for
review between steps. The dry-runs below are still mandatory, but they are **self-checks**: read the
output or screenshot yourself, and continue unless something is actually wrong.

**Choosing the course.** Several courses can be flagged `isCurrent: true` at once. If `$ARGUMENTS` names a
course, match it against the titles of the `isCurrent` courses (case-insensitive substring, e.g.
"grammar" → "Beginning Grammar (2026)"). If there is no argument and more than one course is current, ask
Donald which one. The target video is that course's video with the most recent `publishedAt`.

Run every `npx tsx` command from the **edu-web repo root**. The scripts use `process.cwd()`.

## Steps

1. **Locate the target video.** Run a small Prisma one-off (`scripts/_one-off.ts`, deleted afterwards)
   that lists the `isCurrent: true` courses, picks one as described above, and selects its newest video
   by `publishedAt desc`. Capture the course id, the Prisma `Video.id`, `youtubeVideoId`, the title, and
   `durationSeconds`.

2. **Pre-flight: skip what already exists.** Check each target on its own and only produce the missing
   ones. Report what you skip. If every target already exists, stop.
   - **Quiz exists if** `scripts/drafts/{videoId}.json` or `scripts/drafts/_imported/{videoId}.json`
     exists, OR the DB has any `QuizQuestion` rows for this video. If the rows exist but are all still
     `isDraft: true`, skip generation but still publish them (step 9) and post them (step 11).
   - **Notes exist if** `scripts/notes/{videoId}.md` exists, OR the DB has a `LectureNote` row. Same
     rule: publish an existing draft note.
   - **Chapters exist if** `scripts/chapters/{youtubeVideoId}.txt` exists. The file is keyed by
     **youtubeVideoId**, and chapters are not stored in the DB.
   - **Community posts exist if** `scripts/community-posts/{youtubeVideoId}.json` exists.

3. **Fetch the transcripts.** Run `npx tsx scripts/fetch-transcripts.ts {courseId}` (plaintext, used for
   the quiz and notes) and `npx tsx scripts/fetch-timed-transcripts.ts --video {youtubeVideoId}` (with
   cue start times, used for chapters). Both are idempotent.
   - **Rate-limited (`HTTP Error 429` on the `en` track)?** Download the auto-caption track directly into
     the scratchpad:
     `yt-dlp --no-update --skip-download --write-auto-sub --sub-lang 'en-orig' --sub-format vtt --output '%(id)s.%(ext)s' 'https://www.youtube.com/watch?v={youtubeVideoId}'`
     (quote the URL, because zsh globs the `?`). Then run it through the scripts' own parsers:
     `stripVtt` from `fetch-transcripts.ts` writes `scripts/transcripts/{youtubeVideoId}.txt`, and
     `parseVtt` from `fetch-timed-transcripts.ts` writes `scripts/transcripts-timed/{youtubeVideoId}.json`.
     Copy those functions into a scratch script rather than importing them, because the scripts run
     `main()` on import.
   - **Captions not generated yet?** This is common for the first few hours after an upload. It shows up
     as "no captions", an empty `.txt` or `[]` marker, or no subtitle track in yt-dlp's output. Do NOT
     write anything. Instead, **set a check-in timer**:
     - Use `CronCreate` with `recurring: false`, pinned about **2 hours** from now on an off-minute (not
       :00 or :30). Set the prompt to `/current-quiz <the same course argument>`.
     - Tell Donald the video, that captions aren't ready yet, and the exact time of the check-in.
     - Stop there. The re-run starts again at step 1 and skips anything already done.
     - If the check-in also finds no captions, set another timer, backing off to about 4 hours. After
       about 24 hours with no captions, stop setting timers and tell Donald. Captions may be disabled on
       the video.
     - `CronCreate` jobs live only while this Claude session stays open. Say so, and mention that
       `/schedule` can run a cloud routine if he's closing the session.
   - Before relying on the plaintext transcript, remove the empty marker file if an earlier run left one.

4. **Read the whole transcript and the references.** The transcript has very long lines, so page through
   it until you know every topic covered. Also read, for tone and structure:
   - the previous lecture's notes (`scripts/notes/`), quiz (`scripts/drafts/_imported/`), and chapters
     (`scripts/chapters/`) for the same course;
   - for **Grammar**, the lesson's source file `content/grammar/lessons/*.json` (Harvey's 1880 text: its
     definitions, practice sets, and answers). Where the lecture and the source differ, follow the
     lecture's terminology, e.g. "possessive case" versus the JSON's "possessive adjective". Mention the
     alternate term in passing.

5. **Generate 10 quiz questions** in the house style of [[feedback-quiz-drafting]] (auto-memory):
   - Mostly conceptual. Use numbers only where the lecture itself worked a clean example.
   - **Distractor parity:** all four options should match in length, specificity, and grammatical shape.
     Read the four options as a row, and normalize any that stand out.
   - **Length parity:** the correct option must never be the longest. Keep option lengths within about
     15–20% of each other, and put nuance in `explanation`.
   - **Honest framing.** Don't name the instructor ("Donald says…"); state the point as the course's
     position.
   - **Pronouns:** use masculine for an arbitrary individual. Use feminine for personification and for
     real, specific women. Judge by context.
   - Use **BC/AD**, never BCE/CE.
   - **Plain unicode math, never `$…$`.** The quiz player doesn't render LaTeX. Grep the JSON for `$`
     before importing; any hit is a bug.
   - Spread `correctIndex` across 0–3.
   - **Keep every prompt ≤ 140 characters.** Community posts carry the prompt in the caption, and the
     scheduler warns above 140.
   - Explanations: match the course. Linear Algebra and Grammar use them. University Physics leaves them
     `""`.

6. **Generate the lecture notes.** This is always part of the run. Follow `scripts/lecture-notes-style.md`
   exactly:
   - the four sections `## Overview` / `## Key Concepts` / `## Worked Example` / `## Summary`;
   - aligned equation blocks with `$$` at column 0, never stacked `$$`;
   - `\tan^{-1}` rather than `\arctan`;
   - in the worked example, the equation first, then the substitution;
   - no instructor name and no meta-references.
   See also [[feedback_math_notation]]. Write the notes to `scripts/notes/{videoId}.md`, named by the Prisma
   `Video.id`.
   - **Silently correct verbal and arithmetic slips** ([[feedback_transcript_corrections]]). Check every
     worked computation yourself, because board arithmetic in the transcript is sometimes wrong. Say in the
     final report what you corrected, but never in the notes.
   - **Grammar** keeps the four headers. Its `## Worked Example` holds the lesson's practice sets, worked
     with answers (`**Part (a): …**` numbered lists, as in earlier lessons).
   - **Humanities (e.g. History):** "Worked Example" doesn't fit. Those courses need the adapted sections
     (Overview / Key Themes & Figures / Notable Episode / Summary), and `validate-notes.ts` must be relaxed
     first. Flag this and skip only the notes; carry on with everything else.

7. **Generate chapter timestamps.** Follow `scripts/lecture-chapters-style.md`, working from the TIMED
   transcript.
   - Choose about 10–12 genuine topic shifts. Long, example-dense lectures can use up to about 16.
   - The first chapter is `0:00`. Every timestamp must snap to a real segment `start`, run strictly
     ascending, sit at least about 45 seconds apart, and avoid the final ~3 minutes.
   - Titles are terse (2–6 words), in sentence case, with plain unicode math.
   - **Never** copy the description's `VIDEO CONTENTS` outline.
   - Write to `scripts/chapters/{youtubeVideoId}.txt`. To find timestamps, grep phrases across adjacent
     segments of the JSON and print the segments around each candidate.

8. **Write the quiz draft file** to `scripts/drafts/{videoId}.json` (`videoId` is the Prisma `Video.id`):
   ```json
   { "scope": "video", "videoId": "<Prisma Video.id>",
     "questions": [{ "prompt": "...", "options": ["A","B","C","D"], "correctIndex": 0, "explanation": "..." }] }
   ```

9. **Validate, import, and publish.**
   - **Quiz:** `npx tsx scripts/import-drafts.ts --dry-run`, which should report `would insert 10`. Then
     run `npx tsx scripts/import-drafts.ts`, and afterwards
     `mv scripts/drafts/{videoId}.json scripts/drafts/_imported/`.
   - **Notes:** `npx tsx scripts/validate-notes.ts`, then `npx tsx scripts/import-notes.ts`.
   - **Transcript:** `npx tsx scripts/import-transcripts.ts --video {youtubeVideoId}`, which makes the
     lecture searchable.
   - **Publish both:** run a one-off Prisma script that calls `quizQuestion.updateMany` and
     `lectureNote.updateMany` with `{ where: { videoId, isDraft: true }, data: { isDraft: false } }`, then
     delete the script. The lecture page reads the DB dynamically, so nothing needs revalidating.

10. **Push the chapters live.**
    - Run `npx tsx scripts/validate-chapters.ts`.
    - Run `npx tsx scripts/push-chapters.ts --video {youtubeVideoId} --dry-run`. Check that the existing
      description is untouched and the `Chapters` block is appended or replaced.
    - Then run `npx tsx scripts/push-chapters.ts --video {youtubeVideoId}`.
    - This needs `YOUTUBE_OAUTH_*` in `.env`. If it's missing, tell Donald to run
      `scripts/youtube-auth.ts` and carry on with step 11.

11. **Schedule the community quiz posts.** The quiz is published by now, so run this in the same pass.
    - **Avoid slot collisions.** Read the `scheduled[].when` values in every
      `scripts/community-posts/*.json`. The default start is tomorrow 9:00 AM, with posts at 9 AM and
      9 PM. If another lecture's posts overlap that window, offset the new set by 6 hours with
      `--start "YYYY-MM-DD 15:00"` so the two sets alternate at 3 AM/3 PM. Precedent: Grammar Lesson 3
      and Lesson 5.
    - **Dry run:** `npx tsx scripts/post-quiz-community.ts --video {youtubeVideoId} [--start …] --dry-run`.
      Check the printed plan, including any `warnings:` line (for example, a prompt over 140 characters).
      Fix problems in the DB and in the `_imported` JSON, then re-run the dry run. Read the newest
      screenshot in `scripts/community-debug/` to confirm the prompt, options, correct-answer mark,
      explanation, and scheduled date.
    - **Live:** run the same command without `--dry-run`, using `run_in_background` because it takes a few
      minutes. It writes the marker `scripts/community-posts/{youtubeVideoId}.json`. If it aborts
      partway, resume with `--from <n>` and the same `--start`.
    - If the login session is missing, tell Donald to run `npx tsx scripts/yt-community-auth.ts`. Selectors
      are fragile; see CLAUDE.md, "Community quiz-post scheduler".

12. **Report back** with:
    - the course and video;
    - the quiz (10 published) and the notes (published);
    - the transcript (searchable);
    - the chapters (count, pushed);
    - the community posts (first-to-last schedule, and any offset used);
    - any slips you silently corrected in the notes;
    - anything skipped, and why.
    Include the lecture URL `https://timpson-lyceum.vercel.app/courses/{courseId}/{videoId}` and point to
    YouTube Studio → Content → Posts → Scheduled for last-minute edits.

## Notes

- This command is the per-lecture autopilot for the pipelines documented in `edu-web/CLAUDE.md`: the
  quiz-draft, lecture-notes, YouTube chapters, catalog search, and community quiz-post scheduler sections.
- `yt-dlp` must be installed (`brew install yt-dlp`).
- The derived files (`scripts/drafts/`, `notes/`, `chapters/`, `transcripts*/`, `community-posts/`) are
  gitignored, so a normal run has nothing to commit.
