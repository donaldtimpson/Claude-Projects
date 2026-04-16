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
- `QuizQuestion` — belongs to either a `Video` (per-video quiz) OR a `Course` with `videoId: null` (playlist test), never both

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
