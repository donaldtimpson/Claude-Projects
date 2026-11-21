#!/usr/bin/env python3
"""The decodability checker for Sound It Out.

Every reading word carries `parts`: its graphemes in order, each with the phoneme
it makes when that isn't the grapheme's usual one ("c", "a:ay", "k", "e:_" for
cake — "_" is silent). Those parts drive sound-by-sound playback, the spelling
tiles, and this check.

A grapheme/phoneme pair is taught at one level of the ladder. A word may only use
pairs taught at or before its own level; a sentence may only use words that pass
at its level, plus heart words introduced by then. Run by sync-content.sh, so a
sentence that sneaks in "for" at the digraph stage fails the build instead of
reaching a child.

    python3 phonics.py lint              # check (exit 1 on any problem)
    python3 phonics.py fill              # add `parts` to words that lack them
    python3 phonics.py parts <word>...   # show how words would segment
"""
import json, os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
CONTENT = os.path.join(ROOT, "content/reading/reading.json")

LEVELS = ["CVC", "Digraphs", "Blends", "SilentE",
          "VowelTeams", "RControlled", "Diphthongs", "Endings"]

# grapheme -> [(phoneme, level index)], first entry is the usual sound.
# Phoneme ids are the audio clip names (ph_<id>.m4a); "+" plays two clips.
TABLE = {}
def teach(level, pairs):
    for g, p in pairs:
        TABLE.setdefault(g, []).append((p, LEVELS.index(level)))

teach("CVC", [(c, c) for c in "bdfghjklmnprstvwz"] +
      [("a", "a"), ("e", "e"), ("i", "i"), ("o", "o"), ("u", "u"),
       ("c", "k"), ("x", "ks"), ("y", "y"),
       ("ff", "f"), ("ll", "l"), ("ss", "s"), ("zz", "z")])
teach("Digraphs", [("sh", "sh"), ("ch", "ch"), ("th", "th"), ("th", "dh"),
                   ("ck", "k"), ("ng", "ng"), ("wh", "w"), ("qu", "kw")])
teach("Blends", [("nk", "ng+k")])
teach("SilentE", [("a", "ay"), ("i", "igh"), ("o", "oa"), ("u", "yoo"),
                  ("u", "oo"), ("e", "ee"), ("e", "_")])
teach("VowelTeams", [("ai", "ay"), ("ay", "ay"), ("ee", "ee"), ("ea", "ee"),
                     ("oa", "oa"), ("ow", "oa"), ("igh", "igh"),
                     ("oo", "oo"), ("oo", "oo_short")])
teach("RControlled", [("ar", "ar"), ("or", "or"), ("er", "er"),
                      ("ir", "er"), ("ur", "er")])
teach("Diphthongs", [("ou", "ow"), ("ow", "ow"), ("oi", "oi"), ("oy", "oi"),
                     ("aw", "aw")])
teach("Endings", [("s", "z")])

# The usual sound when segmenting fresh, where a grapheme has several.
USUAL = {"ow": "ow", "oo": "oo", "th": "th"}
# Known words whose sound isn't the usual one, used only by `fill`.
OVERRIDES = {
    "snow": {"ow": "oa"}, "book": {"oo": "oo_short"}, "foot": {"oo": "oo_short"},
    "look": {"oo": "oo_short"}, "good": {"oo": "oo_short"},
    "that": {"th": "dh"}, "this": {"th": "dh"}, "then": {"th": "dh"},
    "with": {"th": "dh"}, "them": {"th": "dh"},
}
LONG = {"a": "ay", "i": "igh", "o": "oa", "e": "ee"}
VOWELS = set("aeiou")
MULTI = sorted((g for g in TABLE if len(g) > 1), key=len, reverse=True)


def segment(word):
    """Greedy longest-match against EVERY grapheme the ladder knows, so "for"
    becomes f + or (r-controlled) rather than slipping through as f-o-r."""
    w = word.lower()
    out, i = [], 0
    while i < len(w):
        g = next((m for m in MULTI if w.startswith(m, i)), w[i])
        out.append([g, None])
        i += len(g)
    # Split digraph: single vowel, one consonant, final e ("cake", "tune").
    if (len(out) >= 3 and out[-1][0] == "e" and out[-2][0] not in VOWELS
            and len(out[-2][0]) <= 2 and out[-3][0] in VOWELS
            and not (len(out) >= 4 and out[-4][0] in VOWELS)):
        v = out[-3][0]
        out[-3][1] = ("oo" if out[-4][0] in ("r", "l", "j", "t", "d", "n", "s", "ch") else "yoo") \
            if v == "u" else LONG[v]
        out[-1][1] = "_"
    elif len(out) >= 2 and out[-1][0] == "e" and out[-2][0] not in VOWELS and \
            any(len(p[0]) > 1 and p[0][0] in VOWELS for p in out[:-2]):
        out[-1][1] = "_"           # "house": the e after a vowel team is silent
    for i, p in enumerate(out):
        if p[1] is None:
            p[1] = default(p[0])
        nxt = out[i + 1][0] if i + 1 < len(out) else ""
        # Soft c (city, mice) and soft g (huge, cage) are never taught, so a word
        # that needs one can't pass as decodable.
        if p[0] == "c" and nxt[:1] in ("e", "i", "y"):
            p[1] = "soft_c"
        if p[0] == "g" and nxt == "e" and i + 2 == len(out):
            p[1] = "soft_g"
    o = OVERRIDES.get(w, {})
    for p in out:
        if p[0] in o:
            p[1] = o[p[0]]
    return out


def default(g):
    g = g.lower()
    return USUAL.get(g) or TABLE.get(g, [(g, 0)])[0][0]


def encode(parts):
    return [g if default(g) == p else f"{g}:{p}" for g, p in parts]


def decode(strs):
    out = []
    for s in strs:
        g, _, p = s.partition(":")
        out.append((g, p or default(g)))
    return out


def level_of(parts):
    """The earliest level at which every pair is taught; None if a pair never is."""
    worst = 0
    for g, p in parts:
        lv = [l for ph, l in TABLE.get(g.lower(), []) if ph == p]
        if not lv:
            return None, f"'{g}' as /{p}/ is never taught"
        worst = max(worst, min(lv))
    return worst, None


def tokens(text):
    return [t for t in (re.sub(r"[^A-Za-z']", "", x) for x in text.split()) if t]


def lint(d):
    errs = []
    heart = {h["word"].lower(): h.get("level", 1) for h in d["heartWords"]}
    known = {}
    for w in d["words"]:
        parts = w.get("parts")
        if not parts:
            errs.append(f"word '{w['word']}': no parts (run phonics.py fill)"); continue
        pairs = decode(parts)
        if "".join(g for g, _ in pairs).lower() != w["word"].lower():
            errs.append(f"word '{w['word']}': parts {parts} don't spell it")
        lv, why = level_of(pairs)
        want = LEVELS.index(w["level"])
        if lv is None:
            errs.append(f"word '{w['word']}': {why}")
        elif lv > want:
            errs.append(f"word '{w['word']}' ({w['level']}) needs {LEVELS[lv]}: {parts}")
        known[w["word"].lower()] = lv if lv is not None else 99

    def check_text(text, level, label, extra=()):
        for t in tokens(text):
            tl = t.lower()
            if tl in extra:
                continue
            if tl in heart:
                if heart[tl] > level:
                    errs.append(f"{label}: heart word '{t}' is introduced at level {heart[tl]}")
                continue
            lv = known.get(tl)
            if lv is None:
                lv, why = level_of(segment(tl))
                if lv is None:
                    errs.append(f"{label}: '{t}' — {why}"); continue
            if lv + 1 > level:
                errs.append(f"{label}: '{t}' needs {LEVELS[lv]} (level {lv + 1})")

    for s in d["sentences"]:
        check_text(s["text"], s.get("level") or 99, f"sentence '{s['text']}' (L{s.get('level')})")
    for h in d["heartWords"]:
        check_text(h["sentence"], h.get("level", 1),
                   f"heart '{h['word']}' example '{h['sentence']}'", extra=(h["word"].lower(),))
    for b in d.get("books", []):
        for pg in b["pages"]:
            check_text(pg["text"], b["level"], f"book '{b['title']}' (L{b['level']}): '{pg['text']}'")
    words = [w["word"] for w in d["words"]]
    for dup in {x for x in words if words.count(x) > 1}:
        errs.append(f"word '{dup}' appears twice")
    return errs


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "lint"
    if cmd == "parts":
        for w in sys.argv[2:]:
            p = segment(w); lv, why = level_of(p)
            print(w, encode(p), LEVELS[lv] if lv is not None else why)
        return
    d = json.load(open(CONTENT))
    defaults = {g: default(g) for g in sorted(TABLE)}
    if cmd == "fill" or d.get("phonemeDefaults") != defaults:
        d["phonemeDefaults"] = defaults
        cmd = "fill"
    if cmd == "fill":
        n = 0
        for w in d["words"]:
            if not w.get("parts"):
                w["parts"] = encode(segment(w["word"])); n += 1
        with open(CONTENT, "w") as f:
            json.dump(d, f, ensure_ascii=False, indent=2); f.write("\n")
        print(f"filled {n} words")
    errs = lint(d)
    for e in errs:
        print("  ✗", e)
    if errs:
        print(f"{len(errs)} decodability problem(s) in reading.json"); sys.exit(1)
    print(f"decodable: {len(d['words'])} words, {len(d['sentences'])} sentences, "
          f"{len(d['heartWords'])} heart words")


if __name__ == "__main__":
    main()
