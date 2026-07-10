import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { db } from "@/lib/db";

async function isAdmin() {
  const cookieStore = await cookies();
  return cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;
}

export async function GET() {
  const categories = await db.category.findMany({
    orderBy: { name: "asc" },
    include: { _count: { select: { courses: true } } },
  });
  return NextResponse.json(categories);
}

export async function POST(req: Request) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { name, slug } = await req.json();
  if (!name?.trim() || !slug?.trim()) {
    return NextResponse.json({ error: "name and slug are required" }, { status: 400 });
  }

  const slugNormalized = (slug as string).trim().toLowerCase().replace(/[^a-z0-9-]/g, "-");

  try {
    const category = await db.category.create({ data: { name: name.trim(), slug: slugNormalized } });
    return NextResponse.json(category, { status: 201 });
  } catch {
    return NextResponse.json({ error: "Name or slug already in use" }, { status: 409 });
  }
}
