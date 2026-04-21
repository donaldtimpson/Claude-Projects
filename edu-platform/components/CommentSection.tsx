"use client";

import { useState } from "react";
import Link from "next/link";

type Comment = {
  id: string;
  body: string;
  createdAt: string;
  user: { id: string; name: string };
};

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
  userName,
  initialComments,
}: {
  videoId: string;
  userId: string | null;
  userName: string | null;
  initialComments: Comment[];
}) {
  const [comments, setComments] = useState<Comment[]>(initialComments);
  const [body, setBody] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

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
      const comment = await res.json();
      setComments((prev) => [...prev, comment]);
      setBody("");
    } else {
      setError("Failed to post comment. Please try again.");
    }
    setSubmitting(false);
  }

  async function handleDelete(id: string) {
    const res = await fetch(`/api/comments/${id}`, { method: "DELETE" });
    if (res.ok) {
      setComments((prev) => prev.filter((c) => c.id !== id));
    }
  }

  return (
    <section className="space-y-6 pt-4 border-t border-crimson-700">
      <h2 className="text-lg font-bold text-parchment">
        Discussion {comments.length > 0 && <span className="text-parchment-dim font-normal text-base">({comments.length})</span>}
      </h2>

      {/* Comment list */}
      {comments.length > 0 ? (
        <ul className="space-y-4">
          {comments.map((c) => (
            <li key={c.id} className="bg-crimson-900 border border-crimson-700 rounded-lg p-4 space-y-1">
              <div className="flex items-center justify-between">
                <span className="text-sm font-semibold text-gold-300">{c.user.name}</span>
                <div className="flex items-center gap-3">
                  <span className="text-xs text-parchment-dim">{timeAgo(c.createdAt)}</span>
                  {c.user.id === userId && (
                    <button
                      onClick={() => handleDelete(c.id)}
                      className="text-xs text-parchment-dim hover:text-red-400 transition-colors"
                    >
                      Delete
                    </button>
                  )}
                </div>
              </div>
              <p className="text-sm text-parchment leading-relaxed whitespace-pre-wrap">{c.body}</p>
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
