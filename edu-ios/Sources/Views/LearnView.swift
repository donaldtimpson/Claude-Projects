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
            .navigationTitle("The Lyceum")
            .searchable(text: $query, prompt: "Search courses & lectures")
            .onChange(of: query) { _, newValue in scheduleSearch(newValue) }
            .navigationDestination(for: CourseListItem.self) { CourseDetailView(courseId: $0.id) }
            .navigationDestination(for: CourseHit.self) { CourseDetailView(courseId: $0.id) }
            .navigationDestination(for: CategoryItem.self) { CategoryView(category: $0) }
            .navigationDestination(for: LectureHit.self) { hit in
                LectureView(route: LectureRoute(courseId: hit.courseId, videoId: hit.videoId, title: hit.title))
            }
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
                        NavigationLink(value: category) {
                            HStack {
                                Text(category.name).font(.display(15)).kerning(0.5).foregroundStyle(Theme.ink)
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right").foregroundStyle(Theme.gold400)
                            }
                            .lyceumCard()
                        }
                        .buttonStyle(.plain)
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
        NavigationLink(value: course) { CourseRow(course: course) }.buttonStyle(.plain)
    }

    // MARK: search
    @ViewBuilder private var searchResults: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if searching {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 24)
                } else if let results {
                    if results.fuzzy == true {
                        Text("No exact matches — showing similar results.")
                            .font(.serif(14)).foregroundStyle(Theme.inkSoft)
                    }
                    if results.courses.isEmpty && results.lectures.isEmpty {
                        Text("No results for “\(query)”.")
                            .font(.serif(16)).foregroundStyle(Theme.inkSoft)
                            .frame(maxWidth: .infinity, alignment: .center).padding(.top, 32)
                    }
                    if !results.courses.isEmpty {
                        SectionHeader(title: "Courses")
                        ForEach(results.courses) { hit in
                            NavigationLink(value: hit) {
                                HStack(spacing: 12) {
                                    Thumb(url: hit.thumbnailUrl)
                                    Text(hit.title).font(.display(15)).kerning(0.5)
                                        .foregroundStyle(Theme.ink).lineLimit(2)
                                    Spacer(minLength: 0)
                                }
                                .lyceumCard()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if !results.lectures.isEmpty {
                        SectionHeader(title: "Lectures")
                        ForEach(results.lectures) { hit in
                            NavigationLink(value: hit) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(hit.title).font(.display(14)).kerning(0.3)
                                        .foregroundStyle(Theme.ink).lineLimit(2)
                                    Text(hit.courseTitle).font(.serif(13)).foregroundStyle(Theme.gold400)
                                    if let snippet = hit.snippet, !snippet.isEmpty {
                                        Text(cleanSnippet(snippet))
                                            .font(.serif(14)).foregroundStyle(Theme.inkSoft).lineLimit(3)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lyceumCard()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.parchment)
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
