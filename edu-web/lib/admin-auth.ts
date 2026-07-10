export function checkAdminPassword(password: string | null): boolean {
  const expected = process.env.ADMIN_PASSWORD;
  if (!expected || !password) return false;
  return password === expected;
}
