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
    @State private var query = ""

    var body: some View {
        content
            .navigationTitle(course?.title ?? "Course")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Filter lectures")
            .navigationDestination(for: LectureRoute.self) { LectureView(route: $0) }
            .task { if course == nil { await load() } }
    }

    private func filteredVideos(_ course: CourseDetail) -> [VideoListItem] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return course.videos }
        return course.videos.filter { $0.title.lowercased().contains(q) }
    }

    @ViewBuilder private var content: some View {
        if loading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.parchment)
        } else if let error {
            ContentUnavailableView("Couldn't load", systemImage: "wifi.slash", description: Text(error))
        } else if let course {
            let videos = filteredVideos(course)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // Hide the description while filtering to keep results focused.
                    if query.isEmpty, !course.description.isEmpty {
                        ExpandableText(text: course.description)
                    }

                    SectionHeader(title: "Lectures")

                    if videos.isEmpty {
                        Text("No lectures match “\(query)”.")
                            .font(.serif(15)).foregroundStyle(Theme.inkSoft).padding(.top, 8)
                    } else {
                        ForEach(videos) { video in
                            NavigationLink(value: LectureRoute(courseId: courseId, videoId: video.id, title: video.title)) {
                                LectureRow(video: video, highlight: query)
                            }
                            .buttonStyle(.plain)
                        }
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
