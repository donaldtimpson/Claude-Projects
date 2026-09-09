import { PrismaClient } from "@prisma/client";
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join } from "node:path";

// Loads scripts/syllabi/{courseId}.md into Course.syllabus for each file.
// One Markdown file per course, named by the Prisma Course id. Idempotent —
// re-running just overwrites the field. Mirrors push-course-descriptions in
// spirit (hand-authored source committed to the repo).
//
//   npx tsx scripts/import-syllabi.ts [--dry-run] [--course <courseId>]
//
const prisma = new PrismaClient();
const DIR = join(process.cwd(), "scripts", "syllabi");

function getArg(flag: string): string | undefined {
  const i = process.argv.indexOf(flag);
  return i !== -1 ? process.argv[i + 1] : undefined;
}

async function main() {
  if (!existsSync(DIR)) {
    console.error(`No syllabi directory at ${DIR}`);
    process.exit(1);
  }
  const dryRun = process.argv.includes("--dry-run");
  const only = getArg("--course");

  const files = readdirSync(DIR)
    .filter((f) => f.endsWith(".md"))
    .filter((f) => !only || f === `${only}.md`);
  if (files.length === 0) {
    console.error("No matching .md files in scripts/syllabi/");
    process.exit(1);
  }

  for (const file of files) {
    const courseId = file.replace(/\.md$/, "");
    const course = await prisma.course.findUnique({
      where: { id: courseId },
      select: { id: true, title: true },
    });
    if (!course) {
      console.log(`  ✗ ${file}: no Course with id ${courseId} — skipping`);
      continue;
    }
    const syllabus = readFileSync(join(DIR, file), "utf8").trim();
    console.log(`  ${dryRun ? "would set" : "setting"} syllabus for ${course.title} (${syllabus.length} chars)`);
    if (!dryRun) {
      await prisma.course.update({ where: { id: courseId }, data: { syllabus } });
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
