import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { requireMobileUser } from "@/lib/mobile-auth";

// Dual-transport current-user accessor. Tries the mobile Bearer token first
// (when a Request is available), then falls back to the NextAuth cookie session.
// Use this in a handler you want to serve BOTH web and mobile from one route
// (e.g. comments). Mobile-only routes can call requireMobileUser directly.
export async function getUserId(req?: Request): Promise<string | null> {
  if (req) {
    const fromBearer = await requireMobileUser(req);
    if (fromBearer) return fromBearer;
  }
  const session = await getServerSession(authOptions);
  return session?.user?.id ?? null;
}
