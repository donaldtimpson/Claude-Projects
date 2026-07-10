import { SignJWT, jwtVerify } from "jose";
import { randomBytes, createHash } from "node:crypto";
import { db } from "@/lib/db";

// Token-based auth for the native app (apps/mobile). Parallel to NextAuth's
// cookie session (web) — same User store, different transport. Access tokens are
// short-lived stateless HS256 JWTs; refresh tokens are opaque random strings
// stored only as a sha256 hash (revocable, rotated on use).

const ACCESS_TTL = "1h";
const ACCESS_TTL_SECONDS = 3600;
const REFRESH_TTL_DAYS = 60;
const REFRESH_TTL_MS = REFRESH_TTL_DAYS * 86_400_000;

function secret(): Uint8Array {
  // Prefer a dedicated secret so mobile keys can rotate without logging out web;
  // fall back to NEXTAUTH_SECRET so a single-secret setup still works.
  const s = process.env.MOBILE_JWT_SECRET || process.env.NEXTAUTH_SECRET;
  if (!s) throw new Error("MOBILE_JWT_SECRET (or NEXTAUTH_SECRET) must be set");
  return new TextEncoder().encode(s);
}

export async function signAccessToken(userId: string): Promise<string> {
  return new SignJWT({})
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(userId)
    .setIssuedAt()
    .setExpirationTime(ACCESS_TTL)
    .sign(secret());
}

export async function verifyAccessToken(token: string): Promise<string | null> {
  try {
    const { payload } = await jwtVerify(token, secret());
    return typeof payload.sub === "string" ? payload.sub : null;
  } catch {
    return null;
  }
}

function bearerToken(req: Request): string | null {
  const h = req.headers.get("authorization");
  if (!h || !h.startsWith("Bearer ")) return null;
  const token = h.slice("Bearer ".length).trim();
  return token || null;
}

// Resolve the current mobile user from the Authorization: Bearer header. Returns
// the userId, or null if missing/invalid/expired. Every protected mobile route
// calls this at the top.
export async function requireMobileUser(req: Request): Promise<string | null> {
  const token = bearerToken(req);
  if (!token) return null;
  return verifyAccessToken(token);
}

function hashRefresh(raw: string): string {
  return createHash("sha256").update(raw).digest("hex");
}

export type TokenPair = {
  accessToken: string;
  refreshToken: string;
  expiresIn: number; // access-token lifetime in seconds
};

// Mint a new access+refresh pair and persist the refresh token's hash.
export async function issueTokenPair(userId: string): Promise<TokenPair> {
  const accessToken = await signAccessToken(userId);
  const refreshToken = randomBytes(32).toString("hex");
  await db.mobileRefreshToken.create({
    data: {
      userId,
      tokenHash: hashRefresh(refreshToken),
      expiresAt: new Date(Date.now() + REFRESH_TTL_MS),
    },
  });
  return { accessToken, refreshToken, expiresIn: ACCESS_TTL_SECONDS };
}

// Rotate: consume the presented refresh token (one-time use) and issue a fresh
// pair. Returns null if the token is unknown or expired.
export async function rotateRefreshToken(raw: string): Promise<TokenPair | null> {
  const tokenHash = hashRefresh(raw);
  const row = await db.mobileRefreshToken.findUnique({ where: { tokenHash } });
  if (!row) return null;
  // Delete first — a refresh token is single-use, valid or not.
  await db.mobileRefreshToken.delete({ where: { tokenHash } }).catch(() => {});
  if (row.expiresAt.getTime() < Date.now()) return null;
  return issueTokenPair(row.userId);
}

// Logout: drop the presented refresh token so it can't be rotated again.
export async function revokeRefreshToken(raw: string): Promise<void> {
  await db.mobileRefreshToken.deleteMany({ where: { tokenHash: hashRefresh(raw) } });
}
