const BASE = "https://www.googleapis.com/youtube/v3";
const KEY = process.env.YOUTUBE_API_KEY!;
const CHANNEL_ID = process.env.YOUTUBE_CHANNEL_ID!;

export type YTPlaylist = {
  id: string;
  title: string;
  description: string;
  thumbnailUrl: string;
  itemCount: number;
};

export type YTVideo = {
  id: string;
  title: string;
  description: string;
  thumbnailUrl: string;
  position: number;
  durationSeconds: number;
  publishedAt: string;
};

async function fetchAll<T>(
  endpoint: string,
  params: Record<string, string>,
  extract: (item: unknown) => T
): Promise<T[]> {
  const results: T[] = [];
  let pageToken: string | undefined;
  do {
    const url = new URL(`${BASE}/${endpoint}`);
    url.searchParams.set("key", KEY);
    for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
    if (pageToken) url.searchParams.set("pageToken", pageToken);

    const res = await fetch(url.toString());
    if (!res.ok) throw new Error(`YouTube API error: ${res.status} ${await res.text()}`);
    const data = (await res.json()) as { items?: unknown[]; nextPageToken?: string };
    for (const item of data.items ?? []) results.push(extract(item));
    pageToken = data.nextPageToken;
  } while (pageToken);
  return results;
}

export async function fetchChannelPlaylists(): Promise<YTPlaylist[]> {
  return fetchAll(
    "playlists",
    { part: "snippet,contentDetails", channelId: CHANNEL_ID, maxResults: "50" },
    (item) => {
      const i = item as Record<string, unknown>;
      const snippet = i.snippet as Record<string, unknown>;
      const thumbnails = snippet.thumbnails as Record<string, { url: string }>;
      const contentDetails = i.contentDetails as Record<string, unknown>;
      return {
        id: i.id as string,
        title: snippet.title as string,
        description: (snippet.description as string) ?? "",
        thumbnailUrl:
          thumbnails?.maxres?.url ?? thumbnails?.high?.url ?? thumbnails?.default?.url ?? "",
        itemCount: (contentDetails.itemCount as number) ?? 0,
      };
    }
  );
}

export async function fetchPlaylistVideos(playlistId: string): Promise<YTVideo[]> {
  // Step 1: get video IDs + positions from playlistItems
  const items = await fetchAll(
    "playlistItems",
    { part: "snippet,contentDetails", playlistId, maxResults: "50" },
    (item) => {
      const i = item as Record<string, unknown>;
      const snippet = i.snippet as Record<string, unknown>;
      const contentDetails = i.contentDetails as Record<string, unknown>;
      return {
        videoId: contentDetails.videoId as string,
        position: snippet.position as number,
        publishedAt: (snippet.publishedAt as string) ?? "",
      };
    }
  );

  if (items.length === 0) return [];

  // Step 2: fetch durations in batches of 50
  const videos: YTVideo[] = [];
  for (let i = 0; i < items.length; i += 50) {
    const batch = items.slice(i, i + 50);
    const ids = batch.map((v) => v.videoId).join(",");
    const url = new URL(`${BASE}/videos`);
    url.searchParams.set("key", KEY);
    url.searchParams.set("part", "snippet,contentDetails");
    url.searchParams.set("id", ids);

    const res = await fetch(url.toString());
    if (!res.ok) throw new Error(`YouTube API error: ${res.status}`);
    const data = (await res.json()) as { items?: unknown[] };

    for (const raw of data.items ?? []) {
      const v = raw as Record<string, unknown>;
      const snippet = v.snippet as Record<string, unknown>;
      const cd = v.contentDetails as Record<string, unknown>;
      const thumbnails = snippet.thumbnails as Record<string, { url: string }>;
      const match = items.find((x) => x.videoId === (v.id as string));

      videos.push({
        id: v.id as string,
        title: snippet.title as string,
        description: (snippet.description as string) ?? "",
        thumbnailUrl:
          thumbnails?.maxres?.url ?? thumbnails?.high?.url ?? thumbnails?.default?.url ?? "",
        position: match?.position ?? 0,
        durationSeconds: parseDuration(cd.duration as string),
        publishedAt: match?.publishedAt ?? (snippet.publishedAt as string) ?? "",
      });
    }
  }

  return videos.sort((a, b) => a.position - b.position);
}

function parseDuration(iso: string): number {
  if (!iso) return 0;
  const m = iso.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);
  if (!m) return 0;
  return (parseInt(m[1] ?? "0") * 3600) + (parseInt(m[2] ?? "0") * 60) + parseInt(m[3] ?? "0");
}
