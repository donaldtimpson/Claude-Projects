import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    // Serve images directly instead of through Vercel's image optimizer. The
    // catalog is almost entirely YouTube thumbnails, which are already
    // CDN-optimized; routing them through the optimizer wasted quota and
    // started returning HTTP 402, blanking every image (the logo included).
    unoptimized: true,
    remotePatterns: [
      { protocol: "https", hostname: "i.ytimg.com" },
      { protocol: "https", hostname: "img.youtube.com" },
    ],
  },
};

export default nextConfig;
