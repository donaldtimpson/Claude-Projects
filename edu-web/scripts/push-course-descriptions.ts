import { PrismaClient } from "@prisma/client";
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import {
  getPlaylistSnippet,
  updatePlaylistDescription,
  MAX_DESCRIPTION_LENGTH,
} from "../lib/youtube-oauth";

// Push hand-written course descriptions into the YouTube PLAYLIST descriptions,
// which is the only durable place to keep them: app/api/youtube/sync overwrites
// Course.description from the playlist on every run, so editing the DB directly
// would be silently undone the next time Donald hits Sync.
//
// Source of truth is scripts/course-descriptions/{youtubePlaylistId}.txt — one
// file per course, committed (unlike the derived chapters/transcripts caches).
// A playlist with no file is left alone.
//
// Usage:
//   npx tsx scripts/push-course-descriptions.ts --dry-run     # always first
//   npx tsx scripts/push-course-descriptions.ts
//   npx tsx scripts/push-course-descriptions.ts --playlist <id> [--dry-run]
//
// Afterwards, re-sync so the DB picks the new text up (admin dashboard's Sync
// button, or POST /api/youtube/sync).

const prisma = new PrismaClient();
const dir = join(process.cwd(), "scripts", "course-descriptions");

async function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes("--dry-run");
  const flagIdx = args.indexOf("--playlist");
  const only = flagIdx !== -1 ? args[flagIdx + 1] : undefined;

  let ids = readdirSync(dir)
    .filter((f) => f.endsWith(".txt"))
    .map((f) => f.replace(/\.txt$/, ""));
  if (only) {
    if (!ids.includes(only)) {
      console.error(`No scripts/course-descriptions/${only}.txt`);
      process.exit(1);
    }
    ids = [only];
  }
  if (ids.length === 0) {
    console.error("No description files in scripts/course-descriptions/.");
    process.exit(1);
  }

  console.log(
    `${dryRun ? "DRY RUN — nothing will be written" : "Writing to YouTube"}: ${ids.length} playlist(s)\n`,
  );

  let changed = 0;
  let skipped = 0;
  let failed = 0;

  for (const playlistId of ids) {
    const course = await prisma.course.findUnique({
      where: { youtubePlaylistId: playlistId },
      select: { title: true },
    });
    const label = course?.title ?? playlistId;

    // Trailing newline from the file would otherwise count as a diff forever.
    const next = readFileSync(join(dir, `${playlistId}.txt`), "utf8").trim();
    if (next.length > MAX_DESCRIPTION_LENGTH) {
      console.log(`✗ ${label}: ${next.length} chars exceeds YouTube's ${MAX_DESCRIPTION_LENGTH}`);
      failed++;
      continue;
    }

    try {
      const snippet = await getPlaylistSnippet(playlistId);
      const current = snippet.description.trim();

      if (current === next) {
        console.log(`· ${label}: already up to date`);
        skipped++;
        continue;
      }

      console.log(`${dryRun ? "→" : "✓"} ${label}`);
      console.log(`    ${current.length} chars -> ${next.length}`);
      if (dryRun) {
        console.log(
          next
            .split("\n")
            .map((l) => `    | ${l}`)
            .join("\n"),
        );
      } else {
        await updatePlaylistDescription(playlistId, next);
      }
      changed++;
    } catch (err) {
      console.log(`✗ ${label}: ${err instanceof Error ? err.message : err}`);
      failed++;
    }
  }

  console.log(
    `\n${dryRun ? "Would change" : "Changed"} ${changed}, unchanged ${skipped}, failed ${failed}`,
  );
  if (!dryRun && changed > 0) {
    console.log("Now re-sync so Course.description picks this up (admin -> Sync YouTube).");
  }
  if (failed > 0) process.exit(1);
}

main()
  .catch((e) => {
    console.error(e instanceof Error ? e.message : e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
