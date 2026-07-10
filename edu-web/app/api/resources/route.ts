import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { ResourceKind } from "@prisma/client";
import { db } from "@/lib/db";

async function isAdmin() {
  const cookieStore = await cookies();
  return cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;
}

const VALID_KINDS = Object.values(ResourceKind) as string[];

export async function GET() {
  const resources = await db.resource.findMany({
    orderBy: [{ kind: "asc" }, { title: "asc" }],
    include: { _count: { select: { courses: true } } },
  });
  return NextResponse.json(resources);
}

export async function POST(req: Request) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { title, url, kind, description } = await req.json();

  if (!title?.trim() || !url?.trim() || !kind?.trim()) {
    return NextResponse.json({ error: "title, url, and kind are required" }, { status: 400 });
  }
  if (!VALID_KINDS.includes(kind)) {
    return NextResponse.json({ error: "invalid kind" }, { status: 400 });
  }

  const resource = await db.resource.create({
    data: {
      title: title.trim(),
      url: url.trim(),
      kind: kind as ResourceKind,
      description: (description ?? "").trim(),
    },
  });
  return NextResponse.json(resource, { status: 201 });
}
