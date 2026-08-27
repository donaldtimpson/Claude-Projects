import { PrismaClient } from "@prisma/client";
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

// Like fetch-transcripts.ts, but KEEPS the cue start times — chapter generation
// needs timecodes, which the plaintext pipeline (stripVtt) throws away. Writes
// scripts/transcripts-timed/{youtubeVideoId}.json as [{ start, text }] where
// start is seconds from the video's beginning. Idempotent (skips existing).
//
// Usage:
//   npx tsx scripts/fetch-timed-transcripts.ts [courseId]
//   npx tsx scripts/fetch-timed-transcripts.ts --video <youtubeVideoId>
//   add --force to re-fetch even if the JSON already exists

const prisma = new PrismaClient();
const OUT_DIR = join(process.cwd(), "scripts", "transcripts-timed");

type Segment = { start: number; text: string };

function tsToSeconds(ts: string): number {
  // HH:MM:SS.mmm
  const m = ts.match(/(\d\d):(\d\d):(\d\d)\.(\d{1,3})/);
  if (!m) return 0;
  return Number(m[1]) * 3600 + Number(m[2]) * 60 + Number(m[3]) + Number(m[4]) / 1000;
}

// Parse a WebVTT file into deduped timed segments. Auto-captions "roll" (a line
// reappears in the next cue), so we keep each cleaned line only the first time it
// appears, tagged with the start time of the cue that introduced it — mirroring
// the dedup in fetch-transcripts.ts's stripVtt, but preserving timing.
function parseVtt(vtt: string): Segment[] {
  const segments: Segment[] = [];
  const seen = new Set<string>();
  let cueStart: number | null = null;

  for (const raw of vtt.split("\n")) {
    const line = raw.trim();
    if (!line || line === "WEBVTT") continue;
    if (line.startsWith("Kind:") || line.startsWith("Language:")) continue;

    if (line.includes("-->")) {
      const startTok = line.split("-->")[0].trim();
      cueStart = tsToSeconds(startTok);
      continue;
    }
    if (cueStart === null) continue; // text before any cue header

    const cleaned = line
      .replace(/<[^>]+>/g, "") // inline <00:00:01.000> / <c> tags
      .replace(/&amp;/g, "&")
      .replace(/&lt;/g, "<")
      .replace(/&gt;/g, ">")
      .replace(/&#39;/g, "'")
      .replace(/&quot;/g, '"')
      .replace(/\s+/g, " ")
      .trim();
    if (!cleaned || seen.has(cleaned)) continue;
    seen.add(cleaned);
    segments.push({ start: cueStart, text: cleaned });
  }

  // Cues can arrive slightly out of order across rolling windows; sort by start.
  return segments.sort((a, b) => a.start - b.start);
}

async function main() {
  if (!existsSync(OUT_DIR)) mkdirSync(OUT_DIR, { recursive: true });

  const args = process.argv.slice(2);
  const force = args.includes("--force");
  const videoFlagIdx = args.indexOf("--video");
  const singleVideoId = videoFlagIdx !== -1 ? args[videoFlagIdx + 1] : undefined;
  const argCourseId = args.find((a) => !a.startsWith("--") && a !== singleVideoId);

  const videos = await prisma.video.findMany({
    where: singleVideoId
      ? { youtubeVideoId: singleVideoId }
      : argCourseId
        ? { courseId: argCourseId }
        : undefined,
    select: { youtubeVideoId: true, title: true },
  });

  console.log(
    `Fetching TIMED transcripts for ${videos.length} video(s)` +
      (singleVideoId ? ` (video ${singleVideoId})` : argCourseId ? ` (course ${argCourseId})` : ""),
  );

  let fetched = 0;
  let skipped = 0;
  let failed = 0;

  for (const v of videos) {
    const outPath = join(OUT_DIR, `${v.youtubeVideoId}.json`);
    // "[]" is the "no captions yet" marker written below; keep it retryable so a
    // freshly-uploaded lecture isn't permanently stuck (see fetch-transcripts.ts).
    if (existsSync(outPath) && !force && readFileSync(outPath, "utf8").trim() !== "[]") {
      skipped++;
      continue;
    }

    const work = join(tmpdir(), `ytt-${v.youtubeVideoId}`);
    mkdirSync(work, { recursive: true });
    try {
      execFileSync(
        "yt-dlp",
        [
          "--skip-download",
          "--write-auto-sub",
          "--write-sub",
          "--sub-lang", "en.*,en",
          "--sub-format", "vtt",
          "--output", "%(id)s.%(ext)s",
          `https://www.youtube.com/watch?v=${v.youtubeVideoId}`,
        ],
        { cwd: work, stdio: "pipe" },
      );

      const vttFile = readdirSync(work).find((f) => f.endsWith(".vtt"));
      if (!vttFile) {
        console.warn(`  no captions: ${v.title}`);
        writeFileSync(outPath, "[]");   // marker only; re-attempted on the next run
        failed++;
        continue;
      }
      const segments = parseVtt(readFileSync(join(work, vttFile), "utf8"));
      writeFileSync(outPath, JSON.stringify(segments));
      console.log(`  ✓ ${v.title} (${segments.length} segments)`);
      fetched++;
    } catch (err) {
      console.warn(`  failed: ${v.title} — ${(err as Error).message.split("\n")[0]}`);
      failed++;
    } finally {
      rmSync(work, { recursive: true, force: true });
    }
  }

  console.log(`\nDone. fetched=${fetched} skipped=${skipped} failed=${failed}`);
  await prisma.$disconnect();
}

main().catch(async (e) => {
  console.error(e);
  await prisma.$disconnect();
  process.exit(1);
});
