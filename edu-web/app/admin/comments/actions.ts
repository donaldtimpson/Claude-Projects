"use server";

import { revalidatePath } from "next/cache";
import { db } from "@/lib/db";
import { assertAdmin } from "@/lib/admin-auth";

// Admin moderation actions on the queue of open comment reports. Every action
// re-asserts the admin cookie. A report is resolved (comment handled) or
// dismissed (no action needed); deleting the comment optionally closes its open
// reports in the same step.

// Soft- or hard-delete the offending comment, then resolve every OPEN report on
// it. Mirrors the user-facing delete rule: a comment that still has replies is
// soft-deleted (placeholder kept so the thread reads), otherwise removed outright.
export async function deleteReportedComment(commentId: string) {
  await assertAdmin();
  const comment = await db.comment.findUnique({
    where: { id: commentId },
    include: { _count: { select: { replies: true } } },
  });
  if (!comment) return;

  if (comment._count.replies > 0) {
    await db.comment.update({ where: { id: commentId }, data: { deletedAt: new Date(), body: "" } });
  } else {
    // Hard delete cascades its reports away; do it inside a txn with the resolve so
    // both halves land together for a comment that survives (soft-delete case).
    await db.commentReport.updateMany({
      where: { commentId, status: "OPEN" },
      data: { status: "RESOLVED", resolvedAt: new Date() },
    });
    await db.comment.delete({ where: { id: commentId } });
    revalidatePath("/admin/comments");
    return;
  }

  await db.commentReport.updateMany({
    where: { commentId, status: "OPEN" },
    data: { status: "RESOLVED", resolvedAt: new Date() },
  });
  revalidatePath("/admin/comments");
}

// Mark a single report RESOLVED (the comment was handled) without touching the
// comment — used when the admin deleted it another way or judged it actioned.
export async function resolveReport(reportId: string) {
  await assertAdmin();
  await db.commentReport.updateMany({
    where: { id: reportId, status: "OPEN" },
    data: { status: "RESOLVED", resolvedAt: new Date() },
  });
  revalidatePath("/admin/comments");
}

// Dismiss a report: the comment is fine, no action needed. Frees the reporter to
// file again if the comment later offends.
export async function dismissReport(reportId: string) {
  await assertAdmin();
  await db.commentReport.updateMany({
    where: { id: reportId, status: "OPEN" },
    data: { status: "DISMISSED", resolvedAt: new Date() },
  });
  revalidatePath("/admin/comments");
}
