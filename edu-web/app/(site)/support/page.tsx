import Link from "next/link";
import type { Metadata } from "next";
import { CONTACT_EMAIL } from "@/lib/legal";

export const metadata: Metadata = {
  title: "Support",
  description: "Help with the Timpson Lyceum app and website — accounts, progress, and getting in touch.",
};

export default function SupportPage() {
  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-3xl mx-auto">
          <Link href="/" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← All Courses
          </Link>
        </div>
      </header>

      <div className="max-w-3xl mx-auto px-6 py-10 space-y-10">
        <div>
          <h1 className="font-display text-2xl text-parchment mb-1">Support</h1>
          <p className="text-parchment-dim text-sm">
            The Lyceum is run by one person. Write to{" "}
            <a href={`mailto:${CONTACT_EMAIL}`} className="text-gold-300 hover:text-gold-400 transition-colors">
              {CONTACT_EMAIL}
            </a>{" "}
            and you will get a real answer.
          </p>
        </div>

        <Section title="Your account works everywhere">
          <p>
            One account covers both this website and the iOS app. Sign in with the same email and
            password in either place and your progress, streak, badges, and review queue follow you.
          </p>
        </Section>

        <Section title="Forgotten password">
          <p>
            Password reset is not yet self-service. Email{" "}
            <a href={`mailto:${CONTACT_EMAIL}`} className="text-gold-300 hover:text-gold-400 transition-colors">
              {CONTACT_EMAIL}
            </a>{" "}
            from the address on your account and you will get a way back in.
          </p>
        </Section>

        <Section title="Deleting your account">
          <p>
            In the app: <span className="text-parchment">Profile → Delete Account</span>. It asks for
            your password, then permanently removes your account and all of your coursework. See the{" "}
            <Link href="/privacy" className="text-gold-300 hover:text-gold-400 transition-colors">
              Privacy Policy
            </Link>{" "}
            for exactly what gets removed.
          </p>
        </Section>

        <Section title="A lecture will not play">
          <p>
            Lectures stream from YouTube, so playback needs a working internet connection and an
            unblocked YouTube. If a video shows an error, check your connection first, then try the
            same lecture on the website — if it plays there but not in the app, that is a bug worth
            reporting.
          </p>
        </Section>

        <Section title="Practicing offline">
          <p>
            Practice drills run entirely on your device and work with no connection. Anything you
            complete offline is queued and synced the next time the app can reach the server, so your
            scores and streak stay correct.
          </p>
        </Section>

        <Section title="Reporting a bug or asking for a course">
          <p>
            Email{" "}
            <a href={`mailto:${CONTACT_EMAIL}`} className="text-gold-300 hover:text-gold-400 transition-colors">
              {CONTACT_EMAIL}
            </a>
            . For a bug, the lecture or drill you were on and what you expected to happen is enough to
            go on.
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
