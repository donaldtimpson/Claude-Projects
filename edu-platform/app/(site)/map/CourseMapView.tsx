"use client";

import { useState } from "react";
import Link from "next/link";

export type MapNode = { id: string; title: string; x: number; y: number };
export type RecEdge = { from: string; to: string; d: string };
export type RelEdge = { a: string; b: string; x1: number; y1: number; x2: number; y2: number };

export default function CourseMapView({
  nodes,
  recEdges,
  relEdges,
  width,
  height,
  nodeW,
  nodeH,
}: {
  nodes: MapNode[];
  recEdges: RecEdge[];
  relEdges: RelEdge[];
  width: number;
  height: number;
  nodeW: number;
  nodeH: number;
}) {
  const [hovered, setHovered] = useState<string | null>(null);

  // Recommended arrows exiting the hovered node light up; related edges touching
  // it brighten too. Draw highlighted edges last so they sit on top.
  const recActive = (e: RecEdge) => hovered != null && e.from === hovered;
  const relActive = (e: RelEdge) => hovered != null && (e.a === hovered || e.b === hovered);
  const sortedRec = [...recEdges].sort((a, b) => Number(recActive(a)) - Number(recActive(b)));
  const sortedRel = [...relEdges].sort((a, b) => Number(relActive(a)) - Number(relActive(b)));

  return (
    <div className="overflow-x-auto border border-crimson-700 rounded-xl bg-crimson-900/40">
      <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`} className="max-w-none">
        <defs>
          <marker
            id="arrow-muted"
            viewBox="0 0 10 10"
            refX="9.5"
            refY="5"
            markerWidth="9"
            markerHeight="9"
            markerUnits="userSpaceOnUse"
            orient="auto"
          >
            <path d="M 0 1 L 9.5 5 L 0 9 z" fill="var(--color-parchment-dim)" />
          </marker>
          <marker
            id="arrow-gold"
            viewBox="0 0 10 10"
            refX="9.5"
            refY="5"
            markerWidth="10"
            markerHeight="10"
            markerUnits="userSpaceOnUse"
            orient="auto"
          >
            <path d="M 0 1 L 9.5 5 L 0 9 z" fill="var(--color-gold-500)" />
          </marker>
        </defs>

        {/* Related (dashed, undirected) — muted by default, brighter when touching hover. */}
        {sortedRel.map((e, i) => {
          const on = relActive(e);
          return (
            <line
              key={`r${i}`}
              x1={e.x1}
              y1={e.y1}
              x2={e.x2}
              y2={e.y2}
              stroke={on ? "var(--color-gold-400)" : "var(--color-parchment-dim)"}
              strokeWidth="1.5"
              strokeDasharray="5 4"
              opacity={on ? 0.95 : 0.4}
            />
          );
        })}

        {/* Recommended arrows — muted by default, gold when exiting the hovered node. */}
        {sortedRec.map((e, i) => {
          const on = recActive(e);
          return (
            <path
              key={`d${i}`}
              d={e.d}
              fill="none"
              stroke={on ? "var(--color-gold-500)" : "var(--color-parchment-dim)"}
              strokeWidth={on ? 2.25 : 1.5}
              opacity={on ? 1 : 0.45}
              markerEnd={`url(#${on ? "arrow-gold" : "arrow-muted"})`}
            />
          );
        })}

        {/* Nodes on top. Hovering sets the active node. */}
        {nodes.map((n) => (
          <foreignObject
            key={n.id}
            x={n.x}
            y={n.y}
            width={nodeW}
            height={nodeH}
            onMouseEnter={() => setHovered(n.id)}
            onMouseLeave={() => setHovered((h) => (h === n.id ? null : h))}
          >
            <Link
              href={`/courses/${n.id}`}
              onFocus={() => setHovered(n.id)}
              onBlur={() => setHovered((h) => (h === n.id ? null : h))}
              className="flex h-full w-full items-center justify-center text-center px-2 rounded-lg border border-crimson-700 bg-crimson-900 text-parchment text-sm leading-tight hover:border-gold-500 hover:text-gold-300 transition-colors"
            >
              {n.title}
            </Link>
          </foreignObject>
        ))}
      </svg>
    </div>
  );
}
