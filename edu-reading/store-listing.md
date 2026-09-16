# App Store listing — Sound It Out (draft)

Paste these into App Store Connect. Nothing here is binding; tweak freely.

## Names
- **App name** (30 char max): `Sound It Out: Phonics` — "Sound It Out" alone was taken on the store
- **Subtitle** (30 char max): `Learn to read, sound by sound` (29) — avoids echoing "Phonics" in the name
- **Home-screen name** (`CFBundleDisplayName`): `Sound It Out` (a subset of the store name, which Apple allows)
- **Developer / publisher name:** `Timpson Lyceum` (the "by …" line; groups future apps)
- **Icon:** speech-bubble `a` on amber (`icon/bubble.png`, set via `tools/set-icon.sh bubble`)

## Promotional text (170 char max, editable anytime without review)
`A calm, ad-free phonics app made by a teacher. Sound out letters and words, trace them with a finger, and play — all on-device, nothing collected.`

## Description
Sound It Out teaches young children to read the way reading actually works:
sounding words out, one letter at a time. It was built by a teacher, and it is
deliberately calm — no ads, no characters shouting, no timers, and nothing that
can ever tell a child they got it wrong.

A gentle path from letters to real reading:
• Letters — the 26 sounds
• Blending — two sounds together (ba, be, bi)
• Word Blending — word families (at → cat, hat)
• Words — a growing ladder from CVC to vowel teams and beyond
• Sentences — the first real sentences, decodable and in order
• By Heart — the rule-breakers (the, was, said)

Write, don't just read:
• Trace — draw each letter and number with a finger, following a dotted guide

Play with what they've learned:
• Find It, Build a Word, Rhyme Time, and Match Up — reinforcement dressed as games

Made for how children (and families) really use it:
• Vowels are always red — a real phonics cue, held across the whole app
• Several children can share one device, each with their own profile
• Themes are earned, so progress is something a child can see
• Grown-up settings (difficulty, microphone, and more) sit behind a simple gate

Private by design: Sound It Out has no network connection at all. Nothing is
collected, nothing is uploaded, nothing is stored off your device — ever. If you
turn on voice, speech is recognized on the device and never recorded or sent.

## Keywords (100 char max, comma-separated, no spaces after commas)
`learn to read,reading,letters,tracing,sight words,spelling,abc,preschool,kindergarten,decodable`
(dropped "phonics" — it's already in the app name, so Apple indexes it; don't waste a keyword slot on it)

## URLs
- **Support URL** (required): a simple page or the Lyceum site — e.g. https://timpson-lyceum.vercel.app
- **Marketing URL** (optional): same or blank
- **Privacy Policy URL** (required): host PRIVACY.md publicly (GitHub Pages) and paste the URL

## Category & audience
- **Primary category:** Education
- **Secondary category:** (optional) Games
- **Made for Kids:** Yes — age band **6–8** (or 5 & under if you prefer)

## Age rating questionnaire → answer "None" to everything → results in 4+

## App Privacy → "Data Not Collected"
Answer **No** to every data-collection question. No tracking, no third parties.

## Export compliance
Info.plist already sets `ITSAppUsesNonExemptEncryption = false` → no extra docs.

## What's New (version 1.0.0)
`First release. Sound out letters and words, trace them, and play — all offline.`
