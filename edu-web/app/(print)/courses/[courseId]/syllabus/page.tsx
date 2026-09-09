import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import MarkdownNotes from "@/components/MarkdownNotes";
import PrintControls from "@/components/PrintControls";

export const dynamic = "force-dynamic";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ courseId: string }>;
}): Promise<Metadata> {
  const { courseId } = await params;
  const course = await db.course.findUnique({ where: { id: courseId }, select: { title: true } });
  return { title: course ? `${course.title} — Syllabus` : "Syllabus", robots: { index: false } };
}

export default async function PrintSyllabusPage({
  params,
}: {
  params: Promise<{ courseId: string }>;
}) {
  const { courseId } = await params;

  const course = await db.course.findUnique({
    where: { id: courseId },
    select: { title: true, syllabus: true },
  });

  if (!course || !course.syllabus.trim()) notFound();

  return (
    <main className="max-w-3xl mx-auto px-8 py-10">
      <PrintControls auto={true} />

      <header className="mb-8 pb-5 border-b border-zinc-200">
        <div className="flex items-center gap-3">
          {/* Plain <img> (not next/image) so the seal eager-loads before the print dialog fires. */}
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/logo.png" alt="The Timpson Lyceum seal" width={44} height={44} className="h-10 w-auto shrink-0" />
          <p className="font-display text-xs tracking-[0.2em] uppercase text-zinc-400">
            The Timpson Lyceum · {course.title}
          </p>
        </div>
        <h1 className="font-display text-2xl font-bold text-zinc-900 mt-3">Syllabus</h1>
      </header>

      <MarkdownNotes content={course.syllabus} variant="print" />
    </main>
  );
}
