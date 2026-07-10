import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();

async function main() {
  const courseId = process.argv[2];
  const drafts = await prisma.quizQuestion.findMany({
    where: { isDraft: true },
    select: {
      id: true,
      prompt: true,
      options: true,
      correctIndex: true,
      explanation: true,
      videoId: true,
      courseId: true,
      video: { select: { title: true, course: { select: { id: true, title: true } } } },
      course: { select: { id: true, title: true } },
    },
    orderBy: { id: "asc" },
  });

  if (!courseId) {
    // Summarize: group by course, show scope breakdown
    const byCourse: Record<string, { title: string; videoScoped: number; courseScoped: number }> = {};
    for (const d of drafts) {
      const c = d.course ?? d.video?.course;
      if (!c) continue;
      byCourse[c.id] ??= { title: c.title, videoScoped: 0, courseScoped: 0 };
      if (d.videoId) byCourse[c.id].videoScoped++;
      else byCourse[c.id].courseScoped++;
    }
    for (const [id, v] of Object.entries(byCourse)) {
      console.log(`${v.courseScoped} test | ${v.videoScoped} video | ${id} ${v.title}`);
    }
    console.log(`\nTotal drafts: ${drafts.length}`);
  } else {
    const sel = drafts.filter((d) => (d.course?.id ?? d.video?.course?.id) === courseId);
    for (const d of sel) {
      const scope = d.videoId ? `VIDEO[${d.video?.title}]` : "COURSE-TEST";
      const opts = (d.options as string[]).map((o, i) => `${i === d.correctIndex ? "✓" : " "}${o}`).join(" | ");
      console.log(`\n[${scope}]\nQ: ${d.prompt}\n   ${opts}\n   exp: ${d.explanation ?? "(none)"}`);
    }
  }
  await prisma.$disconnect();
}
main().catch(async (e) => { console.error(e); await prisma.$disconnect(); process.exit(1); });
