import { finishDailyReviewFor } from "@/lib/services/activity";
import { withUser } from "@/lib/mobile/guard";
import { ok } from "@/lib/mobile/respond";

export async function POST(req: Request) {
  return withUser(req, async (userId) => {
    const badges = await finishDailyReviewFor(userId);
    return ok({ badges });
  });
}
