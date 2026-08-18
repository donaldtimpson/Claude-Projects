#!/usr/bin/env python3
"""Concatenate drills/lesson-*.json into the bundled edu-ios/Resources/Grammar/lessons.json.

Each source file is one drill object (slug/lesson/title/blurb/icon/layout/order/tier/items).
Validates every item against the iOS loader's rules (>=2 distinct options, in-range answer,
unique ids) so a bad row can't silently drop in the app. Emits {"drills":[...]} ordered by
the `lesson` number.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SRC = ROOT / "drills"
OUT = ROOT.parent / "edu-ios" / "Resources" / "Grammar" / "lessons.json"


def validate(drill, path):
    errs = []
    slug = drill.get("slug", "?")
    for key in ("slug", "title", "icon", "items"):
        if key not in drill:
            errs.append(f"{path.name}: missing '{key}'")
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


def main():
    files = sorted(SRC.glob("lesson-*.json"))
    if not files:
        sys.exit("no drills/lesson-*.json found")
    drills, errs, slugs = [], [], set()
    for p in files:
        d = json.loads(p.read_text())
        errs += validate(d, p)
        if d.get("slug") in slugs:
            errs.append(f"duplicate slug {d.get('slug')}")
        slugs.add(d.get("slug"))
        drills.append(d)
    if errs:
        print("VALIDATION FAILED:")
        for e in errs:
            print("  -", e)
        sys.exit(1)
    drills.sort(key=lambda d: d.get("lesson", 999))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({"drills": drills}, indent=1, ensure_ascii=False) + "\n")
    total = sum(len(d["items"]) for d in drills)
    print(f"wrote {OUT}")
    print(f"  {len(drills)} lesson drills, {total} items")
    for d in drills:
        print(f"  L{d.get('lesson'):<2} {d['slug']:<12} {len(d['items']):>3} items  {d['title']}")


if __name__ == "__main__":
    main()
