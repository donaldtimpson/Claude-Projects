import { PrismaClient } from "@prisma/client";
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

const prisma = new PrismaClient();

const OUT_DIR = join(process.cwd(), "scripts", "transcripts");

function stripVtt(vtt: string): string {
  const lines = vtt.split("\n");
  const seen = new Set<string>();
  const out: string[] = [];
  for (const raw of lines) {
    const line = raw.trim();
    if (!line) continue;
    if (line === "WEBVTT") continue;
    if (line.startsWith("Kind:") || line.startsWith("Language:")) continue;
    if (/^\d\d:\d\d:\d\d\./.test(line)) continue;
    if (line.includes("-->")) continue;
    const cleaned = line
      .replace(/<[^>]+>/g, "")
      .replace(/&amp;/g, "&")
      .replace(/&lt;/g, "<")
      .replace(/&gt;/g, ">")
      .replace(/&#39;/g, "'")
      .replace(/&quot;/g, '"')
      .trim();
    if (!cleaned) continue;
    if (seen.has(cleaned)) continue;
    seen.add(cleaned);
    out.push(cleaned);
  }
  return out.join(" ").replace(/\s+/g, " ").trim();
}

async function main() {
  if (!existsSync(OUT_DIR)) mkdirSync(OUT_DIR, { recursive: true });

  const argCourseId = process.argv[2];
  const videos = await prisma.video.findMany({
    where: argCourseId ? { courseId: argCourseId } : undefined,
    select: { id: true, youtubeVideoId: true, title: true },
  });

  console.log(`Fetching transcripts for ${videos.length} videos${argCourseId ? ` (course ${argCourseId})` : ""}`);

  let fetched = 0;
  let skipped = 0;
  let failed = 0;

  for (const v of videos) {
    const outPath = join(OUT_DIR, `${v.youtubeVideoId}.txt`);
    if (existsSync(outPath)) {
      skipped++;
      continue;
    }

    const work = join(tmpdir(), `yt-${v.youtubeVideoId}`);
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
        { cwd: work, stdio: "pipe" }
      );

      const vttFile = readdirSync(work).find((f) => f.endsWith(".vtt"));
      if (!vttFile) {
        console.warn(`  no captions: ${v.title}`);
        writeFileSync(outPath, "");
        failed++;
        continue;
      }
      const vtt = readFileSync(join(work, vttFile), "utf8");
      const text = stripVtt(vtt);
      writeFileSync(outPath, text);
      console.log(`  ✓ ${v.title} (${text.length} chars)`);
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
