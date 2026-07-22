"use client";

import { useMemo } from "react";
import { atlas, type GeoMapKind, type Rect } from "@/lib/drills/geo/atlas";

// Map palette (kept close to the iOS "natural Earth" look).
const SEA = "#24506b";
const LAND = "#6f8f57";
const LAND_STROKE = "#2c2416";
const HIGHLIGHT = "#e6b34d"; // identify target
const CORRECT = "#4c9f70"; // locate: the right region on reveal
const WRONG = "#c0533f"; // locate: your wrong click on reveal
const NEIGHBOR = "#6f747a"; // context countries (gray)
const RIVER = "#2f6fa8";

const clamp = (v: number, lo: number, hi: number) => Math.min(Math.max(v, lo), hi);

// Deterministic 0..1 from a string (32-bit FNV-1a) — stable per target, for off-centering.
function seededFrac(s: string, salt: number): number {
  let h = (2166136261 ^ salt) >>> 0;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 16777619) >>> 0;
  }
  return (h % 1000) / 1000;
}

const ASPECT = 1.6; // display width : height

// A viewport window around a focus rect: scaled by `pad`, clamped to the atlas, at the
// display aspect. `offset` in [0,1] places the focus off-center (locate, so it's not a
// giveaway); 0.5 centers it (identify).
function windowAround(f: Rect, vb: Rect, pad: number, offX = 0.5, offY = 0.5): Rect {
  let w = Math.max(f.w, f.h * ASPECT) * pad;
  w = clamp(w, vb.w * 0.16, vb.w);
  let h = w / ASPECT;
  if (h > vb.h) {
    h = vb.h;
    w = Math.min(h * ASPECT, vb.w);
  }
  const cx = f.x + f.w / 2;
  const cy = f.y + f.h / 2;
  const x = w >= vb.w ? vb.x : clamp(cx - offX * w, vb.x, vb.x + vb.w - w);
  const y = h >= vb.h ? vb.y : clamp(cy - offY * h, vb.y, vb.y + vb.h - h);
  return { x, y, w, h };
}

export default function GeoMap({
  map,
  // identify: highlight this region, non-interactive.
  highlightId,
  // locate: interactive; grade a click against targetId; reveal colors after answering.
  interactive = false,
  targetId,
  revealed = false,
  pickedId = null,
  onPick,
  className = "",
}: {
  map: GeoMapKind;
  highlightId?: string;
  interactive?: boolean;
  targetId?: string;
  revealed?: boolean;
  pickedId?: string | null;
  onPick?: (id: string) => void;
  className?: string;
}) {
  const a = atlas(map);
  const focusId = highlightId ?? targetId ?? "";

  const win = useMemo(() => {
    const r = a.byId.get(focusId)?.focus;
    if (!r) return a.viewBox;
    if (interactive) {
      // Wider window + off-center so the target isn't handed to you by being centered.
      const pad = map === "world" ? 9 : 6;
      return windowAround(r, a.viewBox, pad, 0.3 + 0.4 * seededFrac(focusId, 1), 0.3 + 0.4 * seededFrac(focusId, 2));
    }
    return windowAround(r, a.viewBox, 4); // identify: centered, generous
  }, [a, focusId, interactive, map]);

  function fillFor(id: string): string | undefined {
    if (highlightId && id === highlightId) return HIGHLIGHT;
    if (revealed && id === targetId) return CORRECT;
    if (revealed && pickedId && id === pickedId && pickedId !== targetId) return WRONG;
    return undefined; // → CSS .region fill (with hover)
  }

  return (
    <div
      className={className}
      style={{ background: SEA, aspectRatio: `${ASPECT}`, borderRadius: 10, overflow: "hidden" }}
    >
      <svg
        viewBox={`${win.x} ${win.y} ${win.w} ${win.h}`}
        preserveAspectRatio="xMidYMid meet"
        width="100%"
        height="100%"
        role="img"
      >
        {/* Context countries (US: Canada/Mexico) in flat gray. */}
        {a.neighbors.map((d, i) => (
          <path key={`n${i}`} d={d} fill={NEIGHBOR} stroke="#4a4e52" strokeWidth={0.4} />
        ))}
        {a.regions.map((r) => {
          const fixed = fillFor(r.id);
          return (
            <path
              key={r.id}
              d={r.path}
              className={fixed ? undefined : "region"}
              fill={fixed}
              stroke={LAND_STROKE}
              strokeWidth={0.4}
              onClick={interactive && !revealed ? () => onPick?.(r.id) : undefined}
            />
          );
        })}
        {/* Lakes as water over land — carves lake-inclusive states (fixes Michigan). */}
        {a.lakes.map((d, i) => (
          <path key={`l${i}`} d={d} fill={SEA} stroke={SEA} strokeWidth={0.3} />
        ))}
        {/* Rivers as context. */}
        {a.rivers.map((d, i) => (
          <path key={`r${i}`} d={d} fill="none" stroke={RIVER} strokeWidth={1.2} />
        ))}
      </svg>
      <style jsx>{`
        .region {
          fill: ${LAND};
        }
        ${interactive && !revealed
          ? `.region { cursor: pointer; transition: fill 0.1s; } .region:hover { fill: #a8c07e; }`
          : ""}
      `}</style>
    </div>
  );
}
