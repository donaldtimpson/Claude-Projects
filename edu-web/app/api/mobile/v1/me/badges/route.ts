import { getUserBadges } from "@/lib/gamification/engine";
import { withUser } from "@/lib/mobile/guard";
import { ok } from "@/lib/mobile/respond";

export async function GET(req: Request) {
  return withUser(req, async (userId) => {
    const badges = await getUserBadges(userId);
    return ok({ badges });
  });
}
