import { db } from "@/lib/db";
import { withUser } from "@/lib/mobile/guard";
import { ok, fail, badRequest } from "@/lib/mobile/respond";

// Block / unblock another user (App Store Guideline 1.2). Mobile-namespaced twin
// of /api/blocks. Blocking hides that user's comments from the blocker's
// discussion listing (the GET /comments filter applies it server-side).
//
//   POST   { blockedId }  -> block (idempotent)
//   DELETE { blockedId }  -> unblock (idempotent)

async function readBlockedId(req: Request): Promise<string | null> {
  try {
    const { blockedId } = await req.json();
    return typeof blockedId === "string" && blockedId ? blockedId : null;
  } catch {
    return null;
  }
}

export async function POST(req: Request) {
  return withUser(req, async (userId) => {
    const blockedId = await readBlockedId(req);
    if (!blockedId) return badRequest("blockedId is required.");
    if (blockedId === userId) return badRequest("You can't block yourself.");

    const target = await db.user.findUnique({ where: { id: blockedId }, select: { id: true } });
    if (!target) return fail(404, "User not found.");

    await db.userBlock.upsert({
      where: { blockerId_blockedId: { blockerId: userId, blockedId } },
      create: { blockerId: userId, blockedId },
      update: {},
    });
    return ok({ ok: true, blocked: true });
  });
}

export async function DELETE(req: Request) {
  return withUser(req, async (userId) => {
    const blockedId = await readBlockedId(req);
    if (!blockedId) return badRequest("blockedId is required.");
    await db.userBlock.deleteMany({ where: { blockerId: userId, blockedId } });
    return ok({ ok: true, blocked: false });
  });
}
