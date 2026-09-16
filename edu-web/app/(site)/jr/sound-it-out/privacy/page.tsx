import Link from "next/link";
import type { Metadata } from "next";
import { CONTACT_EMAIL } from "@/lib/legal";

// Sound It Out is a separate app from the Lyceum courses: no account, no network,
// nothing collected. It gets its own policy rather than reusing the Lyceum's, which
// is account-based. This URL is the one App Review reads.
const UPDATED = "September 15, 2026";

export const metadata: Metadata = {
  title: "Sound It Out — Privacy Policy",
  description: "Sound It Out collects nothing and has no network connection. Here is exactly what that means.",
};

export default function SoundItOutPrivacyPage() {
  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-3xl mx-auto">
          <Link href="/jr/sound-it-out" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← Sound It Out
          </Link>
        </div>
      </header>

      <div className="max-w-3xl mx-auto px-6 py-10 space-y-10">
        <div>
          <h1 className="font-display text-2xl text-parchment mb-1">Sound It Out — Privacy Policy</h1>
          <p className="text-parchment-dim text-sm">Last updated {UPDATED}</p>
        </div>

        <Section title="The short version">
          <p className="text-parchment">
            Sound It Out collects no data. None. It has no network connection at all.
          </p>
          <p>
            Sound It Out is a reading app for young children. It was built so there is nothing to
            protect and nothing to ask permission for: the app never sends, uploads, or receives
            anything, and it contains no advertising, no analytics, and no third-party SDKs.
          </p>
        </Section>

        <Section title="What the app stores">
          <p>
            Everything the app remembers — which words a child has read, their badges, the profiles
            you create (a name, an emoji face, a colour), and your settings — is stored only on your
            device, in the app&apos;s own storage. It never leaves the device. Deleting the app
            deletes all of it. Nothing is tied to an account, because there are no accounts.
          </p>
        </Section>

        <Section title="The microphone">
          <p>
            If a grown-up turns on &ldquo;Listen for their voice&rdquo; (from behind the parental
            gate), the app uses the microphone and Apple&apos;s on-device speech recognition to
            notice when your child reads a word aloud, so it can cheer. This happens entirely on the
            device. No audio is recorded, saved, or transmitted anywhere. The feature is off by
            default and can be turned off at any time.
          </p>
        </Section>

        <Section title="Children's privacy">
          <p>
            Sound It Out is designed for children and complies with the U.S. Children&apos;s Online
            Privacy Protection Act (COPPA) and Apple&apos;s Kids Category requirements. It collects
            no personal information from anyone, children included. Any links to the outside
            (attributions and one link to the developer&apos;s other work) sit behind a parental
            gate.
          </p>
        </Section>

        <Section title="Third parties">
          <p>There are none. No data is shared with anyone, because no data is collected.</p>
        </Section>

        <Section title="Changes">
          <p>
            If this policy ever changes, the updated version will be posted at this address with a new
            date above.
          </p>
        </Section>

        <Section title="Contact">
          <p>
            Questions about this policy? Write to{" "}
            <a href={`mailto:${CONTACT_EMAIL}`} className="text-gold-300 hover:text-gold-400 transition-colors">
              {CONTACT_EMAIL}
            </a>
            .
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
