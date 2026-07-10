import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { db } from "@/lib/db";

async function isAdmin() {
  const cookieStore = await cookies();
  return cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;
}

// PATCH — toggle isDraft (publish / unpublish) or update content by note id.
export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const [body, { id }] = await Promise.all([req.json(), params]);
  const { content, isDraft } = body;

  const note = await db.lectureNote.update({
    where: { id },
    data: {
      ...(content != null && { content }),
      ...(isDraft != null && { isDraft }),
    },
  });
  return NextResponse.json(note);
}

export async function DELETE(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  await db.lectureNote.delete({ where: { id } });
  return NextResponse.json({ deleted: true });
}
