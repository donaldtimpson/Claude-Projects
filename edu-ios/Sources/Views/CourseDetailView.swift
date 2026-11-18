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
            .mastheadChrome(course?.shortTitle ?? course?.title ?? "Course")
            .task(id: auth.user?.id) { await load() }
    }

    private func filteredVideos(_ course: CourseDetail) -> [VideoListItem] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return course.videos }
        return course.videos.filter { $0.title.lowercased().contains(q) }
    }

    @ViewBuilder private var content: some View {
        if loading && course == nil {
            LoadingLeather()
        } else if let course {
            let watched = Set(course.viewer?.watchedVideoIds ?? [])
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    CoverHero(imageURL: course.videos.isEmpty ? nil : course.thumbnailUrl, overlap: hasLead(course) ? 40 : 0) {
                        heroText(course, watchedCount: watched.count)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        if hasLead(course) { lead(course).padding(.top, -40) }
                        classStatus(course)

                        if course.syllabus?.isEmpty == false || !course.resources.isEmpty {
                            SectionTitle("Materials")
                            Codex(dividerInset: 62) {
                                if let syl = course.syllabus, !syl.isEmpty {
                                    NavigationLink(value: SyllabusRoute(title: "Syllabus", markdown: syl)) {
                                        LinkRow(icon: "scroll", title: "Course syllabus",
                                                subtitle: "Grading, policies, and the full schedule")
                                    }
                                    .buttonStyle(.lyceumRow)
                                }
                                ForEach(course.resources) { ResourceRow(resource: $0) }
                            }
                        }

                        lectures(course, watched: watched)

                        if !course.problemSets.isEmpty {
                            SectionTitle("Problem Sets")
                            Codex {
                                ForEach(course.problemSets) { ps in
                                    NavigationLink(value: ProblemSetRoute(courseId: courseId, problemSetId: ps.id, title: ps.title)) {
                                        ProblemSetRow(ps: ps)
                                    }
                                    .buttonStyle(.lyceumRow)
                                }
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
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .ignoresSafeArea(.container, edges: .top)
            .background(Theme.page)
            .refreshable { await load() }
        } else if failed {
            LoadFailedView(title: "Couldn't load this course") { await load() }.background(Theme.page)
        }
    }

    private func hasLead(_ course: CourseDetail) -> Bool {
        !course.description.isEmpty || (course.testQuestionCount ?? 0) > 0 || (course.reviewQuestionCount ?? 0) > 0
    }

    @ViewBuilder private func heroText(_ course: CourseDetail, watchedCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if course.isCurrent {
                GiltEyebrow("In session")
            }
            Text(course.title).font(.serif(28, .bold, relativeTo: .title)).foregroundStyle(Theme.onLeather)
                .fixedSize(horizontal: false, vertical: true)
            let n = course.videos.count
            HStack(spacing: 10) {
                Text(n == 0 ? "Coming soon" : watchedCount > 0 ? "\(watchedCount) of \(n) lectures watched" : "\(n) lecture\(n == 1 ? "" : "s")")
                    .font(.ui(14, .medium)).foregroundStyle(Theme.onLeatherSoft)
                    .fixedSize()
                if watchedCount > 0 && n > 0 {
                    GiltBar(fraction: Double(watchedCount) / Double(n), height: 6, onLeather: true)
                }
            }
        }
    }

    /// The card that overlaps the hero: what the course is, and its whole-course actions.
    private func lead(_ course: CourseDetail) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if !course.description.isEmpty { ExpandableText(text: course.description) }
            let test = course.testQuestionCount ?? 0
            let review = course.reviewQuestionCount ?? 0
            if test > 0 || review > 0 {
                VStack(spacing: 10) {
                    if test > 0 {
                        NavigationLink(value: CourseTestRoute(courseId: course.id, title: course.title)) {
                            ButtonLabel(title: "Take the course test · \(test) questions", primary: true)
                        }
                        .buttonStyle(.lyceumPress(cornerRadius: 12))
                    }
                    if review > 0 {
                        NavigationLink(value: CourseReviewRoute(courseId: course.id, title: course.title)) {
                            ButtonLabel(title: "Review the course · \(review) questions", primary: test == 0)
                        }
                        .buttonStyle(.lyceumPress(cornerRadius: 12))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lyceumCard(padding: 18)
        .shadow(color: Color(hex: 0x2a0a0a).opacity(0.14), radius: 14, y: 6)
    }

    @ViewBuilder private func lectures(_ course: CourseDetail, watched: Set<String>) -> some View {
        let videos = filteredVideos(course)
        SectionTitle("Lectures")
        if course.videos.isEmpty {
            EmptyNote("No lectures yet. Check back soon.")
        } else {
            if course.videos.count > 6 {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Theme.inkSoft)
                    TextField("Filter lectures", text: $query)
                        .font(.ui(16))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !query.isEmpty {
                        Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                            .foregroundStyle(Theme.inkSoft)
                            .accessibilityLabel("Clear filter")
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(Capsule().fill(Theme.tint))
            }
            if videos.isEmpty {
                Text("No lectures match “\(query)”.")
                    .font(.serif(16)).foregroundStyle(Theme.inkSoft).padding(.top, 4)
            } else {
                Codex(dividerInset: 122) {
                    ForEach(videos) { video in
                        NavigationLink(value: LectureRoute(courseId: courseId, videoId: video.id, title: video.title)) {
                            LectureRow(video: video, watched: watched.contains(video.id), highlight: query)
                        }
                        .buttonStyle(.lyceumRow)
                    }
                }
            }
        }
    }

    @ViewBuilder private func classStatus(_ course: CourseDetail) -> some View {
        if let enr = course.viewer?.enrollment {
            Codex {
                NavigationLink(value: ClassRoute(sectionId: enr.sectionId, sectionName: enr.sectionName, courseTitle: course.title)) {
                    LinkRow(icon: "checkmark.seal.fill",
                            title: "You're in this class",
                            subtitle: "\(enr.sectionName): your grade and homework")
                }
                .buttonStyle(.lyceumRow)
            }
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
            .padding(.vertical, 14)
            .background {
                if primary {
                    AccentFill()
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.button)
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.strongLine.opacity(0.7), lineWidth: 1))
                }
            }
    }
}

/// A tappable card row: icon, title, subtitle, chevron.
/// A row that opens something, marked with the app's leather medallion like every
/// other row icon.
struct LinkRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var external: Bool = false
    var body: some View {
        HStack(spacing: 12) {
            Medallion(systemImage: icon, size: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.serif(17, .semibold)).foregroundStyle(Theme.ink).multilineTextAlignment(.leading)
                if let subtitle {
                    Text(subtitle).font(.ui(13)).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.leading)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: external ? "arrow.up.right" : "chevron.right")
                .font(.ui(13, .semibold)).foregroundStyle(Theme.inkSoft.opacity(0.6))
        }
        .codexRow()
    }
}

struct ResourceRow: View {
    let resource: CourseResourceItem
    var body: some View {
        if let url = URL(string: resource.url) {
            Link(destination: url) {
                LinkRow(icon: icon, title: resource.title, subtitle: kindLabel, external: true)
            }
            .buttonStyle(.lyceumRow)
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
            Image(systemName: "chevron.right").font(.ui(13, .semibold)).foregroundStyle(Theme.inkSoft.opacity(0.6))
        }
        .codexRow()
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
                        let ready = !code.trimmingCharacters(in: .whitespaces).isEmpty
                        Group {
                            if busy { ProgressView().tint(Theme.onAccent) } else { Text("Register") }
                        }
                        .font(.ui(16, .semibold))
                        // Disabled reads like PrimaryButton's: a quiet tint, not a dimmer accent.
                        .foregroundStyle(ready ? Theme.onAccent : Theme.inkSoft.opacity(0.8))
                        .padding(.horizontal, 16).padding(.vertical, 11)
                        .background {
                            if ready { AccentFill(cornerRadius: 10) } else {
                                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.tint)
                            }
                        }
                    }
                    .disabled(busy || code.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            if let message {
                Text(message).font(.ui(14)).foregroundStyle(success ? Theme.success : Theme.danger)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .leatherBar(title)
    }
}


/// Route to a course's whole-course test.
struct CourseTestRoute: Hashable {
    let courseId: String
    let title: String
}
