// Recently-opened drills, for the hub's "Continue" strip — the web counterpart of the
// iOS @AppStorage("drill_recents") list. Same shape: most-recent-first slugs, capped at
// 5, stored as CSV. Device-local by design (it is a convenience, not progress; the real
// progress signal is the server-derived ✦ from lib/lessons.ts).

const KEY = "drill_recents";
const MAX = 5;

/** Most-recent-first drill slugs. Returns [] on the server or when storage is unavailable. */
export function readRecents(): string[] {
  return getRecentsSnapshot().split(",").filter(Boolean).slice(0, MAX);
}

/** Move `slug` to the front of the list. Called when a drill session opens. */
export function recordRecent(slug: string): void {
  if (typeof window === "undefined") return;
  try {
    const next = [slug, ...readRecents().filter((s) => s !== slug)].slice(0, MAX);
    window.localStorage.setItem(KEY, next.join(","));
    emit();
  } catch {
    // ignore — a missing recents list is not worth failing a drill over
  }
}

// ---- useSyncExternalStore plumbing -----------------------------------------
// The hub reads this through useSyncExternalStore rather than an effect: the server
// snapshot is empty (no storage during SSR) and the client snapshot is the real CSV,
// so React renders the empty strip first and swaps it in without a hydration mismatch.
// The snapshot is the raw CSV *string* — a stable value React can compare by identity,
// unlike a freshly-built array, which would loop forever.

const listeners = new Set<() => void>();

function emit() {
  for (const l of listeners) l();
}

export function subscribeRecents(onChange: () => void): () => void {
  listeners.add(onChange);
  // `storage` fires for OTHER tabs; recordRecent's emit() covers this one.
  const onStorage = (e: StorageEvent) => {
    if (e.key === KEY) onChange();
  };
  window.addEventListener("storage", onStorage);
  return () => {
    listeners.delete(onChange);
    window.removeEventListener("storage", onStorage);
  };
}

export function getRecentsSnapshot(): string {
  if (typeof window === "undefined") return "";
  try {
    return window.localStorage.getItem(KEY) ?? "";
  } catch {
    return ""; // private mode / storage disabled — the strip just stays hidden
  }
}

export function getRecentsServerSnapshot(): string {
  return "";
}
