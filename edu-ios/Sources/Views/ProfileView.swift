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
        .navigationTitle(auth.isSignedIn ? "My Progress" : "Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: SettingsRoute()) { Image(systemName: "gearshape") }
                    .accessibilityLabel("Settings")
            }
        }
    }

    private var earned: [Badge] { badges.filter { $0.unlocked && $0.tier != "omniscient" } }

    /// The public name: the chosen handle, or the server's placeholder until one is picked.
    private var publicHandle: String {
        auth.user?.handle ?? me?.handlePlaceholder ?? "Scholar"
    }

    @ViewBuilder private var signedIn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                if failed && me == nil {
                    LoadFailedView(title: "Couldn't load your progress") { await load() }
                } else {
                    streakCard

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
                            ForEach(p.inProgress) { courseRow($0, done: false) }
                        }
                        if !p.completed.isEmpty {
                            SectionTitle("Completed")
                            ForEach(p.completed) { courseRow($0, done: true) }
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
                    NavigationLink(value: LeaderboardRoute()) {
                        LinkRow(icon: "trophy", title: "See where you stand",
                                subtitle: "You appear as @\(publicHandle)")
                    }
                    .buttonStyle(.lyceumPress)
                }
            }
            .padding()
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(auth.user?.name ?? "Scholar").font(.serif(26, .bold, relativeTo: .title)).foregroundStyle(Theme.ink)
            // The handle is the only name shown in the Hall, so it's editable here.
            Button { showHandleEditor = true } label: {
                HStack(spacing: 6) {
                    Text("@\(publicHandle)").font(.ui(15, .medium)).foregroundStyle(Theme.inkSoft)
                    Image(systemName: "pencil").font(.ui(13, .semibold)).foregroundStyle(Theme.link)
                    if auth.user?.handle == nil && me?.handlePlaceholder != nil {
                        Text("Assigned. Tap to choose your own.").font(.ui(12)).foregroundStyle(Theme.link)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit your public handle, @\(publicHandle)")
        }
    }

    private var streakCard: some View {
        let streak = me?.streak.count ?? 0
        let due = me?.dueCount ?? 0
        return VStack(alignment: .leading, spacing: 10) {
            Text(streak > 0 ? "🔥 \(streak)-day streak" : "Start your streak today")
                .font(.serif(21, .bold)).foregroundStyle(Theme.ink)
            Text(due > 0
                 ? "\(due) card\(due == 1 ? "" : "s") due for review."
                 : streak > 0 && me?.streak.activeToday == true
                    ? "All caught up. See you tomorrow."
                    : "Study anything today (a lecture, a quiz, a review, a drill) to keep it going.")
                .font(.serif(16)).foregroundStyle(Theme.inkSoft)
            HStack(spacing: 10) {
                Button { router.tab = .review } label: {
                    ButtonLabel(title: due > 0 ? "Start daily review" : "Open review", primary: true)
                }
                Button { router.tab = .drills } label: {
                    ButtonLabel(title: "Practice drills", primary: false)
                }
            }
            .padding(.top, 2)
        }
        .lyceumCard()
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ornament.opacity(0.7), lineWidth: 1.5))
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
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(c.title).font(.serif(17, .semibold)).foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading).lineLimit(2)
                    Spacer(minLength: 8)
                    Text(done ? "Complete ✓" : "\(c.watchedCount) / \(c.totalCount)")
                        .font(.ui(13, .medium)).monospacedDigit()
                        .foregroundStyle(done ? Theme.success : Theme.inkSoft)
                }
                ProgressView(value: c.fraction).tint(done ? Theme.successLine : Theme.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .lyceumCard()
        }
        .buttonStyle(.lyceumPress)
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

/// An enrolled class on My Progress: course, section, the current grade, and each
/// category that counts, opening the full class page.
struct ClassCard: View {
    let grade: ClassGrade
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(grade.courseTitle).font(.serif(17, .semibold)).foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading).lineLimit(2)
                    Text(grade.sectionName).font(.ui(13)).foregroundStyle(Theme.inkSoft)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(ProfileView.pct(grade.currentGrade))
                        .font(.ui(28, .bold)).monospacedDigit()
                        .foregroundStyle(Theme.grade(grade.currentGrade))
                    Text("current grade").font(.ui(12)).foregroundStyle(Theme.inkSoft)
                }
            }
            FlowLayout(spacing: 6) {
                ForEach(grade.breakdown, id: \.label) { row in
                    HStack(spacing: 4) {
                        Text(row.label).foregroundStyle(Theme.inkSoft)
                        Text(ProfileView.pct(row.pct)).fontWeight(.semibold).foregroundStyle(Theme.grade(row.pct))
                    }
                    .font(.ui(13))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.tint)
                    .clipShape(Capsule())
                }
            }
            HStack(spacing: 4) {
                Text("Grade, homework & quizzes").font(.ui(14, .semibold)).foregroundStyle(Theme.link)
                Image(systemName: "chevron.right").font(.ui(12, .semibold)).foregroundStyle(Theme.link)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lyceumCard()
    }
}
