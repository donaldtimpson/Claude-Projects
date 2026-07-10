"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

function toSlug(s: string) {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}

type Course = { id: string; title: string };

export default function CategoryEditor({
  categoryId,
  initialName,
  initialSlug,
  allCourses,
  initialAssignedIds,
}: {
  categoryId: string;
  initialName: string;
  initialSlug: string;
  allCourses: Course[];
  initialAssignedIds: string[];
}) {
  const router = useRouter();

  const [name, setName] = useState(initialName);
  const [slug, setSlug] = useState(initialSlug);
  const [slugEdited, setSlugEdited] = useState(false);
  const [assigned, setAssigned] = useState<Set<string>>(new Set(initialAssignedIds));

  const [savingMeta, setSavingMeta] = useState(false);
  const [savingCourses, setSavingCourses] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [metaError, setMetaError] = useState("");
  const [coursesError, setCoursesError] = useState("");

  function handleNameChange(v: string) {
    setName(v);
    if (!slugEdited) setSlug(toSlug(v));
  }

  function toggleCourse(id: string) {
    setAssigned((prev) => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  }

  async function saveMeta(e: React.FormEvent) {
    e.preventDefault();
    setSavingMeta(true);
    setMetaError("");
    const res = await fetch(`/api/categories/${categoryId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name, slug }),
    });
    setSavingMeta(false);
    if (!res.ok) {
      const data = await res.json();
      setMetaError(data.error ?? "Failed to save");
      return;
    }
    router.refresh();
  }

  async function saveCourses(e: React.FormEvent) {
    e.preventDefault();
    setSavingCourses(true);
    setCoursesError("");
    const res = await fetch(`/api/categories/${categoryId}/courses`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ courseIds: Array.from(assigned) }),
    });
    setSavingCourses(false);
    if (!res.ok) {
      setCoursesError("Failed to save course assignments");
      return;
    }
    router.refresh();
  }

  async function deleteCategory() {
    if (!confirm(`Delete category "${name}"? This cannot be undone.`)) return;
    setDeleting(true);
    await fetch(`/api/categories/${categoryId}`, { method: "DELETE" });
    router.push("/admin/categories");
    router.refresh();
  }

  return (
    <div className="space-y-10">
      {/* Name / slug */}
      <section className="space-y-4">
        <h2 className="font-semibold text-parchment">Details</h2>
        <form onSubmit={saveMeta} className="space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1">
              <label className="text-xs text-parchment-dim">Name</label>
              <input
                value={name}
                onChange={(e) => handleNameChange(e.target.value)}
                className="w-full bg-crimson-800 border border-crimson-700 rounded-lg px-3 py-2 text-sm text-parchment focus:outline-none focus:border-gold-500"
                required
              />
            </div>
            <div className="space-y-1">
              <label className="text-xs text-parchment-dim">Slug</label>
              <input
                value={slug}
                onChange={(e) => { setSlug(e.target.value); setSlugEdited(true); }}
                className="w-full bg-crimson-800 border border-crimson-700 rounded-lg px-3 py-2 text-sm text-parchment font-mono focus:outline-none focus:border-gold-500"
                required
              />
            </div>
          </div>
          {metaError && <p className="text-red-400 text-sm">{metaError}</p>}
          <div className="flex items-center justify-between">
            <button
              type="submit"
              disabled={savingMeta}
              className="px-4 py-2 bg-gold-500 hover:bg-gold-400 disabled:opacity-50 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
            >
              {savingMeta ? "Saving…" : "Save Details"}
            </button>
            <button
              type="button"
              onClick={deleteCategory}
              disabled={deleting}
              className="text-sm text-red-400 hover:text-red-300 transition-colors disabled:opacity-50"
            >
              {deleting ? "Deleting…" : "Delete Category"}
            </button>
          </div>
        </form>
      </section>

      {/* Course assignment */}
      <section className="space-y-4">
        <h2 className="font-semibold text-parchment">Courses in this Category</h2>
        <form onSubmit={saveCourses} className="space-y-4">
          <ul className="space-y-2">
            {allCourses.map((course) => (
              <li key={course.id}>
                <label className="flex items-center gap-3 cursor-pointer group">
                  <input
                    type="checkbox"
                    checked={assigned.has(course.id)}
                    onChange={() => toggleCourse(course.id)}
                    className="accent-gold-500 w-4 h-4 shrink-0"
                  />
                  <span className="text-sm text-parchment group-hover:text-gold-300 transition-colors">
                    {course.title}
                  </span>
                </label>
              </li>
            ))}
          </ul>
          {coursesError && <p className="text-red-400 text-sm">{coursesError}</p>}
          <button
            type="submit"
            disabled={savingCourses}
            className="px-4 py-2 bg-gold-500 hover:bg-gold-400 disabled:opacity-50 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
          >
            {savingCourses ? "Saving…" : "Save Course Assignments"}
          </button>
        </form>
      </section>
    </div>
  );
}
