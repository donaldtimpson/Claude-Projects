// OAuth 2.0 helpers for WRITING to YouTube (editing video descriptions). The
// read path in lib/youtube.ts uses a plain API key, which only grants access to
// public data; mutating a video requires an OAuth access token minted from the
// channel owner's refresh token. Run scripts/youtube-auth.ts once to obtain the
// refresh token and store the three YOUTUBE_OAUTH_* vars in .env.
//
// Raw fetch (no googleapis dep), matching lib/youtube.ts's style.

const TOKEN_URL = "https://oauth2.googleapis.com/token";
const BASE = "https://www.googleapis.com/youtube/v3";

// YouTube enforces a 5000-character limit on descriptions.
export const MAX_DESCRIPTION_LENGTH = 5000;

// Access tokens last ~1h; cache within a single process run (one batch).
let cached: { token: string; expiresAt: number } | null = null;

export async function getAccessToken(): Promise<string> {
  if (cached && Date.now() < cached.expiresAt - 60_000) return cached.token;

  const clientId = process.env.YOUTUBE_OAUTH_CLIENT_ID;
  const clientSecret = process.env.YOUTUBE_OAUTH_CLIENT_SECRET;
  const refreshToken = process.env.YOUTUBE_OAUTH_REFRESH_TOKEN;
  if (!clientId || !clientSecret || !refreshToken) {
    throw new Error(
      "Missing YOUTUBE_OAUTH_* env vars. Run `npx tsx scripts/youtube-auth.ts` once to set them.",
    );
  }

  const res = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      refresh_token: refreshToken,
      grant_type: "refresh_token",
    }),
  });
  if (!res.ok) {
    throw new Error(
      `Token refresh failed: ${res.status} ${await res.text()}\n` +
        "If this says invalid_grant, the refresh token expired (Testing-mode apps expire after " +
        "7 days). Re-run `npx tsx scripts/youtube-auth.ts`.",
    );
  }
  const data = (await res.json()) as { access_token: string; expires_in: number };
  cached = { token: data.access_token, expiresAt: Date.now() + data.expires_in * 1000 };
  return data.access_token;
}

// The snippet fields we read back and resend on update. videos.update with
// part=snippet REPLACES the whole snippet, so anything omitted is cleared — we
// preserve everything we know about and only swap the description.
export type VideoSnippet = {
  title: string;
  description: string;
  categoryId: string;
  tags?: string[];
  defaultLanguage?: string;
  defaultAudioLanguage?: string;
};

export async function getVideoSnippet(videoId: string): Promise<VideoSnippet> {
  const token = await getAccessToken();
  const url = new URL(`${BASE}/videos`);
  url.searchParams.set("part", "snippet");
  url.searchParams.set("id", videoId);
  const res = await fetch(url.toString(), { headers: { Authorization: `Bearer ${token}` } });
  if (!res.ok) throw new Error(`videos.list failed: ${res.status} ${await res.text()}`);
  const data = (await res.json()) as { items?: { snippet: VideoSnippet }[] };
  const snippet = data.items?.[0]?.snippet;
  if (!snippet) throw new Error(`Video not found or not owned by the authed channel: ${videoId}`);
  return snippet;
}

// Fetch the full snippet, swap ONLY the description, and write it back. Title and
// categoryId are required by the API; tags / language fields are preserved when
// present so the update doesn't silently strip them.
export async function updateVideoDescription(
  videoId: string,
  newDescription: string,
): Promise<void> {
  if (newDescription.length > MAX_DESCRIPTION_LENGTH) {
    throw new Error(
      `Description for ${videoId} is ${newDescription.length} chars (> ${MAX_DESCRIPTION_LENGTH}).`,
    );
  }
  const snippet = await getVideoSnippet(videoId);
  const body = {
    id: videoId,
    snippet: {
      title: snippet.title,
      categoryId: snippet.categoryId,
      description: newDescription,
      ...(snippet.tags ? { tags: snippet.tags } : {}),
      ...(snippet.defaultLanguage ? { defaultLanguage: snippet.defaultLanguage } : {}),
      ...(snippet.defaultAudioLanguage
        ? { defaultAudioLanguage: snippet.defaultAudioLanguage }
        : {}),
    },
  };

  const token = await getAccessToken();
  const url = new URL(`${BASE}/videos`);
  url.searchParams.set("part", "snippet");
  const res = await fetch(url.toString(), {
    method: "PUT",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`videos.update failed: ${res.status} ${await res.text()}`);
}

// --- Playlists (course descriptions) ---------------------------------------
//
// A Course's description mirrors its YouTube playlist description, and
// app/api/youtube/sync overwrites the DB copy from YouTube on every run — so the
// playlist is the only durable place to edit it. Same replace-the-whole-snippet
// caveat as videos: playlists.update with part=snippet requires the title, and
// clears anything omitted.

export type PlaylistSnippet = {
  title: string;
  description: string;
  defaultLanguage?: string;
};

export async function getPlaylistSnippet(playlistId: string): Promise<PlaylistSnippet> {
  const token = await getAccessToken();
  const url = new URL(`${BASE}/playlists`);
  url.searchParams.set("part", "snippet");
  url.searchParams.set("id", playlistId);
  const res = await fetch(url.toString(), { headers: { Authorization: `Bearer ${token}` } });
  if (!res.ok) throw new Error(`playlists.list failed: ${res.status} ${await res.text()}`);
  const data = (await res.json()) as { items?: { snippet: PlaylistSnippet }[] };
  const snippet = data.items?.[0]?.snippet;
  if (!snippet) {
    throw new Error(`Playlist not found or not owned by the authed channel: ${playlistId}`);
  }
  return snippet;
}

export async function updatePlaylistDescription(
  playlistId: string,
  newDescription: string,
): Promise<void> {
  if (newDescription.length > MAX_DESCRIPTION_LENGTH) {
    throw new Error(
      `Description for ${playlistId} is ${newDescription.length} chars (> ${MAX_DESCRIPTION_LENGTH}).`,
    );
  }
  const snippet = await getPlaylistSnippet(playlistId);
  const body = {
    id: playlistId,
    snippet: {
      title: snippet.title,
      description: newDescription,
      ...(snippet.defaultLanguage ? { defaultLanguage: snippet.defaultLanguage } : {}),
    },
  };

  const token = await getAccessToken();
  const url = new URL(`${BASE}/playlists`);
  url.searchParams.set("part", "snippet");
  const res = await fetch(url.toString(), {
    method: "PUT",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`playlists.update failed: ${res.status} ${await res.text()}`);
}
