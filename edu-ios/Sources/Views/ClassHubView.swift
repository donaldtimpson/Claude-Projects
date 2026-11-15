import SwiftUI

/// Navigation target for an enrolled class's homework. `sectionName` / `courseTitle`
/// let the nav bar fill in before the assignments request comes back.
struct ClassRoute: Hashable {
    let sectionId: String
    let sectionName: String
    let courseTitle: String
}

// One class, as the web class hub shows it: the current grade and how it's
// calculated, each instructor-defined category (e.g. Tests), homework with open
// work first, and quiz/test bests. Everything comes from GET me/classes/{id},
// built from the same gradebook as the web page.
struct ClassHubView: View {
    let route: ClassRoute

    @EnvironmentObject private var auth: AuthViewModel
    @State private var hub: ClassHub?
    @State private var failed = false

    var body: some View {
        content
            .navigationTitle(hub?.sectionName ?? route.sectionName)
            .navigationBarTitleDisplayMode(.inline)
            .task { await load() }
    }

    @ViewBuilder private var content: some View {
        if let hub {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header(hub)
                    breakdown(hub)
                    ForEach(hub.customCategories) { cat in
                        SectionTitle(cat.name)
                        VStack(spacing: 0) {
                            ForEach(Array(cat.items.enumerated()), id: \.element.id) { i, item in
                                HStack {
                                    Text(item.name).font(.serif(17)).foregroundStyle(Theme.ink)
                                    Spacer(minLength: 8)
                                    if let score = item.score {
                                        Text("\(fmt(score))/\(fmt(item.maxPoints))")
                                            .font(.ui(15, .semibold)).monospacedDigit()
                                            .foregroundStyle(Theme.grade(item.maxPoints > 0 ? score / item.maxPoints * 100 : nil))
                                    } else {
                                        Text("Not graded yet").font(.ui(13)).foregroundStyle(Theme.inkSoft)
                                    }
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                if i < cat.items.count - 1 { Divider().overlay(Theme.line) }
                            }
                        }
                        .lyceumCard(padding: 0)
                    }
                    homework(hub)
                    quizzes(hub)
                }
                .padding()
            }
            .background(Theme.page)
            .refreshable { await load() }
            .titleRevealsOnScroll(hub.sectionName)
        } else if failed {
            LoadFailedView(title: "Couldn't load this class") { await load() }.background(Theme.page)
        } else {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.page)
        }
    }

    private func header(_ hub: ClassHub) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(hub.sectionName).font(.serif(24, .bold, relativeTo: .title)).foregroundStyle(Theme.ink)
                NavigationLink(value: CourseRoute(courseId: hub.courseId)) {
                    Text("\(hub.courseTitle): go to lectures →")
                        .font(.ui(14, .medium)).foregroundStyle(Theme.link)
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                Text(ProfileView.pct(hub.currentGrade))
                    .font(.ui(34, .bold)).monospacedDigit()
                    .foregroundStyle(Theme.grade(hub.currentGrade))
                Text("current grade").font(.ui(12)).foregroundStyle(Theme.inkSoft)
            }
        }
    }

    @ViewBuilder private func breakdown(_ hub: ClassHub) -> some View {
        SectionTitle("How Your Grade Is Calculated")
        VStack(spacing: 0) {
            HStack {
                Eyebrow("Category")
                Spacer()
                Eyebrow("Score").frame(width: 70, alignment: .trailing)
                Eyebrow("Weight").frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(Theme.tint)
            ForEach(hub.breakdown, id: \.key) { row in
                Divider().overlay(Theme.line)
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.label).font(.serif(17)).foregroundStyle(Theme.ink)
                        Text(row.detail).font(.ui(12)).foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(ProfileView.pct(row.pct)).font(.ui(15, .semibold)).monospacedDigit()
                            .foregroundStyle(Theme.grade(row.pct))
                        if row.pct == nil { Text("pending").font(.ui(11)).foregroundStyle(Theme.inkSoft) }
                    }
                    .frame(width: 70, alignment: .trailing)
                    Text("\(row.weight)%").font(.ui(14)).monospacedDigit().foregroundStyle(Theme.inkSoft)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
        }
        .lyceumCard(padding: 0)
        Text("Your grade is the weighted average of the categories with data so far. Pending categories don't count against you yet.")
            .font(.ui(13)).foregroundStyle(Theme.inkSoft)
    }

    @ViewBuilder private func homework(_ hub: ClassHub) -> some View {
        SectionTitle("Homework")
        if hub.assignments.isEmpty {
            EmptyNote("No homework assigned yet.")
        } else {
            let isGraded: (AssignmentItem) -> Bool = { !$0.isLesson && $0.status == .graded }
            let firstGraded = hub.assignments.firstIndex(where: isGraded)
            ForEach(Array(hub.assignments.enumerated()), id: \.element.id) { i, a in
                if i == firstGraded, i > 0 {
                    Eyebrow("Graded").padding(.top, 8)
                }
                NavigationLink(value: AssignmentRoute(assignment: a, courseId: hub.courseId, courseTitle: hub.courseTitle)) {
                    AssignmentRow(assignment: a, userId: auth.user?.id ?? "guest", compact: isGraded(a))
                }
                .buttonStyle(.lyceumPress)
            }
        }
    }

    @ViewBuilder private func quizzes(_ hub: ClassHub) -> some View {
        if !hub.quizzes.isEmpty || hub.courseTest != nil {
            SectionTitle(hub.courseTest != nil ? "Quizzes & Test" : "Quizzes")
            Text("Your best attempt counts. Retake any quiz to raise it.")
                .font(.ui(13)).foregroundStyle(Theme.inkSoft)
            VStack(spacing: 0) {
                ForEach(Array(hub.quizzes.enumerated()), id: \.element.id) { i, q in
                    NavigationLink(value: LectureRoute(courseId: hub.courseId, videoId: q.videoId, title: q.title)) {
                        quizRow(q.title, q.bestPct)
                    }
                    .buttonStyle(.plain)
                    if i < hub.quizzes.count - 1 || hub.courseTest != nil { Divider().overlay(Theme.line) }
                }
                if let test = hub.courseTest {
                    NavigationLink(value: CourseTestRoute(courseId: hub.courseId, title: hub.courseTitle)) {
                        quizRow("Course Test", test.bestPct)
                    }
                    .buttonStyle(.plain)
                }
            }
            .lyceumCard(padding: 0)
        }
    }

    private func quizRow(_ title: String, _ pct: Double?) -> some View {
        HStack {
            Text(title).font(.serif(16)).foregroundStyle(Theme.ink).lineLimit(2).multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            if let pct {
                Text(ProfileView.pct(pct)).font(.ui(15, .semibold)).monospacedDigit().foregroundStyle(Theme.grade(pct))
            } else {
                Text("Not taken").font(.ui(13)).foregroundStyle(Theme.inkSoft)
            }
            Image(systemName: "chevron.right").font(.ui(12, .semibold)).foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func fmt(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }

    private func load() async {
        do {
            hub = try await APIClient.shared.get("/me/classes/\(route.sectionId)")
            failed = false
        } catch {
            if hub == nil { failed = true }
        }
    }
}

// One homework row: title, due date and points, and where it stands. Graded
// problem sets collapse to a compact row with the score in ink.
struct AssignmentRow: View {
    let assignment: AssignmentItem
    let userId: String
    var compact: Bool = false

    private var aced: Bool {
        assignment.isLesson && assignment.lessonSlug
            .map { LessonProgress.shared.isAced(userId: userId, slug: $0) } == true
    }

    var body: some View {
        HStack(alignment: compact ? .center : .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.title).font(.serif(17, compact ? .regular : .semibold)).foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading).lineLimit(2)
                if !compact {
                    Text(detailLine).font(.ui(13)).foregroundStyle(overdue ? Theme.danger : Theme.inkSoft)
                        .multilineTextAlignment(.leading)
                    status
                }
            }
            Spacer(minLength: 8)
            if compact, let score = assignment.submission?.score {
                Text("\(score)/\(assignment.points)").font(.ui(15, .semibold)).monospacedDigit().foregroundStyle(Theme.ink)
            }
            Image(systemName: "chevron.right").font(.ui(12, .semibold)).foregroundStyle(Theme.inkSoft)
        }
        .lyceumCard(padding: compact ? 12 : 14)
    }

    private var overdue: Bool {
        guard !assignment.isLesson, assignment.submission == nil, let due = assignment.dueAt,
              let d = ISO8601DateFormatter.lyceum.date(from: due) else { return false }
        return d < .now
    }

    private var detailLine: String {
        var parts: [String] = []
        if assignment.isLesson {
            parts.append("Grammar lesson · pass the 30-question run")
        } else if let due = assignment.dueAt.flatMap(dueDisplay) {
            parts.append(overdue ? "Was due \(due)" : "Due \(due)")
        } else {
            parts.append("No due date")
        }
        parts.append("\(assignment.points) pts")
        return parts.joined(separator: " · ")
    }

    @ViewBuilder private var status: some View {
        Group {
            if assignment.isLesson {
                Text(aced ? "✦ Aced · \(assignment.points)/\(assignment.points)" : "Not yet aced")
                    .foregroundStyle(aced ? Theme.accentText : Theme.inkSoft)
            } else {
                switch assignment.status {
                case .graded: Text("Graded").foregroundStyle(Theme.ink)
                case .submitted: Text("Submitted, awaiting a grade").foregroundStyle(Theme.success)
                case .notSubmitted: Text(overdue ? "Past due, not submitted" : "Not submitted").foregroundStyle(overdue ? Theme.danger : Theme.inkSoft)
                }
            }
        }
        .font(.ui(13, .semibold))
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
