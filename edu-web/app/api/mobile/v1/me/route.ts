import { db } from "@/lib/db";
import { getStreak } from "@/lib/gamification/engine";
import { getDueCount } from "@/lib/srs";
import { withUser } from "@/lib/mobile/guard";
import { verifyCredentials } from "@/lib/auth-core";
import { ok, fail, unauthorized } from "@/lib/mobile/respond";

export async function GET(req: Request) {
  return withUser(req, async (userId) => {
    const [user, streak, dueCount, bestRows] = await Promise.all([
      db.user.findUnique({
        where: { id: userId },
        select: { id: true, name: true, email: true, handle: true },
      }),
      getStreak(userId),
      getDueCount(userId),
      // Best Rapid Fire score per (drill, difficulty, sprint length) — the synced
      // high scores. Duration is part of the key: 60s and 120s are separate boards.
      db.drillAttempt.groupBy({
        by: ["slug", "level", "durationSec"],
        where: { userId, mode: "timed", score: { not: null } },
        _max: { score: true },
      }),
    ]);
    // Access tokens are stateless 1h JWTs, so one outlives the account it names
    // (a deleted account's token still verifies). Say 401 rather than handing the
    // app a null user, so it drops the dead tokens and returns to sign-in.
    if (!user) return unauthorized();

    const drillBests = bestRows.map((r) => ({
      slug: r.slug, level: r.level, durationSec: r.durationSec, best: r._max.score ?? 0,
    }));
    return ok({ user, streak, dueCount, drillBests });
  });
}

// Account deletion, initiated from the app (Profile -> Delete Account). App Store
// Review Guideline 5.1.1(v) requires any app that lets you create an account to
// let you delete it from inside the app — no support-email hoop, and a real
// delete, not a deactivation flag.
//
// Every User relation in the schema is `onDelete: Cascade`, so one `user.delete`
// takes the sessions, progress, quiz + drill attempts, reviews, comments, badges,
// enrollments, submissions, and refresh tokens with it. IdempotencyKey carries a
// bare `userId` with no relation, so it's cleared explicitly.
export async function DELETE(req: Request) {
  return withUser(req, async (userId) => {
    const user = await db.user.findUnique({
      where: { id: userId },
      select: { email: true, password: true },
    });
    if (!user) return fail(404, "Account not found.");

    // Re-authenticate before destroying data: a stolen access token alone must
    // not be enough to wipe a student's account. Apple-only accounts have no
    // password, so the app gates those behind its typed confirmation instead.
    if (user.password) {
      const body = await req.json().catch(() => ({}) as { password?: string });
      const confirmed = await verifyCredentials(user.email, body?.password);
      if (!confirmed) return fail(401, "Incorrect password.");
    }

    await db.$transaction([
      db.idempotencyKey.deleteMany({ where: { userId } }),
      db.user.delete({ where: { id: userId } }),
    ]);
    return ok({ deleted: true });
  });
}
