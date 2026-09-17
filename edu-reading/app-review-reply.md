# App Review reply — Sound It Out: Phonics (Guideline 2.1, Information Needed)

Paste the block below into the **Reply** to App Review in App Store Connect, and also
into **App Review Information → Notes** (Apple asks you to keep it there for future
submissions). Fill the two bracketed spots first.

---

Thank you for reviewing Sound It Out: Phonics. Please find the requested information below.

**Overview**
Sound It Out: Phonics is a fully offline phonics app that teaches young children to read,
from single letter sounds up to their first decodable sentences. It was built by a
classroom teacher. It has no accounts, no network connection of any kind, no ads, no
analytics, no in-app purchases, and no third-party SDKs. Everything is usable the moment
the app opens — there is nothing to sign into.

**1. Screen recording**
A screen recording captured on a physical iPhone running the latest iOS is attached. It
begins by launching the app and shows the typical flow: the home screen of decks, tapping
into a deck, tapping a card to hear the sound and again to turn it, and swiping to the next
card. It then opens the grown-ups' area through the parental gate and enables the optional
"Listen for their voice" feature, granting the microphone permission when prompted, and
shows a child saying a word to advance a card.
- Account registration/login/deletion: not applicable — the app has no accounts.
- User-generated content: not applicable — nothing is created, shared, or transmitted to
  other users. Local "player profiles" (a name, an emoji face, a colour) live only on the
  device, are visible only on that device, and are never uploaded, so no content
  reporting/blocking mechanism applies.
- Paid content or features: not applicable — there are no in-app purchases and no paid
  content. Every feature is free.

**2. Purpose and target audience**
Purpose: to take a young child from spoken vocabulary to reading a real sentence, one sound
at a time, in a calm, ad-free, private environment. Target audience: pre-readers and early
readers roughly ages 4–8, and their parents/teachers. Problem it solves: most early-reading
apps are loud, gamified, ad-supported, and data-hungry; this one is deliberately quiet,
never tells a child they are wrong, and collects nothing. Value: a teacher-designed
sequence (letters → blending → words → sentences → sight words) that a parent can trust to
be safe and offline.

**3. Setup and access instructions**
No setup, login, credentials, or sample files are required. Launch the app and it is
immediately usable. On first run a default child profile is created silently, so a child is
never blocked behind a setup screen.
To review the optional microphone/speech feature (off by default):
1. Tap the grown-ups'/settings control and pass the parental gate (answer the spelled-out
   multiplication question).
2. Toggle on "Listen for their voice."
3. Allow the microphone when iOS prompts.
4. On any letter/word/number/colour/shape card, say the word aloud; the card advances.
   Feedback is positive-only — a non-match does nothing and a child is never told they are
   wrong. Speech is recognized on-device and never recorded, saved, or transmitted.

**4. External services, tools, or platforms used for core functionality**
None. The app uses only Apple's own on-device frameworks (SwiftUI/UIKit, and
SFSpeechRecognizer for the optional on-device speech recognition). Specifically:
- Data providers: none. All content is bundled in the app.
- Authentication services: none. There are no accounts.
- Payment processors: none. No in-app purchases.
- AI / cloud services: none. Speech recognition runs entirely on the device; no request
  ever leaves the phone. There is no networking code in the app at all.
- Analytics / advertising / third-party SDKs: none.

**5. Regional differences**
None. The app functions identically in all regions. Content is English-language phonics
only, there are no region-gated features, and because the app has no network connection
there is no regional backend or region-specific behavior.

**6. Regulated industry / protected third-party material**
The app is not part of a regulated industry. It is a Made-for-Kids / Education app that
complies with COPPA and Apple's Kids Category requirements and collects no data.
Third-party material is limited to bundled assets that are properly licensed:
- Photographs: licensed under Creative Commons Attribution (CC BY). Attribution ships
  inside the app (viewable behind the parental gate) and is documented per-image in the
  build. We can provide the full attribution/credits file on request.
- Font: Andika (SIL Open Font License).
No other protected or third-party material is used.

**Export compliance:** uses only Apple on-device frameworks; Info.plist sets
ITSAppUsesNonExemptEncryption = false.

**Review contact:** Donald Timpson · [EMAIL] · [PHONE]

---
