import Link from "next/link";
import Image from "next/image";
import UserMenu from "@/components/UserMenu";

export default function SiteHeader() {
  return (
    <header className="bg-crimson-900 border-b border-crimson-700 px-6 py-0">
      <div className="max-w-6xl mx-auto flex items-center justify-between">
        <Link href="/" className="flex items-center gap-3">
          <Image src="/logo.png" alt="The Timpson Lyceum seal" width={80} height={80} />
          <span className="font-display text-sm tracking-[0.2em] uppercase text-gold-300">
            The Timpson Lyceum
          </span>
        </Link>
        <nav className="flex items-center gap-6 font-display text-xs tracking-[0.15em] uppercase text-parchment-dim">
          <Link href="/" className="hover:text-gold-300 transition-colors">
            Courses
          </Link>
          <a
            href="https://www.youtube.com/@donaldDtimpson"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-gold-300 transition-colors"
          >
            YouTube ↗
          </a>
          <UserMenu />
        </nav>
      </div>
    </header>
  );
}
