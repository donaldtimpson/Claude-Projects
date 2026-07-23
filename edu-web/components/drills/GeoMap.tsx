"use client";

import { useEffect, useMemo, useRef, useState } from "react";
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

// Keep a window inside the atlas (shrink to fit, then slide within bounds).
function clampRect(r: Rect, vb: Rect): Rect {
  const w = Math.min(r.w, vb.w);
  const h = Math.min(r.h, vb.h);
  return {
    x: w >= vb.w ? vb.x : clamp(r.x, vb.x, vb.x + vb.w - w),
    y: h >= vb.h ? vb.y : clamp(r.y, vb.y, vb.y + vb.h - h),
    w,
    h,
  };
}

// The smallest aspect-correct window framing BOTH `a` and `b` — the zoom-out extent used
// mid-flight so the transition shows where it's going instead of panning blind at high zoom.
function bridgeWindow(a: Rect, b: Rect, vb: Rect): Rect {
  const x = Math.min(a.x, b.x);
  const y = Math.min(a.y, b.y);
  const uw = Math.max(a.x + a.w, b.x + b.w) - x;
  const uh = Math.max(a.y + a.h, b.y + b.h) - y;
  let w = Math.min(Math.max(uw, uh * ASPECT) * 1.08, vb.w);
  let h = w / ASPECT;
  if (h > vb.h) {
    h = vb.h;
    w = Math.min(h * ASPECT, vb.w);
  }
  const cx = x + uw / 2;
  const cy = y + uh / 2;
  return clampRect({ x: cx - w / 2, y: cy - h / 2, w, h }, vb);
}

const easeInOut = (t: number) => (t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2);
const FLY_MS = 850;

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

  // The viewBox actually drawn. It animates from question to question (see the effect);
  // `win` is the settled destination for the current target.
  const [view, setView] = useState<Rect>(win);
  const cur = useRef<Rect>(win); // latest on-screen window (source for the next fly's start)
  const prevFocus = useRef<string | null>(null);
  const raf = useRef<number | null>(null);

  // Fly from the previous window to the new one when the target changes: zoom OUT through a
  // bridge that frames both, then IN — so it's easy to see where the new location sits
  // relative to the last (mirrors the iOS drills). First render / same target: snap.
  useEffect(() => {
    if (prevFocus.current === null || prevFocus.current === focusId) {
      prevFocus.current = focusId;
      cur.current = win;
      setView(win);
      return;
    }
    prevFocus.current = focusId;
    const from = cur.current;
    const to = win;
    const bridge = bridgeWindow(from, to, a.viewBox);
    const extraW = Math.max(0, bridge.w - Math.max(from.w, to.w)); // 0 when already overlapping
    const cx0 = from.x + from.w / 2, cy0 = from.y + from.h / 2;
    const cx1 = to.x + to.w / 2, cy1 = to.y + to.h / 2;
    let start: number | null = null;
    const step = (ts: number) => {
      if (start === null) start = ts;
      const t = Math.min(1, (ts - start) / FLY_MS);
      const e = easeInOut(t);
      const w = from.w + (to.w - from.w) * e + extraW * 4 * t * (1 - t); // bulge out mid-flight
      const h = w / ASPECT;
      const cx = cx0 + (cx1 - cx0) * e;
      const cy = cy0 + (cy1 - cy0) * e;
      const v = clampRect({ x: cx - w / 2, y: cy - h / 2, w, h }, a.viewBox);
      cur.current = v;
      setView(v);
      if (t < 1) raf.current = requestAnimationFrame(step);
    };
    if (raf.current) cancelAnimationFrame(raf.current);
    raf.current = requestAnimationFrame(step);
    return () => {
      if (raf.current) cancelAnimationFrame(raf.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [focusId]);

  function fillFor(id: string): string | undefined {
    if (highlightId && id === highlightId) return HIGHLIGHT;
    if (revealed && id === targetId) return CORRECT;
    if (revealed && pickedId && id === pickedId && pickedId !== targetId) return WRONG;
    return undefined; // → CSS .region fill (with hover)
  }

  // Memoized so the ~60fps viewBox animation re-renders only the <svg> attribute, not all
  // ~170 region paths (they only depend on the fill/interaction state, not the viewport).
  const shapes = useMemo(
    () => (
      <>
        {a.neighbors.map((d, i) => (
          <path key={`n${i}`} d={d} fill={NEIGHBOR} stroke="#4a4e52" strokeWidth={0.4} />
        ))}
        {a.regions.map((r) => {
          const fixed = fillFor(r.id);
          return (
            <path
              key={r.id}
              d={r.path}
              className={fixed ? undefined : "geomap-region"}
              fill={fixed ?? LAND}
              stroke={LAND_STROKE}
              strokeWidth={0.4}
              onClick={interactive && !revealed ? () => onPick?.(r.id) : undefined}
            />
          );
        })}
        {a.lakes.map((d, i) => (
          <path key={`l${i}`} d={d} fill={SEA} stroke={SEA} strokeWidth={0.3} />
        ))}
        {a.rivers.map((d, i) => (
          <path key={`r${i}`} d={d} fill="none" stroke={RIVER} strokeWidth={1.2} />
        ))}
      </>
    ),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [a, interactive, revealed, pickedId, highlightId, targetId, onPick],
  );

  // Land fill is set explicitly on each path (above), so it never depends on scoped CSS.
  // Hover/cursor is a plain global rule gated by the `gm-live` wrapper class (only present
  // while the map is interactive); CSS `fill` overrides the presentation attribute.
  const live = interactive && !revealed;
  return (
    <div
      className={`${className}${live ? " gm-live" : ""}`}
      style={{ background: SEA, aspectRatio: `${ASPECT}`, borderRadius: 10, overflow: "hidden" }}
    >
      <svg
        viewBox={`${view.x} ${view.y} ${view.w} ${view.h}`}
        preserveAspectRatio="xMidYMid meet"
        width="100%"
        height="100%"
        role="img"
      >
        {shapes}
      </svg>
      <style>{`.geomap-region{transition:fill .12s}.gm-live .geomap-region{cursor:pointer}.gm-live .geomap-region:hover{fill:#a8c07e}`}</style>
    </div>
  );
}
