import { withUser } from "@/lib/mobile/guard";
import { ok, fail, badRequest } from "@/lib/mobile/respond";
import { submitAssignmentFor } from "@/lib/assignments-data";

type Body = { url?: string };

// Submit a solution link to a homework assignment — the mobile counterpart of the
// web submitAssignment action. Validation, enrollment authorization, and the
// (url + submittedAt only) upsert all run in submitAssignmentFor, shared with the
// web action so the rules stay identical. Score / feedback / gradedAt are the
// instructor's and are never touched here.
export async function POST(
  req: Request,
  { params }: { params: Promise<{ assignmentId: string }> },
) {
  return withUser(req, async (userId) => {
    const { assignmentId } = await params;

    let body: Body;
    try {
      body = await req.json();
    } catch {
      return badRequest();
    }
    if (typeof body.url !== "string") {
      return badRequest("url is required.");
    }

    const result = await submitAssignmentFor(assignmentId, userId, body.url);
    if (!result.ok) return fail(result.status, result.error);
    return ok({ submission: result.submission });
  });
}
