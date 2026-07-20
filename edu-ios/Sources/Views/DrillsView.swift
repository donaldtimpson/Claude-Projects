import SwiftUI

struct DrillsView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var active: ActiveDrill?
    @State private var query = ""
    @AppStorage("drill_recents") private var recentsCSV = ""   // most-recent-first slugs

    private var userId: String { auth.user?.id ?? "guest" }
    private var recents: [DrillDef] {
        recentsCSV.split(separator: ",").compactMap { DrillCatalog.drill(slug: String($0)) }
    }

    // Browse sections — a presentation grouping kept view-side so DrillEngine stays lean.
    // A drill not listed here still appears under "More" (defensive).
    private static let sections: [(title: String, slugs: [String])] = [
        ("Mental Math", ["arithmetic", "percentages", "order-of-operations", "powers-of-two",
                         "squares", "gcd", "primes", "sequences", "logarithms"]),
        ("Trigonometry", ["unit-circle", "vectors"]),
        ("Calculus", ["derivative", "integral"]),
        ("Linear Algebra", ["determinant", "solve-system", "matrix-vector", "dot-product"]),
        ("Geography", ["name-country", "name-state", "locate-country", "locate-state"]),
    ]
    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            if query.isEmpty {
                browse
            } else {
                let results = DrillCatalog.all.filter { matches($0, query) }
                VStack(alignment: .leading, spacing: 12) {
                    if results.isEmpty {
                        Text("No drills match “\(query)”.").foregroundStyle(Theme.inkSoft).padding(.top, 40)
                    }
                    grid(results)
                }
                .padding()
            }
        }
        .background(Theme.parchment)
        .navigationTitle("Practice Drills")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Search drills")
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

    // MARK: browse (search empty)
    @ViewBuilder private var browse: some View {
        VStack(alignment: .leading, spacing: 22) {
            if !recents.isEmpty {
                sectionHeader("Continue")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) { ForEach(recents) { recentTile($0) } }
                        .padding(.horizontal, 2)
                }
            }
            ForEach(Self.sections, id: \.title) { section in
                let drills = section.slugs.compactMap { DrillCatalog.drill(slug: $0) }
                if !drills.isEmpty {
                    sectionHeader(section.title)
                    grid(drills)
                }
            }
            let categorized = Set(Self.sections.flatMap(\.slugs))
            let extras = DrillCatalog.all.filter { !categorized.contains($0.slug) }
            if !extras.isEmpty {
                sectionHeader("More")
                grid(extras)
            }
        }
        .padding()
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title).font(.display(15)).kerning(1).foregroundStyle(Theme.gold400)
    }

    private func grid(_ drills: [DrillDef]) -> some View {
        LazyVGrid(columns: cols, spacing: 12) { ForEach(drills) { tile($0) } }
    }

    // MARK: tiles
    private func tile(_ d: DrillDef) -> some View {
        Button { open(d.slug) } label: {
            VStack(spacing: 8) {
                Text(d.icon).font(.system(size: 34))
                Text(d.title).font(.subheadline).foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
                if let sub = masterySubtitle(d) {
                    Text(sub).font(.caption2).foregroundStyle(Theme.gold400)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 92)
            .lyceumCard()
        }
        .buttonStyle(.plain)
    }

    private func recentTile(_ d: DrillDef) -> some View {
        Button { open(d.slug) } label: {
            VStack(spacing: 6) {
                Text(d.icon).font(.system(size: 30))
                Text(d.title).font(.caption).foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
                if let sub = masterySubtitle(d) {
                    Text(sub).font(.caption2).foregroundStyle(Theme.gold400)
                }
            }
            .frame(width: 116, height: 96)
            .lyceumCard()
        }
        .buttonStyle(.plain)
    }

    // "N/total mastered" for Learn-capable drills (their whole pool), else nil.
    private func masterySubtitle(_ d: DrillDef) -> String? {
        guard let items = d.poolItems?(3) else { return nil }
        let m = DrillMastery.shared.masteredCount(userId: userId, slug: d.slug, items: items)
        return m > 0 ? "\(m)/\(items.count) mastered" : nil
    }

    // MARK: logic
    private func open(_ slug: String) {
        var r = recents.map(\.slug).filter { $0 != slug }
        r.insert(slug, at: 0)
        recentsCSV = r.prefix(5).joined(separator: ",")
        active = ActiveDrill(id: slug)
    }

    private func matches(_ d: DrillDef, _ q: String) -> Bool {
        let category = Self.sections.first { $0.slugs.contains(d.slug) }?.title ?? ""
        return "\(d.title) \(d.blurb) \(category)".lowercased().contains(q.lowercased())
    }
}

struct ActiveDrill: Identifiable { let id: String }
