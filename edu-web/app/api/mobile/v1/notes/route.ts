import { db } from "@/lib/db";
import { ok, badRequest } from "@/lib/mobile/respond";

export async function GET(req: Request) {
  const videoId = new URL(req.url).searchParams.get("videoId");
  if (!videoId) return badRequest("videoId is required.");
  const note = await db.lectureNote.findFirst({
    where: { videoId, isDraft: false },
    select: { content: true, updatedAt: true },
  });
  return ok({ note });
}
