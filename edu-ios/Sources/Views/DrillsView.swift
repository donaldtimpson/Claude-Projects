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
    @State private var acedRefresh = false   // bumped after /me/lessons load to re-render the ✦
    @AppStorage("drill_recents") private var recentsCSV = ""   // most-recent-first slugs

    private var userId: String { auth.user?.id ?? "guest" }
    private var recents: [DrillDef] {
        recentsCSV.split(separator: ",").compactMap { DrillCatalog.drill(slug: String($0)) }
    }

    private static let categories: [DrillCategoryRoute] = [
        .init(title: "Grammar Lessons", icon: "graduationcap.fill", slugs: DrillCatalog.lessonSlugs),
        .init(title: "Mental Math", icon: "plus.forwardslash.minus", slugs: ["arithmetic", "percentages", "order-of-operations",
              "powers-of-two", "squares", "gcd", "primes", "sequences", "logarithms"]),
        .init(title: "Trigonometry", icon: "angle", slugs: ["unit-circle", "vectors"]),
        .init(title: "Calculus", icon: "function", slugs: ["derivative", "integral"]),
        .init(title: "Linear Algebra", icon: "square.grid.3x3", slugs: ["determinant", "solve-system", "matrix-vector", "dot-product"]),
        .init(title: "Geography", icon: "globe.europe.africa.fill", slugs: ["name-country", "name-state", "locate-country", "locate-state",
              "capital-country", "capital-state"]),
        .init(title: "Grammar", icon: "text.quote", slugs: DrillCatalog.grammarSlugs),
    ]

    @FocusState private var searchFocused: Bool
    private var searching: Bool { searchFocused || !query.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Masthead(overlap: !searching && !recents.isEmpty ? 40 : 0) { mastheadText }
                if query.isEmpty { browse } else { searchResults }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .tint(Theme.link)
        .background(Theme.page)
        .mastheadChrome("Practice Drills", crest: true)
        .task(id: userId) { await refreshAced() }
        .navigationDestination(for: DrillCategoryRoute.self) { route in
            CategoryDrillsView(route: route, userId: userId, open: open)
        }
        .fullScreenCover(item: $active) { drill in
            NavigationStack {
                DrillRunnerView(slug: drill.id)
            }
        }
    }

    // Server-derived ✦: fetch the user's aced lesson slugs and merge them into
    // LessonProgress. Bumps acedRefresh so the rows re-render once the (signed-in)
    // result lands; local optimistic marks still show instantly on a flawless run.
    private func refreshAced() async {
        guard auth.user != nil else { return }
        if let res: LessonsResponse = try? await APIClient.shared.get("/me/lessons") {
            LessonProgress.shared.setServerAced(userId: userId, slugs: res.acedSlugs)
            acedRefresh.toggle()
        }
    }

    // While searching the masthead keeps just the field.
    private var mastheadText: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !searching {
                GiltEyebrow("The Palaestra")
                Text("Practice Drills")
                    .font(.serif(30, .bold, relativeTo: .largeTitle)).foregroundStyle(Theme.onLeather)
                Text("Short, sharp practice. Ace a drill to earn its ✦.")
                    .font(.serif(16).italic()).foregroundStyle(Theme.onLeatherSoft)
                    .padding(.bottom, 8)
            }
            LeatherSearchField(prompt: "Search drills", text: $query, focus: $searchFocused)
        }
        .animation(.snappy(duration: 0.3), value: searching)
    }

    // MARK: browse (search empty) — Continue strip, categories
    @ViewBuilder private var browse: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                if !recents.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(recents) { d in
                                Button { open(d.slug) } label: { recentTile(d) }.buttonStyle(.lyceumPress)
                            }
                        }
                        .padding(.horizontal, 2).padding(.vertical, 2)
                    }
                    .scrollClipDisabled()
                    .padding(.top, searching ? 12 : -40)
                }
                sectionHeader("Categories")
                Codex(dividerInset: 72) {
                    ForEach(Self.categories, id: \.title) { cat in
                        NavigationLink(value: cat) { categoryRow(cat) }
                            .buttonStyle(.lyceumRow)
                            // Handle for the screenshot UI test (tools/screenshots.sh).
                            .accessibilityIdentifier("drillCategoryRow")
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder private func categoryCount(_ cat: DrillCategoryRoute) -> some View {
        if cat.slugs == DrillCatalog.lessonSlugs {
            let aced = LessonProgress.shared.acedCount(userId: userId, slugs: cat.slugs)
            Text(aced > 0 ? "✦ \(aced) of \(cat.slugs.count) aced" : "\(cat.slugs.count) lessons")
                .font(.ui(13, aced > 0 ? .semibold : .regular)).foregroundStyle(aced > 0 ? Theme.accentText : Theme.inkSoft)
        } else {
            Text("\(cat.slugs.count) drills").font(.ui(13)).foregroundStyle(Theme.inkSoft)
        }
    }

    // MARK: search results — matching categories first, then drills; matches highlighted
    @ViewBuilder private var searchResults: some View {
        let cats = Self.categories.filter { $0.title.range(of: query, options: .caseInsensitive) != nil }
        let drills = DrillCatalog.all.filter { matches($0, query) }
        VStack(alignment: .leading, spacing: 12) {
            if cats.isEmpty && drills.isEmpty {
                Text("No matches for “\(query)”.").font(.serif(16)).foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity).padding(.top, 40)
            }
            if !cats.isEmpty {
                sectionHeader("Categories")
                Codex(dividerInset: 70) {
                    ForEach(cats, id: \.title) { cat in
                        NavigationLink(value: cat) { categoryRow(cat, query: query) }.buttonStyle(.lyceumRow)
                    }
                }
            }
            if !drills.isEmpty {
                sectionHeader("Drills")
                Codex(dividerInset: 70) {
                    ForEach(drills) { d in DrillRow(drill: d, userId: userId, query: query) { open(d.slug) } }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }

    private func sectionHeader(_ title: String) -> some View {
        SectionTitle(title)
    }

    private func categoryRow(_ cat: DrillCategoryRoute, query: String = "") -> some View {
        HStack(spacing: 12) {
            Medallion(systemImage: cat.icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(highlighted(cat.title, query)).font(.serif(17, .semibold)).foregroundStyle(Theme.ink)
                categoryCount(cat)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.ui(13, .semibold)).foregroundStyle(Theme.inkSoft.opacity(0.6))
        }
        .codexRow()
    }

    // Recent chip — a fixed, uniform card (content centered) so the strip reads evenly.
    private func recentTile(_ d: DrillDef) -> some View {
        VStack(spacing: 6) {
            DrillIcon(drill: d, size: 48)
            Text(d.title).font(.serif(15, .semibold)).foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.75)
            if LessonProgress.shared.isAced(userId: userId, slug: d.slug) {
                Text("✦ Aced").font(.ui(13, .semibold)).foregroundStyle(Theme.accentText)
            } else if let sub = masterySubtitle(d, userId: userId) {
                Text(sub).font(.ui(13)).foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(8)
        .frame(width: 128, height: 124)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.line, lineWidth: 0.75))
        .shadow(color: Color(hex: 0x2a0a0a).opacity(0.14), radius: 12, y: 5)
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
        return "\(d.title) \(d.blurb) \(category)".range(of: q, options: .caseInsensitive) != nil
    }
}

// A pushed screen listing one category's drills as full-width rows.
struct CategoryDrillsView: View {
    let route: DrillCategoryRoute
    let userId: String
    let open: (String) -> Void

    var body: some View {
        ScrollView {
            Codex(dividerInset: 70) {
                ForEach(route.slugs.compactMap { DrillCatalog.drill(slug: $0) }) { d in
                    DrillRow(drill: d, userId: userId) { open(d.slug) }
                }
            }
            .padding()
        }
        .background(Theme.page)
        .leatherBar(route.title)
    }
}

// The shared full-width drill row (icon + title + blurb + optional mastery). Highlights
// the search match in title/blurb when `query` is set.
struct DrillRow: View {
    let drill: DrillDef
    let userId: String
    var query: String = ""
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                DrillIcon(drill: drill)
                VStack(alignment: .leading, spacing: 2) {
                    Text(highlighted(drill.title, query)).font(.serif(17, .semibold)).foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                    Text(highlighted(drill.blurb, query)).font(.ui(14)).foregroundStyle(Theme.inkSoft).lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                if LessonProgress.shared.isAced(userId: userId, slug: drill.slug) {
                    Text("✦ Aced").font(.ui(12, .semibold)).foregroundStyle(Theme.accentText)
                } else if let sub = masterySubtitle(drill, userId: userId) {
                    Text(sub).font(.ui(12)).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.trailing)
                }
            }
            .codexRow()
        }
        .buttonStyle(.lyceumRow)
        .accessibilityIdentifier("drillRow")
    }
}

// A drill's Learn pool, built once per slug. `poolItems` is a closure that rebuilds its
// array on every call — and for the map drills it's what forces the geo atlas to parse —
// so calling it straight from a view body re-did that work on every layout pass.
@MainActor private var poolItemsCache: [String: [String]] = [:]

// "N/total mastered" for Learn-capable drills (their whole pool), else nil.
@MainActor func masterySubtitle(_ d: DrillDef, userId: String) -> String? {
    guard let pool = d.poolItems else { return nil }
    let items: [String]
    if let cached = poolItemsCache[d.slug] { items = cached }
    else { items = pool(3); poolItemsCache[d.slug] = items }
    let m = DrillMastery.shared.masteredCount(userId: userId, slug: d.slug, items: items)
    return m > 0 ? "\(m)/\(items.count) mastered" : nil
}

// Bold + gold the case-insensitive matches of `query` within `text`, so the user sees
// why a result matched.
func highlighted(_ text: String, _ query: String) -> AttributedString {
    var attr = AttributedString(text)
    let q = query.trimmingCharacters(in: .whitespaces)
    guard !q.isEmpty else { return attr }
    var start = attr.startIndex
    while let r = attr[start...].range(of: q, options: .caseInsensitive) {
        attr[r].foregroundColor = Theme.accentText
        attr[r].inlinePresentationIntent = .stronglyEmphasized
        start = r.upperBound
    }
    return attr
}

struct ActiveDrill: Identifiable { let id: String }

/// A drill's emoji on a small tinted tile with a gold hairline.
/// A drill's mark: the same leather medallion as its category, struck with the drill's
/// glyph, or for a grammar lesson its number. (The catalog's emoji stay on the web.)
struct DrillIcon: View {
    let drill: DrillDef
    var size: CGFloat = 42
    var body: some View {
        if let n = Self.lessonNumber(drill.slug) {
            Medallion(numeral: n, size: size)
        } else {
            Medallion(systemImage: DrillSymbols.bySlug[drill.slug] ?? "sparkles", size: size)
        }
    }

    /// "lesson-07" → 7.
    static func lessonNumber(_ slug: String) -> Int? {
        guard slug.hasPrefix("lesson-") else { return nil }
        return Int(slug.dropFirst("lesson-".count))
    }
}

/// A category's or drill's mark: a gold glyph (or numeral) struck on a small leather medallion.
struct Medallion: View {
    private let systemImage: String?
    private let numeral: Int?
    var size: CGFloat = 44

    init(systemImage: String, size: CGFloat = 44) {
        self.systemImage = systemImage; self.numeral = nil; self.size = size
    }
    init(numeral: Int, size: CGFloat = 44) {
        self.systemImage = nil; self.numeral = numeral; self.size = size
    }

    var body: some View {
        Group {
            if let numeral {
                Text("\(numeral)").font(.serif(size * 0.44, .bold)).monospacedDigit()
            } else if let systemImage {
                Image(systemName: systemImage).font(.system(size: size * 0.4, weight: .semibold))
            }
        }
        .foregroundStyle(Theme.gilt)
        .frame(width: size, height: size)
        .background(Circle().fill(Theme.leather))
        .overlay(Circle().inset(by: 2.5).strokeBorder(Theme.gilt.opacity(0.55), lineWidth: 0.75))
        .shadow(color: Color(hex: 0x3a0b0b).opacity(0.25), radius: 2, y: 1)
        .accessibilityHidden(true)
    }
}
