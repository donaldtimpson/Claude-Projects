import { PrismaClient } from "@prisma/client";
import { writeFileSync } from "node:fs";
import { join } from "node:path";

const prisma = new PrismaClient();

async function main() {
  const questions = await prisma.quizQuestion.findMany({
    where: { isDraft: false },
    include: {
      video: { select: { title: true, course: { select: { title: true } } } },
      course: { select: { title: true } },
    },
    orderBy: { createdAt: "asc" },
  });

  const exemplars = questions.map((q) => ({
    scope: q.videoId ? "video" : "course",
    courseTitle: q.video?.course?.title ?? q.course?.title ?? null,
    videoTitle: q.video?.title ?? null,
    prompt: q.prompt,
    options: q.options as string[],
    correctIndex: q.correctIndex,
    explanation: q.explanation,
  }));

  const outPath = join(process.cwd(), "scripts", "exemplars.json");
  writeFileSync(outPath, JSON.stringify(exemplars, null, 2));
  console.log(`Wrote ${exemplars.length} exemplars to ${outPath}`);

  await prisma.$disconnect();
}

main().catch(async (e) => {
  console.error(e);
  await prisma.$disconnect();
  process.exit(1);
});
