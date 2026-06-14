# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Educational course website for Donald Timpson (@donaldDtimpson on YouTube). Surfaces YouTube playlists as courses, with per-video quizzes and per-playlist tests. Admin UI for authoring quiz content. Phase 2 (not yet built) will add student accounts and progress tracking.

## Commands

```bash
npm run dev          # start dev server at localhost:3000
npm run build        # production build
npx tsc --noEmit     # type check without building
npx prisma migrate dev --name <name>   # apply schema changes + regenerate client
npx prisma generate  # regenerate client after schema edits without migrating
npx prisma studio    # browser-based DB viewer
```

## Environment Variables (`.env`)

```
DATABASE_URL        # Neon PostgreSQL connection string
YOUTUBE_API_KEY     # Google Cloud — YouTube Data API v3 (READ-ONLY: playlist/video sync)
YOUTUBE_CHANNEL_ID  # UCxxxxxxxxxxxxxxxxxxxxxxxx (not the handle, the ID)
ADMIN_PASSWORD      # Password for /admin area

# OAuth — only needed to WRITE to YouTube (the chapters pipeline). Set the first
# two from a "Desktop app" OAuth client; mint the third via scripts/youtube-auth.ts.
YOUTUBE_OAUTH_CLIENT_ID
YOUTUBE_OAUTH_CLIENT_SECRET
YOUTUBE_OAUTH_REFRESH_TOKEN
```

## Architecture

**Stack:** Next.js (App Router) · Prisma 5 · PostgreSQL (Neon) · Tailwind CSS

> Note: Prisma 5 is pinned because Node 21 is installed locally. Prisma 6+ requires Node 20.19+/22.12+.

**Database models** (`prisma/schema.prisma`):
- `Course` — mirrors a YouTube playlist (`youtubePlaylistId` unique key)
- `Video` — mirrors a playlist item (`youtubeVideoId` unique key, `position` for ordering)
- `QuizQuestion` — belongs to either a `Video` (per-video quiz) OR a `Course` with `videoId: null` (playlist test), never both. `isDraft: true` hides the question from students; admin still sees it with a "Draft" badge + Publish button.
- `LectureNote` — Markdown study notes, 1:1 with `Video` (unique `videoId`). Same `isDraft` gate as `QuizQuestion`. See the lecture-notes pipeline section below.

**Key lib files:**
- `lib/db.ts` — Prisma client singleton (safe for hot reload in dev)
- `lib/youtube.ts` — YouTube Data API v3 client; `fetchChannelPlaylists()` and `fetchPlaylistVideos(playlistId)` handle pagination automatically
- `lib/admin-auth.ts` — password comparison helper

**Admin auth:** Cookie-based (`admin_auth`). `middleware.ts` guards all `/admin/*` routes, redirecting to `/admin/login` if the cookie is missing or wrong. The cookie is set by `POST /api/admin/login` and cleared by `DELETE` on the same route.

**YouTube sync:** `POST /api/youtube/sync` (requires `x-admin-password` header) fetches all channel playlists then all videos per playlist, upserting into `Course` and `Video` tables. Called from the admin dashboard's Sync button (`app/admin/SyncButton.tsx`).

**Quiz flow (public):** `app/courses/[courseId]/[videoId]/QuizPlayer.tsx` is a client component that handles all quiz state locally (no server round-trips during answering). Score is shown at end but not persisted (Phase 2).

**Quiz authoring (admin):** `app/admin/QuizEditor.tsx` is a shared client component used by both the per-video editor (`/admin/courses/[courseId]`) and the playlist test editor (`/admin/test/[courseId]`). It reads the admin password from the cookie to attach to API calls.

## Route Map

| Route | Purpose |
|---|---|
| `/` | Course grid (server component, revalidates hourly) |
| `/courses/[courseId]` | Video list + playlist test CTA |
| `/courses/[courseId]/[videoId]` | YouTube embed + video quiz |
| `/courses/[courseId]/test` | Full playlist test |
| `/admin` | Dashboard: course list + Sync YouTube button |
| `/admin/login` | Password login |
| `/admin/courses/[courseId]` | Edit per-video quiz questions |
| `/admin/test/[courseId]` | Edit playlist test questions |
| `POST /api/youtube/sync` | Sync playlists+videos from YouTube |
| `GET/POST /api/quiz` | List or create quiz questions |
| `PATCH/DELETE /api/quiz/[id]` | Update or delete a question |
| `POST /api/admin/login` | Set auth cookie |
| `DELETE /api/admin/login` | Clear auth cookie (logout) |

## Setup After Clone

1. Set all four env vars in `.env`
2. `npx prisma migrate dev --name init`
3. `npm run dev`
4. Go to `/admin`, log in, click **Sync YouTube**

## Phase 2 (Not Yet Built)

- NextAuth.js student accounts
- `QuizAttempt` table to persist per-student scores
- Comment/question threads per video

## Quiz-draft generation pipeline (`scripts/`)

Free workflow for backfilling quizzes across the YouTube back catalog without paying for the Anthropic API. The "LLM" is Claude in a session — read transcript + exemplars from context, write draft JSONs, no external API call.

**Setup (once per machine):**
- `brew install yt-dlp`
- DB must have the `isDraft` column applied (`npx prisma migrate dev`)

**Workflow:**

1. `npx tsx scripts/export-exemplars.ts` — writes `scripts/exemplars.json` with every published `QuizQuestion`. Used as few-shot style guide.
2. `npx tsx scripts/fetch-transcripts.ts [courseId]` — uses yt-dlp to pull YouTube auto-captions for every `Video` (or just one course's videos), strips VTT to plaintext, caches at `scripts/transcripts/{youtubeVideoId}.txt`. Idempotent — skips existing files.
3. **Ask Claude in a session: "generate drafts for course X"**. Claude reads the relevant `scripts/transcripts/*.txt` files + `scripts/exemplars.json` and writes one `scripts/drafts/{videoId}.json` per video. JSON shape:
   ```json
   { "scope": "video", "videoId": "<Prisma Video.id, NOT youtubeVideoId>",
     "questions": [{ "prompt": "...", "options": ["A","B","C","D"], "correctIndex": 0, "explanation": "..." }] }
   ```
   For playlist tests use `{ "scope": "course", "courseId": "...", "questions": [...] }`.
4. `npx tsx scripts/import-drafts.ts --dry-run` (preview), then drop the flag to insert. Inserts as `isDraft: true`. Idempotent at the file level — skips a draft file if any drafts already exist for that video/course.
5. Review/edit/publish in `/admin/courses/{id}` or `/admin/test/{id}`.

**Public reads** (video page, course test page, attempt review, `_count` badges, `GET /api/quiz`) all filter `isDraft: false`. Admin SSR pages and `GET /api/quiz?includeDrafts=true` (admin-only) include drafts.

`scripts/transcripts/`, `scripts/drafts/`, `scripts/exemplars.json`, `scripts/bank-*.json` should be gitignored — high churn, not source of truth.

## Consistent quizzes across repeated offerings

Several subjects were taught multiple times (same textbook, different years) with non-aligned lectures. To
keep the un-quizzed offerings consistent with the one that's already done, **reuse the finished offering's
questions verbatim wherever a topic matches**, keyed by topic — NOT by lecture number (a sibling lecture may
merge two anchor lectures or split one across two). 10 per lecture, 30 per course test (was 20 before
2026-06-05; the extra 10 weight later-course material to balance coverage).

1. **Anchor = the already-published offering.** Its questions are the canonical bank.
   `npx tsx scripts/export-exemplars.ts --course <anchorCourseId> --out scripts/bank-<subject>.json`
   writes the bank topic-ordered (by `lecturePosition`), so each question shows its source lecture.
2. `npx tsx scripts/fetch-transcripts.ts <siblingCourseId>` (pre-`touch` review/no-material videos to skip).
3. **Map sibling→anchor by TOPIC.** If sibling lectures are topic-titled, map from titles. If generic
   ("Lecture N"), first run a read-only "mapper" subagent that reads the sibling transcripts and returns a
   `sibling-position → anchor-position` table (the anchor's topic arc, derived from the bank, guides it).
4. **Partition into batches with DISJOINT anchor pools** (each anchor lecture owned by exactly one batch) so
   parallel drafting agents can't reuse the same anchor question twice. Each agent: read transcript → confirm
   the real topic (mapper guesses are often wrong — the agent MUST verify from the transcript) → reuse
   matching anchor questions verbatim → author new (house style) only to fill to 10 or for sibling-only
   topics. Cap: each anchor question reused at most once across the sibling.
5. **Course test:** reuse the anchor's 20 only for topics the sibling actually covered; author replacements
   for topics it skipped (e.g. a sibling that stops before integration). Don't test uncovered material.
6. **Validate before import** (a node script): 10 per video file / 10·20·30 per course file, 4 options, 0 instructor-name mentions,
   no intra-course duplicate prompts, and the correct answer is never the conspicuously-longest option
   (reused anchor questions are exempt — they're already-reviewed canon; only rebalance NET-NEW ones).
   Then `import-drafts.ts --dry-run`, import, review in `/admin`, publish.

**Gotcha:** before importing a new sibling's drafts, move the previous sibling's `scripts/drafts/*.json`
into `scripts/drafts/_imported/`. `import-drafts.ts` is idempotent only against existing *drafts* — if the
prior batch was already *published* (isDraft:false), it would re-insert duplicates. (`import-drafts.ts` reads
only top-level `scripts/drafts/*.json`, not the `_imported/` subdir.)

Reuse rate tracks how aligned the offerings are: clean re-teaches (e.g. Calculus 2021, DM 2022) hit ~85–95%;
reordered/divergent ones (e.g. DM 2019/2020, which add group theory / Fermat / relativity not in the anchor)
land ~50–55% with the rest authored new and topic-appropriate.

## Lecture-notes generation pipeline (`scripts/`)

Same zero-API-cost, human-in-the-loop shape as the quiz pipeline. Notes live in the `LectureNote` model
(1:1 with `Video`, unique `videoId`) behind the same `isDraft` gate: imported as drafts, reviewed in
`/admin`, then published. Public reads (`app/(site)/courses/[courseId]/[videoId]/page.tsx`,
`GET /api/notes`) show a note only when `isDraft: false`; the admin course page and
`GET /api/notes?includeDrafts=true` include drafts.

**Workflow:**

1. `npx tsx scripts/fetch-transcripts.ts [courseId]` — reuse the quiz pipeline's transcript cache at
   `scripts/transcripts/{youtubeVideoId}.txt` (already populated for most of the catalog).
2. **Ask Claude in a session: "generate lecture notes for course X"**. Claude reads the relevant
   `scripts/transcripts/*.txt` and writes one Markdown file per lecture to `scripts/notes/{videoId}.md`
   (filename = Prisma `Video.id`, **not** youtubeVideoId). Source = transcript backbone + well-established
   subject knowledge to fix obvious mis-transcriptions; no textbook-PDF ingestion. Structured format,
   four sections required by the validator:
   ```markdown
   ## Overview
   ## Key Concepts        (term → definition bullets)
   ## Worked Example       (numbered steps; LaTeX math via $…$ / $$…$$ renders with KaTeX)
   ## Summary              (takeaway bullets)
   ```
3. `npx tsx scripts/validate-notes.ts` (structure + instructor-name check) → `npx tsx scripts/import-notes.ts --dry-run`
   (preview) → drop the flag to insert as `isDraft: true`. Idempotent: skips a file if a note already
   exists for that video.
4. Review/edit/publish per video in `/admin/courses/{id}` (the `NotesEditor` above each video's quiz).

`scripts/notes/` is gitignored (derived, not source of truth — the DB is).

| Route added | Purpose |
|---|---|
| `GET /api/notes?videoId=` | Fetch a video's note (drafts hidden unless admin + `includeDrafts=true`) |
| `PUT /api/notes` | Upsert note content for a video (creates as draft) |
| `PATCH/DELETE /api/notes/[id]` | Publish/unpublish (toggle `isDraft`) or delete |

## YouTube chapters pipeline (`scripts/`)

Generate chapter timestamps from a lecture's transcript and write them into the **YouTube video
description** via the official Data API v3 (`videos.update`, `part=snippet`). Same
generate → review → push shape as the quiz/notes pipelines. Editing descriptions is
API-sanctioned (unlike community/quiz posts, which have no API — see the parked idea).

**Auth:** the read path (`lib/youtube.ts`) uses the read-only `YOUTUBE_API_KEY`. WRITING needs
**OAuth 2.0** (`youtube.force-ssl` scope). One-time setup: create a "Desktop app" OAuth client
in the same Google Cloud project, put its id/secret in `.env` as `YOUTUBE_OAUTH_CLIENT_ID` /
`_CLIENT_SECRET`, then `npx tsx scripts/youtube-auth.ts` (loopback consent flow) writes
`YOUTUBE_OAUTH_REFRESH_TOKEN`. Set the consent screen to **In production** so the refresh token
is long-lived (Testing-mode tokens expire after 7 days). Helpers live in `lib/youtube-oauth.ts`.

**Gotcha:** `videos.update` with `part=snippet` REPLACES the snippet, so `updateVideoDescription`
fetches the full snippet and resends title/categoryId/tags/languages, swapping only the
description.

**Workflow:**

1. `npx tsx scripts/fetch-timed-transcripts.ts [courseId]` — like `fetch-transcripts.ts` but
   keeps cue start times, writing `scripts/transcripts-timed/{youtubeVideoId}.json` as
   `[{ start, text }]` (the plaintext pipeline strips timecodes). Idempotent.
2. **Ask Claude in a session: "generate chapters for course X"** — reads the timed transcript +
   `scripts/lecture-chapters-style.md`, picks ~5–12 topic-shift breakpoints snapped to real cue
   starts, writes `scripts/chapters/{youtubeVideoId}.txt` (one `0:00 Title` line per chapter).
3. `npx tsx scripts/validate-chapters.ts` — enforces YouTube's clickable-chapter rules (first
   stamp `0:00`, ≥3, strictly ascending, each ≥10s, last within the video's `durationSeconds`).
4. `npx tsx scripts/push-chapters.ts <courseId|--video <id>> --dry-run` — prints the proposed
   description; drop `--dry-run` to push live. The chapters go in a managed block under a
   `Chapters` header; re-pushing replaces that block in place (idempotent, non-destructive to
   the rest of the description). `videos.update` is 50 quota units (10k/day default).

`scripts/transcripts-timed/` and `scripts/chapters/` are gitignored (derived/ephemeral).

**Future:** extend `/current-quiz` to also draft chapters for the newest video (alongside the
quiz + notes it already generates), and optionally persist chapters to render clickable seek
points on the on-site lecture page.

## Catalog search (`lib/search.ts`, `scripts/`)

Global full-text search across courses, lectures, published notes, and **transcripts** — so a topic
can be found by what was *said*, not just titles. Header search box (`components/SearchBox.tsx`,
wrapped in `<Suspense>` in `SiteHeader.tsx`) → `/search?q=` (`app/(site)/search/page.tsx`); also
`GET /api/search?q=`. Both call `searchCatalog()` in `lib/search.ts`.

- **Storage:** `Transcript` model (1:1 with `Video`): `content` (plaintext) + `segments` (timed
  `[{start,text}]` JSON, when available). Public, no draft gate.
- **Backend:** Postgres FTS via GIN expression indexes (`to_tsvector('english', …)`) added in the
  `add_transcript_and_fts` migration; queried with raw SQL (`websearch_to_tsquery` + `ts_rank` +
  `ts_headline`). The to_tsvector expressions in `lib/search.ts` must match the index expressions.
- **Deep-link to the moment:** a transcript hit's earliest matching segment → `?t=<seconds>` on the
  lecture link; the lecture page passes it as `?start=` to the YouTube embed. Lectures lacking timed
  segments still match (plaintext) and link to the top.
- **Import (required — transcript files are gitignored, not deployed):**
  `npx tsx scripts/fetch-transcripts.ts [courseId]` (plaintext) and `fetch-timed-transcripts.ts`
  (timed) populate the caches, then `npx tsx scripts/import-transcripts.ts [--dry-run]` upserts them
  into the `Transcript` table (idempotent; keyed by youtubeVideoId). Re-run after syncing new videos.

Snippets come from rough auto-captions, so results lean on the lecture title + timestamp with the
snippet as supporting context. Search currently includes sibling offerings (not just canonical) —
filter to canonical later if duplicates feel noisy.
