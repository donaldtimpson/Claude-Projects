import SwiftUI

struct ReviewView: View {
    @EnvironmentObject private var queue: WriteQueueManager

    @State private var deck: ReviewDeckResponse?
    @State private var error: String?
    @State private var loading = true
    @State private var phase = Phase.idle
    @State private var index = 0
    @State private var correct = 0

    enum Phase { case idle, running, done }

    var body: some View {
        Group {
            switch phase {
            case .idle: idleView
            case .running: runningView
            case .done: doneView
            }
        }
        .navigationTitle("Daily Review")
    }

    private var cards: [DueCard] { deck?.cards ?? [] }

    @ViewBuilder private var idleView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if loading {
                    ProgressView()
                } else if let error {
                    ContentUnavailableView("Couldn't load", systemImage: "wifi.slash", description: Text(error))
                } else {
                    VStack(spacing: 12) {
                        let due = deck?.dueCount ?? 0
                        Text(due > 0 ? "\(due) card\(due == 1 ? "" : "s") due today across your courses."
                             : "You're all caught up — no cards due right now.")
                            .foregroundStyle(Theme.ink)
                        PrimaryButton(title: "Start review", enabled: !cards.isEmpty) {
                            index = 0; correct = 0; phase = .running
                        }
                    }
                    .lyceumCard()
                }
            }
            .padding()
        }
        .background(Theme.parchment)
        .task { if deck == nil { await load() } }
    }

    @ViewBuilder private var runningView: some View {
        ScrollView {
            if index < cards.count {
                let card = cards[index]
                MCQCard(
                    prompt: card.prompt, options: card.options, correctIndex: card.correctIndex,
                    explanation: card.explanation,
                    progress: "Card \(index + 1) of \(cards.count) · \(card.source)"
                ) { _, wasCorrect in
                    if wasCorrect { correct += 1 }
                    let card = card
                    Task {
                        _ = await queue.submit(
                            path: "/review/grade",
                            body: ReviewGradeBody(questionId: card.id, correct: wasCorrect, clientId: makeClientId()),
                            clientId: makeClientId()
                        )
                    }
                    if index + 1 < cards.count { index += 1 } else { finish() }
                }
                .id(card.id)
                .padding()
            }
        }
        .background(Theme.parchment)
    }

    @ViewBuilder private var doneView: some View {
        VStack(spacing: 16) {
            Text("Session complete").font(.title.weight(.bold)).foregroundStyle(Theme.crimson)
            Text("\(correct) of \(cards.count) correct").foregroundStyle(Theme.ink)
            PrimaryButton(title: "Done") {
                phase = .idle
                Task { await load() }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.parchment)
    }

    private func finish() {
        Task {
            struct BadgesResult: Codable { let badges: [Badge] }
            let _: BadgesResult? = try? await APIClient.shared.post("/review/finish", body: [String: String]())
        }
        phase = .done
    }

    private func load() async {
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
