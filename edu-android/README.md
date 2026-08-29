# Lyceum for Android

A native Kotlin + Jetpack Compose port of `edu-ios`, against the same
`/api/mobile/v1` backend in `edu-web`. The iOS app is the reference: where a
screen exists on both, it should behave the same way and use the same words.

## Running it

Everything needed is already on this machine; there is no separate SDK install.

```sh
cd edu-android
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export ANDROID_HOME=$HOME/Library/Android/sdk

./gradlew assembleDebug

# an emulator, if one isn't already up
$ANDROID_HOME/emulator/emulator -avd Medium_Phone_API_36 &

$ANDROID_HOME/platform-tools/adb install -r app/build/outputs/apk/debug/app-debug.apk
$ANDROID_HOME/platform-tools/adb shell am start -n com.timpsonlyceum.lyceum/.MainActivity
```

Or just open the folder in Android Studio and press Run.

The app talks to **production** by default, so it works from an emulator with no
LAN address to keep in sync. To point it at `npm run dev` on this Mac, set
`AppConfig.override = "http://10.0.2.2:3000"` — `10.0.2.2` is the host as seen
from inside the emulator.

Versions are pinned: Gradle 8.11.1, AGP 8.7.3, Kotlin 2.0.21, compileSdk 35,
minSdk 26. The Homebrew Gradle is 9.x, which AGP will not accept — use the
wrapper (`./gradlew`), not `gradle`.

## What's here

| Area | State |
| --- | --- |
| Catalog, categories, search | Done — hybrid instant/server search as on iOS |
| Course detail, lectures, problem sets | Done |
| Lecture video | Done, **unverified on real hardware** (see below) |
| Lecture notes (Markdown + KaTeX) | Done |
| Lecture quiz, course test | Done |
| Daily review (spaced repetition) | Done |
| My Progress, grades, badges, delete account | Done |
| Hall of Scholars | Done |
| Course map | Listed, not drawn as a graph (see below) |
| Drills | All 63, in three modes |
| Lecture discussion | Deliberately absent, as on iOS |

Signed-out behaviour matches iOS and is the thing not to regress: the app opens
on the catalog, and lectures, notes, quizzes, and drills all work with no
account. Only Review and saved progress need one, and each says what signing in
buys rather than refusing.

## Known gaps

**The video player is unverified.** The IFrame API loads and reports no error
code, so the embed is accepted, but the emulator does not decode the video and
the frame stays black — the same limitation the iOS Simulator has. This needs
one run on a physical Android device to call working.

**The course map is a list, not a graph.** Each course with its prerequisites
underneath. That carries the thing a student acts on — "what should I take
before this?" — but it is not the pannable graph the iOS app draws.

**No emoji flags.** Android frequently cannot compose a regional-indicator pair
and falls back to two boxed letters. It is not reliably detectable: on the API 36
emulator both `Paint.hasGlyph` and text measurement claim the sequence composes
while the raster still shows boxes. See the note at the top of `GeoDrills.kt`.

**Not ported from iOS:** the offline write queue. Everything a drill does now
works — Practice, Learn (Leitner boxes), and Rapid Fire — but a run completed
with no connection is lost rather than queued for replay.

**No Play Store setup.** No developer account yet, so there is no release
signing config, no keystore, and no listing. Debug builds only.

## Layout

```
drills/     the drill engine — pure generators, JSON-backed grammar and geo,
            the category lists, and DrillStore (mastery, ✦, bests, recents)
model/      the API contract, mirroring edu-ios Sources/Models
net/        AppConfig, TokenStore, ApiClient, Repository
ui/theme/   palette and the two brand faces, names matched to the iOS Theme
ui/         Navigation, screens, and shared components
assets/     grammar.json, lessons.json, capitals.json, the two atlases, fonts
```

`ui/theme/Theme.kt` deliberately keeps the iOS colour names (`parchment`, `ink`,
`gold300`, …) so a screen can be carried across without renaming anything.
