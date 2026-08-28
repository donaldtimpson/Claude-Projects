import SwiftUI

// The course map, as a phone should do it.
//
// The web draws the whole dependency graph at once and leans on hover to pull one
// course's connections out of the tangle. A phone has no hover and no room, so a
// wall chart of 13 courses and 19 edges is just a knot of crossing lines. But the
// questions a student actually asks are local — "what do I need before this?",
// "where does this lead?" — and a local question never needs a crossing line.
//
// So this is a lens rather than a chart: one course in focus, what feeds into it
// above, what it opens up below, and a tap to walk to any neighbour. The most
// crowded course in the catalogue has eight neighbours, so a focused screen is
// always legible. The breadcrumb across the top carries the part a lens loses —
// the chain of courses that leads to where you're standing.
struct CourseMapView: View {
    @State private var courses: [MapCourse] = []
    @State private var links: [MapLink] = []
    @State private var loading = true
    @State private var error: String?

    @State private var focusId: String?
    /// Where the walk has been, so it can be retraced.
    @State private var history: [String] = []

    var body: some View {
        Group {
            if loading {
                ProgressView().tint(Theme.gold300)
            } else if let error {
                ContentUnavailableView("Couldn't load", systemImage: "wifi.slash", description: Text(error))
            } else if let focus = focused {
                lens(focus)
            } else {
                ContentUnavailableView(
                    "No connections yet",
                    systemImage: "arrow.triangle.branch",
                    description: Text("Once courses are linked to one another, the map will show what leads where."))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.parchment)
        .navigationTitle("Course Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !charted.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(charted) { c in
                            Button { focus(c.id) } label: {
                                Label(c.nodeLabel, systemImage: c.id == focusId ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                    .tint(Theme.gold400)
                    .accessibilityLabel("Jump to a course")
                }
            }
        }
        .task { await load() }
    }

    // MARK: the lens

    @ViewBuilder private func lens(_ course: MapCourse) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let trail = trail(to: course.id), trail.count > 1 {
                    breadcrumb(trail)
                }

                let parents = neighbours(of: course.id, .parents)
                let children = neighbours(of: course.id, .children)
                let related = neighbours(of: course.id, .related)

                group(
                    title: parents.isEmpty ? "START HERE" : "BUILDS ON",
                    empty: "Nothing comes before this — it's a place to start.",
                    courses: parents,
                    glyph: "arrow.down")

                hero(course)

                group(
                    title: "LEADS TO",
                    empty: "Nothing follows this one yet — it's the furthest step on this path so far.",
                    courses: children,
                    glyph: nil)

                if !related.isEmpty {
                    group(title: "RELATED", empty: "", courses: related, glyph: nil)
                }
            }
            .padding()
            .animation(.snappy(duration: 0.28), value: focusId)
        }
    }

    private func hero(_ course: MapCourse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(course.nodeLabel)
                        .font(.display(21)).foregroundStyle(Theme.crimson)
                        .multilineTextAlignment(.leading)
                    // Only when the full title says something the label doesn't —
                    // "…(2024)" adds nothing, but "University Physics II" does when
                    // the label is the short title "Electricity & Magnetism".
                    if !course.title.hasPrefix(course.nodeLabel) {
                        Text(course.title)
                            .font(.serif(13)).foregroundStyle(Theme.inkSoft)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 0)
                if course.isCurrent == true {
                    Text("LIVE").font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.onAccent)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Theme.accent, in: Capsule())
                }
            }
            NavigationLink(value: MapCourseRoute(id: course.id)) {
                HStack(spacing: 6) {
                    Text("Open this course").font(.display(13))
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(Theme.gold400)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.parchmentDeep)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.gold500, lineWidth: 1.5))
        .id(course.id)   // so the card animates when the focus changes
        .transition(.scale(scale: 0.97).combined(with: .opacity))
    }

    @ViewBuilder private func group(title: String, empty: String,
                                    courses list: [MapCourse], glyph: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.display(11)).kerning(2).foregroundStyle(Theme.gold400)
            if list.isEmpty {
                if !empty.isEmpty {
                    Text(empty).font(.serif(14)).foregroundStyle(Theme.inkSoft)
                }
            } else {
                ForEach(list) { c in
                    Button { focus(c.id) } label: { neighbourRow(c) }
                        .buttonStyle(.lyceumPress)
                }
                if let glyph {
                    Image(systemName: glyph)
                        .font(.caption).foregroundStyle(Theme.gold500.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func neighbourRow(_ c: MapCourse) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(c.nodeLabel)
                    .font(.display(14)).foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                let n = neighbours(of: c.id, .children).count
                if n > 0 {
                    Text("opens \(n) more").font(.caption).foregroundStyle(Theme.inkSoft)
                }
            }
            Spacer(minLength: 0)
            if c.isCurrent == true {
                Text("LIVE").font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.onAccent)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Theme.accent, in: Capsule())
            }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.gold400)
        }
        .lyceumCard()
    }

    /// The chain of courses that leads to the focus — the one thing a lens can't show
    /// on its own. Horizontally scrollable, and every step is tappable.
    private func breadcrumb(_ trail: [MapCourse]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("THE WAY HERE")
                .font(.display(11)).kerning(2).foregroundStyle(Theme.gold400)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(trail.enumerated()), id: \.element.id) { i, c in
                        if i > 0 {
                            Image(systemName: "chevron.right")
                                .font(.caption2).foregroundStyle(Theme.inkSoft)
                        }
                        Button { focus(c.id) } label: {
                            Text(c.nodeLabel)
                                .font(.caption)
                                .foregroundStyle(c.id == focusId ? Theme.onAccent : Theme.inkSoft)
                                .padding(.horizontal, 9).padding(.vertical, 5)
                                .background(c.id == focusId ? Theme.accent : Theme.card, in: Capsule())
                                .overlay(Capsule().stroke(Theme.line, lineWidth: c.id == focusId ? 0 : 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: graph

    private enum Direction { case parents, children, related }

    private var byId: [String: MapCourse] {
        Dictionary(uniqueKeysWithValues: courses.map { ($0.id, $0) })
    }

    /// Courses that appear in at least one link, in label order — the map's contents.
    private var charted: [MapCourse] {
        let ids = Set(links.flatMap { [$0.fromCourseId, $0.toCourseId] })
        return ids.compactMap { byId[$0] }.sorted { $0.nodeLabel < $1.nodeLabel }
    }

    private var focused: MapCourse? { focusId.flatMap { byId[$0] } }

    private func neighbours(of id: String, _ dir: Direction) -> [MapCourse] {
        let ids: [String]
        switch dir {
        case .parents:  ids = links.filter { $0.isRecommended && $0.toCourseId == id }.map(\.fromCourseId)
        case .children: ids = links.filter { $0.isRecommended && $0.fromCourseId == id }.map(\.toCourseId)
        case .related:
            ids = links.filter { !$0.isRecommended && ($0.fromCourseId == id || $0.toCourseId == id) }
                .map { $0.fromCourseId == id ? $0.toCourseId : $0.fromCourseId }
        }
        return ids.compactMap { byId[$0] }.sorted { $0.nodeLabel < $1.nodeLabel }
    }

    /// Longest chain of prerequisites ending at `id`. Depth-first with a visited set,
    /// which is safe on a DAG this size and can't loop even if a cycle slipped in.
    private func trail(to id: String, seen: Set<String> = []) -> [MapCourse]? {
        guard let course = byId[id], !seen.contains(id) else { return nil }
        var best: [MapCourse] = []
        for parent in neighbours(of: id, .parents) {
            if let chain = trail(to: parent.id, seen: seen.union([id])), chain.count > best.count {
                best = chain
            }
        }
        return best + [course]
    }

    private func focus(_ id: String) {
        guard id != focusId else { return }
        if let current = focusId { history.append(current) }
        withAnimation(.snappy(duration: 0.28)) { focusId = id }
    }

    private func load() async {
        do {
            let res: CourseMapResponse = try await APIClient.shared.get("/map", auth: false)
            courses = res.courses
            links = res.links
            // Open on what's being taught now — the student's own "you are here" —
            // falling back to the best-connected course, which shows the most map.
            let charted = Set(res.links.flatMap { [$0.fromCourseId, $0.toCourseId] })
            let outDegree = { (id: String) in res.links.filter { $0.isRecommended && $0.fromCourseId == id }.count }
            // Among the courses being taught now, prefer one that leads somewhere —
            // opening on a leaf greets the reader with "nothing follows this one".
            let live = res.courses
                .filter { $0.isCurrent == true && charted.contains($0.id) }
                .max { outDegree($0.id) < outDegree($1.id) }
            focusId = live?.id ?? charted.max { outDegree($0) < outDegree($1) }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

/// Route to a course from the map.
struct MapCourseRoute: Hashable { let id: String }
