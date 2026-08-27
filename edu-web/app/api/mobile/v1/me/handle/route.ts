import { db } from "@/lib/db";
import { withUser } from "@/lib/mobile/guard";
import { ok, badRequest } from "@/lib/mobile/respond";
import { validateHandle } from "@/lib/gamification/handle";

// Set the student's public handle — the mobile twin of the web dashboard's
// setHandle server action. Deliberately reuses validateHandle (length, charset,
// reserved names, profanity) and the same case-insensitive uniqueness check, so
// the app cannot let through a handle the web would refuse. The handle is the only
// name shown in the Hall of Scholars, which is why it's gated at all.
export async function PUT(req: Request) {
  return withUser(req, async (userId) => {
    const body = (await req.json().catch(() => ({}))) as { handle?: string };

    const check = validateHandle(String(body.handle ?? ""));
    if (!check.ok) return badRequest(check.error);

    const taken = await db.user.findFirst({
      where: { handle: { equals: check.value, mode: "insensitive" }, NOT: { id: userId } },
      select: { id: true },
    });
    if (taken) return badRequest("That handle is already taken.");

    const user = await db.user.update({
      where: { id: userId },
      data: { handle: check.value },
      select: { id: true, name: true, email: true, handle: true },
    });
    return ok({ user });
  });
}
