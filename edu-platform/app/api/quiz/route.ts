import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { db } from "@/lib/db";

async function isAdmin() {
  const cookieStore = await cookies();
  return cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const videoId = searchParams.get("videoId");
  const courseId = searchParams.get("courseId");
  const includeDrafts = searchParams.get("includeDrafts") === "true" && await isAdmin();

  const questions = await db.quizQuestion.findMany({
    where: {
      videoId: videoId ?? undefined,
      courseId: courseId ?? undefined,
      ...(includeDrafts ? {} : { isDraft: false }),
    },
    orderBy: { position: "asc" },
  });
  return NextResponse.json(questions);
}

export async function POST(req: Request) {
  if (!await isAdmin()) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const body = await req.json();
  const { videoId, courseId, prompt, options, correctIndex, explanation, position, isDraft } = body;

  if (!prompt || !options || correctIndex == null || (!videoId && !courseId)) {
    return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
  }

  const question = await db.quizQuestion.create({
    data: {
      videoId,
      courseId,
      prompt,
      options,
      correctIndex,
      explanation: explanation ?? "",
      position: position ?? 0,
      isDraft: isDraft ?? false,
    },
  });
  return NextResponse.json(question, { status: 201 });
}
