# Sourcing photographs for Look and Say

Three steps, and the middle one is a person looking at pictures. That is not a gap
in the tooling — it is the job.

```bash
python3 fetch.py  words.txt  out/       # 1. pull 4 candidates per word from Openverse
swift  sheet.swift out/ sheets/         # 2. lay them out as contact sheets
python3 install.py picks.json out/      # 3. crop, compress, write imagesets + credits
```

## Why a human has to pick

Every attempt at fully automatic selection produced cards that teach the wrong
thing, and they fail in ways a machine cannot notice:

| Source | Query | What came back |
|---|---|---|
| Wikimedia search | `apple` | An Apple II computer |
| Wikimedia search | `dog` | A dhole (a wild canid) |
| Wikipedia lead image | `sleep` | A Domenico Fetti painting |
| Wikipedia lead image | `star` | The Sun — byte-identical to the `sun` card |
| Openverse | `pig` | Guinea pigs, and a freight train |
| Openverse | `milk` | A milk tanker truck |
| Openverse | `nose` | A cow's, a cat's, and a dog's |

All of these are *correct* results. None of them show a four-year-old what the
word means. Roughly a quarter of first-pass results need rejecting, and the only
reliable detector is an eye.

## Query hints

`hints.json` maps a word to a better query where the bare noun is ambiguous:
`mouse` → `mouse animal`, `orange` → `orange fruit`, `seal` → `seal animal`.
Add to it whenever a word comes back wrong — that is cheaper than re-reviewing.

## Licensing

Only `cc0` and `by` are requested. **`by` obliges naming the photographer**, so
`install.py` writes `photo-credits.json` alongside the images and the app lists
every one in the grown-ups' area. Do not widen this to `by-nc` — non-commercial
cannot survive a paid or ad-supported future.

## Two traps

- **Contact-sheet numbers are positional, not filename suffixes.** Where a
  download failed the two diverge. `install.py` indexes the sorted candidate list,
  which is what the sheet showed.
- **Imagesets must be single-scale universal.** One declaring empty 2x/3x slots
  returns nil from `UIImage(named:)` on a 3x device even though the file is present
  in `Assets.car` — indistinguishable from the image not being bundled.
