import XCTest

// Captures the app's interactive states (an answered quiz, a running drill,
// revealed solutions, achievements) for design review, against a local server
// with a minted token. Driven by tools/parity-states.sh-style env:
//   PARITY_TOKEN, PARITY_API, PARITY_LECTURE_URL, PARITY_PSET_URL, PARITY_REVIEW_URL, SCREENSHOT_DIR
// Skipped unless PARITY_TOKEN is set, so it never runs by accident.
final class ParityStatesTests: XCTestCase {
    private var env: [String: String] { ProcessInfo.processInfo.environment }
    private var outputDir: URL!

    override func setUpWithError() throws {
        try XCTSkipIf((env["PARITY_TOKEN"] ?? "").isEmpty, "PARITY_TOKEN not set")
        continueAfterFailure = true
        outputDir = URL(fileURLWithPath: env["SCREENSHOT_DIR"] ?? NSTemporaryDirectory(), isDirectory: true)
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    }

    private func launch(_ url: String?) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["API_BASE_URL"] = env["PARITY_API"] ?? "http://localhost:3123"
        app.launchEnvironment["DEBUG_ACCESS_TOKEN"] = env["PARITY_TOKEN"] ?? ""
        if let url { app.launchEnvironment["DEBUG_OPEN_URL"] = url }
        app.launch()
        return app
    }

    private func shoot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        try? data.write(to: outputDir.appendingPathComponent("\(name).png"))
    }

    private func settle(_ s: Double = 2) { Thread.sleep(forTimeInterval: s) }

    func testQuizAnswered() {
        let app = launch(env["PARITY_LECTURE_URL"])
        settle(5)
        app.segmentedControls.firstMatch.buttons.element(boundBy: 1).tap()
        settle(1)
        app.buttons["Start quiz"].firstMatch.tap()
        settle(3)
        // Pick the second option: usually wrong, which shows both answer states.
        let options = app.buttons.matching(identifier: "answerOption")
        if options.count > 1 { options.element(boundBy: 1).tap() } else { options.firstMatch.tap() }
        settle(1.5)
        shoot("quiz-answered")
    }

    func testProblemSetRevealed() {
        let app = launch(env["PARITY_PSET_URL"])
        settle(6)
        app.buttons["▸ Reveal all solutions"].firstMatch.tap()
        settle(2)
        app.swipeUp()
        settle(1)
        shoot("pset-revealed")
    }

    func testCourseReviewPlaying() {
        let app = launch(env["PARITY_REVIEW_URL"])
        settle(4)
        app.buttons["Start review"].firstMatch.tap()
        settle(3)
        shoot("review-question")
    }

    func testDrillRunning() {
        let app = launch("lyceum://drills")
        settle(4)
        app.staticTexts["Mental Math"].firstMatch.tap()
        settle(2)
        app.scrollViews.buttons.firstMatch.tap()
        settle(2)
        shoot("drill-setup")
        let start = app.buttons["Easy"].firstMatch
        if start.exists { start.tap() } else { app.buttons["Start"].firstMatch.tap() }
        settle(2)
        shoot("drill-running")
    }

    func testAchievements() {
        let app = launch("lyceum://dashboard")
        settle(5)
        app.swipeUp()
        settle(1)
        app.buttons["See all"].firstMatch.tap()
        settle(2)
        shoot("achievements")
    }

    func testSettingsGear() {
        let app = launch(nil)
        settle(5)
        app.tabBars.buttons["Progress"].firstMatch.tap()
        settle(3)
        app.buttons["settingsButton"].firstMatch.tap()
        settle(2)
        shoot("settings-gear")
    }

    /// Each screen in PARITY_SCROLL_URLS (comma-separated) scrolled once, to see the
    /// bar after its leather masthead has gone under it.
    func testScrolledChrome() throws {
        let urls = (env["PARITY_SCROLL_URLS"] ?? "").split(separator: ",").map(String.init)
        try XCTSkipIf(urls.isEmpty, "PARITY_SCROLL_URLS not set")
        for (i, url) in urls.enumerated() {
            let app = launch(url == "-" ? nil : url)
            settle(6)
            app.swipeUp(velocity: .slow)
            settle(1.5)
            shoot("scrolled-\(i)")
            app.terminate()
        }
    }

    /// The edge swipe still goes back on a screen that draws its own back button.
    func testSwipeBackFromMastheadScreen() throws {
        let url = try XCTUnwrap(env["PARITY_COURSE_URL"])
        let app = launch(url)
        settle(6)
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)
        settle(2)
        shoot("swiped-back")
        XCTAssertTrue(app.staticTexts["CURRENTLY TEACHING"].exists || app.staticTexts["ALL COURSES"].exists,
                      "edge swipe didn't return to the Courses root")
    }
}
