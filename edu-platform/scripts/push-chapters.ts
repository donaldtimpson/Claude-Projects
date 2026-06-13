import { PrismaClient } from "@prisma/client";
import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { parseChapters, validateChapters, mergeDescription, CHAPTER_HEADER } from "../lib/chapters";
import { getVideoSnippet, updateVideoDescription, MAX_DESCRIPTION_LENGTH } from "../lib/youtube-oauth";

// Push generated chapters into YouTube video descriptions. Reads
// scripts/chapters/{youtubeVideoId}.txt, validates against YouTube's rules,
// merges a managed chapters block into the LIVE description (replacing an
// existing block in place — non-destructive to the rest), and writes it back via
// the Data API. Always dry-run first.
//
// Usage:
//   npx tsx scripts/push-chapters.ts <courseId> [--dry-run]
//   npx tsx scripts/push-chapters.ts --video <youtubeVideoId> [--dry-run]

const prisma = new PrismaClient();
const dir = join(process.cwd(), "scripts", "chapters");

async function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes("--dry-run");
  const videoFlagIdx = args.indexOf("--video");
  const singleVideoId = videoFlagIdx !== -1 ? args[videoFlagIdx + 1] : undefined;
  const courseId = args.find((a) => !a.startsWith("--") && a !== singleVideoId);

  if (!singleVideoId && !courseId) {
    console.error(
      "Specify a target: `<courseId>` or `--video <youtubeVideoId>`. Add --dry-run to preview.",
    );
    process.exit(1);
  }

  // Resolve target videos (must have a chapters file).
  const targets: { youtubeVideoId: string; title: string; durationSeconds: number }[] = [];
  if (singleVideoId) {
    const v = await prisma.video.findUnique({
      where: { youtubeVideoId: singleVideoId },
      select: { youtubeVideoId: true, title: true, durationSeconds: true },
    });
    if (!v) {
      console.error(`No Video row for youtubeVideoId "${singleVideoId}".`);
      process.exit(1);
    }
    targets.push({ ...v, durationSeconds: v.durationSeconds ?? 0 });
  } else {
    const vids = await prisma.video.findMany({
      where: { courseId },
      select: { youtubeVideoId: true, title: true, durationSeconds: true },
    });
    for (const v of vids) {
      if (existsSync(join(dir, `${v.youtubeVideoId}.txt`))) {
        targets.push({ ...v, durationSeconds: v.durationSeconds ?? 0 });
      }
    }
  }

  if (targets.length === 0) {
    console.error("No target videos with a scripts/chapters/*.txt file found.");
    process.exit(1);
  }

  console.log(`${dryRun ? "DRY RUN — " : ""}processing ${targets.length} video(s)\n`);
  let pushed = 0;
  let failed = 0;

  for (const t of targets) {
    const file = join(dir, `${t.youtubeVideoId}.txt`);
    if (!existsSync(file)) {
      console.log(`— skip ${t.title}: no chapters file`);
      continue;
    }
    const { chapters, badLines } = parseChapters(readFileSync(file, "utf8"));
    const problems = validateChapters(chapters, badLines, t.durationSeconds);
    if (problems.length) {
      console.log(`✗ ${t.title} (${t.youtubeVideoId}) — invalid, skipping:`);
      for (const p of problems) console.log(`    ${p}`);
      failed++;
      continue;
    }

    let existing: string;
    try {
      existing = (await getVideoSnippet(t.youtubeVideoId)).description ?? "";
    } catch (e) {
      console.log(`✗ ${t.title}: ${(e as Error).message}`);
      failed++;
      continue;
    }

    const next = mergeDescription(existing, chapters);
    const replaced = existing.split("\n").some((l) => l.trim() === CHAPTER_HEADER);

    if (next.length > MAX_DESCRIPTION_LENGTH) {
      console.log(
        `✗ ${t.title}: new description is ${next.length} chars (> ${MAX_DESCRIPTION_LENGTH}). Trim chapters.`,
      );
      failed++;
      continue;
    }

    if (dryRun) {
      console.log(`\n══════ ${t.title} (${t.youtubeVideoId}) ══════`);
      console.log(`(${replaced ? "REPLACING existing" : "APPENDING new"} chapters block; ${chapters.length} chapters)\n`);
      console.log("──── proposed description ────");
      console.log(next);
      console.log("──── end ────\n");
    } else {
      try {
        await updateVideoDescription(t.youtubeVideoId, next);
        console.log(`✓ ${t.title} — ${replaced ? "updated" : "added"} ${chapters.length} chapters`);
        pushed++;
      } catch (e) {
        console.log(`✗ ${t.title}: ${(e as Error).message}`);
        failed++;
      }
    }
  }

  if (!dryRun) console.log(`\nDone. pushed=${pushed} failed=${failed}`);
  else if (failed) console.log(`\n${failed} video(s) had validation/fetch errors (see above).`);
  await prisma.$disconnect();
}

main().catch(async (e) => {
  console.error(e);
  await prisma.$disconnect();
  process.exit(1);
});
