import SwiftUI

struct CategoryView: View {
    let category: CategoryItem
    @State private var courses: [CourseListItem] = []
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        ZStack(alignment: .top) {
            Theme.parchment.ignoresSafeArea()
            backdrop
            content
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { if courses.isEmpty { await load() } }
    }

    // Faded category artwork behind the list (echoes the web category page).
    private var backdrop: some View {
        AsyncImage(url: AppConfig.assetURL("/categories/\(category.slug).png")) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Color.clear
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
        .clipped()
        .opacity(0.20)
        .overlay(
            LinearGradient(colors: [.clear, Theme.parchment], startPoint: .top, endPoint: .bottom)
        )
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }

    @ViewBuilder private var content: some View {
        if loading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error {
            ContentUnavailableView("Couldn't load", systemImage: "wifi.slash", description: Text(error))
        } else if courses.isEmpty {
            Text("No courses in this category yet.")
                .font(.serif(16)).foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
