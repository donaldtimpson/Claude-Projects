import { redirect } from "next/navigation";

// Problem sets are now managed per-course under the course hub's Problem Sets
// tab. This global index no longer has a nav entry — send it to the dashboard.
export default function LegacyProblemSetsIndexRedirect() {
  redirect("/admin");
}
