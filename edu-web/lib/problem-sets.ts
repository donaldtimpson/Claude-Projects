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

export type Chunk =
  | { kind: "item"; key: string; n: number; content: string }
  | { kind: "section"; key: string; content: string };

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
  let current: { chunk: ChunkMeta; lines: string[] } | null = null;

  const flush = () => {
    if (!current) return;
    chunks.push({ ...current.chunk, content: current.lines.join("\n").trim() });
    current = null;
  };

  for (const line of md.split("\n")) {
    const item = ITEM_RE.exec(line);
    if (item) {
      flush();
      const n = Number(item[1]);
      current = { chunk: { kind: "item", key: `item:${n}`, n }, lines: [line] };
      continue;
    }
    // Headings before the first item are part of the preamble, not a section.
    if (HEADING_RE.test(line) && (current || chunks.length > 0)) {
      flush();
      current = { chunk: { kind: "section", key: `section:${headingKey(line)}` }, lines: [line] };
      continue;
    }
    if (current) current.lines.push(line);
    else preambleLines.push(line);
  }
  flush();

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
