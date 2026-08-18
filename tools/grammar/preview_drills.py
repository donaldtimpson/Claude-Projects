#!/usr/bin/env python3
"""Render drills/lesson-*.json to a browser preview (Lyceum theme) for review.

Lists every drill and every item with the CORRECT option marked, so the whole pool can be
eyeballed without building the app. Review aid only — the drills ship to iOS.
    python preview.py            # all lessons -> build/lessons-preview.html
    python preview.py lesson-01  # just one
"""
import html
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SRC = ROOT.parent.parent / "content" / "grammar" / "drills"

# Lyceum palette (mirrors grammar-slides/themes.py "lyceum")
CSS = """
*{box-sizing:border-box;}
:root{--paper:#190808;--ink:#F5ECD8;--accent:#DDB954;--muted:#C4AF8E;--rule:#4A1A1A;
      --answer:#5CB85C;--body-bg:#0F0404;}
body{margin:0;background:var(--body-bg);color:var(--ink);font-family:Georgia,'Times New Roman',serif;padding:32px 20px;line-height:1.4;}
.wrap{max-width:900px;margin:0 auto;}
h1{color:var(--accent);font-weight:700;letter-spacing:.02em;text-align:center;margin:0 0 4px;}
.sub{text-align:center;color:var(--muted);font-style:italic;margin:0 0 28px;}
.drill{background:var(--paper);border:1px solid var(--rule);border-radius:8px;padding:24px 28px;margin-bottom:22px;box-shadow:0 2px 12px rgba(0,0,0,.35);}
.dhead{display:flex;align-items:baseline;gap:10px;}
.dicon{font-size:26px;}
.dtitle{color:var(--accent);font-weight:700;font-size:24px;margin:0;}
.dcount{margin-left:auto;color:var(--muted);font-size:14px;font-variant-numeric:tabular-nums;}
.dblurb{color:var(--muted);font-style:italic;font-size:15px;margin:2px 0 14px;}
.dbl{border:0;height:0;margin:0 0 16px;border-top:3px solid var(--accent);box-shadow:0 4px 0 -3px var(--rule);}
.item{padding:12px 0;border-bottom:1px solid var(--rule);}
.item:last-child{border-bottom:0;}
.q{white-space:pre-line;font-size:18px;margin-bottom:8px;}
.qn{color:var(--accent);font-weight:700;margin-right:6px;}
.opts{display:flex;flex-wrap:wrap;gap:8px;margin-bottom:6px;}
.opt{border:1px solid var(--rule);border-radius:16px;padding:4px 12px;font-size:15px;color:var(--ink);}
.opt.correct{border-color:var(--answer);color:var(--answer);font-weight:700;}
.exp{color:var(--muted);font-size:14px;font-style:italic;}
.cnote{color:var(--muted);font-size:13px;margin:-6px 0 12px;}
"""


def esc(s):
    return html.escape(str(s))


def render_drill(d):
    items = d["items"]
    rows = ""
    for i, it in enumerate(items, 1):
        opts = "".join(
            f'<span class="opt{" correct" if j == it["answer"] else ""}">{esc(o)}</span>'
            for j, o in enumerate(it["options"]))
        rows += (f'<div class="item"><div class="q"><span class="qn">{i}.</span>{esc(it["prompt"])}</div>'
                 f'<div class="opts">{opts}</div>'
                 f'<div class="exp">{esc(it["explain"])}</div></div>')
    # concept tally
    return (f'<div class="drill"><div class="dhead"><span class="dicon">{esc(d.get("icon",""))}</span>'
            f'<h2 class="dtitle">{esc(d["title"])}</h2>'
            f'<span class="dcount">{len(items)} items · run of 30</span></div>'
            f'<div class="dblurb">{esc(d.get("blurb",""))}</div><hr class="dbl">{rows}</div>')


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else None
    files = sorted(SRC.glob(f"{which}.json" if which else "lesson-*.json"))
    if not files:
        sys.exit("no matching drills/lesson-*.json")
    drills = sorted((json.loads(p.read_text()) for p in files), key=lambda d: d.get("lesson", 999))
    body = "".join(render_drill(d) for d in drills)
    total = sum(len(d["items"]) for d in drills)
    doc = (f'<title>Lesson Drills — Preview</title>'
           f'<meta name="description" content="Per-lesson homework drill pools ({total} items)">'
           f'<style>{CSS}</style><div class="wrap">'
           f'<h1>Lesson Homework Drills</h1>'
           f'<div class="sub">{len(drills)} lesson pool(s) · {total} items · correct answer in green</div>'
           f'{body}</div>')
    out = ROOT / "build"
    out.mkdir(exist_ok=True)
    path = out / ("lessons-preview.html" if not which else f"{which}-preview.html")
    path.write_text(doc)
    print(f"wrote {path}")


if __name__ == "__main__":
    main()
