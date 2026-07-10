// Best-effort in-memory rate limiter for the auth endpoints.
//
// NOTE: this is per-instance state. In serverless (multiple warm Lambdas) it is
// NOT shared, so it's a speed bump against casual brute force, not a hard
// guarantee. Harden with Upstash Ratelimit or a Postgres-backed counter before
// relying on it in anger. Paired with generic auth errors (no user enumeration),
// it's a reasonable v1 baseline.

type Bucket = { count: number; resetAt: number };
const buckets = new Map<string, Bucket>();

// Returns true if the call is allowed, false if the limit is exceeded.
export function rateLimit(key: string, limit: number, windowMs: number): boolean {
  const now = Date.now();
  const b = buckets.get(key);
  if (!b || b.resetAt < now) {
    buckets.set(key, { count: 1, resetAt: now + windowMs });
    return true;
  }
  if (b.count >= limit) return false;
  b.count += 1;
  return true;
}

export function clientIp(req: Request): string {
  const fwd = req.headers.get("x-forwarded-for");
  if (fwd) return fwd.split(",")[0]!.trim();
  return req.headers.get("x-real-ip") || "unknown";
}
