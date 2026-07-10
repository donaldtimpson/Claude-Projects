import SwiftUI

struct LectureRoute: Hashable {
    let courseId: String
    let videoId: String
    let title: String
}

struct CourseDetailView: View {
    let courseId: String
    @State private var course: CourseDetail?
    @State private var error: String?
    @State private var loading = true

    var body: some View {
        content
            .navigationTitle(course?.title ?? "Course")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: LectureRoute.self) { LectureView(route: $0) }
            .task { if course == nil { await load() } }
    }

    @ViewBuilder private var content: some View {
        if loading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.parchment)
        } else if let error {
            ContentUnavailableView("Couldn't load", systemImage: "wifi.slash", description: Text(error))
        } else if let course {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if !course.description.isEmpty {
                        Text(course.description).foregroundStyle(Theme.ink)
                    }
                    Text("\(course.videos.count) lectures")
                        .font(.subheadline).foregroundStyle(Theme.inkSoft)

                    ForEach(course.videos) { video in
                        NavigationLink(value: LectureRoute(courseId: courseId, videoId: video.id, title: video.title)) {
                            HStack(spacing: 12) {
                                Text("\(video.position)")
                                    .font(.headline).foregroundStyle(Theme.gold).frame(width: 28)
                                Text(video.title).foregroundStyle(Theme.ink).lineLimit(2)
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
                            }
                            .lyceumCard()
                        }
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
            let res: CourseDetailResponse = try await APIClient.shared.get("/courses/\(courseId)", auth: false)
            course = res.course
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
