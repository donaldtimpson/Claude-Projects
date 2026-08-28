import SwiftUI

// The Hall of Scholars — the app's half of the web /leaderboard. The app already
// referenced this in three places (the handle editor, the delete-account warning)
// while having no screen to show, so a student was told to pick a public name for a
// board they couldn't visit. Same three sections as the web page, same ranking, from
// the same getLeaderboard() the site uses.
struct ScholarsView: View {
    @EnvironmentObject private var auth: AuthViewModel

    @State private var entries: [ScholarEntry] = []
    @State private var scoring: ScoringRules?
    @State private var loading = true
    @State private var error: String?

    private var myIndex: Int? {
        guard let id = auth.user?.id else { return nil }
        return entries.firstIndex { $0.scholar.userId == id }
    }

    var body: some View {
        ScrollView {
            if loading {
                ProgressView().tint(Theme.gold300).padding(.top, 60)
            } else if let error {
                ContentUnavailableView("Couldn't load", systemImage: "wifi.slash", description: Text(error))
                    .padding(.top, 40)
            } else {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Every scholar is ranked by their standing — shown only by their chosen handle.")
                        .font(.serif(15)).foregroundStyle(Theme.inkSoft)

                    standingSection
                    boardSection
                    scoringSection
                }
                .padding()
            }
        }
        .background(Theme.parchment)
        .navigationTitle("Hall of Scholars")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    // MARK: your standing

    @ViewBuilder private var standingSection: some View {
        header("YOUR STANDING")
        if let i = myIndex {
            row(entries[i], rank: i + 1, isMe: true)
            Text("Ranked \(i + 1) of \(entries.count).")
                .font(.caption).foregroundStyle(Theme.inkSoft)
        } else if auth.isSignedIn {
            Text("You're not on the board yet. Watch a lecture or take a quiz and you'll claim your place in the Hall.")
                .font(.serif(15)).foregroundStyle(Theme.inkSoft)
                .lyceumCard()
        } else {
            // Signed out this is the one thing on screen that needs an account, so it
            // says what it buys rather than blocking the board itself — the ranking is
            // public and stays readable.
            SignInPrompt(
                message: "Sign in to earn a place in the Hall of Scholars.",
                reason: "Claim your place in the Hall of Scholars.",
                actionTitle: "Sign in")
                .lyceumCard()
        }
    }

    // MARK: the board

    @ViewBuilder private var boardSection: some View {
        header("THE BOARD")
        ForEach(Array(entries.enumerated()), id: \.element.id) { i, entry in
            row(entry, rank: i + 1, isMe: i == myIndex)
        }
    }

    private func row(_ entry: ScholarEntry, rank: Int, isMe: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(Self.medal(rank).isEmpty ? "\(rank)" : Self.medal(rank))
                .font(.display(15))
                .foregroundStyle(Self.rankColor(rank))
                .frame(width: 34, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.scholar.handle)
                        .font(.display(15)).foregroundStyle(isMe ? Theme.gold300 : Theme.ink)
                    if isMe {
                        Text("YOU").font(.caption2.weight(.bold))
                            .foregroundStyle(Theme.onAccent)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Theme.accent, in: Capsule())
                    }
                    if entry.isHouse {
                        Text("HOUSE").font(.caption2)
                            .foregroundStyle(Theme.inkSoft)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                    }
                }
                Text("\(entry.scholar.lectures) lectures · \(entry.scholar.quizPts) quiz · \(entry.scholar.badgePts) badges")
                    .font(.caption).foregroundStyle(Theme.inkSoft)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 1) {
                Text(Self.fmt(entry.scholar.standing))
                    .font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.gold400)
                Text("standing").font(.caption2).foregroundStyle(Theme.inkSoft)
            }
        }
        .lyceumCard()
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isMe ? Theme.gold500 : .clear, lineWidth: 1.5))
    }

    // MARK: how standing is earned

    @ViewBuilder private var scoringSection: some View {
        header("HOW STANDING IS EARNED")
        VStack(alignment: .leading, spacing: 8) {
            // Values come from the server with the board, so this can't contradict the
            // totals directly above it.
            let s = scoring
            rule("+\(s?.lecture ?? 10)", "for every lecture you watch")
            rule("+\(s?.quizPerCorrect ?? 1)", "per correct quiz answer — your best attempt counts, so retrying only helps")
            rule("+\(s?.testPerCorrect ?? 2)", "per correct answer on a course test (best attempt)")
            rule("+\(s?.completion ?? 250)", "for finishing a course — every lecture watched, quizzes passed, test passed")
            rule("+\(s?.badgeMin ?? 25)–\(s?.badgeMax ?? 500)", "for each achievement, by tier (Bronze → Platinum)")
            Text("Because quizzes count your best attempt, there's nothing to gain from looking up answers — the standing rewards mastering the material, not guessing quickly.")
                .font(.caption).foregroundStyle(Theme.inkSoft)
                .padding(.top, 4)
        }
        .lyceumCard()
    }

    private func rule(_ points: String, _ label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(points).font(.display(13)).foregroundStyle(Theme.gold400)
                .frame(width: 76, alignment: .leading)
            Text(label).font(.serif(14)).foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 0)
        }
    }

    private func header(_ t: String) -> some View {
        Text(t).font(.display(11)).kerning(2).foregroundStyle(Theme.gold400)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    // MARK: data

    private func load() async {
        // The board is public — no account needed to read it, same as the website.
        do {
            let res: LeaderboardResponse = try await APIClient.shared.get("/leaderboard", auth: false)
            entries = res.scholars
            scoring = res.scoring
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    private static func medal(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }

    private static func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Theme.gold300
        case 2: return Theme.ink
        case 3: return Theme.gold500
        default: return Theme.inkSoft
        }
    }

    private static func fmt(_ n: Int) -> String {
        n.formatted(.number.grouping(.automatic))
    }
}
