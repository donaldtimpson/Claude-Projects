import { PrismaClient } from "@prisma/client";
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join } from "node:path";

// Imports scripts/transcripts/{youtubeVideoId}.txt into the Transcript model so
// it's searchable at runtime (the files are gitignored and not deployed). Also
// attaches the timed segments from scripts/transcripts-timed/{youtubeVideoId}.json
// when present (used to deep-link a search hit to its moment). Filename (minus
// .txt) is the YouTube video id. Idempotent: upserts, so re-running refreshes
// content. Pass --video <youtubeVideoId> to import just one (the autopilot uses
// this); pass --dry-run to preview.
const prisma = new PrismaClient();

type Segment = { start: number; text: string };

async function main() {
  const dir = join(process.cwd(), "scripts", "transcripts");
  const timedDir = join(process.cwd(), "scripts", "transcripts-timed");
  if (!existsSync(dir)) {
    console.error(`No transcripts directory found at ${dir}`);
    process.exit(1);
  }

  const args = process.argv.slice(2);
  const dryRun = args.includes("--dry-run");
  const vIdx = args.indexOf("--video");
  const single = vIdx !== -1 ? args[vIdx + 1] : undefined; // import just one youtubeVideoId

  let files = readdirSync(dir).filter((f) => f.endsWith(".txt"));
  if (single) files = files.filter((f) => f === `${single}.txt`);
  console.log(`Found ${files.length} transcript file(s).${single ? ` (video ${single})` : ""}${dryRun ? " (dry run)" : ""}`);

  let imported = 0;
  let withSegments = 0;
  let skipped = 0;
  let missingVideo = 0;

  for (const file of files) {
    const youtubeVideoId = file.replace(/\.txt$/, "");
    const content = readFileSync(join(dir, file), "utf8").trim();
    if (!content) {
      skipped++;
      continue;
    }

    const video = await prisma.video.findUnique({
      where: { youtubeVideoId },
      select: { id: true },
    });
    if (!video) {
      missingVideo++;
      continue; // transcript cached for a video not in this DB (e.g. a sibling offering not synced)
    }

    // Attach timed segments when available.
    let segments: Segment[] | undefined;
    const timedPath = join(timedDir, `${youtubeVideoId}.json`);
    if (existsSync(timedPath)) {
      try {
        const parsed = JSON.parse(readFileSync(timedPath, "utf8")) as Segment[];
        if (Array.isArray(parsed) && parsed.length) {
          segments = parsed;
          withSegments++;
        }
      } catch {
        /* ignore malformed timed file; plaintext still imports */
      }
    }

    if (dryRun) {
      console.log(`  ✓ ${youtubeVideoId}: ${content.length} chars${segments ? `, ${segments.length} segments` : ""}`);
      imported++;
      continue;
    }

    await prisma.transcript.upsert({
      where: { videoId: video.id },
      create: { videoId: video.id, content, segments: segments ?? undefined },
      update: { content, segments: segments ?? undefined },
    });
    imported++;
  }

  console.log(
    `\nDone. imported=${imported} (withSegments=${withSegments}) skipped-empty=${skipped} no-matching-video=${missingVideo}`,
  );
  await prisma.$disconnect();
}

main().catch(async (e) => {
  console.error(e);
  await prisma.$disconnect();
  process.exit(1);
});
