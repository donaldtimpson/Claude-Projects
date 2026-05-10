"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { ResourceKind } from "@prisma/client";
import { RESOURCE_KIND_OPTIONS } from "@/lib/resource-kinds";

type Course = { id: string; title: string };

export default function ResourceEditor({
  resourceId,
  initialTitle,
  initialUrl,
  initialKind,
  initialDescription,
  allCourses,
  initialAssignedIds,
}: {
  resourceId: string;
  initialTitle: string;
  initialUrl: string;
  initialKind: ResourceKind;
  initialDescription: string;
  allCourses: Course[];
  initialAssignedIds: string[];
}) {
  const router = useRouter();

  const [title, setTitle] = useState(initialTitle);
  const [url, setUrl] = useState(initialUrl);
  const [kind, setKind] = useState<ResourceKind>(initialKind);
  const [description, setDescription] = useState(initialDescription);
  const [assigned, setAssigned] = useState<Set<string>>(new Set(initialAssignedIds));

  const [savingMeta, setSavingMeta] = useState(false);
  const [savingCourses, setSavingCourses] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [metaError, setMetaError] = useState("");
  const [coursesError, setCoursesError] = useState("");

  function toggleCourse(id: string) {
    setAssigned((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  async function saveMeta(e: React.FormEvent) {
    e.preventDefault();
    setSavingMeta(true);
    setMetaError("");
    const res = await fetch(`/api/resources/${resourceId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title, url, kind, description }),
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
    const res = await fetch(`/api/resources/${resourceId}/courses`, {
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

  async function deleteResource() {
    if (!confirm(`Delete resource "${title}"? This cannot be undone.`)) return;
    setDeleting(true);
    await fetch(`/api/resources/${resourceId}`, { method: "DELETE" });
    router.push("/admin/resources");
    router.refresh();
  }

  return (
    <div className="space-y-10">
      {/* Details */}
      <section className="space-y-4">
        <h2 className="font-semibold text-parchment">Details</h2>
        <form onSubmit={saveMeta} className="space-y-3">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div className="space-y-1">
              <label className="text-xs text-parchment-dim">Title</label>
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full bg-crimson-800 border border-crimson-700 rounded-lg px-3 py-2 text-sm text-parchment focus:outline-none focus:border-gold-500"
                required
              />
            </div>
            <div className="space-y-1">
              <label className="text-xs text-parchment-dim">Kind</label>
              <select
                value={kind}
                onChange={(e) => setKind(e.target.value as ResourceKind)}
                className="w-full bg-crimson-800 border border-crimson-700 rounded-lg px-3 py-2 text-sm text-parchment focus:outline-none focus:border-gold-500"
              >
                {RESOURCE_KIND_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>{opt.label}</option>
                ))}
              </select>
            </div>
          </div>
          <div className="space-y-1">
            <label className="text-xs text-parchment-dim">URL</label>
            <input
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              className="w-full bg-crimson-800 border border-crimson-700 rounded-lg px-3 py-2 text-sm text-parchment font-mono focus:outline-none focus:border-gold-500"
              required
            />
          </div>
          <div className="space-y-1">
            <label className="text-xs text-parchment-dim">Description (optional)</label>
            <input
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full bg-crimson-800 border border-crimson-700 rounded-lg px-3 py-2 text-sm text-parchment focus:outline-none focus:border-gold-500"
            />
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
              onClick={deleteResource}
              disabled={deleting}
              className="text-sm text-red-400 hover:text-red-300 transition-colors disabled:opacity-50"
            >
              {deleting ? "Deleting…" : "Delete Resource"}
            </button>
          </div>
        </form>
      </section>

      {/* Course assignment */}
      <section className="space-y-4">
        <h2 className="font-semibold text-parchment">Courses Using This Resource</h2>
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
