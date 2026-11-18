import XCTest

// A design-review tour: every tab and the screens it reaches, each captured at the
// top, just past its masthead, mid-way and at the bottom, plus search idle, focused
// and with results. Run once per appearance (simctl ui <udid> appearance light|dark).
// Signs into the seeded review account (REVIEW_EMAIL / REVIEW_PASSWORD) and only
// reads: no quiz is submitted. Skipped unless AUDIT_DIR is set.
final class AuditTests: XCTestCase {
    private var app: XCUIApplication!
    private var env: [String: String] { ProcessInfo.processInfo.environment }
    private var outputDir: URL!
    private var index = 0

    override func setUpWithError() throws {
        try XCTSkipIf((env["AUDIT_DIR"] ?? "").isEmpty, "AUDIT_DIR not set")
        continueAfterFailure = true
        outputDir = URL(fileURLWithPath: env["AUDIT_DIR"]!, isDirectory: true)
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    }

    private func launch(_ url: String? = nil) {
        app?.terminate()
        app = XCUIApplication()
        app.launchEnvironment["API_BASE_URL"] = env["API_BASE_URL"] ?? "https://timpson-lyceum.vercel.app"
        if let url { app.launchEnvironment["DEBUG_OPEN_URL"] = url }
        app.launch()
        settle(4)
    }

    /// AUDIT_ONLY=courses,drills… limits the tour to those sections.
    private func want(_ section: String) -> Bool {
        let only = (env["AUDIT_ONLY"] ?? "").split(separator: ",").map(String.init)
        return only.isEmpty || only.contains(section)
    }

    func testTour() throws {
        launch()
        signInIfNeeded()

        if want("courses") { tourCourses() }
        if want("pushed") { tourPushed() }
        if want("review") { tourReview() }
        if want("drills") { tourDrills() }
        if want("progress") { tourProgress() }
    }

    private func tourCourses() {
        launch()
        tapTab("Courses"); settle(4)
        scrollSet("courses")
        searchSet("courses", query: "matrix")
        launch()
        tapTab("Courses"); settle(4)
        if tap(app.descendants(matching: .any)["courseRow"].firstMatch) {
            settle(4)
            scrollSet("course-detail")
            let lecture = app.descendants(matching: .any)["lectureRow"].firstMatch
            for _ in 0..<6 where !(lecture.exists && lecture.isHittable) { app.swipeUp() }
            if tap(lecture) {
                settle(5)
                shoot("lecture-top")
                let seg = app.segmentedControls.firstMatch
                if seg.exists {
                    for i in 0..<seg.buttons.count {
                        seg.buttons.element(boundBy: i).tap(); settle(4)
                        let name = seg.buttons.element(boundBy: i).label.lowercased().replacingOccurrences(of: " ", with: "-")
                        shoot("lecture-\(name)")
                        drag(0.75, 0.3); settle(1.5)
                        shoot("lecture-\(name)-scrolled")
                        drag(0.3, 0.8); settle(1)
                    }
                }
            }
        }
    }

    private func tourPushed() {
        launch("lyceum://map"); settle(3); scrollSet("map")
        launch("lyceum://leaderboard"); settle(3); scrollSet("scholars")
        let scholar = app.scrollViews.buttons.element(boundBy: 2)
        if tap(scholar) { settle(4); scrollSet("scholar-profile") }

    }

    private func tourReview() {
        launch("lyceum://review"); settle(4)
        scrollSet("review")
        if tap(app.buttons["Start review"].firstMatch, timeout: 4) {
            settle(3); shoot("review-card")
        }

    }

    private func tourDrills() {
        launch("lyceum://drills"); settle(3)
        scrollSet("drills")
        searchSet("drills", query: "prime")
        launch("lyceum://drills"); settle(3)
        if tap(app.descendants(matching: .any)["drillCategoryRow"].firstMatch) {
            settle(2); scrollSet("drill-category")
            if tap(app.descendants(matching: .any)["drillRow"].firstMatch) {
                settle(3); shoot("drill-setup")
                drag(0.75, 0.3); settle(1); shoot("drill-setup-scrolled")
            }
        }
        launch("lyceum://drills"); settle(3)
        for _ in 0..<3 { app.swipeUp() }
        if tap(app.staticTexts["Geography"].firstMatch) {
            settle(2); shoot("drill-geography")
            if tap(app.descendants(matching: .any)["drillRow"].firstMatch) { settle(4); shoot("drill-geo-setup") }
        }

    }

    private func tourProgress() {
        launch("lyceum://dashboard"); settle(5)
        scrollSet("progress")
        launch("lyceum://dashboard"); settle(5)
        for _ in 0..<2 { app.swipeUp() }
        if tap(app.buttons["See all"].firstMatch) { settle(3); scrollSet("achievements") }
        launch("lyceum://settings"); settle(3); scrollSet("settings")
        launch("lyceum://dashboard"); settle(5)
        let classCard = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'section' OR label CONTAINS[c] 'class'")).firstMatch
        if tap(classCard, timeout: 3) {
            settle(4); scrollSet("class-hub")
        }
    }

    // MARK: - capture sets

    /// Top, just past the masthead (bar transition), mid, bottom, and pulled down.
    private func scrollSet(_ name: String) {
        shoot("\(name)-0top")
        drag(0.62, 0.48); settle(1.2)
        shoot("\(name)-1past-masthead")
        drag(0.8, 0.25); settle(1.2)
        shoot("\(name)-2mid")
        for _ in 0..<5 { app.swipeUp() }
        settle(1.2)
        shoot("\(name)-3bottom")
        for _ in 0..<6 { app.swipeDown() }
        settle(0.6)
        // Overscroll at the top: the leather should run up under the bar.
        let s = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
        let e = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        s.press(forDuration: 0.05, thenDragTo: e, withVelocity: .slow, thenHoldForDuration: 0.6)
        shoot("\(name)-4overscroll")
        settle(1)
    }

    private func searchSet(_ name: String, query: String) {
        let field = app.textFields["searchField"].firstMatch
        guard field.waitForExistence(timeout: 5) else { return }
        shoot("\(name)-search-0idle")
        field.tap(); settle(1.5)
        shoot("\(name)-search-1focused")
        field.typeText(query); settle(4)
        shoot("\(name)-search-2results")
        app.swipeUp(); settle(1)
        shoot("\(name)-search-3results-scrolled")
        // Keyboard down, query kept.
        if app.keyboards.buttons["search"].exists { app.keyboards.buttons["search"].tap() } else { app.swipeDown() }
        settle(8) // lecture search on production is slow
        shoot("\(name)-search-5settled")
        settle(1)
        shoot("\(name)-search-4submitted")
    }

    // MARK: - helpers

    private func shoot(_ name: String) {
        index += 1
        let shot = XCUIScreen.main.screenshot()
        try? shot.pngRepresentation.write(to: outputDir.appendingPathComponent(String(format: "%03d-%@.png", index, name)))
    }

    private func settle(_ s: Double = 2) { Thread.sleep(forTimeInterval: s) }

    private func drag(_ from: CGFloat, _ to: CGFloat) {
        let s = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: from))
        let e = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: to))
        s.press(forDuration: 0.05, thenDragTo: e, withVelocity: .slow, thenHoldForDuration: 0.3)
    }

    private func tapTab(_ label: String) {
        let b = app.tabBars.buttons[label].firstMatch
        if b.waitForExistence(timeout: 20) { b.tap() }
    }

    @discardableResult
    private func tap(_ el: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        guard el.waitForExistence(timeout: timeout) else { return false }
        for _ in 0..<4 where !el.isHittable { app.swipeUp(); settle(0.5) }
        guard el.isHittable else { return false }
        el.tap()
        return true
    }

    private func signInIfNeeded() {
        tapTab("Progress")
        let email = app.textFields["Email"]
        guard email.waitForExistence(timeout: 8) else { return }
        email.tap(); email.typeText(env["REVIEW_EMAIL"] ?? "")
        let pw = app.secureTextFields["Password"]
        pw.tap(); pw.typeText(env["REVIEW_PASSWORD"] ?? "")
        app.buttons["Sign in"].tap()
        _ = app.navigationBars["My Progress"].waitForExistence(timeout: 45)
        settle(2)
        let sb = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for l in ["Not Now", "Cancel"] where sb.buttons[l].exists { sb.buttons[l].tap() }
    }
}
