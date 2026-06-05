"use client";

import { createContext, useCallback, useContext, useState } from "react";

export type ToastBadge = { key: string; name: string; tier: string; blurb: string };
type ToastItem = ToastBadge & { id: number };

const ToastCtx = createContext<{ celebrate: (badges: ToastBadge[]) => void } | null>(null);

export function useToast() {
  return useContext(ToastCtx);
}

let counter = 0;

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = useState<ToastItem[]>([]);

  const dismiss = useCallback((id: number) => {
    setItems((cur) => cur.filter((i) => i.id !== id));
  }, []);

  const celebrate = useCallback(
    (badges: ToastBadge[]) => {
      if (!badges?.length) return;
      const added = badges.map((b) => ({ ...b, id: ++counter }));
      setItems((cur) => [...cur, ...added]);
      added.forEach((a) => setTimeout(() => dismiss(a.id), 6000));
    },
    [dismiss],
  );

  return (
    <ToastCtx.Provider value={{ celebrate }}>
      {children}
      <div className="fixed bottom-4 right-4 z-[60] flex flex-col gap-2 w-[20rem] max-w-[calc(100vw-2rem)] pointer-events-none">
        {items.map((t) => (
          <AchievementToast key={t.id} badge={t} onClose={() => dismiss(t.id)} />
        ))}
      </div>
    </ToastCtx.Provider>
  );
}

function AchievementToast({ badge, onClose }: { badge: ToastItem; onClose: () => void }) {
  return (
    <div className="pointer-events-auto relative rounded-xl p-[1.5px] bg-gradient-to-r from-gold-400 via-gold-200 to-gold-400 shadow-[0_0_25px_-8px] shadow-gold-400/60 animate-[fadeIn_0.25s_ease-out]">
      <div className="rounded-xl bg-crimson-950 px-4 py-3 pr-8">
        <p className="font-display text-[10px] uppercase tracking-[0.2em] text-gold-300 mb-0.5">
          ✦ Achievement Unlocked
        </p>
        <p className="text-sm font-medium text-parchment">
          {badge.name}
          <span className="text-parchment-dim font-normal"> · {badge.tier}</span>
        </p>
        <p className="text-xs text-parchment-dim mt-0.5 leading-snug">{badge.blurb}</p>
        <button
          onClick={onClose}
          aria-label="Dismiss"
          className="absolute top-2 right-2 text-parchment-dim hover:text-gold-300 transition-colors text-sm leading-none"
        >
          ✕
        </button>
      </div>
    </div>
  );
}
