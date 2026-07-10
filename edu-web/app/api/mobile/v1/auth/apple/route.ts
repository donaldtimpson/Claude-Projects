import { Prisma } from "@prisma/client";
import { db } from "@/lib/db";
import { verifyAppleIdentityToken } from "@/lib/apple-auth";
import { issueTokenPair } from "@/lib/mobile-auth";
import { ok, fail, badRequest } from "@/lib/mobile/respond";
import { rateLimit, clientIp } from "@/lib/mobile/rate-limit";

type Body = {
  identityToken?: string;
  fullName?: { givenName?: string | null; familyName?: string | null };
};

export async function POST(req: Request) {
  if (!rateLimit(`apple:${clientIp(req)}`, 20, 60_000)) {
    return fail(429, "Too many attempts. Please try again in a minute.");
  }
  let body: Body;
  try {
    body = await req.json();
  } catch {
    return badRequest();
  }
  if (!body.identityToken) return badRequest("identityToken is required.");

  const identity = await verifyAppleIdentityToken(body.identityToken);
  if (!identity) return fail(401, "Could not verify your Apple sign-in.");

  const email = identity.email?.trim().toLowerCase();

  // 1) Returning Apple user (matched by stable Apple id).
  let user = await db.user.findUnique({ where: { appleUserId: identity.sub } });

  // 2) Link to an existing account when Apple gives us a matching verified email.
  if (!user && email && identity.emailVerified) {
    const existing = await db.user.findUnique({ where: { email } });
    if (existing) {
      user = await db.user.update({
        where: { id: existing.id },
        data: { appleUserId: identity.sub },
      });
    }
  }

  // 3) Otherwise create a fresh (passwordless) account.
  if (!user) {
    if (!email) {
      return fail(400, "Apple didn't share an email, so we can't create an account. Sign up with email instead.");
    }
    const name = [body.fullName?.givenName, body.fullName?.familyName].filter(Boolean).join(" ") || null;
    try {
      user = await db.user.create({
        data: { email, name, appleUserId: identity.sub, password: null },
      });
    } catch (err) {
      // Race: the email was just created — link to it instead.
      if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002") {
        const existing = await db.user.findUnique({ where: { email } });
        if (existing) {
          user = await db.user.update({
            where: { id: existing.id },
            data: { appleUserId: identity.sub },
          });
        }
      }
      if (!user) throw err;
    }
  }

  const tokens = await issueTokenPair(user.id);
  return ok({
    user: { id: user.id, name: user.name, email: user.email, handle: user.handle },
    ...tokens,
  });
}
