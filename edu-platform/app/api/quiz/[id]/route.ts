import { NextResponse } from "next/server";
import { db } from "@/lib/db";

function isAdmin(req: Request) {
  return req.headers.get("x-admin-password") === process.env.ADMIN_PASSWORD;
}

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  if (!isAdmin(req)) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

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

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  if (!isAdmin(req)) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  await db.quizQuestion.delete({ where: { id } });
  return NextResponse.json({ deleted: true });
}
