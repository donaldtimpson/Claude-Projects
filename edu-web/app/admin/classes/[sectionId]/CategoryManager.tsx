"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { addGradeCategory, updateGradeCategory, deleteGradeCategory } from "@/lib/grades";

// Manage a section's custom grade categories (name + weight). Items and scores
// are handled in the grid; this is where categories are created, weighted, deleted.
export default function CategoryManager({
  sectionId,
  categories,
}: {
  sectionId: string;
  categories: { id: string; name: string; weight: number }[];
}) {
  const router = useRouter();
  const [newName, setNewName] = useState("");

  async function call(action: (fd: FormData) => Promise<void>, fields: Record<string, string>) {
    const fd = new FormData();
    for (const [k, v] of Object.entries(fields)) fd.set(k, v);
    await action(fd);
    router.refresh();
  }

  const input =
    "bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-2 py-1.5 text-parchment text-sm transition-colors";

  return (
    <div className="border-t border-crimson-800 pt-3 mt-4 space-y-2">
      <p className="text-xs font-display tracking-[0.15em] uppercase text-gold-400">Custom categories</p>
      {categories.map((c) => (
        <div key={c.id} className="flex items-center gap-2 flex-wrap">
          <input
            defaultValue={c.name}
            onBlur={(e) => e.target.value.trim() !== c.name && call(updateGradeCategory, { id: c.id, name: e.target.value })}
            className={`${input} w-48`}
          />
          <input
            type="number"
            min={0}
            defaultValue={c.weight}
            onBlur={(e) => Number(e.target.value) !== c.weight && call(updateGradeCategory, { id: c.id, weight: e.target.value })}
            className={`${input} w-16`}
          />
          <span className="text-xs text-parchment-dim">%</span>
          <button
            onClick={() => confirm(`Delete "${c.name}" and all its scores?`) && call(deleteGradeCategory, { id: c.id })}
            className="text-xs text-parchment-dim hover:text-red-400 transition-colors"
          >
            delete
          </button>
        </div>
      ))}
      <div className="flex items-center gap-2 pt-1">
        <input
          value={newName}
          onChange={(e) => setNewName(e.target.value)}
          placeholder="New category (e.g. Tests)"
          className={`${input} w-48 placeholder:text-parchment-dim/60`}
        />
        <button
          onClick={async () => {
            if (!newName.trim()) return;
            await call(addGradeCategory, { sectionId, name: newName.trim() });
            setNewName("");
          }}
          className="font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded px-3 py-1.5 font-semibold transition-colors"
        >
          Add
        </button>
      </div>
    </div>
  );
}
