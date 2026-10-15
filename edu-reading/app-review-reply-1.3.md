# App Review reply — Sound It Out: Phonics (Guideline 1.3, Kids Category data questions)

Paste the block below into the **Reply** to App Review in App Store Connect, and also add it
to **App Review Information → Notes** so it's on file for future submissions.

---

Thank you. Sound It Out: Phonics is a fully offline app for young children with **no network
connection of any kind** — it contains no networking code, so nothing it holds can be sent,
uploaded, or received. Answering each question directly:

**1. Does the app include third-party analytics?**
No. There is no analytics of any kind — no third-party analytics and no first-party analytics.
The app contains no analytics SDK and no telemetry, and because it has no network layer there
is nowhere for analytics data to be sent.

**2. Does the app include third-party advertising?**
No. There is no advertising of any kind, and no ad networks or advertising SDKs are integrated.

**3. Will the data be shared with any third parties?**
No. No data is shared with any third party for any purpose, because no data ever leaves the
device. There are no third-party SDKs, no servers, and no network requests anywhere in the app.

**4. Is the app collecting any user or device data for purposes beyond third-party analytics
or third-party advertising?**
No data is collected in the App Store Privacy sense — nothing is transmitted off the device.
For full transparency, here is the complete list of everything the app stores, all of it
**locally on the device only**, in the app's own sandboxed storage, never linked to an identity
and never transmitted:

- **Child profiles a parent optionally creates:** a first name or nickname the parent types, an
  emoji face, and a color. These exist only so more than one child can share a device. A default
  profile is created silently on first launch so a child is never blocked behind a setup screen.
- **Reading progress and badges:** which words a child has read and which achievements they've
  earned, so progress persists between sessions.
- **Grown-up settings:** e.g. difficulty level and whether the optional microphone feature is on.

All of the above is stored with Apple's standard on-device storage (UserDefaults) and is removed
when the app is deleted. It is never uploaded, backed up to any server of ours, or shared. No
device identifiers, no advertising identifiers, no location, no contacts, and no usage data are
collected.

**Microphone / speech — optional, OFF by default.** A grown-up can enable "Listen for their
voice" only from the Settings screen behind the parental gate; the microphone permission is
requested only from there. When on, the app uses Apple's **on-device** speech recognition
(SFSpeechRecognizer) so a child can read a word aloud and the card advances with positive-only
feedback. **No audio is recorded, saved, or transmitted.** No speech data is collected or
shared.

The one external link (to the developer's other work) and all grown-up settings sit behind a
parental gate (a spelled-out multiplication question), per Guideline 1.3. The app complies with
COPPA and Apple's Kids Category requirements and collects no data. Our App Privacy answers in
App Store Connect are set to **Data Not Collected**, which accurately reflects the above.

**Review contact:** Donald Timpson · dt323259@gmail.com · 1-435-619-1784

---
