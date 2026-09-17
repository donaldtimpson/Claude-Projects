import { NextResponse } from "next/server";
import { db } from "@/lib/db";
import { getUserId } from "@/lib/current-user";

// Block / unblock another user. Dual-transport (web cookie session OR mobile
// Bearer token) via getUserId. Blocking hides that user's comments from the
// blocker's discussion listing everywhere (web + mobile) — the App Store
// Guideline 1.2 "block abusive users" affordance. The block is one-directional
// and private to the blocker.
//
//   POST   { blockedId }  -> create the block (idempotent)
//   DELETE { blockedId }  -> remove it (idempotent)

async function readBlockedId(req: Request): Promise<string | null> {
  try {
    const { blockedId } = await req.json();
    return typeof blockedId === "string" && blockedId ? blockedId : null;
  } catch {
    return null;
  }
}

export async function POST(req: Request) {
  const userId = await getUserId(req);
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const blockedId = await readBlockedId(req);
  if (!blockedId) return NextResponse.json({ error: "blockedId is required." }, { status: 400 });
  if (blockedId === userId) {
    return NextResponse.json({ error: "You can't block yourself." }, { status: 400 });
  }

  const target = await db.user.findUnique({ where: { id: blockedId }, select: { id: true } });
  if (!target) return NextResponse.json({ error: "User not found." }, { status: 404 });

  // Idempotent: re-blocking is a no-op thanks to the unique (blockerId, blockedId).
  await db.userBlock.upsert({
    where: { blockerId_blockedId: { blockerId: userId, blockedId } },
    create: { blockerId: userId, blockedId },
    update: {},
  });
  return NextResponse.json({ ok: true, blocked: true });
}

export async function DELETE(req: Request) {
  const userId = await getUserId(req);
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const blockedId = await readBlockedId(req);
  if (!blockedId) return NextResponse.json({ error: "blockedId is required." }, { status: 400 });

  await db.userBlock.deleteMany({ where: { blockerId: userId, blockedId } });
  return NextResponse.json({ ok: true, blocked: false });
}
