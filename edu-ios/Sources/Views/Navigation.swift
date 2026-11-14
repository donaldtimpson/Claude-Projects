import SwiftUI

// One place for navigation: the tabs, each tab's stack, every route type the app
// pushes, and deep links.
//
// Every destination is registered once, at the root of each tab's stack, via
// `.lyceumDestinations()`. Any screen can then push any route by value (a course
// page linking to a lecture, a lecture to a problem set, a problem set to its
// homework) without each screen re-registering what it can reach.

struct CourseRoute: Hashable {
    let courseId: String
}

struct CourseReviewRoute: Hashable {
    let courseId: String
    let title: String
}

struct ScholarRoute: Hashable {
    let handle: String
}

struct SettingsRoute: Hashable {}

enum AppTab: Hashable {
    case courses, review, drills, progress
}

@MainActor
final class Router: ObservableObject {
    @Published var tab: AppTab = .courses
    @Published var courses = NavigationPath()
    @Published var review = NavigationPath()
    @Published var drills = NavigationPath()
    @Published var progress = NavigationPath()

    /// Opens a link to the site or the app's own scheme, mirroring the web's paths:
    ///   /courses/{id}, /courses/{id}/{videoId}, /courses/{id}/problems/{psId},
    ///   /courses/{id}/test, /courses/{id}/review, /dashboard, /dashboard/class/{id},
    ///   /review, /drills, /leaderboard, /leaderboard/{handle}
    /// Accepts lyceum://courses/… (host = first segment) and https://…/courses/….
    func open(_ url: URL) {
        var parts = url.pathComponents.filter { $0 != "/" }
        if url.scheme == "lyceum", let host = url.host() { parts.insert(host, at: 0) }
        guard let head = parts.first else { return }

        switch head {
        case "courses":
            guard parts.count >= 2 else { tab = .courses; courses = NavigationPath(); return }
            let courseId = parts[1]
            var path = NavigationPath()
            path.append(CourseRoute(courseId: courseId))
            if parts.count >= 4, parts[2] == "problems" {
                path.append(ProblemSetRoute(courseId: courseId, problemSetId: parts[3], title: "Problem set"))
            } else if parts.count >= 3, parts[2] == "test" {
                path.append(CourseTestRoute(courseId: courseId, title: "Course Test"))
            } else if parts.count >= 3, parts[2] == "review" {
                path.append(CourseReviewRoute(courseId: courseId, title: "Course Review"))
            } else if parts.count >= 3 {
                path.append(LectureRoute(courseId: courseId, videoId: parts[2], title: "Lecture"))
            }
            tab = .courses
            courses = path
        case "dashboard":
            var path = NavigationPath()
            if parts.count >= 3, parts[1] == "class" {
                path.append(ClassRoute(sectionId: parts[2], sectionName: "Class", courseTitle: ""))
            }
            tab = .progress
            progress = path
        case "review":
            tab = .review
        case "drills":
            tab = .drills
        case "leaderboard":
            var path = NavigationPath()
            path.append(LeaderboardRoute())
            if parts.count >= 2 { path.append(ScholarRoute(handle: parts[1])) }
            tab = .courses
            courses = path
        case "settings":
            var path = NavigationPath()
            path.append(SettingsRoute())
            tab = .progress
            progress = path
        default:
            break
        }
    }
}

struct LeaderboardRoute: Hashable {}
struct CourseMapRoute: Hashable {}

extension View {
    /// Registers every route the app can push. Apply once at the root of each tab's stack.
    func lyceumDestinations() -> some View {
        self
            .navigationDestination(for: CourseRoute.self) { CourseDetailView(courseId: $0.courseId) }
            .navigationDestination(for: CourseListItem.self) { CourseDetailView(courseId: $0.id) }
            .navigationDestination(for: CourseHit.self) { CourseDetailView(courseId: $0.id) }
            .navigationDestination(for: CourseRef.self) { CourseDetailView(courseId: $0.id) }
            .navigationDestination(for: CourseOffering.self) { CourseDetailView(courseId: $0.id) }
            .navigationDestination(for: CategoryItem.self) { CategoryView(category: $0) }
            .navigationDestination(for: LectureRoute.self) { LectureView(route: $0) }
            .navigationDestination(for: LectureHit.self) { hit in
                LectureView(route: LectureRoute(courseId: hit.courseId, videoId: hit.videoId, title: hit.title,
                                                startSeconds: hit.startSeconds))
            }
            .navigationDestination(for: ProblemSetRoute.self) { ProblemSetView(route: $0) }
            .navigationDestination(for: CourseTestRoute.self) {
                CourseTestView(courseId: $0.courseId, courseTitle: $0.title)
            }
            .navigationDestination(for: CourseReviewRoute.self) { CourseReviewView(route: $0) }
            .navigationDestination(for: SyllabusRoute.self) { SyllabusView(title: $0.title, markdown: $0.markdown) }
            .navigationDestination(for: ClassRoute.self) { ClassHubView(route: $0) }
            .navigationDestination(for: AssignmentRoute.self) { AssignmentDetailView(route: $0) }
            .navigationDestination(for: LeaderboardRoute.self) { _ in ScholarsView() }
            .navigationDestination(for: ScholarRoute.self) { ScholarProfileView(handle: $0.handle) }
            .navigationDestination(for: CourseMapRoute.self) { _ in CourseMapView() }
            .navigationDestination(for: SettingsRoute.self) { _ in SettingsView() }
    }
}
