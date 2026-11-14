import { withUser } from "@/lib/mobile/guard";
import { ok, fail } from "@/lib/mobile/respond";
import { getClassHubFor } from "@/lib/class-hub";

// One class, as the app's class screen shows it: grade breakdown, custom
// category items, homework (open first), and quiz/test bests. Same 404 for an
// unknown section and one the caller isn't in.
export async function GET(
  req: Request,
  { params }: { params: Promise<{ sectionId: string }> },
) {
  return withUser(req, async (userId) => {
    const { sectionId } = await params;
    const hub = await getClassHubFor(sectionId, userId);
    if (!hub) return fail(404, "Class not found.");
    return ok(hub);
  });
}
