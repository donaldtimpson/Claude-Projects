import type { NextResponse } from "next/server";
import { requireMobileUser } from "@/lib/mobile-auth";
import { unauthorized } from "@/lib/mobile/respond";

// Wrap a protected mobile handler: resolves the Bearer-token user or returns 401.
export async function withUser(
  req: Request,
  handler: (userId: string) => Promise<NextResponse>,
): Promise<NextResponse> {
  const userId = await requireMobileUser(req);
  if (!userId) return unauthorized();
  return handler(userId);
}
