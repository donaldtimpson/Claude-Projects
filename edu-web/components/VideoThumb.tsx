"use client";

import Image from "next/image";
import { useState } from "react";

// YouTube's `maxresdefault.jpg` only exists for HD source video and 404s
// otherwise (common on lectures without a custom thumbnail). `mqdefault.jpg` is
// native 16:9 and always exists for any public video, so we fall back to it.
export default function VideoThumb({
  videoId,
  src,
  alt,
  sizes = "128px",
}: {
  videoId: string;
  src: string;
  alt: string;
  sizes?: string;
}) {
  const fallback = `https://i.ytimg.com/vi/${videoId}/mqdefault.jpg`;
  const [current, setCurrent] = useState(src || fallback);
  return (
    <Image
      src={current}
      alt={alt}
      fill
      sizes={sizes}
      className="object-cover"
      onError={() => {
        if (current !== fallback) setCurrent(fallback);
      }}
    />
  );
}
