import Link from "next/link";
import { db } from "@/lib/db";
import ReportActions from "./ReportActions";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 50;

const REASON_LABEL: Record<string, string> = {
  SPAM: "Spam",
  HARASSMENT: "Harassment",
  HATE: "Hate speech",
  SEXUAL: "Sexual content",
  VIOLENCE: "Violence",
  OTHER: "Other",
};

function timeAgo(date: Date) {
  const diff = Date.now() - date.getTime();
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return "just now";
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `${days}d ago`;
  return date.toLocaleDateString();
}

export default async function AdminCommentsPage({
  searchParams,
}: {
  searchParams: Promise<{ page?: string }>;
}) {
  const { page: pageParam } = await searchParams;
  const page = Math.max(1, Number(pageParam) || 1);

  const [openReports, comments, totalCount] = await Promise.all([
    // The moderation queue: every open report, with the offending comment, its
    // author + lecture context, and who reported it. Newest first.
    db.commentReport.findMany({
      where: { status: "OPEN" },
      orderBy: { createdAt: "desc" },
      include: {
        reporter: { select: { id: true, name: true, email: true } },
        comment: {
          include: {
            user: { select: { id: true, name: true, email: true } },
            video: { select: { id: true, title: true, course: { select: { id: true, title: true } } } },
          },
        },
      },
    }),
    db.comment.findMany({
      orderBy: { createdAt: "desc" },
      take: PAGE_SIZE,
      skip: (page - 1) * PAGE_SIZE,
      include: {
        user: { select: { id: true, name: true, email: true } },
        video: { select: { id: true, title: true, course: { select: { id: true, title: true } } } },
      },
    }),
    db.comment.count(),
  ]);

  const totalPages = Math.max(1, Math.ceil(totalCount / PAGE_SIZE));

  return (
    <main className="max-w-3xl mx-auto px-6 py-10 space-y-10">
      <div>
        <Link href="/admin" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
          ← Dashboard
        </Link>
        <h1 className="text-2xl font-bold text-parchment mt-3">Comment Moderation</h1>
      </div>

      {/* Moderation queue: open reports */}
      <section className="space-y-4">
        <div>
          <h2 className="text-lg font-bold text-parchment">
            Reported comments{" "}
            {openReports.length > 0 && (
              <span className="text-red-400 font-normal text-base">({openReports.length} open)</span>
            )}
          </h2>
          <p className="text-sm text-parchment-dim mt-1">
            {openReports.length === 0
              ? "No open reports. Nothing needs review."
              : "Delete the comment (soft-deletes if it has replies), resolve, or dismiss."}
          </p>
        </div>

        {openReports.length > 0 && (
          <ul className="space-y-3">
            {openReports.map((r) => (
              <li
                key={r.id}
                className="bg-crimson-900 border border-red-500/40 rounded-xl p-4 space-y-3"
              >
                <div className="flex items-center justify-between gap-3 flex-wrap">
                  <div className="flex items-center gap-2 min-w-0 flex-wrap">
                    <span className="text-xs font-semibold uppercase tracking-wide text-red-400 shrink-0">
                      {REASON_LABEL[r.reason] ?? r.reason}
                    </span>
                    <span className="text-xs text-parchment-dim shrink-0">
                      reported by {r.reporter.name || r.reporter.email} · {timeAgo(r.createdAt)}
                    </span>
                  </div>
                  <Link
                    href={`/courses/${r.comment.video.course.id}/${r.comment.video.id}#comment-${r.comment.id}`}
                    className="text-xs text-gold-400 hover:text-gold-300 transition-colors shrink-0"
                  >
                    View in context →
                  </Link>
                </div>
                {r.note && (
                  <p className="text-xs text-parchment-dim italic">“{r.note}”</p>
                )}
                <p className="text-xs text-parchment-dim truncate">
                  {r.comment.user.name || r.comment.user.email} · {r.comment.video.course.title} ·{" "}
                  {r.comment.video.title}
                </p>
                <p
                  className={`text-sm leading-relaxed whitespace-pre-wrap line-clamp-6 ${
                    r.comment.deletedAt ? "italic text-parchment-dim" : "text-parchment"
                  }`}
                >
                  {r.comment.deletedAt ? "[comment deleted]" : r.comment.body}
                </p>
                <ReportActions
                  reportId={r.id}
                  commentId={r.comment.id}
                  commentDeleted={r.comment.deletedAt != null}
                />
              </li>
            ))}
          </ul>
        )}
      </section>

      <div>
        <h2 className="text-lg font-bold text-parchment">Recent Comments</h2>
        <p className="text-sm text-parchment-dim mt-1">
          {totalCount === 0
            ? "No comments yet."
            : `${totalCount} comment${totalCount === 1 ? "" : "s"} across all courses, newest first.`}
        </p>
      </div>

      {comments.length > 0 && (
        <ul className="space-y-3">
          {comments.map((c) => (
            <li
              key={c.id}
              className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 space-y-2"
            >
              <div className="flex items-center justify-between gap-3 flex-wrap">
                <div className="flex items-center gap-2 min-w-0">
                  <span className="text-sm font-semibold text-gold-300 truncate">
                    {c.user.name || c.user.email}
                  </span>
                  {c.parentId && (
                    <span className="text-xs text-parchment-dim shrink-0" title="Reply">↳ reply</span>
                  )}
                  <span className="text-xs text-parchment-dim shrink-0">{timeAgo(c.createdAt)}</span>
                </div>
                <Link
                  href={`/courses/${c.video.course.id}/${c.video.id}#comment-${c.id}`}
                  className="text-xs text-gold-400 hover:text-gold-300 transition-colors shrink-0"
                >
                  View in context →
                </Link>
              </div>
              <p className="text-xs text-parchment-dim truncate">
                {c.video.course.title} · {c.video.title}
              </p>
              <p
                className={`text-sm leading-relaxed whitespace-pre-wrap line-clamp-6 ${
                  c.deletedAt ? "italic text-parchment-dim" : "text-parchment"
                }`}
              >
                {c.deletedAt ? "[comment deleted]" : c.body}
              </p>
            </li>
          ))}
        </ul>
      )}

      {totalPages > 1 && (
        <div className="flex items-center justify-between text-sm text-parchment-dim">
          {page > 1 ? (
            <Link
              href={`/admin/comments?page=${page - 1}`}
              className="text-gold-400 hover:text-gold-300 transition-colors"
            >
              ← Newer
            </Link>
          ) : (
            <span />
          )}
          <span>
            Page {page} of {totalPages}
          </span>
          {page < totalPages ? (
            <Link
              href={`/admin/comments?page=${page + 1}`}
              className="text-gold-400 hover:text-gold-300 transition-colors"
            >
              Older →
            </Link>
          ) : (
            <span />
          )}
        </div>
      )}
    </main>
  );
}
