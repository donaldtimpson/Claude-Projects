import { NextResponse } from "next/server";
import { db } from "@/lib/db";
import { getUserId } from "@/lib/current-user";
import { normalizeReason } from "@/lib/moderation";

// Report a comment for moderation. Dual-transport (web cookie session OR mobile
// Bearer token) via getUserId, mirroring POST /api/comments. Creates an OPEN
// CommentReport that surfaces in the admin moderation queue. Idempotent per
// (comment, reporter): a second open report by the same user on the same comment
// returns 200 without erroring (the unique key on (commentId, reporterId, status)
// is caught rather than surfaced as a failure). This is the App Store Guideline
// 1.2 "report objectionable content" affordance.
export async function POST(
  req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId(req);
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const comment = await db.comment.findUnique({ where: { id }, select: { id: true, userId: true } });
  if (!comment) return NextResponse.json({ error: "Comment not found" }, { status: 404 });
  if (comment.userId === userId) {
    return NextResponse.json({ error: "You can't report your own comment." }, { status: 400 });
  }

  let payload: { reason?: string; note?: string } = {};
  try {
    payload = await req.json();
  } catch {
    // Body is optional — a bare report defaults to reason OTHER.
  }
  const reason = normalizeReason(payload.reason);
  const note = payload.note?.trim() ? payload.note.trim().slice(0, 1000) : null;

  try {
    await db.commentReport.create({
      data: { commentId: id, reporterId: userId, reason, note },
    });
  } catch {
    // Unique (commentId, reporterId, status=OPEN) collision: the user already has
    // an open report on this comment. Treat as success — the report is on file.
    return NextResponse.json({ ok: true, alreadyReported: true });
  }
  return NextResponse.json({ ok: true }, { status: 201 });
}
