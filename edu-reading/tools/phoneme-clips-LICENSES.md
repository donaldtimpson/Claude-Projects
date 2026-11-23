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
b, d, g are NOT Phonicademy's: theirs were 70-105 ms and the owner found them too
short on device. They come from FreeReading's "Most common letter sounds" clips
(https://www.freereading.net/wiki/Most_common_letter_sounds_(audio_clips).html,
CC BY-SA 3.0): each cut at the silence before its example word (bat / dot / got —
verified by transcribing the remainder, before any Phonicademy file was involved),
started at the burst less 15 ms, levelled to the same loudness: b 234 ms, d 165 ms,
g 269 ms — a burst with a short fading release, no held vowel. Adapted clips are
CC BY-SA 3.0. build_sounds.py rebuilds only the Phonicademy ones; the archive
(clips.tar.enc) holds the full set.

Mapping (file -> id): c,k->k  qu->kw  x->ks  th->th  th-voiced->dh  ai->ay
u-e->yoo  oo->oo  oo-book->oo_short  ur->er  (others same name). Unused: nk (the
app plays ng+k), ear, air, ure, zh.

## Where the clips live

Not as plain files in git (the repo is public). They are committed only as an
AES-256 encrypted archive, `tools/sounds/clips.tar.enc`; the key is kept outside
the repo at `~/.config/sound-it-out/sounds.key` on each machine.

- New machine: copy `sounds.key` to that path, then `edu-reading/tools/sounds/decrypt.sh`.
- After changing the clips: `edu-reading/tools/sounds/encrypt.sh`, commit `clips.tar.enc`.
- From scratch (no archive/key): `tools/sounds/build_sounds.py <pack dir>` rebuilds them
  from the Phonicademy download.

Without the clips the app still builds; letter sounds stay silent.
