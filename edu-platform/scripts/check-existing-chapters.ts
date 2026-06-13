import { PrismaClient } from "@prisma/client";
import { descriptionChapterStatus } from "../lib/chapters";
import { getVideoSnippet } from "../lib/youtube-oauth";

// For a course, read each video's LIVE YouTube description and classify whether
// it already has chapters. Drives the chapters pipeline: only "none" videos need
// generating; "preexisting" (hand-authored) are skipped; "ours" already carry a
// managed block. Usage: npx tsx scripts/check-existing-chapters.ts <courseId>

const prisma = new PrismaClient();

async function main() {
  const courseId = process.argv[2];
  if (!courseId) { console.error("Usage: check-existing-chapters.ts <courseId>"); process.exit(1); }

  const vids = await prisma.video.findMany({
    where: { courseId },
    select: { youtubeVideoId: true, title: true, position: true },
    orderBy: { position: "asc" },
  });

  const counts = { preexisting: 0, ours: 0, none: 0 } as Record<string, number>;
  for (const v of vids) {
    let status: string;
    try {
      const snip = await getVideoSnippet(v.youtubeVideoId);
      status = descriptionChapterStatus(snip.description ?? "");
    } catch (e) {
      status = `ERROR(${(e as Error).message.slice(0, 40)})`;
    }
    counts[status] = (counts[status] ?? 0) + 1;
    const tag = status === "preexisting" ? "HAS CHAPTERS (skip) " : status === "ours" ? "ours (update)      " : status === "none" ? "needs chapters     " : status;
    console.log(`  ${tag}  ${v.youtubeVideoId}  ${v.title.slice(0, 55)}`);
  }
  console.log(`\n${vids.length} videos — needs=${counts.none ?? 0} preexisting=${counts.preexisting ?? 0} ours=${counts.ours ?? 0}`);
}

main().finally(() => prisma.$disconnect());
