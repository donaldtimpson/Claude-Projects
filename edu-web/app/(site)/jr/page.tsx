import Link from "next/link";
import Image from "next/image";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Lyceum Jr",
  description:
    "The Timpson Lyceum's junior branch — calm, ad-free learning for the youngest students. First up: Sound It Out, a phonics reading app.",
};

export default function JrPage() {
  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-3xl mx-auto">
          <Link href="/" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← The Timpson Lyceum
          </Link>
        </div>
      </header>

      <div className="max-w-3xl mx-auto px-6 py-14 space-y-12">
        <div className="space-y-4">
          <p className="font-display text-xs tracking-[0.25em] uppercase text-gold-400">
            Timpson Lyceum · Junior
          </p>
          <h1 className="font-display text-4xl text-parchment leading-tight">Lyceum Jr</h1>
          <p className="text-parchment-dim text-lg leading-relaxed">
            The Lyceum teaches older students grammar, logic, mathematics, and physics. Lyceum Jr is
            its junior branch — the same care, made for the youngest learners, and just as calm and
            ad-free.
          </p>
        </div>

        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            The first app
          </h2>
          <Link
            href="/jr/sound-it-out"
            className="flex items-center gap-5 rounded-xl border border-crimson-700 bg-crimson-900/40 p-5 hover:border-gold-500 transition-colors"
          >
            <Image
              src="/jr/sound-it-out.png"
              alt="Sound It Out app icon"
              width={72}
              height={72}
              className="rounded-2xl shrink-0"
            />
            <div className="min-w-0">
              <p className="font-display text-xl text-parchment">Sound It Out</p>
              <p className="text-parchment-dim text-sm leading-relaxed">
                A phonics reading app for young children — sound out letters and words, trace them
                with a finger, and play. Learn more →
              </p>
            </div>
          </Link>
        </section>

        <p className="text-parchment-dim text-sm leading-relaxed">
          More is on the way. Everything from the Lyceum, at every age, stays free, private, and made
          by a teacher.
        </p>
      </div>
    </main>
  );
}
