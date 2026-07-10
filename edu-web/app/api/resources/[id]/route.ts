import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { ResourceKind } from "@prisma/client";
import { db } from "@/lib/db";

async function isAdmin() {
  const cookieStore = await cookies();
  return cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;
}

const VALID_KINDS = Object.values(ResourceKind) as string[];

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const { title, url, kind, description } = await req.json();

  const data: { title?: string; url?: string; kind?: ResourceKind; description?: string } = {};
  if (title?.trim()) data.title = title.trim();
  if (url?.trim()) data.url = url.trim();
  if (kind?.trim()) {
    if (!VALID_KINDS.includes(kind)) {
      return NextResponse.json({ error: "invalid kind" }, { status: 400 });
    }
    data.kind = kind as ResourceKind;
  }
  if (typeof description === "string") data.description = description.trim();

  const resource = await db.resource.update({ where: { id }, data });
  return NextResponse.json(resource);
}

export async function DELETE(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  await db.resource.delete({ where: { id } });
  return new NextResponse(null, { status: 204 });
}
