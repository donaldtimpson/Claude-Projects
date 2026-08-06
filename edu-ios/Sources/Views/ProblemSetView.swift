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

    @State private var detail: ProblemSetDetail?
    @State private var error: String?
    @State private var loading = true
    @State private var webHeight: CGFloat = 400
    @State private var revealAll = false
    @State private var shareItem: ShareItem?
    @State private var generatingPDF = false

    var body: some View {
        content
            .navigationTitle(detail?.title ?? route.title)
            .navigationBarTitleDisplayMode(.inline)
            .task { if detail == nil { await load() } }
            .sheet(item: $shareItem) { ShareSheet(url: $0.url) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let detail, !detail.content.isPaired || detail.solutionsAvailable {
                        Button {
                            exportPDF(detail)
                        } label: {
                            if generatingPDF {
                                ProgressView()
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        .disabled(generatingPDF)
                        .foregroundStyle(Theme.gold400)
                        .accessibilityLabel("Share problem set as PDF")
                    }
                }
            }
    }

    @ViewBuilder private var content: some View {
        if loading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.parchment)
        } else if let error {
            ContentUnavailableView(
                "Couldn't load problem set", systemImage: "wifi.slash", description: Text(error))
        } else if let detail {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header(detail)

                    if detail.content.isPaired, let parts = detail.content.parts {
                        if detail.solutionsAvailable {
                            revealBar(count: parts.filter { $0.solution != nil }.count)
                        }
                        ProblemSetWebView(
                            parts: parts,
                            problemsPreamble: detail.content.problemsPreamble,
                            solutionPreamble: detail.content.solutionPreamble,
                            revealAll: revealAll,
                            height: $webHeight
                        )
                        .frame(height: webHeight)
                    } else {
                        // Fallback shape: the two halves didn't line up server-side,
                        // so problems and solutions arrive as whole documents.
                        blocksBody(detail)
                    }
                }
                .padding()
            }
            .background(Theme.parchment)
        }
    }

    @ViewBuilder private func header(_ detail: ProblemSetDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if detail.points > 0 || detail.extraCreditPoints > 0 {
                Text(pointsLine(detail))
                    .font(.serif(13)).foregroundStyle(Theme.inkSoft)
            }
            // A set follows a chapter, so it usually covers more than one lecture.
            if let lectures = detail.lectures, !lectures.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("COVERS")
                        .font(.display(11)).kerning(2).foregroundStyle(Theme.gold400)
                    ForEach(lectures) { lecture in
                        NavigationLink(value: LectureRoute(
                            courseId: route.courseId, videoId: lecture.id, title: lecture.title)
                        ) {
                            HStack(spacing: 6) {
                                Text(lecture.title)
                                    .font(.serif(14)).foregroundStyle(Theme.inkSoft)
                                    .multilineTextAlignment(.leading)
                                Image(systemName: "chevron.right")
                                    .font(.caption2).foregroundStyle(Theme.gold400)
                            }
                        }
                        .buttonStyle(.lyceumPress)
                    }
                }
            }
            if let urlString = detail.attachmentUrl, let url = URL(string: urlString) {
                Link(destination: url) {
                    Label("Open attachment", systemImage: "paperclip")
                        .font(.serif(14)).foregroundStyle(Theme.gold300)
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
            Button {
                revealAll.toggle()
            } label: {
                Text(revealAll ? "Hide all solutions" : "Reveal all solutions")
                    .font(.display(11)).kerning(1.5)
                    .foregroundStyle(revealAll ? Theme.gold300 : Theme.inkSoft)
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(revealAll ? Theme.gold500 : Theme.line, lineWidth: 1)
                    )
            }
            .buttonStyle(.lyceumPress)
            Text("Worked solutions for all \(count).")
                .font(.serif(13)).foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder private func blocksBody(_ detail: ProblemSetDetail) -> some View {
        if let body = detail.content.body {
            MathWebView(markdown: body, height: $webHeight)
                .frame(height: webHeight)
                .lyceumCard()
        }
        if let solution = detail.content.solution {
            DisclosureGroup("Solutions") {
                MathWebView(markdown: solution, height: $webHeight)
                    .frame(height: webHeight)
            }
            .tint(Theme.gold300)
        }
    }

    /// Flatten the set back to one Markdown document for the PDF exporter, which
    /// renders a light-themed printable page from Markdown.
    private func exportPDF(_ detail: ProblemSetDetail) {
        generatingPDF = true
        var md = ""
        if detail.content.isPaired, let parts = detail.content.parts {
            if let pre = detail.content.problemsPreamble, !pre.isEmpty { md += pre + "\n\n" }
            if let pre = detail.content.solutionPreamble, !pre.isEmpty { md += pre + "\n\n" }
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
                "/courses/\(route.courseId)/problems/\(route.problemSetId)", auth: false)
            detail = res.problemSet
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
