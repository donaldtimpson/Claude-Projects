// Hall of Aces — pseudonymous handles of everyone who scored 100% on this
// lecture's quiz. Always shown; celebrates perfect scores and invites others.

const CAP = 24;

export default function QuizAces({
  acers,
  myUserId,
}: {
  acers: { userId: string; handle: string }[];
  myUserId?: string | null;
}) {
  const total = acers.length;

  // Always include "you" even if the list is capped.
  let shown = acers.slice(0, CAP);
  const mine = myUserId ? acers.find((a) => a.userId === myUserId) : undefined;
  if (mine && !shown.some((a) => a.userId === myUserId)) {
    shown = [mine, ...shown.slice(0, CAP - 1)];
  }
  const more = total - shown.length;

  return (
    <section className="bg-crimson-900 border border-crimson-700 rounded-xl p-5 space-y-3">
      <div className="flex items-baseline justify-between gap-3">
        <h3 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400">✦ Hall of Aces</h3>
        {total > 0 && (
          <span className="text-xs text-parchment-dim">
            {total} perfect {total === 1 ? "score" : "scores"}
          </span>
        )}
      </div>

      {total === 0 ? (
        <p className="text-sm text-parchment-dim">No one has aced this lecture yet — be the first.</p>
      ) : (
        <div className="flex flex-wrap gap-2">
          {shown.map((a) => {
            const isMe = a.userId === myUserId;
            return (
              <span
                key={a.userId}
                className={`text-xs rounded px-2 py-1 border ${
                  isMe ? "border-gold-500 text-gold-300 bg-crimson-800" : "border-crimson-700 text-parchment-dim"
                }`}
              >
                {a.handle}
                {isMe && " (you)"}
              </span>
            );
          })}
          {more > 0 && <span className="text-xs text-parchment-dim px-2 py-1">+{more} more</span>}
        </div>
      )}
    </section>
  );
}
