import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var me: MeResponse?
    @State private var badges: [Badge] = []
    @State private var showDelete = false

    var body: some View {
        signedIn
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
    }

    private var earned: [Badge] { badges.filter { $0.unlocked } }

    @ViewBuilder private var signedIn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(auth.user?.name ?? "Scholar").font(.title.weight(.bold)).foregroundStyle(Theme.crimson)
                if let handle = auth.user?.handle { Text("@\(handle)").foregroundStyle(Theme.inkSoft) }

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
                        .padding(.vertical, 2)
                    }
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
        me = await meResult
        badges = (await badgesResult)?.badges ?? []
    }
}
