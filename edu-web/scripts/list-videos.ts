import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();
async function main() {
  const courseId = process.argv[2];
  if (!courseId) { console.error("usage: list-videos.ts <courseId>"); process.exit(1); }
  const course = await prisma.course.findUnique({
    where: { id: courseId },
    select: { title: true, videos: { orderBy: { position: "asc" }, select: { id: true, position: true, title: true, youtubeVideoId: true } } },
  });
  if (!course) { console.error("course not found"); process.exit(1); }
  console.log(`# ${course.title}  (${course.videos.length} videos)`);
  for (const v of course.videos) {
    console.log(`${v.position.toString().padStart(2)} | ${v.id} | ${v.youtubeVideoId} | ${v.title}`);
  }
  await prisma.$disconnect();
}
main().catch(async (e) => { console.error(e); await prisma.$disconnect(); process.exit(1); });
