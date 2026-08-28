import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var me: MeResponse?
    @State private var badges: [Badge] = []
    @State private var progress: ProgressResponse?
    @State private var showDelete = false
    @State private var showHandleEditor = false
    @State private var expandedClass: String?

    var body: some View {
        Group {
            if auth.isSignedIn {
                signedIn
            } else {
                // Signed out, this tab IS the sign-in screen. Nothing else in the app
                // requires an account, so this is where the ask lives.
                AuthView(reason: "Keep your progress, quiz scores, streak, and badges across your devices.")
                    .background(Theme.parchment)
            }
        }
        // "Account" rather than "Sign In": the same screen switches to Create Account,
        // and a title contradicting the form under it reads as a bug.
        .navigationTitle(auth.isSignedIn ? "Profile" : "Account")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var earned: [Badge] { badges.filter { $0.unlocked } }

    /// The name this student actually appears under publicly: their chosen handle, or
    /// the server's assigned placeholder while they haven't picked one.
    private var publicHandle: String {
        auth.user?.handle ?? me?.handlePlaceholder ?? "Scholar"
    }

    @ViewBuilder private var signedIn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(auth.user?.name ?? "Scholar").font(.title.weight(.bold)).foregroundStyle(Theme.crimson)
                // The handle is the only name shown in the Hall of Scholars, so it's
                // editable here just as it is on the web dashboard. A student who never
                // picked one still HAS a public name — the server's auto-assigned
                // placeholder — so show that rather than a blank, and say it's assigned.
                Button { showHandleEditor = true } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text("@\(publicHandle)").foregroundStyle(Theme.inkSoft)
                            Image(systemName: "pencil").font(.caption).foregroundStyle(Theme.gold400)
                        }
                        if auth.user?.handle == nil && me?.handlePlaceholder != nil {
                            Text("auto-assigned — tap to choose your own")
                                .font(.caption2).foregroundStyle(Theme.gold400)
                        }
                    }
                }
                .buttonStyle(.plain)

                HStack {
                    stat("\(me?.streak.count ?? 0)", "day streak")
                    stat("\(earned.count)", "badges")
                    stat("\(me?.dueCount ?? 0)", "cards due")
                }
                .frame(maxWidth: .infinity)
                .lyceumCard()

                HStack(alignment: .firstTextBaseline) {
                    Text("Badges").font(.headline).foregroundStyle(Theme.ink)
                    Spacer()
                    if !badges.isEmpty {
                        NavigationLink { AchievementsView(badges: badges) } label: {
                            Text("View all").font(.subheadline).foregroundStyle(Theme.gold400)
                        }
                    }
                }
                if earned.isEmpty {
                    Text("No badges yet — take a quiz or run a drill to start earning.")
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(earned.prefix(10)) { badge in
                                VStack(spacing: 5) {
                                    BadgeMedallion(badge: badge, size: 60)
                                    Text(badge.name)
                                        .font(.caption2).foregroundStyle(Theme.inkSoft)
                                        .lineLimit(1).frame(width: 72)
                                }
                            }
                        }
                        // A medallion's glow is a shadow of radius ≈ size * 0.13 — about
                        // 8pt here — so it needs that much clearance on every side or the
                        // ScrollView clips it and the badges read as flat-edged discs.
                        // 2pt wasn't enough vertically and there was none at all on the
                        // sides, which cut the first and last badge.
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                    }
                    // Cancel the parent's inset so the strip scrolls edge to edge; the
                    // inner padding above puts the badges back in line with the headings.
                    .padding(.horizontal, -16)
                }

                if let p = progress, !p.classes.isEmpty {
                    sectionHeader("MY CLASSES")
                    ForEach(p.classes) { c in classCard(c) }
                }

                if let p = progress, !p.inProgress.isEmpty {
                    sectionHeader("IN PROGRESS")
                    ForEach(p.inProgress) { courseRow($0) }
                }

                if let p = progress, !p.completed.isEmpty {
                    sectionHeader("COMPLETED")
                    ForEach(p.completed) { courseRow($0) }
                }

                // Reachable from inside the app, not just the App Store listing —
                // reviewers look for it, and students shouldn't have to.
                HStack(spacing: 18) {
                    Link("Privacy Policy", destination: AppConfig.assetURL("/privacy")!)
                    Link("Support", destination: AppConfig.assetURL("/support")!)
                }
                .font(.callout)
                .tint(Theme.gold400)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                SecondaryButton(title: "Sign out") { Task { await auth.logout() } }

                // Account deletion has to be reachable from inside the app (App Store
                // Review Guideline 5.1.1(v)). Kept quiet and last so nobody taps it by
                // accident on the way to signing out.
                Button("Delete Account") { showDelete = true }
                    .font(.callout)
                    .tint(Theme.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding()
        }
        .background(Theme.parchment)
        .sheet(isPresented: $showDelete) { DeleteAccountSheet() }
        .sheet(isPresented: $showHandleEditor) {
            HandleEditorSheet(current: auth.user?.handle, assigned: me?.handlePlaceholder) { updated in
                auth.user = updated
            }
        }
        .task { await load() }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 28, weight: .bold)).foregroundStyle(Theme.crimson)
            Text(label).font(.caption).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
    }

    private func load() async {
        async let meResult: MeResponse? = try? await APIClient.shared.get("/me")
        async let badgesResult: BadgesResponse? = try? await APIClient.shared.get("/me/badges")
        async let progressResult: ProgressResponse? = try? await APIClient.shared.get("/me/progress")
        me = await meResult
        badges = (await badgesResult)?.badges ?? []
        progress = await progressResult
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.display(11)).kerning(2).foregroundStyle(Theme.gold400)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    /// One enrolled class: the headline grade, and the same six weighted categories
    /// the web class hub shows, folded away until asked for.
    @ViewBuilder private func classCard(_ c: ClassGrade) -> some View {
        let open = expandedClass == c.sectionId
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    expandedClass = open ? nil : c.sectionId
                }
            } label: {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.courseTitle)
                            .font(.display(14)).foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.leading).lineLimit(2)
                        Text(c.sectionName).font(.serif(13)).foregroundStyle(Theme.inkSoft)
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Self.pct(c.currentGrade))
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Self.gradeColor(c.currentGrade))
                        Text("current grade").font(.caption2).foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            .buttonStyle(.plain)

            if open {
                VStack(spacing: 6) {
                    ForEach(c.breakdown, id: \.label) { row in
                        HStack(alignment: .firstTextBaseline) {
                            Text(row.label).font(.serif(14)).foregroundStyle(Theme.ink)
                            Text("· \(row.detail)").font(.caption).foregroundStyle(Theme.inkSoft)
                            Spacer(minLength: 4)
                            Text(Self.pct(row.pct))
                                .font(.serif(14)).foregroundStyle(Self.gradeColor(row.pct))
                            Text("\(row.weight)%")
                                .font(.caption).foregroundStyle(Theme.inkSoft)
                                .frame(width: 34, alignment: .trailing)
                        }
                    }
                    Text("A category with no data yet shows — and doesn't count against you.")
                        .font(.caption).foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                }
            }

            Text(open ? "Hide breakdown" : "Show breakdown")
                .font(.caption).foregroundStyle(Theme.gold400)
        }
        .lyceumCard()
    }

    private func courseRow(_ c: CourseProgressItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(c.title)
                .font(.display(14)).foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading).lineLimit(2)
            QuizProgressBar(fraction: c.fraction)
            Text("\(c.watchedCount) of \(c.totalCount) lectures")
                .font(.caption).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lyceumCard()
    }

    /// nil reads as "—", not 0: a category with no data yet is pending, not failed.
    static func pct(_ v: Double?) -> String { v.map { "\(Int($0.rounded()))%" } ?? "—" }

    static func gradeColor(_ v: Double?) -> Color {
        guard let v else { return Theme.inkSoft }
        if v >= 90 { return Theme.success }
        if v >= 70 { return Theme.gold400 }
        return Theme.danger
    }
}
