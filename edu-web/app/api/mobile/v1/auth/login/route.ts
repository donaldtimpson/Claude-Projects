import { verifyCredentials } from "@/lib/auth-core";
import { issueTokenPair } from "@/lib/mobile-auth";
import { ok, fail, badRequest } from "@/lib/mobile/respond";
import { rateLimit, clientIp } from "@/lib/mobile/rate-limit";

export async function POST(req: Request) {
  if (!rateLimit(`login:${clientIp(req)}`, 10, 60_000)) {
    return fail(429, "Too many attempts. Please try again in a minute.");
  }
  let body: { email?: string; password?: string };
  try {
    body = await req.json();
  } catch {
    return badRequest();
  }
  const user = await verifyCredentials(body.email, body.password);
  // Generic message — never reveal whether the email exists.
  if (!user) return fail(401, "Invalid email or password.");
  const tokens = await issueTokenPair(user.id);
  return ok({ user, ...tokens });
}
