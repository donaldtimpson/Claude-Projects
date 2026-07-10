import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join } from "node:path";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import remarkMath from "remark-math";
import rehypeKatex from "rehype-katex";

// Render the note exactly as MarkdownNotes.tsx does and return any KaTeX parse
// errors (these surface as red error text on the page). The usual culprits:
//   • a multi-line $$…$$ block whose delimiters are NOT on their own lines, or
//     whose opening $$ is indented inside a list item — remark-math then eats
//     the opener line and never finds the closer (see lecture-notes-style.md).
//   • a literal "$" written next to math delimiters (e.g. the marker `$\$$`);
//     use `\mathdollar` INSIDE the math instead.
function katexErrors(content: string): string[] {
  const html = renderToStaticMarkup(
    createElement(ReactMarkdown as any, {
      remarkPlugins: [remarkGfm, remarkMath],
      rehypePlugins: [rehypeKatex],
      children: content,
    }),
  );
  return [...html.matchAll(/class="katex-error"[^>]*title="([^"]*)"/g)].map((m) =>
    m[1].replace(/&#x27;/g, "'").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">"),
  );
}

// Pre-import structural check for scripts/notes/*.md. Verifies each file is
// non-empty, contains the four expected study-note sections, has no
// instructor-name leak, and renders without KaTeX errors. DB-level checks
// (videoId exists) happen at import time.
const dir = join(process.cwd(), "scripts", "notes");
if (!existsSync(dir)) {
  console.error(`No notes directory found at ${dir}`);
  process.exit(1);
}

const REQUIRED_SECTIONS = ["## Overview", "## Key Concepts", "## Worked Example", "## Summary"];
const files = readdirSync(dir).filter((f) => f.endsWith(".md"));
let errors = 0;
const err = (m: string) => { console.log("  ✗ " + m); errors++; };

for (const f of files) {
  const content = readFileSync(join(dir, f), "utf8");
  if (!content.trim()) { err(`${f}: empty file`); continue; }
  for (const section of REQUIRED_SECTIONS) {
    if (!content.includes(section)) err(`${f}: missing "${section}" section`);
  }
  if (content.toLowerCase().includes("donald")) err(`${f}: mentions instructor name`);
  for (const tex of katexErrors(content)) err(`${f}: KaTeX render error — ${tex.slice(0, 140)}`);
}

console.log(`\n${files.length} file(s) checked. errors=${errors}`);
process.exit(errors > 0 ? 1 : 0);
