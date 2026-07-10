import { db } from "@/lib/db";
import { getUserId } from "@/lib/current-user";
import { ok, fail, unauthorized } from "@/lib/mobile/respond";

export async function DELETE(
  req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId(req);
  if (!userId) return unauthorized();

  const { id } = await params;
  const comment = await db.comment.findUnique({
    where: { id },
    include: { _count: { select: { replies: true } } },
  });
  if (!comment) return fail(404, "Comment not found.");
  if (comment.userId !== userId) return fail(403, "Forbidden.");

  // A comment that still has replies is soft-deleted to keep the thread readable.
  if (comment._count.replies > 0) {
    await db.comment.update({ where: { id }, data: { deletedAt: new Date(), body: "" } });
    return ok({ ok: true, mode: "soft" });
  }
  await db.comment.delete({ where: { id } });
  return ok({ ok: true, mode: "hard" });
}
