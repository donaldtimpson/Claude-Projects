import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { cookies } from "next/headers";
import { db } from "@/lib/db";
import MarkdownNotes from "@/components/MarkdownNotes";
import PrintControls from "@/components/PrintControls";

export const dynamic = "force-dynamic";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ courseId: string; videoId: string }>;
}): Promise<Metadata> {
  const { videoId } = await params;
  const video = await db.video.findUnique({ where: { id: videoId }, select: { title: true } });
  return { title: video ? `${video.title} — Notes` : "Lecture Notes", robots: { index: false } };
}

async function isAdmin() {
  const cookieStore = await cookies();
  return cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;
}

export default async function PrintNotesPage({
  params,
}: {
  params: Promise<{ courseId: string; videoId: string }>;
}) {
  const { courseId, videoId } = await params;

  const video = await db.video.findUnique({
    where: { id: videoId },
    include: { course: { select: { title: true } }, lectureNote: true },
  });

  if (!video || video.courseId !== courseId || !video.lectureNote) notFound();

  // Drafts are printable only by an admin (so notes can be checked before publishing).
  const note = video.lectureNote;
  if (note.isDraft && !(await isAdmin())) notFound();

  return (
    <main className="max-w-3xl mx-auto px-8 py-10">
      <PrintControls auto={!note.isDraft} />

      <header className="mb-8 pb-5 border-b border-zinc-200">
        <div className="flex items-center gap-3">
          {/* Plain <img> (not next/image) so the seal eager-loads before the print dialog fires. */}
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/logo.png" alt="The Timpson Lyceum seal" width={44} height={44} className="h-10 w-auto shrink-0" />
          <p className="font-display text-xs tracking-[0.2em] uppercase text-zinc-400">
            The Timpson Lyceum · {video.course.title}
          </p>
        </div>
        <h1 className="font-display text-2xl font-bold text-zinc-900 mt-3">{video.title}</h1>
      </header>

      <MarkdownNotes content={note.content} variant="print" />
    </main>
  );
}
