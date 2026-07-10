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

    enum QuizPhase { case idle, running, done }
    struct ScorePair { let score: Int; let total: Int }

    var body: some View {
        content
            .navigationTitle(route.title)
            .navigationBarTitleDisplayMode(.inline)
            .wrappingNavTitle(route.title)
            .task { if detail == nil { await load() } }
    }

    @ViewBuilder private var content: some View {
        if loading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.parchment)
        } else if let error {
            ContentUnavailableView("Couldn't load lecture", systemImage: "wifi.slash", description: Text(error))
        } else if let detail {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    YouTubePlayer(videoId: detail.video.youtubeVideoId)
                        .aspectRatio(16.0 / 9.0, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Picker("", selection: $tab) {
                        Text("Notes").tag(0)
                        Text("Quiz (\(detail.quiz.count))").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if tab == 0 { notesSection(detail) } else { quizSection(detail) }
                }
                .padding()
            }
            .background(Theme.parchment)
        }
    }

    @ViewBuilder private func notesSection(_ detail: VideoDetailResponse) -> some View {
        if let note = detail.note {
            MathWebView(markdown: note.content, height: $noteHeight)
                .frame(height: noteHeight)
                .lyceumCard()
        } else {
            Text("No study notes for this lecture yet.").foregroundStyle(Theme.inkSoft)
        }
    }

    @ViewBuilder private func quizSection(_ detail: VideoDetailResponse) -> some View {
        if detail.quiz.isEmpty {
            Text("No quiz for this lecture yet.").foregroundStyle(Theme.inkSoft)
        } else {
            switch quizPhase {
            case .idle:
                VStack(spacing: 12) {
                    Text("\(detail.quiz.count) questions").foregroundStyle(Theme.ink)
                    PrimaryButton(title: "Start quiz") { quizPhase = .running }
                }
                .lyceumCard()
            case .running:
                QuizView(questions: detail.quiz) { score, total, answers in
                    Task {
                        _ = await queue.submit(
                            path: "/quiz/attempt",
                            body: QuizAttemptBody(videoId: detail.video.id, courseId: nil,
                                                  score: score, total: total, answers: answers,
                                                  clientId: makeClientId()),
                            clientId: makeClientId()
                        )
                    }
                    quizScore = ScorePair(score: score, total: total)
                    quizPhase = .done
                }
            case .done:
                if let quizScore {
                    VStack(spacing: 12) {
                        Text("\(quizScore.score) / \(quizScore.total)")
                            .font(.largeTitle.weight(.bold)).foregroundStyle(Theme.crimson)
                        if !auth.isSignedIn {
                            Text("Sign in to save your score and feed spaced repetition.")
                                .font(.footnote).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.center)
                        }
                        SecondaryButton(title: "Retake quiz") { quizPhase = .running }
                    }
                    .lyceumCard()
                }
            }
        }
    }

    private func load() async {
        do {
            let res: VideoDetailResponse = try await APIClient.shared.get(
                "/courses/\(route.courseId)/videos/\(route.videoId)", auth: false)
            detail = res
            error = nil
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
