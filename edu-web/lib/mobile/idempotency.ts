import { Prisma } from "@prisma/client";
import { db } from "@/lib/db";

// Guard an offline-replayable write. The mobile app tags each queued mutation
// with a stable clientId; when it replays the queue on reconnect this ensures the
// work runs at most once — a replay can't double-insert a quiz attempt or
// double-count a review rep.
//
// Best-effort semantics: the key is recorded BEFORE the work runs, so a crash
// between the two blocks a later replay of that exact clientId. Acceptable for
// v1 — the client surfaces the error and the user retries the action (with a new
// clientId) if needed. Callers with no clientId (e.g. live online writes) run
// unguarded.
export async function withIdempotency<T>(
  userId: string,
  clientId: string | null | undefined,
  scope: string,
  fn: () => Promise<T>,
): Promise<{ duplicate: boolean; result: T | null }> {
  if (!clientId) {
    return { duplicate: false, result: await fn() };
  }
  try {
    await db.idempotencyKey.create({ data: { key: clientId, userId, scope } });
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002") {
      return { duplicate: true, result: null };
    }
    throw err;
  }
  return { duplicate: false, result: await fn() };
}
