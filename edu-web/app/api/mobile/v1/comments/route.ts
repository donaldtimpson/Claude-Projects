import { db } from "@/lib/db";
import { getUserId } from "@/lib/current-user";
import { nestComments, serializeComment } from "@/lib/comments";
import { ok, fail, badRequest, unauthorized } from "@/lib/mobile/respond";

export async function GET(req: Request) {
  const videoId = new URL(req.url).searchParams.get("videoId");
  if (!videoId) return badRequest("videoId is required.");
  const comments = await db.comment.findMany({
    where: { videoId },
    include: { user: { select: { id: true, name: true } } },
    orderBy: { createdAt: "asc" },
  });
  return ok({ comments: nestComments(comments) });
}

export async function POST(req: Request) {
  const userId = await getUserId(req);
  if (!userId) return unauthorized();

  let payload: { videoId?: string; body?: string; parentId?: string };
  try {
    payload = await req.json();
  } catch {
    return badRequest();
  }
  const { videoId, body, parentId } = payload;
  if (!videoId || !body?.trim()) return badRequest("videoId and body are required.");

  // Replies collapse to a single level (mirrors the web route).
  let resolvedParentId: string | null = null;
  if (parentId) {
    const parent = await db.comment.findUnique({ where: { id: parentId } });
    if (!parent || parent.videoId !== videoId) return fail(404, "Parent comment not found.");
    if (parent.deletedAt) return badRequest("Cannot reply to a deleted comment.");
    resolvedParentId = parent.parentId ?? parent.id;
  }

  const comment = await db.comment.create({
    data: { userId, videoId, parentId: resolvedParentId, body: body.trim() },
    include: { user: { select: { id: true, name: true } } },
  });
  return ok(serializeComment(comment), { status: 201 });
}
