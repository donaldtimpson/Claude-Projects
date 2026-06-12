import { PrismaClient } from "@prisma/client";
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join } from "node:path";

// Imports scripts/notes/{videoId}.md as draft LectureNotes (isDraft: true).
// Filename (minus .md) is the Prisma Video.id. Idempotent: skips a file if a
// note already exists for that video. Pass --dry-run to preview.
const prisma = new PrismaClient();

async function main() {
  const notesDir = join(process.cwd(), "scripts", "notes");
  if (!existsSync(notesDir)) {
    console.error(`No notes directory found at ${notesDir}`);
    process.exit(1);
  }

  const files = readdirSync(notesDir).filter((f) => f.endsWith(".md"));
  if (files.length === 0) {
    console.error(`No .md note files found in ${notesDir}`);
    process.exit(1);
  }

  const dryRun = process.argv.includes("--dry-run");
  console.log(`Found ${files.length} note file(s).${dryRun ? " (dry run)" : ""}`);

  let inserted = 0;
  let skipped = 0;

  for (const file of files) {
    const videoId = file.replace(/\.md$/, "");
    const content = readFileSync(join(notesDir, file), "utf8").trim();

    if (!content) {
      console.error(`  ✗ ${file}: empty file`);
      continue;
    }

    const video = await prisma.video.findUnique({ where: { id: videoId }, select: { id: true } });
    if (!video) {
      console.error(`  ✗ ${file}: no Video with id ${videoId}`);
      continue;
    }

    const existing = await prisma.lectureNote.findUnique({ where: { videoId } });
    if (existing) {
      console.log(`  • ${file}: note already exists — skipping`);
      skipped++;
      continue;
    }

    if (dryRun) {
      console.log(`  ✓ ${file}: would insert draft note (${content.length} chars)`);
      inserted++;
      continue;
    }

    await prisma.lectureNote.create({ data: { videoId, content, isDraft: true } });
    console.log(`  ✓ ${file}: inserted draft note (${content.length} chars)`);
    inserted++;
  }

  console.log(`\nDone. inserted=${inserted} skipped=${skipped}`);
  await prisma.$disconnect();
}

main().catch(async (e) => {
  console.error(e);
  await prisma.$disconnect();
  process.exit(1);
});
