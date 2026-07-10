import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var me: MeResponse?
    @State private var badges: [Badge] = []

    var body: some View {
        signedIn
            .navigationTitle("Profile")
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

                Text("Badges").font(.headline).foregroundStyle(Theme.ink)
                if earned.isEmpty {
                    Text("No badges yet — take a quiz or run a drill to start earning.")
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                        ForEach(earned) { badge in
                            Text(badge.name)
                                .font(.caption).fontWeight(.bold).foregroundStyle(.white)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(Theme.gold).clipShape(Capsule())
                        }
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
