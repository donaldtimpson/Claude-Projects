# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Educational course website for Donald Timpson (@donaldDtimpson on YouTube). Surfaces YouTube playlists as courses, with per-video quizzes and per-playlist tests, lecture notes, transcript search, and procedural practice drills. Admin UI for authoring content. Students have accounts (NextAuth) with persisted quiz scores, progress tracking, spaced-repetition review, gamification (badges/streaks/leaderboard), threaded discussion, and a live-class registration + gradebook layer.

## Commands

```bash
npm run dev          # start dev server at localhost:3000
npm run build        # production build
npx tsc --noEmit     # type check without building
npx prisma migrate dev --name <name>   # apply schema changes + regenerate client
npx prisma generate  # regenerate client after schema edits without migrating
npx prisma studio    # browser-based DB viewer
```

> **Migrations in this Claude Code env:** `migrate dev` needs a TTY, which isn't available here.
> Hand-write the migration SQL under `prisma/migrations/<timestamp>_<name>/migration.sql` (edit
> `schema.prisma` to match), then `npx prisma migrate deploy && npx prisma generate`. Local + prod
> share the one Neon DB, so a migration hits production immediately — make it additive/backward-safe.

## Environment Variables (`.env`)

```
DATABASE_URL        # Neon PostgreSQL connection string
YOUTUBE_API_KEY     # Google Cloud — YouTube Data API v3 (READ-ONLY: playlist/video sync)
YOUTUBE_CHANNEL_ID  # UCxxxxxxxxxxxxxxxxxxxxxxxx (not the handle, the ID)
ADMIN_PASSWORD      # Password for /admin area
NEXTAUTH_SECRET     # NextAuth JWT signing secret (student accounts)
NEXTAUTH_URL        # Base URL for NextAuth callbacks (e.g. http://localhost:3000)
NEXT_PUBLIC_SITE_URL # Optional — absolute base URL for share links/metadata (falls back to a default)

# OAuth — only needed to WRITE to YouTube (the chapters pipeline). Set the first
# two from a "Desktop app" OAuth client; mint the third via scripts/youtube-auth.ts.
YOUTUBE_OAUTH_CLIENT_ID
YOUTUBE_OAUTH_CLIENT_SECRET
YOUTUBE_OAUTH_REFRESH_TOKEN
```

## Architecture

**Stack:** Next.js (App Router) · Prisma 6 · PostgreSQL (Neon) · Tailwind CSS

> Note: local runtime is **Node 22** (`.nvmrc` = 22, `engines.node` = "22.x"). On **Prisma 6** (6.19.3) as of 2026-07-01. `@prisma/client`, `prisma`, and `@prisma/adapter-neon` must stay on the same 6.x line together; `@neondatabase/serverless` stays `^0.10.4` (still satisfies the v6 adapter). **`driverAdapters` is GA in 6** — no `previewFeatures` flag needed. The v6 Neon adapter takes a **PoolConfig** (`new PrismaNeon({ connectionString })`) and builds the pool itself; v5 took a pre-built `Pool` (see `lib/db.ts`). Scripts that use a bare `new PrismaClient()` (no adapter) still work — the Rust query engine is still the default in 6.
>
> Prisma **7** is the current latest but is a scoped migration deferred on purpose: it swaps to the `prisma-client` generator (ESM output + required `output` path) and would rewrite the `@prisma/client` import in ~27 files. Do it on its own and re-run the read-only DB smoke test against the shared Neon DB.

**Database models** (`prisma/schema.prisma`):
- `Course` — mirrors a YouTube playlist (`youtubePlaylistId` unique key)
- `Video` — mirrors a playlist item (`youtubeVideoId` unique key, `position` for ordering)
- `QuizQuestion` — belongs to either a `Video` (per-video quiz) OR a `Course` with `videoId: null` (playlist test), never both. `isDraft: true` hides the question from students; admin still sees it with a "Draft" badge + Publish button.
- `LectureNote` — Markdown study notes, 1:1 with `Video` (unique `videoId`). Same `isDraft` gate as `QuizQuestion`. See the lecture-notes pipeline section below.
- `Transcript` — plaintext + timed segments per `Video`, powers catalog search (see that section).
- `Comment` — per-`Video` discussion, single-level threaded (`parentId` self-relation; soft-delete via `deletedAt` when a comment has replies).
- **Student accounts & gamification:** `User`/`Session` (NextAuth credentials), `QuizAttempt` (persisted scores), `VideoProgress` (watched state), `UserAchievement` (badges), `QuestionReview` (spaced repetition), `DrillAttempt` (practice drills). See the drills / spaced-repetition sections and `lib/gamification/`.
- **Classroom layer:** `Section`, `Enrollment`, `Assignment`, `ProblemSet`, `Submission` — live-class registration, rostering, homework, and the weighted gradebook.
- **Catalog structure:** `Category`/`CourseCategory` (subject grouping), `CourseLink` (course dependency graph / `/map`), `Resource`/`CourseResource`, `Announcement`.

**Key lib files:**
- `lib/db.ts` — Prisma client singleton (safe for hot reload in dev)
- `lib/youtube.ts` — YouTube Data API v3 client; `fetchChannelPlaylists()` and `fetchPlaylistVideos(playlistId)` handle pagination automatically
- `lib/admin-auth.ts` — password comparison helper

**Admin auth:** Cookie-based (`admin_auth`). `proxy.ts` (Next 16's renamed middleware convention — exports a `proxy` function) guards all `/admin/*` routes, redirecting to `/admin/login` if the cookie is missing or wrong. The cookie is set by `POST /api/admin/login` and cleared by `DELETE` on the same route.

**Student auth (separate from admin):** NextAuth with a `CredentialsProvider` (email + bcrypt), JWT sessions, sign-in at `/auth/signin`, sign-up at `/auth/signup` (`lib/auth.ts`). `session.user.id` is the canonical current-user id used across server components, API routes, and server actions (`getServerSession(authOptions)`).

**YouTube sync:** `POST /api/youtube/sync` (requires `x-admin-password` header) fetches all channel playlists then all videos per playlist, upserting into `Course` and `Video` tables. Called from the admin dashboard's Sync button (`app/admin/SyncButton.tsx`).

**Quiz flow (public):** `app/(site)/courses/[courseId]/[videoId]/QuizPlayer.tsx` is a client component that handles all quiz state locally (no server round-trips during answering). The final score is persisted for signed-in students via `saveQuizAttempt` (`lib/actions.ts`) into `QuizAttempt`, which also drives gamification (badges/streaks/leaderboard).

**Quiz authoring (admin):** `app/admin/QuizEditor.tsx` is a shared client component used by both the per-video editor (`/admin/courses/[courseId]`) and the playlist test editor (`/admin/test/[courseId]`). It reads the admin password from the cookie to attach to API calls.

## Route Map

Public pages live under the `app/(site)/` route group; the table lists paths as seen by users.
Feature-specific routes are also documented in each feature's section below — this is the orientation map, not an exhaustive list.

| Route | Purpose |
|---|---|
| `/` | Course grid (server component, revalidates hourly) |
| `/courses/[courseId]` | Video list, resources, problem sets + playlist test CTA |
| `/courses/[courseId]/[videoId]` | YouTube embed, video quiz, notes, threaded discussion |
| `/courses/[courseId]/test` | Full playlist test |
| `/categories/[slug]` · `/map` | Subject grouping · course dependency graph |
| `/dashboard` · `/leaderboard` · `/leaderboard/[handle]` | Student home · gamification leaderboard + profiles |
| `/review` · `/drills` · `/drills/[slug]` | Spaced-repetition review · practice drills |
| `/search` | Full-text catalog + transcript search |
| `/auth/signin` · `/auth/signup` | Student NextAuth pages |
| `/admin` | Dashboard: course list + Sync YouTube button |
| `/admin/login` | Password login |
| `/admin/courses/[courseId]` | Per-video quiz + notes editor |
| `/admin/test/[courseId]` | Playlist test editor |
| `/admin/{categories,resources,links,problem-sets,classes,announcements,achievements,drills,comments}` | Admin management areas |
| `POST /api/youtube/sync` | Sync playlists+videos from YouTube |
| `GET/POST /api/quiz` · `PATCH/DELETE /api/quiz/[id]` | Quiz question CRUD |
| `GET/POST /api/comments` · `DELETE /api/comments/[id]` | Discussion comments + replies |
| `GET/PUT /api/notes` · `PATCH/DELETE /api/notes/[id]` | Lecture notes |
| `GET /api/search` | Search backend (`lib/search.ts`) |
| `POST/DELETE /api/admin/login` | Set / clear admin auth cookie |
| `/api/auth/[...nextauth]` · `POST /api/auth/signup` | NextAuth handlers · student registration |

Other API routes exist under `app/api/` (categories, resources, announcements, admin course links/offerings) — grep there for the full set.

## Setup After Clone

1. Set the env vars above in `.env` (at minimum `DATABASE_URL`, `NEXTAUTH_SECRET`, `NEXTAUTH_URL`, `ADMIN_PASSWORD`, and the YouTube read keys)
2. `npx prisma migrate deploy && npx prisma generate` (or `migrate dev --name init` on a fresh local DB with a TTY)
3. `npm run dev`
4. Go to `/admin`, log in, click **Sync YouTube**

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
can be found by what was *said*, not just titles. The header `SearchBox` (`components/SearchBox.tsx`,
wrapped in `<Suspense>` in `SiteHeader.tsx`) is a **live type-ahead dropdown**: debounced fetches to
`GET /api/search?q=` show results as you type (spinner + arrow-key nav); it lives in the persistent
layout header, so results survive navigation (re-focus after a mis-click → they're still there).
Enter / "see all" goes to the full `/search?q=` page (`app/(site)/search/page.tsx`, with a route
`loading.tsx` skeleton). Everything calls `searchCatalog()` in `lib/search.ts`.

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

## Practice drills (`/drills`)

Procedurally-generated, timed/scored practice — distinct from quizzes (which draw from the stored
`QuizQuestion` bank). A drill generates an endless stream of random problems **client-side**; there
is no question bank and nothing to author. Three drills ship: `arithmetic`, `unit-circle`, `vectors`.

- **Framework:** a drill type is pure data + a `generate(level)` function (`lib/drills/types.ts`
  `DrillDef`). One generic client player (`components/drills/DrillPlayer.tsx`) renders and grades any
  drill; the only thing that varies is the answer-input mode — a discriminated union on
  `Problem.input` (`numeric` | `choice` | `fields`). The correct answer lives inside the input
  descriptor, so grading is mechanical.
- **Adding a drill** = write `lib/drills/generators/<name>.ts` exporting a `DrillDef`, then add it to
  `DRILLS` in `lib/drills/registry.ts`. The hub card, `/drills/<slug>` route, mode/level selection,
  KaTeX, and persistence all work automatically. Candidates that map onto existing input modes:
  degree↔radian / log rules / derivative-of-power (`numeric`), truth tables / dot-cross + right-hand
  rule (`choice`/`fields`), factoring (`choice`).
- **Math + diagrams:** KaTeX via `components/drills/Tex.tsx` (a thin `katex.renderToString` wrapper,
  lighter than `MarkdownNotes`). Diagrams are inline SVG (`components/drills/DrillDiagram.tsx`) — no
  image hosting. Unit-circle exact values are matched by a **canonical key, never a float compare**;
  `Math.sin` only positions the diagram.
- **Gamification:** finishing a session calls `recordDrillSession` (`lib/actions.ts`), which writes a
  `DrillAttempt` row and direct-grants drill badges (`drill-first`, `drill-streak-10`,
  `drill-sessions-25`, `drill-flawless-timed`) — same idempotent pattern as the review badges, so
  existing scoring is untouched. `DrillAttempt.completedAt` feeds the 🔥 streak via `getStreak` in
  `lib/gamification/engine.ts`. Drills are fully playable signed-out (no persistence, no toast).
- **Per-course discoverability (no code):** attach a `TOOL` Resource whose `url` is an internal path
  like `/drills/unit-circle` to a relevant course — the existing course Resources section renders it.
- **Migration:** `DrillAttempt` was added in `prisma/migrations/20260628000000_add_drill_attempt/`.
  Apply with `npx prisma migrate deploy && npx prisma generate` from `edu-platform/` (no TTY for
  `migrate dev` here; local + prod share the Neon DB).

| Route | Purpose |
|---|---|
| `/drills` | Hub — one card per registered drill |
| `/drills/[slug]` | Difficulty + mode picker, then the drill session |

## Community quiz-post scheduler (`scripts/`, local-only)

Schedules a lecture's 10 published quiz questions as **YouTube Community "Quiz" posts, 12h apart**
(a ~5-day engagement funnel, each linking back to the lecture). Unlike the chapters pipeline, this
is **NOT API-backed**: the YouTube Data API v3 has no endpoint for community/quiz posts, so the only
fully-automated path is **browser automation of the youtube.com composer**. This runs **only locally
on Donald's Mac and is never deployed to Vercel** (Playwright is a devDependency).

**Auth (one-time):** `npx tsx scripts/yt-community-auth.ts` opens a persistent Chrome profile
(`.yt-profile/`, gitignored) headed; log into @donaldDtimpson manually once and the session sticks.
Google blocks sign-in from automation-flagged browsers, so `lib/yt-studio.ts` launches Chrome with
`ignoreDefaultArgs:["--enable-automation"]` + `--disable-blink-features=AutomationControlled` (no
`navigator.webdriver`, no infobar) — that's what lets the manual login through.

**Pieces:**
- `lib/community-post.ts` — pure builder. `buildQuizPosts(prisma, youtubeVideoId, {start, intervalHours})`
  reads the 10 published `QuizQuestion` rows and returns posts. The post **caption carries the question
  prompt** (the quiz module only holds the answer choices + an optional explanation) plus a CTA link to
  `/courses/{courseId}/{videoId}`. Schedule times must land on :00/:15/:30/:45 (the picker's increments).
- `lib/yt-studio.ts` — Playwright helpers: persistent-context launch, `need()` (waits for an expected
  element, else screenshots to `scripts/community-debug/` and **aborts** — never blind-clicks), jitter.
- `scripts/post-quiz-community.ts` — the automation.

**Usage:**
```
npx tsx scripts/post-quiz-community.ts --video <youtubeVideoId> [--dry-run] \
    [--start "YYYY-MM-DD HH:mm"] [--interval-hours 12] [--from <n>] [--force]
```
- `--dry-run` composes the first post + sets its schedule, screenshots, and aborts **before
  confirming** (nothing posts). Always dry-run first.
- `--from <n>` (1-based) resumes mid-run without re-posting earlier ones; pin `--start` to keep the
  spacing aligned with already-scheduled posts.
- On success writes a marker `scripts/community-posts/{youtubeVideoId}.json` (idempotent; `--force`
  overrides). Posts are **scheduled**, so review/delete them in YouTube Studio (Content → Posts →
  Scheduled) before they publish.

**Composer flow (reverse-engineered; selectors are fragile):** youtube.com `/channel/{id}/community`
→ masthead **"Create" → "Create post"** (as of 2026-07 the post-type buttons no longer render inline;
they live behind this menu — `openComposer` clicks both) → "Add a quiz" → fill `Answer N` placeholders
(+ "Add answer" for >2) → per-option "Mark as correct
answer" toggle (option 0 correct by default) → optional "Add an explanation (optional)" → type the
caption into the `[contenteditable]` ("What's on your mind?") via `insertText` → "Action menu" →
"Schedule post" → `#date-picker` calendar (click the `.calendar-day` whose text is the day, past days
are disabled; **read `#date-label-text` back to confirm**) → time `option` (e.g. "9:00 AM") → confirm
"Schedule". Each post reloads the page for a clean composer. If YouTube redesigns the composer, the
selectors here are the first thing to re-check.
