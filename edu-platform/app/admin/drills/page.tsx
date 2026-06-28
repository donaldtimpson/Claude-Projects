import Link from "next/link";
import { DRILLS } from "@/lib/drills/registry";
import DrillTester from "./DrillTester";

export const dynamic = "force-dynamic";

export default function AdminDrillsPage() {
  const drills = DRILLS.map((d) => ({
    slug: d.slug,
    title: d.title,
    blurb: d.blurb,
    icon: d.icon,
    subject: d.subject,
  }));

  return (
    <main className="flex-1">
      <div className="max-w-3xl mx-auto px-6 py-10 space-y-6">
        <div>
          <Link href="/admin" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← Admin
          </Link>
          <h1 className="font-display text-2xl text-parchment mt-2 mb-1">Practice Drills</h1>
          <p className="text-parchment-dim text-sm">
            Try out any drill here. These test runs are not recorded — no streak, no badges. The live
            student version is at{" "}
            <Link href="/drills" className="text-gold-400 hover:text-gold-300 transition-colors">
              /drills
            </Link>
            .
          </p>
        </div>
        <DrillTester drills={drills} />
      </div>
    </main>
  );
}
