import Link from "next/link";
import { db } from "@/lib/db";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 50;

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

  const [comments, totalCount] = await Promise.all([
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
    <main className="max-w-3xl mx-auto px-6 py-10 space-y-8">
      <div>
        <Link href="/admin" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
          ← Dashboard
        </Link>
        <h1 className="text-2xl font-bold text-parchment mt-3">Recent Comments</h1>
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
