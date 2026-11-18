import SwiftUI

struct CategoryView: View {
    let category: CategoryItem
    @State private var courses: [CourseListItem] = []
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        content
            .mastheadChrome(category.name)
            .task { if courses.isEmpty { await load() } }
    }

    @ViewBuilder private var content: some View {
        if loading {
            LoadingLeather()
        } else if let error {
            ContentUnavailableView("Couldn't load", systemImage: "wifi.slash", description: Text(error))
        } else if courses.isEmpty {
            Text("No courses in this category yet.")
                .font(.serif(16)).foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.parchment)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    CoverHero(imageURL: AppConfig.assetURL("/categories/\(category.slug).png")?.absoluteString, overlap: 0) {
                        VStack(alignment: .leading, spacing: 6) {
                            GiltEyebrow("Category")
                            Text(category.name).font(.serif(30, .bold, relativeTo: .largeTitle))
                                .foregroundStyle(Theme.onLeather)
                            Text("\(courses.count) course\(courses.count == 1 ? "" : "s")")
                                .font(.ui(14, .medium)).foregroundStyle(Theme.onLeatherSoft)
                        }
                    }
                    Codex(dividerInset: 122) {
                        ForEach(courses) { course in
                            NavigationLink(value: course) { CourseRow(course: course) }
                                .buttonStyle(.lyceumRow)
                        }
                    }
                    .padding()
                }
            }
            .ignoresSafeArea(.container, edges: .top)
            .background(Theme.page)
        }
    }

    private func load() async {
        do {
            let res: CategoryDetailResponse = try await APIClient.shared.get(
                "/categories/\(category.slug)", auth: false)
            courses = res.courses
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
