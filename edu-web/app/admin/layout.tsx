import Link from "next/link";
import AdminNav from "./AdminNav";
import SyncButton from "./SyncButton";

export const dynamic = "force-dynamic";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex-1 flex flex-col">
      <header className="border-b border-crimson-700 px-6 py-4 flex items-center justify-between gap-4 flex-wrap">
        <div className="flex items-center gap-4 flex-wrap">
          <Link href="/" className="text-parchment-dim hover:text-parchment text-sm transition-colors">
            ← Site
          </Link>
          <span className="font-display text-sm tracking-[0.15em] uppercase text-gold-300">Admin</span>
          <AdminNav />
        </div>
        <div className="flex items-center gap-4">
          <SyncButton />
          <LogoutButton />
        </div>
      </header>
      <div className="flex-1">{children}</div>
    </div>
  );
}

function LogoutButton() {
  return (
    <form
      action={async () => {
        "use server";
        const { cookies } = await import("next/headers");
        (await cookies()).delete("admin_auth");
      }}
    >
      <button
        type="submit"
        className="text-sm text-parchment-dim hover:text-red-400 transition-colors"
      >
        Logout
      </button>
    </form>
  );
}
