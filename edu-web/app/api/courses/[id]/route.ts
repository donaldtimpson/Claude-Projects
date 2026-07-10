import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { db } from "@/lib/db";

async function isAdmin() {
  const cookieStore = await cookies();
  return cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;
}

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const body = await req.json();

  const data: { isCurrent?: boolean } = {};
  if (typeof body.isCurrent === "boolean") data.isCurrent = body.isCurrent;

  if (Object.keys(data).length === 0) {
    return NextResponse.json({ error: "No valid fields to update" }, { status: 400 });
  }

  const course = await db.course.update({ where: { id }, data });
  return NextResponse.json(course);
}
