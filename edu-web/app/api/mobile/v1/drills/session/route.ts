import { withUser } from "@/lib/mobile/guard";
import { withIdempotency } from "@/lib/mobile/idempotency";
import { recordDrillSessionFor } from "@/lib/services/activity";
import { ok, badRequest } from "@/lib/mobile/respond";
import type { DrillSummary } from "@/lib/drills";

export async function POST(req: Request) {
  return withUser(req, async (userId) => {
    let body: Partial<DrillSummary> & { clientId?: string };
    try {
      body = await req.json();
    } catch {
      return badRequest();
    }
    const { slug, level, total, correct, bestStreak, mode, durationSec, clientId } = body;
    if (
      typeof slug !== "string" ||
      typeof level !== "number" ||
      typeof total !== "number" ||
      typeof correct !== "number" ||
      typeof bestStreak !== "number" ||
      (mode !== "count" && mode !== "timed") ||
      typeof durationSec !== "number"
    ) {
      return badRequest("Invalid drill summary.");
    }

    const summary: DrillSummary = { slug, level, total, correct, bestStreak, mode, durationSec };
    const { duplicate, result } = await withIdempotency(userId, clientId, "drill-session", () =>
      recordDrillSessionFor(userId, summary),
    );
    return ok({ duplicate, badges: result ?? [] });
  });
}
