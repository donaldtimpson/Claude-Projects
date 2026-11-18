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
    }

    /// What's in today's deck, course by course: how many cards, from how many lectures.
    @ViewBuilder private var deckContents: some View {
        let groups = Dictionary(grouping: cards) { courseName(fromSource: $0.source) }
            .map { (course: $0.key, cards: $0.value) }
            .sorted { $0.cards.count > $1.cards.count }
        SectionTitle("In Today's Deck")
        Codex {
            ForEach(groups, id: \.course) { g in
                let lectures = Set(g.cards.map(\.source)).count
                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(g.course).font(.serif(17, .semibold)).foregroundStyle(Theme.ink)
                        Spacer(minLength: 8)
                        Text("\(g.cards.count)").font(.ui(16, .semibold)).monospacedDigit().foregroundStyle(Theme.ink)
                    }
                    GiltBar(fraction: Double(g.cards.count) / Double(max(1, cards.count)), height: 5)
                    Text("From \(lectures) lecture\(lectures == 1 ? "" : "s")").font(.ui(12.5)).foregroundStyle(Theme.inkSoft)
                }
                .codexRow()
            }
        }
        if (deck?.dueCount ?? 0) > cards.count {
            Text("Today's session takes the first \(cards.count). The rest come round next time.")
                .font(.ui(12.5)).foregroundStyle(Theme.inkSoft).padding(.horizontal, 4)
        }
    }

    private var deckArt: some View {
        ZStack {
            ForEach(0..<3) { i in
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color(hex: 0xfbf5e6))
                    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).inset(by: 4)
                        .strokeBorder(Color(hex: 0xb8860b).opacity(0.55), lineWidth: 0.75))
                    .overlay {
                        if i == 2 {
                            Text("?").font(.display(30)).foregroundStyle(Color(hex: 0x8a1f1f))
                        }
                    }
                    .frame(width: 64, height: 86)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .rotationEffect(.degrees([-11, 5, -2][i]))
                    .offset(x: [-14, 12, 0][i], y: [4, 2, -2][i])
            }
        }
        .frame(width: 100, height: 104)
        .accessibilityHidden(true)
    }

    private var cards: [DueCard] { deck?.cards ?? [] }

    @ViewBuilder private var idleView: some View {
        let due = deck?.dueCount ?? 0
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Masthead(overlap: 40) {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            GiltEyebrow("Daily Review")
                            if loading && deck == nil {
                                ProgressView().tint(Theme.onLeather).padding(.vertical, 22)
                            } else if due > 0 {
                                Text("\(due)")
                                    .font(.ui(58, .bold)).monospacedDigit()
                                    .foregroundStyle(Theme.gilt)
                                    .contentTransition(.numericText())
                                Text("card\(due == 1 ? "" : "s") due today")
                                    .font(.serif(19, .semibold)).foregroundStyle(Theme.onLeather)
                            } else {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 44)).foregroundStyle(Theme.gilt)
                                    .padding(.vertical, 6)
                                Text("All caught up")
                                    .font(.serif(22, .semibold)).foregroundStyle(Theme.onLeather)
                            }
                        }
                        Spacer(minLength: 0)
                        deckArt
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    if error != nil && deck == nil {
                        LoadFailedView(title: "Couldn't load your review") { await load() }
                    } else if !(loading && deck == nil) {
                        VStack(alignment: .leading, spacing: 12) {
                            if due > 0 {
                                Text("Questions you've missed come back just before you'd forget them. Get one right and it waits longer; miss it and it starts over.")
                                    .font(.serif(16.5)).foregroundStyle(Theme.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                                PrimaryButton(title: "Start review") {
                                    index = 0; correct = 0; phase = .running
                                }
                            } else {
                                Text("No cards are due right now. Take a lecture quiz, and anything you miss will join your deck.")
                                    .font(.serif(16.5)).foregroundStyle(Theme.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lyceumCard(padding: 18)
                        .shadow(color: Color(hex: 0x2a0a0a).opacity(0.14), radius: 14, y: 6)
                        .padding(.top, -40)

                        if !cards.isEmpty { deckContents }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .background(Theme.page)
        .mastheadChrome("Daily Review", crest: true)
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
        // A session: its own way out, and the tabs out of the way.
        .leatherBar("Daily Review", leading: ChromeAction(systemImage: "xmark", label: "End review") {
            phase = .idle
            Task { await load() }
        })
        .toolbar(.hidden, for: .tabBar)
    }

    @ViewBuilder private var doneView: some View {
        let missed = cards.count - correct
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "laurel.leading")
                VStack(spacing: 0) {
                    Text("\(correct)").font(.ui(54, .bold)).monospacedDigit()
                    Text("of \(cards.count)").font(.ui(15, .semibold)).foregroundStyle(Theme.inkSoft)
                }
                Image(systemName: "laurel.trailing")
            }
            .font(.system(size: 56, weight: .light))
            .foregroundStyle(Theme.gilt)
            .symbolEffect(.bounce, value: phase == .done)
            Text("Review complete").font(.serif(26, .bold, relativeTo: .title)).foregroundStyle(Theme.ink)
            Text(missed == 0
                 ? "Spotless. Every card cleared; they'll come back on a longer schedule."
                 : "\(missed) card\(missed == 1 ? "" : "s") reset to the start. You'll see \(missed == 1 ? "it" : "them") again soon.")
                .font(.serif(17)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Done") {
                phase = .idle
                Task { await load() }
            }
            .padding(.top, 6)
        }
        .padding(28)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.page)
        .leatherBar("Daily Review", backButton: false)
        .sensoryFeedback(.success, trigger: phase == .done)
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
