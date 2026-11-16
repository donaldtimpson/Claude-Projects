import SwiftUI

// The Courses tab: the web home page. Announcements, then (signed in) Continue
// Watching, Currently Teaching, Browse by Category, and All Courses; search filters
// courses instantly and searches lecture transcripts on the server.
struct LearnView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var router: Router
    @State private var courses: [CourseListItem] = []
    @State private var categories: [CategoryItem] = []
    @State private var announcements: [Announcement] = []
    @State private var continueWatching: [CourseProgressItem] = []
    @State private var loading = true
    @State private var failed = false

    @State private var query = ""
    @State private var results: SearchResults?
    @State private var searching = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        content
            .tint(Theme.link)
            // The map and the board are public and live in the web's nav drawer;
            // here they hang off the home tab, reachable signed out. (Buttons onto
            // the stack path: value links in a toolbar don't reliably resolve.)
            .mastheadChrome("Courses", actions: [
                ChromeAction(systemImage: "point.topleft.down.to.point.bottomright.curvepath", label: "Course Map") {
                    router.courses.append(CourseMapRoute())
                },
                ChromeAction(systemImage: "trophy", label: "Hall of Scholars") {
                    router.courses.append(LeaderboardRoute())
                },
            ])
            .searchable(text: $query, prompt: "Search courses & lectures")
            .onChange(of: query) { _, newValue in scheduleSearch(newValue) }
            .task { if courses.isEmpty { await loadCatalog() } }
            .task(id: auth.user?.id) { await loadContinueWatching() }
            // The search field sits on leather: cream, not the crimson accent (which
            // the content above keeps for itself).
            .tint(Theme.onLeather)
    }

    @ViewBuilder private var content: some View {
        if !query.isEmpty {
            searchResults
        } else if loading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.page)
        } else if failed {
            LoadFailedView(title: "Couldn't load courses") { await loadCatalog() }
                .background(Theme.page)
        } else {
            catalog
        }
    }

    private var currentCourses: [CourseListItem] { courses.filter(\.isCurrent) }

    // MARK: catalog (browse)
    @ViewBuilder private var catalog: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Masthead(overlap: continueWatching.isEmpty ? 0 : 40) { mastheadText }

                VStack(alignment: .leading, spacing: 12) {
                    if !continueWatching.isEmpty {
                        continueCarousel.padding(.top, -40)
                    }

                    if !announcements.isEmpty {
                        SectionTitle("Announcements")
                        ForEach(announcements) { AnnouncementCard(announcement: $0) }
                    }

                    if !currentCourses.isEmpty {
                        SectionTitle("Currently Teaching")
                        Codex(dividerInset: 122) { ForEach(currentCourses) { courseLink($0) } }
                    }

                    if !categories.isEmpty {
                        SectionTitle("Browse by Category")
                        Codex(dividerInset: 122) {
                            ForEach(categories) { category in
                                NavigationLink(value: category) { CategoryRow(category: category) }
                                    .buttonStyle(.lyceumRow)
                            }
                        }
                    }

                    SectionTitle("All Courses")
                    Codex(dividerInset: 122) { ForEach(courses) { courseLink($0) } }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .background(Theme.page)
        .refreshable {
            await loadCatalog()
            await loadContinueWatching()
        }
    }

    private var greeting: String {
        guard let name = auth.user?.name?.split(separator: " ").first else { return "Welcome to the Lyceum." }
        let hour = Calendar.current.component(.hour, from: .now)
        let part = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
        return "\(part), \(name)."
    }

    private var mastheadText: some View {
        VStack(alignment: .leading, spacing: 8) {
            GiltEyebrow("The Timpson Lyceum")
            Text(greeting)
                .font(.serif(30, .bold, relativeTo: .largeTitle))
                .foregroundStyle(Theme.onLeather)
                .fixedSize(horizontal: false, vertical: true)
            Text(auth.user == nil
                 ? "Lectures, notes, quizzes, and drills from a real classroom, free."
                 : currentCourses.isEmpty
                    ? "Pick up where you left off, or start something new."
                    : "\(currentCourses.count) course\(currentCourses.count == 1 ? "" : "s") in session this term.")
                .font(.serif(16).italic())
                .foregroundStyle(Theme.onLeatherSoft)
        }
    }

    private var continueCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(continueWatching) { item in
                    if let next = item.nextLecture {
                        NavigationLink(value: LectureRoute(courseId: item.id, videoId: next.id, title: next.title)) {
                            ContinueCard(item: item, next: next)
                        }
                        .buttonStyle(.lyceumPress)
                        .scrollTransition(axis: .horizontal) { view, phase in
                            view.scaleEffect(phase.isIdentity ? 1 : 0.94).opacity(phase.isIdentity ? 1 : 0.8)
                        }
                    }
                }
            }
            .scrollTargetLayout()
            .padding(.vertical, 2)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollClipDisabled()
    }

    private func courseLink(_ course: CourseListItem) -> some View {
        NavigationLink(value: course) { CourseRow(course: course) }.buttonStyle(.lyceumRow)
    }

    // MARK: search (hybrid: instant local filter + server-backed lecture search)
    private var queryLower: String { query.trimmingCharacters(in: .whitespaces).lowercased() }

    private var filteredCourses: [CourseListItem] {
        guard !queryLower.isEmpty else { return [] }
        return courses.filter { $0.title.lowercased().contains(queryLower) }
    }

    private var filteredCategories: [CategoryItem] {
        guard !queryLower.isEmpty else { return [] }
        return categories.filter { $0.name.lowercased().contains(queryLower) }
    }

    @ViewBuilder private var searchResults: some View {
        let courseHits = filteredCourses
        let categoryHits = filteredCategories
        let lectureHits = results?.lectures ?? []

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if !courseHits.isEmpty {
                    SectionTitle("Courses")
                    Codex(dividerInset: 122) {
                        ForEach(courseHits) { course in
                            NavigationLink(value: course) { CourseRow(course: course, highlight: query) }
                                .buttonStyle(.lyceumRow)
                        }
                    }
                }

                if !categoryHits.isEmpty {
                    SectionTitle("Categories")
                    Codex(dividerInset: 122) {
                        ForEach(categoryHits) { category in
                            NavigationLink(value: category) { CategoryRow(category: category, highlight: query) }
                                .buttonStyle(.lyceumRow)
                        }
                    }
                }

                // Deep search across lecture notes/transcripts — needs the server,
                // so it fills in after the instant local results above.
                if searching || !lectureHits.isEmpty {
                    SectionTitle("In Lectures")
                    if searching {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Searching lectures…").font(.ui(14)).foregroundStyle(Theme.inkSoft)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    } else {
                        Codex {
                            ForEach(lectureHits) { hit in
                                NavigationLink(value: hit) { lectureResultRow(hit) }.buttonStyle(.lyceumRow)
                            }
                        }
                    }
                }

                if courseHits.isEmpty && categoryHits.isEmpty && lectureHits.isEmpty && !searching {
                    Text("No results for “\(query)”.")
                        .font(.serif(16)).foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity, alignment: .center).padding(.top, 32)
                }
            }
            .padding()
        }
        .background(Theme.page)
    }

    private func lectureResultRow(_ hit: LectureHit) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(hit.title).font(.serif(17, .semibold)).foregroundStyle(Theme.ink).lineLimit(2)
            HStack(spacing: 6) {
                Text(hit.courseTitle).lineLimit(1)
                if let t = hit.startSeconds {
                    Text("· jump to \(formatDuration(t))").foregroundStyle(Theme.link)
                }
            }
            .font(.ui(13)).foregroundStyle(Theme.inkSoft)
            if let snippet = hit.snippet, !snippet.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Eyebrow("From transcript")
                    Text(highlightedSnippet(snippet)).font(.serif(15)).foregroundStyle(Theme.inkSoft).lineLimit(3)
                }
                .padding(.top, 2)
            }
        }
        .codexRow()
    }

    // The server marks matches with [[hl]]…[[/hl]]; show them in ink, semibold.
    private func highlightedSnippet(_ s: String) -> AttributedString {
        var out = AttributedString()
        var rest = Substring(s)
        while let open = rest.range(of: "[[hl]]") {
            out += AttributedString(String(rest[..<open.lowerBound]))
            rest = rest[open.upperBound...]
            let close = rest.range(of: "[[/hl]]")
            var hit = AttributedString(String(rest[..<(close?.lowerBound ?? rest.endIndex)]))
            hit.foregroundColor = Theme.ink
            hit.font = .serif(15, .semibold)
            out += hit
            rest = close.map { rest[$0.upperBound...] } ?? ""
        }
        out += AttributedString(String(rest))
        return out
    }

    // MARK: data
    private func loadCatalog() async {
        loading = courses.isEmpty
        async let coursesResult: CoursesResponse? = try? await APIClient.shared.get("/courses", auth: false)
        async let categoriesResult: CategoriesResponse? = try? await APIClient.shared.get("/categories", auth: false)
        async let announcementsResult: AnnouncementsResponse? = try? await APIClient.shared.get("/announcements", auth: false)
        let (c, cats, ann) = await (coursesResult, categoriesResult, announcementsResult)
        if let c { courses = c.courses; failed = false } else if courses.isEmpty { failed = true }
        if let cats { categories = cats.categories }
        if let ann { announcements = ann.announcements }
        loading = false
    }

    private func loadContinueWatching() async {
        guard auth.user != nil else { continueWatching = []; return }
        if let p: ProgressResponse = try? await APIClient.shared.get("/me/progress") {
            continueWatching = Array(p.inProgress.filter { $0.nextLecture != nil }.prefix(6))
        }
    }

    private func scheduleSearch(_ raw: String) {
        searchTask?.cancel()
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = nil
            searching = false
            return
        }
        searching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // debounce
            if Task.isCancelled { return }
            await runSearch(trimmed)
        }
    }

    private func runSearch(_ q: String) async {
        let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
        do {
            results = try await APIClient.shared.get("/search?q=\(encoded)", auth: false)
        } catch {
            results = SearchResults(courses: [], lectures: [], fuzzy: nil)
        }
        searching = false
    }
}

// One announcement. Pinned ones get an accent wash and a pin.
struct AnnouncementCard: View {
    let announcement: Announcement
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(announcement.title).font(.serif(18, .semibold)).foregroundStyle(Theme.ink)
                Spacer(minLength: 4)
                if announcement.pinned { Pill("Pinned", tone: .accent) }
            }
            Text(formatDate(announcement.createdAt)).font(.ui(13)).foregroundStyle(Theme.inkSoft)
            ExpandableText(text: announcement.body, lineLimit: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lyceumCard()
        .overlay(alignment: .leading) {
            if announcement.pinned {
                UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 12)
                    .fill(Theme.ornament).frame(width: 4)
            }
        }
    }
}

// Continue Watching: the next unwatched lecture of a course in progress, as a
// poster: the lecture's frame with a play button, then the course and how far along.
struct ContinueCard: View {
    let item: CourseProgressItem
    let next: NextLecture
    static let width: CGFloat = 300

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: next.thumbnailUrl ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Theme.tint)
            }
            .frame(width: Self.width, height: Self.width * 9 / 16)
            .clipped()
            .overlay(alignment: .bottomLeading) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill").font(.system(size: 11, weight: .bold))
                    Text("Up next").font(.ui(12, .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.ultraThinMaterial.opacity(0.9), in: Capsule())
                .environment(\.colorScheme, .dark)
                .padding(10)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title.uppercased())
                    .font(.ui(11, .semibold, relativeTo: .caption)).kerning(0.9)
                    .foregroundStyle(Theme.accentText).lineLimit(1)
                Text(displayTitle(next.title)).font(.serif(16.5, .semibold)).foregroundStyle(Theme.ink)
                    .lineLimit(2, reservesSpace: true).multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    GiltBar(fraction: item.fraction, height: 6)
                    Text("\(item.watchedCount) of \(item.totalCount)").font(.ui(12, .medium)).monospacedDigit()
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize()
                }
            }
            .padding(14)
        }
        .frame(width: Self.width)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.line, lineWidth: 0.75))
        .shadow(color: Color(hex: 0x2a0a0a).opacity(0.18), radius: 14, y: 6)
    }
}

/// "Nov 14, 2026" from an ISO-8601 timestamp.
func formatDate(_ iso: String, time: Bool = false) -> String {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let date = f.date(from: iso) ?? ISO8601DateFormatter().date(from: iso)
    guard let date else { return "" }
    return time
        ? date.formatted(date: .abbreviated, time: .shortened)
        : date.formatted(date: .abbreviated, time: .omitted)
}
