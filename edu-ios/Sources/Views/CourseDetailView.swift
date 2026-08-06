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
            .navigationTitle(course?.shortTitle ?? course?.title ?? "Course")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Filter lectures")
            .navigationDestination(for: LectureRoute.self) { LectureView(route: $0) }
            .navigationDestination(for: ProblemSetRoute.self) { ProblemSetView(route: $0) }
            .navigationDestination(for: CourseOffering.self) { CourseDetailView(courseId: $0.id) }
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
                            .buttonStyle(.lyceumPress)
                        }
                    }

                    // Problem sets sit below the lectures, like the web course page.
                    if query.isEmpty, !course.problemSets.isEmpty {
                        SectionHeader(title: "Problem Sets")
                        ForEach(course.problemSets) { ps in
                            NavigationLink(value: ProblemSetRoute(
                                courseId: courseId, problemSetId: ps.id, title: ps.title)
                            ) {
                                problemSetRow(ps)
                            }
                            .buttonStyle(.lyceumPress)
                        }
                    }

                    if query.isEmpty, let offerings = course.offerings, !offerings.isEmpty {
                        SectionHeader(title: "Other Offerings")
                        ForEach(offerings) { offering in
                            NavigationLink(value: offering) { offeringRow(offering) }
                                .buttonStyle(.lyceumPress)
                        }
                    }
                }
                .padding()
            }
            .background(Theme.parchment)
        }
    }

    private func problemSetRow(_ ps: ProblemSetItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(ps.title).font(.display(15)).kerning(0.5).foregroundStyle(Theme.ink).lineLimit(2)
                // Same subtitle as the web card: lecture span · solutions · points.
                let bits = [
                    ps.lectureSpan,
                    (ps.hasSolutions ?? false) ? "worked solutions" : nil,
                    ps.points > 0 ? "\(ps.points) pts" : nil,
                ].compactMap { $0 }
                if !bits.isEmpty {
                    Text(bits.joined(separator: " · "))
                        .font(.serif(13)).foregroundStyle(Theme.inkSoft)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").foregroundStyle(Theme.gold400)
        }
        .lyceumCard()
    }

    private func offeringRow(_ offering: CourseOffering) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(offering.title).font(.display(15)).kerning(0.5).foregroundStyle(Theme.ink).lineLimit(2)
                // Show the year only when the title doesn't already include it.
                if let year = offering.year, !offering.title.contains(String(year)) {
                    Text(String(year)).font(.serif(14)).foregroundStyle(Theme.inkSoft)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").foregroundStyle(Theme.gold400)
        }
        .lyceumCard()
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
