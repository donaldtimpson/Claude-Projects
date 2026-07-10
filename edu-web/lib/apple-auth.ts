import { createRemoteJWKSet, jwtVerify } from "jose";

// Verifies an "Sign in with Apple" identity token (a JWT signed by Apple).
// jose caches Apple's public keys (JWKS) between calls.
const APPLE_JWKS = createRemoteJWKSet(new URL("https://appleid.apple.com/auth/keys"));

// The token's `aud` is the app's bundle id for a native app. Override via
// APPLE_CLIENT_ID if the bundle id ever changes.
const AUDIENCE = process.env.APPLE_CLIENT_ID || "com.timpsonlyceum.Lyceum";

export type AppleIdentity = {
  sub: string; // stable per-user Apple id
  email?: string;
  emailVerified: boolean;
};

export async function verifyAppleIdentityToken(token: string): Promise<AppleIdentity | null> {
  try {
    const { payload } = await jwtVerify(token, APPLE_JWKS, {
      issuer: "https://appleid.apple.com",
      audience: AUDIENCE,
    });
    if (typeof payload.sub !== "string") return null;
    const verified = payload.email_verified;
    return {
      sub: payload.sub,
      email: typeof payload.email === "string" ? payload.email : undefined,
      emailVerified: verified === true || verified === "true",
    };
  } catch {
    return null;
  }
}
