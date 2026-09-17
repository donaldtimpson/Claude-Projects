import { describe, it, expect, vi, beforeEach } from "vitest";

// Controllable Prisma stand-in for withIdempotency. We override `@/lib/db`'s
// `db.idempotencyKey.create` per test; the vitest alias already redirects
// `@/lib/db`, and vi.mock replaces it wholesale with this factory.
const createMock = vi.fn();
vi.mock("@/lib/db", () => ({
  db: { idempotencyKey: { create: (...args: unknown[]) => createMock(...args) } },
}));

import { Prisma } from "@prisma/client";
import { withIdempotency } from "@/lib/mobile/idempotency";

// A P2002 (unique constraint) error like Prisma throws on a duplicate key.
function p2002(): Prisma.PrismaClientKnownRequestError {
  return new Prisma.PrismaClientKnownRequestError("Unique constraint failed", {
    code: "P2002",
    clientVersion: "test",
  });
}

beforeEach(() => {
  createMock.mockReset();
});

describe("withIdempotency", () => {
  it("with no clientId, runs the work unguarded (no key recorded)", async () => {
    const fn = vi.fn().mockResolvedValue("done");
    const out = await withIdempotency("u1", null, "quiz", fn);
    expect(out).toEqual({ duplicate: false, result: "done" });
    expect(fn).toHaveBeenCalledOnce();
    expect(createMock).not.toHaveBeenCalled();
  });

  it("with undefined clientId, also runs unguarded", async () => {
    const fn = vi.fn().mockResolvedValue(7);
    const out = await withIdempotency("u1", undefined, "quiz", fn);
    expect(out).toEqual({ duplicate: false, result: 7 });
    expect(createMock).not.toHaveBeenCalled();
  });

  it("first use of a clientId records the key then runs the work", async () => {
    createMock.mockResolvedValue({});
    const fn = vi.fn().mockResolvedValue("result-1");
    const out = await withIdempotency("u1", "client-abc", "review", fn);

    expect(createMock).toHaveBeenCalledWith({
      data: { key: "client-abc", userId: "u1", scope: "review" },
    });
    expect(fn).toHaveBeenCalledOnce();
    expect(out).toEqual({ duplicate: false, result: "result-1" });
  });

  it("a replayed clientId (P2002 on create) is a duplicate — work does NOT run", async () => {
    createMock.mockRejectedValue(p2002());
    const fn = vi.fn().mockResolvedValue("should-not-run");
    const out = await withIdempotency("u1", "client-abc", "review", fn);

    expect(out).toEqual({ duplicate: true, result: null });
    expect(fn).not.toHaveBeenCalled();
  });

  it("records the key BEFORE running the work (crash-safety ordering)", async () => {
    const order: string[] = [];
    createMock.mockImplementation(async () => {
      order.push("create");
    });
    const fn = vi.fn().mockImplementation(async () => {
      order.push("work");
      return 1;
    });
    await withIdempotency("u1", "c1", "s", fn);
    expect(order).toEqual(["create", "work"]);
  });

  it("a non-P2002 error propagates (not swallowed as a duplicate)", async () => {
    createMock.mockRejectedValue(new Error("connection lost"));
    const fn = vi.fn();
    await expect(withIdempotency("u1", "c1", "s", fn)).rejects.toThrow("connection lost");
    expect(fn).not.toHaveBeenCalled();
  });
});
