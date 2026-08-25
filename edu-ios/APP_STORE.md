# Shipping Lyceum to the App Store

Everything App Store Connect asks for, in the order it asks. Written 2026-08-23
against the state of the repo at that commit.

---

## 0. Enrollment — done

**Settled as of 2026-08-23.** The individual membership is active and the team
ID did **not** change: enrolling with the same personal Apple ID upgraded the
existing personal team in place, so `LGF933VBP2` in `project.yml` and
`ExportOptions.plist` is correct and needs no edit. (An earlier draft of this
page predicted a new ID. It was wrong — noted here so nobody "fixes" a file that
is already right.) Your employer's `busybusy, Inc` (`J7WN5UF5X3`) is untouched
and unused.

Build **1.0.0 (1)** uploaded successfully on 2026-08-23; the app's Apple ID is
**6804510418**. Distribution uses Xcode's **cloud-managed** signing, so the
distribution certificate lives with Xcode and will not appear in
`security find-identity` — its absence there is not a problem.

The original instructions, kept for the record:

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
- **Your team ID may change.** It did not here — the personal team was upgraded
  in place — but if you ever do land on a new ID, it goes in `DEVELOPMENT_TEAM`
  in `edu-ios/project.yml` and `teamID` in `ExportOptions.plist`, followed by
  `xcodegen generate`. The ID is at <https://developer.apple.com/account> →
  Membership Details.

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
See the warning in §8.

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

## 7. TestFlight beta testing

TestFlight needs what a submission needs: **a build uploaded to App Store
Connect under a paid team** (§0, §6). You already have one — **1.0.0 (1)**,
uploaded 2026-08-23 — so everything below is App Store Connect work, with no new
archive required. That build expires **2026-11-21**, 90 days after upload.

Two kinds of testing, and the difference is the whole story:

| | Internal | External |
| --- | --- | --- |
| Who | Up to 100 people, each of whom must be a user on your App Store Connect team | Up to 10,000 people, invited by email or by a public link |
| Beta App Review | **None.** Testable as soon as the build finishes processing | **Required** for the first build of a version; later builds of the same version usually clear automatically |
| Test Information needed | Feedback email | All of it — description, feedback email, demo account |
| Use it for | Yourself, on your own devices; one or two people you trust with team access | Actual students |

Every build expires **90 days** after upload, for testers as well as for you.
Each internal tester can install on up to 30 devices.

### Test Information

App Store Connect → your app → **TestFlight** → **Test Information**. Filled in
once for the app, not per build.

**Beta App Description**

```
The Timpson Lyceum is a free classical curriculum in mathematics, physics, logic,
and philosophy — thirteen complete courses and 267 lectures, with written notes,
quizzes, daily spaced review, and offline practice drills.

This is the first build. I am looking for two things: whether anything is broken
on your device, and whether the app is actually pleasant to study in. Lecture
video streams from YouTube, so playback needs a connection; the drills run
entirely on-device and work in airplane mode.

Nothing in the app costs money and there are no ads. An account is required
because it holds your progress, your review schedule, and your streak. You can
delete it, and everything attached to it, from Profile -> Delete Account.
```

**Feedback Email**

```
dt323259@gmail.com
```

**Privacy Policy URL** — `https://timpson-lyceum.vercel.app/privacy`
(same as the listing, §2).

**Sign-in required** — Yes. Give the same demo account as §5
(`appreview@timpsonlyceum.com` / `LyceumReview2026!`) so Beta App Review can get
in. Real testers should make their own accounts, or their progress collides.

### What to Test

Per build, and it's the field testers actually read. For 1.0.0:

```
Everything is new, so anything you hit is worth reporting. If you want a route
through it:

1. Make an account, then open Learn and start any lecture. Does the video play,
   and does your place get remembered when you come back?
2. Open the notes under a lecture. The mathematics should be typeset, not raw
   markup — tell me if you see stray backslashes or dollar signs.
3. Take a lecture quiz. Every answer has an explanation; say so if one is wrong
   or badly worded.
4. Come back tomorrow and open Review. Cards from yesterday's quiz should be
   waiting.
5. Try a few Practice Drills, including in airplane mode. Scores should sync
   once you are back online.

Send anything odd to the feedback address, or use the screenshot-and-share
button in TestFlight. Device model and iOS version help.
```

### Getting testers in

**Internal.** App Store Connect → **Users and Access** → invite the person by
email (role of Developer or App Manager is enough), then **TestFlight** →
Internal Testing → create a group → add them. They see the build within minutes
of it processing, with no review. This is the fastest way to prove the pipeline
works — add yourself first.

**External.** TestFlight → External Testing → create a group ("Students", say),
then either add emails one at a time or turn on the **public link** and cap it
at a number you're willing to support. The first build goes to Beta App Review
before any of them can install; that is usually same-day to 48 hours, and it is
a lighter review than App Store review — but the demo account above has to work,
or it fails there for the same reason a submission would.

The public link is the one that fits your situation: it is an ordinary URL, so
it can go in a YouTube community post or a video description, and anyone who
taps it gets the build. Everyone needs the free **TestFlight** app from the App
Store first.

### Between rounds

Every upload needs a **build number higher than the last** —
`CURRENT_PROJECT_VERSION` in `project.yml`, same rule as §6. Testers get
1.0.0 (2) as an update; you do not create a new version for it.

---

## 8. Known exposure, submitted on purpose

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

## 9. Small cleanups, not blockers

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
