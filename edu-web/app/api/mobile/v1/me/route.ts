import { db } from "@/lib/db";
import { getStreak } from "@/lib/gamification/engine";
import { getDueCount } from "@/lib/srs";
import { withUser } from "@/lib/mobile/guard";
import { ok } from "@/lib/mobile/respond";

export async function GET(req: Request) {
  return withUser(req, async (userId) => {
    const [user, streak, dueCount] = await Promise.all([
      db.user.findUnique({
        where: { id: userId },
        select: { id: true, name: true, email: true, handle: true },
      }),
      getStreak(userId),
      getDueCount(userId),
    ]);
    return ok({ user, streak, dueCount });
  });
}
