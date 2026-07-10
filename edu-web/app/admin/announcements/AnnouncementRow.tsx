"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

type Announcement = {
  id: string;
  title: string;
  body: string;
  pinned: boolean;
  createdAt: string | Date;
  course: { id: string; title: string } | null;
};

export default function AnnouncementRow({ announcement }: { announcement: Announcement }) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);

  async function togglePin() {
    setBusy(true);
    await fetch(`/api/announcements/${announcement.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ pinned: !announcement.pinned }),
    });
    setBusy(false);
    router.refresh();
  }

  async function remove() {
    if (!confirm(`Delete "${announcement.title}"?`)) return;
    setBusy(true);
    await fetch(`/api/announcements/${announcement.id}`, { method: "DELETE" });
    setBusy(false);
    router.refresh();
  }

  const scopeLabel = announcement.course ? announcement.course.title : "Site-wide";
  const date = new Date(announcement.createdAt).toLocaleString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });

  return (
    <div className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 flex items-start justify-between gap-4">
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2 flex-wrap">
          <p className="font-semibold text-parchment">{announcement.title}</p>
          {announcement.pinned && (
            <span className="text-[10px] uppercase tracking-wider bg-gold-500 text-crimson-950 px-1.5 py-0.5 rounded font-semibold">
              Pinned
            </span>
          )}
        </div>
        <p className="text-xs text-parchment-dim mt-0.5">
          {scopeLabel} · {date}
        </p>
        {announcement.body && (
          <p className="text-sm text-parchment-dim mt-2 whitespace-pre-wrap">{announcement.body}</p>
        )}
      </div>
      <div className="flex flex-col items-end gap-2 shrink-0">
        <button
          type="button"
          onClick={togglePin}
          disabled={busy}
          className="text-xs text-gold-400 hover:text-gold-300 disabled:opacity-50 transition-colors"
        >
          {announcement.pinned ? "Unpin" : "Pin"}
        </button>
        <button
          type="button"
          onClick={remove}
          disabled={busy}
          className="text-xs text-red-400 hover:text-red-300 disabled:opacity-50 transition-colors"
        >
          Delete
        </button>
      </div>
    </div>
  );
}
