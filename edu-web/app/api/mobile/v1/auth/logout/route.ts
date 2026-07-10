import { revokeRefreshToken } from "@/lib/mobile-auth";
import { ok } from "@/lib/mobile/respond";

export async function POST(req: Request) {
  const body = await req.json().catch(() => ({}) as { refreshToken?: string });
  if (body?.refreshToken) await revokeRefreshToken(body.refreshToken);
  return ok({ ok: true });
}
