import { recordReviewClearedFor } from "@/lib/services/activity";
import { withUser } from "@/lib/mobile/guard";
import { ok } from "@/lib/mobile/respond";

// Award path for finishing a full course-review session (mirrors the web
// recordReviewCleared server action).
export async function POST(
  req: Request,
  { params }: { params: Promise<{ courseId: string }> },
) {
  return withUser(req, async (userId) => {
    const { courseId } = await params;
    const body = await req.json().catch(() => ({}) as { perfect?: boolean });
    const badges = await recordReviewClearedFor(userId, courseId, !!body?.perfect);
    return ok({ badges });
  });
}
