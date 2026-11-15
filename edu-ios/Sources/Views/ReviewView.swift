import SwiftUI

struct ReviewView: View {
    @EnvironmentObject private var queue: WriteQueueManager
    @EnvironmentObject private var auth: AuthViewModel

    @State private var deck: ReviewDeckResponse?
    @State private var error: String?
    @State private var loading = true
    @State private var phase = Phase.idle
    @State private var index = 0
    @State private var correct = 0

    enum Phase { case idle, running, done }

    var body: some View {
        Group {
            if !auth.isSignedIn {
                // Review is the one tab that can't be anonymous: the deck IS the
                // student's own history of missed questions, scheduled per person.
                // Explain that rather than just refusing.
                SignInGate(
                    icon: "square.stack.3d.up",
                    title: "Daily Review",
                    message: "Review builds a deck from the questions you've missed and brings each one back just before you'd forget it. That needs an account to remember what you've seen.",
                    reason: "Review remembers what you've missed and schedules it for you."
                )
            } else {
                switch phase {
                case .idle: idleView
                case .running: runningView
                case .done: doneView
                }
            }
        }
        .navigationTitle("Daily Review")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var cards: [DueCard] { deck?.cards ?? [] }

    @ViewBuilder private var idleView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if loading && deck == nil {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 60)
                } else if error != nil && deck == nil {
                    LoadFailedView(title: "Couldn't load your review") { await load() }
                } else {
                    let due = deck?.dueCount ?? 0
                    VStack(alignment: .leading, spacing: 12) {
                        if due > 0 {
                            Text("\(due) card\(due == 1 ? "" : "s") due today").font(.serif(22, .bold)).foregroundStyle(Theme.ink)
                            Text("Questions you've missed come back just before you'd forget them. Get one right and it waits longer; miss it and it starts over.")
                                .font(.serif(17)).foregroundStyle(Theme.inkSoft)
                            PrimaryButton(title: "Start review") {
                                index = 0; correct = 0; phase = .running
                            }
                        } else if (deck?.cards.isEmpty ?? true) && due == 0 {
                            Text("All caught up ✓").font(.serif(22, .bold)).foregroundStyle(Theme.ink)
                            Text("No cards are due right now. Take a lecture quiz and anything you miss will join your deck.")
                                .font(.serif(17)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lyceumCard()
                }
            }
            .padding()
        }
        .background(Theme.page)
        .refreshable { await load() }
        .task { await load() }
    }

    @ViewBuilder private var runningView: some View {
        ScrollView {
            if index < cards.count {
                let card = cards[index]
                VStack(alignment: .leading, spacing: 10) {
                    Text(card.source).font(.ui(13)).foregroundStyle(Theme.inkSoft).lineLimit(2)
                    MCQCard(
                        prompt: card.prompt, options: card.options, correctIndex: card.correctIndex,
                        explanation: card.explanation,
                        progress: "\(index + 1) of \(cards.count)",
                        progressFraction: Double(index) / Double(max(1, cards.count))
                    ) { _, wasCorrect in
                        if wasCorrect { correct += 1 }
                        let id = makeClientId()
                        Task {
                            _ = await queue.submit(
                                path: "/review/grade",
                                body: ReviewGradeBody(questionId: card.id, correct: wasCorrect, clientId: id),
                                clientId: id
                            )
                        }
                        if index + 1 < cards.count { index += 1 } else { finish() }
                    }
                    .id(card.id)
                }
                .padding()
            }
        }
        .background(Theme.page)
    }

    @ViewBuilder private var doneView: some View {
        let missed = cards.count - correct
        VStack(spacing: 14) {
            Text("Review complete").font(.serif(26, .bold, relativeTo: .title)).foregroundStyle(Theme.ink)
            Text("\(correct) / \(cards.count) correct").font(.ui(28, .bold)).monospacedDigit().foregroundStyle(Theme.ink)
            Text(missed == 0
                 ? "Spotless. Every card cleared; they'll come back on a longer schedule."
                 : "\(missed) card\(missed == 1 ? "" : "s") reset to the start. You'll see \(missed == 1 ? "it" : "them") again soon.")
                .font(.serif(17)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Done") {
                phase = .idle
                Task { await load() }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.page)
    }

    private func finish() {
        Task {
            if let res: BadgesResponse = try? await APIClient.shared.post("/review/finish", body: [String: String]()) {
                Celebrations.shared.celebrate(res.badges)
            }
        }
        phase = .done
    }

    private func load() async {
        guard auth.isSignedIn else { loading = false; return }
        loading = true
        do {
            deck = try await APIClient.shared.get("/review/deck")
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
