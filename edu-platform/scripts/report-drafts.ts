import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();
async function main() {
  const courses = await prisma.course.findMany({
    select: { id: true, title: true, videos: { select: { id: true } } },
    orderBy: { title: "asc" },
  });
  let totalDraft = 0;
  for (const c of courses) {
    const videoIds = c.videos.map((v) => v.id);
    const where = { OR: [{ courseId: c.id, videoId: null }, { videoId: { in: videoIds } }] };
    const draft = await prisma.quizQuestion.count({ where: { ...where, isDraft: true } });
    const pub = await prisma.quizQuestion.count({ where: { ...where, isDraft: false } });
    totalDraft += draft;
    if (draft > 0 || pub > 0) {
      console.log(`${draft.toString().padStart(4)} draft | ${pub.toString().padStart(4)} pub  | ${c.id}  ${c.title}`);
    }
  }
  console.log(`\nTOTAL DRAFTS: ${totalDraft}`);
  await prisma.$disconnect();
}
main().catch(async (e) => { console.error(e); await prisma.$disconnect(); process.exit(1); });
