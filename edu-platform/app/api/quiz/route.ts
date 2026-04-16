import { NextResponse } from "next/server";
import { db } from "@/lib/db";

function isAdmin(req: Request) {
  return req.headers.get("x-admin-password") === process.env.ADMIN_PASSWORD;
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const videoId = searchParams.get("videoId");
  const courseId = searchParams.get("courseId");

  const questions = await db.quizQuestion.findMany({
    where: { videoId: videoId ?? undefined, courseId: courseId ?? undefined },
    orderBy: { position: "asc" },
  });
  return NextResponse.json(questions);
}

export async function POST(req: Request) {
  if (!isAdmin(req)) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const body = await req.json();
  const { videoId, courseId, prompt, options, correctIndex, explanation, position } = body;

  if (!prompt || !options || correctIndex == null || (!videoId && !courseId)) {
    return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
  }

  const question = await db.quizQuestion.create({
    data: { videoId, courseId, prompt, options, correctIndex, explanation: explanation ?? "", position: position ?? 0 },
  });
  return NextResponse.json(question, { status: 201 });
}
