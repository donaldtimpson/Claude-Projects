import bcrypt from "bcryptjs";
import { Prisma } from "@prisma/client";
import { db } from "@/lib/db";

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export type CreateUserResult =
  | { ok: true; userId: string }
  | { ok: false; status: number; error: string };

// Shared registration used by BOTH the web signup route
// (app/api/auth/signup) and the mobile register endpoint. Validation, email
// normalization, bcrypt hashing, and the unique-email race (P2002) live here
// once. Returns a discriminated result so each caller shapes its own response.
export async function createUser(input: {
  name?: unknown;
  email?: unknown;
  password?: unknown;
}): Promise<CreateUserResult> {
  const { name, email, password } = input;

  if (!name || !email || !password) {
    return { ok: false, status: 400, error: "All fields are required." };
  }
  if (typeof password !== "string" || password.length < 8) {
    return { ok: false, status: 400, error: "Password must be at least 8 characters." };
  }

  const normalizedEmail = typeof email === "string" ? email.trim().toLowerCase() : "";
  if (!EMAIL_REGEX.test(normalizedEmail)) {
    return { ok: false, status: 400, error: "Please enter a valid email address." };
  }

  const existing = await db.user.findUnique({ where: { email: normalizedEmail } });
  if (existing) {
    return { ok: false, status: 409, error: "An account with that email already exists." };
  }

  const hashed = await bcrypt.hash(password, 12);
  try {
    const user = await db.user.create({
      data: { name: String(name), email: normalizedEmail, password: hashed },
    });
    return { ok: true, userId: user.id };
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002") {
      return { ok: false, status: 409, error: "An account with that email already exists." };
    }
    throw err;
  }
}
