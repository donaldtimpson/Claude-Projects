import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const videoId = searchParams.get("videoId");
  if (!videoId) return NextResponse.json({ error: "videoId required" }, { status: 400 });

  const comments = await db.comment.findMany({
    where: { videoId },
    include: { user: { select: { id: true, name: true } } },
    orderBy: { createdAt: "asc" },
  });

  return NextResponse.json(
    comments.map((c) => ({
      id: c.id,
      body: c.body,
      createdAt: c.createdAt.toISOString(),
      user: { id: c.user.id, name: c.user.name ?? "Student" },
    }))
  );
}

export async function POST(req: Request) {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { videoId, body } = await req.json();
  if (!videoId || !body?.trim()) {
    return NextResponse.json({ error: "videoId and body required" }, { status: 400 });
  }

  const comment = await db.comment.create({
    data: { userId: session.user.id, videoId, body: body.trim() },
    include: { user: { select: { id: true, name: true } } },
  });

  return NextResponse.json(
    {
      id: comment.id,
      body: comment.body,
      createdAt: comment.createdAt.toISOString(),
      user: { id: comment.user.id, name: comment.user.name ?? "Student" },
    },
    { status: 201 }
  );
}
