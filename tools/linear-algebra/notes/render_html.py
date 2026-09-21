#!/usr/bin/env python3
"""
Render a lecture-notes Markdown file to a standalone HTML viewer.

The notes Markdown in content/linear-algebra/notes/ is the source of truth. This
wraps it in a self-contained page that renders the Markdown client-side (marked.js)
with LaTeX math (MathJax, $inline$ / $$display$$) in the Timpson Lyceum house style.
No build deps — pure stdlib; the browser pulls marked + MathJax from a CDN.

Usage:
    python3 render_html.py content/linear-algebra/notes/01_systems-and-row-reduction.md
    python3 render_html.py <path.md> [--title "Custom title"] [-o out.html]

Default output is the input path with a .html suffix, next to the .md.
"""
import argparse
import re
import sys
from pathlib import Path

HEAD = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__TITLE__</title>
<script>
  window.MathJax = {
    tex: { inlineMath: [['$','$']], displayMath: [['$$','$$']] },
    svg: { fontCache: 'global' },
    options: { skipHtmlTags: ['script','noscript','style','textarea','pre','code'] }
  };
</script>
<script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js" async></script>
<style>
  :root{
    --crimson:#8a1a2b; --gold:#b08a2e; --ink:#23201c; --parchment:#faf7f0;
    --rule:#e4ddcf; --callout:#fbf4e6;
  }
  html{scroll-behavior:smooth}
  body{
    margin:0; background:var(--parchment); color:var(--ink);
    font-family:Georgia,'EB Garamond','Iowan Old Style',serif;
    font-size:19px; line-height:1.62;
  }
  #wrap{max-width:820px; margin:0 auto; padding:56px 28px 120px}
  h1,h2,h3{font-family:'Cinzel',Georgia,serif; line-height:1.2; color:var(--crimson)}
  h1{font-size:2.05rem; margin:0 0 .2em; text-align:center; letter-spacing:.5px}
  h2{font-size:1.5rem; margin:2.2em 0 .5em; padding-bottom:.22em; border-bottom:2px solid var(--gold)}
  h3{font-size:1.16rem; color:#5a2530; margin:1.6em 0 .35em}
  a{color:var(--crimson)}
  hr{border:0; border-top:1px solid var(--rule); margin:2.4em 0}
  strong{color:#1c1a17}
  code{background:#efe9dc; padding:.08em .35em; border-radius:4px; font-size:.86em}
  table{border-collapse:collapse; margin:1em 0; width:100%; font-size:.92em}
  th,td{border:1px solid var(--rule); padding:.5em .7em; text-align:left; vertical-align:top}
  th{background:#f0e9d9}
  blockquote{
    margin:1.1em 0; padding:.7em 1.1em; background:var(--callout);
    border-left:4px solid var(--gold); border-radius:0 6px 6px 0;
  }
  blockquote p{margin:.4em 0}
  blockquote strong{color:var(--crimson)}
  mjx-container[display="true"]{overflow-x:auto; overflow-y:hidden; padding:2px 0}
  .toolbar{
    max-width:820px; margin:0 auto; padding:10px 28px 0; text-align:right;
    font-family:system-ui,sans-serif; font-size:13px; color:#8a827200
  }
  @media print{ body{background:#fff} .toolbar{display:none} }
  @media (max-width:640px){ body{font-size:17px} #wrap{padding:32px 16px 80px} }
</style>
</head>
<body>
<div id="wrap"><p style="text-align:center;color:#9a9384;font-family:system-ui,sans-serif">Rendering…</p></div>
<script type="text/markdown" id="src">"""

TAIL = """</script>
<script>
  (function(){
    var raw = document.getElementById('src').textContent;
    // Protect math so the markdown parser can't mangle underscores/backslashes.
    var store = [], i = 0;
    raw = raw.replace(/\\$\\$[\\s\\S]+?\\$\\$/g, function(m){ store.push(m); return '@@M'+(i++)+'@@'; });
    raw = raw.replace(/\\$[^\\$\\n]+?\\$/g,   function(m){ store.push(m); return '@@M'+(i++)+'@@'; });
    var html = marked.parse(raw);
    html = html.replace(/@@M(\\d+)@@/g, function(_, n){ return store[+n]; });
    document.getElementById('wrap').innerHTML = html;
    var go = function(){ MathJax.typesetPromise(); };
    if (window.MathJax && MathJax.typesetPromise) go();
    else { var t=setInterval(function(){ if(window.MathJax&&MathJax.typesetPromise){clearInterval(t);go();} },80); }
  })();
</script>
</body>
</html>
"""


def first_heading(md: str) -> str:
    for line in md.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return "Linear Algebra — Lecture Notes"


def render(md: str, title: str) -> str:
    # The Markdown lives inside a <script> block; only a literal </script> could
    # close it early. Nothing else needs escaping (marked sees the raw text).
    safe = md.replace("</script>", "<\\/script>")
    return HEAD.replace("__TITLE__", title) + safe + TAIL


def main() -> int:
    ap = argparse.ArgumentParser(description="Render lecture-notes Markdown to a standalone HTML viewer.")
    ap.add_argument("md", type=Path, help="path to the notes .md")
    ap.add_argument("-o", "--out", type=Path, help="output .html (default: alongside the .md)")
    ap.add_argument("--title", help="page <title> (default: first H1 in the Markdown)")
    args = ap.parse_args()

    if not args.md.exists():
        print(f"error: {args.md} not found", file=sys.stderr)
        return 1

    md = args.md.read_text(encoding="utf-8")
    title = args.title or first_heading(md)
    out = args.out or args.md.with_suffix(".html")
    out.write_text(render(md, title), encoding="utf-8")
    print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
