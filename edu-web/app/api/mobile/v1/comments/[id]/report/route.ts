import { db } from "@/lib/db";
import { withUser } from "@/lib/mobile/guard";
import { ok, fail, badRequest } from "@/lib/mobile/respond";
import { normalizeReason } from "@/lib/moderation";

// Report a comment for moderation (App Store Guideline 1.2). Mobile-namespaced
// twin of POST /api/comments/[id]/report; same OPEN-report semantics, idempotent
// per (comment, reporter). Feeds the admin moderation queue.
export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  return withUser(req, async (userId) => {
    const { id } = await params;
    const comment = await db.comment.findUnique({ where: { id }, select: { id: true, userId: true } });
    if (!comment) return fail(404, "Comment not found.");
    if (comment.userId === userId) return badRequest("You can't report your own comment.");

    let payload: { reason?: string; note?: string } = {};
    try {
      payload = await req.json();
    } catch {
      // Optional body — bare report defaults to reason OTHER.
    }
    const reason = normalizeReason(payload.reason);
    const note = payload.note?.trim() ? payload.note.trim().slice(0, 1000) : null;

    try {
      await db.commentReport.create({ data: { commentId: id, reporterId: userId, reason, note } });
    } catch {
      // Open report already on file for this (comment, reporter) — treat as success.
      return ok({ ok: true, alreadyReported: true });
    }
    return ok({ ok: true }, { status: 201 });
  });
}
