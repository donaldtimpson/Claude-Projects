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

**License Agreement** — leave it on Apple's **standard EULA**. The app is free
with no purchases, and there is no `/terms` page on the site to align a custom
one with. A custom EULA would still have to carry Apple's minimum terms, so it
buys nothing. Revisit only if paid features or content-use terms ever appear.
It has no effect on TestFlight.

**Agreements** — the **Free Apps** agreement in Business → Agreements is active,
but Apple reissues it from time to time. When it does, submissions *and* external
TestFlight distribution stop until the Account Holder accepts the new version.
If something refuses to submit for no visible reason, look there first.

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

Then, for the tracking question: **"No, we do not use data for tracking."**
There is no analytics SDK and no advertising identifier in the app.

**Age rating.** Answer the questionnaire honestly. The one that used to matter
was user-generated content — but as of 1.0 the app has **none**: lecture comments
are switched off (§10) and there is no homework submission on iOS. Answer the UGC
question as none, which should land the rating at 4+ rather than 13+. `User
Content → Other User Content` is likewise gone from the table above and from
`PrivacyInfo.xcprivacy`. All three answers go back together when comments return.

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

**App Review Information → Notes** — the short version below got a 2.1
"Information Needed" rejection on 2026-08-25. **Use the expanded answers in §10
instead**; this is kept for reference.

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

### Beta App Review Information

Same page as Test Information, lower down, and it is the block that actually
gets a build through Beta App Review. Distinct from §5's App Review notes,
though the content overlaps.

| Field | Value |
| --- | --- |
| First Name | `Donald` |
| Last Name | `Timpson` |
| Email | `dt323259@gmail.com` |
| Phone Number | your own |
| Sign-in required | **Yes** |
| User Name | `appreview@timpsonlyceum.com` |
| Password | `LyceumReview2026!` |

**Review Notes**

```
Sign-in is required for everything in the app. Demo account:
  email:    appreview@timpsonlyceum.com
  password: LyceumReview2026!

This is a free educational app for a classical curriculum in mathematics,
physics, logic, and philosophy. There are no purchases, no subscription, and
no ads.

Lecture video is served from YouTube, so the device needs a network connection
to play a lecture; the practice drills run on-device and work offline.

Account deletion is at Profile -> Delete Account. It asks for the typed word
DELETE and the password, then permanently removes the account and all of its
coursework.

The same courses are also on the web at https://timpson-lyceum.vercel.app.
```

Beta App Review hits the same login wall App Review does, so confirm the demo
account still signs in before submitting — re-seed from `edu-web` with
`npx tsx scripts/seed-review-account.ts --reset` if unsure.

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

**Login gate — Guideline 5.1.1(i). FIXED 2026-08-28, after the rejection.** The
app required an account before showing anything, while the website served the
same lectures to anonymous visitors. It came back exactly as predicted.

The app now opens on the catalog signed in or not. No wall, and deliberately no
"skip" button on a sign-up screen either — a skippable wall is still the pattern
reviewers scrutinise, and the website has never had one. Courses, lectures,
notes, quizzes, and drills all work anonymously; only Review (the deck IS your
own history) and Profile ask for an account, and each says what signing in buys
rather than just refusing. The quiz and drill result screens now carry an
actionable prompt instead of the dead-end "Sign in to save…" footnotes.

No API work was needed — every browse endpoint under /api/mobile/v1 was already
public, and only /me*, /progress/*, /quiz/attempt, /drills/session and /review/*
require a token. The wall was purely RootView.

`Screenshots/SignedOutAccessTests.swift` pins the behaviour: launches into the
catalog, every tab reachable, drills ungated, Review explains itself. Run it with
the LyceumScreenshots scheme; it needs no seeded account.

**Comments — Guideline 1.2. Closed for 1.0.** Students could post lecture
comments in the app with no way to report a comment or block a user, which apps
carrying user-generated content are required to have. When App Review asked to
see reporting and blocking by name (§10), Donald chose to **hide the Discussion
tab in the iOS app for 1.0** rather than build moderation under time pressure.
The web keeps comments; the backend endpoints are untouched.

The switch is `commentsEnabled` in `LectureView.swift` — flip it to `true` once
`CommentReport` + report/block + an admin queue exist, and restore the App
Privacy row, the privacy-manifest entry, and the age-rating answer with it.

Both are now closed: 5.1.1(i) is fixed above, and comments stay hidden until
moderation ships.

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

---

## 10. The Guideline 2.1 rejection, 2026-08-25

Apple rejected 1.0.0 (1) under **2.1 — Information Needed**. Nothing in the app
was found wrong; they asked seven questions and want the answers in the App
Review Information **Notes** field, plus a screen recording. The TestFlight line
in their "How to Prevent Common Issues" footer is boilerplate — it is not a
requirement, and nothing in the rejection asks for beta testers.

### Item 1 — the screen recording

Has to be captured **on a physical device**, on current iOS, starting from
launching the app. Record with the TestFlight build already on your phone
(Control Center → screen recording). Aim for five minutes or so, unhurried.

Apple names four things to include if the app has them. Ours has two:

| They ask for | We have |
| --- | --- |
| Registration, login, account deletion | Yes — all three, must be shown |
| Paid content, purchases, subscriptions | None. Say so in the reply |
| User-generated content + report/block | **None as of 1.0** — the Discussion tab is switched off. Say so in the reply |
| Prompts for sensitive data or capabilities | None. `Info.plist` has no `*UsageDescription` key at all |

Shot list, in order:

1. Launch from the Home screen — cold, not from the app switcher.
2. **Register** a brand-new account. Use a throwaway address; do not reuse the
   review account, they want to see the flow work from nothing.
3. Learn tab → open a course → open a lecture → let the video actually play for
   a few seconds.
4. Open that lecture's notes, and scroll far enough that typeset mathematics is
   on screen.
5. Take a lecture quiz, answer two or three questions, show an explanation.
6. Drills tab → run one drill to completion.
7. Review tab → show a card.
8. Profile → **Delete Account** → type DELETE, enter the password, complete it.
   Show the app returning to signed-out.
9. Sign back in with the demo account to show it still works.

Attach it to the App Store Connect reply, or — easier, given the file size — put
it up as an **unlisted YouTube video** and paste the link. Apple accepts a link.

### Comments are off in 1.0 — decided 2026-08-25

Apple explicitly asked to see "user-generated content, **including content
reporting and blocking mechanisms**." The app had lecture comments and neither a
report nor a block — `CommentsView.swift` offers delete-your-own and nothing
else. Filming that would have handed a reviewer the Guideline 1.2 finding §8 had
been carrying.

Donald chose to **hide the Discussion tab for 1.0** rather than build moderation
under review pressure. `commentsEnabled` in `LectureView.swift` is `false`; the
Picker drops the Discussion segment, the section never renders, and the comments
fetch is skipped. Nothing was deleted — the web keeps comments and the backend
endpoints are untouched — so turning it back on for 1.1 is one line plus the
moderation work.

Consequences already applied: `Other User Content` removed from
`PrivacyInfo.xcprivacy` and from the §4 App Privacy table, and §4's age-rating
guidance updated, because with comments off and no homework submission on iOS
the app collects **no** user content at all. Those three go back together.

So the answer to Apple's UGC question is simply that the app has none.

### Item 2 — devices and operating systems tested

Needs your actual list; Apple wants specific models, not "iPhone." Fill in and
paste:

```
Tested on physical hardware:
  - iPhone 14 Pro Max, iOS 26.6   (installed via TestFlight)

Tested in Simulator (Xcode 26):
  - iPhone 17 Pro Max, iOS 26
  - iPad Pro 13-inch (M4), iPadOS 26

The app is universal (iPhone and iPad). Minimum supported version is iOS 18.0.
```

Simulator coverage is worth listing but does not substitute for the physical
device — that is the point they are making.

### Items 3–7 — paste-ready

**3. Functions, audience, problem solved, value**

```
The Timpson Lyceum is a free educational app offering a complete classical
curriculum in mathematics, physics, logic, and philosophy. It contains thirteen
published courses and 267 video lectures, ranging from Intermediate Algebra
through Calculus, Real Analysis, General Topology, and Computation Theory;
University Physics I and II; First-Order Predicate Logic; and surveys of the
History of Philosophy and the History of Rome.

I am a teacher, and these are recordings of the courses I teach. The app gives a
student five things: the lecture videos in course order, written notes with
properly typeset mathematics, a ten-question quiz per lecture with an
explanation on every answer, a daily spaced-repetition review deck drawn from
questions the student has already answered, and 62 offline practice drills in
grammar, geography, and arithmetic.

Target audience: high-school and college students studying these subjects,
whether in my own classes or elsewhere, and self-directed adult learners. The
problem it solves is that free lecture material online is normally an unordered
playlist with no notes, no assessment, and no retention schedule. This is a
structured course of study instead — sequenced, with the reading, testing, and
review that make the lectures stick.

The app is entirely free. There are no purchases, no subscriptions, and no
advertising. There is no paid tier and no content withheld.
```

**4. Setup and access instructions**

```
An account is required, because the account holds the student's progress, review
schedule, and streak. Demo account:

  email:    appreview@timpsonlyceum.com
  password: LyceumReview2026!

This account is pre-populated with watched lectures, completed quizzes, review
cards due today, and earned badges, so no screen appears empty.

No sample files, entitlements, or configuration are needed. A network connection
is required to play a lecture, because lecture video is served from YouTube; the
practice drills run entirely on-device and work offline.

Main features, and where they are:
  - Learn tab      : courses, lectures, notes, and quizzes
  - Drills tab     : 62 practice drills, in practice / timed / learn modes
  - Review tab     : today's spaced-repetition deck across all courses
  - Profile tab    : progress, badges, streak, and Delete Account

Account deletion is at Profile -> Delete Account. It requires typing the word
DELETE and re-entering the password, then permanently removes the account and
all coursework attached to it, on the server and on the device.
```

**5. External services, tools, and platforms**

```
  - YouTube (Google LLC) - lecture video playback, embedded via the YouTube
    IFrame Player API. All videos are my own, published on my own channel.
  - Vercel - hosting for the backend web application and its API.
  - Neon - the managed PostgreSQL database behind that API.
  - jsDelivr - CDN delivering the KaTeX and marked JavaScript libraries used to
    render mathematics inside the lecture-notes view.

Authentication is first-party: accounts are created and stored by our own
backend, with bcrypt-hashed passwords and JWT session tokens. There is no
third-party identity provider, no social login, and Sign in with Apple is not
enabled in this version.

There are no payment processors, because nothing is for sale. There are no AI
services. There is no analytics SDK, no advertising SDK, no attribution SDK, and
no tracking of any kind; the app requests no IDFA and does not present App
Tracking Transparency.
```

**6. Regional differences**

```
There are none. The app offers identical features and identical content in every
region. It ships in English only, has no region-locked material, no
regional pricing (it is free everywhere), and no geographic restrictions of any
kind.
```

**7. Regulated industry and third-party material**

```
The app does not operate in a regulated industry. It is general educational
material, not accredited instruction; it grants no degree, credential, or
certification, and it makes no medical, legal, or financial claims.

All content is my own or public domain:

  - The 267 lectures are my own recordings, taught and published by me on my own
    YouTube channel. I am the author and the copyright holder.
  - Lecture notes, quiz questions, and their explanations are written by me.
  - The grammar course follows Harvey's "Elementary Grammar and Composition"
    (1880), which is in the public domain. The drills built from it are my own
    authoring.
  - The Linear Algebra problem sets are original problems written by me. They
    follow the topic sequence of a standard textbook, as any linear algebra
    course does, but no exercise is reproduced from it.

No third-party protected material is reproduced in the app, so there is no
license or authorization to document.
```

### The Notes field

Apple asked that this live in App Review Information → **Notes** for future
submissions. **Where it is:** the very bottom of the version page
(`/distribution/ios/version/inflight`), in the **App Review Information** block,
below Sign-In Information and Contact Information. Apple's helper text on that
box talks about Chinese permits for news and book apps, which makes it look like
the wrong field — it isn't. That is the notes App Review reads. Watch the
character counter after pasting; it silently drops anything over the cap. The full items 3–7 above come to 4,624 characters and the Notes
field caps at **4,000**, so paste the condensed version below (3,912) there, and
put the full answers in the Resolution Center reply, which has more room.

This replaces the shorter notes in §5 entirely.

```
DEMO ACCOUNT (sign-in is required for all features)
email: appreview@timpsonlyceum.com
password: LyceumReview2026!
The account is pre-populated with watched lectures, completed quizzes, review
cards due today, and earned badges, so no screen appears empty. No sample files
or configuration are needed.

WHAT THE APP IS
A free educational app: a complete classical curriculum in mathematics, physics,
logic, and philosophy. Thirteen courses and 267 video lectures, from
Intermediate Algebra through Calculus, Real Analysis, General Topology, and
Computation Theory; University Physics I and II; First-Order Predicate Logic;
and surveys of the History of Philosophy and the History of Rome. I am a
teacher, and these are recordings of the courses I teach.

Each lecture carries written notes with typeset mathematics and a ten-question
quiz with an explanation on every answer. Questions the student answers enter a
daily spaced-repetition review deck across all their courses. There are also 62
practice drills in grammar, geography, and arithmetic that run entirely
on-device and work offline.

AUDIENCE AND VALUE
High-school and college students studying these subjects, and self-directed
adult learners. Free lecture material online is normally an unordered playlist
with no notes, no assessment, and no retention schedule. This is a sequenced
course of study with all three.

The app is entirely free: no purchases, no subscriptions, no advertising, no
paid tier, and no content withheld.

WHERE THE FEATURES ARE
Learn tab: courses, lectures, notes, quizzes
Drills tab: 62 drills, in practice / timed / learn modes
Review tab: today's spaced-repetition deck across all courses
Profile tab: progress, badges, streak, and Delete Account

Account deletion requires typing the word DELETE and re-entering the password,
then permanently removes the account and all coursework attached to it, on the
server and on the device. A network connection is needed to play a lecture,
because video is served from YouTube; the drills work offline.

EXTERNAL SERVICES
YouTube (Google LLC) - lecture playback via the IFrame Player API. All videos
are my own, published on my own channel.
Vercel - hosting for the backend web application and its API.
Neon - the managed PostgreSQL database behind that API.
jsDelivr - CDN for the KaTeX and marked libraries that render mathematics in the
lecture-notes view.

Authentication is first-party: bcrypt-hashed passwords and JWT sessions on our
own backend. No third-party identity provider, no social login, and Sign in with
Apple is not enabled in this version. There are no payment processors, no AI
services, and no analytics, advertising, or attribution SDKs. The app requests
no IDFA, does not present App Tracking Transparency, and requests no
sensitive-data or device permissions of any kind.

USER-GENERATED CONTENT
None. This version has no comments, messaging, uploads, or user profiles visible
to other users.

REGIONAL DIFFERENCES
None. Identical features and identical content in every region, English only, no
region-locked material and no geographic restrictions.

REGULATED INDUSTRY AND THIRD-PARTY MATERIAL
Neither applies. This is general educational material, not accredited
instruction; it grants no credential and makes no medical, legal, or financial
claims. All content is my own or public domain: the lectures are my own
recordings, the notes and quiz questions are written by me, the grammar course
follows Harvey's "Elementary Grammar and Composition" (1880, public domain), and
the Linear Algebra problem sets are original problems written by me. No
third-party protected material is reproduced, so there is nothing to license.

TESTED ON
iPhone 14 Pro Max, iOS 26.6 (physical device, installed via TestFlight).
Simulator: iPhone 17 Pro Max (iOS 26), iPad Pro 13-inch M4 (iPadOS 26).
Universal app (iPhone and iPad); minimum supported version is iOS 18.0.
```

---
