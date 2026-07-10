import { getDueDeck, getDueCount } from "@/lib/srs";
import { withUser } from "@/lib/mobile/guard";
import { ok } from "@/lib/mobile/respond";

// Today's cross-course spaced-repetition deck (most overdue first, capped).
export async function GET(req: Request) {
  return withUser(req, async (userId) => {
    const [cards, dueCount] = await Promise.all([getDueDeck(userId), getDueCount(userId)]);
    return ok({ cards, dueCount });
  });
}
