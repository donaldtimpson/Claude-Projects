import SwiftUI

// A drill category you can drill into (top-level row → pushed list of drills).
struct DrillCategoryRoute: Hashable {
    let title: String
    let icon: String
    let slugs: [String]
}

struct DrillsView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var active: ActiveDrill?
    @State private var query = ""
    @AppStorage("drill_recents") private var recentsCSV = ""   // most-recent-first slugs

    private var userId: String { auth.user?.id ?? "guest" }
    private var recents: [DrillDef] {
        recentsCSV.split(separator: ",").compactMap { DrillCatalog.drill(slug: String($0)) }
    }

    private static let categories: [DrillCategoryRoute] = [
        .init(title: "Mental Math", icon: "🧮", slugs: ["arithmetic", "percentages", "order-of-operations",
              "powers-of-two", "squares", "gcd", "primes", "sequences", "logarithms"]),
        .init(title: "Trigonometry", icon: "📐", slugs: ["unit-circle", "vectors"]),
        .init(title: "Calculus", icon: "∫", slugs: ["derivative", "integral"]),
        .init(title: "Linear Algebra", icon: "▦", slugs: ["determinant", "solve-system", "matrix-vector", "dot-product"]),
        .init(title: "Geography", icon: "🌍", slugs: ["name-country", "name-state", "locate-country", "locate-state"]),
    ]

    var body: some View {
        ScrollView {
            if query.isEmpty {
                browse
            } else {
                let results = DrillCatalog.all.filter { matches($0, query) }
                VStack(spacing: 10) {
                    if results.isEmpty {
                        Text("No drills match “\(query)”.").foregroundStyle(Theme.inkSoft).padding(.top, 40)
                    }
                    ForEach(results) { d in DrillRow(drill: d, userId: userId) { open(d.slug) } }
                }
                .padding()
            }
        }
        .background(Theme.parchment)
        .navigationTitle("Practice Drills")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Search drills")
        .navigationDestination(for: DrillCategoryRoute.self) { route in
            CategoryDrillsView(route: route, userId: userId, open: open)
        }
        .fullScreenCover(item: $active) { drill in
            NavigationStack {
                DrillRunnerView(slug: drill.id)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button { active = nil } label: { Image(systemName: "xmark").font(.body.weight(.semibold)) }
                                .tint(Theme.gold300)
                        }
                    }
            }
        }
    }

    // MARK: browse (search empty) — Continue strip + category rows to drill into
    @ViewBuilder private var browse: some View {
        VStack(alignment: .leading, spacing: 22) {
            if !recents.isEmpty {
                sectionHeader("Continue")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recents) { d in
                            Button { open(d.slug) } label: { recentTile(d) }.buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            sectionHeader("Categories")
            VStack(spacing: 10) {
                ForEach(Self.categories, id: \.title) { cat in
                    NavigationLink(value: cat) { categoryRow(cat) }.buttonStyle(.plain)
                }
            }
        }
        .padding()
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title).font(.display(15)).kerning(1).foregroundStyle(Theme.gold400)
    }

    private func categoryRow(_ cat: DrillCategoryRoute) -> some View {
        HStack(spacing: 12) {
            Text(cat.icon).font(.system(size: 32))
            VStack(alignment: .leading, spacing: 2) {
                Text(cat.title).font(.headline).foregroundStyle(Theme.ink)
                Text("\(cat.slugs.count) drills").font(.subheadline).foregroundStyle(Theme.inkSoft)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.subheadline).foregroundStyle(Theme.inkSoft)
        }
        .lyceumCard()
    }

    private func recentTile(_ d: DrillDef) -> some View {
        VStack(spacing: 6) {
            Text(d.icon).font(.system(size: 30))
            Text(d.title).font(.caption).foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
            if let sub = masterySubtitle(d, userId: userId) {
                Text(sub).font(.caption2).foregroundStyle(Theme.gold400)
            }
        }
        .frame(width: 116, height: 96)
        .lyceumCard()
    }

    // MARK: logic
    private func open(_ slug: String) {
        var r = recents.map(\.slug).filter { $0 != slug }
        r.insert(slug, at: 0)
        recentsCSV = r.prefix(5).joined(separator: ",")
        active = ActiveDrill(id: slug)
    }

    private func matches(_ d: DrillDef, _ q: String) -> Bool {
        let category = Self.categories.first { $0.slugs.contains(d.slug) }?.title ?? ""
        return "\(d.title) \(d.blurb) \(category)".lowercased().contains(q.lowercased())
    }
}

// A pushed screen listing one category's drills as full-width rows.
struct CategoryDrillsView: View {
    let route: DrillCategoryRoute
    let userId: String
    let open: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(route.slugs.compactMap { DrillCatalog.drill(slug: $0) }) { d in
                    DrillRow(drill: d, userId: userId) { open(d.slug) }
                }
            }
            .padding()
        }
        .background(Theme.parchment)
        .navigationTitle(route.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// The shared full-width drill row (icon + title + blurb + optional mastery).
struct DrillRow: View {
    let drill: DrillDef
    let userId: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(drill.icon).font(.system(size: 34))
                VStack(alignment: .leading, spacing: 2) {
                    Text(drill.title).font(.headline).foregroundStyle(Theme.ink)
                    Text(drill.blurb).font(.subheadline).foregroundStyle(Theme.inkSoft).lineLimit(2)
                    if let sub = masterySubtitle(drill, userId: userId) {
                        Text(sub).font(.caption2).foregroundStyle(Theme.gold400)
                    }
                }
                Spacer(minLength: 0)
            }
            .lyceumCard()
        }
        .buttonStyle(.plain)
    }
}

// "N/total mastered" for Learn-capable drills (their whole pool), else nil.
@MainActor func masterySubtitle(_ d: DrillDef, userId: String) -> String? {
    guard let items = d.poolItems?(3) else { return nil }
    let m = DrillMastery.shared.masteredCount(userId: userId, slug: d.slug, items: items)
    return m > 0 ? "\(m)/\(items.count) mastered" : nil
}

struct ActiveDrill: Identifiable { let id: String }
