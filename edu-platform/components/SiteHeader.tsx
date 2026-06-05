import Link from "next/link";
import Image from "next/image";
import { cookies } from "next/headers";
import UserMenu from "@/components/UserMenu";
import SiteNav from "@/components/SiteNav";
import NavBreadcrumb from "@/components/NavBreadcrumb";

export default async function SiteHeader() {
  const cookieStore = await cookies();
  const isAdmin = cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;

  return (
    <header className="bg-crimson-900 border-b border-crimson-700 px-6">
      <div className="max-w-6xl mx-auto flex items-center justify-between gap-4 h-16">
        <div className="flex items-center gap-3 min-w-0">
          <SiteNav isAdmin={isAdmin} />
          <Link href="/" className="flex items-center gap-3 shrink-0">
            <Image
              src="/logo.png"
              alt="The Timpson Lyceum seal"
              width={120}
              height={80}
              className="h-10 w-auto sm:h-12"
            />
            <span className="hidden md:inline font-display text-sm tracking-[0.2em] uppercase text-gold-300">
              The Timpson Lyceum
            </span>
          </Link>
          <NavBreadcrumb />
        </div>
        <UserMenu />
      </div>
    </header>
  );
}
