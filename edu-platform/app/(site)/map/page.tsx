import type { Metadata } from "next";
import Link from "next/link";
import { db } from "@/lib/db";
import { layerByLongestPath, type Edge } from "@/lib/course-graph";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Course Map",
  description: "How the courses at The Timpson Lyceum build on and relate to one another.",
};

// Layout constants (SVG user units).
const NODE_W = 168;
const NODE_H = 52;
const H_GAP = 32;
const V_GAP = 84;
const PAD = 32;

export default async function CourseMapPage() {
  const [courses, links] = await Promise.all([
    db.course.findMany({ select: { id: true, title: true } }),
    db.courseLink.findMany({ select: { fromCourseId: true, toCourseId: true, kind: true } }),
  ]);

  const titleById = new Map(courses.map((c) => [c.id, c.title]));
  const recommended: Edge[] = links.filter((l) => l.kind === "RECOMMENDED");
  const related: Edge[] = links.filter((l) => l.kind === "RELATED");

  // Only chart courses that actually participate in a connection.
  const connectedIds = [
    ...new Set(links.flatMap((l) => [l.fromCourseId, l.toCourseId])),
  ].filter((id) => titleById.has(id));

  if (connectedIds.length === 0) {
    return (
      <main className="max-w-4xl mx-auto px-6 py-16 text-center">
        <h1 className="text-3xl font-bold text-parchment mb-3">Course Map</h1>
        <p className="text-parchment-dim">No course connections have been added yet.</p>
      </main>
    );
  }

  // Layer the recommended DAG, then group courses into rows by level.
  const level = layerByLongestPath(connectedIds, recommended);
  const maxLevel = Math.max(...connectedIds.map((id) => level.get(id) ?? 0));
  const rows: string[][] = Array.from({ length: maxLevel + 1 }, () => []);
  for (const id of connectedIds) rows[level.get(id) ?? 0].push(id);
  rows.forEach((row) => row.sort((a, b) => (titleById.get(a)! < titleById.get(b)! ? -1 : 1)));

  // Position every node. pos: id -> {x,y} of the box's top-left.
  const contentWidth = Math.max(...rows.map((row) => row.length * NODE_W + (row.length - 1) * H_GAP));
  const pos = new Map<string, { x: number; y: number }>();
  rows.forEach((row, lvl) => {
    const rowWidth = row.length * NODE_W + (row.length - 1) * H_GAP;
    const startX = PAD + (contentWidth - rowWidth) / 2;
    const y = PAD + lvl * (NODE_H + V_GAP);
    row.forEach((id, i) => pos.set(id, { x: startX + i * (NODE_W + H_GAP), y }));
  });

  const svgWidth = contentWidth + PAD * 2;
  const svgHeight = PAD * 2 + (maxLevel + 1) * NODE_H + maxLevel * V_GAP;

  const centerOf = (id: string) => {
    const p = pos.get(id)!;
    return { cx: p.x + NODE_W / 2, cy: p.y + NODE_H / 2 };
  };

  return (
    <main className="max-w-6xl mx-auto px-6 py-10">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-parchment mb-2">Course Map</h1>
        <p className="text-parchment-dim">
          How the courses build on and relate to one another. These are recommendations, not
          requirements — watch anything in any order.
        </p>
        <div className="flex flex-wrap gap-5 mt-4 text-xs text-parchment-dim">
          <span className="flex items-center gap-2">
            <svg width="28" height="10" aria-hidden>
              <line x1="0" y1="5" x2="22" y2="5" stroke="var(--color-gold-500)" strokeWidth="2" />
              <polygon points="22,1 28,5 22,9" fill="var(--color-gold-500)" />
            </svg>
            Builds toward (recommended)
          </span>
          <span className="flex items-center gap-2">
            <svg width="28" height="10" aria-hidden>
              <line
                x1="0"
                y1="5"
                x2="28"
                y2="5"
                stroke="var(--color-parchment-dim)"
                strokeWidth="2"
                strokeDasharray="5 4"
              />
            </svg>
            Related material
          </span>
        </div>
      </div>

      <div className="overflow-x-auto border border-crimson-700 rounded-xl bg-crimson-900/40">
        <svg
          width={svgWidth}
          height={svgHeight}
          viewBox={`0 0 ${svgWidth} ${svgHeight}`}
          className="max-w-none"
        >
          <defs>
            <marker
              id="arrow"
              viewBox="0 0 10 10"
              refX="9"
              refY="5"
              markerWidth="7"
              markerHeight="7"
              orient="auto-start-reverse"
            >
              <path d="M 0 0 L 10 5 L 0 10 z" fill="var(--color-gold-500)" />
            </marker>
          </defs>

          {/* Related links first (behind), dashed and undirected. */}
          {related.map((l, i) => {
            const a = centerOf(l.fromCourseId);
            const b = centerOf(l.toCourseId);
            return (
              <line
                key={`r${i}`}
                x1={a.cx}
                y1={a.cy}
                x2={b.cx}
                y2={b.cy}
                stroke="var(--color-parchment-dim)"
                strokeWidth="1.5"
                strokeDasharray="5 4"
                opacity="0.7"
              />
            );
          })}

          {/* Recommended links: arrow from bottom of source to top of target
              (target always sits at a lower level, so arrows point downward). */}
          {recommended.map((l, i) => {
            const from = pos.get(l.fromCourseId);
            const to = pos.get(l.toCourseId);
            if (!from || !to) return null;
            return (
              <line
                key={`d${i}`}
                x1={from.x + NODE_W / 2}
                y1={from.y + NODE_H}
                x2={to.x + NODE_W / 2}
                y2={to.y}
                stroke="var(--color-gold-500)"
                strokeWidth="2"
                markerEnd="url(#arrow)"
              />
            );
          })}

          {/* Nodes on top. */}
          {connectedIds.map((id) => {
            const p = pos.get(id)!;
            return (
              <foreignObject key={id} x={p.x} y={p.y} width={NODE_W} height={NODE_H}>
                <Link
                  href={`/courses/${id}`}
                  className="flex h-full w-full items-center justify-center text-center px-2 rounded-lg border border-crimson-700 bg-crimson-900 text-parchment text-sm leading-tight hover:border-gold-500 hover:text-gold-300 transition-colors"
                >
                  {titleById.get(id)}
                </Link>
              </foreignObject>
            );
          })}
        </svg>
      </div>
    </main>
  );
}
