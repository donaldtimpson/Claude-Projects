// Lecture order and labels, shared by the web course pages and the mobile API so
// the app and the site can't disagree about which lecture is "Lecture 3".
//
// Order: chronological (publishedAt, then position). publishedAt is reliable
// lecture order across every course, while position runs backwards on active
// playlists that YouTube sorts newest-first. A `manualOrder` course is the
// exception: there, position IS the hand-arranged order.
//
// Labels: the number in the lecture's own title ("Lecture 3", "Lesson 9"), which
// is what students see on the video; otherwise its place in the ordered list.

type Orderable = { position: number; publishedAt: Date | null };

export function sortLectures<T extends Orderable>(videos: T[], manualOrder: boolean): T[] {
  return [...videos].sort((a, b) => {
    if (!manualOrder) {
      const ta = a.publishedAt?.getTime() ?? Number.POSITIVE_INFINITY;
      const tb = b.publishedAt?.getTime() ?? Number.POSITIVE_INFINITY;
      if (ta !== tb) return ta - tb;
    }
    return a.position - b.position;
  });
}

export type LectureLabel = { word: "Lecture" | "Lesson"; n: string };

/** Labels for an already-ordered lecture list, keyed by video id. */
export function lectureLabels(ordered: { id: string; title: string }[]): Map<string, LectureLabel> {
  return new Map(
    ordered.map((v, i) => {
      const m = v.title.match(/\b(Lecture|Lesson)\s+(\d+)/i);
      const label: LectureLabel = m
        ? { word: m[1].toLowerCase() === "lesson" ? "Lesson" : "Lecture", n: m[2] }
        : { word: "Lecture", n: String(i + 1) };
      return [v.id, label];
    }),
  );
}

export const formatLabel = (l: LectureLabel) => `${l.word} ${l.n}`;

/** "Lecture 3" or "Lectures 4–5" for the lectures a problem set covers. */
export function lectureSpan(
  videoIds: string[],
  ordered: { id: string }[],
  labels: Map<string, LectureLabel>,
): string | null {
  const index = new Map(ordered.map((v, i) => [v.id, i]));
  const covered = videoIds
    .filter((id) => labels.has(id))
    .sort((a, b) => (index.get(a) ?? 0) - (index.get(b) ?? 0))
    .map((id) => labels.get(id)!);
  if (covered.length === 0) return null;
  const first = covered[0];
  const last = covered[covered.length - 1];
  return covered.length === 1 ? formatLabel(first) : `${first.word}s ${first.n}–${last.n}`;
}

/** Problem sets whose title marks them as a test get a "Test" badge. */
export const isTestTitle = (title: string) => /\b(test|exam|midterm|final)\b/i.test(title);
