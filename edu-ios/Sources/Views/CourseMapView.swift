import SwiftUI

// The course map — which courses lead into which. The web draws this as a wide SVG
// that scrolls sideways; that reads badly on a phone, so this turns the same graph
// on its side and flows DOWN the screen, which is the direction a phone scrolls
// anyway. It works because the graph is deep and narrow: 7 tiers, never more than
// four courses abreast, so every tier fits the width without pinching or panning.
//
// Same shape as the web: only courses that actually participate in a connection are
// charted, laid out by longest path so a course always sits below everything it
// follows.
struct CourseMapView: View {
    @State private var courses: [MapCourse] = []
    @State private var links: [MapLink] = []
    @State private var loading = true
    @State private var error: String?

    // Node metrics. Height is fixed so tiers line up and the edges stay predictable.
    private let nodeH: CGFloat = 62
    private let vGap: CGFloat = 46
    private let hGap: CGFloat = 10
    private let sidePad: CGFloat = 16
    /// Cap the width so a tier holding one course doesn't stretch a card across the
    /// whole screen while a four-up tier is pinched. Tiers are centred instead.
    private let maxNodeW: CGFloat = 152

    var body: some View {
        Group {
            if loading {
                ProgressView().tint(Theme.gold300)
            } else if let error {
                ContentUnavailableView("Couldn't load", systemImage: "wifi.slash", description: Text(error))
            } else if tiers.isEmpty {
                ContentUnavailableView(
                    "No connections yet",
                    systemImage: "point.topleft.down.to.point.bottomright.curvepath",
                    description: Text("Once courses are linked to one another, the map will show what leads where."))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Courses that lead into one another, earliest at the top. Tap any course to open it.")
                            .font(.serif(15)).foregroundStyle(Theme.inkSoft)
                            .padding(.horizontal, sidePad)
                        graph
                        legend.padding(.horizontal, sidePad)
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.parchment)
        .navigationTitle("Course Map")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    // MARK: layout

    /// Courses in any link, layered by longest path over the RECOMMENDED edges — the
    /// same rule the web map uses, so both platforms agree on what sits where.
    private var tiers: [[MapCourse]] {
        let byId = Dictionary(uniqueKeysWithValues: courses.map { ($0.id, $0) })
        let charted = Set(links.flatMap { [$0.fromCourseId, $0.toCourseId] }).filter { byId[$0] != nil }
        guard !charted.isEmpty else { return [] }

        let rec = links.filter(\.isRecommended)
        var level: [String: Int] = Dictionary(uniqueKeysWithValues: charted.map { ($0, 0) })
        // Relax repeatedly rather than topologically sorting: the graph is tiny, and
        // this can't spin forever because each pass either raises a level or stops.
        for _ in 0..<charted.count {
            var changed = false
            for e in rec {
                guard let from = level[e.fromCourseId], let to = level[e.toCourseId] else { continue }
                if to < from + 1 { level[e.toCourseId] = from + 1; changed = true }
            }
            if !changed { break }
        }
        let maxLevel = level.values.max() ?? 0
        return (0...maxLevel).map { l in
            charted.filter { level[$0] == l }
                .compactMap { byId[$0] }
                .sorted { $0.nodeLabel < $1.nodeLabel }
        }
    }

    /// Node width and the x of the first node's leading edge, for a tier of `count`.
    private func metrics(_ count: Int, in width: CGFloat) -> (nodeW: CGFloat, startX: CGFloat) {
        let n = CGFloat(max(count, 1))
        let usable = width - sidePad * 2
        let nodeW = min(maxNodeW, max(64, (usable - hGap * (n - 1)) / n))
        let rowW = nodeW * n + hGap * (n - 1)
        return (nodeW, (width - rowW) / 2)
    }

    private func positions(in width: CGFloat) -> [String: CGPoint] {
        var out: [String: CGPoint] = [:]
        for (row, tier) in tiers.enumerated() {
            let m = metrics(tier.count, in: width)
            for (i, c) in tier.enumerated() {
                out[c.id] = CGPoint(
                    x: m.startX + CGFloat(i) * (m.nodeW + hGap) + m.nodeW / 2,
                    y: CGFloat(row) * (nodeH + vGap) + nodeH / 2)
            }
        }
        return out
    }

    private var graphHeight: CGFloat {
        CGFloat(max(tiers.count, 1)) * nodeH + CGFloat(max(tiers.count - 1, 0)) * vGap
    }

    @ViewBuilder private var graph: some View {
        GeometryReader { geo in
            let pos = positions(in: geo.size.width)
            ZStack(alignment: .topLeading) {
                // Edges first, so nodes sit on top of them.
                Canvas { ctx, _ in
                    for link in links {
                        guard let a = pos[link.fromCourseId], let b = pos[link.toCourseId] else { continue }
                        let start = CGPoint(x: a.x, y: a.y + nodeH / 2)
                        let end = CGPoint(x: b.x, y: b.y - nodeH / 2)
                        var path = Path()
                        path.move(to: start)
                        // A vertical-tangent curve: leaves the bottom of one card and
                        // arrives at the top of the next, so crossings read cleanly.
                        path.addCurve(
                            to: end,
                            control1: CGPoint(x: start.x, y: start.y + vGap * 0.6),
                            control2: CGPoint(x: end.x, y: end.y - vGap * 0.6))
                        ctx.stroke(
                            path,
                            with: .color(link.isRecommended ? Theme.gold500.opacity(0.75) : Theme.line),
                            style: StrokeStyle(
                                lineWidth: link.isRecommended ? 1.6 : 1.2,
                                dash: link.isRecommended ? [] : [4, 4]))
                    }
                }
                ForEach(Array(tiers.enumerated()), id: \.offset) { _, tier in
                    ForEach(tier) { course in
                        node(course, width: metrics(tier.count, in: geo.size.width).nodeW)
                            .position(pos[course.id] ?? .zero)
                    }
                }
            }
        }
        .frame(height: graphHeight)
    }

    private func node(_ course: MapCourse, width: CGFloat) -> some View {
        NavigationLink(value: MapCourseRoute(id: course.id)) {
            Text(course.nodeLabel)
                .font(.system(size: 11, weight: .medium))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .lineLimit(3)
                .foregroundStyle(course.isCurrent == true ? Theme.onAccent : Theme.ink)
                .padding(.horizontal, 5)
                .frame(width: width, height: nodeH)
                .background(course.isCurrent == true ? Theme.accent : Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(course.isCurrent == true ? Theme.gold300 : Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var legend: some View {
        HStack(spacing: 16) {
            Label { Text("leads to").font(.caption).foregroundStyle(Theme.inkSoft) } icon: {
                Rectangle().fill(Theme.gold500).frame(width: 16, height: 2)
            }
            Label { Text("related").font(.caption).foregroundStyle(Theme.inkSoft) } icon: {
                Rectangle().fill(Theme.line).frame(width: 16, height: 2)
            }
            Label { Text("teaching now").font(.caption).foregroundStyle(Theme.inkSoft) } icon: {
                RoundedRectangle(cornerRadius: 2).fill(Theme.accent).frame(width: 12, height: 10)
            }
            Spacer(minLength: 0)
        }
    }

    private func load() async {
        do {
            // Public, like the website's map.
            let res: CourseMapResponse = try await APIClient.shared.get("/map", auth: false)
            courses = res.courses
            links = res.links
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

/// Route to a course from the map.
struct MapCourseRoute: Hashable { let id: String }
