import SwiftUI

struct LearnView: View {
    @State private var courses: [CourseListItem] = []
    @State private var categories: [CategoryItem] = []
    @State private var loading = true
    @State private var error: String?

    @State private var query = ""
    @State private var results: SearchResults?
    @State private var searching = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        content
            // The catalog is "Courses" on the web; it was "Learn" in the tab bar and
            // "Timpson Lyceum" in the title bar here — three names for one screen. The
            // wordmark still opens the app on the splash.
            .navigationTitle("Courses")
            .navigationBarTitleDisplayMode(.inline)
            // The board is public and the web keeps it in the always-available nav
            // drawer. There's no drawer here, so it hangs off the home tab — reachable
            // signed out, which matters because My Progress is the sign-in form then.
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { CourseMapView() } label: {
                        Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    }
                    .tint(Theme.gold400)
                    .accessibilityLabel("Course Map")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { ScholarsView() } label: {
                        Image(systemName: "trophy")
                    }
                    .tint(Theme.gold400)
                    .accessibilityLabel("Hall of Scholars")
                }
            }
            .searchable(text: $query, prompt: "Search courses & lectures")
            .onChange(of: query) { _, newValue in scheduleSearch(newValue) }
            .navigationDestination(for: CourseListItem.self) { CourseDetailView(courseId: $0.id) }
            .navigationDestination(for: CourseHit.self) { CourseDetailView(courseId: $0.id) }
            .navigationDestination(for: CategoryItem.self) { CategoryView(category: $0) }
            .navigationDestination(for: MapCourseRoute.self) { CourseDetailView(courseId: $0.id) }
            .navigationDestination(for: LectureHit.self) { hit in
                LectureView(route: LectureRoute(courseId: hit.courseId, videoId: hit.videoId, title: hit.title))
            }
            // A search hit pushes a lecture straight onto THIS stack, so the routes
            // reachable from there (Practice -> problem set -> its Covers lectures)
            // must be registered here too, not only on CourseDetailView.
            .navigationDestination(for: LectureRoute.self) { LectureView(route: $0) }
            .navigationDestination(for: ProblemSetRoute.self) { ProblemSetView(route: $0) }
            .task { if courses.isEmpty { await loadCatalog() } }
    }

    @ViewBuilder private var content: some View {
        if !query.isEmpty {
            searchResults
        } else if loading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.parchment)
        } else if let error {
            ContentUnavailableView("Couldn't load courses", systemImage: "wifi.slash", description: Text(error))
        } else {
            catalog
        }
    }

    private var currentCourses: [CourseListItem] { courses.filter(\.isCurrent) }

    // MARK: catalog (browse)
    @ViewBuilder private var catalog: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if !currentCourses.isEmpty {
                    SectionHeader(title: "Currently Teaching")
                    ForEach(currentCourses) { courseLink($0) }
                }

                if !categories.isEmpty {
                    SectionHeader(title: "Browse by Category")
                    ForEach(categories) { category in
                        NavigationLink(value: category) { CategoryRow(category: category) }
                            .buttonStyle(.lyceumPress)
                    }
                }

                SectionHeader(title: "All Courses")
                ForEach(courses) { courseLink($0) }
            }
            .padding()
        }
        .background(Theme.parchment)
        .refreshable { await loadCatalog() }
    }

    private func courseLink(_ course: CourseListItem) -> some View {
        NavigationLink(value: course) { CourseRow(course: course) }.buttonStyle(.lyceumPress)
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
                    SectionHeader(title: "Courses")
                    ForEach(courseHits) { course in
                        NavigationLink(value: course) { CourseRow(course: course, highlight: query) }
                            .buttonStyle(.lyceumPress)
                    }
                }

                if !categoryHits.isEmpty {
                    SectionHeader(title: "Categories")
                    ForEach(categoryHits) { category in
                        NavigationLink(value: category) { CategoryRow(category: category, highlight: query) }
                            .buttonStyle(.lyceumPress)
                    }
                }

                // Deep search across lecture notes/transcripts — needs the server,
                // so it fills in after the instant local results above.
                if searching || !lectureHits.isEmpty {
                    SectionHeader(title: "In Lectures")
                    if searching {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Searching lectures…").font(.serif(14)).foregroundStyle(Theme.inkSoft)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    } else {
                        ForEach(lectureHits) { hit in
                            NavigationLink(value: hit) { lectureResultRow(hit) }.buttonStyle(.lyceumPress)
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
        .background(Theme.parchment)
    }

    private func lectureResultRow(_ hit: LectureHit) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(hit.title).font(.display(14)).kerning(0.3).foregroundStyle(Theme.ink).lineLimit(2)
            Text(hit.courseTitle).font(.serif(13)).foregroundStyle(Theme.gold400)
            if let snippet = hit.snippet, !snippet.isEmpty {
                Text(cleanSnippet(snippet)).font(.serif(14)).foregroundStyle(Theme.inkSoft).lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lyceumCard()
    }

    private func cleanSnippet(_ s: String) -> String {
        s.replacingOccurrences(of: "[[hl]]", with: "").replacingOccurrences(of: "[[/hl]]", with: "")
    }

    // MARK: data
    private func loadCatalog() async {
        loading = courses.isEmpty
        async let coursesResult: CoursesResponse? = try? await APIClient.shared.get("/courses", auth: false)
        async let categoriesResult: CategoriesResponse? = try? await APIClient.shared.get("/categories", auth: false)
        let c = await coursesResult
        let cats = await categoriesResult
        if let c { courses = c.courses; error = nil } else if courses.isEmpty { error = "Couldn't reach the server." }
        categories = cats?.categories ?? []
        loading = false
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
