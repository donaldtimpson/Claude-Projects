import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { db } from "@/lib/db";
import { canonicalRelatedPair, wouldCreateCycle } from "@/lib/course-graph";

async function isAdmin() {
  const cookieStore = await cookies();
  return cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;
}

type Body = {
  fromCourseId?: string;
  toCourseId?: string;
  kind?: "RECOMMENDED" | "RELATED";
};

function normalize(body: Body): { from: string; to: string; kind: "RECOMMENDED" | "RELATED" } | null {
  const { fromCourseId, toCourseId, kind } = body;
  if (!fromCourseId || !toCourseId || (kind !== "RECOMMENDED" && kind !== "RELATED")) return null;
  if (fromCourseId === toCourseId) return null;
  if (kind === "RELATED") {
    const [from, to] = canonicalRelatedPair(fromCourseId, toCourseId);
    return { from, to, kind };
  }
  return { from: fromCourseId, to: toCourseId, kind };
}

export async function POST(req: Request) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const link = normalize(await req.json());
  if (!link) return NextResponse.json({ error: "Invalid link" }, { status: 400 });

  if (link.kind === "RECOMMENDED") {
    const existing = await db.courseLink.findMany({
      where: { kind: "RECOMMENDED" },
      select: { fromCourseId: true, toCourseId: true },
    });
    if (wouldCreateCycle(existing, link.from, link.to)) {
      return NextResponse.json(
        { error: "That recommended link would create a cycle. Use a Related link instead." },
        { status: 409 },
      );
    }
  }

  // Idempotent: the @@unique([from, to, kind]) makes a repeat a no-op.
  const created = await db.courseLink.upsert({
    where: {
      fromCourseId_toCourseId_kind: {
        fromCourseId: link.from,
        toCourseId: link.to,
        kind: link.kind,
      },
    },
    create: { fromCourseId: link.from, toCourseId: link.to, kind: link.kind },
    update: {},
  });
  return NextResponse.json(created, { status: 201 });
}

export async function DELETE(req: Request) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const link = normalize(await req.json());
  if (!link) return NextResponse.json({ error: "Invalid link" }, { status: 400 });

  await db.courseLink.deleteMany({
    where: { fromCourseId: link.from, toCourseId: link.to, kind: link.kind },
  });
  return NextResponse.json({ ok: true });
}
