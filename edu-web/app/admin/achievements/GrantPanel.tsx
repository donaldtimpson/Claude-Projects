"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { grantAchievement, revokeAchievement } from "./actions";

type CatalogBadge = { key: string; name: string; tier: string; category: string };
type UserView = { id: string; handle: string; name: string | null; email: string; granted: string[] };

export default function GrantPanel({ users, catalog }: { users: UserView[]; catalog: CatalogBadge[] }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [picks, setPicks] = useState<Record<string, string>>({});
  const nameOf = (key: string) => catalog.find((b) => b.key === key)?.name ?? key;

  function grant(userId: string) {
    const key = picks[userId] ?? catalog[0]?.key;
    if (!key) return;
    startTransition(async () => {
      await grantAchievement(userId, key);
      router.refresh();
    });
  }

  function revoke(userId: string, key: string) {
    startTransition(async () => {
      await revokeAchievement(userId, key);
      router.refresh();
    });
  }

  return (
    <div className="space-y-3">
      {users.length === 0 && <p className="text-parchment-dim text-sm">No registered students yet.</p>}
      {users.map((u) => (
        <div key={u.id} className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 space-y-3">
          <div className="flex items-center justify-between gap-4">
            <div className="min-w-0">
              <p className="text-sm font-medium text-gold-300">{u.handle}</p>
              <p className="text-xs text-parchment-dim truncate">
                {u.name ? `${u.name} · ` : ""}
                {u.email}
              </p>
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <select
                value={picks[u.id] ?? catalog[0]?.key}
                onChange={(e) => setPicks((p) => ({ ...p, [u.id]: e.target.value }))}
                className="bg-crimson-950 border border-crimson-700 rounded px-2 py-1.5 text-xs text-parchment max-w-[12rem]"
              >
                {catalog.map((b) => (
                  <option key={b.key} value={b.key}>
                    {b.name} ({b.tier})
                  </option>
                ))}
              </select>
              <button
                onClick={() => grant(u.id)}
                disabled={pending}
                className="font-display text-xs tracking-wider uppercase bg-gold-600 hover:bg-gold-500 disabled:opacity-50 text-crimson-950 rounded px-3 py-1.5 font-semibold transition-colors"
              >
                Grant
              </button>
            </div>
          </div>

          {u.granted.length > 0 && (
            <div className="flex flex-wrap gap-2 pt-1 border-t border-crimson-800">
              {u.granted.map((key) => (
                <span
                  key={key}
                  className="inline-flex items-center gap-1.5 text-xs bg-crimson-800 text-parchment-dim rounded px-2 py-1"
                >
                  ✦ {nameOf(key)}
                  <button
                    onClick={() => revoke(u.id, key)}
                    disabled={pending}
                    aria-label={`Revoke ${nameOf(key)}`}
                    className="text-parchment-dim hover:text-red-400 transition-colors"
                  >
                    ✕
                  </button>
                </span>
              ))}
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
