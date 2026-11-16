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
            .mastheadChrome(hub?.sectionName ?? route.sectionName)
            .task { await load() }
    }

    @ViewBuilder private var content: some View {
        if let hub {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Masthead(overlap: 40) { header(hub) }
                    VStack(alignment: .leading, spacing: 12) {
                        breakdown(hub).padding(.top, -40)
                        ForEach(hub.customCategories) { cat in
                            SectionTitle(cat.name)
                            Codex {
                                ForEach(cat.items) { item in
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
                                    .codexRow()
                                }
                            }
                        }
                        homework(hub)
                        quizzes(hub)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .background(Theme.page)
            .refreshable { await load() }
        } else if failed {
            LoadFailedView(title: "Couldn't load this class") { await load() }.background(Theme.page)
        } else {
            LoadingLeather()
        }
    }

    private func header(_ hub: ClassHub) -> some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                GiltEyebrow("Your class")
                Text(hub.sectionName).font(.serif(25, .bold, relativeTo: .title)).foregroundStyle(Theme.onLeather)
                    .lineLimit(2).minimumScaleFactor(0.8)
                NavigationLink(value: CourseRoute(courseId: hub.courseId)) {
                    HStack(spacing: 4) {
                        Text(hub.courseTitle).multilineTextAlignment(.leading)
                        Image(systemName: "chevron.right").font(.ui(11, .bold))
                    }
                    .font(.ui(14, .medium)).foregroundStyle(Theme.giltText)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 8)
            VStack(spacing: 4) {
                GradeRing(pct: hub.currentGrade, size: 82, lineWidth: 7, onLeather: true)
                Text("CURRENT GRADE").font(.ui(9.5, .semibold, relativeTo: .caption2)).kerning(0.8)
                    .foregroundStyle(Theme.onLeatherSoft)
            }
        }
    }

    /// How the grade is made: each category's score as a bar, with its weight.
    @ViewBuilder private func breakdown(_ hub: ClassHub) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow("How your grade is calculated", color: Theme.accentText)
            ForEach(hub.breakdown, id: \.key) { row in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.label).font(.serif(17, .semibold)).foregroundStyle(Theme.ink)
                        Text("\(row.weight)%").font(.ui(12, .medium)).monospacedDigit()
                            .foregroundStyle(Theme.inkSoft)
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(Capsule().fill(Theme.tint))
                            .accessibilityLabel("weight \(row.weight) percent")
                        Spacer()
                        Text(row.pct == nil ? "pending" : ProfileView.pct(row.pct))
                            .font(.ui(row.pct == nil ? 13 : 16, .semibold)).monospacedDigit()
                            .foregroundStyle(Theme.grade(row.pct))
                    }
                    ScoreBar(pct: row.pct)
                    Text(row.detail).font(.ui(12)).foregroundStyle(Theme.inkSoft)
                }
            }
            Text("Your grade is the weighted average of the categories with data so far. Pending categories don't count against you yet.")
                .font(.ui(12.5)).foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lyceumCard(padding: 18)
        .shadow(color: Color(hex: 0x2a0a0a).opacity(0.14), radius: 14, y: 6)
    }

    @ViewBuilder private func homework(_ hub: ClassHub) -> some View {
        SectionTitle("Homework")
        if hub.assignments.isEmpty {
            EmptyNote("No homework assigned yet.")
        } else {
            let isGraded: (AssignmentItem) -> Bool = { !$0.isLesson && $0.status == .graded }
            let firstGraded = hub.assignments.firstIndex(where: isGraded)
            let split = firstGraded ?? hub.assignments.count
            let open = Array(hub.assignments[..<split])
            let graded = Array(hub.assignments[split...])
            if !open.isEmpty {
                Codex { ForEach(open) { assignmentLink($0, hub: hub, compact: false) } }
            }
            if !graded.isEmpty {
                if !open.isEmpty { Eyebrow("Graded").padding(.top, 6) }
                Codex { ForEach(graded) { assignmentLink($0, hub: hub, compact: true) } }
            }
        }
    }

    private func assignmentLink(_ a: AssignmentItem, hub: ClassHub, compact: Bool) -> some View {
        NavigationLink(value: AssignmentRoute(assignment: a, courseId: hub.courseId, courseTitle: hub.courseTitle)) {
            AssignmentRow(assignment: a, userId: auth.user?.id ?? "guest", compact: compact)
        }
        .buttonStyle(.lyceumRow)
    }

    @ViewBuilder private func quizzes(_ hub: ClassHub) -> some View {
        if !hub.quizzes.isEmpty || hub.courseTest != nil {
            SectionTitle(hub.courseTest != nil ? "Quizzes & Test" : "Quizzes")
            Text("Your best attempt counts. Retake any quiz to raise it.")
                .font(.ui(13)).foregroundStyle(Theme.inkSoft)
            Codex {
                ForEach(hub.quizzes) { q in
                    NavigationLink(value: LectureRoute(courseId: hub.courseId, videoId: q.videoId, title: q.title)) {
                        quizRow(q.title, q.bestPct)
                    }
                    .buttonStyle(.lyceumRow)
                }
                if let test = hub.courseTest {
                    NavigationLink(value: CourseTestRoute(courseId: hub.courseId, title: hub.courseTitle)) {
                        quizRow("Course Test", test.bestPct)
                    }
                    .buttonStyle(.lyceumRow)
                }
            }
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
            Image(systemName: "chevron.right").font(.ui(12, .semibold)).foregroundStyle(Theme.inkSoft.opacity(0.6))
        }
        .codexRow()
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
            Image(systemName: "chevron.right").font(.ui(12, .semibold)).foregroundStyle(Theme.inkSoft.opacity(0.6))
        }
        .codexRow()
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

/// A category's score as a gold-leaf bar; the figure beside it carries the tier.
struct ScoreBar: View {
    let pct: Double?
    @State private var shown: Double = 0
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.tint)
                if pct != nil, shown > 0 {
                    Capsule()
                        .fill(Theme.giltBar)
                        .frame(width: max(6, g.size.width * shown))
                }
            }
        }
        .frame(height: 6)
        .onAppear {
            withAnimation(.spring(duration: 0.9, bounce: 0.1).delay(0.15)) { shown = min(max((pct ?? 0) / 100, 0), 1) }
        }
        .accessibilityHidden(true)
    }
}
