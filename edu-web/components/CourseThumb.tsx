import Image from "next/image";

/**
 * Media area for a course card (16:9). Decides what to show:
 *  - empty course (0 videos): a themed "Coming Soon" placeholder in the
 *    lyceum crimson/gold palette — never YouTube's gray empty-playlist image
 *    (which is what gets stored in thumbnailUrl for an empty playlist).
 *  - has videos + a real thumbnail: the thumbnail.
 *  - has videos but no thumbnail: a neutral fallback.
 */
export default function CourseThumb({
  thumbnailUrl,
  title,
  videoCount,
}: {
  thumbnailUrl?: string | null;
  title: string;
  videoCount: number;
}) {
  if (videoCount === 0) return <ComingSoonThumb />;

  if (thumbnailUrl) {
    return (
      <div className="relative aspect-video">
        <Image
          src={thumbnailUrl}
          alt={title}
          fill
          className="object-cover opacity-90 group-hover:opacity-100 transition-opacity"
        />
      </div>
    );
  }

  return (
    <div className="aspect-video bg-crimson-800 flex items-center justify-center">
      <span className="text-parchment-dim text-sm">No thumbnail</span>
    </div>
  );
}

export function ComingSoonThumb() {
  return (
    <div className="relative aspect-video overflow-hidden bg-gradient-to-br from-crimson-800 via-crimson-900 to-crimson-950">
      {/* soft gold glow */}
      <div
        className="absolute inset-0"
        style={{
          background:
            "radial-gradient(ellipse at 50% 38%, rgba(207,161,53,0.28), transparent 62%)",
        }}
      />
      {/* thin gold inset frame */}
      <div className="absolute inset-3 rounded border border-gold-500/40" />
      {/* content */}
      <div className="absolute inset-0 flex flex-col items-center justify-center gap-2 px-4 text-center">
        <span className="font-display text-gold-300 text-base sm:text-lg tracking-[0.3em] uppercase">
          Coming Soon
        </span>
        <span className="flex items-center gap-2 text-gold-500/70">
          <span className="h-px w-6 bg-gold-500/50" />
          <span className="text-xs">✦</span>
          <span className="h-px w-6 bg-gold-500/50" />
        </span>
      </div>
    </div>
  );
}
