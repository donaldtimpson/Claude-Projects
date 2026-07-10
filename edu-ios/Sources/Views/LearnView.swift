import SwiftUI

struct LearnView: View {
    @State private var courses: [CourseListItem] = []
    @State private var error: String?
    @State private var loading = true

    var body: some View {
        content
            .navigationTitle("The Lyceum")
            .navigationDestination(for: CourseListItem.self) { CourseDetailView(courseId: $0.id) }
            .task { if courses.isEmpty { await load() } }
            .refreshable { await load() }
    }

    @ViewBuilder private var content: some View {
        if loading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.parchment)
        } else if let error {
            ContentUnavailableView("Couldn't load courses", systemImage: "wifi.slash",
                                   description: Text(error))
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
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
        loading = courses.isEmpty
        do {
            let res: CoursesResponse = try await APIClient.shared.get("/courses", auth: false)
            courses = res.courses
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

private struct CourseRow: View {
    let course: CourseListItem

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: course.thumbnailUrl)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Theme.parchmentDeep)
            }
            .frame(width: 96, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(course.title).font(.headline).foregroundStyle(Theme.ink).lineLimit(2)
                Text("\(course.videoCount) lectures").font(.subheadline).foregroundStyle(Theme.inkSoft)
                if course.isCurrent {
                    Text("Current course")
                        .font(.caption).fontWeight(.bold).foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Theme.crimson).clipShape(Capsule())
                }
            }
            Spacer(minLength: 0)
        }
        .lyceumCard()
    }
}
