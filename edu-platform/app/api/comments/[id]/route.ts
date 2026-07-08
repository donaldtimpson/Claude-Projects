import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";

export async function DELETE(
  _req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const comment = await db.comment.findUnique({
    where: { id },
    include: { _count: { select: { replies: true } } },
  });
  if (!comment) return NextResponse.json({ error: "Not found" }, { status: 404 });
  if (comment.userId !== session.user.id) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  // Keep the thread readable: a comment that still has replies is soft-deleted
  // (placeholder), everything else is removed outright.
  if (comment._count.replies > 0) {
    await db.comment.update({ where: { id }, data: { deletedAt: new Date(), body: "" } });
    return NextResponse.json({ ok: true, mode: "soft" });
  }

  await db.comment.delete({ where: { id } });
  return NextResponse.json({ ok: true, mode: "hard" });
}
