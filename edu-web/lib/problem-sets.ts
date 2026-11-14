// Pairing a problem set's problems with its worked solutions.
//
// Both halves are authored as Markdown and split into parts two ways:
//
//   numbered items   **1.** (3 pts) Solve the system…   /  **1. (2 pts ••)** …
//   named sections   ### Extra Credit (3 pts •••)
//
// Solutions repeat the same structure, so each part can be matched to its
// answer — numbered items by their number, named sections by their heading
// (the trailing points tag is ignored, since the body writes
// "### Extra Credit (3 pts •••)" where the solution writes "### Extra Credit").
// That lets the page attach each answer to the thing it answers instead of
// dumping one blob at the bottom.
//
// Authoring is free-form Markdown, so `pairProblemSet` degrades to a single
// appended block whenever the two sides don't line up, rather than dropping
// authored solutions or attaching them to the wrong problem.

/** A bold leading number at the start of a line: `**1.**`, `**1. (2 pts)**`, `**10.` … */
const ITEM_RE = /^\*\*\s*(\d+)\s*\./;
/** A Markdown ATX heading: `### Extra Credit`. */
const HEADING_RE = /^#{1,6}\s+/;

/**
 * Normalize a heading so a body section matches its solution section.
 * Drops the `#` marks, any trailing parenthetical points tag, and emphasis.
 */
function headingKey(line: string): string {
  return line
    .replace(HEADING_RE, "")
    .replace(/\([^)]*\)\s*$/, "")
    .replace(/[*_`]/g, "")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, " ");
}

/**
 * One authored part. `start`/`end` are its source line range (end exclusive,
 * including any trailing blank lines), so an editor can splice a single part
 * back into the full document.
 */
export type Chunk =
  | { kind: "item"; key: string; n: number; content: string; start: number; end: number }
  | { kind: "section"; key: string; content: string; start: number; end: number };

/** A chunk's identity, before its Markdown body has been collected. */
type ChunkMeta =
  | { kind: "item"; key: string; n: number }
  | { kind: "section"; key: string };

export type SplitMarkdown = {
  /** Anything before the first numbered item — title heading, point totals, a lead-in line. */
  preamble: string;
  chunks: Chunk[];
};

/**
 * Split authored Markdown into its preamble and its parts.
 *
 * A heading only starts a new section once a numbered item has been seen —
 * before that it's still the document's own title/lead-in, which belongs to
 * the preamble.
 */
export function splitAuthored(md: string): SplitMarkdown {
  const preambleLines: string[] = [];
  const chunks: Chunk[] = [];
  let current: { chunk: ChunkMeta; lines: string[]; start: number } | null = null;

  const allLines = md.split("\n");
  const flush = (end: number) => {
    if (!current) return;
    chunks.push({
      ...current.chunk,
      content: current.lines.join("\n").trim(),
      start: current.start,
      end,
    });
    current = null;
  };

  for (const [i, line] of allLines.entries()) {
    const item = ITEM_RE.exec(line);
    if (item) {
      flush(i);
      const n = Number(item[1]);
      current = { chunk: { kind: "item", key: `item:${n}`, n }, lines: [line], start: i };
      continue;
    }
    // Headings before the first item are part of the preamble, not a section.
    if (HEADING_RE.test(line) && (current || chunks.length > 0)) {
      flush(i);
      current = {
        chunk: { kind: "section", key: `section:${headingKey(line)}` },
        lines: [line],
        start: i,
      };
      continue;
    }
    if (current) current.lines.push(line);
    else preambleLines.push(line);
  }
  flush(allLines.length);

  return { preamble: preambleLines.join("\n").trim(), chunks };
}

export type PairedPart = {
  /** Stable identity for React keys, anchors, and open/closed state. */
  key: string;
  /** What the reveal button should say, e.g. "3" or "Extra Credit". */
  label: string;
  problem: string;
  /** The matching worked solution, or null when there isn't one. */
  solution: string | null;
};

export type PairedProblemSet =
  | {
      /** Structure lined up: render each solution inline under its own part. */
      mode: "paired";
      problemsPreamble: string;
      /**
       * The solutions document's own lead-in. Parsed for fidelity but NOT
       * rendered anywhere: in practice it's just "## Answer Key — Chapter N",
       * which the reveal buttons already imply.
       */
      solutionPreamble: string;
      parts: PairedPart[];
    }
  | {
      /** Couldn't line up: render the problems whole, solutions as one block. */
      mode: "blocks";
      body: string;
      solution: string | null;
    };

/** Human label for a part's reveal button. */
function labelFor(chunk: Chunk): string {
  if (chunk.kind === "item") return String(chunk.n);
  // "section:extra credit" → "Extra Credit"
  const name = chunk.key.slice("section:".length);
  return name.replace(/\b\w/g, (c) => c.toUpperCase());
}

/**
 * Pair a set's problems with its solutions for rendering.
 *
 * `includeSolutions` false yields the same structure with every solution null,
 * so the page layout doesn't change shape when answers are withheld.
 */
export function pairProblemSet(
  body: string,
  solution: string,
  includeSolutions: boolean
): PairedProblemSet {
  const solutionText = includeSolutions ? solution.trim() : "";
  const problems = splitAuthored(body);

  // Nothing to hang answers off — no parts to interleave.
  if (problems.chunks.length === 0) {
    return { mode: "blocks", body, solution: solutionText || null };
  }

  const toParts = (bySolution: Map<string, string>): PairedPart[] =>
    problems.chunks.map((c) => ({
      key: c.key,
      label: labelFor(c),
      problem: c.content,
      solution: bySolution.get(c.key) ?? null,
    }));

  if (!solutionText) {
    return {
      mode: "paired",
      problemsPreamble: problems.preamble,
      solutionPreamble: "",
      parts: toParts(new Map()),
    };
  }

  const solutions = splitAuthored(solutionText);
  const bySolution = new Map<string, string>();
  for (const chunk of solutions.chunks) {
    // Duplicate keys would make the pairing ambiguous.
    if (bySolution.has(chunk.key)) return { mode: "blocks", body, solution: solutionText };
    bySolution.set(chunk.key, chunk.content);
  }

  // Never silently drop an authored solution: if any solution part has no
  // problem to attach to, show everything as blocks instead. (The reverse — a
  // problem with no solution — is fine; it just gets no reveal button.)
  const problemKeys = new Set(problems.chunks.map((c) => c.key));
  const orphanedSolution = solutions.chunks.some((c) => !problemKeys.has(c.key));
  if (orphanedSolution) return { mode: "blocks", body, solution: solutionText };

  return {
    mode: "paired",
    problemsPreamble: problems.preamble,
    solutionPreamble: solutions.preamble,
    parts: toParts(bySolution),
  };
}

export type ReviewRow = {
  /** Unique per row, even when the authored keys collide. */
  id: string;
  label: string;
  problem: Chunk | null;
  solution: Chunk | null;
  /** A problem or solution number that appears more than once on its side. */
  duplicate: boolean;
};

export type ProblemSetReview = {
  problemsPreamble: string;
  solutionPreamble: string;
  /** Problems in authored order, then any solutions that matched no problem. */
  rows: ReviewRow[];
  /** What students get: false means the public page falls back to blocks. */
  pairsPublicly: boolean;
};

/**
 * The admin's view of how a set's problems and solutions line up. Unlike
 * `pairProblemSet`, which degrades to blocks when anything is off, this keeps
 * every part and flags what doesn't match, so the author can see and fix it.
 */
export function reviewProblemSet(body: string, solution: string): ProblemSetReview {
  const problems = splitAuthored(body);
  const solutions = splitAuthored(solution);

  const count = (cs: Chunk[]) => {
    const m = new Map<string, number>();
    for (const c of cs) m.set(c.key, (m.get(c.key) ?? 0) + 1);
    return m;
  };
  const problemCounts = count(problems.chunks);
  const solutionCounts = count(solutions.chunks);

  // A key's first solution pairs with its first problem, and so on.
  const unused = [...solutions.chunks];
  const takeSolution = (key: string) => {
    const i = unused.findIndex((c) => c.key === key);
    return i < 0 ? null : unused.splice(i, 1)[0];
  };

  const rows: ReviewRow[] = problems.chunks.map((p, i) => ({
    id: `p${i}`,
    label: labelFor(p),
    problem: p,
    solution: takeSolution(p.key),
    duplicate: (problemCounts.get(p.key) ?? 0) > 1 || (solutionCounts.get(p.key) ?? 0) > 1,
  }));
  for (const [i, s] of unused.entries()) {
    rows.push({
      id: `s${i}`,
      label: labelFor(s),
      problem: null,
      solution: s,
      duplicate: (solutionCounts.get(s.key) ?? 0) > 1,
    });
  }

  return {
    problemsPreamble: problems.preamble,
    solutionPreamble: solutions.preamble,
    rows,
    pairsPublicly: pairProblemSet(body, solution, true).mode === "paired",
  };
}

/**
 * Replace one part's source lines with new text, keeping the blank-line
 * spacing that separated it from the next part.
 */
export function replaceChunk(md: string, chunk: Chunk, text: string): string {
  const lines = md.split("\n");
  let trailing = 0;
  while (
    chunk.end - trailing - 1 > chunk.start &&
    lines[chunk.end - trailing - 1].trim() === ""
  ) {
    trailing++;
  }
  const replacement = text.trim() ? text.replace(/\s+$/, "").split("\n") : [];
  if (replacement.length > 0 && chunk.end < lines.length) trailing = Math.max(trailing, 1);
  lines.splice(
    chunk.start,
    chunk.end - chunk.start,
    ...replacement,
    ...Array(replacement.length ? trailing : 0).fill(""),
  );
  return lines.join("\n");
}

/** Insert a new part before `before`, or at the end when `before` is null. */
export function insertChunk(md: string, before: Chunk | null, text: string): string {
  const block = text.replace(/\s+$/, "");
  if (!block) return md;
  if (!before) {
    const head = md.replace(/\s+$/, "");
    return head ? `${head}\n\n${block}\n` : `${block}\n`;
  }
  const lines = md.split("\n");
  lines.splice(before.start, 0, ...block.split("\n"), "");
  return lines.join("\n");
}

/**
 * Estimate how many ruled work lines to leave under a problem on a printed
 * worksheet, from its worked solution (a proxy for how much a student must
 * write). Prose contributes by length; each displayed equation and each matrix
 * needs extra vertical room. Returns a clamped line count so no single problem
 * blows past a page and none is cramped. `null`/empty solution → a sane default.
 */
export function estimateWorkLines(solution: string | null | undefined): number {
  const s = (solution ?? "").trim();
  if (!s) return 5;

  const displayMath = Math.floor((s.match(/\$\$/g)?.length ?? 0) / 2);
  const matrices = s.match(/\\begin\{(?:bmatrix|pmatrix|vmatrix|array)\}/g)?.length ?? 0;
  const alignments = s.match(/\\begin\{(?:aligned|align|cases)\}/g)?.length ?? 0;
  // Prose length with math stripped out (math is counted separately below).
  const prose = s.replace(/\$\$[\s\S]*?\$\$/g, "").replace(/\$[^$]*\$/g, "");

  const lines =
    Math.ceil(prose.length / 55) + // ~55 solution chars per handwritten line
    displayMath * 3 + // each displayed equation ~3 lines of room
    matrices * 2 + // matrices need extra 2-D room
    alignments * 2;

  return Math.max(4, Math.min(lines, 24)); // never cramped, never over ~a page
}

/**
 * Whether a viewer may see a set's worked solutions.
 *
 * `ProblemSet.solutionsPublic` is the single source of truth — a published
 * set's answers ship with its problems unless it's been withheld. There is
 * deliberately no per-class override: two switches meant the admin UI could
 * disagree with what students actually saw.
 */
export function canSeeSolutions(opts: { solutionsPublic: boolean }): boolean {
  return opts.solutionsPublic;
}
