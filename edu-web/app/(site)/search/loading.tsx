// Shown instantly while the /search server query runs (route-level Suspense),
// so navigating to the full results page never looks frozen.
export default function Loading() {
  return (
    <main className="flex-1">
      <div className="mx-auto max-w-5xl px-6 py-8 space-y-6">
        <div className="h-7 w-56 animate-pulse rounded bg-crimson-800" />
        <div className="space-y-2">
          {Array.from({ length: 5 }).map((_, i) => (
            <div
              key={i}
              className="h-16 animate-pulse rounded-xl border border-crimson-700 bg-crimson-900"
            />
          ))}
        </div>
      </div>
    </main>
  );
}
