import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { nestComments, serializeComment } from "@/lib/comments";
import { getBlockedUserIds } from "@/lib/moderation";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const videoId = searchParams.get("videoId");
  if (!videoId) return NextResponse.json({ error: "videoId required" }, { status: 400 });

  // Hide comments authored by anyone the viewer has blocked (both top-level and
  // replies, since the filter runs on the flat row set before nesting).
  const session = await getServerSession(authOptions);
  const blocked = await getBlockedUserIds(session?.user?.id ?? null);

  const comments = await db.comment.findMany({
    where: { videoId, ...(blocked.length ? { userId: { notIn: blocked } } : {}) },
    include: { user: { select: { id: true, name: true } } },
    orderBy: { createdAt: "asc" },
  });

  return NextResponse.json(nestComments(comments));
}

export async function POST(req: Request) {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { videoId, body, parentId } = await req.json();
  if (!videoId || !body?.trim()) {
    return NextResponse.json({ error: "videoId and body required" }, { status: 400 });
  }

  // Replies collapse to a single level: a reply always attaches to the top-level
  // comment, even if the user replied to another reply.
  let resolvedParentId: string | null = null;
  if (parentId) {
    const parent = await db.comment.findUnique({ where: { id: parentId } });
    if (!parent || parent.videoId !== videoId) {
      return NextResponse.json({ error: "Parent comment not found" }, { status: 404 });
    }
    if (parent.deletedAt) {
      return NextResponse.json({ error: "Cannot reply to a deleted comment" }, { status: 400 });
    }
    resolvedParentId = parent.parentId ?? parent.id;
  }

  const comment = await db.comment.create({
    data: { userId: session.user.id, videoId, parentId: resolvedParentId, body: body.trim() },
    include: { user: { select: { id: true, name: true } } },
  });

  return NextResponse.json(serializeComment(comment), { status: 201 });
}
