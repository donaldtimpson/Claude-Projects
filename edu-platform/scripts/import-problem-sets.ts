import { PrismaClient } from "@prisma/client";
import { existsSync } from "node:fs";
import { PROBLEM_SETS_DIR, listProblemSetFiles } from "./problem-sets-lib";

// Imports scripts/problem-sets/{section}.md as draft ProblemSets (isDraft: true)
// for one course. Mirrors import-drafts.ts / import-notes.ts. Files are created
// in section order (1.1 → 8.6) so createdAt ascends to match the course page list
// and the problem-set prev/next nav. Idempotent: skips a section whose title
// already exists for the course.
//
//   npx tsx scripts/import-problem-sets.ts --course <courseId> [--dry-run]
//
// Pass --update to also overwrite the body/solution/points of problem sets that
// already exist (matched by title) — used to sync corrected drafts back to the DB
// in place, preserving each row's createdAt (and therefore the 1.1 → 8.6 order).
// Without --update, existing sets are skipped (safe first-import default).
//
const prisma = new PrismaClient();

function getArg(flag: string): string | undefined {
  const i = process.argv.indexOf(flag);
  return i !== -1 ? process.argv[i + 1] : undefined;
}

async function main() {
  if (!existsSync(PROBLEM_SETS_DIR)) {
    console.error(`No problem-sets directory found at ${PROBLEM_SETS_DIR}`);
    process.exit(1);
  }

  const dryRun = process.argv.includes("--dry-run");
  const update = process.argv.includes("--update");
  const courseId = getArg("--course");
  if (!courseId) {
    console.error("Missing --course <courseId>. (Pass the Linear Algebra course id.)");
    process.exit(1);
  }

  // Validate the course exists (and isn't a typo) before touching anything.
  const course = await prisma.course.findUnique({
    where: { id: courseId },
    select: { id: true, title: true },
  });
  if (!course) {
    console.error(`No Course with id ${courseId}`);
    process.exit(1);
  }

  const files = listProblemSetFiles();
  if (files.length === 0) {
    console.error(`No .md problem-set files found in ${PROBLEM_SETS_DIR}`);
    process.exit(1);
  }

  console.log(
    `Course: ${course.title} (${course.id})\nFound ${files.length} problem-set file(s).${dryRun ? " (dry run)" : ""}`,
  );

  let inserted = 0;
  let updated = 0;
  let skipped = 0;

  // Sequential create() (not createMany) so createdAt increments in section order.
  for (const ps of files) {
    const existing = await prisma.problemSet.findFirst({
      where: { courseId, title: ps.title },
      select: { id: true },
    });
    if (existing) {
      if (!update) {
        console.log(`  • ${ps.title}: already exists — skipping`);
        skipped++;
        continue;
      }
      if (dryRun) {
        console.log(`  ↻ ${ps.title}: would update existing draft`);
        updated++;
        continue;
      }
      // Update content in place — preserves createdAt (and the 1.1 → 8.6 order).
      // Does NOT touch isDraft, so an already-published set stays published.
      await prisma.problemSet.update({
        where: { id: existing.id },
        data: {
          body: ps.body,
          solution: ps.solution,
          points: ps.points,
          extraCreditPoints: ps.extraCreditPoints,
          attachmentUrl: ps.attachmentUrl,
        },
      });
      console.log(`  ↻ ${ps.title}: updated`);
      updated++;
      continue;
    }

    if (dryRun) {
      console.log(
        `  ✓ ${ps.title}: would insert draft (${ps.points} pts` +
          `${ps.extraCreditPoints ? ` +${ps.extraCreditPoints} ec` : ""}, ` +
          `${ps.body.length} body chars, ${ps.solution.length} solution chars)`,
      );
      inserted++;
      continue;
    }

    await prisma.problemSet.create({
      data: {
        courseId,
        title: ps.title,
        body: ps.body,
        solution: ps.solution,
        points: ps.points,
        extraCreditPoints: ps.extraCreditPoints,
        attachmentUrl: ps.attachmentUrl,
        isDraft: true,
      },
    });
    console.log(`  ✓ ${ps.title}: inserted draft`);
    inserted++;
  }

  console.log(`\nDone. inserted=${inserted} updated=${updated} skipped=${skipped}`);
  await prisma.$disconnect();
}

main().catch(async (e) => {
  console.error(e);
  await prisma.$disconnect();
  process.exit(1);
});
