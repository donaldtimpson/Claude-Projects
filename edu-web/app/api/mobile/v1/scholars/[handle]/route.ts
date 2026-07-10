import { getScholarByHandle } from "@/lib/gamification/engine";
import { ok, fail } from "@/lib/mobile/respond";

export async function GET(
  _req: Request,
  { params }: { params: Promise<{ handle: string }> },
) {
  const { handle } = await params;
  const scholar = await getScholarByHandle(handle);
  if (!scholar) return fail(404, "Scholar not found.");
  return ok({ scholar });
}
