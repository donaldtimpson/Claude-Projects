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

type Link = { from: string; to: string; kind: "RECOMMENDED" | "RELATED" };

// Connections live at the subject level, so resolve each endpoint to its
// representative (canonical) course before storing — links from/to a sibling
// offering normalize onto the subject's canonical course. Returns null if a
// course is missing or both endpoints resolve to the same subject.
async function resolveLink(body: Body): Promise<Link | null> {
  const { fromCourseId, toCourseId, kind } = body;
  if (!fromCourseId || !toCourseId || (kind !== "RECOMMENDED" && kind !== "RELATED")) return null;

  const courses = await db.course.findMany({
    where: { id: { in: [fromCourseId, toCourseId] } },
    select: { id: true, canonicalCourseId: true },
  });
  const repOf = (id: string) => {
    const c = courses.find((x) => x.id === id);
    return c ? (c.canonicalCourseId ?? c.id) : null;
  };
  const from = repOf(fromCourseId);
  const to = repOf(toCourseId);
  if (!from || !to || from === to) return null;

  if (kind === "RELATED") {
    const [a, b] = canonicalRelatedPair(from, to);
    return { from: a, to: b, kind };
  }
  return { from, to, kind };
}

export async function POST(req: Request) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const link = await resolveLink(await req.json());
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

  const link = await resolveLink(await req.json());
  if (!link) return NextResponse.json({ error: "Invalid link" }, { status: 400 });

  await db.courseLink.deleteMany({
    where: { fromCourseId: link.from, toCourseId: link.to, kind: link.kind },
  });
  return NextResponse.json({ ok: true });
}
