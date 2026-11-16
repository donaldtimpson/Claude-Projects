import SwiftUI

// The Hall of Scholars: the web /leaderboard. Your standing (the four-part
// standing card), the board with metal rank discs, and how standing is earned.
// Every row opens that scholar's profile, as on the web.
struct ScholarsView: View {
    @EnvironmentObject private var auth: AuthViewModel

    @State private var entries: [ScholarEntry] = []
    @State private var scoring: ScoringRules?
    @State private var loading = true
    @State private var failed = false

    private var myIndex: Int? {
        guard let id = auth.user?.id else { return nil }
        return entries.firstIndex { $0.scholar.userId == id }
    }

    var body: some View {
        Group {
            if loading && entries.isEmpty {
                LoadingLeather()
            } else if failed && entries.isEmpty {
                LoadFailedView(title: "Couldn't load the Hall") { await load() }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Masthead(overlap: 0) { podium }
                        VStack(alignment: .leading, spacing: 12) {
                            standingSection
                            if entries.count > 3 {
                                SectionTitle("The Hall")
                                Codex(dividerInset: 56) {
                                    ForEach(Array(entries.enumerated().dropFirst(3)), id: \.element.id) { i, entry in
                                        NavigationLink(value: ScholarRoute(handle: entry.scholar.handle)) {
                                            ScholarRow(entry: entry, rank: i + 1, isMe: i == myIndex)
                                        }
                                        .buttonStyle(.lyceumRow)
                                    }
                                }
                            }
                            if entries.contains(where: \.isHouse) {
                                (Text(Image(systemName: "building.columns")) + Text("  House scholars are great minds of the past who set the pace. They aren't real students."))
                                    .font(.ui(12.5)).foregroundStyle(Theme.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal, 4)
                            }
                            scoringSection
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
                .refreshable { await load() }
            }
        }
        .background(Theme.page)
        .mastheadChrome("Hall of Scholars", threshold: 140)
        .task { await load() }
    }

    /// The top three on a podium, first place raised in the middle.
    private var podium: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                GiltEyebrow("Hall of Scholars")
                Text("Ranked by standing, shown only by chosen handle.")
                    .font(.serif(15).italic()).foregroundStyle(Theme.onLeatherSoft)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach([1, 0, 2], id: \.self) { i in
                    if i < entries.count {
                        NavigationLink(value: ScholarRoute(handle: entries[i].scholar.handle)) {
                            podiumPlace(entries[i], rank: i + 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func podiumPlace(_ entry: ScholarEntry, rank: Int) -> some View {
        let height: CGFloat = rank == 1 ? 74 : rank == 2 ? 52 : 38
        return VStack(spacing: 6) {
            RankMedal(rank: rank, size: rank == 1 ? 50 : 42)
            Text(entry.scholar.handle).font(.serif(14.5, .semibold)).foregroundStyle(Theme.onLeather)
                .lineLimit(1).minimumScaleFactor(0.75)
            Text(entry.scholar.standing.formatted()).font(.ui(13, .semibold)).monospacedDigit()
                .foregroundStyle(Theme.giltText)
            // The step itself.
            UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8)
                .fill(LinearGradient(colors: [.white.opacity(0.16), .white.opacity(0.04)], startPoint: .top, endPoint: .bottom))
                .overlay(alignment: .top) { Rectangle().fill(Theme.giltBar).frame(height: 1).opacity(0.7) }
                .frame(height: height)
                .overlay(Text("\(rank)").font(.display(20)).foregroundStyle(Theme.onLeather.opacity(0.35)))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rank \(rank), \(entry.scholar.handle), \(entry.scholar.standing) standing")
    }

    @ViewBuilder private var standingSection: some View {
        SectionTitle("Your Standing")
        if let i = myIndex {
            StandingCard(scholar: entries[i].scholar, rank: i + 1, total: entries.count, highlighted: true)
        } else if auth.isSignedIn {
            EmptyNote("You're not on the board yet. Watch a lecture or take a quiz and you'll claim your place in the Hall.")
        } else {
            // The ranking is public; only claiming a place needs an account.
            SignInPrompt(
                message: "Sign in to earn a place in the Hall of Scholars.",
                reason: "Claim your place in the Hall of Scholars.",
                actionTitle: "Sign in")
                .frame(maxWidth: .infinity)
                .lyceumCard()
        }
    }



    @ViewBuilder private var scoringSection: some View {
        SectionTitle("How Standing Is Earned")
        VStack(alignment: .leading, spacing: 10) {
            // Values come from the server with the board, so they match the totals.
            let s = scoring
            rule("+\(s?.lecture ?? 10)", "for every lecture you watch")
            rule("+\(s?.quizPerCorrect ?? 1)", "per correct quiz answer (your best attempt counts, so retrying only helps)")
            rule("+\(s?.testPerCorrect ?? 2)", "per correct answer on a course test (best attempt)")
            rule("+\(s?.completion ?? 250)", "for finishing a course: every lecture watched, quizzes and test passed")
            rule("+\(s?.badgeMin ?? 25)–\(s?.badgeMax ?? 500)", "for each achievement, by tier (Bronze to Platinum)")
            Text("Because quizzes count your best attempt, there's nothing to gain from looking up answers. Standing rewards mastering the material.")
                .font(.serif(15)).foregroundStyle(Theme.inkSoft)
                .padding(.top, 2)
        }
        .lyceumCard()
    }

    private func rule(_ points: String, _ label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(points).font(.ui(15, .bold)).monospacedDigit().foregroundStyle(Theme.ink)
                .frame(width: 78, alignment: .leading)
            Text(label).font(.serif(16)).foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 0)
        }
    }

    private func load() async {
        do {
            let res: LeaderboardResponse = try await APIClient.shared.get("/leaderboard", auth: false)
            entries = res.scholars
            scoring = res.scoring
            failed = false
        } catch {
            failed = true
        }
        loading = false
    }
}

/// One scholar on the board: rank disc, handle, standing.
struct ScholarRow: View {
    let entry: ScholarEntry
    let rank: Int
    let isMe: Bool
    var body: some View {
        HStack(spacing: 12) {
            RankDisc(rank: rank)
            HStack(spacing: 6) {
                Text(entry.scholar.handle).font(.serif(17, isMe ? .bold : .medium)).foregroundStyle(Theme.ink)
                    .lineLimit(1)
                if isMe { Pill("You", tone: .accent) }
                if entry.isHouse {
                    Image(systemName: "building.columns").font(.ui(12)).foregroundStyle(Theme.inkSoft)
                        .accessibilityLabel("House scholar")
                }
            }
            Spacer(minLength: 8)
            Text(entry.scholar.standing.formatted())
                .font(.ui(16, .semibold)).monospacedDigit()
                .foregroundStyle(entry.scholar.standing > 0 ? Theme.ink : Theme.inkSoft)
            Image(systemName: "chevron.right").font(.ui(12, .semibold)).foregroundStyle(Theme.inkSoft.opacity(0.6))
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(isMe ? Theme.accentText.opacity(0.07) : .clear)
    }
}

/// A struck medal for the podium: metal face, darker rim, the rank in Cinzel.
struct RankMedal: View {
    let rank: Int
    var size: CGFloat = 44
    var body: some View {
        let (light, dark): (UInt, UInt) = switch rank {
        case 1: (0xf6e39c, 0xa8801f)
        case 2: (0xf1f2f4, 0x8e9196)
        default: (0xf0c08e, 0x8c5528)
        }
        ZStack {
            Circle().fill(LinearGradient(colors: [Color(hex: light), Color(hex: dark)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().inset(by: size * 0.1)
                .strokeBorder(LinearGradient(colors: [Color(hex: dark), Color(hex: light)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.2)
            Text("\(rank)").font(.display(size * 0.38)).foregroundStyle(Color(hex: 0x3a2508).opacity(0.85))
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
        .accessibilityHidden(true)
    }
}

/// Gold, silver and bronze discs for the top three (same metals in both themes);
/// a plain numeral for everyone else.
struct RankDisc: View {
    let rank: Int
    var body: some View {
        if let metal {
            Text("\(rank)")
                .font(.ui(14, .bold))
                .foregroundStyle(Color(hex: 0x2a1a08))
                .frame(width: 30, height: 30)
                .background(Circle().fill(metal))
                .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 1))
                .accessibilityLabel("Rank \(rank)")
        } else {
            Text("\(rank)")
                .font(.ui(15, .medium)).monospacedDigit()
                .foregroundStyle(Theme.inkSoft)
                .frame(width: 30)
                .accessibilityLabel("Rank \(rank)")
        }
    }
    private var metal: Color? {
        switch rank {
        case 1: Color(hex: 0xd4a72c)
        case 2: Color(hex: 0xb5b7bb)
        case 3: Color(hex: 0xb9773f)
        default: nil
        }
    }
}

/// A scholar's standing: total, rank, and a bar split into where it came from
/// (lectures, quizzes, completion, badges), with the same four colors as the web.
struct StandingCard: View {
    let scholar: Scholar
    let rank: Int
    let total: Int
    var highlighted: Bool = false
    /// Off on a profile, whose page title is already the handle.
    var showHandle: Bool = true

    private var segments: [(String, Int, Color)] {
        [
            // The app's own metals and inks: crimson, gold, bronze, slate.
            ("Lectures", scholar.lectures, Color(light: 0x9a2828, dark: 0xc4554e)),
            ("Quizzes", scholar.quizPts, Color(light: 0xc9962a, dark: 0xd9ad45)),
            ("Completion", scholar.completions, Color(light: 0x8c5528, dark: 0xb97b48)),
            ("Badges", scholar.badgePts, Color(light: 0x5a4f46, dark: 0xa8977e)),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    if showHandle {
                        Text(scholar.handle).font(.serif(20, .bold)).foregroundStyle(Theme.ink)
                    }
                    Text("Rank #\(rank) of \(total)").font(.ui(showHandle ? 13 : 15, showHandle ? .regular : .semibold))
                        .foregroundStyle(showHandle ? Theme.inkSoft : Theme.ink)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(scholar.standing.formatted()).font(.ui(26, .bold)).monospacedDigit().foregroundStyle(Theme.ink)
                    Eyebrow("Standing")
                }
            }
            GeometryReader { geo in
                let sum = max(1, segments.map(\.1).reduce(0, +))
                HStack(spacing: 2) {
                    ForEach(segments.indices, id: \.self) { i in
                        let v = segments[i].1
                        if v > 0 {
                            Rectangle().fill(segments[i].2)
                                .frame(width: max(3, geo.size.width * CGFloat(v) / CGFloat(sum)))
                        }
                    }
                }
                .frame(width: geo.size.width, alignment: .leading)
                .background(Theme.tint)
                .clipShape(Capsule())
            }
            .frame(height: 10)
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], spacing: 6) {
                ForEach(segments.indices, id: \.self) { i in
                    HStack(spacing: 6) {
                        Circle().fill(segments[i].2).frame(width: 9, height: 9)
                        Text(segments[i].0).font(.ui(13)).foregroundStyle(Theme.inkSoft)
                        Text(segments[i].1.formatted()).font(.ui(13, .semibold)).monospacedDigit().foregroundStyle(Theme.ink)
                    }
                }
            }
        }
        .lyceumCard()
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(highlighted ? Theme.ornament : .clear, lineWidth: 1.5))
    }
}

// MARK: - Scholar profile

private struct ScholarProfileEntry: Codable {
    let scholar: Scholar
    var badges: [Badge]? = nil
    var house: Bool? = nil
    var note: String? = nil
    let rank: Int
    let total: Int
}

private struct ScholarProfileResponse: Codable {
    let scholar: ScholarProfileEntry
}

/// One scholar's page: the web /leaderboard/[handle].
struct ScholarProfileView: View {
    let handle: String
    @EnvironmentObject private var auth: AuthViewModel
    @State private var entry: ScholarProfileEntry?
    @State private var failed = false

    var body: some View {
        Group {
            if let entry {
                let isMe = entry.scholar.userId != nil && entry.scholar.userId == auth.user?.id
                let isHouse = entry.house ?? entry.scholar.house ?? false
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                    Masthead(overlap: 0) {
                        HStack(spacing: 14) {
                            if entry.rank <= 3 {
                                RankMedal(rank: entry.rank, size: 56)
                            } else {
                                Text(String(entry.scholar.handle.prefix(1)))
                                    .font(.display(26)).foregroundStyle(Theme.onLeather)
                                    .frame(width: 56, height: 56)
                                    .background(Circle().fill(.white.opacity(0.1)))
                                    .overlay(Circle().strokeBorder(Theme.gilt, lineWidth: 1.2))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                GiltEyebrow(isMe ? "That's you" : "Scholar")
                                Text(entry.scholar.handle).font(.serif(26, .bold, relativeTo: .title))
                                    .foregroundStyle(Theme.onLeather).lineLimit(1).minimumScaleFactor(0.7)
                                Text("Rank #\(entry.rank) of \(entry.total) in the Hall").font(.ui(14))
                                    .foregroundStyle(Theme.onLeatherSoft)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        if isHouse {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("✦ House Scholar, not a real student").font(.ui(14, .semibold)).foregroundStyle(Theme.accentText)
                                if let note = entry.note ?? entry.scholar.note {
                                    Text(note).font(.serif(15)).foregroundStyle(Theme.inkSoft)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lyceumCard()
                        }
                        SectionTitle("Standing")
                        StandingCard(scholar: entry.scholar, rank: entry.rank, total: entry.total,
                                     highlighted: isMe || isHouse, showHandle: false)
                        if let badges = entry.badges, !badges.isEmpty {
                            SectionTitle("Achievements")
                            let earned = badges.filter { $0.unlocked && $0.tier != "omniscient" }
                            Codex {
                                NavigationLink {
                                    AchievementsView(badges: badges)
                                } label: {
                                    LinkRow(icon: "rosette", iconColor: Theme.ornament,
                                            title: "\(earned.count) of \(badges.filter { $0.tier != "omniscient" }.count) earned",
                                            subtitle: "See every achievement")
                                }
                                .buttonStyle(.lyceumRow)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                    }
                }
            } else if failed {
                LoadFailedView(title: "Couldn't load this scholar") { await load() }
            } else {
                LoadingLeather()
            }
        }
        .background(Theme.page)
        .mastheadChrome(handle)
        .task { await load() }
    }

    private func load() async {
        let encoded = handle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? handle
        do {
            let res: ScholarProfileResponse = try await APIClient.shared.get("/scholars/\(encoded)", auth: false)
            entry = res.scholar
            failed = false
        } catch {
            failed = true
        }
    }
}
