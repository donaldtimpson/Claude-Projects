import SwiftUI

struct LectureRoute: Hashable {
    let courseId: String
    let videoId: String
    let title: String
    /// Start the video here (a transcript search hit's moment).
    var startSeconds: Int? = nil
}

struct SyllabusRoute: Hashable {
    let title: String
    let markdown: String
}

// A course: the web course page. Header with the test and review actions, your
// class (or registration), resources, syllabus, lectures with watched marks,
// problem sets, other offerings, connections, and course announcements.
struct CourseDetailView: View {
    let courseId: String
    @EnvironmentObject private var auth: AuthViewModel
    @State private var course: CourseDetail?
    @State private var announcements: [Announcement] = []
    @State private var failed = false
    @State private var loading = true
    @State private var query = ""

    var body: some View {
        content
            .navigationTitle(course?.shortTitle ?? course?.title ?? "Course")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Filter lectures")
            .task(id: auth.user?.id) { await load() }
    }

    private func filteredVideos(_ course: CourseDetail) -> [VideoListItem] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return course.videos }
        return course.videos.filter { $0.title.lowercased().contains(q) }
    }

    @ViewBuilder private var content: some View {
        if loading && course == nil {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.page)
        } else if let course {
            let videos = filteredVideos(course)
            let watched = Set(course.viewer?.watchedVideoIds ?? [])
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if query.isEmpty {
                        header(course, watchedCount: watched.count)
                        classStatus(course)
                        if !course.resources.isEmpty {
                            SectionTitle("Resources")
                            ForEach(course.resources) { ResourceRow(resource: $0) }
                        }
                        if let syl = course.syllabus, !syl.isEmpty {
                            SectionTitle("Syllabus")
                            NavigationLink(value: SyllabusRoute(title: "Syllabus", markdown: syl)) {
                                LinkRow(icon: "doc.text", title: "Course syllabus",
                                        subtitle: "Grading, policies, and the full schedule")
                            }
                            .buttonStyle(.lyceumPress)
                        }
                    }

                    SectionTitle("Lectures")
                    if course.videos.isEmpty {
                        EmptyNote("No lectures yet. Check back soon.")
                    } else if videos.isEmpty {
                        Text("No lectures match “\(query)”.")
                            .font(.serif(16)).foregroundStyle(Theme.inkSoft).padding(.top, 4)
                    } else {
                        ForEach(videos) { video in
                            NavigationLink(value: LectureRoute(courseId: courseId, videoId: video.id, title: video.title)) {
                                LectureRow(video: video, watched: watched.contains(video.id), highlight: query)
                            }
                            .buttonStyle(.lyceumPress)
                        }
                    }

                    if query.isEmpty {
                        if !course.problemSets.isEmpty {
                            SectionTitle("Problem Sets")
                            ForEach(course.problemSets) { ps in
                                NavigationLink(value: ProblemSetRoute(courseId: courseId, problemSetId: ps.id, title: ps.title)) {
                                    ProblemSetRow(ps: ps)
                                }
                                .buttonStyle(.lyceumPress)
                            }
                        }
                        if let offerings = course.offerings, !offerings.isEmpty {
                            SectionTitle("Other Offerings")
                            ChipFlow(items: offerings.map { o in
                                // The year only when the title doesn't already include it.
                                let label = o.year.map { y in o.title.contains(String(y)) ? o.title : "\(o.title) (\(y))" } ?? o.title
                                return (label, AnyHashable(o))
                            })
                        }
                        if let c = course.connections, !c.isEmpty {
                            connectionGroup("Builds on", c.buildsOn)
                            connectionGroup("Leads to", c.leadsTo)
                            connectionGroup("Related Courses", c.related)
                        }
                        if !announcements.isEmpty {
                            SectionTitle("Announcements")
                            ForEach(announcements) { AnnouncementCard(announcement: $0) }
                        }
                    }
                }
                .padding()
            }
            .background(Theme.page)
            .refreshable { await load() }
        } else if failed {
            LoadFailedView(title: "Couldn't load this course") { await load() }.background(Theme.page)
        }
    }

    @ViewBuilder private func header(_ course: CourseDetail, watchedCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(course.title).font(.serif(26, .bold, relativeTo: .title)).foregroundStyle(Theme.ink)
            HStack(spacing: 6) {
                Text(course.videos.isEmpty ? "Coming soon" : "\(course.videos.count) lecture\(course.videos.count == 1 ? "" : "s")")
                    .foregroundStyle(Theme.inkSoft)
                if watchedCount > 0 {
                    Text("· \(watchedCount) watched").foregroundStyle(Theme.success)
                }
            }
            .font(.ui(14))
            if !course.description.isEmpty { ExpandableText(text: course.description) }

            let test = course.testQuestionCount ?? 0
            let review = course.reviewQuestionCount ?? 0
            if test > 0 || review > 0 {
                VStack(spacing: 10) {
                    if test > 0 {
                        NavigationLink(value: CourseTestRoute(courseId: course.id, title: course.title)) {
                            ButtonLabel(title: "Take the course test (\(test) questions)", primary: true)
                        }
                    }
                    if review > 0 {
                        NavigationLink(value: CourseReviewRoute(courseId: course.id, title: course.title)) {
                            ButtonLabel(title: "Review the course (\(review) questions)", primary: test == 0)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder private func classStatus(_ course: CourseDetail) -> some View {
        if let enr = course.viewer?.enrollment {
            NavigationLink(value: ClassRoute(sectionId: enr.sectionId, sectionName: enr.sectionName, courseTitle: course.title)) {
                LinkRow(icon: "checkmark.seal.fill", iconColor: Theme.success,
                        title: "You're in this class",
                        subtitle: "\(enr.sectionName): your grade and homework")
            }
            .buttonStyle(.lyceumPress)
        } else if course.registrationOpen == true {
            RegisterCard(courseTitle: course.title) { await load() }
        }
    }

    @ViewBuilder private func connectionGroup(_ title: String, _ courses: [CourseRef]) -> some View {
        if !courses.isEmpty {
            SectionTitle(title)
            ChipFlow(items: courses.map { ($0.title, AnyHashable($0)) })
        }
    }

    private func load() async {
        do {
            let res: CourseDetailResponse = try await APIClient.shared.get("/courses/\(courseId)")
            course = res.course
            failed = false
        } catch {
            if course == nil { failed = true }
        }
        loading = false
        if let res: AnnouncementsResponse = try? await APIClient.shared.get("/announcements?courseId=\(courseId)", auth: false) {
            // Site-wide announcements are on the home tab; here, just this course's.
            announcements = res.announcements.filter { $0.courseId == courseId }
        }
    }
}

/// A button-shaped label for a NavigationLink (primary or secondary style).
struct ButtonLabel: View {
    let title: String
    var primary: Bool = true
    var body: some View {
        Text(title)
            .font(.ui(16, .semibold))
            .foregroundStyle(primary ? Theme.onAccent : Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(primary ? Theme.accent : Theme.button)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(primary ? .clear : Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// A tappable card row: icon, title, subtitle, chevron.
struct LinkRow: View {
    let icon: String
    var iconColor: Color = Theme.link
    let title: String
    var subtitle: String? = nil
    var external: Bool = false
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.ui(20)).foregroundStyle(iconColor).frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.serif(17, .semibold)).foregroundStyle(Theme.ink).multilineTextAlignment(.leading)
                if let subtitle {
                    Text(subtitle).font(.ui(13)).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.leading)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: external ? "arrow.up.right" : "chevron.right")
                .font(.ui(14, .semibold)).foregroundStyle(Theme.inkSoft)
        }
        .lyceumCard(padding: 14)
    }
}

struct ResourceRow: View {
    let resource: CourseResourceItem
    var body: some View {
        if let url = URL(string: resource.url) {
            Link(destination: url) {
                LinkRow(icon: icon, title: resource.title, subtitle: kindLabel, external: true)
            }
            .buttonStyle(.lyceumPress)
        }
    }
    private var kindLabel: String {
        switch resource.kind {
        case "TEXTBOOK": "Textbook"
        case "SLIDES": "Slides"
        case "PROBLEM_SET": "Problem set"
        case "TOOL": "Tool / applet"
        case "VIDEO": "Video"
        case "DOCUMENT": "Document"
        default: "Link"
        }
    }
    private var icon: String {
        switch resource.kind {
        case "TEXTBOOK": "book.closed"
        case "SLIDES": "rectangle.on.rectangle"
        case "PROBLEM_SET": "pencil.and.list.clipboard"
        case "TOOL": "function"
        case "VIDEO": "play.rectangle"
        case "DOCUMENT": "doc"
        default: "link"
        }
    }
}

struct ProblemSetRow: View {
    let ps: ProblemSetItem
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(ps.title).font(.serif(17, .semibold)).foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                    if ps.isTest == true { Pill("Test") }
                }
                // Same subtitle as the web card: lecture span · solutions · points.
                let bits = [
                    ps.lectureSpan,
                    (ps.hasSolutions ?? false) ? "worked solutions" : nil,
                    ps.points > 0 ? "\(ps.points) pts" : nil,
                ].compactMap { $0 }
                if !bits.isEmpty {
                    Text(bits.joined(separator: " · ")).font(.ui(13)).foregroundStyle(Theme.inkSoft)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.ui(14, .semibold)).foregroundStyle(Theme.inkSoft)
        }
        .lyceumCard(padding: 14)
    }
}

/// Wrapping row of course chips that push their value.
struct ChipFlow: View {
    let items: [(String, AnyHashable)]
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(items.indices, id: \.self) { i in
                NavigationLink(value: items[i].1) {
                    Text(items[i].0)
                        .font(.ui(14, .medium))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Theme.field)
                        .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// "Taking this class for a grade?" Register with the class code; signed out,
/// it offers sign-in first. Registration never gates the materials.
struct RegisterCard: View {
    let courseTitle: String
    let onRegistered: () async -> Void
    @EnvironmentObject private var auth: AuthViewModel
    @State private var code = ""
    @State private var busy = false
    @State private var message: String?
    @State private var success = false
    @State private var showAuth = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Taking this class for a grade?").font(.serif(17, .semibold)).foregroundStyle(Theme.ink)
            Text("Register with the class code from your teacher to see your grade and turn in homework.")
                .font(.serif(15)).foregroundStyle(Theme.inkSoft)
            if auth.user == nil {
                Button("Sign in to register") { showAuth = true }
                    .font(.ui(15, .semibold)).foregroundStyle(Theme.link)
            } else {
                HStack(spacing: 8) {
                    TextField("Class code", text: $code)
                        .font(.ui(17, .semibold))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(Theme.field)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Button {
                        Task { await register() }
                    } label: {
                        Group {
                            if busy { ProgressView().tint(Theme.onAccent) } else { Text("Register") }
                        }
                        .font(.ui(16, .semibold))
                        .foregroundStyle(Theme.onAccent)
                        .padding(.horizontal, 16).padding(.vertical, 11)
                        .background(code.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.strongLine : Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(busy || code.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            if let message {
                Text(message).font(.ui(14)).foregroundStyle(success ? Theme.success : Theme.danger)
            }
        }
        .lyceumCard()
        .sheet(isPresented: $showAuth) { AuthSheet(reason: "Sign in to register for \(courseTitle).") }
    }

    private func register() async {
        busy = true
        defer { busy = false }
        struct Body: Encodable { let code: String }
        do {
            let res: RegisterResponse = try await APIClient.shared.post("/me/classes/register", body: Body(code: code))
            success = true
            message = "You're registered for \(res.sectionName)."
            await onRegistered()
        } catch let e as APIError {
            success = false
            message = e.message
        } catch {
            success = false
            message = "Couldn't reach the server. Try again."
        }
    }
}

/// Full syllabus screen — renders the course's Markdown syllabus (grading,
/// policies, schedule) with the shared math/markdown web renderer.
struct SyllabusView: View {
    let title: String
    let markdown: String
    @State private var webHeight: CGFloat = 200

    var body: some View {
        ScrollView {
            MathWebView(markdown: markdown, height: $webHeight)
                .frame(height: webHeight)
                .padding()
        }
        .background(Theme.page)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}


/// Route to a course's whole-course test.
struct CourseTestRoute: Hashable {
    let courseId: String
    let title: String
}
