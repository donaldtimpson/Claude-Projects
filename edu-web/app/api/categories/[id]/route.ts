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
  const { name, slug } = await req.json();

  const data: { name?: string; slug?: string } = {};
  if (name?.trim()) data.name = name.trim();
  if (slug?.trim()) data.slug = (slug as string).trim().toLowerCase().replace(/[^a-z0-9-]/g, "-");

  try {
    const category = await db.category.update({ where: { id }, data });
    return NextResponse.json(category);
  } catch {
    return NextResponse.json({ error: "Name or slug already in use" }, { status: 409 });
  }
}

export async function DELETE(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  await db.category.delete({ where: { id } });
  return new NextResponse(null, { status: 204 });
}
