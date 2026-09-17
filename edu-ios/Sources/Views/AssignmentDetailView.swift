import SwiftUI

/// Navigation target for one assignment's detail + submission. Carries the whole
/// AssignmentItem so the screen renders immediately; a fresh fetch after a submit
/// keeps the score/feedback current.
struct AssignmentRoute: Hashable {
    let assignment: AssignmentItem
    let courseId: String
    let courseTitle: String
}

// One assignment in full: what it is, a link through to the problem set (or the
// lesson drill), and — for a submittable problem-set assignment — a URL submit
// form with validation, a submit action, loading/error states, and the returned
// score + feedback once the instructor grades it. Mirrors the web class hub's
// per-assignment card + SubmitForm.
struct AssignmentDetailView: View {
    let route: AssignmentRoute

    @EnvironmentObject private var auth: AuthViewModel
    @State private var assignment: AssignmentItem
    @State private var urlText: String = ""
    @State private var submitting = false
    @State private var submitError: String?
    @State private var justSubmitted = false
    @State private var activeDrill: ActiveDrill?

    init(route: AssignmentRoute) {
        self.route = route
        _assignment = State(initialValue: route.assignment)
        _urlText = State(initialValue: route.assignment.submission?.url ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if assignment.isLesson {
                    lessonBody
                } else {
                    problemSetBody
                }
            }
            .padding()
        }
        .background(Theme.parchment)
        .navigationTitle(assignment.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: ProblemSetRoute.self) { ProblemSetView(route: $0) }
        // Same presentation the drills hub and lecture screen use, so a lesson-drill
        // homework opened here behaves identically to one opened elsewhere.
        .fullScreenCover(item: $activeDrill) { drill in
            NavigationStack {
                DrillRunnerView(slug: drill.id)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button { activeDrill = nil } label: {
                                Image(systemName: "xmark").font(.body.weight(.semibold))
                            }
                            .tint(Theme.gold300)
                        }
                    }
            }
        }
    }

    // MARK: - Header (shared)

    @ViewBuilder private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(route.courseTitle)
                .font(.serif(14)).foregroundStyle(Theme.inkSoft)
            Text(metaLine)
                .font(.serif(13)).foregroundStyle(Theme.inkSoft)
        }
    }

    private var metaLine: String {
        var parts: [String] = []
        if assignment.isLesson {
            parts.append("Grammar lesson")
        } else if let due = assignment.dueAt.flatMap(dueDisplay) {
            parts.append("Due \(due)")
        } else {
            parts.append("No due date")
        }
        parts.append("\(assignment.points) points")
        return parts.joined(separator: " · ")
    }

    // MARK: - Lesson-drill assignment (auto-graded, no URL submission)

    private var aced: Bool {
        assignment.lessonSlug
            .map { LessonProgress.shared.isAced(userId: auth.user?.id ?? "guest", slug: $0) } == true
    }

    @ViewBuilder private var lessonBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pass the 30-question homework run flawlessly to earn full credit — the ✦ is your record.")
                .font(.serif(16)).foregroundStyle(Theme.ink)

            HStack {
                Text("Status").font(.display(12)).kerning(1).foregroundStyle(Theme.gold400)
                Spacer()
                if aced {
                    Text("✦ aced · \(assignment.points)/\(assignment.points)")
                        .font(.serif(15)).foregroundStyle(Theme.gold300)
                } else {
                    Text("not yet aced").font(.serif(15)).foregroundStyle(Theme.inkSoft)
                }
            }
            .lyceumCard()

            if let slug = assignment.lessonSlug, DrillCatalog.drill(slug: slug) != nil {
                PrimaryButton(title: aced ? "Practice again" : "Do the homework drill") {
                    activeDrill = ActiveDrill(id: slug)
                }
            } else {
                Text("This lesson isn't available in this version of the app.")
                    .font(.serif(14)).foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: - Problem-set assignment (URL submission, instructor-scored)

    @ViewBuilder private var problemSetBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Link through to the problems (and their worked solutions, when public).
            if let courseId = assignment.courseId, let psId = assignment.problemSetId {
                NavigationLink(value: ProblemSetRoute(
                    courseId: courseId, problemSetId: psId, title: assignment.title
                )) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("View the problem set")
                                .font(.display(14)).foregroundStyle(Theme.ink)
                            Text((assignment.solutionsAvailable ?? false)
                                 ? "Problems with worked solutions" : "Problems")
                                .font(.serif(13)).foregroundStyle(Theme.inkSoft)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").foregroundStyle(Theme.gold400)
                    }
                    .lyceumCard()
                }
                .buttonStyle(.lyceumPress)
            }

            gradeSection
            submitSection
        }
    }

    /// The instructor's score + feedback once graded. Absent until then.
    @ViewBuilder private var gradeSection: some View {
        if assignment.status == .graded, let sub = assignment.submission {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("YOUR GRADE").font(.display(11)).kerning(2).foregroundStyle(Theme.gold400)
                    Spacer()
                    Text("\(sub.score ?? 0)/\(assignment.points)")
                        .font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.gold300)
                }
                if let feedback = sub.feedback, !feedback.isEmpty {
                    Text(feedback)
                        .font(.serif(15)).foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 10)
                        .overlay(Rectangle().fill(Theme.line).frame(width: 2), alignment: .leading)
                }
            }
            .lyceumCard()
        }
    }

    @ViewBuilder private var submitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(assignment.submission == nil ? "SUBMIT YOUR WORK" : "UPDATE YOUR SUBMISSION")
                .font(.display(11)).kerning(2).foregroundStyle(Theme.gold400)

            Text("Paste a link to your solution (Google Doc, PDF, photo album, etc.).")
                .font(.serif(14)).foregroundStyle(Theme.inkSoft)

            TextField("https://…", text: $urlText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .font(.serif(16)).foregroundStyle(Theme.ink)
                .padding(12)
                .background(Theme.parchmentDeep, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))

            if let submitError {
                Text(submitError).font(.footnote).foregroundStyle(Theme.danger)
            }
            if justSubmitted {
                Text("Submitted — your instructor can now see your link.")
                    .font(.footnote).foregroundStyle(Theme.success)
            }

            PrimaryButton(
                title: assignment.submission == nil ? "Submit" : "Resubmit",
                enabled: isValidURL,
                loading: submitting
            ) {
                Task { await submit() }
            }

            if let sub = assignment.submission, let at = sub.submittedAt.flatMap(dueDisplay) {
                Text("Last submitted \(at).")
                    .font(.caption).foregroundStyle(Theme.inkSoft)
            }
        }
        .lyceumCard()
    }

    // Matches the server's guard: a link starting with http(s)://.
    private var isValidURL: Bool {
        let t = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.range(of: "^https?://", options: [.regularExpression, .caseInsensitive]) != nil
    }

    private func submit() async {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidURL else {
            submitError = "Paste a link starting with http:// or https:// to your solution."
            return
        }
        submitting = true
        submitError = nil
        justSubmitted = false
        do {
            let res: SubmitResponse = try await APIClient.shared.post(
                "/assignments/\(assignment.id)/submit",
                body: SubmitAssignmentBody(url: trimmed))
            assignment.submission = res.submission
            urlText = res.submission.url ?? trimmed
            justSubmitted = true
            Haptics.success()
        } catch {
            submitError = error.localizedDescription
            Haptics.error()
        }
        submitting = false
    }
}
