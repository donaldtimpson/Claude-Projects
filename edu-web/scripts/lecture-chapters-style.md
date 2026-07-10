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

- **Target ~10–12 chapters** (Donald's preferred granularity — the major topic blocks, not the
  finest subdivisions); fewer (~4–6) for short videos. Example-dense 2-hour lectures may run to
  **~14–16** when each worked example deserves its own scrub point. Each chapter is a genuine
  topic shift, not an arbitrary slice; aim for chapters ≥ ~45–90s, never sub-15s slivers.
- **Don't touch the existing description.** Many of Donald's descriptions already have a manual
  `__________VIDEO CONTENTS__________` outline; the pipeline appends the timestamped `Chapters`
  block *below* it and leaves everything above untouched (decided 2026-06-13).
- **Titles: terse and scannable** (≈2–6 words), describing the topic a viewer is jumping to.
  Sentence case, consistent within a video. No trailing punctuation (a real "?" is fine).
  Prefer the short noun phrase over a full clause ("Solid sphere on a ramp", not "Worked
  example: a solid sphere rolling down a ramp"). Drop the "Worked example:" prefix unless it
  genuinely aids scanning; the title itself signals it.
- **Math: use plain unicode**, not LaTeX — descriptions are UTF-8 and render symbols like
  `τ = Iα`, `r × F`, `ω`, `Δx`, `→` fine, but NOT `\tau` or `$…$`. Keep it short and readable.
- Still call out the worked examples / derivations as their own chapters (students scrub back to
  them) — just title them tersely.
- Match the lecture's real subject; don't title a chapter after a tangent or a preview of a
  later lecture.

## Voice / corrections

- Donald is the speaker — **silently correct obvious verbal slips** (wrong term/number he
  self-corrects) when titling; never add disclaimers. Consistent with the notes/quiz pipelines.
- Don't mention "the transcript", "the video", or the instructor by name in titles.
