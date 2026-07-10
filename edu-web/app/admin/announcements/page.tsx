import Link from "next/link";
import { db } from "@/lib/db";
import AnnouncementCreateForm from "./AnnouncementCreateForm";
import AnnouncementRow from "./AnnouncementRow";

export const dynamic = "force-dynamic";

export default async function AdminAnnouncementsPage() {
  const [announcements, courses] = await Promise.all([
    db.announcement.findMany({
      orderBy: [{ pinned: "desc" }, { createdAt: "desc" }],
      include: { course: { select: { id: true, title: true } } },
    }),
    db.course.findMany({ orderBy: { title: "asc" }, select: { id: true, title: true } }),
  ]);

  return (
    <main className="max-w-3xl mx-auto px-6 py-10 space-y-8">
      <div>
        <Link href="/admin" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
          ← Dashboard
        </Link>
        <h1 className="text-2xl font-bold text-parchment mt-3">Announcements</h1>
        <p className="text-sm text-parchment-dim mt-1">
          Site-wide announcements appear on the home page and every course page. Course announcements
          appear only on that course&apos;s page. Pinned announcements float to the top.
        </p>
      </div>

      <section className="space-y-3">
        <h2 className="font-semibold text-parchment">New Announcement</h2>
        <AnnouncementCreateForm courses={courses} />
      </section>

      <section className="space-y-3">
        <h2 className="font-semibold text-parchment">All Announcements</h2>
        {announcements.length === 0 ? (
          <p className="text-parchment-dim text-sm">No announcements yet.</p>
        ) : (
          <div className="space-y-3">
            {announcements.map((a) => (
              <AnnouncementRow key={a.id} announcement={a} />
            ))}
          </div>
        )}
      </section>
    </main>
  );
}
