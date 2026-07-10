"use client";

import { useEffect } from "react";

// Auto-opens the browser's print dialog on load (where the user picks "Save as
// PDF"), and offers a manual button. Hidden from the printed output itself.
export default function PrintControls({ auto }: { auto: boolean }) {
  useEffect(() => {
    if (auto) {
      const t = setTimeout(() => window.print(), 400); // let fonts/KaTeX settle
      return () => clearTimeout(t);
    }
  }, [auto]);

  return (
    <div className="print:hidden flex justify-end mb-6">
      <button
        onClick={() => window.print()}
        className="px-4 py-2 rounded-lg bg-zinc-900 text-white text-sm font-medium hover:bg-zinc-700 transition-colors"
      >
        Download PDF
      </button>
    </div>
  );
}
