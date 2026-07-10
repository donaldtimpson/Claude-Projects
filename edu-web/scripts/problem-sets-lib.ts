import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";

// Shared parsing for the per-section problem-set files in scripts/problem-sets/.
// Each file is Markdown with a YAML-ish frontmatter block and a `<!-- SOLUTIONS -->`
// delimiter splitting the public problems (body) from the instructor solutions.
// See scripts/problem-sets-style.md for the format.

export const PROBLEM_SETS_DIR = join(process.cwd(), "scripts", "problem-sets");
export const SOLUTION_DELIMITER = "<!-- SOLUTIONS -->";

export type ProblemSetFile = {
  file: string;
  section: string;
  title: string;
  points: number;
  extraCreditPoints: number;
  attachmentUrl: string | null;
  body: string;
  solution: string;
};

// Minimal frontmatter parser (no gray-matter dependency in this repo). Supports
// `key: value` lines with optionally quoted string values and integer numbers.
function parseFrontmatter(raw: string, file: string): { fm: Record<string, string>; rest: string } {
  if (!raw.startsWith("---")) throw new Error(`${file}: missing frontmatter (must start with ---)`);
  const end = raw.indexOf("\n---", 3);
  if (end === -1) throw new Error(`${file}: unterminated frontmatter (no closing ---)`);
  const block = raw.slice(3, end).trim();
  const rest = raw.slice(raw.indexOf("\n", end + 1) + 1);
  const fm: Record<string, string> = {};
  for (const line of block.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const colon = trimmed.indexOf(":");
    if (colon === -1) throw new Error(`${file}: bad frontmatter line "${trimmed}"`);
    const key = trimmed.slice(0, colon).trim();
    let value = trimmed.slice(colon + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    fm[key] = value;
  }
  return { fm, rest };
}

export function parseProblemSetFile(file: string): ProblemSetFile {
  const raw = readFileSync(join(PROBLEM_SETS_DIR, file), "utf8");
  const { fm, rest } = parseFrontmatter(raw, file);

  const section = fm.section ?? "";
  const title = fm.title ?? "";
  if (!section) throw new Error(`${file}: frontmatter missing "section"`);
  if (!title) throw new Error(`${file}: frontmatter missing "title"`);

  const points = Number.parseInt(fm.points ?? "", 10);
  const extraCreditPoints = Number.parseInt(fm.extraCreditPoints ?? "0", 10);
  if (!Number.isFinite(points)) throw new Error(`${file}: frontmatter "points" must be an integer`);

  const idx = rest.indexOf(SOLUTION_DELIMITER);
  if (idx === -1) throw new Error(`${file}: missing "${SOLUTION_DELIMITER}" delimiter`);
  const body = rest.slice(0, idx).trim();
  const solution = rest.slice(idx + SOLUTION_DELIMITER.length).trim();

  return {
    file,
    section,
    title,
    points,
    extraCreditPoints: Number.isFinite(extraCreditPoints) ? extraCreditPoints : 0,
    attachmentUrl: fm.attachmentUrl ? fm.attachmentUrl : null,
    body,
    solution,
  };
}

// Natural sort by "chapter.section" so 1.10 follows 1.9 (not 1.1), and chapters
// stay in order. Drives createdAt ordering at import time → the course page list
// and the prev/next nav walk 1.1 → 8.6.
export function sectionSortKey(section: string): [number, number] {
  const [ch, sec] = section.split(".");
  return [Number.parseInt(ch, 10) || 0, Number.parseInt(sec, 10) || 0];
}

export function listProblemSetFiles(): ProblemSetFile[] {
  const files = readdirSync(PROBLEM_SETS_DIR).filter((f) => f.endsWith(".md"));
  const parsed = files.map(parseProblemSetFile);
  parsed.sort((a, b) => {
    const ka = sectionSortKey(a.section);
    const kb = sectionSortKey(b.section);
    return ka[0] - kb[0] || ka[1] - kb[1];
  });
  return parsed;
}
