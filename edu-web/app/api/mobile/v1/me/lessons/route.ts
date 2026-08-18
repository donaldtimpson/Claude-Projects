import { getAcedLessonSlugs } from "@/lib/lessons";
import { withUser } from "@/lib/mobile/guard";
import { ok } from "@/lib/mobile/respond";

// Aced grammar-lesson slugs for the current user, derived from DrillAttempt rows
// (a flawless homework-length run). Powers the ✦ across iOS + web.
export async function GET(req: Request) {
  return withUser(req, async (userId) => {
    const acedSlugs = await getAcedLessonSlugs(userId);
    return ok({ acedSlugs });
  });
}
