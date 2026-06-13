# Lecture chapter-timestamp style guide

Canonical guide for generating YouTube chapter timestamps from a lecture's timed transcript.
Used both for ad-hoc "generate chapters for course X" runs and (eventually) the `/current-quiz`
autopilot. Mirrors the role of `lecture-notes-style.md`.

## Input / output

- **Input:** `scripts/transcripts-timed/{youtubeVideoId}.json` — an array of `{ start, text }`
  segments (`start` in seconds). Read the whole transcript to understand the lecture's arc.
- **Output:** `scripts/chapters/{youtubeVideoId}.txt` — one chapter per line, nothing else:
  ```
  0:00 Introduction
  1:32 Torque as the rotational analogue of force
  4:10 Newton's second law for rotation
  9:05 Worked example: solid sphere on a ramp
  ```

## Format rules (these make YouTube render clickable chapters — non-negotiable)

- The **first chapter must be `0:00`** (title it `Introduction` unless the lecture opens
  straight into content worth naming).
- **At least 3** chapters.
- Timestamps **strictly ascending**, each at least **10 seconds** after the previous (aim for
  more — see below).
- Use `M:SS` (or `H:MM:SS` past an hour); zero-pad seconds (`1:05`, not `1:5`).
- Every timestamp must **snap to an actual segment `start`** from the transcript JSON (don't
  invent times), and must be **within the video's duration**.

## Content rules

- **Target ~5–12 chapters** for a typical lecture; fewer for short videos. Each chapter should
  be a genuine topic shift, not an arbitrary time slice. Aim for chapters at least ~45–90s long
  so they're useful navigation, never sub-15s slivers.
- **Titles: concise and scannable** (≈3–8 words), describing the topic a viewer is choosing to
  jump to. Title Case or sentence case, consistent within a video. No trailing punctuation.
- Name the **worked example / proof / demo** sections explicitly (e.g. "Worked example: …") —
  those are the parts students scrub back to.
- Match the lecture's real subject; don't title a chapter after a tangent or a preview of a
  later lecture.

## Voice / corrections

- Donald is the speaker — **silently correct obvious verbal slips** (wrong term/number he
  self-corrects) when titling; never add disclaimers. Consistent with the notes/quiz pipelines.
- Don't mention "the transcript", "the video", or the instructor by name in titles.
