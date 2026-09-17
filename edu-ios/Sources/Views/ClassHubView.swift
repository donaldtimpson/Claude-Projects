import SwiftUI

/// Navigation target for an enrolled class's homework. `sectionName` / `courseTitle`
/// let the nav bar fill in before the assignments request comes back.
struct ClassRoute: Hashable {
    let sectionId: String
    let sectionName: String
    let courseTitle: String
}

// A student's homework for one enrolled section: every assignment with its status
// (not submitted / submitted / graded), due date, and points. Mirrors the web
// class hub's Homework section (app/(site)/dashboard/class/[sectionId]/page.tsx).
// Tapping an assignment opens its detail — the problem set + submit form, or the
// lesson drill.
struct ClassHubView: View {
    let route: ClassRoute

    @EnvironmentObject private var auth: AuthViewModel
    @State private var data: ClassAssignmentsResponse?
    @State private var error: String?
    @State private var loading = true

    var body: some View {
        content
            .navigationTitle(route.sectionName)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AssignmentRoute.self) { AssignmentDetailView(route: $0) }
            .task { if data == nil { await load() } }
    }

    @ViewBuilder private var content: some View {
        if loading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.parchment)
        } else if let error {
            ContentUnavailableView(
                "Couldn't load homework", systemImage: "wifi.slash", description: Text(error))
        } else if let data {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(data.courseTitle)
                        .font(.serif(15)).foregroundStyle(Theme.inkSoft)

                    Text("HOMEWORK")
                        .font(.display(11)).kerning(2).foregroundStyle(Theme.gold400)
                        .padding(.top, 2)

                    if data.assignments.isEmpty {
                        Text("No homework assigned yet.")
                            .font(.serif(15)).foregroundStyle(Theme.inkSoft)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(data.assignments) { a in
                            NavigationLink(value: AssignmentRoute(
                                assignment: a,
                                courseId: data.courseId,
                                courseTitle: data.courseTitle
                            )) {
                                AssignmentRow(assignment: a, userId: auth.user?.id ?? "guest")
                            }
                            .buttonStyle(.lyceumPress)
                        }
                    }
                }
                .padding()
            }
            .background(Theme.parchment)
            .refreshable { await load() }
        }
    }

    private func load() async {
        do {
            let res: ClassAssignmentsResponse = try await APIClient.shared.get(
                "/me/classes/\(route.sectionId)/assignments")
            data = res
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

// One assignment row: title, the "due · points" line, and a status pill on the
// right. Lesson drills read their aced state locally (LessonProgress), matching
// how Practice on the lecture screen shows the ✦.
struct AssignmentRow: View {
    let assignment: AssignmentItem
    let userId: String

    private var aced: Bool {
        assignment.isLesson && assignment.lessonSlug
            .map { LessonProgress.shared.isAced(userId: userId, slug: $0) } == true
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(assignment.title)
                    .font(.display(14)).foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading).lineLimit(2)
                Text(detailLine)
                    .font(.serif(13)).foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 8)
            statusPill
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.gold400)
        }
        .lyceumCard()
    }

    private var detailLine: String {
        var parts: [String] = []
        if assignment.isLesson {
            parts.append("Grammar lesson")
        } else if let due = assignment.dueAt.flatMap(dueDisplay) {
            parts.append("Due \(due)")
        } else {
            parts.append("No due date")
        }
        parts.append("\(assignment.points) pts")
        return parts.joined(separator: " · ")
    }

    @ViewBuilder private var statusPill: some View {
        if assignment.isLesson {
            if aced {
                pill("✦ aced", Theme.gold300)
            } else {
                pill("not yet aced", Theme.inkSoft)
            }
        } else {
            switch assignment.status {
            case .graded:
                pill("\(assignment.submission?.score ?? 0)/\(assignment.points)", Theme.gold300)
            case .submitted:
                pill("submitted", Theme.success)
            case .notSubmitted:
                pill("not submitted", Theme.inkSoft)
            }
        }
    }

    private func pill(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.caption).foregroundStyle(color)
            .fixedSize()
    }
}

/// ISO-8601 → short local "Sep 20, 5:00 PM". Handles the API's fractional-seconds
/// variant like relativeTime does.
func dueDisplay(_ iso: String) -> String? {
    let withFractional = ISO8601DateFormatter()
    withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let plain = ISO8601DateFormatter()
    guard let date = withFractional.date(from: iso) ?? plain.date(from: iso) else { return nil }
    let f = DateFormatter()
    f.dateFormat = "MMM d, h:mm a"
    return f.string(from: date)
}
