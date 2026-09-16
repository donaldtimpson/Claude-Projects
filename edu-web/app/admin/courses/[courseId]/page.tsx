import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import SyllabusEditor from "../../SyllabusEditor";
import LectureRow from "./LectureRow";
import LectureOrderEditor from "./LectureOrderEditor";
import LessonBankToggle from "./LessonBankToggle";
import { grammarLessonDrills } from "@/lib/drills/grammar";

// Lectures tab of the course hub. Header, title, Current toggle and the tab
// bar are provided by the surrounding layout.tsx.
export default async function AdminCourseLectures({ params }: { params: Promise<{ courseId: string }> }) {
  const { courseId } = await params;
  const course = await db.course.findUnique({
    where: { id: courseId },
    include: { videos: { orderBy: { position: "asc" } } },
  });
  if (!course) notFound();

  const videoIds = course.videos.map((v) => v.id);
  const [allQuestions, allNotes, allLessonLinks, problemSets, allPsLinks] = await Promise.all([
    db.quizQuestion.findMany({ where: { videoId: { in: videoIds } }, orderBy: { position: "asc" } }),
    db.lectureNote.findMany({ where: { videoId: { in: videoIds } } }),
    db.videoLesson.findMany({ where: { videoId: { in: videoIds } }, select: { videoId: true, lessonSlug: true } }),
    db.problemSet.findMany({
      where: { courseId },
      orderBy: { createdAt: "asc" },
      select: { id: true, title: true, isDraft: true },
    }),
    db.problemSetVideo.findMany({
      where: { videoId: { in: videoIds } },
      select: { videoId: true, problemSetId: true },
    }),
  ]);

  const grammarEnabled = course.lessonBank === "grammar";
  const lessonOptions = grammarLessonDrills.map((d) => ({ slug: d.slug, title: d.title }));
  const linkedByVideo = new Map<string, string[]>();
  for (const vl of allLessonLinks) {
    linkedByVideo.set(vl.videoId, [...(linkedByVideo.get(vl.videoId) ?? []), vl.lessonSlug]);
  }
  const psByVideo = new Map<string, string[]>();
  for (const pv of allPsLinks) {
    psByVideo.set(pv.videoId, [...(psByVideo.get(pv.videoId) ?? []), pv.problemSetId]);
  }

  return (
    <div className="space-y-8">
      <div className="flex items-center gap-3 flex-wrap">
        <LessonBankToggle courseId={course.id} initial={course.lessonBank} />
        <span className="text-xs text-parchment-dim">
          Show the Grammar lesson-drill linker on this course&apos;s lectures.
        </span>
      </div>

      {course.videos.length > 1 && (
        <LectureOrderEditor
          courseId={course.id}
          initialManualOrder={course.manualOrder}
          lectures={course.videos.map((v) => ({ id: v.id, title: v.title }))}
        />
      )}

      <SyllabusEditor courseId={course.id} initialSyllabus={course.syllabus} />

      <section className="space-y-3">
        <h2 className="font-display text-sm tracking-[0.15em] uppercase text-parchment-dim">Lectures</h2>
        {course.videos.map((video, idx) => {
          const questions = allQuestions
            .filter((q) => q.videoId === video.id)
            .map((q) => ({
              id: q.id,
              prompt: q.prompt,
              options: q.options as string[],
              correctIndex: q.correctIndex,
              explanation: q.explanation,
              position: q.position,
              isDraft: q.isDraft,
            }));
          const noteRow = allNotes.find((n) => n.videoId === video.id);
          return (
            <LectureRow
              key={video.id}
              index={idx + 1}
              title={video.title}
              videoId={video.id}
              printHref={`/courses/${courseId}/${video.id}/notes`}
              initialNote={noteRow ? { id: noteRow.id, content: noteRow.content, isDraft: noteRow.isDraft } : null}
              initialQuestions={questions}
              lessons={lessonOptions}
              linkedLessons={linkedByVideo.get(video.id) ?? []}
              grammarEnabled={grammarEnabled}
              problemSets={problemSets}
              linkedProblemSets={psByVideo.get(video.id) ?? []}
            />
          );
        })}
      </section>
    </div>
  );
}
