"use client";

import { useState } from "react";
import Link from "next/link";

export type MapNode = { id: string; title: string; x: number; y: number };
export type RecEdge = { from: string; to: string; d: string };
export type RelEdge = { a: string; b: string; d: string };

// Heraldic azure for incoming ("builds toward it"); gold stays for outgoing.
const AZURE = "#7fb0e0";

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

  // --- Experimental: soft tint on the hovered node's neighbours ---
  // childrenOf[H] = nodes H points to (gold, "where it leads"); parentsOf[H] =
  // nodes pointing into H (azure, "what builds toward it"). Easy to remove.
  const childrenOf = new Map<string, Set<string>>();
  const parentsOf = new Map<string, Set<string>>();
  for (const e of recEdges) {
    (childrenOf.get(e.from) ?? childrenOf.set(e.from, new Set()).get(e.from)!).add(e.to);
    (parentsOf.get(e.to) ?? parentsOf.set(e.to, new Set()).get(e.to)!).add(e.from);
  }
  const nodeTint = (id: string): { borderColor: string; backgroundColor: string } | undefined => {
    if (!hovered || hovered === id) return undefined;
    if (childrenOf.get(hovered)?.has(id))
      return {
        borderColor: "var(--color-gold-500)",
        backgroundColor: "color-mix(in srgb, var(--color-crimson-900) 86%, var(--color-gold-500))",
      };
    if (parentsOf.get(hovered)?.has(id))
      return {
        borderColor: AZURE,
        backgroundColor: `color-mix(in srgb, var(--color-crimson-900) 86%, ${AZURE})`,
      };
    return undefined;
  };

  // On hover: outgoing recommended arrows go gold, incoming go azure, related
  // edges touching the node brighten. Draw active edges last so they sit on top.
  const outActive = (e: RecEdge) => hovered != null && e.from === hovered;
  const inActive = (e: RecEdge) => hovered != null && e.to === hovered;
  const recState = (e: RecEdge) => (outActive(e) ? "out" : inActive(e) ? "in" : "off");
  const relActive = (e: RelEdge) => hovered != null && (e.a === hovered || e.b === hovered);
  const sortedRec = [...recEdges].sort(
    (a, b) => Number(recState(a) !== "off") - Number(recState(b) !== "off"),
  );
  const sortedRel = [...relEdges].sort((a, b) => Number(relActive(a)) - Number(relActive(b)));

  return (
    <div className="overflow-x-auto border border-crimson-700 rounded-xl bg-crimson-900/40">
      <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`} className="max-w-none">
        <defs>
          {[
            ["arrow-muted", "var(--color-parchment-dim)"],
            ["arrow-gold", "var(--color-gold-500)"],
            ["arrow-azure", AZURE],
          ].map(([id, fill]) => (
            <marker
              key={id}
              id={id}
              viewBox="0 0 10 10"
              refX="9.5"
              refY="5"
              markerWidth={id === "arrow-muted" ? 9 : 10}
              markerHeight={id === "arrow-muted" ? 9 : 10}
              markerUnits="userSpaceOnUse"
              orient="auto"
            >
              <path d="M 0 1 L 9.5 5 L 0 9 z" fill={fill} />
            </marker>
          ))}
        </defs>

        {/* Related (dashed, undirected) — muted by default, brighter when touching hover. */}
        {sortedRel.map((e, i) => {
          const on = relActive(e);
          return (
            <path
              key={`r${i}`}
              d={e.d}
              fill="none"
              stroke={on ? "var(--color-gold-400)" : "var(--color-parchment-dim)"}
              strokeWidth="1.5"
              strokeDasharray="5 4"
              opacity={on ? 0.95 : 0.4}
            />
          );
        })}

        {/* Recommended arrows — muted by default; gold leaving the hovered node,
            azure arriving into it. */}
        {sortedRec.map((e, i) => {
          const state = recState(e);
          const stroke =
            state === "out"
              ? "var(--color-gold-500)"
              : state === "in"
                ? AZURE
                : "var(--color-parchment-dim)";
          const marker =
            state === "out" ? "arrow-gold" : state === "in" ? "arrow-azure" : "arrow-muted";
          return (
            <path
              key={`d${i}`}
              d={e.d}
              fill="none"
              stroke={stroke}
              strokeWidth={state === "off" ? 1.5 : 2.25}
              opacity={state === "off" ? 0.45 : 1}
              markerEnd={`url(#${marker})`}
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
              style={nodeTint(n.id)}
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
