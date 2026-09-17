import { cookies } from "next/headers";

export function checkAdminPassword(password: string | null): boolean {
  const expected = process.env.ADMIN_PASSWORD;
  if (!expected || !password) return false;
  return password === expected;
}

// Guard for admin-only server actions: throws "Unauthorized" unless the caller
// carries a valid admin_auth cookie. Shared by every admin server-action module.
export async function assertAdmin(): Promise<void> {
  const store = await cookies();
  if (!checkAdminPassword(store.get("admin_auth")?.value ?? null)) {
    throw new Error("Unauthorized");
  }
}
