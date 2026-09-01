import Link from "next/link";
import type { Metadata } from "next";
import { CONTACT_EMAIL, PRIVACY_UPDATED } from "@/lib/legal";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description:
    "What the Timpson Lyceum collects, why, and how to get your account deleted.",
};

export default function PrivacyPage() {
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
          <h1 className="font-display text-2xl text-parchment mb-1">Privacy Policy</h1>
          <p className="text-parchment-dim text-sm">Last updated {PRIVACY_UPDATED}</p>
        </div>

        <Section title="The short version">
          <p>
            The Timpson Lyceum is a one-person educational project. It collects the least it can:
            an account so your progress follows you between the website and the iOS app, and a
            record of what you&apos;ve watched, answered, and practiced so the app can show you your
            standing and decide which questions to review next. Nothing is sold, and there are no
            advertising or analytics trackers.
          </p>
        </Section>

        <Section title="What is collected">
          <List
            items={[
              ["Your account", "Your email address, your password (stored only as a bcrypt hash — never in readable form), and the name you choose to give. Name is optional."],
              ["Your handle", "An optional pseudonym. If you set one, it is the only thing shown next to you in the public Hall of Scholars — your email and real name are never displayed there."],
              ["Your coursework", "Which lectures you have watched and how far, your quiz answers and scores, your practice-drill sessions and high scores, your spaced-repetition review history, your badges, and your streak."],
              ["Your comments", "Comments you post on a lecture, which are public and shown next to your handle."],
              ["Live-class records", "If you register for one of Donald's live classes with a join code: your enrollment in that class and the homework you submit for it."],
            ]}
          />
        </Section>

        <Section title="What is not collected">
          <List
            items={[
              ["No tracking", "There are no advertising identifiers, no third-party analytics SDKs, and no cross-app or cross-site tracking. Your data is never used to track you across other companies' apps or websites."],
              ["No selling or sharing", "Your information is never sold, rented, or handed to data brokers."],
              ["No payments", "The app is free and has no purchases, so no payment or financial information is ever collected."],
              ["No device data harvesting", "The app does not collect your contacts, photos, location, microphone, camera, or health data."],
            ]}
          />
        </Section>

        <Section title="Why it is collected">
          <p>
            Every item above exists to make the app work: to sign you in, to resume a lecture where
            you left off, to grade a quiz, to schedule your next spaced-repetition review, to award a
            badge, and to place you in the Hall of Scholars. None of it is used for advertising or
            profiling.
          </p>
        </Section>

        <Section title="Who else touches it">
          <List
            items={[
              ["Vercel", "Hosts the website and the app's API. Standard server logs, which include IP addresses, are kept briefly for operations and abuse prevention."],
              ["Neon", "Hosts the Postgres database where your account and coursework are stored."],
              ["YouTube (Google)", "Lecture videos are hosted on YouTube and played through YouTube's embedded player inside the app. When you play a lecture, Google receives that playback request and applies its own privacy policy to it. The Lyceum does not send Google your account, email, or coursework."],
            ]}
          />
          <p>
            These are service providers acting on the Lyceum&apos;s behalf, not partners who get to
            reuse your data for their own purposes — except YouTube, whose player is Google&apos;s and
            is governed by Google&apos;s policy.
          </p>
        </Section>

        <Section title="Deleting your account">
          <p>
            You can delete your account and everything attached to it from inside the app:{" "}
            <span className="text-parchment">Profile → Delete Account</span>. You will be asked to
            type the word DELETE to confirm, because it cannot be undone. Nothing else is required —
            no password, no email, and no request to us.
          </p>
          <p>
            Deletion is immediate and permanent. It removes your account, your progress, your quiz
            and drill history, your reviews, your badges, your comments, your class enrollments, and
            your homework submissions. It cannot be undone, and there is no way to recover the data
            afterward. If you would rather not use the app to do it, write to{" "}
            <a href={`mailto:${CONTACT_EMAIL}`} className="text-gold-300 hover:text-gold-400 transition-colors">
              {CONTACT_EMAIL}
            </a>{" "}
            from your account&apos;s email address and it will be done for you.
          </p>
        </Section>

        <Section title="Children">
          <p>
            The Lyceum teaches high-school and college-level material and is written for students of
            about thirteen and up. It is not directed at children under thirteen, and accounts are
            not knowingly created for them. If you believe a child under thirteen has an account,
            write to the address below and it will be deleted.
          </p>
        </Section>

        <Section title="Changes">
          <p>
            If this policy changes in substance, the date at the top of this page changes with it.
            Material changes will also be noted in the app.
          </p>
        </Section>

        <Section title="Contact">
          <p>
            Questions about any of this, or about your own data, go to{" "}
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
