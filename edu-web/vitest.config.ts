import { defineConfig } from "vitest/config";
import { fileURLToPath } from "node:url";

// Pure-logic unit tests. Node environment (no DOM); the `@/` alias mirrors
// tsconfig's paths. Anything that imports the Prisma client (`@/lib/db`) is
// redirected to a stub so tests never need a live database — we test the pure
// helpers in isolation.
export default defineConfig({
  test: {
    environment: "node",
    include: ["tests/**/*.test.ts"],
  },
  resolve: {
    alias: {
      "@/lib/db": fileURLToPath(new URL("./tests/stubs/db.ts", import.meta.url)),
      "@": fileURLToPath(new URL("./", import.meta.url)),
    },
  },
});
