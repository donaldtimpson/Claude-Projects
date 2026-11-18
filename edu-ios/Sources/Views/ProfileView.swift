import SwiftUI

// My Progress: the web /dashboard. Streak and review, your classes, courses in
// progress and completed, achievements, and your place in the Hall. Signed out
// this tab is the sign-in form. Settings (appearance, privacy, support, account)
// sit behind the gear in both states.
struct ProfileView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var router: Router
    @State private var me: MeResponse?
    @State private var badges: [Badge] = []
    @State private var progress: ProgressResponse?
    @State private var failed = false
    @State private var showHandleEditor = false

    var body: some View {
        Group {
            if auth.isSignedIn {
                signedIn
            } else {
                AuthView(reason: "Keep your progress, quiz scores, streak, and badges across your devices.")
                    .background(Theme.page)
            }
        }
        .mastheadChrome(auth.isSignedIn ? "My Progress" : "Account", actions: [
            // A Button onto the stack path: a value NavigationLink in a toolbar
            // doesn't reliably resolve against the stack's destinations.
            ChromeAction(systemImage: "gearshape", label: "Settings", identifier: "settingsButton") {
                router.progress.append(SettingsRoute())
            },
        ], crest: true)
    }

    private var earned: [Badge] { badges.filter { $0.unlocked && $0.tier != "omniscient" } }

    /// The public name: the chosen handle, or the server's placeholder until one is picked.
    private var publicHandle: String {
        auth.user?.handle ?? me?.handlePlaceholder ?? "Scholar"
    }

    @ViewBuilder private var signedIn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Masthead(overlap: 40) { header }
                VStack(alignment: .leading, spacing: 12) {
                    if failed && me == nil {
                        LoadFailedView(title: "Couldn't load your progress") { await load() }
                    } else {
                        todayCard.padding(.top, -40)

                        if let p = progress, !p.classes.isEmpty {
                            SectionTitle("My Classes")
                            ForEach(p.classes) { c in
                                NavigationLink(value: ClassRoute(sectionId: c.sectionId, sectionName: c.sectionName, courseTitle: c.courseTitle)) {
                                    ClassCard(grade: c)
                                }
                                .buttonStyle(.lyceumPress)
                            }
                        }

                        if let p = progress {
                            SectionTitle("In Progress")
                            if p.inProgress.isEmpty {
                                EmptyNote("No courses in progress yet. Watch a lecture to start one.")
                            } else {
                                Codex(dividerInset: 86) { ForEach(p.inProgress) { courseRow($0, done: false) } }
                            }
                            if !p.completed.isEmpty {
                                SectionTitle("Completed")
                                Codex(dividerInset: 86) { ForEach(p.completed) { courseRow($0, done: true) } }
                            }
                        }

                        SectionTitle("Your Achievements") {
                            if !badges.isEmpty {
                                NavigationLink { AchievementsView(badges: badges) } label: {
                                    Text("See all").font(.ui(14, .semibold)).foregroundStyle(Theme.link)
                                }
                            }
                        }
                        achievementsStrip

                        SectionTitle("Hall of Scholars")
                        Codex {
                            NavigationLink(value: LeaderboardRoute()) {
                                LinkRow(icon: "trophy.fill", title: "See where you stand",
                                        subtitle: "You appear as @\(publicHandle)")
                            }
                            .buttonStyle(.lyceumRow)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .background(Theme.page)
        .refreshable { await load() }
        .sheet(isPresented: $showHandleEditor) {
            HandleEditorSheet(current: auth.user?.handle, assigned: me?.handlePlaceholder) { updated in
                auth.user = updated
            }
        }
        .task { await load() }
    }

    /// The masthead: who you are, then three gilt figures: streak, cards due, badges.
    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                GiltEyebrow("My Progress")
                Text(auth.user?.name ?? "Scholar")
                    .font(.serif(30, .bold, relativeTo: .largeTitle)).foregroundStyle(Theme.onLeather)
                // The handle is the only name shown in the Hall, so it's editable here.
                Button { showHandleEditor = true } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("@\(publicHandle)").font(.ui(15, .medium)).foregroundStyle(Theme.onLeatherSoft)
                            Image(systemName: "pencil").font(.ui(12, .bold)).foregroundStyle(Theme.giltText)
                        }
                        if auth.user?.handle == nil && me?.handlePlaceholder != nil {
                            Text("Assigned for you. Tap to choose your own.")
                                .font(.ui(13)).foregroundStyle(Theme.giltText)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit your public handle, @\(publicHandle)")
            }

            HStack(spacing: 0) {
                figure(icon: "flame.fill", value: me?.streak.count ?? 0, label: "day streak",
                       bounce: me?.streak.activeToday == true)
                giltDivider
                figure(icon: "square.stack.3d.up.fill", value: me?.dueCount ?? 0, label: "cards due")
                giltDivider
                figure(icon: "rosette", value: earned.count, label: earned.count == 1 ? "badge" : "badges")
            }
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.black.opacity(0.18)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.giltText.opacity(0.28), lineWidth: 0.75))
        }
    }

    private func figure(icon: String, value: Int, label: String, bounce: Bool = false) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.gilt)
                .symbolEffect(.bounce, value: bounce)
            Text("\(value)").font(.ui(24, .bold)).monospacedDigit().foregroundStyle(Theme.onLeather)
                .contentTransition(.numericText())
            Text(label.uppercased()).font(.ui(10.5, .semibold, relativeTo: .caption2)).kerning(0.8)
                .foregroundStyle(Theme.onLeatherSoft)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }

    private var giltDivider: some View {
        Rectangle().fill(Theme.giltText.opacity(0.3)).frame(width: 0.75, height: 44)
    }

    /// Today: what to do next, with the two ways to keep the streak going.
    private var todayCard: some View {
        let streak = me?.streak.count ?? 0
        let due = me?.dueCount ?? 0
        let doneToday = me?.streak.activeToday == true
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow("Today", color: Theme.accentText)
                Spacer()
                if doneToday {
                    Label("Streak kept", systemImage: "checkmark.seal.fill")
                        .font(.ui(12, .semibold)).foregroundStyle(Theme.success)
                }
            }
            Text(due > 0
                 ? "\(due) card\(due == 1 ? "" : "s") waiting for review"
                 : doneToday ? "All caught up. See you tomorrow." : streak > 0 ? "Keep your \(streak)-day streak alive" : "Start a streak today")
                .font(.serif(21, .bold)).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(due > 0
                 ? "Questions you've missed come back just before you'd forget them."
                 : "Study anything today (a lecture, a quiz, a review, a drill) to keep it going.")
                .font(.serif(15.5)).foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                Button { router.tab = .review } label: {
                    ButtonLabel(title: due > 0 ? "Start review" : "Open review", primary: true)
                }
                .buttonStyle(.lyceumPress(cornerRadius: 12))
                Button { router.tab = .drills } label: {
                    ButtonLabel(title: "Practice drills", primary: false)
                }
                .buttonStyle(.lyceumPress(cornerRadius: 12))
            }
            .padding(.top, 2)
        }
        .lyceumCard(padding: 18)
        .shadow(color: Color(hex: 0x2a0a0a).opacity(0.14), radius: 14, y: 6)
    }

    @ViewBuilder private var achievementsStrip: some View {
        if earned.isEmpty {
            EmptyNote("No achievements yet. Take a quiz or run a drill to start earning.")
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(earned.prefix(12)) { badge in
                        VStack(spacing: 6) {
                            BadgeMedallion(badge: badge, size: 60)
                            Text(badge.name).font(.ui(12)).foregroundStyle(Theme.inkSoft)
                                .lineLimit(1).frame(width: 74)
                        }
                    }
                }
                // Room for the medallions' glow on every side.
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
        }
    }

    private func courseRow(_ c: CourseProgressItem, done: Bool) -> some View {
        NavigationLink(value: CourseRoute(courseId: c.id)) {
            HStack(spacing: 12) {
                ZStack {
                    if let url = c.nextLecture?.thumbnailUrl {
                        AsyncImage(url: URL(string: url)) { $0.resizable().aspectRatio(contentMode: .fill) } placeholder: { Theme.tint }
                    } else {
                        LeatherBackground()
                        Image(systemName: done ? "laurel.leading" : "book.closed.fill")
                            .font(.system(size: 20, weight: .medium)).foregroundStyle(Theme.gilt)
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 7) {
                    Text(c.title).font(.serif(16.5, .semibold)).foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading).lineLimit(2)
                    HStack(spacing: 10) {
                        GiltBar(fraction: c.fraction, height: 6)
                        Text(done ? "Complete" : "\(c.watchedCount) of \(c.totalCount)")
                            .font(.ui(12, .medium)).monospacedDigit()
                            .foregroundStyle(done ? Theme.success : Theme.inkSoft)
                            .fixedSize()
                    }
                }
                Image(systemName: "chevron.right").font(.ui(13, .semibold)).foregroundStyle(Theme.inkSoft.opacity(0.6))
            }
            .codexRow()
        }
        .buttonStyle(.lyceumRow)
    }

    private func load() async {
        async let meResult: MeResponse? = try? await APIClient.shared.get("/me")
        async let badgesResult: BadgesResponse? = try? await APIClient.shared.get("/me/badges")
        async let progressResult: ProgressResponse? = try? await APIClient.shared.get("/me/progress")
        let (m, b, p) = await (meResult, badgesResult, progressResult)
        if let m { me = m }
        if let b { badges = b.badges }
        if let p { progress = p }
        failed = m == nil && p == nil
    }

    /// nil reads as "—", not 0: a category with no data yet is pending, not failed.
    static func pct(_ v: Double?) -> String { v.map { "\(Int($0.rounded()))%" } ?? "—" }
    static func gradeColor(_ v: Double?) -> Color { Theme.grade(v) }
}

/// An enrolled class on My Progress: course and section beside the grade ring, then
/// each category that counts, opening the full class page.
struct ClassCard: View {
    let grade: ClassGrade
    private let columns = [GridItem(.flexible(), spacing: 10, alignment: .leading),
                           GridItem(.flexible(), spacing: 10, alignment: .leading),
                           GridItem(.flexible(), spacing: 10, alignment: .leading)]
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(grade.sectionName, color: Theme.accentText)
                    Text(grade.courseTitle).font(.serif(18, .semibold)).foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading).lineLimit(3)
                }
                Spacer(minLength: 8)
                GradeRing(pct: grade.currentGrade, size: 68, lineWidth: 6)
            }
            if !grade.breakdown.isEmpty {
                Rectangle().fill(Theme.line).frame(height: 0.5)
                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    ForEach(grade.breakdown, id: \.label) { row in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(row.label).font(.ui(12)).foregroundStyle(Theme.inkSoft).lineLimit(1)
                            Text(ProfileView.pct(row.pct)).font(.ui(16, .semibold)).monospacedDigit()
                                .foregroundStyle(Theme.grade(row.pct))
                        }
                    }
                }
            }
            HStack(spacing: 4) {
                Text("Grade, homework & quizzes").font(.ui(14, .semibold)).foregroundStyle(Theme.link)
                Image(systemName: "chevron.right").font(.ui(12, .semibold)).foregroundStyle(Theme.link)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lyceumCard(padding: 18)
    }
}
