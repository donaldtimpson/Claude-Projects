import { db } from "@/lib/db";
import { getStreak } from "@/lib/gamification/engine";
import { getDueCount } from "@/lib/srs";
import { withUser } from "@/lib/mobile/guard";
import { ok } from "@/lib/mobile/respond";

export async function GET(req: Request) {
  return withUser(req, async (userId) => {
    const [user, streak, dueCount, bestRows] = await Promise.all([
      db.user.findUnique({
        where: { id: userId },
        select: { id: true, name: true, email: true, handle: true },
      }),
      getStreak(userId),
      getDueCount(userId),
      // Best Rapid Fire score per (drill, difficulty) — the synced high scores.
      db.drillAttempt.groupBy({
        by: ["slug", "level"],
        where: { userId, mode: "timed", score: { not: null } },
        _max: { score: true },
      }),
    ]);
    const drillBests = bestRows.map((r) => ({ slug: r.slug, level: r.level, best: r._max.score ?? 0 }));
    return ok({ user, streak, dueCount, drillBests });
  });
}
