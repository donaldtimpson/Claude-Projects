# Shipping Lyceum to the App Store

Everything App Store Connect asks for, in the order it asks. Written 2026-08-23
against the state of the repo at that commit.

---

## 0. The one thing blocking everything: enrollment

You need a **paid Apple Developer Program** membership of your own. The only
paid team on this Mac is `busybusy, Inc` (`J7WN5UF5X3`), your employer's — you
can't ship a personal app under it, and the `LGF933VBP2` currently baked into
`project.yml` is a free personal team, which cannot upload to App Store Connect.

1. Go to <https://developer.apple.com/programs/enroll/> and sign in with your
   **personal** Apple ID (not the one tied to busybusy work).
2. Choose **Individual / Sole Proprietor**. You do not need a D-U-N-S number for
   this; that's the organization path.
3. $99/year. Apple verifies identity — usually 24–48 hours, occasionally longer.
   Have a government ID handy.

Two consequences worth knowing before you click:

- **The seller name shown publicly will be your legal name**, "Donald Timpson",
  not "The Timpson Lyceum". Only an organization membership can display a
  business name. If that matters, that's the fork in the road — say so and we
  can look at the org path instead.
- **Your team ID will change.** A paid individual team gets a different ID from
  the personal team. Once enrolled, update `DEVELOPMENT_TEAM` in
  `edu-ios/project.yml` and run `xcodegen generate`. The ID is at
  <https://developer.apple.com/account> → Membership Details.

Nothing else on this page can be done until that clears, so start it first.

---

## 1. Register the bundle ID and create the app record

In App Store Connect, once enrolled:

- **Identifiers** → new App ID → Explicit → `com.timpsonlyceum.Lyceum`.
  Enable no capabilities (Sign in with Apple stays off for v1.0).
- **Apps** → new app:
  - Platform: iOS
  - Name: `The Timpson Lyceum`
  - Primary language: English (U.S.)
  - Bundle ID: the one above
  - SKU: `lyceum-ios-1` (internal only, never shown)
  - User access: Full

---

## 2. Listing metadata

Paste-ready. Character limits are Apple's and these all fit.

**Name** (30 max) — 18 used

```
The Timpson Lyceum
```

**Subtitle** (30 max) — 28 used

```
Lectures, drills, and review
```

**Promotional text** (170 max; editable later without a review)

```
Thirteen full courses in mathematics, physics, logic, and philosophy — lectures, notes, quizzes, and daily spaced review. Free, no ads, taught by one teacher.
```

**Keywords** (100 max; comma-separated, no spaces — don't repeat words already
in the name or subtitle, Apple indexes those separately) — 96 used

```
calculus,algebra,physics,logic,philosophy,geometry,topology,lectures,quiz,flashcards,study,tutor
```

**Description** (4000 max)

```
The Timpson Lyceum is a free classical curriculum in mathematics, physics, logic, and philosophy — the same courses I teach, in full, with nothing held back for a paid tier.

Thirteen published courses and 267 lectures, from Intermediate Algebra through Calculus, Real Analysis, General Topology, and Computation Theory; University Physics I and II; First-Order Predicate Logic; and full surveys of the History of Philosophy and the History of Rome.

WHAT'S IN IT

Lectures. Every course is a complete lecture series, in order, with chapter markers so you can find the part you need.

Written notes. Most lectures have companion notes with the mathematics properly typeset — the derivations, worked examples, and definitions, in a form you can read instead of scrub through.

Quizzes. Ten questions per lecture, with an explanation on every answer, so you find out whether you actually followed it.

Daily review. Questions you have answered enter a spaced-repetition schedule and come back across all your courses in one daily deck, timed so you meet them again just as they start to fade.

Practice drills. Sixty-two drills — grammar, geography, arithmetic, and more — in practice, timed Rapid Fire, and learn modes. These run entirely on your device, so they work with no connection; your scores sync when you're back online.

Progress that follows you. Streaks, badges, and a place in the Hall of Scholars, shared with the website — start a lecture on your laptop and pick it up on your phone.

WHO IT'S FOR

Students in my classes, students taking these subjects somewhere else, and anyone who wants to work through a real curriculum rather than a playlist. The material is high-school and college level.

No ads, no purchases, no subscription. An account keeps your progress, your review schedule, and your streak; you can delete it, and everything attached to it, from inside the app at any time.
```

**What's New in This Version** (for 1.0)

```
First release.
```

**URLs**

| Field | Value |
| --- | --- |
| Support URL | `https://timpson-lyceum.vercel.app/support` |
| Marketing URL | `https://timpson-lyceum.vercel.app` |
| Privacy Policy URL | `https://timpson-lyceum.vercel.app/privacy` |

**Category** — Primary: `Education`. Secondary: `Reference`.

**Copyright**

```
2026 Donald Timpson
```

---

## 3. Screenshots

Already captured. Regenerate any time with:

```sh
cd edu-ios && tools/screenshots.sh
```

Output lands in `edu-ios/build/screenshots/` (gitignored):

- `iphone-6.9/` — 8 shots at 1320×2868 (the required 6.9" iPhone size)
- `ipad-13/` — 8 shots at 2064×2752 (the required 13" iPad size)

Those two sizes are all App Store Connect asks for; it scales them down for
every smaller device itself. Upload in numbered order — the first one or two are
what people actually see in search results, so lead with `01-learn-catalog` and
`03-lecture-notes`.

The harness signs into the seeded review account against production, so if the
shots ever look empty, re-seed it first (§5).

---

## 4. App Privacy

Answer **"Yes, we collect data"**, then declare exactly these. Every one is
*linked to the user*, used for **App Functionality** only, and **not** used for
tracking — which matches `Resources/PrivacyInfo.xcprivacy` and the `/privacy`
page, and they need to keep matching.

| Data type | Why |
| --- | --- |
| Contact Info → Email Address | The account |
| Contact Info → Name | Optional display name |
| Identifiers → User ID | The account row |
| Usage Data → Product Interaction | Watch progress, quiz and drill attempts, reviews, streak |
| User Content → Other User Content | Lecture comments and submitted homework links |

Then, for the tracking question: **"No, we do not use data for tracking."**
There is no analytics SDK and no advertising identifier in the app.

**Age rating.** Answer the questionnaire honestly. The one that matters: the app
**does** carry user-generated content — students can post lecture comments from
inside it. Declaring that will likely land the rating at 13+ rather than 4+.
See the warning in §7.

**Export compliance** is already answered in code:
`ITSAppUsesNonExemptEncryption = false` in `Info.plist`, because the only
cryptography is HTTPS and Keychain, both exempt. You should not be asked again.

---

## 5. Review account

App Store Connect requires demo credentials whenever an app needs a login, and
this one gates everything. The account is already created and seeded on
production:

```
appreview@timpsonlyceum.com
LyceumReview2026!
```

Re-seed or rebuild it from `edu-web`:

```sh
npx tsx scripts/seed-review-account.ts            # create if missing
npx tsx scripts/seed-review-account.ts --reset    # wipe and rebuild
```

It signs in with a streak, 9 badges, 12 review cards due, 12 lectures watched,
and 8 quizzes taken, so no screen greets a reviewer with zeroes.

**App Review Information → Notes** — paste this:

```
Sign-in is required. Demo account:
  email:    appreview@timpsonlyceum.com
  password: LyceumReview2026!

This is a free educational app for a classical curriculum in mathematics,
physics, logic, and philosophy. There are no purchases and no subscription.
Lecture video is served from YouTube, so the device needs a network connection
to play a lecture; the practice drills work offline.

Account deletion is at Profile -> Delete Account. It asks for the typed word
DELETE and the password, then permanently removes the account and all of its
coursework.

The same courses are also on the web at https://timpson-lyceum.vercel.app.
```

---

## 6. Archive and upload

After enrolling, first update the team:

```sh
# project.yml -> DEVELOPMENT_TEAM: <your new paid team ID>
cd edu-ios && xcodegen generate
```

The simplest first submission is through the Xcode GUI:

1. `open Lyceum.xcodeproj`
2. Select the **Lyceum** scheme and **Any iOS Device (arm64)** as the destination.
3. Product → Archive.
4. In the Organizer: Distribute App → App Store Connect → Upload.

Or from the command line:

```sh
xcodebuild -project Lyceum.xcodeproj -scheme Lyceum \
  -sdk iphoneos -configuration Release \
  -archivePath build/Lyceum.xcarchive archive

xcodebuild -exportArchive \
  -archivePath build/Lyceum.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/export
```

Version is `MARKETING_VERSION 1.0.0` / `CURRENT_PROJECT_VERSION 1` in
`project.yml`. Every upload needs a **build number higher than the last one**, so
bump `CURRENT_PROJECT_VERSION` for each attempt — 1.0.0 (1), 1.0.0 (2), and so
on. Apple rejects a duplicate immediately.

Once the build finishes processing (10–30 minutes), attach it to the version in
App Store Connect and **Submit for Review**. First reviews usually land within
24–48 hours.

---

## 7. Known exposure, submitted on purpose

Both of these were raised and you chose to submit as-is. Recording them so a
rejection is not a surprise, and so the fix is already scoped.

**Login gate — Guideline 5.1.1(i).** The app requires an account before showing
anything, while the website serves the same lectures to anonymous visitors. The
guideline says that if an app's core content doesn't require an account, it
shouldn't demand one, and a reviewer can check the website in a browser. If this
comes back: let people browse courses, lectures, and notes signed out, and gate
only progress, quizzes, review, drill sync, and comments.

**Comments — Guideline 1.2.** Students can post lecture comments in the app, and
there is no way to report a comment or block a user; you can only delete your
own. Apps with user-generated content are required to have a report/block
mechanism and a way to act on reports, and this is enforced fairly consistently.
Two ways out if it's flagged: hide the comments tab in the iOS app for now (the
web keeps it), or build `CommentReport` + report/block + an admin queue.

Neither is a reason not to submit. Each costs a review cycle if it's caught.

---

## 8. Small cleanups, not blockers

- Course descriptions start with a raw URL — the Electricity & Magnetism course
  opens with "To get the most out of this course... visit
  https://timpson-lyceum.vercel.app/courses/cmp4n6v650004h3uxd68xbvp8...". It's
  a YouTube-description artifact, and it's the first thing on the course screen
  and in a screenshot.
- `Linear Algebra (2026)` has 0 lectures and shows as "Coming soon" in the
  catalog. Harmless, but a reviewer may wonder.
- Password reset is still manual over email (`/support` says so). Worth making
  self-service before you have many students.
- Sign in with Apple is disabled. Not required — you offer no third-party social
  login — but a paid membership can enable it, and it lowers signup friction.
  Re-enable the entitlement in `project.yml` and `appleSignInAvailable` in
  `AuthViews.swift`; the backend `/auth/apple` endpoint is already there.
