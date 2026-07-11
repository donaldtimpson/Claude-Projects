import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { db } from "@/lib/db";
import { fetchChannelPlaylists, fetchPlaylistVideos } from "@/lib/youtube";

export async function POST() {
  const cookieStore = await cookies();
  const cookie = cookieStore.get("admin_auth")?.value;
  if (cookie !== process.env.ADMIN_PASSWORD) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    const playlists = await fetchChannelPlaylists();
    let totalVideos = 0;

    for (const pl of playlists) {
      await db.course.upsert({
        where: { youtubePlaylistId: pl.id },
        create: {
          youtubePlaylistId: pl.id,
          title: pl.title,
          description: pl.description,
          thumbnailUrl: pl.thumbnailUrl,
          videoCount: pl.itemCount,
          publishedAt: pl.publishedAt ? new Date(pl.publishedAt) : null,
          syncedAt: new Date(),
        },
        update: {
          title: pl.title,
          description: pl.description,
          thumbnailUrl: pl.thumbnailUrl,
          videoCount: pl.itemCount,
          publishedAt: pl.publishedAt ? new Date(pl.publishedAt) : null,
          syncedAt: new Date(),
        },
      });

      const course = await db.course.findUnique({ where: { youtubePlaylistId: pl.id } });
      if (!course) continue;

      // Manual-order courses keep their hand-arranged Video.position: existing
      // lectures are never repositioned by sync, and brand-new lectures are
      // appended after the current max position. Normal courses track the
      // playlist order (position = YouTube's playlist position).
      const existing = await db.video.findMany({
        where: { courseId: course.id },
        select: { youtubeVideoId: true, position: true },
      });
      const known = new Set(existing.map((v) => v.youtubeVideoId));
      let nextPosition = existing.reduce((m, v) => Math.max(m, v.position), -1) + 1;

      const videos = await fetchPlaylistVideos(pl.id);
      for (const vid of videos) {
        const isNew = !known.has(vid.id);
        // New lecture in a manual course => append at the end; otherwise use the
        // playlist position. (create-only value; existing manual videos keep theirs.)
        const createPosition = course.manualOrder && isNew ? nextPosition++ : vid.position;
        await db.video.upsert({
          where: { youtubeVideoId: vid.id },
          create: {
            courseId: course.id,
            youtubeVideoId: vid.id,
            title: vid.title,
            description: vid.description,
            thumbnailUrl: vid.thumbnailUrl,
            position: createPosition,
            durationSeconds: vid.durationSeconds,
            publishedAt: vid.publishedAt ? new Date(vid.publishedAt) : null,
          },
          update: {
            title: vid.title,
            description: vid.description,
            thumbnailUrl: vid.thumbnailUrl,
            // Preserve manual ordering: don't touch position on existing videos.
            ...(course.manualOrder ? {} : { position: vid.position }),
            durationSeconds: vid.durationSeconds,
          },
        });
        totalVideos++;
      }

      // Use the first lecture's thumbnail as the course cover. YouTube's playlist
      // thumbnail tracks the newest upload for active playlists, which would show
      // the most recent lecture instead of lecture 1. publishedAt is reliable
      // lecture order across all courses.
      const firstVideo = await db.video.findFirst({
        where: { courseId: course.id },
        orderBy: course.manualOrder
          ? [{ position: "asc" }]
          : [{ publishedAt: "asc" }, { position: "asc" }],
        select: { thumbnailUrl: true },
      });
      if (firstVideo?.thumbnailUrl) {
        await db.course.update({
          where: { id: course.id },
          data: { thumbnailUrl: firstVideo.thumbnailUrl },
        });
      }
    }

    return NextResponse.json({ synced: { courses: playlists.length, videos: totalVideos } });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
