import SwiftUI

// Full badge catalog: medallions grouped by category, with an Omniscient capstone.
// Shows everything (earned + locked) by default; a toggle narrows to earned.
struct AchievementsView: View {
    let badges: [Badge]
    @State private var showAll = true
    @State private var detail: Badge?

    private var rest: [Badge] { badges.filter { $0.tier != "omniscient" } }
    private var omniscient: Badge? { badges.first { $0.tier == "omniscient" } }
    private var earnedCount: Int { rest.filter { $0.unlocked }.count }

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 12)]

    private func rank(_ badge: Badge) -> Int { BadgeMeta.tierRank[badge.tier] ?? 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                if let omniscient { omniscientCard(omniscient) }
                ForEach(BadgeMeta.categoryOrder, id: \.self) { cat in
                    section(for: cat)
                }
            }
            .padding()
        }
        .background(Theme.parchment)
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $detail) { detailSheet($0) }
    }

    private var header: some View {
        HStack {
            Text("\(earnedCount) / \(rest.count) earned")
                .font(.serif(16)).foregroundStyle(Theme.ink)
            Spacer()
            Picker("", selection: $showAll) {
                Text("All").tag(true)
                Text("Earned").tag(false)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
        }
    }

    @ViewBuilder private func section(for category: String) -> some View {
        let list = rest
            .filter { $0.category == category }
            .sorted { rank($0) < rank($1) }
        let visible = showAll ? list : list.filter { $0.unlocked }
        if !visible.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: BadgeMeta.categorySymbol(category)).foregroundStyle(Theme.gold400)
                    Text(BadgeMeta.categoryLabel(category))
                        .font(.display(16)).foregroundStyle(Theme.ink)
                    Spacer(minLength: 8)
                    Text("\(list.filter { $0.unlocked }.count) / \(list.count)")
                        .font(.caption).foregroundStyle(Theme.inkSoft)
                }
                LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                    ForEach(visible) { badge in
                        cell(badge)
                    }
                }
            }
        }
    }

    private func cell(_ badge: Badge) -> some View {
        Button { detail = badge } label: {
            VStack(spacing: 6) {
                BadgeMedallion(badge: badge, size: 66)
                Text(badge.name)
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundStyle(badge.unlocked ? Theme.ink : Theme.inkSoft)
                    .multilineTextAlignment(.center).lineLimit(2)
                Text(BadgeMeta.tierLabel(badge.tier))
                    .font(.system(size: 9, weight: .semibold)).kerning(0.5)
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func omniscientCard(_ badge: Badge) -> some View {
        HStack(spacing: 14) {
            BadgeMedallion(badge: badge, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text("OMNISCIENT").font(.display(12)).kerning(2).foregroundStyle(Theme.gold300)
                Text(badge.name).font(.display(18)).foregroundStyle(Theme.ink)
                Text(badge.blurb).font(.serif(14)).foregroundStyle(Theme.inkSoft).lineLimit(3)
            }
            Spacer(minLength: 0)
            Text(badge.unlocked ? "Attained" : "Unclaimed")
                .font(.caption).foregroundStyle(badge.unlocked ? Theme.gold300 : Theme.inkSoft)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(Theme.crimson900)
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(
                    AngularGradient(colors: [Color(hex: 0xf8ecb8), Color(hex: 0xb8860b), Color(hex: 0xf8ecb8)], center: .center),
                    lineWidth: 1.5))
        )
        .shadow(color: Color(hex: 0xddb954).opacity(badge.unlocked ? 0.35 : 0.12), radius: 16)
    }

    private func detailSheet(_ badge: Badge) -> some View {
        VStack(spacing: 16) {
            BadgeMedallion(badge: badge, size: 120)
                .padding(.top, 28)
            Text(badge.name).font(.display(22)).foregroundStyle(Theme.ink).multilineTextAlignment(.center)
            Text(BadgeMeta.tierLabel(badge.tier).uppercased())
                .font(.caption).kerning(1.5).foregroundStyle(Theme.gold400)
            Text(badge.blurb)
                .font(.serif(17)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center).padding(.horizontal, 24)
            Text(badge.unlocked ? "✓ Earned" : "Locked")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(badge.unlocked ? Theme.gold300 : Theme.inkSoft)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Theme.parchment)
        .presentationDetents([.medium])
    }
}
