"use client";

import { useState } from "react";
import { markVideoWatched } from "@/lib/actions";
import { useToast } from "@/components/Toast";

export default function MarkWatchedButton({
  videoId,
  initialWatched,
}: {
  videoId: string;
  initialWatched: boolean;
}) {
  const [watched, setWatched] = useState(initialWatched);
  const toast = useToast();

  async function handleClick() {
    setWatched(true);
    const earned = await markVideoWatched(videoId);
    if (earned.length && toast) {
      toast.celebrate(earned.map((b) => ({ key: b.key, name: b.name, tier: b.tier, blurb: b.blurb })));
    }
  }

  if (watched) {
    return (
      <div className="flex items-center gap-2 text-green-400 text-sm font-display tracking-wider">
        <span>✓</span>
        <span>Watched</span>
      </div>
    );
  }

  return (
    <button
      onClick={handleClick}
      className="text-sm font-display tracking-wider text-parchment-dim hover:text-gold-300 border border-crimson-600 hover:border-gold-500 px-4 py-1.5 rounded transition-colors"
    >
      Mark as Watched
    </button>
  );
}
