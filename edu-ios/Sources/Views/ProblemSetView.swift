import SwiftUI

/// Navigation target for a problem set. `title` lets the nav bar fill in before
/// the detail request comes back.
struct ProblemSetRoute: Hashable {
    let courseId: String
    let problemSetId: String
    let title: String
}

// Problems with their worked solutions attached, matching the web page: each
// answer sits under the problem it answers, collapsed until asked for.
struct ProblemSetView: View {
    let route: ProblemSetRoute
    @EnvironmentObject private var auth: AuthViewModel

    @State private var detail: ProblemSetDetail?
    @State private var failed = false
    @State private var webHeight: CGFloat = 400
    @State private var solutionHeight: CGFloat = 300
    @State private var revealAll = false
    @State private var showBlockSolutions = false
    @State private var shareItem: ShareItem?
    @State private var generatingPDF = false

    var body: some View {
        content
            .navigationTitle(detail?.title ?? route.title)
            .navigationBarTitleDisplayMode(.inline)
            .task(id: auth.user?.id) { await load() }
            .sheet(item: $shareItem) { ShareSheet(url: $0.url) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let detail {
                        Button {
                            exportPDF(detail)
                        } label: {
                            if generatingPDF { ProgressView() } else { Image(systemName: "square.and.arrow.up") }
                        }
                        .disabled(generatingPDF)
                        .accessibilityLabel("Share problem set as PDF")
                    }
                }
            }
    }

    @ViewBuilder private var content: some View {
        if let detail {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header(detail)
                    ForEach(detail.homework ?? []) { HomeworkBanner(homework: $0, detail: detail, courseId: route.courseId) }

                    if detail.content.isPaired, let parts = detail.content.parts {
                        if detail.solutionsAvailable, parts.contains(where: { $0.solution != nil }) {
                            revealBar(count: parts.filter { $0.solution != nil }.count)
                        }
                        ProblemSetWebView(
                            parts: parts,
                            problemsPreamble: detail.content.problemsPreamble,
                            revealAll: revealAll,
                            height: $webHeight
                        )
                        .frame(height: webHeight)
                    } else {
                        // The two halves didn't line up server-side, so problems and
                        // solutions arrive as whole documents.
                        blocksBody(detail)
                    }
                }
                .padding()
            }
            .background(Theme.page)
            .refreshable { await load() }
        } else if failed {
            LoadFailedView(title: "Couldn't load this problem set") { await load() }.background(Theme.page)
        } else {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.page)
        }
    }

    @ViewBuilder private func header(_ detail: ProblemSetDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(detail.title).font(.serif(24, .bold, relativeTo: .title)).foregroundStyle(Theme.ink)
                if detail.isTest == true { Pill("Test") }
            }
            if detail.points > 0 || detail.extraCreditPoints > 0 {
                Text(pointsLine(detail)).font(.ui(14)).foregroundStyle(Theme.inkSoft)
            }
            // A set follows a chapter, so it usually covers several lectures.
            if let lectures = detail.lectures, !lectures.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Eyebrow("Covers")
                    FlowLayout(spacing: 6) {
                        ForEach(lectures) { lecture in
                            NavigationLink(value: LectureRoute(courseId: route.courseId, videoId: lecture.id, title: lecture.title)) {
                                Text(lecture.label ?? lecture.title)
                                    .font(.ui(13, .medium)).foregroundStyle(Theme.ink)
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(Theme.field)
                                    .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(lecture.title)
                        }
                    }
                }
            }
            if let urlString = detail.attachmentUrl, let url = URL(string: urlString) {
                Link(destination: url) {
                    Label("Open attachment", systemImage: "paperclip").font(.ui(15, .semibold)).foregroundStyle(Theme.link)
                }
            }
        }
    }

    private func pointsLine(_ detail: ProblemSetDetail) -> String {
        var s = "\(detail.points) points"
        if detail.extraCreditPoints > 0 { s += " · \(detail.extraCreditPoints) extra credit" }
        return s
    }

    @ViewBuilder private func revealBar(count: Int) -> some View {
        HStack(spacing: 10) {
            Button { revealAll.toggle() } label: {
                Text("\(revealAll ? "▾" : "▸") \(revealAll ? "Hide all solutions" : "Reveal all solutions")")
                    .font(.ui(15, .semibold)).foregroundStyle(Theme.link)
            }
            .buttonStyle(.plain)
            Text("Worked solutions for every problem.").font(.ui(13)).foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder private func blocksBody(_ detail: ProblemSetDetail) -> some View {
        if let body = detail.content.body, !body.isEmpty {
            MathWebView(markdown: body, height: $webHeight)
                .frame(height: webHeight)
                .lyceumCard()
        } else {
            EmptyNote("See the attachment above for the problems.")
        }
        if let solution = detail.content.solution {
            Button { showBlockSolutions.toggle() } label: {
                Text("\(showBlockSolutions ? "▾ Hide" : "▸ Show") solutions").font(.ui(15, .semibold)).foregroundStyle(Theme.link)
            }
            .buttonStyle(.plain)
            if showBlockSolutions {
                MathWebView(markdown: solution, height: $solutionHeight)
                    .frame(height: solutionHeight)
                    .padding(.leading, 14)
                    .overlay(alignment: .leading) { Rectangle().fill(Theme.ornament).frame(width: 3) }
            }
        }
    }

    /// Flatten the set back to one Markdown document for the PDF exporter, which
    /// renders a light-themed printable page from Markdown.
    private func exportPDF(_ detail: ProblemSetDetail) {
        generatingPDF = true
        var md = ""
        if detail.content.isPaired, let parts = detail.content.parts {
            if let pre = detail.content.problemsPreamble, !pre.isEmpty { md += pre + "\n\n" }
            for part in parts {
                md += part.problem + "\n\n"
                if let s = part.solution { md += "**Solution.** " + s + "\n\n" }
            }
        } else {
            md = (detail.content.body ?? "")
            if let s = detail.content.solution { md += "\n\n## Solutions\n\n" + s }
        }
        let markdown = md
        Task {
            let exporter = NotesPDFExporter()
            let url = await exporter.export(markdown: markdown, title: detail.title)
            generatingPDF = false
            if let url { shareItem = ShareItem(url: url) }
        }
    }

    private func load() async {
        do {
            let res: ProblemSetDetailResponse = try await APIClient.shared.get(
                "/courses/\(route.courseId)/problems/\(route.problemSetId)")
            detail = res.problemSet
            failed = false
        } catch {
            if detail == nil { failed = true }
        }
    }
}

/// "Homework" banner for an enrolled student: which class assigned it, when it's
/// due, where they stand, and the way to turn it in.
struct HomeworkBanner: View {
    let homework: ProblemSetHomework
    let detail: ProblemSetDetail
    let courseId: String

    var body: some View {
        NavigationLink(value: AssignmentRoute(assignment: assignment, courseId: courseId, courseTitle: homework.sectionName)) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow("Homework", color: Theme.accentText)
                    Text(subtitle).font(.ui(14)).foregroundStyle(Theme.inkSoft)
                    Text(status.0).font(.ui(14, .semibold)).foregroundStyle(status.1)
                }
                Spacer(minLength: 8)
                Text(homework.submission == nil ? "Turn it in" : "View")
                    .font(.ui(15, .semibold)).foregroundStyle(Theme.link)
                Image(systemName: "chevron.right").font(.ui(13, .semibold)).foregroundStyle(Theme.link)
            }
            .lyceumCard()
            .overlay(alignment: .leading) {
                UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 12).fill(Theme.ornament).frame(width: 4)
            }
        }
        .buttonStyle(.lyceumPress)
    }

    private var assignment: AssignmentItem {
        AssignmentItem(id: homework.id, kind: "problemSet", title: homework.title, points: homework.points,
                       dueAt: homework.dueAt, courseId: courseId, problemSetId: detail.id,
                       solutionsAvailable: detail.solutionsAvailable, lessonSlug: nil,
                       submission: homework.submission)
    }

    private var subtitle: String {
        var s = "Assigned in \(homework.sectionName)"
        if let due = homework.dueAt { s += " · due \(formatDate(due, time: true))" }
        return s
    }

    private var status: (String, Color) {
        if let sub = homework.submission {
            if let score = sub.score { return ("Graded: \(score)/\(homework.points)", Theme.ink) }
            return ("Submitted, awaiting a grade", Theme.success)
        }
        if let due = homework.dueAt, let d = ISO8601DateFormatter.lyceum.date(from: due), d < .now {
            return ("Past due, not submitted", Theme.danger)
        }
        return ("Not submitted yet", Theme.inkSoft)
    }
}

extension ISO8601DateFormatter {
    /// Parses the server's timestamps (with or without fractional seconds).
    static let lyceum: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}
