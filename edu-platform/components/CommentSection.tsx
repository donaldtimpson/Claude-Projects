"use client";

import { useState } from "react";
import Link from "next/link";
import { DELETED_BODY, type SerializedComment } from "@/lib/comments";

function timeAgo(iso: string) {
  const diff = Date.now() - new Date(iso).getTime();
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return "just now";
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

export default function CommentSection({
  videoId,
  userId,
  initialComments,
}: {
  videoId: string;
  userId: string | null;
  userName: string | null;
  initialComments: SerializedComment[];
}) {
  const [comments, setComments] = useState<SerializedComment[]>(initialComments);
  const [body, setBody] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  // At most one reply box is open at a time; keyed by the top-level thread it belongs to.
  const [replyTopId, setReplyTopId] = useState<string | null>(null);
  const [replyBody, setReplyBody] = useState("");
  const [replySubmitting, setReplySubmitting] = useState(false);
  const [replyError, setReplyError] = useState("");

  const count = comments.reduce(
    (n, c) => n + (c.deleted ? 0 : 1) + c.replies.filter((r) => !r.deleted).length,
    0
  );

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!body.trim()) return;
    setSubmitting(true);
    setError("");

    const res = await fetch("/api/comments", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ videoId, body }),
    });

    if (res.ok) {
      const comment: SerializedComment = await res.json();
      setComments((prev) => [...prev, comment]);
      setBody("");
    } else {
      setError("Failed to post comment. Please try again.");
    }
    setSubmitting(false);
  }

  // `top` is the thread the reply lands under; `target` is the comment the user
  // clicked (a reply target gets an @mention prefill since replies flatten).
  function openReply(top: SerializedComment, target: SerializedComment) {
    setReplyTopId(top.id);
    setReplyBody(target.id === top.id ? "" : `@${target.user.name} `);
    setReplyError("");
  }

  function cancelReply() {
    setReplyTopId(null);
    setReplyBody("");
    setReplyError("");
  }

  async function handleReplySubmit(e: React.FormEvent, topId: string) {
    e.preventDefault();
    if (!replyBody.trim()) return;
    setReplySubmitting(true);
    setReplyError("");

    const res = await fetch("/api/comments", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ videoId, body: replyBody, parentId: topId }),
    });

    if (res.ok) {
      const reply: SerializedComment = await res.json();
      setComments((prev) =>
        prev.map((c) => (c.id === topId ? { ...c, replies: [...c.replies, reply] } : c))
      );
      cancelReply();
    } else {
      setReplyError("Failed to post reply. Please try again.");
    }
    setReplySubmitting(false);
  }

  async function handleDelete(id: string) {
    const res = await fetch(`/api/comments/${id}`, { method: "DELETE" });
    if (!res.ok) return;
    const { mode } = await res.json();

    setComments((prev) => {
      if (mode === "soft") {
        // Only comments that still have replies are soft-deleted (always top-level).
        return prev.map((c) =>
          c.id === id
            ? { ...c, deleted: true, body: DELETED_BODY, user: { id: "", name: "" } }
            : c
        );
      }
      // Hard delete: drop it from the top-level list or from a thread's replies.
      return prev
        .filter((c) => c.id !== id)
        .map((c) => ({ ...c, replies: c.replies.filter((r) => r.id !== id) }));
    });
  }

  function renderComment(c: SerializedComment, top: SerializedComment) {
    return (
      <>
        <div className="flex items-center justify-between">
          <span className="text-sm font-semibold text-gold-300">
            {c.deleted ? <span className="italic text-parchment-dim font-normal">deleted</span> : c.user.name}
          </span>
          {!c.deleted && (
            <div className="flex items-center gap-3">
              <span className="text-xs text-parchment-dim">{timeAgo(c.createdAt)}</span>
              {userId && (
                <button
                  onClick={() => openReply(top, c)}
                  className="text-xs text-parchment-dim hover:text-gold-300 transition-colors"
                >
                  Reply
                </button>
              )}
              {c.user.id === userId && (
                <button
                  onClick={() => handleDelete(c.id)}
                  className="text-xs text-parchment-dim hover:text-red-400 transition-colors"
                >
                  Delete
                </button>
              )}
            </div>
          )}
        </div>
        <p
          className={`text-sm leading-relaxed whitespace-pre-wrap ${
            c.deleted ? "italic text-parchment-dim" : "text-parchment"
          }`}
        >
          {c.body}
        </p>
      </>
    );
  }

  return (
    <section className="space-y-6 pt-4 border-t border-crimson-700">
      <h2 className="text-lg font-bold text-parchment">
        Discussion {count > 0 && <span className="text-parchment-dim font-normal text-base">({count})</span>}
      </h2>

      {/* Comment list */}
      {comments.length > 0 ? (
        <ul className="space-y-4">
          {comments.map((c) => (
            <li
              key={c.id}
              id={`comment-${c.id}`}
              className="bg-crimson-900 border border-crimson-700 rounded-lg p-4 space-y-1 scroll-mt-24"
            >
              {renderComment(c, c)}

              {/* Replies */}
              {c.replies.length > 0 && (
                <ul className="mt-3 space-y-3 border-l-2 border-crimson-700 pl-4">
                  {c.replies.map((r) => (
                    <li key={r.id} id={`comment-${r.id}`} className="space-y-1 scroll-mt-24">
                      {renderComment(r, c)}
                    </li>
                  ))}
                </ul>
              )}

              {/* Reply composer for this thread */}
              {replyTopId === c.id && userId && (
                <form onSubmit={(e) => handleReplySubmit(e, c.id)} className="mt-3 space-y-2 pl-4">
                  <textarea
                    value={replyBody}
                    onChange={(e) => setReplyBody(e.target.value)}
                    placeholder="Write a reply…"
                    rows={2}
                    autoFocus
                    className="w-full bg-crimson-800 border border-crimson-600 rounded-lg px-3 py-2 text-sm text-parchment placeholder-parchment-500 focus:outline-none focus:border-gold-400 resize-none"
                  />
                  {replyError && <p className="text-red-400 text-xs">{replyError}</p>}
                  <div className="flex items-center gap-2">
                    <button
                      type="submit"
                      disabled={replySubmitting || !replyBody.trim()}
                      className="px-3 py-1.5 bg-gold-600 hover:bg-gold-500 text-crimson-950 text-xs font-semibold rounded-lg transition-colors disabled:opacity-50"
                    >
                      {replySubmitting ? "Posting…" : "Reply"}
                    </button>
                    <button
                      type="button"
                      onClick={cancelReply}
                      className="text-xs text-parchment-dim hover:text-parchment transition-colors"
                    >
                      Cancel
                    </button>
                  </div>
                </form>
              )}
            </li>
          ))}
        </ul>
      ) : (
        <p className="text-sm text-parchment-dim">No comments yet. Be the first!</p>
      )}

      {/* Compose */}
      {userId ? (
        <form onSubmit={handleSubmit} className="space-y-3">
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            placeholder="Ask a question or leave a comment…"
            rows={3}
            className="w-full bg-crimson-800 border border-crimson-600 rounded-lg px-4 py-3 text-sm text-parchment placeholder-parchment-500 focus:outline-none focus:border-gold-400 resize-none"
          />
          {error && <p className="text-red-400 text-xs">{error}</p>}
          <button
            type="submit"
            disabled={submitting || !body.trim()}
            className="px-4 py-2 bg-gold-600 hover:bg-gold-500 text-crimson-950 text-sm font-semibold rounded-lg transition-colors disabled:opacity-50"
          >
            {submitting ? "Posting…" : "Post Comment"}
          </button>
        </form>
      ) : (
        <p className="text-sm text-parchment-dim">
          <Link href="/auth/signin" className="text-gold-400 hover:text-gold-300">
            Sign in
          </Link>{" "}
          to leave a comment.
        </p>
      )}
    </section>
  );
}
