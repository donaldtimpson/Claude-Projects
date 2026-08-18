#!/usr/bin/env python3
"""Build the bundled grammar JSON banks from the shared content source.

Source of truth (content/grammar/):
  drills/lesson-*.json  — per-lesson homework banks, concatenated → lessons.json
  practice.json         — the ✒️ rule/vocab practice bank ({"drills":[...]}) → grammar.json

Both are validated against the app loaders' rules (>=2 distinct options, in-range
answer, unique ids) and emitted to every app that bundles them:
  edu-ios/Resources/Grammar/{lessons,grammar}.json     (Xcode bundles these)
  edu-web/lib/drills/grammar/data/{lessons,grammar}.json  (imported at build time)

Run from anywhere: `python3 tools/grammar/build_app_content.py`.
"""
import json
import sys
from pathlib import Path


def repo_root() -> Path:
    for d in Path(__file__).resolve().parents:
        if (d / "content").is_dir() and (d / "edu-ios").is_dir():
            return d
    sys.exit("could not locate repo root (needs content/ + edu-ios/)")


ROOT = repo_root()
CONTENT = ROOT / "content" / "grammar"
# Dirs each get both lessons.json and grammar.json written into them.
TARGET_DIRS = [
    ROOT / "edu-ios" / "Resources" / "Grammar",
    ROOT / "edu-web" / "lib" / "drills" / "grammar" / "data",
]


def validate_drill(drill, where):
    errs = []
    slug = drill.get("slug", "?")
    for key in ("slug", "title", "icon", "items"):
        if key not in drill:
            errs.append(f"{where}: missing '{key}'")
    seen_ids = set()
    for it in drill.get("items", []):
        iid = it.get("id", "?")
        if iid in seen_ids:
            errs.append(f"{slug}: duplicate item id {iid}")
        seen_ids.add(iid)
        opts = it.get("options", [])
        if len(opts) < 2:
            errs.append(f"{slug}/{iid}: needs >=2 options")
        if len(set(opts)) != len(opts):
            errs.append(f"{slug}/{iid}: options must be distinct (shuffle keys on text)")
        ans = it.get("answer")
        if not isinstance(ans, int) or ans < 0 or ans >= len(opts):
            errs.append(f"{slug}/{iid}: answer index {ans} out of range")
        for key in ("prompt", "explain"):
            if not it.get(key):
                errs.append(f"{slug}/{iid}: missing '{key}'")
    return errs


def load_lessons(errs):
    files = sorted((CONTENT / "drills").glob("lesson-*.json"))
    if not files:
        sys.exit(f"no lesson-*.json found in {CONTENT / 'drills'}")
    drills, slugs = [], set()
    for p in files:
        d = json.loads(p.read_text())
        errs += validate_drill(d, p.name)
        if d.get("slug") in slugs:
            errs.append(f"duplicate slug {d.get('slug')}")
        slugs.add(d.get("slug"))
        drills.append(d)
    drills.sort(key=lambda d: d.get("lesson", 999))
    return {"drills": drills}


def load_practice(errs):
    obj = json.loads((CONTENT / "practice.json").read_text())
    slugs = set()
    for d in obj.get("drills", []):
        errs += validate_drill(d, "practice.json")
        if d.get("slug") in slugs:
            errs.append(f"duplicate slug {d.get('slug')}")
        slugs.add(d.get("slug"))
    return obj


def main():
    errs = []
    banks = {"lessons.json": load_lessons(errs), "grammar.json": load_practice(errs)}
    if errs:
        print("VALIDATION FAILED:")
        for e in errs:
            print("  -", e)
        sys.exit(1)
    for name, payload in banks.items():
        text = json.dumps(payload, indent=1, ensure_ascii=False) + "\n"
        for d in TARGET_DIRS:
            d.mkdir(parents=True, exist_ok=True)
            (d / name).write_text(text)
    for name, payload in banks.items():
        total = sum(len(x["items"]) for x in payload["drills"])
        print(f"{name}: {len(payload['drills'])} drills, {total} items "
              f"→ {', '.join(str(d.relative_to(ROOT)) for d in TARGET_DIRS)}")


if __name__ == "__main__":
    main()
