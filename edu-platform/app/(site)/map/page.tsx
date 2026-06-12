import type { Metadata } from "next";
import { db } from "@/lib/db";
import { layerByLongestPath, type Edge } from "@/lib/course-graph";
import CourseMapView, { type MapNode, type RecEdge, type RelEdge } from "./CourseMapView";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Course Map",
  description: "How the courses at The Timpson Lyceum build on and relate to one another.",
};

// Layout constants (SVG user units).
const NODE_W = 172;
const NODE_H = 54;
const H_GAP = 40;
const V_GAP = 104;
const PAD = 36;
const GAP = 8; // arrowhead stops this far short of the target box
const PORT_LO = 0.18; // incoming/outgoing ports spread across this band of the edge
const PORT_HI = 0.82;

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

  // Recommended adjacency (parents above, children below).
  const parents = new Map<string, string[]>();
  const children = new Map<string, string[]>();
  for (const e of recommended) {
    (children.get(e.fromCourseId) ?? children.set(e.fromCourseId, []).get(e.fromCourseId)!).push(e.toCourseId);
    (parents.get(e.toCourseId) ?? parents.set(e.toCourseId, []).get(e.toCourseId)!).push(e.fromCourseId);
  }

  // Crossing reduction (Sugiyama-style barycenter): repeatedly reorder each row
  // toward the average position of its neighbours in the adjacent row. Nodes with
  // no neighbours keep their place (fall back to their current index).
  const indexOf = new Map<string, number>();
  const reindex = () => rows.forEach((row) => row.forEach((id, i) => indexOf.set(id, i)));
  reindex();
  const bary = (neighbors: string[]): number | null =>
    neighbors.length ? neighbors.reduce((s, n) => s + (indexOf.get(n) ?? 0), 0) / neighbors.length : null;
  const sortRow = (row: string[], keyFn: (id: string) => number | null) =>
    row
      .map((id, i) => ({ id, k: keyFn(id), i }))
      .sort((a, b) => (a.k ?? a.i) - (b.k ?? b.i))
      .map((w) => w.id);
  for (let iter = 0; iter < 4; iter++) {
    for (let l = 1; l <= maxLevel; l++) {
      rows[l] = sortRow(rows[l], (id) => bary(parents.get(id) ?? []));
      reindex();
    }
    for (let l = maxLevel - 1; l >= 0; l--) {
      rows[l] = sortRow(rows[l], (id) => bary(children.get(id) ?? []));
      reindex();
    }
  }

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
  const center = (id: string) => {
    const p = pos.get(id)!;
    return { cx: p.x + NODE_W / 2, cy: p.y + NODE_H / 2 };
  };
  const portX = (id: string, i: number, n: number) => {
    const frac = n <= 1 ? 0.5 : PORT_LO + (PORT_HI - PORT_LO) * (i / (n - 1));
    return pos.get(id)!.x + NODE_W * frac;
  };

  // Assign each recommended edge a distinct exit port (bottom of source) and entry
  // port (top of target). Sorting ports by the opposite node's x keeps the little
  // fans from crossing themselves.
  type Pt = { x: number; y: number };
  const exitPort = new Map<string, Pt>();
  const entryPort = new Map<string, Pt>();
  const key = (e: Edge) => `${e.fromCourseId}|${e.toCourseId}`;
  for (const src of connectedIds) {
    const outs = recommended
      .filter((e) => e.fromCourseId === src)
      .sort((a, b) => center(a.toCourseId).cx - center(b.toCourseId).cx);
    const p = pos.get(src)!;
    outs.forEach((e, i) => exitPort.set(key(e), { x: portX(src, i, outs.length), y: p.y + NODE_H }));
  }
  for (const tgt of connectedIds) {
    const ins = recommended
      .filter((e) => e.toCourseId === tgt)
      .sort((a, b) => center(a.fromCourseId).cx - center(b.fromCourseId).cx);
    const p = pos.get(tgt)!;
    ins.forEach((e, i) => entryPort.set(key(e), { x: portX(tgt, i, ins.length), y: p.y }));
  }

  // Point on a node's border (expanded by `gap`) in the direction of (tx,ty).
  const boundary = (id: string, tx: number, ty: number, gap: number): Pt => {
    const c = center(id);
    const dx = tx - c.cx;
    const dy = ty - c.cy;
    if (dx === 0 && dy === 0) return { x: c.cx, y: c.cy };
    const t = Math.min(
      dx !== 0 ? (NODE_W / 2 + gap) / Math.abs(dx) : Infinity,
      dy !== 0 ? (NODE_H / 2 + gap) / Math.abs(dy) : Infinity,
    );
    return { x: c.cx + dx * t, y: c.cy + dy * t };
  };

  // Precompute serializable geometry for the client view.
  const nodes: MapNode[] = connectedIds.map((id) => ({
    id,
    title: titleById.get(id)!,
    x: pos.get(id)!.x,
    y: pos.get(id)!.y,
  }));

  const recEdges: RecEdge[] = recommended
    .map((l) => {
      const ex = exitPort.get(key(l));
      const en = entryPort.get(key(l));
      if (!ex || !en) return null;
      const ty = en.y - GAP;
      const dy = ty - ex.y;
      const d = `M ${ex.x} ${ex.y} C ${ex.x} ${ex.y + dy * 0.5}, ${en.x} ${ty - dy * 0.5}, ${en.x} ${ty}`;
      return { from: l.fromCourseId, to: l.toCourseId, d };
    })
    .filter((e): e is RecEdge => e !== null);

  const relEdges: RelEdge[] = related.map((l) => {
    const a = center(l.fromCourseId);
    const b = center(l.toCourseId);
    const s = boundary(l.fromCourseId, b.cx, b.cy, 4);
    const e = boundary(l.toCourseId, a.cx, a.cy, 4);
    return { a: l.fromCourseId, b: l.toCourseId, x1: s.x, y1: s.y, x2: e.x, y2: e.y };
  });

  return (
    <main className="max-w-6xl mx-auto px-6 py-10">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-parchment mb-2">Course Map</h1>
        <p className="text-parchment-dim">
          How the courses build on and relate to one another. These are recommendations, not
          requirements — watch anything in any order.{" "}
          <span className="text-parchment-dim/80">Hover a course to light up where it leads.</span>
        </p>
        <div className="flex flex-wrap gap-5 mt-4 text-xs text-parchment-dim">
          <span className="flex items-center gap-2">
            <svg width="28" height="10" aria-hidden>
              <line x1="0" y1="5" x2="21" y2="5" stroke="var(--color-gold-500)" strokeWidth="2" />
              <polygon points="21,1 28,5 21,9" fill="var(--color-gold-500)" />
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
            Related Courses
          </span>
        </div>
      </div>

      <CourseMapView
        nodes={nodes}
        recEdges={recEdges}
        relEdges={relEdges}
        width={svgWidth}
        height={svgHeight}
        nodeW={NODE_W}
        nodeH={NODE_H}
      />
    </main>
  );
}
