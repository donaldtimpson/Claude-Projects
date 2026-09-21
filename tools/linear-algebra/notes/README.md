# linear-algebra/notes tools

Generator for the Linear Algebra pre-lecture notes. The notes Markdown in
`content/linear-algebra/notes/` is the source of truth; this renders it for the browser.

## `render_html.py`
Wraps a notes `.md` in a self-contained HTML viewer — Lyceum house style, Markdown rendered
client-side by marked.js, LaTeX math (`$…$` / `$$…$$`) by MathJax. Pure stdlib; the browser
pulls the two libraries from a CDN, so no `pip`/`.venv` is needed.

```bash
# writes content/linear-algebra/notes/01_systems-and-row-reduction.html
python3 tools/linear-algebra/notes/render_html.py content/linear-algebra/notes/01_systems-and-row-reduction.md
```

The page `<title>` defaults to the first `# ` heading; override with `--title`. Output defaults
to the input path with a `.html` suffix; override with `-o`.
