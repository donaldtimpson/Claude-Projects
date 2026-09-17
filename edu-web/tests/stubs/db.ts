// Test stub for `@/lib/db`. The real module constructs a Prisma client + Neon
// adapter, which needs DATABASE_URL and a live connection. None of the pure
// helpers under test touch the DB, but they live in modules that import it at
// top level, so this stand-in lets those modules load. Any accidental query
// throws loudly rather than silently returning undefined.
const trap = new Proxy(
  {},
  {
    get() {
      throw new Error("tests/stubs/db.ts: unexpected Prisma access in a pure-logic test");
    },
  },
);

export const db = trap as unknown as Record<string, unknown>;
