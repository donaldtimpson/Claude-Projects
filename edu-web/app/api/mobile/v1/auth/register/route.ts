import { createUser } from "@/lib/users";
import { issueTokenPair } from "@/lib/mobile-auth";
import { db } from "@/lib/db";
import { ok, fail, badRequest } from "@/lib/mobile/respond";
import { rateLimit, clientIp } from "@/lib/mobile/rate-limit";

export async function POST(req: Request) {
  if (!rateLimit(`register:${clientIp(req)}`, 5, 60_000)) {
    return fail(429, "Too many attempts. Please try again in a minute.");
  }
  let body: { name?: string; email?: string; password?: string };
  try {
    body = await req.json();
  } catch {
    return badRequest();
  }
  const result = await createUser(body);
  if (!result.ok) return fail(result.status, result.error);

  // Auto-login the new account so the app lands signed in.
  const user = await db.user.findUnique({
    where: { id: result.userId },
    select: { id: true, name: true, email: true },
  });
  const tokens = await issueTokenPair(result.userId);
  return ok({ user, ...tokens }, { status: 201 });
}
