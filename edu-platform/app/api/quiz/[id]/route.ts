import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { db } from "@/lib/db";

async function isAdmin() {
  const cookieStore = await cookies();
  return cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;
}

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  if (!await isAdmin()) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const [body, { id }] = await Promise.all([req.json(), params]);
  const { prompt, options, correctIndex, explanation, position } = body;

  const question = await db.quizQuestion.update({
    where: { id },
    data: {
      ...(prompt != null && { prompt }),
      ...(options != null && { options }),
      ...(correctIndex != null && { correctIndex }),
      ...(explanation != null && { explanation }),
      ...(position != null && { position }),
    },
  });
  return NextResponse.json(question);
}

export async function DELETE(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  if (!await isAdmin()) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  await db.quizQuestion.delete({ where: { id } });
  return NextResponse.json({ deleted: true });
}
