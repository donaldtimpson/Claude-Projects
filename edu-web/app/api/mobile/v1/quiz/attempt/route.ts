import { withUser } from "@/lib/mobile/guard";
import { withIdempotency } from "@/lib/mobile/idempotency";
import { recordQuizAttemptFor } from "@/lib/services/activity";
import { ok, badRequest } from "@/lib/mobile/respond";

type Body = {
  videoId?: string | null;
  courseId?: string | null;
  score?: number;
  total?: number;
  answers?: (number | null)[];
  clientId?: string;
};

export async function POST(req: Request) {
  return withUser(req, async (userId) => {
    let body: Body;
    try {
      body = await req.json();
    } catch {
      return badRequest();
    }
    const { videoId = null, courseId = null, score, total, answers, clientId } = body;
    if (
      typeof score !== "number" ||
      typeof total !== "number" ||
      !Array.isArray(answers) ||
      (videoId == null && courseId == null)
    ) {
      return badRequest("score, total, answers and a videoId or courseId are required.");
    }

    const { duplicate, result } = await withIdempotency(userId, clientId, "quiz-attempt", () =>
      recordQuizAttemptFor(userId, { videoId, courseId, score, total, answers }),
    );
    return ok({ duplicate, badges: result ?? [] });
  });
}
