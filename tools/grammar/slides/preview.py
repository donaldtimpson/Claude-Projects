#!/usr/bin/env python3
"""Lesson JSON -> standalone HTML slideshow (for quick visual review as an Artifact).

Mirrors the look of generate_deck.py so the HTML preview matches the .pptx.

Usage:
    python preview.py the-verb            # writes build/the-verb.html
"""
import base64
import html
import json
import sys
from pathlib import Path

from themes import THEMES, get_theme

REPO_ROOT = Path(__file__).resolve().parents[3]


def font_stack(name):
    if name == "Georgia":
        return "Georgia, 'Times New Roman', serif"
    return f"'{name}', Georgia, serif"


def font_faces(theme):
    """Inline the theme's .ttf files as @font-face data URIs (CSP blocks CDNs)."""
    out = []
    for family, relpath in (theme.get("fonts") or {}).items():
        data = (REPO_ROOT / relpath).read_bytes()
        b64 = base64.b64encode(data).decode()
        out.append(
            f"@font-face{{font-family:'{family}';font-weight:400 700;font-display:swap;"
            f"src:url(data:font/ttf;base64,{b64}) format('truetype');}}")
    return "".join(out)


def root_vars(theme):
    return (":root{"
            f"--paper:#{theme['paper']}; --ink:#{theme['ink']}; --accent:#{theme['accent']};"
            f"--muted:#{theme['muted']}; --rule:#{theme['rule']}; --answer:#{theme['answer']};"
            f"--diagram:#{theme['diagram']}; --body-bg:#{theme['body_bg']};"
            f"--head-font:{font_stack(theme.get('head_font', 'Georgia'))};"
            f"--body-font:{font_stack(theme.get('body_font', 'Georgia'))};}}")


CSS_BODY = """
* { box-sizing: border-box; }
body { margin:0; background:var(--body-bg); font-family: var(--body-font);
       color:var(--ink); padding:24px; }
.deck { max-width: 960px; margin: 0 auto; }
.slide {
  position: relative; background: var(--paper); aspect-ratio: 16/9;
  border: 1px solid var(--rule); border-radius: 4px; margin-bottom: 22px;
  padding: 52px 64px; box-shadow: 0 2px 10px rgba(0,0,0,.08); overflow: hidden;
}
.slide .foot { position:absolute; left:64px; bottom:22px; font-size:12px;
               font-style:italic; color:var(--muted); }
/* thick-then-thin letterpress rule */
.dbl { border:0; height:0; margin: 0 0 26px;
       border-top: 3px solid var(--accent); box-shadow: 0 4px 0 -3px var(--rule); }
.h { color: var(--accent); font-family: var(--head-font); font-weight: 700; font-size: 34px; margin: 0 0 10px; }
.title-slide { display:flex; flex-direction:column; align-items:center;
               justify-content:center; text-align:center; }
.title-slide .eyebrow { color: var(--muted); font-family: var(--head-font); font-weight:700;
       font-size: 15px; letter-spacing: .28em; text-transform: uppercase; margin: 0 0 8px; }
.title-slide .t { color: var(--accent); font-family: var(--head-font); font-weight:700;
       font-size: 60px; margin: 8px 0; }
.title-slide .st { color: var(--muted); font-style: italic; font-size: 22px; margin-top: 16px; }
.title-slide .dbl { width: 320px; margin: 10px 0; }
.title-slide .motto { color: var(--accent); font-style: italic; font-size: 19px;
       letter-spacing: .03em; margin-top: 16px; }
.defn { font-style: italic; font-size: 30px; line-height: 1.35; margin: 8px 0 26px; }
.exlabel { color: var(--accent); font-weight:700; font-size: 15px; margin: 0 0 8px;
           letter-spacing: .18em; text-transform: uppercase; }
ul.b { list-style: none; padding: 0; margin: 0; }
ul.b li { font-size: 24px; line-height: 1.4; margin-bottom: 12px; padding-left: 26px;
          position: relative; }
ul.b li:before { content: "•"; color: var(--accent); font-weight: 700;
                 position: absolute; left: 0; }
.ex li { font-size: 22px; margin-bottom: 8px; }
.instr { color: var(--muted); font-style: italic; font-size: 18px; margin: 0 0 20px; }
.ansline { color: var(--answer); font-weight: 700; font-size: 20px; margin-top: 3px; padding-left: 22px; }
.qans { color: var(--answer); font-weight: 700; font-size: 20px; margin-left: 4px; }
.ansinline { color: var(--answer); font-weight: 700; margin-left: 6px; }
.anskey { position: absolute; top: 54px; right: 64px; color: var(--accent);
          font-weight: 700; font-size: 14px; letter-spacing: .18em;
          text-transform: uppercase; }
.diagrows { }
.diagrows li { margin-bottom: 16px; display: flex; align-items: center; gap: 14px; }
svg.diag { display: block; }
svg.diag text { font-family: var(--body-font); font-size: 18px; fill: var(--diagram); }
svg.diag line { stroke: var(--diagram); stroke-width: 1.6; }
.cols { display: grid; grid-template-columns: 1fr 1fr; gap: 12px 28px; }
ol.q { padding-left: 0; list-style: none; counter-reset: q; }
ol.q li { counter-increment: q; font-size: 24px; line-height: 1.4; margin-bottom: 14px;
          padding-left: 34px; position: relative; }
ol.q li:before { content: counter(q) "."; color: var(--accent); font-weight: 700;
                 position: absolute; left: 0; }
ol.q.tight li { font-size: 22px; line-height: 1.2; margin-bottom: 5px; }
"""


_BRAND = {"eyebrow": "", "motto": ""}


def esc(s):
    return html.escape(str(s))


def diagram_svg(s, p, o=None):
    """Reed-Kellogg baseline: subject | predicate | object. The
    subject/predicate divider crosses below the baseline; the
    predicate/object divider stops at it."""
    ch, pad = 9.8, 15
    ws = len(s) * ch + 2 * pad
    wp = len(p) * ch + 2 * pad
    wo = (len(o) * ch + 2 * pad) if o else 0
    total = ws + wp + wo
    base, topln, below, texty = 30, 6, 13, 23
    x1, x2 = ws, ws + wp
    parts = [f'<svg class="diag" width="{total:.0f}" height="46" '
             f'viewBox="0 0 {total:.0f} 46" xmlns="http://www.w3.org/2000/svg">']
    parts.append(f'<line x1="0" y1="{base}" x2="{total:.0f}" y2="{base}"/>')
    parts.append(f'<line x1="{x1:.0f}" y1="{topln}" x2="{x1:.0f}" y2="{base + below}"/>')
    if o:
        parts.append(f'<line x1="{x2:.0f}" y1="{topln}" x2="{x2:.0f}" y2="{base}"/>')
    parts.append(f'<text x="{ws/2:.0f}" y="{texty}" text-anchor="middle">{esc(s)}</text>')
    parts.append(f'<text x="{ws + wp/2:.0f}" y="{texty}" text-anchor="middle">{esc(p)}</text>')
    if o:
        parts.append(f'<text x="{ws + wp + wo/2:.0f}" y="{texty}" text-anchor="middle">{esc(o)}</text>')
    parts.append('</svg>')
    return "".join(parts)


def render(slide, source, show_answers=False):
    t = slide["type"]
    foot = f'<div class="foot">{esc(source)}</div>'
    if t == "title":
        st = f'<div class="st">{esc(slide["subtitle"])}</div>' if slide.get("subtitle") else ""
        motto = f'<div class="motto">{esc(_BRAND["motto"])}</div>' if _BRAND.get("motto") else ""
        return (f'<section class="slide title-slide">'
                f'<div class="eyebrow">{esc(_BRAND["eyebrow"])}</div>'
                f'<hr class="dbl">'
                f'<h1 class="t">{esc(slide["title"])}</h1>{st}'
                f'<hr class="dbl">{motto}{foot}</section>')
    if t == "definition":
        exs = ""
        if slide.get("examples"):
            lis = "".join(f"<li>{esc(e)}</li>" for e in slide["examples"])
            exs = f'<p class="exlabel">Examples</p><ul class="b ex">{lis}</ul>'
        return (f'<section class="slide"><h2 class="h">{esc(slide["term"])}</h2><hr class="dbl">'
                f'<div class="defn">{esc(slide["text"])}</div>{exs}{foot}</section>')
    if t == "concept":
        lis = "".join(f"<li>{esc(b)}</li>" for b in slide["bullets"])
        return (f'<section class="slide"><h2 class="h">{esc(slide["heading"])}</h2><hr class="dbl">'
                f'<ul class="b">{lis}</ul>{foot}</section>')
    if t == "practice":
        items = slide["items"]
        answers = slide.get("answers") or []
        is_diagram = bool(answers) and isinstance(answers[0], dict)
        tag = '<div class="anskey">Answer Key</div>' if show_answers else ''
        head = (f'<h2 class="h">{esc(slide["heading"])}</h2><hr class="dbl">'
                f'<p class="instr">{esc(slide["instruction"])}</p>')
        if show_answers and is_diagram:
            rows = "".join(
                f'<li><b style="color:var(--accent)">{i+1}.</b>'
                f'{diagram_svg(a["s"], a["p"], a.get("o"))}</li>'
                for i, a in enumerate(answers))
            body = f'<ul class="b diagrows" style="list-style:none">{rows}</ul>'
        else:
            mid = (len(items) + 1) // 2
            inline = bool(slide.get("answerInline"))
            def col(start, chunk):
                out = ""
                for i, it in enumerate(chunk):
                    n = start + i
                    ans = ""
                    if show_answers and not is_diagram and n - 1 < len(answers):
                        if inline:
                            ans = f' <span class="ansinline">{esc(answers[n-1])}</span>'
                        else:
                            ans = f'<div class="ansline">{esc(answers[n-1])}</div>'
                    out += f'<li><b style="color:var(--accent)">{n}.</b> {esc(it)}{ans}</li>'
                return out
            left = f'<ul class="b" style="list-style:none">{col(1, items[:mid])}</ul>'
            right = f'<ul class="b" style="list-style:none">{col(mid+1, items[mid:])}</ul>'
            body = f'<div class="cols">{left}{right}</div>'
        return f'<section class="slide">{tag}{head}{body}{foot}</section>'
    if t == "questions":
        answers = slide.get("answers") or []
        tag = '<div class="anskey">Answer Key</div>' if show_answers else ''
        lis = ""
        for i, q in enumerate(slide["items"]):
            ans = ""
            if show_answers and i < len(answers):
                ans = f' <span class="qans">{esc(answers[i])}</span>'
            lis += f"<li>{esc(q)}{ans}</li>"
        qcls = "q tight" if show_answers else "q"
        return (f'<section class="slide">{tag}<h2 class="h">Questions</h2><hr class="dbl">'
                f'<ol class="{qcls}">{lis}</ol>{foot}</section>')
    return ""


def build(lesson_path: Path, theme_name="light") -> Path:
    theme = get_theme(theme_name)
    _BRAND["eyebrow"] = theme.get("eyebrow", "")
    _BRAND["motto"] = theme.get("motto", "")
    data = json.loads(lesson_path.read_text())
    source = data.get("source", "")
    parts = []
    for s in data["slides"]:
        parts.append(render(s, source))
        if s["type"] in ("practice", "questions") and s.get("answers"):
            parts.append(render(s, source, show_answers=True))
    slides = "\n".join(parts)
    css = font_faces(theme) + root_vars(theme) + CSS_BODY
    doc = (f'<title>{esc(data["title"])} — Slides Preview</title>'
           f'<meta name="description" content="{esc(source)}">'
           f'<style>{css}</style><div class="deck">{slides}</div>')
    out_dir = Path(__file__).resolve().parent / "build"
    out_dir.mkdir(exist_ok=True)
    suffix = "" if theme_name == "light" else f"-{theme_name}"
    out_path = out_dir / f"{data['lesson']}{suffix}.html"
    out_path.write_text(doc)
    return out_path


def resolve(arg: str) -> Path:
    p = Path(arg)
    if p.suffix == ".json" and p.exists():
        return p
    cand = Path(__file__).resolve().parents[3] / "content" / "grammar" / "lessons" / f"{arg}.json"
    if cand.exists():
        return cand
    raise SystemExit(f"Lesson not found: {arg}")


if __name__ == "__main__":
    lesson, theme = "the-verb", "light"
    for a in sys.argv[1:]:
        if a in THEMES:
            theme = a
        else:
            lesson = a
    out = build(resolve(lesson), theme)
    print(f"wrote {out}  (theme: {theme})")
