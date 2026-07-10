import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { db } from "@/lib/db";

async function isAdmin() {
  const cookieStore = await cookies();
  return cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;
}

// PUT /api/resources/[id]/courses  { courseIds: string[] }
// Replaces the full course list for this resource.
export async function PUT(req: Request, { params }: { params: Promise<{ id: string }> }) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const { courseIds }: { courseIds: string[] } = await req.json();

  await db.$transaction([
    db.courseResource.deleteMany({ where: { resourceId: id } }),
    ...(courseIds.length > 0
      ? [db.courseResource.createMany({
          data: courseIds.map((courseId) => ({ resourceId: id, courseId })),
        })]
      : []),
  ]);

  return NextResponse.json({ ok: true });
}
