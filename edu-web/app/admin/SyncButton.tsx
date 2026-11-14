"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function SyncButton() {
  const router = useRouter();
  const [status, setStatus] = useState<"idle" | "loading" | "done" | "error">("idle");
  const [message, setMessage] = useState("");

  async function sync() {
    setStatus("loading");
    setMessage("");
    try {
      const res = await fetch("/api/youtube/sync", { method: "POST" });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setMessage(`Synced ${data.synced.courses} courses and ${data.synced.videos} videos.`);
      setStatus("done");
      router.refresh();
    } catch (err) {
      setMessage(err instanceof Error ? err.message : "Sync failed.");
      setStatus("error");
    }
  }

  return (
    <div className="flex items-center gap-3">
      {message && (
        <p className={`text-sm ${status === "error" ? "text-red-400" : "text-green-400"}`}>
          {message}
        </p>
      )}
      <button
        onClick={sync}
        disabled={status === "loading"}
        className="font-ui font-semibold whitespace-nowrap px-3 py-2 bg-btn hover:bg-btn-hover border border-crimson-700 text-parchment text-sm rounded-lg transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
      >
        {status === "loading" ? "Syncing…" : "Sync YouTube"}
      </button>
    </div>
  );
}
