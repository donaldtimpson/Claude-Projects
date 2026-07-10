type Announcement = {
  id: string;
  title: string;
  body: string;
  pinned: boolean;
  createdAt: Date;
  course: { id: string; title: string } | null;
};

export default function AnnouncementsFeed({
  announcements,
  showScope = false,
}: {
  announcements: Announcement[];
  showScope?: boolean;
}) {
  if (announcements.length === 0) return null;

  return (
    <section className="space-y-3">
      <h2 className="text-sm uppercase tracking-wider text-parchment-dim">Announcements</h2>
      <ul className="space-y-3">
        {announcements.map((a) => (
          <li
            key={a.id}
            className={`rounded-xl p-4 border ${
              a.pinned
                ? "bg-gold-500/10 border-gold-500/60"
                : "bg-crimson-900 border-crimson-700"
            }`}
          >
            <div className="flex items-center gap-2 flex-wrap">
              {a.pinned && (
                <span className="text-[10px] uppercase tracking-wider bg-gold-500 text-crimson-950 px-1.5 py-0.5 rounded font-semibold">
                  Pinned
                </span>
              )}
              <p className="font-semibold text-parchment">{a.title}</p>
            </div>
            <p className="text-xs text-parchment-dim mt-1">
              {new Date(a.createdAt).toLocaleString(undefined, {
                month: "short",
                day: "numeric",
                year: "numeric",
                hour: "numeric",
                minute: "2-digit",
              })}
              {showScope && (
                <span> · {a.course ? a.course.title : "Site-wide"}</span>
              )}
            </p>
            {a.body && (
              <p className="text-sm text-parchment-dim mt-2 whitespace-pre-wrap">{a.body}</p>
            )}
          </li>
        ))}
      </ul>
    </section>
  );
}
