import { redirect } from "next/navigation";
import Link from "next/link";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { getDueDeck } from "@/lib/srs";
import { gradeReview, finishDailyReview } from "@/lib/actions";
import DailyReviewPlayer from "./DailyReviewPlayer";

export const dynamic = "force-dynamic";

function dueInWords(dueAt: Date): string {
  const days = Math.ceil((dueAt.getTime() - Date.now()) / 86_400_000);
  if (days <= 1) return "tomorrow";
  return `in ${days} days`;
}

export default async function DailyReviewPage() {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) redirect("/auth/signin");
  const userId = session.user.id;

  const due = await getDueDeck(userId);

  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-3xl mx-auto">
          <Link href="/dashboard" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← My Progress
          </Link>
        </div>
      </header>

      <div className="max-w-3xl mx-auto px-6 py-10 space-y-6">
        <h1 className="text-2xl font-bold text-parchment">Daily Review</h1>

        {due.length > 0 ? (
          <DailyReviewPlayer cards={due} onGrade={gradeReview} onFinish={finishDailyReview} />
        ) : (
          <EmptyState userId={userId} />
        )}
      </div>
    </main>
  );
}

async function EmptyState({ userId }: { userId: string }) {
  const [deckSize, next] = await Promise.all([
    db.questionReview.count({ where: { userId } }),
    db.questionReview.findFirst({
      where: { userId, question: { isDraft: false } },
      orderBy: { dueAt: "asc" },
      select: { dueAt: true },
    }),
  ]);

  return (
    <section className="bg-crimson-900 border border-crimson-700 rounded-xl p-6 space-y-2">
      {deckSize === 0 ? (
        <>
          <p className="text-parchment font-medium">Your review deck is empty.</p>
          <p className="text-sm text-parchment-dim">
            Take any lecture quiz or course test and its questions start showing up here for
            spaced review.{" "}
            <Link href="/" className="text-gold-400 hover:text-gold-300 transition-colors">
              Browse courses →
            </Link>
          </p>
        </>
      ) : (
        <>
          <p className="text-parchment font-medium">All caught up ✓</p>
          <p className="text-sm text-parchment-dim">
            Nothing due right now.{next ? ` Next cards are due ${dueInWords(next.dueAt)}.` : ""}
          </p>
        </>
      )}
    </section>
  );
}
