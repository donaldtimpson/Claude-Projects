# Phonics sound clips (ios/Resources/Sounds/ph_*.m4a)

Source: Phonicademy 44 Sounds Audio Pack — https://phonicademy.com/printables/phonics-audio-pack
Licence: Phonicademy Audio License v2.1 (5 Nov 2026) — https://phonicademy.com/audio-license
Required credit (shown in the app's grown-ups area): "Phonics sounds: Phonicademy (phonicademy.com)"

Licence points we rely on / must keep:
- Allowed: bundling inside the app and distributing it via the App Store; trimming,
  normalising and converting the files.
- Not allowed: shipping the files as a standalone pack or extractable collection;
  using them to train, fine-tune or TEST AI/ML models (so validation used signal
  measurements only, no speech-recognition models); describing them as a recording
  of a real or named person.
- Products released under v2.1 may keep v2.1 terms if the licence later changes.

What was done to each file (tools: afconvert + numpy/pyworld signal analysis):
- Files that say the sound three times (b, c/k, d, g, p, t, ch, j, h, w, y, x, qu):
  the first take only.
- Held sounds ended earlier with a 60 ms fade: short vowels 450 ms, ee/oo/aw/ur
  550 ms, s sh f th th-voiced v z m n l r 600 ms. ng: its longest steady swell.
- Gliding vowels and r-vowels (ai igh oa u-e ow oi ar or) kept whole — trimming
  would cut the glide.
- Levelled: loudest 200 ms at -16 dBFS, peaks <= -1 dBFS; AAC 96 kbps.

Acceptance (all 43 pass): length inside a band per sound class; voiceless stops,
affricates and fricatives unvoiced and with no vowel tail (two independent checks:
periodicity + low-band energy, and spectrograms reviewed); one take per clip; no
clipping; encoded length identical to source.
Known: b/d/g are 70-105 ms — the source's own, phonetically correct (no "buh").

Mapping (file -> id): c,k->k  qu->kw  x->ks  th->th  th-voiced->dh  ai->ay
u-e->yoo  oo->oo  oo-book->oo_short  ur->er  (others same name). Unused: nk (the
app plays ng+k), ear, air, ure, zh.
