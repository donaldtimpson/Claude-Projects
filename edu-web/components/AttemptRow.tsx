"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";

function scoreColor(p: number) {
  if (p === 100) return "text-green-400";
  if (p >= 70) return "text-gold-400";
  return "text-red-400";
}

export default function AttemptRow({
  attemptId,
  label,
  subtitle,
  subtitleHref,
  date,
  score,
  total,
}: {
  attemptId: string;
  label: string;
  subtitle?: string;
  subtitleHref?: string;
  date: string;
  score: number;
  total: number;
}) {
  const router = useRouter();
  const p = Math.round((score / total) * 100);

  return (
    <div
      onClick={() => router.push(`/dashboard/attempt/${attemptId}`)}
      className="group cursor-pointer bg-crimson-900 border border-crimson-700 rounded-xl p-4 flex items-center gap-4 hover:border-gold-500 transition-colors"
    >
      <div className="flex-1 min-w-0">
        {subtitle && subtitleHref && (
          <Link
            href={subtitleHref}
            onClick={(e) => e.stopPropagation()}
            className="text-xs text-parchment-dim hover:text-gold-300 transition-colors mb-0.5 block truncate"
          >
            {subtitle} ↗
          </Link>
        )}
        <p className="text-sm font-medium text-parchment group-hover:text-gold-300 transition-colors line-clamp-1">
          {label}
        </p>
        <p className="text-xs text-parchment-dim mt-0.5">{date}</p>
      </div>
      <div className="text-right shrink-0">
        <p className={`text-lg font-bold ${scoreColor(p)}`}>
          {score}/{total}
        </p>
        <p className={`text-xs ${scoreColor(p)}`}>{p}%</p>
      </div>
    </div>
  );
}
