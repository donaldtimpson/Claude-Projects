import { PrismaClient } from "@prisma/client";
import { readFileSync } from "node:fs";
import { join } from "node:path";

// Imports the E&M practice + real midterm (scripts/physics-midterm/*.md) as two
// ProblemSet rows on the University Physics II course. Mirrors the draft-gate
// convention of import-problem-sets.ts.
//
//   npx tsx scripts/import-physics-midterm.ts [--dry-run] [--update]
//
// - Practice Midterm: Published + solutions public — behaves like a normal
//   problem set (students study it with the worked key).
// - Real Midterm: Draft + solutions withheld — editable/printable in admin;
//   publish it and flip "solutions public" after you administer it.
//
// Idempotent: a row whose title already exists is skipped unless --update is
// passed (which overwrites body/solution/points/flags, preserving createdAt so
// the list order is stable). Rows are slotted just after the Chapter 28 set.

const prisma = new PrismaClient();
const COURSE_ID = "cmp4n6v650004h3uxd68xbvp8"; // University Physics II — E&M
const DIR = join(process.cwd(), "scripts", "physics-midterm");
const DELIM = "<!-- SOLUTIONS -->";

type Cfg = {
  file: string;
  title: string;
  isDraft: boolean;
  solutionsPublic: boolean;
  order: number; // fractional position within the ch28→ch29 gap
};

const CONFIGS: Cfg[] = [
  {
    file: "practice-midterm.md",
    title: "Practice Midterm — Chapters 21–28",
    isDraft: false,
    solutionsPublic: true,
    order: 0.33,
  },
  {
    file: "midterm.md",
    title: "Midterm — Chapters 21–28",
    isDraft: true,
    solutionsPublic: false,
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

  // Slot the midterms just after the Chapter 28 set (before Chapter 29).
  const sets = await prisma.problemSet.findMany({
    where: { courseId: COURSE_ID },
    orderBy: { createdAt: "asc" },
    select: { title: true, createdAt: true },
  });
  const ch28 = sets.find((s) => s.title.startsWith("Chapter 28"));
  const ch29 = sets.find((s) => s.title.startsWith("Chapter 29"));
  const base = ch28 ? ch28.createdAt.getTime() : Date.now();
  // Keep the slot strictly between Ch28 and Ch29 (the sets are only ~ms apart,
  // so do NOT floor the gap — a floor would overshoot past later chapters).
  const next = ch29 && ch29.createdAt.getTime() > base ? ch29.createdAt.getTime() : base + 120_000;
  const gap = next - base;

  for (const cfg of CONFIGS) {
    const { body, solution } = parse(cfg.file);
    const createdAt = new Date(base + gap * cfg.order);
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
