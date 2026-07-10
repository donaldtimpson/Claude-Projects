import { applyReviewGrade } from "@/lib/srs";
import { withUser } from "@/lib/mobile/guard";
import { withIdempotency } from "@/lib/mobile/idempotency";
import { ok, badRequest } from "@/lib/mobile/respond";

export async function POST(req: Request) {
  return withUser(req, async (userId) => {
    let body: { questionId?: string; correct?: boolean; clientId?: string };
    try {
      body = await req.json();
    } catch {
      return badRequest();
    }
    if (!body.questionId || typeof body.correct !== "boolean") {
      return badRequest("questionId and correct are required.");
    }

    // applyReviewGrade increments reps, so an offline replay must be deduped.
    const { duplicate } = await withIdempotency(userId, body.clientId, "review-grade", () =>
      applyReviewGrade(userId, body.questionId!, body.correct!),
    );
    return ok({ duplicate });
  });
}
