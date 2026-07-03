import Link from "next/link";
import { db } from "@/lib/db";
import { createSection, rotateJoinCode, removeEnrollment } from "@/lib/classes";

export const dynamic = "force-dynamic";

// Admin: create class sections (each with a join code), see rosters, and manage
// enrollment. Registration is only open on the currently-active course — a section
// on any other course keeps its roster but won't accept new join-code sign-ups.
export default async function AdminClassesPage() {
  const [courses, sections] = await Promise.all([
    db.course.findMany({
      orderBy: [{ isCurrent: "desc" }, { createdAt: "asc" }],
      select: { id: true, title: true, isCurrent: true },
    }),
    db.section.findMany({
      orderBy: { createdAt: "desc" },
      include: {
        course: { select: { id: true, title: true, isCurrent: true } },
        enrollments: {
          where: { status: "active" },
          orderBy: { enrolledAt: "asc" },
          include: { user: { select: { id: true, name: true, email: true } } },
        },
      },
    }),
  ]);

  return (
    <main className="max-w-4xl mx-auto px-6 py-10 space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-parchment">Classes</h1>
        <p className="text-sm text-parchment-dim mt-1">
          A section is a live class you teach. Students register with its join code — but only while
          the linked course is the <span className="text-gold-300">★ Current</span> course. Materials
          stay public regardless; registration only builds your roster for homework and grades.
        </p>
      </div>

      {/* Create a section */}
      <form action={createSection} className="bg-crimson-900 border border-crimson-700 rounded-xl p-5 space-y-3">
        <p className="font-medium text-parchment">New class section</p>
        <div className="flex flex-col sm:flex-row gap-2">
          <select
            name="courseId"
            required
            defaultValue={courses.find((c) => c.isCurrent)?.id ?? ""}
            className="flex-1 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment transition-colors"
          >
            <option value="" disabled>
              Choose a course…
            </option>
            {courses.map((c) => (
              <option key={c.id} value={c.id}>
                {c.title}
                {c.isCurrent ? " ★ (current)" : ""}
              </option>
            ))}
          </select>
          <input
            name="name"
            required
            placeholder="Section name (e.g. Fall 2026 · Period 3)"
            autoComplete="off"
            className="flex-1 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment placeholder:text-parchment-dim/60 transition-colors"
          />
          <button
            type="submit"
            className="shrink-0 font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded px-4 py-2.5 font-semibold transition-colors"
          >
            Create
          </button>
        </div>
      </form>

      {/* Existing sections */}
      {sections.length === 0 ? (
        <p className="text-parchment-dim text-sm">No class sections yet.</p>
      ) : (
        <div className="space-y-5">
          {sections.map((s) => (
            <div key={s.id} className="bg-crimson-900 border border-crimson-700 rounded-xl p-5 space-y-4">
              <div className="flex items-start justify-between gap-4 flex-wrap">
                <div className="min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <h2 className="font-semibold text-parchment">{s.name}</h2>
                    {s.course.isCurrent ? (
                      <span className="text-[11px] px-2 py-0.5 rounded-full border border-green-700 text-green-400 whitespace-nowrap">
                        registration open
                      </span>
                    ) : (
                      <span className="text-[11px] px-2 py-0.5 rounded-full border border-crimson-700 text-parchment-dim whitespace-nowrap">
                        registration closed
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-parchment-dim mt-1">
                    <Link href={`/courses/${s.course.id}`} className="hover:text-gold-300 transition-colors">
                      {s.course.title}
                    </Link>{" "}
                    · {s.enrollments.length} student{s.enrollments.length === 1 ? "" : "s"}
                  </p>
                </div>
                <div className="flex items-center gap-3 shrink-0">
                  <span
                    className="font-mono text-lg tracking-[0.3em] text-gold-300 bg-crimson-950 border border-crimson-700 rounded-lg px-3 py-1.5"
                    title="Join code"
                  >
                    {s.joinCode}
                  </span>
                  <form action={rotateJoinCode}>
                    <input type="hidden" name="sectionId" value={s.id} />
                    <button
                      type="submit"
                      className="text-xs text-parchment-dim hover:text-gold-300 transition-colors"
                      title="Generate a new code (invalidates the old one)"
                    >
                      ↻ rotate
                    </button>
                  </form>
                </div>
              </div>

              {s.enrollments.length > 0 && (
                <ul className="divide-y divide-crimson-800 border-t border-crimson-800">
                  {s.enrollments.map((e) => (
                    <li key={e.userId} className="flex items-center justify-between gap-4 py-2">
                      <div className="min-w-0">
                        <p className="text-sm text-parchment truncate">{e.user.name ?? "—"}</p>
                        <p className="text-xs text-parchment-dim truncate">
                          {e.user.email} · joined {new Date(e.enrolledAt).toLocaleDateString()}
                        </p>
                      </div>
                      <form action={removeEnrollment} className="shrink-0">
                        <input type="hidden" name="sectionId" value={s.id} />
                        <input type="hidden" name="userId" value={e.userId} />
                        <button
                          type="submit"
                          className="text-xs text-parchment-dim hover:text-red-400 transition-colors"
                        >
                          remove
                        </button>
                      </form>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          ))}
        </div>
      )}
    </main>
  );
}
