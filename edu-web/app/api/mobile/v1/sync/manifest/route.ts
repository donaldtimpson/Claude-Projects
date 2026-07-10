import { db } from "@/lib/db";
import { ok } from "@/lib/mobile/respond";

// Offline sync manifest: a lightweight {id, updatedAt} list per content type so
// the app pulls only what changed since its last sync. Published content only.
export async function GET() {
  const [courses, videos, notes, quiz] = await Promise.all([
    db.course.findMany({ select: { id: true, updatedAt: true } }),
    db.video.findMany({ select: { id: true, updatedAt: true } }),
    db.lectureNote.findMany({
      where: { isDraft: false },
      select: { videoId: true, updatedAt: true },
    }),
    db.quizQuestion.findMany({
      where: { isDraft: false },
      select: { id: true, updatedAt: true },
    }),
  ]);
  return ok({ courses, videos, notes, quiz, generatedAt: new Date().toISOString() });
}
