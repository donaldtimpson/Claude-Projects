import SwiftUI

struct LectureView: View {
    let route: LectureRoute
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var queue: WriteQueueManager

    @State private var detail: VideoDetailResponse?
    @State private var error: String?
    @State private var loading = true
    @State private var tab = 0
    @State private var noteHeight: CGFloat = 240
    @State private var quizPhase = QuizPhase.idle
    @State private var quizScore: ScorePair?
    @State private var videoError: Int?
    @State private var aces: [QuizAce] = []
    @State private var shareItem: ShareItem?
    @State private var generatingPDF = false
    @State private var comments: [CommentItem] = []
    @State private var showCompose = false
    @State private var composeReplyTo: CommentItem?
    @State private var pendingDelete: CommentItem?
    @State private var pendingReport: CommentItem?
    @State private var pendingBlock: CommentItem?
    @State private var moderationNotice: String?
    @State private var activeDrill: ActiveDrill?
    @State private var watched = false
    @State private var markingWatched = false

    /// Lecture discussion is off in the app. Comments are rarely used on the site,
    /// and an app that shows user-generated content owes App Review the whole of
    /// Guideline 1.2 (a content filter, agreed terms, report, block). Report/block
    /// and the moderation queue are built; flip this to bring the tab back once a
    /// filter and terms exist. See APP_STORE.md §10 and §13.
    private let commentsEnabled = false

    enum QuizPhase { case idle, running, done }
    struct ScorePair { let score: Int; let total: Int }

    /// Human-readable explanation of a YouTube IFrame Player API error code.
    private func youtubeErrorMessage(_ code: Int) -> String {
        switch code {
        case 2:        return "Video unavailable (bad video ID). [YT error 2]"
        case 5:        return "Playback error in the HTML5 player. [YT error 5]"
        case 100:      return "This video was removed or is private. [YT error 100]"
        case 101, 150: return "The owner doesn't allow this video to be played in embedded players. Watch it on YouTube. [YT error \(code)]"
        default:       return "Video couldn't be played. [YT error \(code)]"
        }
    }

    var body: some View {
        content
            .leatherBar(detail?.video.label ?? "Lecture")
            .task(id: auth.user?.id) { await load() }
            .sheet(isPresented: $showCompose) {
                CommentComposeSheet(replyingTo: composeReplyTo, onSubmit: postComment)
            }
            .sheet(item: $shareItem) { ShareSheet(url: $0.url) }
            .confirmationDialog(
                "Delete this comment?",
                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                presenting: pendingDelete
            ) { target in
                Button("Delete", role: .destructive) {
                    Task { await deleteComment(target) }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
            // Report / Block / notice dialogs (App Store Guideline 1.2). Extracted
            // into one modifier so the body stays inside the type-checker's budget.
            .modifier(ModerationDialogs(
                pendingReport: $pendingReport,
                pendingBlock: $pendingBlock,
                moderationNotice: $moderationNotice,
                onReport: { comment, reason in Task { await reportComment(comment, reason: reason) } },
                onBlock: { comment in Task { await blockUser(comment) } }
            ))
            // Same presentation the drills hub uses, so a drill opened from a
            // lecture behaves identically to one opened from Practice Drills.
            .fullScreenCover(item: $activeDrill) { drill in
                NavigationStack {
                    DrillRunnerView(slug: drill.id)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button { activeDrill = nil } label: {
                                    Image(systemName: "xmark").font(.body.weight(.semibold))
                                }
                                .tint(Theme.link)
                            }
                        }
                }
            }
    }

    @ViewBuilder private var content: some View {
        if let detail {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // The film runs edge to edge, on black, like a player should.
                    YouTubePlayer(videoId: detail.video.youtubeVideoId, start: route.startSeconds) { code in
                        videoError = code
                    }
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .padding(.horizontal, -16)

                    if let videoError {
                        Text(youtubeErrorMessage(videoError))
                            .font(.ui(14)).foregroundStyle(Theme.inkSoft)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(displayTitle(detail.video.title))
                            .font(.serif(23, .bold, relativeTo: .title2))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if auth.isSignedIn { watchedButton(detail).padding(.top, 4) }
                    }

                    lectureNav(detail)

                    // Practice sits above the tabs: it's navigation to another
                    // screen, not another tab of this lecture's content.
                    practiceSection(detail)

                    Picker("Section", selection: $tab) {
                        Text("Notes").tag(0)
                        Text("Quiz (\(detail.quiz.count))").tag(1)
                        if commentsEnabled {
                            Text("Discussion (\(liveCommentCount(comments)))").tag(2)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch tab {
                    case 1: quizSection(detail)
                    case 2 where commentsEnabled: discussionSection(detail)
                    default: notesSection(detail)
                    }
                }
                .padding()
            }
            .background(Theme.page)
        } else if error != nil {
            LoadFailedView(title: "Couldn't load this lecture") { await load() }.background(Theme.page)
        } else {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.page)
        }
    }

    /// Mark as watched, as on the web: an explicit choice, since watching is
    /// what counts toward attendance.
    private func watchedButton(_ detail: VideoDetailResponse) -> some View {
        Button {
            guard !watched else { return }
            Task { await markWatched(detail) }
        } label: {
            HStack(spacing: 6) {
                if markingWatched {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: watched ? "checkmark.circle.fill" : "circle")
                }
                Text(watched ? "Watched" : "Mark as watched")
            }
            .font(.ui(15, .semibold))
            .foregroundStyle(watched ? Theme.success : Theme.ink)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(watched ? Theme.successFill : Theme.button)
            .overlay(Capsule().stroke(watched ? Theme.successLine : Theme.line, lineWidth: 1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(markingWatched)
        .accessibilityHint(watched ? "" : "Counts toward attendance in your class.")
    }

    /// Previous / next lecture as one bound pair of rows; after the last lecture, the
    /// course test if there is one.
    @ViewBuilder private func lectureNav(_ detail: VideoDetailResponse) -> some View {
        let testCount = detail.courseTestQuestionCount ?? 0
        if detail.prev != nil || detail.next != nil || testCount > 0 {
            Codex(dividerInset: 50) {
                if let prev = detail.prev {
                    NavigationLink(value: LectureRoute(courseId: route.courseId, videoId: prev.id, title: prev.title)) {
                        turnRow(icon: "chevron.left", eyebrow: "Previous · \(prev.label)", title: displayTitle(prev.title))
                    }
                    .buttonStyle(.lyceumRow)
                }
                if let next = detail.next {
                    NavigationLink(value: LectureRoute(courseId: route.courseId, videoId: next.id, title: next.title)) {
                        turnRow(icon: "chevron.right", eyebrow: "Next · \(next.label)", title: displayTitle(next.title))
                    }
                    .buttonStyle(.lyceumRow)
                } else if testCount > 0 {
                    NavigationLink(value: CourseTestRoute(courseId: route.courseId, title: "Course Test")) {
                        turnRow(icon: "checkmark.seal", eyebrow: "That's the last lecture", title: "Take the course test")
                    }
                    .buttonStyle(.lyceumRow)
                }
            }
        }
    }

    private func turnRow(icon: String, eyebrow: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.link)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow.uppercased()).font(.ui(10.5, .semibold, relativeTo: .caption2)).kerning(0.8)
                    .foregroundStyle(Theme.inkSoft)
                Text(title).font(.serif(16, .semibold)).foregroundStyle(Theme.ink).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .codexRow()
    }

    /// Lesson drills tagged as covering this lecture, resolved against the bundled
    /// catalog. A slug this build doesn't carry is dropped — better no row than a
    /// row that can't open.
    private func lessonDrills(_ detail: VideoDetailResponse) -> [DrillDef] {
        (detail.lessonSlugs ?? []).compactMap { DrillCatalog.drill(slug: $0) }
    }

    @ViewBuilder private func practiceSection(_ detail: VideoDetailResponse) -> some View {
        let sets = detail.problemSets ?? []
        let drills = lessonDrills(detail)
        if !sets.isEmpty || !drills.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle("Practice")
                Codex {
                ForEach(sets) { ps in
                    NavigationLink(value: ProblemSetRoute(courseId: route.courseId, problemSetId: ps.id, title: ps.title)) {
                        ProblemSetRow(ps: ProblemSetItem(
                            id: ps.id, title: ps.title, points: ps.points, hasSolutions: ps.hasSolutions,
                            isTest: ps.isTest))
                    }
                    .buttonStyle(.lyceumRow)
                }
                // From a student's side "practice this lecture" is one idea, whatever form it takes.
                ForEach(drills) { d in
                    Button { activeDrill = ActiveDrill(id: d.slug) } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(d.title).font(.serif(17, .semibold)).foregroundStyle(Theme.ink)
                                    .multilineTextAlignment(.leading).lineLimit(2)
                                Text(d.blurb).font(.ui(13)).foregroundStyle(Theme.inkSoft)
                                    .multilineTextAlignment(.leading).lineLimit(2)
                            }
                            Spacer(minLength: 0)
                            if LessonProgress.shared.isAced(userId: auth.user?.id ?? "guest", slug: d.slug) {
                                Text("✦ Aced").font(.ui(13, .semibold)).foregroundStyle(Theme.accentText)
                            }
                            Image(systemName: "chevron.right").font(.ui(13, .semibold)).foregroundStyle(Theme.inkSoft.opacity(0.6))
                        }
                        .codexRow()
                    }
                    .buttonStyle(.lyceumRow)
                }
                }
            }
        }
    }

    @ViewBuilder private func notesSection(_ detail: VideoDetailResponse) -> some View {
        if let note = detail.note {
            VStack(spacing: 8) {
                HStack {
                    Spacer(minLength: 0)
                    Button {
                        exportNotesPDF(markdown: note.content, lectureTitle: detail.video.title)
                    } label: {
                        if generatingPDF {
                            ProgressView()
                        } else {
                            Label("Share as PDF", systemImage: "square.and.arrow.up").font(.ui(14, .semibold))
                        }
                    }
                    .disabled(generatingPDF)
                    .foregroundStyle(Theme.link)
                    .accessibilityLabel("Share notes as PDF")
                }
                MathWebView(markdown: note.content, height: $noteHeight)
                    .frame(height: noteHeight)
                    .lyceumCard()
            }
        } else {
            EmptyNote("No study notes for this lecture yet.")
        }
    }

    @ViewBuilder private func quizSection(_ detail: VideoDetailResponse) -> some View {
        if detail.quiz.isEmpty {
            EmptyNote("No quiz for this lecture yet.")
        } else {
            VStack(spacing: 16) {
                switch quizPhase {
                case .idle:
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(detail.quiz.count) questions on this lecture").font(.serif(18, .semibold)).foregroundStyle(Theme.ink)
                        Text("Your best attempt counts, so retaking only helps.").font(.serif(16)).foregroundStyle(Theme.inkSoft)
                        PrimaryButton(title: "Start quiz") { quizPhase = .running }
                    }
                    .lyceumCard()
                case .running:
                    QuizView(questions: detail.quiz) { score, total, answers in
                        quizScore = ScorePair(score: score, total: total)
                        quizPhase = .done
                        Task {
                            _ = await queue.submit(
                                path: "/quiz/attempt",
                                body: QuizAttemptBody(videoId: detail.video.id, courseId: nil,
                                                      score: score, total: total, answers: answers,
                                                      clientId: makeClientId()),
                                clientId: makeClientId()
                            )
                            // A perfect score joins the Hall of Aces — refresh it.
                            if score == total { await refreshAces() }
                        }
                    }
                case .done:
                    if let quizScore {
                        let pct = quizScore.total > 0 ? Double(quizScore.score) / Double(quizScore.total) * 100 : 0
                        VStack(spacing: 12) {
                            HStack(spacing: 4) {
                                if pct >= 100 { Image(systemName: "laurel.leading") }
                                VStack(spacing: 0) {
                                    Text("\(quizScore.score) / \(quizScore.total)")
                                        .font(.ui(40, .bold)).monospacedDigit().foregroundStyle(Theme.ink)
                                    Text("\(Int(pct.rounded()))%").font(.ui(17, .semibold)).foregroundStyle(Theme.grade(pct))
                                }
                                if pct >= 100 { Image(systemName: "laurel.trailing") }
                            }
                            .font(.system(size: 50, weight: .light))
                            .foregroundStyle(Theme.gilt)
                            Text(pct >= 100 ? "✦ Perfect. You aced this lecture."
                                 : pct >= 70 ? "Good work. Retake it any time to raise your best."
                                 : "Keep studying: the notes above cover every question.")
                                .font(.serif(17)).foregroundStyle(pct >= 100 ? Theme.accentText : Theme.inkSoft)
                                .multilineTextAlignment(.center)
                            if !auth.isSignedIn {
                                SignInPrompt(
                                    message: "This score isn't saved. An account keeps your scores and feeds them into daily review.",
                                    reason: "Save this quiz score and review what you missed.")
                            }
                            SecondaryButton(title: "Retake quiz") { quizPhase = .running }
                        }
                        .lyceumCard()
                    }
                }

                QuizAcesView(aces: aces, myUserId: auth.user?.id)
            }
        }
    }

    @ViewBuilder private func discussionSection(_ detail: VideoDetailResponse) -> some View {
        DiscussionSection(
            comments: comments,
            isSignedIn: auth.isSignedIn,
            currentUserId: auth.user?.id,
            onAdd: { composeReplyTo = nil; showCompose = true },
            onReply: { composeReplyTo = $0; showCompose = true },
            onDelete: { pendingDelete = $0 },
            onReport: { pendingReport = $0 },
            onBlock: { pendingBlock = $0 }
        )
    }

    private func exportNotesPDF(markdown: String, lectureTitle: String) {
        generatingPDF = true
        Task {
            let exporter = NotesPDFExporter()
            let url = await exporter.export(markdown: markdown, title: "\(lectureTitle) — Notes")
            generatingPDF = false
            if let url { shareItem = ShareItem(url: url) }
        }
    }

    private func markWatched(_ detail: VideoDetailResponse) async {
        markingWatched = true
        let id = makeClientId()
        _ = await queue.submit(
            path: "/progress/video-watched",
            body: VideoWatchedBody(videoId: detail.video.id, clientId: id),
            clientId: id
        )
        // Queued offline writes replay later; show it as watched either way.
        withAnimation { watched = true }
        markingWatched = false
        Haptics.success()
    }

    private func refreshAces() async {
        if let res: VideoDetailResponse = try? await APIClient.shared.get(
            "/courses/\(route.courseId)/videos/\(route.videoId)", auth: false) {
            aces = res.aces ?? []
        }
    }

    private func reloadComments() async {
        guard let videoId = detail?.video.id else { return }
        if let res: CommentsResponse = try? await APIClient.shared.get(
            "/comments?videoId=\(videoId)", auth: false) {
            comments = res.comments
        }
    }

    /// Posts a new comment or reply; returns true on success (the compose sheet dismisses).
    private func postComment(_ body: String) async -> Bool {
        guard let videoId = detail?.video.id else { return false }
        do {
            let _: CommentItem = try await APIClient.shared.post(
                "/comments",
                body: NewCommentBody(videoId: videoId, body: body, parentId: composeReplyTo?.id)
            )
            await reloadComments()
            return true
        } catch {
            return false
        }
    }

    private func deleteComment(_ comment: CommentItem) async {
        do {
            let _: DeleteCommentResult = try await APIClient.shared.delete("/comments/\(comment.id)")
        } catch {
            // Swallow — a failed delete just leaves the comment in place.
        }
        await reloadComments()
    }

    /// Files a moderation report for a comment (App Store Guideline 1.2).
    private func reportComment(_ comment: CommentItem, reason: String) async {
        do {
            let _: ModerationAck = try await APIClient.shared.post(
                "/comments/\(comment.id)/report",
                body: ReportCommentBody(reason: reason)
            )
            moderationNotice = "Reported. Thank you — we'll review it."
        } catch {
            moderationNotice = "Couldn't send the report. Please try again."
        }
    }

    /// Blocks a comment's author, then drops their comments from the current view.
    /// A reload would also exclude them (the listing filters blocked authors
    /// server-side), but pruning locally makes the block feel immediate.
    private func blockUser(_ comment: CommentItem) async {
        do {
            let _: ModerationAck = try await APIClient.shared.post(
                "/blocks",
                body: BlockUserBody(blockedId: comment.user.id)
            )
            let blockedId = comment.user.id
            comments = comments.compactMap { top in
                if !top.deleted && top.user.id == blockedId { return nil }
                return top.withReplies(top.replies.filter { $0.deleted || $0.user.id != blockedId })
            }
        } catch {
            moderationNotice = "Couldn't block this user. Please try again."
        }
    }

    private func load() async {
        do {
            let res: VideoDetailResponse = try await APIClient.shared.get(
                "/courses/\(route.courseId)/videos/\(route.videoId)")
            detail = res
            aces = res.aces ?? []
            error = nil
            watched = res.watched ?? false
            if commentsEnabled { await reloadComments() }
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

// The comment Report / Block / notice dialogs, factored out of LectureView.body so
// the lecture screen's view expression stays inside the Swift type-checker's time
// budget. Report offers a reason picker; Block confirms; a shared alert relays the
// outcome. (App Store Guideline 1.2 moderation affordances.)
private struct ModerationDialogs: ViewModifier {
    @Binding var pendingReport: CommentItem?
    @Binding var pendingBlock: CommentItem?
    @Binding var moderationNotice: String?
    let onReport: (CommentItem, String) -> Void
    let onBlock: (CommentItem) -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Report this comment",
                isPresented: Binding(get: { pendingReport != nil }, set: { if !$0 { pendingReport = nil } }),
                titleVisibility: .visible,
                presenting: pendingReport
            ) { target in
                ForEach(ReportReason.all) { reason in
                    Button(reason.label, role: .destructive) {
                        onReport(target, reason.value)
                        pendingReport = nil
                    }
                }
                Button("Cancel", role: .cancel) { pendingReport = nil }
            }
            .confirmationDialog(
                pendingBlock.map { "Block \($0.user.name)?" } ?? "Block user?",
                isPresented: Binding(get: { pendingBlock != nil }, set: { if !$0 { pendingBlock = nil } }),
                titleVisibility: .visible,
                presenting: pendingBlock
            ) { target in
                Button("Block", role: .destructive) {
                    onBlock(target)
                    pendingBlock = nil
                }
                Button("Cancel", role: .cancel) { pendingBlock = nil }
            } message: { _ in
                Text("You won't see this person's comments anymore.")
            }
            .alert(
                "Moderation",
                isPresented: Binding(get: { moderationNotice != nil }, set: { if !$0 { moderationNotice = nil } }),
                presenting: moderationNotice
            ) { _ in
                Button("OK", role: .cancel) { moderationNotice = nil }
            } message: { note in
                Text(note)
            }
    }
}
