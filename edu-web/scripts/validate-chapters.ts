import { PrismaClient } from "@prisma/client";
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join } from "node:path";
import { parseChapters, validateChapters } from "../lib/chapters";

// Pre-push validation for scripts/chapters/{youtubeVideoId}.txt. Enforces
// YouTube's clickable-chapter rules (starts at 0:00, ≥3 chapters, ascending,
// ≥10s each) and bounds the last chapter against the video's real duration
// (from the Video row). Mirrors validate-notes.ts's exit-code pattern.

const prisma = new PrismaClient();
const dir = join(process.cwd(), "scripts", "chapters");

async function main() {
  if (!existsSync(dir)) {
    console.error(`No chapters directory found at ${dir}`);
    process.exit(1);
  }

  const files = readdirSync(dir).filter((f) => f.endsWith(".txt"));
  const durations = new Map<string, number>();
  const rows = await prisma.video.findMany({ select: { youtubeVideoId: true, durationSeconds: true } });
  for (const r of rows) durations.set(r.youtubeVideoId, r.durationSeconds ?? 0);

  let errors = 0;
  for (const f of files) {
    const youtubeVideoId = f.replace(/\.txt$/, "");
    const { chapters, badLines } = parseChapters(readFileSync(join(dir, f), "utf8"));
    const duration = durations.get(youtubeVideoId);
    if (duration === undefined) {
      console.log(`  ✗ ${f}: no Video row for "${youtubeVideoId}" (wrong filename?)`);
      errors++;
      continue;
    }
    const problems = validateChapters(chapters, badLines, duration);
    for (const p of problems) {
      console.log(`  ✗ ${f}: ${p}`);
      errors++;
    }
  }

  console.log(`\n${files.length} file(s) checked. errors=${errors}`);
  await prisma.$disconnect();
  process.exit(errors > 0 ? 1 : 0);
}

main().catch(async (e) => {
  console.error(e);
  await prisma.$disconnect();
  process.exit(1);
});
