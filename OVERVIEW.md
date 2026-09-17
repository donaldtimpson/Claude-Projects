# Claude-Projects — what's in this repo

One git repo, four shipped applications, plus the shared content and generators that feed them.
Three of the four are **Timpson Lyceum** — a course site built on Donald Timpson's YouTube
catalog (@donaldDtimpson) and two native clients for it. The fourth, **Sound It Out**, is an
unrelated children's reading app that shares nothing but the repo.

| Directory | What it is | Stack | Size |
|---|---|---|---|
| `edu-web/` | Timpson Lyceum — the website, the database, the admin CMS, and the mobile API | Next.js 16 (App Router) · Prisma 6 · Neon Postgres · Tailwind · Vercel | ~220 files, ~20k lines |
| `edu-ios/` | Lyceum for iOS/iPadOS — the reference mobile client | SwiftUI, iOS 18+, SwiftData, xcodegen | 50 files, ~8.8k lines |
| `edu-android/` | Lyceum for Android — a port of the iOS app | Kotlin + Jetpack Compose, minSdk 26 | 37 files, ~7.7k lines |
| `edu-reading/` | Sound It Out — early-reading flashcards for children | SwiftUI, no network layer at all | 33 files, ~4.6k lines |
| `content/` | Source-of-truth JSON for grammar and reading content | — | — |
| `tools/` | Python generators that turn `content/` into app bundles and slide decks | Python 3 | — |

---

## edu-web — the platform

The website and the backend everything else talks to. It mirrors YouTube playlists into
`Course`/`Video` rows and layers coursework on top of them.

**Catalog.** A course grid on `/`, subject `/categories/[slug]` pages, a course page with its
lecture list, resources and problem sets, and a lecture page with the YouTube embed, quiz, notes
and threaded discussion. `/map` draws the course dependency graph (`CourseLink` — recommended and
required prerequisites, logical rather than college-catalog ones). `POST /api/youtube/sync` pulls
playlists and videos from the YouTube Data API; the playlist is the source of truth for a course's
title and description, so blurbs are pushed *to* YouTube rather than edited in the DB.

**Quizzes and tests.** `QuizQuestion` rows belong either to a video (a 10-question lecture quiz) or
to a course with `videoId: null` (a 30-question playlist test). `isDraft` gates them: drafts are
invisible to students and carry a Publish button in admin. The player grades entirely client-side
and persists only the final score.

**Lecture notes.** `LectureNote`, 1:1 with a video — Markdown with KaTeX math, same draft gate,
with a print/PDF route.

**Problem sets.** `ProblemSet` holds problems and worked solutions, both Markdown + KaTeX.
Solutions render *inline with the problem they answer* (matched by number or heading, with a
safe fallback to an appended block if the two halves don't line up), behind per-problem reveal
toggles. `solutionsPublic` is the single switch for visibility. Sets link many-to-many to the
lectures they cover, and have a print route with an optional answer key.

**Search.** Postgres full-text search over courses, lectures, published notes and *transcripts*, so
a topic is findable by what was said. A transcript hit deep-links to `?t=<seconds>` on the lecture.
The header search box is a live type-ahead that survives navigation.

**Student accounts and gamification.** NextAuth credentials auth (separate from the cookie-based
admin auth, which `proxy.ts` enforces over `/admin/*`). Persisted quiz attempts, watched-state
progress, a dashboard, ~30 badges (`lib/gamification/engine.ts`), a 🔥 daily streak, and a
`/leaderboard` with public `/leaderboard/[handle]` scholar profiles.

**Spaced repetition.** `/review` is a cross-course daily review deck built from missed questions
(`QuestionReview`, `lib/srs.ts`), with its own badges and streak feed.

**Practice drills.** `/drills` — 62 timed, scored drills in seven categories, behind a two-level
hub (categories → drills) with client-side search and a device-local "Continue" strip of recents.
23 are **procedural**: a pure `generate(level)` function producing an endless problem stream, with
one generic player that grades any drill via a discriminated union on the input mode
(`numeric | choice | fields`). Categories: Mental Math (9), Trigonometry (2), Calculus (2), Linear
Algebra (4), Geography (6). Math renders through KaTeX, diagrams are inline SVG, and unit-circle
answers are matched by canonical key rather than float comparison. The other 39 are **bundled
banks** built from `content/grammar/`: 19 lesson-homework drills and 20 grammar practice drills.
Finishing a session writes a `DrillAttempt`, which drives drill badges and the streak. Drills are
fully playable signed out.

**Classroom and gradebook.** A live-class layer: `Section`s with a generated join code (students
may only join the *current* course), `Enrollment` rosters, `Assignment`s submitted as a link or as
an auto-graded lesson drill, and a weighted gradebook (`lib/gradebook.ts`) combining attendance
from lecture watches, best-attempt quiz and test scores, homework, midterm and final, with weights
stored per section.

**Admin CMS.** `/admin` covers courses, quizzes, the playlist test, notes, categories, resources,
course links, problem sets, classes, announcements, achievements, drills and comment moderation.

**Mobile API.** `app/api/mobile/v1/*` — Bearer JWT (plus Sign in with Apple), reusing the same user
store as web through `lib/auth-core.ts` and the same engagement logic via `lib/services/activity.ts`.
~40 endpoints cover catalog, courses, videos, notes, quizzes, review, drills, progress, badges,
scholars, search, the course map, comments and a sync manifest. Offline writes carry a `clientId`
that the server dedups (`IdempotencyKey`).

---

## Content pipelines (`edu-web/scripts/`)

A recurring shape: **generate → validate → dry-run → import → review in admin → publish.** The
"LLM" is Claude in a session reading files from context, so none of it costs API money.

- **Quiz drafts** — `yt-dlp` pulls auto-captions into a transcript cache; Claude writes draft JSONs
  against exported exemplars; a validator checks counts, option parity and duplicate prompts; then
  import as drafts. For subjects taught more than once, questions from the finished offering are
  reused *verbatim keyed by topic* (never by lecture number), with disjoint anchor pools so
  parallel agents can't reuse the same question twice.
- **Lecture notes** — same shape, four required sections (Overview / Key Concepts / Worked Example /
  Summary), validated for structure before import.
- **YouTube chapters** — timed transcripts → ~5–12 breakpoints snapped to real cue starts →
  validated against YouTube's clickable-chapter rules → pushed into the video description via
  OAuth `videos.update`, into a managed block that re-pushes idempotently.
- **Course descriptions** — hand-authored text per playlist, pushed to YouTube, then re-synced.
- **Community quiz posts** — the one non-API pipeline. YouTube has no endpoint for community posts,
  so a local Playwright script drives the youtube.com composer to schedule a lecture's 10 quizzes as
  Quiz posts 12h apart. Local-only, never deployed, and always dry-run first.
- `/current-quiz` is a slash command that runs quiz + notes + chapters for the newest video.

---

## edu-ios — Lyceum for iPhone and iPad

SwiftUI, universal, iOS 18+. The `.xcodeproj` is generated by xcodegen and gitignored. A
`.sidebarAdaptable` TabView gives bottom tabs on iPhone and a sidebar on iPad: **Learn / Review /
Drills / Profile**.

Learn is the catalog, course detail, lecture (YouTube IFrame player in a WebView, plus KaTeX/Markdown
notes), quizzes, course tests, problem sets and the course map — drawn as a real pannable graph.
Review is the spaced-repetition deck. Drills is the full 62 in three modes (Practice, Learn with
Leitner boxes, Rapid Fire) with native Swift generators, a bundled grammar bank, and a bundled
vector atlas for the geography drills — no image assets, so "Name the Country", "Name the State" and
the tap-to-locate variants all draw from data. Profile covers progress, grades, badges, the Hall of
Scholars and account deletion.

`APIClient` handles async/await with token refresh, tokens live in the Keychain, and engagement
writes (quiz attempts, review grades, drill sessions, watch progress) queue in SwiftData when offline
and replay on reconnect. Signed-out use is deliberate: lectures, notes, quizzes and drills all work
without an account; only Review and saved progress need one.

Build 1.0.0 (1) is uploaded to App Store Connect (`APP_STORE.md` is the submission runbook).

---

## edu-android — Lyceum for Android

A Kotlin/Compose port against the same mobile API, with the iOS app as the explicit reference —
same screens, same words, and `Theme.kt` keeps the iOS colour names (`parchment`, `ink`, `gold300`)
so a screen can be carried across without renaming anything. Catalog, search, course detail,
lectures, notes, quizzes, tests, daily review, progress, badges, Hall of Scholars and all the drills
in all three modes are done, and signed-out behaviour matches iOS.

Three known gaps, all documented: the video player is unverified on real hardware (the emulator
won't decode the embed, same as the iOS Simulator); the course map is a prerequisite list rather
than a drawn graph; and the offline write queue isn't ported, so a drill finished with no connection
is lost. No Play Store account yet, so debug builds only.

---

## edu-reading — Sound It Out

A standalone iOS app for pre-readers, separate from the Lyceum in every way: different audience,
different branding, **no accounts, no networking code at all, nothing stored off the device.**

The whole interface is one card: tap it to hear it, tap again to turn it, or swipe. Six decks —
Letter Sounds, Blending, Words, Sentences, Sight Words as heart words, and a Look and Say deck of
211 words across 446 pictures — plus drawn Colours, Shapes and Numbers decks. Optional on-device
speech recognition listens while a card is up and turns it when the word is read; it is built so it
can only ever say yes, never mark a child wrong.

**Find It** is the one unambiguous input in the app: the app says (or prints) a word and the child
taps the right picture from two to four, with distractors drawn from the same deck. **My World**
adds per-child players with no passwords, thirteen badges, and five earned themes that reskin the
whole app — deliberately no streak. Everything adult-facing sits behind a parental gate, as the
Kids Category guideline requires, including the CC BY attributions for the 406 licensed photographs.

Decks are data (`content/reading/reading.json`, synced by `tools/sync-content.sh`), bundled Andika
is load-bearing typography, and vowels are red everywhere.

---

## Shared content and tooling

`content/grammar/` is the single source for the Grammar course, drawn from Harvey's *Elementary
Grammar & Composition* (1880): 19 lesson JSONs (the teaching content), 19 homework banks of 40–45
items, and a 20-drill practice bank. `tools/grammar/build_app_content.py` emits byte-identical JSON
into both `edu-web/lib/drills/grammar/data/` and `edu-ios/Resources/Grammar/`, and
`tools/grammar/slides/` renders the same lesson JSON into `.pptx` decks that convert cleanly to
Google Slides, with an HTML preview for review. Edit the source, never the generated bundles.

A lesson is **aced** by a flawless 30-question homework run, derived server-side from `DrillAttempt`
rows and served to the clients via `GET /api/mobile/v1/me/lessons` — so the ✦ is one fact across
web, iOS and Android.
