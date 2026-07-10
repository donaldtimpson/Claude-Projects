import { DRILLS } from "@/lib/drills";
import { ok } from "@/lib/mobile/respond";

// Drill hub metadata for the mobile client. The native app reimplements the
// generators in Swift (they run on-device / offline); this endpoint exists so the
// hub list can be server-driven if needed. `generate` is intentionally omitted.
export async function GET() {
  const drills = DRILLS.map(({ slug, title, blurb, icon, subject, levels }) => ({
    slug,
    title,
    blurb,
    icon,
    subject,
    levels,
  }));
  return ok({ drills });
}
