import SwiftUI

// Course review: the web /courses/[id]/review. Every published question in the
// course (each lecture's quiz, then the test), shuffled. A miss comes back three
// questions later until it's answered right; the round is cleared when every
// question is mastered. Endless mode keeps cycling.
struct CourseReviewView: View {
    let route: CourseReviewRoute
    @EnvironmentObject private var auth: AuthViewModel

    private static let reinsert = 3

    @State private var pool: [ReviewQuestion] = []
    @State private var loading = true
    @State private var failed = false

    enum Phase { case intro, playing, cleared }
    @State private var phase = Phase.intro
    @State private var endless = false
    @State private var queue: [Int] = []
    @State private var mastered: Set<Int> = []
    @State private var everMissed: Set<Int> = []
    @State private var answers = 0
    @State private var stumbles = 0
    @State private var streak = 0
    @State private var reported = false
    @State private var cardId = UUID()

    var body: some View {
        Group {
            if loading {
                ProgressView()
            } else if failed {
                LoadFailedView(title: "Couldn't load the review") { await load() }
            } else if pool.isEmpty {
                ContentUnavailableView("Nothing to review yet", systemImage: "square.stack.3d.up",
                                       description: Text("This course has no published questions yet."))
            } else {
                ScrollView {
                    switch phase {
                    case .intro: intro
                    case .playing: playing
                    case .cleared: cleared
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.page)
        .navigationTitle("Course Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if phase == .playing {
                ToolbarItem(placement: .topBarTrailing) { Button("End") { finishEarly() } }
            }
        }
        .task { if pool.isEmpty { await load() } }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(route.title).font(.serif(24, .bold, relativeTo: .title)).foregroundStyle(Theme.ink)
            Text("All \(pool.count) questions from this course (every lecture quiz\(pool.contains { $0.source == "Course Test" } ? " plus the course test" : "")) in a shuffled deck. Miss one and it comes back a few questions later until you get it right. Clear the deck when you've mastered them all.")
                .font(.serif(17)).foregroundStyle(Theme.inkSoft)
            PrimaryButton(title: "Start review") { start(endless: false) }
            SecondaryButton(title: "Endless mode", systemImage: "infinity") { start(endless: true) }
        }
        .padding()
    }

    @ViewBuilder private var playing: some View {
        if let i = queue.first {
            let q = pool[i]
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(endless ? "∞ Endless · streak \(streak)" : "\(mastered.count) / \(pool.count) mastered · \(pool.count - mastered.count) to review")
                        .font(.ui(14, .medium)).monospacedDigit().foregroundStyle(Theme.inkSoft)
                    Spacer()
                }
                Text(q.source).font(.ui(13)).foregroundStyle(Theme.inkSoft).lineLimit(2)
                MCQCard(
                    prompt: q.prompt, options: q.options, correctIndex: q.correctIndex,
                    explanation: q.explanation, progress: "",
                    progressFraction: endless ? nil : Double(mastered.count) / Double(pool.count)
                ) { _, correct in advance(correct: correct) }
                .id(cardId)
            }
            .padding()
        }
    }

    private var cleared: some View {
        VStack(spacing: 16) {
            Text("Deck cleared").font(.serif(26, .bold, relativeTo: .title)).foregroundStyle(Theme.ink)
            Text("\(answers) answers").font(.ui(16)).foregroundStyle(Theme.inkSoft)
            Text(stumbles == 0
                 ? "✦ Flawless. Every question right the first time."
                 : "\(stumbles) stumble\(stumbles == 1 ? "" : "s") along the way, and every one mastered.")
                .font(.serif(18)).foregroundStyle(stumbles == 0 ? Theme.accentText : Theme.ink)
                .multilineTextAlignment(.center)
            if !auth.isSignedIn {
                SignInPrompt(message: "Sign in and clearing a course review counts toward your achievements.",
                             reason: "Save your course review.")
            }
            PrimaryButton(title: "Review again") { start(endless: false) }
            SecondaryButton(title: "Endless mode", systemImage: "infinity") {
                endless = true
                queue = Array(pool.indices).shuffled()
                cardId = UUID()
                phase = .playing
            }
        }
        .padding()
    }

    private func start(endless: Bool) {
        self.endless = endless
        queue = Array(pool.indices).shuffled()
        mastered = []
        everMissed = []
        answers = 0
        stumbles = 0
        streak = 0
        cardId = UUID()
        phase = .playing
    }

    private func advance(correct: Bool) {
        guard let i = queue.first else { return }
        answers += 1
        var rest = Array(queue.dropFirst())
        if correct {
            streak += 1
            mastered.insert(i)
        } else {
            streak = 0
            stumbles += 1
            everMissed.insert(i)
            mastered.remove(i)
            rest.insert(i, at: min(Self.reinsert, rest.count))
        }
        if rest.isEmpty {
            if endless {
                rest = Array(pool.indices).shuffled()
            } else {
                reportCleared()
                phase = .cleared
            }
        }
        queue = rest
        cardId = UUID()
    }

    private func finishEarly() {
        phase = .intro
    }

    private func reportCleared() {
        guard auth.isSignedIn, !reported else { return }
        reported = true
        struct Body: Encodable { let perfect: Bool }
        let perfect = stumbles == 0
        Task {
            if let res: BadgesResponse = try? await APIClient.shared.post(
                "/courses/\(route.courseId)/review-cleared", body: Body(perfect: perfect)) {
                Celebrations.shared.celebrate(res.badges)
            }
        }
    }

    private func load() async {
        loading = true
        do {
            let res: ReviewPoolResponse = try await APIClient.shared.get("/quiz?reviewCourseId=\(route.courseId)", auth: false)
            pool = res.questions
            failed = false
        } catch {
            failed = true
        }
        loading = false
    }
}
