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

`scripts/transcripts/`, `scripts/drafts/`, `scripts/exemplars.json` should be gitignored — high churn, not source of truth.
