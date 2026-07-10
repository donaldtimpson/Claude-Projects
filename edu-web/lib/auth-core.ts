import bcrypt from "bcryptjs";
import { db } from "@/lib/db";

export type VerifiedUser = { id: string; name: string | null; email: string };

// Shared credential check used by BOTH transports: the web NextAuth
// CredentialsProvider (lib/auth.ts, cookie session) and the native mobile login
// endpoint (app/api/mobile/v1/auth/login, Bearer JWT). One bcrypt path, one User
// store — so a password works identically on web and mobile.
export async function verifyCredentials(
  email: string | undefined | null,
  password: string | undefined | null,
): Promise<VerifiedUser | null> {
  if (!email || !password) return null;
  const normalized = email.trim().toLowerCase();
  const user = await db.user.findUnique({ where: { email: normalized } });
  if (!user || !user.password) return null; // Apple-only accounts have no password
  const valid = await bcrypt.compare(password, user.password);
  if (!valid) return null;
  return { id: user.id, name: user.name, email: user.email };
}
