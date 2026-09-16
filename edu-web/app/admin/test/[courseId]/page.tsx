import { redirect } from "next/navigation";

// Moved into the course hub. Kept as a redirect so old links/bookmarks survive.
export default async function LegacyTestRedirect({ params }: { params: Promise<{ courseId: string }> }) {
  const { courseId } = await params;
  redirect(`/admin/courses/${courseId}/test`);
}
