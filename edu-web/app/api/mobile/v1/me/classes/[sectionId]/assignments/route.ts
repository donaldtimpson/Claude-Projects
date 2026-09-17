import { withUser } from "@/lib/mobile/guard";
import { ok, fail } from "@/lib/mobile/respond";
import { getSectionAssignmentsFor } from "@/lib/assignments-data";

// A class's homework for the enrolled student — the mobile half of the web class
// hub's Homework section. The query, title fallback, and solution-visibility rules
// live in getSectionAssignmentsFor so the app and web can never diverge.
//
// getSectionAssignmentsFor returns null both when the section is missing and when
// the caller isn't an active enrollee, so a non-member can't tell an unknown
// section from one they're simply not in — a 404 for both.
export async function GET(
  req: Request,
  { params }: { params: Promise<{ sectionId: string }> },
) {
  return withUser(req, async (userId) => {
    const { sectionId } = await params;
    const data = await getSectionAssignmentsFor(sectionId, userId);
    if (!data) return fail(404, "Class not found.");
    return ok(data);
  });
}
