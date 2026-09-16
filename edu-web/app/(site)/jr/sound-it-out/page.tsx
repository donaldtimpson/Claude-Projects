import Link from "next/link";
import Image from "next/image";
import type { Metadata } from "next";
import { CONTACT_EMAIL } from "@/lib/legal";

export const metadata: Metadata = {
  title: "Sound It Out",
  description:
    "A calm, ad-free phonics app made by a teacher. Sound out letters and words, trace them with a finger, and play — all on-device, nothing collected.",
};

export default function SoundItOutPage() {
  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-3xl mx-auto">
          <Link href="/jr" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← Lyceum Jr
          </Link>
        </div>
      </header>

      <div className="max-w-3xl mx-auto px-6 py-14 space-y-12">
        {/* Hero */}
        <div className="flex flex-col sm:flex-row sm:items-center gap-6">
          <Image
            src="/jr/sound-it-out.png"
            alt="Sound It Out app icon"
            width={104}
            height={104}
            className="rounded-3xl shrink-0"
            priority
          />
          <div className="space-y-2">
            <p className="font-display text-xs tracking-[0.25em] uppercase text-gold-400">
              Timpson Lyceum Jr
            </p>
            <h1 className="font-display text-4xl text-parchment leading-tight">Sound It Out</h1>
            <p className="text-parchment-dim text-lg">Phonics reading for kids.</p>
          </div>
        </div>

        <p className="text-parchment-dim text-lg leading-relaxed">
          Sound It Out teaches young children to read the way reading actually works — sounding words
          out, one letter at a time. It was built by a teacher, and it is deliberately calm: no ads,
          no characters shouting, no timers, and nothing that can ever tell a child they got it
          wrong.
        </p>

        {/* App Store — no link yet; swap in the badge/link once live */}
        <div className="rounded-xl border border-crimson-700 bg-crimson-900/40 px-5 py-4">
          <p className="text-parchment text-sm">
            <span className="text-gold-300">Coming soon to the App Store</span> — for iPhone and iPad.
          </p>
        </div>

        <Section title="What's inside">
          <List
            items={[
              ["Sound it out", "Letters and their sounds, blending two sounds together, word families, whole words, and first sentences — a gentle path from letters to real reading."],
              ["Write it", "Trace each letter and number with a finger, following a dotted guide down the middle."],
              ["Play", "Find It, Build a Word, Rhyme Time, and Match Up — practice dressed as games."],
              ["Made for families", "Several children can share one device, each with their own profile. Grown-up settings sit behind a simple gate."],
            ]}
          />
        </Section>

        <Section title="Private by design">
          <p>
            Sound It Out has no network connection at all. Nothing is collected, nothing is uploaded,
            nothing is stored off your device — ever. If you turn on voice, speech is recognized on
            the device and never recorded or sent. Read the full{" "}
            <Link href="/jr/sound-it-out/privacy" className="text-gold-300 hover:text-gold-400 transition-colors">
              privacy policy
            </Link>
            .
          </p>
        </Section>

        <Section title="Support">
          <p>
            Questions, trouble, or an idea? Write to{" "}
            <a href={`mailto:${CONTACT_EMAIL}`} className="text-gold-300 hover:text-gold-400 transition-colors">
              {CONTACT_EMAIL}
            </a>{" "}
            and you will get a real answer — the Lyceum is run by one person.
          </p>
        </Section>
      </div>
    </main>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="space-y-4">
      <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
        {title}
      </h2>
      <div className="space-y-4 text-sm text-parchment-dim leading-relaxed">{children}</div>
    </section>
  );
}

function List({ items }: { items: [string, string][] }) {
  return (
    <ul className="space-y-3">
      {items.map(([label, body]) => (
        <li key={label}>
          <span className="text-parchment">{label}.</span> {body}
        </li>
      ))}
    </ul>
  );
}
