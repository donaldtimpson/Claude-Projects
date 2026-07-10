import { existsSync } from "node:fs";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import remarkMath from "remark-math";
import rehypeKatex from "rehype-katex";
import { PROBLEM_SETS_DIR, listProblemSetFiles } from "./problem-sets-lib";

// Pre-import structural + KaTeX check for scripts/problem-sets/*.md. Mirrors
// validate-notes.ts: renders the Markdown through the real MarkdownNotes KaTeX
// pipeline and fails on any parse error, plus problem-set-specific checks
// (title format, point-tag sums, no instructor-name leak). See
// scripts/problem-sets-style.md. DB-level checks happen at import time.

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

// Sum the "(N pts)" core tags and "(N pts ••)" extra-credit tags in the body.
function sumPointTags(body: string): { core: number; extra: number } {
  let core = 0;
  let extra = 0;
  for (const m of body.matchAll(/\((\d+)\s*pts?\s*(••)?\)/g)) {
    const n = Number.parseInt(m[1], 10);
    if (m[2]) extra += n;
    else core += n;
  }
  return { core, extra };
}

if (!existsSync(PROBLEM_SETS_DIR)) {
  console.error(`No problem-sets directory found at ${PROBLEM_SETS_DIR}`);
  process.exit(1);
}

let files;
try {
  files = listProblemSetFiles();
} catch (e) {
  console.error(`  ✗ ${(e as Error).message}`);
  process.exit(1);
}

if (files.length === 0) {
  console.error(`No .md problem-set files found in ${PROBLEM_SETS_DIR}`);
  process.exit(1);
}

let errors = 0;
const err = (m: string) => {
  console.log("  ✗ " + m);
  errors++;
};

const seenTitles = new Set<string>();

for (const ps of files) {
  const { file } = ps;

  if (!/^\d+\.\d+ Exercises$/.test(ps.title)) {
    err(`${file}: title "${ps.title}" should look like "N.N Exercises"`);
  }
  if (ps.title !== `${ps.section} Exercises`) {
    err(`${file}: title "${ps.title}" does not match section "${ps.section}"`);
  }
  if (seenTitles.has(ps.title)) err(`${file}: duplicate title "${ps.title}"`);
  seenTitles.add(ps.title);

  if (!ps.body.trim()) err(`${file}: empty problems body`);
  if (!ps.solution.trim()) err(`${file}: empty solutions`);

  const { core, extra } = sumPointTags(ps.body);
  if (core !== ps.points) {
    err(`${file}: core point tags sum to ${core} but frontmatter points=${ps.points}`);
  }
  if (extra !== ps.extraCreditPoints) {
    err(`${file}: extra-credit tags sum to ${extra} but frontmatter extraCreditPoints=${ps.extraCreditPoints}`);
  }

  const lower = (ps.body + "\n" + ps.solution).toLowerCase();
  if (lower.includes("donald")) err(`${file}: mentions instructor name`);
  if (/\\arctan\b/.test(ps.body + ps.solution)) err(`${file}: use \\tan^{-1} not \\arctan`);

  for (const tex of katexErrors(ps.body)) err(`${file}: KaTeX error in problems — ${tex.slice(0, 140)}`);
  for (const tex of katexErrors(ps.solution)) err(`${file}: KaTeX error in solutions — ${tex.slice(0, 140)}`);
}

console.log(`\n${files.length} file(s) checked. errors=${errors}`);
process.exit(errors > 0 ? 1 : 0);
