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
    @State private var activeDrill: ActiveDrill?

    /// Lecture discussion is off for the 1.0 App Store submission. Comments are
    /// user-generated content, and Guideline 1.2 requires a way to report
    /// content and block users, which we don't have yet — App Review asked to
    /// see exactly that. Flip this back on once moderation ships; nothing else
    /// was removed, and the backend endpoints are untouched. See APP_STORE.md §10.
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
            .navigationTitle(detail.map { "Lecture \($0.video.position + 1)" } ?? "Lecture")
            .navigationBarTitleDisplayMode(.inline)
            .task { if detail == nil { await load() } }
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
                                .tint(Theme.gold300)
                            }
                        }
                }
            }
    }

    @ViewBuilder private var content: some View {
        if loading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.parchment)
        } else if let error {
            ContentUnavailableView("Couldn't load lecture", systemImage: "wifi.slash", description: Text(error))
        } else if let detail {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(detail.video.title)
                        .font(.display(20))
                        .kerning(0.5)
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    YouTubePlayer(videoId: detail.video.youtubeVideoId) { code in
                        videoError = code
                    }
                        .aspectRatio(16.0 / 9.0, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if let videoError {
                        Text(youtubeErrorMessage(videoError))
                            .font(.footnote)
                            .foregroundStyle(Theme.inkSoft)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Practice sits above the tabs rather than becoming a fourth
                    // segment: it's navigation to another screen, not another tab
                    // of this lecture's content, and the segmented control is
                    // already carrying long labels.
                    practiceSection(detail)

                    Picker("", selection: $tab) {
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
            .background(Theme.parchment)
        }
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
            VStack(alignment: .leading, spacing: 8) {
                Text("PRACTICE")
                    .font(.display(11)).kerning(2).foregroundStyle(Theme.gold400)
                ForEach(sets) { ps in
                    NavigationLink(value: ProblemSetRoute(
                        courseId: route.courseId, problemSetId: ps.id, title: ps.title)
                    ) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ps.title)
                                    .font(.display(14)).foregroundStyle(Theme.ink)
                                    .multilineTextAlignment(.leading).lineLimit(2)
                                Text((ps.hasSolutions ?? false)
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
                // Same section as the problem sets: from a student's side "practice
                // this lecture" is one idea, whatever form the practice takes.
                ForEach(drills) { d in
                    Button { activeDrill = ActiveDrill(id: d.slug) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(d.title)
                                    .font(.display(14)).foregroundStyle(Theme.ink)
                                    .multilineTextAlignment(.leading).lineLimit(2)
                                Text(d.blurb)
                                    .font(.serif(13)).foregroundStyle(Theme.inkSoft)
                                    .multilineTextAlignment(.leading).lineLimit(2)
                            }
                            Spacer(minLength: 0)
                            if LessonProgress.shared.isAced(userId: auth.user?.id ?? "guest", slug: d.slug) {
                                Text("✦")
                                    .font(.display(15)).foregroundStyle(Theme.gold300)
                                    .accessibilityLabel("Aced")
                            }
                            Image(systemName: "chevron.right").foregroundStyle(Theme.gold400)
                        }
                        .lyceumCard()
                    }
                    .buttonStyle(.lyceumPress)
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
                            Image(systemName: "square.and.arrow.up").font(.title3)
                        }
                    }
                    .disabled(generatingPDF)
                    .foregroundStyle(Theme.gold400)
                    .accessibilityLabel("Share notes as PDF")
                }
                MathWebView(markdown: note.content, height: $noteHeight)
                    .frame(height: noteHeight)
                    .lyceumCard()
            }
        } else {
            Text("No study notes for this lecture yet.").foregroundStyle(Theme.inkSoft)
        }
    }

    @ViewBuilder private func quizSection(_ detail: VideoDetailResponse) -> some View {
        if detail.quiz.isEmpty {
            Text("No quiz for this lecture yet.").foregroundStyle(Theme.inkSoft)
        } else {
            VStack(spacing: 16) {
                switch quizPhase {
                case .idle:
                    VStack(spacing: 12) {
                        Text("\(detail.quiz.count) questions").foregroundStyle(Theme.ink)
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
                        VStack(spacing: 12) {
                            Text("\(quizScore.score) / \(quizScore.total)")
                                .font(.largeTitle.weight(.bold)).foregroundStyle(Theme.crimson)
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
            onDelete: { pendingDelete = $0 }
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

    private func load() async {
        do {
            let res: VideoDetailResponse = try await APIClient.shared.get(
                "/courses/\(route.courseId)/videos/\(route.videoId)", auth: false)
            detail = res
            aces = res.aces ?? []
            error = nil
            if commentsEnabled { await reloadComments() }
            if auth.isSignedIn {
                _ = await queue.submit(
                    path: "/progress/video-watched",
                    body: VideoWatchedBody(videoId: res.video.id, clientId: makeClientId()),
                    clientId: makeClientId()
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
