"use client";

import { setVideoLessons } from "@/lib/assignments";

// Per-lecture control: which grammar lesson drill(s) this lecture covers. Mirrors
// the problem-set↔video links, but the lesson side is a bundled content slug.
export default function LessonLinkEditor({
  videoId,
  lessons,
  linked,
}: {
  videoId: string;
  lessons: { slug: string; title: string }[];
  linked: string[];
}) {
  const linkedSet = new Set(linked);
  return (
    <form action={setVideoLessons} className="space-y-2">
      <input type="hidden" name="videoId" value={videoId} />
      <p className="font-display text-xs tracking-[0.15em] uppercase text-gold-400">Grammar lessons covered</p>
      <div className="flex flex-wrap gap-x-4 gap-y-1">
        {lessons.map((l) => (
          <label key={l.slug} className="flex items-center gap-2 text-sm text-parchment-dim">
            <input type="checkbox" name="lessonSlug" value={l.slug} defaultChecked={linkedSet.has(l.slug)} />
            {l.title}
          </label>
        ))}
      </div>
      <button
        type="submit"
        className="font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded px-4 py-2 font-semibold transition-colors"
      >
        Save lessons
      </button>
    </form>
  );
}
