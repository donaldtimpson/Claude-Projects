import Link from "next/link";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex-1 flex flex-col">
      <header className="border-b border-slate-800 px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-6">
          <Link href="/" className="text-slate-400 hover:text-white text-sm transition-colors">
            ← Site
          </Link>
          <Link href="/admin" className="text-white font-semibold text-sm">
            Admin
          </Link>
        </div>
        <LogoutButton />
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
        className="text-sm text-slate-400 hover:text-red-400 transition-colors"
      >
        Logout
      </button>
    </form>
  );
}
