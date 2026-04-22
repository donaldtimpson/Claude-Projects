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

      const videos = await fetchPlaylistVideos(pl.id);
      for (const vid of videos) {
        await db.video.upsert({
          where: { youtubeVideoId: vid.id },
          create: {
            courseId: course.id,
            youtubeVideoId: vid.id,
            title: vid.title,
            description: vid.description,
            thumbnailUrl: vid.thumbnailUrl,
            position: vid.position,
            durationSeconds: vid.durationSeconds,
            publishedAt: vid.publishedAt ? new Date(vid.publishedAt) : null,
          },
          update: {
            title: vid.title,
            description: vid.description,
            thumbnailUrl: vid.thumbnailUrl,
            position: vid.position,
            durationSeconds: vid.durationSeconds,
          },
        });
        totalVideos++;
      }
    }

    return NextResponse.json({ synced: { courses: playlists.length, videos: totalVideos } });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
