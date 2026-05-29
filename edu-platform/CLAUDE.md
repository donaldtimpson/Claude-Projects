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
YOUTUBE_API_KEY     # Google Cloud — YouTube Data API v3
YOUTUBE_CHANNEL_ID  # UCxxxxxxxxxxxxxxxxxxxxxxxx (not the handle, the ID)
ADMIN_PASSWORD      # Password for /admin area
```

## Architecture

**Stack:** Next.js (App Router) · Prisma 5 · PostgreSQL (Neon) · Tailwind CSS

> Note: Prisma 5 is pinned because Node 21 is installed locally. Prisma 6+ requires Node 20.19+/22.12+.

**Database models** (`prisma/schema.prisma`):
- `Course` — mirrors a YouTube playlist (`youtubePlaylistId` unique key)
- `Video` — mirrors a playlist item (`youtubeVideoId` unique key, `position` for ordering)
- `QuizQuestion` — belongs to either a `Video` (per-video quiz) OR a `Course` with `videoId: null` (playlist test), never both. `isDraft: true` hides the question from students; admin still sees it with a "Draft" badge + Publish button.

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
merge two anchor lectures or split one across two). Still 10 per lecture, 20 per course test.

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
6. **Validate before import** (a node script): exactly 10/20 per file, 4 options, 0 instructor-name mentions,
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
