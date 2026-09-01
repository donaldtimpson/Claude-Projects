import { db } from "@/lib/db";
import { getStreak, generateHandle } from "@/lib/gamification/engine";
import { getDueCount } from "@/lib/srs";
import { withUser } from "@/lib/mobile/guard";
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
    // What this student is called in the Hall of Scholars when they haven't picked a
    // handle. The leaderboard, the quiz aces, and the admin views all fall back to
    // generateHandle, so a student with no handle already HAS a public name — the app
    // just never showed it, leaving them unable to find themselves on the board. Sent
    // alongside the raw handle rather than replacing it, so the editor can still tell
    // "chosen" from "assigned", exactly as the web dashboard does.
    return ok({ user, streak, dueCount, drillBests, handlePlaceholder: generateHandle(userId) });
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
      select: { id: true },
    });
    if (!user) return fail(404, "Account not found.");

    // Deliberately NO password re-entry. This route used to re-authenticate before
    // destroying data, on the reasoning that a stolen access token alone should not
    // be enough to wipe an account. App Review rejected 1.0 (3) under Guideline
    // 5.1.1(v) for exactly that: the guideline says an app must not require the
    // user to "add a password to complete account deletion", and a reviewer reads a
    // password field on the delete screen as that barrier regardless of whether the
    // account already has one.
    //
    // What guards the action instead is what the guideline does allow — a
    // confirmation step: the app makes the student type DELETE, and lists what is
    // about to be destroyed. The bearer token still has to be valid, which means an
    // unlocked device holding a Keychain-stored token an hour old at most.
    //
    // This is the only account-deletion path in the system — there is no web
    // equivalent — so nothing else re-authenticates either.

    await db.$transaction([
      db.idempotencyKey.deleteMany({ where: { userId } }),
      db.user.delete({ where: { id: userId } }),
    ]);
    return ok({ deleted: true });
  });
}
