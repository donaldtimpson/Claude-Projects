import { withUser } from "@/lib/mobile/guard";
import { withIdempotency } from "@/lib/mobile/idempotency";
import { markVideoWatchedFor } from "@/lib/services/activity";
import { ok, badRequest } from "@/lib/mobile/respond";

export async function POST(req: Request) {
  return withUser(req, async (userId) => {
    let body: { videoId?: string; clientId?: string };
    try {
      body = await req.json();
    } catch {
      return badRequest();
    }
    if (!body.videoId) return badRequest("videoId is required.");

    // markVideoWatchedFor is an upsert (already idempotent); the key still short-
    // circuits a replay so we skip the achievement re-sync work.
    const { duplicate, result } = await withIdempotency(userId, body.clientId, "video-watched", () =>
      markVideoWatchedFor(userId, body.videoId!),
    );
    return ok({ duplicate, badges: result ?? [] });
  });
}
