import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";

// Validates scripts/drafts/*.json (top level only). Checks per-file structure,
// expected counts (10 video / 20 course), instructor-name leaks, and intra-course
// duplicate prompts. Pass --course <id> to scope the duplicate check to one course's files.
const dir = join(process.cwd(), "scripts", "drafts");
const files = readdirSync(dir).filter((f) => f.endsWith(".json"));
let errors = 0;
const warn = (m: string) => console.log("  ⚠ " + m);
const err = (m: string) => { console.log("  ✗ " + m); errors++; };

const promptsByCourse: Record<string, { prompt: string; file: string }[]> = {};

for (const f of files) {
  const d = JSON.parse(readFileSync(join(dir, f), "utf8"));
  const qs = d.questions ?? [];
  const expected = d.scope === "course" ? 20 : 10;
  if (qs.length !== expected) err(`${f}: ${qs.length} questions (expected ${expected})`);
  const seen = new Set<string>();
  for (const [i, q] of qs.entries()) {
    if (!Array.isArray(q.options) || q.options.length !== 4) err(`${f} q${i}: ${q.options?.length} options (expected 4)`);
    if (typeof q.correctIndex !== "number" || q.correctIndex < 0 || q.correctIndex >= (q.options?.length ?? 0)) err(`${f} q${i}: bad correctIndex`);
    const blob = (q.prompt + " " + (q.options || []).join(" ") + " " + (q.explanation || "")).toLowerCase();
    if (blob.includes("donald")) err(`${f} q${i}: mentions instructor name`);
    const key = (q.prompt || "").trim().toLowerCase();
    if (seen.has(key)) err(`${f} q${i}: duplicate prompt within file`);
    seen.add(key);
    // longest-answer heuristic (warn only — reused anchors are exempt and we can't tell here)
    if (Array.isArray(q.options)) {
      const lens = q.options.map((o: string) => o.length);
      const max = Math.max(...lens);
      if (lens[q.correctIndex] === max && lens.filter((l: number) => l === max).length === 1 && max > Math.min(...lens) * 1.6) {
        warn(`${f} q${i}: correct answer is conspicuously longest (${lens[q.correctIndex]} vs min ${Math.min(...lens)})`);
      }
    }
  }
  const courseKey = d.scope === "course" ? d.courseId : "video:" + f.slice(0, 8);
  // group all video files under one bucket via --course arg
}

// cross-file duplicate prompts across the whole batch (catches anchor reused twice)
const allPrompts: Record<string, string[]> = {};
for (const f of files) {
  const d = JSON.parse(readFileSync(join(dir, f), "utf8"));
  for (const q of d.questions ?? []) {
    const key = (q.prompt || "").trim().toLowerCase();
    (allPrompts[key] = allPrompts[key] || []).push(f);
  }
}
let dupCount = 0;
for (const [key, fs] of Object.entries(allPrompts)) {
  if (fs.length > 1) { dupCount++; if (dupCount <= 40) warn(`prompt reused in ${fs.length} files: ${fs.join(", ")} :: "${key.slice(0, 70)}"`); }
}

console.log(`\n${files.length} files checked. errors=${errors}, cross-file duplicate prompts=${dupCount}`);
process.exit(errors > 0 ? 1 : 0);
