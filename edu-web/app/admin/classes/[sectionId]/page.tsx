import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import { getSectionGradebook } from "@/lib/gradebook";
import { deleteAssignment, updateAssignment } from "@/lib/assignments";
import { setGradeWeights } from "@/lib/grades";
import { removeEnrollment } from "@/lib/classes";
import { grammarLessonDrills } from "@/lib/drills/grammar";
import AssignForm from "./AssignForm";
import Gradebook from "./Gradebook";
import SectionNameEditor from "./SectionNameEditor";
import CategoryManager from "./CategoryManager";
import ProblemSetToggles from "./ProblemSetToggles";

export const dynamic = "force-dynamic";

export default async function GradebookPage({ params }: { params: Promise<{ sectionId: string }> }) {
  const { sectionId } = await params;
  const gb = await getSectionGradebook(sectionId);
  if (!gb) notFound();

  const [problemSets, videos, assignments] = await Promise.all([
    db.problemSet.findMany({
      where: { courseId: gb.section.course.id, isDraft: false },
      orderBy: { createdAt: "desc" },
      select: { id: true, title: true, points: true },
    }),
    db.video.findMany({
      where: { courseId: gb.section.course.id },
      orderBy: [{ publishedAt: "asc" }, { position: "asc" }],
      select: { id: true, title: true },
    }),
    db.assignment.findMany({
      where: { sectionId },
      orderBy: { createdAt: "asc" },
      include: {
        problemSet: {
          select: {
            id: true,
            title: true,
            solutionsPublic: true,
            isDraft: true,
            videos: { select: { video: { select: { id: true, title: true, position: true } } } },
          },
        },
        _count: { select: { submissions: true } },
      },
    }),
  ]);

  const lessons = grammarLessonDrills.map((d) => ({ slug: d.slug, title: d.title }));
  const lessonTitle = new Map(lessons.map((l) => [l.slug, l.title]));
  const assignmentTitle = (a: (typeof assignments)[number]) =>
    a.title ?? a.problemSet?.title ?? lessonTitle.get(a.lessonSlug ?? "") ?? a.lessonSlug ?? "";
  assignments.sort((x, y) =>
    assignmentTitle(x).localeCompare(assignmentTitle(y), undefined, { numeric: true, sensitivity: "base" }),
  );
  const w = gb.config.weights;
  const customWeight = gb.customCategories.reduce((s, c) => s + c.weight, 0);
  const weightTotal = w.attendance + w.quizzes + w.test + w.homework + w.midterm + w.final + customWeight;

  return (
    <main className="max-w-6xl mx-auto px-6 py-10 space-y-6">
      <div>
        <Link href="/admin/classes" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
          ← Classes
        </Link>
        <SectionNameEditor sectionId={sectionId} initialName={gb.section.name} />
        <p className="text-sm text-parchment-dim mt-1">
          <Link href={`/courses/${gb.section.course.id}`} className="hover:text-gold-300 transition-colors">
            {gb.section.course.title}
          </Link>{" "}
          · {gb.students.length} student{gb.students.length === 1 ? "" : "s"} · {gb.totalLectures} lectures ·{" "}
          {gb.totalQuizzes} quizzes{gb.hasTest ? " · final test" : ""}
        </p>
      </div>

      {/* Grade weights */}
      <details className="bg-crimson-900 border border-crimson-700 rounded-xl px-4 py-3">
        <summary className="cursor-pointer text-sm text-parchment">
          Grade weights (total {weightTotal}%) &amp; exam maxes
        </summary>
        <form action={setGradeWeights} className="mt-3 flex flex-wrap items-end gap-3">
          <input type="hidden" name="sectionId" value={sectionId} />
          {(
            [
              ["attendance", "Attendance"],
              ["quizzes", "Quizzes"],
              ["test", "Course Test"],
              ["homework", "Homework"],
              ["midterm", "Midterm"],
              ["final", "Final"],
            ] as const
          ).map(([key, label]) => (
            <label key={key} className="text-xs text-parchment-dim flex flex-col gap-1">
              {label} %
              <input
                name={key}
                type="number"
                min={0}
                defaultValue={gb.config.weights[key]}
                className="w-20 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-2 py-1.5 text-parchment text-sm transition-colors"
              />
            </label>
          ))}
          <span className="text-parchment-dim self-center">|</span>
          {(
            [
              ["midtermMax", "Midterm max", gb.config.midtermMax],
              ["finalMax", "Final max", gb.config.finalMax],
            ] as const
          ).map(([key, label, val]) => (
            <label key={key} className="text-xs text-parchment-dim flex flex-col gap-1">
              {label}
              <input
                name={key}
                type="number"
                min={1}
                defaultValue={val}
                className="w-20 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-2 py-1.5 text-parchment text-sm transition-colors"
              />
            </label>
          ))}
          <button
            type="submit"
            className="font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded px-4 py-2 font-semibold transition-colors"
          >
            Save weights
          </button>
        </form>
        <CategoryManager
          sectionId={sectionId}
          categories={gb.customCategories.map((c) => ({ id: c.id, name: c.name, weight: c.weight }))}
        />
      </details>

      {gb.students.length === 0 ? (
        <p className="text-parchment-dim text-sm">No students registered yet — share the join code from Classes.</p>
      ) : (
        <Gradebook gb={gb} sectionId={sectionId} />
      )}

      {/* Assignments */}
      <section className="space-y-4 pt-4">
        <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
          Homework Assignments
        </h2>
        <AssignForm sectionId={sectionId} problemSets={problemSets} videos={videos} lessons={lessons} />
        {problemSets.length === 0 && (
          <p className="text-xs text-parchment-dim">
            <Link
              href={`/admin/courses/${gb.section.course.id}/problem-sets`}
              className="text-gold-400 hover:text-gold-300 transition-colors"
            >
              Create &amp; publish a problem set →
            </Link>
          </p>
        )}

        {assignments.length > 0 && (
          <ul className="space-y-2">
            {assignments.map((a) => {
              const isLesson = Boolean(a.lessonSlug);
              const title =
                a.title ?? a.problemSet?.title ?? lessonTitle.get(a.lessonSlug ?? "") ?? a.lessonSlug ?? "Assignment";
              const linkedLectures = (a.problemSet?.videos ?? [])
                .map((pv) => pv.video)
                .sort((x, y) => x.position - y.position);
              return (
                <li key={a.id} className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 space-y-3">
                  <div className="flex items-center justify-between gap-4">
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-parchment truncate">{title}</p>
                      <p className="text-xs text-parchment-dim mt-0.5">
                        {isLesson
                          ? `Lesson drill · auto-graded (ace = full credit) · ${a.points} pts`
                          : `${a.problemSet ? "Problem set" : "Paper"} · ${a.points} pts · ${a._count.submissions}/${gb.students.length} submitted`}
                      </p>
                      {a.problemSet &&
                        (linkedLectures.length > 0 ? (
                          <p
                            className="text-xs text-parchment-dim mt-0.5 truncate"
                            title={linkedLectures.map((v) => v.title).join(", ")}
                          >
                            ↔ {linkedLectures.map((v) => v.title).join(", ")}
                          </p>
                        ) : (
                          <p className="text-xs text-amber-300 mt-0.5">⚠ no lecture linked</p>
                        ))}
                    </div>
                    <div className="flex items-center gap-3 shrink-0 text-sm">
                      {a.problemSet && (
                        <>
                          <ProblemSetToggles
                            problemSetId={a.problemSet.id}
                            isDraft={a.problemSet.isDraft}
                            solutionsPublic={a.problemSet.solutionsPublic}
                          />
                          <Link
                            href={`/admin/problem-sets/${a.problemSet.id}`}
                            className="text-parchment-dim hover:text-gold-300 transition-colors"
                            title="Edit problem set"
                          >
                            edit ↗
                          </Link>
                        </>
                      )}
                      {isLesson ? (
                        <Link href={`/drills/${a.lessonSlug}`} className="text-gold-400 hover:text-gold-300 transition-colors">
                          open drill →
                        </Link>
                      ) : (
                        <Link
                          href={`/admin/classes/${sectionId}/assignments/${a.id}`}
                          className="text-gold-400 hover:text-gold-300 transition-colors"
                        >
                          submissions →
                        </Link>
                      )}
                      <form action={deleteAssignment}>
                        <input type="hidden" name="id" value={a.id} />
                        <button type="submit" className="text-parchment-dim hover:text-red-400 transition-colors">
                          delete
                        </button>
                      </form>
                    </div>
                  </div>

                  <details className="text-sm">
                    <summary className="cursor-pointer text-parchment-dim hover:text-gold-300 transition-colors w-fit">
                      edit
                    </summary>
                    <form action={updateAssignment} className="mt-3 flex flex-wrap items-end gap-3">
                      <input type="hidden" name="id" value={a.id} />
                      <label className="flex flex-col gap-1 text-xs text-parchment-dim">
                        Label
                        <input
                          name="title"
                          defaultValue={a.title ?? ""}
                          placeholder={a.problemSet?.title ?? lessonTitle.get(a.lessonSlug ?? "") ?? ""}
                          className="w-56 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-3 py-2 text-parchment text-sm placeholder:text-parchment-dim/60 transition-colors"
                        />
                      </label>
                      <label className="flex flex-col gap-1 text-xs text-parchment-dim">
                        Points
                        <input
                          name="points"
                          type="number"
                          min={0}
                          defaultValue={a.points}
                          className="w-20 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-3 py-2 text-parchment text-sm transition-colors"
                        />
                      </label>
                      <button
                        type="submit"
                        className="shrink-0 font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded px-4 py-2 font-semibold transition-colors"
                      >
                        Save
                      </button>
                    </form>
                  </details>
                </li>
              );
            })}
          </ul>
        )}
      </section>

      {/* Roster */}
      <section className="space-y-3 pt-4">
        <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
          Roster
        </h2>
        {gb.students.length === 0 ? (
          <p className="text-xs text-parchment-dim">No students registered yet.</p>
        ) : (
          <ul className="divide-y divide-crimson-800 border border-crimson-700 rounded-xl overflow-hidden">
            {gb.students.map((s) => (
              <li key={s.userId} className="flex items-center justify-between gap-4 px-4 py-2.5 bg-crimson-900/40">
                <div className="min-w-0">
                  <p className="text-sm text-parchment truncate">{s.name ?? "—"}</p>
                  <p className="text-xs text-parchment-dim truncate">{s.email}</p>
                </div>
                <form action={removeEnrollment} className="shrink-0">
                  <input type="hidden" name="sectionId" value={sectionId} />
                  <input type="hidden" name="userId" value={s.userId} />
                  <button type="submit" className="text-xs text-parchment-dim hover:text-red-400 transition-colors">
                    remove
                  </button>
                </form>
              </li>
            ))}
          </ul>
        )}
      </section>
    </main>
  );
}
