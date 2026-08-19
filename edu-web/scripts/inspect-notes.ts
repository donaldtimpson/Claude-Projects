import { PrismaClient } from "@prisma/client";
import katex from "katex";

const db = new PrismaClient();

// Count un-escaped $ characters in a markdown body, ignoring those inside $$...$$
// display blocks (a delimiter pair starts/ends a math block; we count those
// separately). Anything odd indicates an unclosed inline math span.
function countDollars(md: string): { display: number; inline: number; inlineOdd: boolean } {
  // First strip $$..$$ blocks
  const displayBlocks = md.match(/\$\$[\s\S]+?\$\$/g) ?? [];
  const stripped = md.replace(/\$\$[\s\S]+?\$\$/g, "");
  // Count unescaped single $ (not preceded by backslash) in the stripped text.
  const single = (stripped.match(/(?<!\\)\$/g) ?? []).length;
  return { display: displayBlocks.length, inline: single, inlineOdd: single % 2 !== 0 };
}

// Extract every $$...$$ block and $...$ span from a markdown chunk and try to
// render each one through KaTeX. Returns the failures.
function findKatexErrors(md: string): { snippet: string; error: string }[] {
  const out: { snippet: string; error: string }[] = [];

  // Display math: $$...$$  (non-greedy, multiline)
  const displayRe = /\$\$([\s\S]+?)\$\$/g;
  let m: RegExpExecArray | null;
  while ((m = displayRe.exec(md))) {
    try {
      katex.renderToString(m[1], { displayMode: true, throwOnError: true, strict: false });
    } catch (e) {
      out.push({ snippet: "$$" + m[1].slice(0, 200) + (m[1].length > 200 ? "..." : "") + "$$", error: (e as Error).message });
    }
  }

  // Inline math: $...$  (single $, no $$, no newlines)
  // Strip display blocks first so we don't re-scan them.
  const noDisplay = md.replace(displayRe, "");
  const inlineRe = /(?<!\$)\$([^$\n]+?)\$(?!\$)/g;
  while ((m = inlineRe.exec(noDisplay))) {
    try {
      katex.renderToString(m[1], { displayMode: false, throwOnError: true, strict: false });
    } catch (e) {
      out.push({ snippet: "$" + m[1] + "$", error: (e as Error).message });
    }
  }

  return out;
}

// Fetch a few published lecture notes and grep for Worked Example LaTeX patterns
// that commonly trip KaTeX (\begin{align*}, \\ at top level, unicode chars, etc).

async function main() {
  const notes = await db.lectureNote.findMany({
    where: { isDraft: false },
    include: { video: { include: { course: { select: { title: true } } } } },
  });

  console.log(`Total published notes scanned: ${notes.length}`);

  const samples: { course: string; videoTitle: string; example: string }[] = [];

  for (const n of notes) {
    const startIdx = n.content.indexOf("## Worked Example");
    if (startIdx === -1) continue;
    const rest = n.content.slice(startIdx);
    const endIdx = rest.indexOf("\n## ", 5);
    const example = endIdx === -1 ? rest : rest.slice(0, endIdx);
    samples.push({
      course: n.video.course.title,
      videoTitle: n.video.title,
      example,
    });
  }

  // Run each Worked Example through KaTeX and collect failures.
  const errorTally = new Map<string, { count: number; sample: string; example?: string }>();
  let notesWithErrors = 0;
  const failures: { course: string; videoTitle: string; errors: { snippet: string; error: string }[] }[] = [];

  for (const s of samples) {
    const errs = findKatexErrors(s.example);
    if (errs.length === 0) continue;
    notesWithErrors++;
    failures.push({ course: s.course, videoTitle: s.videoTitle, errors: errs });
    for (const e of errs) {
      const key = e.error.split("\n")[0].replace(/at position \d+/, "at position <N>");
      const prev = errorTally.get(key);
      if (prev) prev.count++;
      else errorTally.set(key, { count: 1, sample: e.snippet, example: `${s.course} → ${s.videoTitle}` });
    }
  }

  console.log(`\nNotes with KaTeX errors: ${notesWithErrors} / ${samples.length}`);
  console.log("\n========= Error frequency =========");
  for (const [msg, info] of [...errorTally.entries()].sort((a, b) => b[1].count - a[1].count)) {
    console.log(`\n[${info.count}x] ${msg}`);
    console.log(`  e.g.   ${info.example}`);
    console.log(`  snip:  ${info.sample.slice(0, 200)}`);
  }

  // Dump first 3 failing examples in full.
  console.log("\n========= First 3 failing notes (full Worked Example) =========");
  for (const f of failures.slice(0, 3)) {
    console.log(`\n--- ${f.course} / ${f.videoTitle}`);
    for (const e of f.errors) {
      console.log(`  x ${e.error.split("\n")[0]}`);
      console.log(`    snippet: ${e.snippet.slice(0, 300)}`);
    }
  }

  // Now scan FULL note content (not just Worked Example) for odd-$-count issues
  console.log("\n========= Whole-note dollar-sign parity check =========");
  let oddCount = 0;
  for (const n of notes) {
    const c = countDollars(n.content);
    if (c.inlineOdd) {
      oddCount++;
      if (oddCount <= 5) {
        console.log(`  ${n.video.course.title} / ${n.video.title}`);
        console.log(`    display blocks: ${c.display}, inline $: ${c.inline} (odd)`);
      }
    }
  }
  console.log(`\nNotes with odd inline-$ count: ${oddCount} / ${notes.length}`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => db.$disconnect());
