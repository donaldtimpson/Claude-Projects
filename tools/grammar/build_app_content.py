#!/usr/bin/env python3
"""Build the bundled grammar lesson-drill JSON from the shared content source.

Source of truth: content/grammar/drills/lesson-*.json (one drill object each:
slug/lesson/title/blurb/icon/layout/order/tier/items). This concatenates them,
validates every item against the app loaders' rules (>=2 distinct options,
in-range answer, unique ids), sorts by `lesson`, and writes {"drills":[...]} to
each app that bundles it.

Run from anywhere: `python3 tools/grammar/build_app_content.py`.
"""
import json
import sys
from pathlib import Path


def repo_root() -> Path:
    """Walk up until we find the dir holding both content/ and edu-ios/."""
    for d in Path(__file__).resolve().parents:
        if (d / "content").is_dir() and (d / "edu-ios").is_dir():
            return d
    sys.exit("could not locate repo root (needs content/ + edu-ios/)")


ROOT = repo_root()
SRC = ROOT / "content" / "grammar" / "drills"
# Every app that bundles the built lessons file. Phase 2 adds the edu-web target here.
TARGETS = [
    ROOT / "edu-ios" / "Resources" / "Grammar" / "lessons.json",
]


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
        sys.exit(f"no lesson-*.json found in {SRC}")
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
    payload = json.dumps({"drills": drills}, indent=1, ensure_ascii=False) + "\n"
    for out in TARGETS:
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(payload)
        print(f"wrote {out.relative_to(ROOT)}")
    total = sum(len(d["items"]) for d in drills)
    print(f"  {len(drills)} lesson drills, {total} items")
    for d in drills:
        print(f"  L{d.get('lesson'):<2} {d['slug']:<12} {len(d['items']):>3} items  {d['title']}")


if __name__ == "__main__":
    main()
