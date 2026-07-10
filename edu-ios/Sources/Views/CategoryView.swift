import SwiftUI

struct CategoryView: View {
    let category: CategoryItem
    @State private var courses: [CourseListItem] = []
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        content
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .task { if courses.isEmpty { await load() } }
    }

    @ViewBuilder private var content: some View {
        if loading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.parchment)
        } else if let error {
            ContentUnavailableView("Couldn't load", systemImage: "wifi.slash", description: Text(error))
        } else if courses.isEmpty {
            Text("No courses in this category yet.")
                .font(.serif(16)).foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.parchment)
        } else {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(courses) { course in
                        NavigationLink(value: course) { CourseRow(course: course) }
                            .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Theme.parchment)
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
