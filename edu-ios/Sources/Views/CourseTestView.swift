import SwiftUI

// The course test — the whole-course exam the web has always offered at
// /courses/[id]/test and the app had no way to reach, even though the mobile /quiz
// endpoint already served it (courseId with videoId: null).
//
// Deliberately reuses QuizView, so a test question behaves exactly like a lecture
// quiz question: same card, same reveal, same keyboard. The only differences are the
// question set and that the attempt is recorded against the course rather than a video.
struct CourseTestView: View {
    let courseId: String
    let courseTitle: String

    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var queue: WriteQueueManager

    @State private var questions: [QuizQuestion] = []
    @State private var loading = true
    @State private var error: String?
    @State private var phase = Phase.idle
    @State private var score: ScorePair?

    enum Phase { case idle, running, done }
    struct ScorePair { let score: Int; let total: Int }

    var body: some View {
        Group {
            if loading {
                ProgressView().tint(Theme.gold300)
            } else if let error {
                ContentUnavailableView("Couldn't load", systemImage: "wifi.slash", description: Text(error))
            } else {
                switch phase {
                case .running:
                    QuizView(questions: questions) { s, t, answers in
                        score = ScorePair(score: s, total: t)
                        phase = .done
                        record(score: s, total: t, answers: answers)
                    }
                default:
                    ScrollView { summary }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.parchment)
        .navigationTitle("Course Test")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    @ViewBuilder private var summary: some View {
        VStack(spacing: 16) {
            Text(courseTitle)
                .font(.display(20)).foregroundStyle(Theme.crimson)
                .multilineTextAlignment(.center)

            if let score {
                Text("\(score.score) / \(score.total)")
                    .font(.system(size: 40, weight: .bold)).foregroundStyle(Theme.crimson)
                let pct = score.total > 0 ? Int((Double(score.score) / Double(score.total) * 100).rounded()) : 0
                // 70% is the pass mark the standing engine uses to count a course as passed.
                Text(pct >= 70 ? "\(pct)% — passed" : "\(pct)%")
                    .font(.serif(16)).foregroundStyle(pct >= 70 ? Theme.success : Theme.inkSoft)
                if !auth.isSignedIn {
                    SignInPrompt(
                        message: "This result isn't saved. An account keeps your best attempt and counts it toward your standing.",
                        reason: "Save your course test result.")
                }
                SecondaryButton(title: "Retake the test") { phase = .running }
            } else {
                Text("\(questions.count) questions covering the whole course. Your best attempt is the one that counts, so there's no penalty for trying it early.")
                    .font(.serif(15)).foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                PrimaryButton(title: "Start the test") { phase = .running }
            }
        }
        .padding()
    }

    private func load() async {
        do {
            let res: QuizResponse = try await APIClient.shared.get("/quiz?courseId=\(courseId)", auth: false)
            questions = res.questions
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    private func record(score: Int, total: Int, answers: [Int?]) {
        // Signed out the test still runs; there's just nothing to attribute it to.
        guard auth.isSignedIn else { return }
        Task {
            _ = await queue.submit(
                path: "/quiz/attempt",
                body: QuizAttemptBody(videoId: nil, courseId: courseId, score: score,
                                      total: total, answers: answers, clientId: makeClientId()),
                clientId: makeClientId()
            )
        }
    }
}
