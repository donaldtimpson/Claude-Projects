import { PrismaClient } from "@prisma/client";
import { readFileSync } from "node:fs";
import { join } from "node:path";

// Imports the Linear Algebra unit tests (scripts/linear-algebra-tests/*.md) as
// ProblemSet rows on the Linear Algebra course. Same shape as
// import-physics-midterm.ts.
//
//   npx tsx scripts/import-linear-algebra-tests.ts [--dry-run] [--update]
//
// - Practice Test: Published + solutions public — behaves like a normal
//   problem set (students study it with the worked key).
// - Real Test: Draft + solutions withheld — editable/printable in admin;
//   publish it and flip "solutions public" after you administer it.
//
// Idempotent: a row whose title already exists is skipped unless --update is
// passed (which overwrites body/solution/points/flags, preserving createdAt so
// the list order is stable). Each test is slotted just after the last section
// set it covers (Test 1 → after 1.10, before 2.1).

const prisma = new PrismaClient();
const COURSE_ID = "cmr6plbkh0000jg044yr526qd"; // Linear Algebra (Lay 5e)
const DIR = join(process.cwd(), "scripts", "linear-algebra-tests");
const DELIM = "<!-- SOLUTIONS -->";

type Cfg = {
  file: string;
  title: string;
  isDraft: boolean;
  solutionsPublic: boolean;
  after: string; // title of the problem set this test follows
  before: string; // title of the problem set this test precedes
  order: number; // fractional position within the after→before gap
};

const CONFIGS: Cfg[] = [
  {
    file: "practice-test-1.md",
    title: "Practice Test 1 — Chapter 1",
    isDraft: false,
    solutionsPublic: true,
    after: "1.10 Exercises",
    before: "2.1 Exercises",
    order: 0.33,
  },
  {
    file: "test-1.md",
    title: "Test 1 — Chapter 1",
    isDraft: true,
    solutionsPublic: false,
    after: "1.10 Exercises",
    before: "2.1 Exercises",
    order: 0.66,
  },
];

function parse(file: string): { body: string; solution: string } {
  const raw = readFileSync(join(DIR, file), "utf8");
  const i = raw.indexOf(DELIM);
  if (i === -1) throw new Error(`${file}: missing ${DELIM} delimiter`);
  return { body: raw.slice(0, i).trim(), solution: raw.slice(i + DELIM.length).trim() };
}

async function main() {
  const dryRun = process.argv.includes("--dry-run");
  const update = process.argv.includes("--update");

  const course = await prisma.course.findUnique({
    where: { id: COURSE_ID },
    select: { id: true, title: true },
  });
  if (!course) throw new Error(`No Course with id ${COURSE_ID}`);
  console.log(`Course: ${course.title}${dryRun ? "  (dry run)" : ""}`);

  const sets = await prisma.problemSet.findMany({
    where: { courseId: COURSE_ID },
    orderBy: { createdAt: "asc" },
    select: { title: true, createdAt: true },
  });

  for (const cfg of CONFIGS) {
    const { body, solution } = parse(cfg.file);
    // Keep the slot strictly between the two sets (they may be only ~ms apart,
    // so do NOT floor the gap — a floor would overshoot past later sets).
    const after = sets.find((s) => s.title === cfg.after);
    const before = sets.find((s) => s.title === cfg.before);
    if (!after) throw new Error(`${cfg.file}: no problem set titled "${cfg.after}"`);
    const base = after.createdAt.getTime();
    const next = before && before.createdAt.getTime() > base ? before.createdAt.getTime() : base + 120_000;
    const createdAt = new Date(base + (next - base) * cfg.order);
    const data = {
      body,
      solution,
      points: 100,
      extraCreditPoints: 5,
      isDraft: cfg.isDraft,
      solutionsPublic: cfg.solutionsPublic,
    };

    const existing = await prisma.problemSet.findFirst({
      where: { courseId: COURSE_ID, title: cfg.title },
      select: { id: true },
    });

    if (existing) {
      if (!update) {
        console.log(`  • ${cfg.title}: already exists — skipping (pass --update to overwrite)`);
        continue;
      }
      console.log(`  ↻ ${cfg.title}: ${dryRun ? "would update" : "updating"} (draft=${cfg.isDraft}, solutionsPublic=${cfg.solutionsPublic})`);
      if (!dryRun) await prisma.problemSet.update({ where: { id: existing.id }, data });
      continue;
    }

    console.log(`  + ${cfg.title}: ${dryRun ? "would create" : "creating"} (draft=${cfg.isDraft}, solutionsPublic=${cfg.solutionsPublic}, createdAt=${createdAt.toISOString()})`);
    if (!dryRun) {
      await prisma.problemSet.create({
        data: { courseId: COURSE_ID, title: cfg.title, createdAt, ...data },
      });
    }
  }
  console.log("Done.");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
