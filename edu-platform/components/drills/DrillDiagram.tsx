"use client";

import type { DiagramSpec } from "@/lib/drills/types";

// Inline SVG diagrams for drills — no image hosting. Same approach as the course
// map (components in map/CourseMapView.tsx): a <svg viewBox>, <defs>/<marker>,
// <line>/<path>, <text>. SVG's y-axis points down, so screen-y = center - value.

const SIZE = 240;
const C = SIZE / 2; // center x/y

const AXIS = "var(--color-crimson-600)";
const GOLD = "var(--color-gold-400)";
const GOLD_DIM = "var(--color-gold-600)";
const FAINT = "var(--color-crimson-700)";
const TEXT = "var(--color-parchment-dim)";

// Sample a circular arc (CCW from 0 to `deg`) as an SVG path string.
function arcPath(deg: number, radius: number): string {
  const steps = Math.max(2, Math.round(Math.abs(deg) / 6));
  const pts: string[] = [];
  for (let i = 0; i <= steps; i++) {
    const a = ((deg * (i / steps)) * Math.PI) / 180;
    const x = C + radius * Math.cos(a);
    const y = C - radius * Math.sin(a);
    pts.push(`${i === 0 ? "M" : "L"} ${x.toFixed(1)} ${y.toFixed(1)}`);
  }
  return pts.join(" ");
}

export default function DrillDiagram({ spec }: { spec: DiagramSpec }) {
  return (
    <svg
      viewBox={`0 0 ${SIZE} ${SIZE}`}
      className="w-56 h-56 mx-auto"
      role="img"
      aria-label={spec.kind === "vector" ? "Vector diagram" : "Unit circle diagram"}
    >
      <defs>
        <marker id="drill-arrow" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto">
          <path d="M 0 1 L 9.5 5 L 0 9 z" fill={GOLD} />
        </marker>
      </defs>
      {spec.kind === "vector" ? <VectorDiagram spec={spec} /> : <UnitCircleDiagram spec={spec} />}
    </svg>
  );
}

function Axes() {
  return (
    <>
      <line x1={14} y1={C} x2={SIZE - 14} y2={C} stroke={AXIS} strokeWidth={1} />
      <line x1={C} y1={14} x2={C} y2={SIZE - 14} stroke={AXIS} strokeWidth={1} />
    </>
  );
}

function VectorDiagram({ spec }: { spec: Extract<DiagramSpec, { kind: "vector" }> }) {
  const rad = (spec.angleDeg * Math.PI) / 180;
  const len = 92; // arrow is schematic — always ~this long regardless of magnitude
  const ex = C + len * Math.cos(rad);
  const ey = C - len * Math.sin(rad);

  return (
    <>
      <Axes />
      {/* dashed component projections */}
      <line x1={ex} y1={ey} x2={ex} y2={C} stroke={GOLD_DIM} strokeWidth={1} strokeDasharray="4 3" />
      <line x1={ex} y1={ey} x2={C} y2={ey} stroke={GOLD_DIM} strokeWidth={1} strokeDasharray="4 3" />
      {/* angle arc + label */}
      <path d={arcPath(spec.angleDeg, 26)} fill="none" stroke={GOLD} strokeWidth={1.25} />
      <text
        x={C + 36 * Math.cos((rad / 2))}
        y={C - 36 * Math.sin((rad / 2)) + 4}
        fill={TEXT}
        fontSize={11}
        textAnchor="middle"
      >
        {spec.angleDeg}°
      </text>
      {/* the vector */}
      <line x1={C} y1={C} x2={ex} y2={ey} stroke={GOLD} strokeWidth={2.5} markerEnd="url(#drill-arrow)" />
      {/* component axis labels */}
      <text x={(C + ex) / 2} y={C + 14} fill={TEXT} fontSize={11} textAnchor="middle">vₓ</text>
      <text x={ex + (ex >= C ? 8 : -8)} y={(C + ey) / 2} fill={TEXT} fontSize={11} textAnchor="middle">v_y</text>
      <text x={ex} y={ey - 6} fill={GOLD} fontSize={11} textAnchor="middle">|v|={spec.magnitude}</text>
    </>
  );
}

function UnitCircleDiagram({ spec }: { spec: Extract<DiagramSpec, { kind: "unit-circle" }> }) {
  const R = 86;
  const px = C + R * Math.cos(spec.angleRad);
  const py = C - R * Math.sin(spec.angleRad);
  const deg = Math.round((spec.angleRad * 180) / Math.PI);

  const emphCos = spec.fn === "cos" || spec.fn === "tan";
  const emphSin = spec.fn === "sin" || spec.fn === "tan";

  return (
    <>
      <circle cx={C} cy={C} r={R} fill="none" stroke={FAINT} strokeWidth={1} />
      <Axes />
      {/* reference triangle legs: horizontal = cos, vertical = sin */}
      <line
        x1={C} y1={C} x2={px} y2={C}
        stroke={emphCos ? GOLD : FAINT}
        strokeWidth={emphCos ? 2.5 : 1}
      />
      <line
        x1={px} y1={C} x2={px} y2={py}
        stroke={emphSin ? GOLD : FAINT}
        strokeWidth={emphSin ? 2.5 : 1}
      />
      {/* radius to the angle + point */}
      <line x1={C} y1={C} x2={px} y2={py} stroke={GOLD_DIM} strokeWidth={1.5} />
      <circle cx={px} cy={py} r={3.5} fill={GOLD} />
      {/* angle arc + θ label */}
      <path d={arcPath(deg, 24)} fill="none" stroke={GOLD} strokeWidth={1.25} />
      <text
        x={C + 34 * Math.cos(spec.angleRad / 2)}
        y={C - 34 * Math.sin(spec.angleRad / 2) + 4}
        fill={TEXT}
        fontSize={11}
        textAnchor="middle"
      >
        θ
      </text>
    </>
  );
}
