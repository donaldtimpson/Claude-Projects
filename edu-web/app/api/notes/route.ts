import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { db } from "@/lib/db";

async function isAdmin() {
  const cookieStore = await cookies();
  return cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;
}

// GET ?videoId=  — returns the note. Drafts are hidden unless requested by an admin.
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const videoId = searchParams.get("videoId");
  if (!videoId) return NextResponse.json({ error: "Missing videoId" }, { status: 400 });

  const includeDrafts = searchParams.get("includeDrafts") === "true" && (await isAdmin());
  const note = await db.lectureNote.findUnique({ where: { videoId } });
  if (!note || (note.isDraft && !includeDrafts)) return NextResponse.json(null);
  return NextResponse.json(note);
}

// PUT — upsert the note's content for a video. Creates as draft; preserves the
// existing isDraft state on update so saving edits never silently unpublishes.
export async function PUT(req: Request) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { videoId, content } = await req.json();
  if (!videoId || typeof content !== "string") {
    return NextResponse.json({ error: "Missing videoId or content" }, { status: 400 });
  }

  const note = await db.lectureNote.upsert({
    where: { videoId },
    create: { videoId, content, isDraft: true },
    update: { content },
  });
  return NextResponse.json(note);
}
