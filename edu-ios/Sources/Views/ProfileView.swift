import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var me: MeResponse?
    @State private var badges: [Badge] = []

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

                SecondaryButton(title: "Sign out") { Task { await auth.logout() } }
            }
            .padding()
        }
        .background(Theme.parchment)
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
