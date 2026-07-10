import { rotateRefreshToken } from "@/lib/mobile-auth";
import { ok, fail, badRequest } from "@/lib/mobile/respond";

export async function POST(req: Request) {
  let body: { refreshToken?: string };
  try {
    body = await req.json();
  } catch {
    return badRequest();
  }
  if (!body.refreshToken) return badRequest("refreshToken is required.");
  const pair = await rotateRefreshToken(body.refreshToken);
  if (!pair) return fail(401, "Invalid or expired refresh token.");
  return ok(pair);
}
