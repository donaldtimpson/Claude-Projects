"use client";

// Records this drill in the device-local "Continue" list when its session page opens —
// the web counterpart of the iOS `open(slug)` recents write. Renders nothing.

import { useEffect } from "react";
import { recordRecent } from "@/lib/drills/recents";

export default function RecordRecent({ slug }: { slug: string }) {
  useEffect(() => {
    recordRecent(slug);
  }, [slug]);
  return null;
}
