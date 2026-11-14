import { withUser } from "@/lib/mobile/guard";
import { ok, fail, badRequest } from "@/lib/mobile/respond";
import { registerWithCode } from "@/lib/class-hub";

type Body = { code?: string };

// Register for a live class with its join code (the web RegisterForm's
// counterpart; both run registerWithCode).
export async function POST(req: Request) {
  return withUser(req, async (userId) => {
    let body: Body;
    try {
      body = await req.json();
    } catch {
      return badRequest();
    }
    if (typeof body.code !== "string") return badRequest("code is required.");
    const result = await registerWithCode(userId, body.code);
    if (!result.ok) return fail(400, result.error);
    return ok(result);
  });
}
