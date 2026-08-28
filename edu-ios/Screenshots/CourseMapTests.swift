import XCTest

// The course map is a screen you walk around in, so the walk has to survive leaving
// it. Opening a course and coming back used to drop you at the default course,
// which made a mis-tap cost you your place. Runs signed out against the local dev
// server; the map is public. Not in the Lyceum scheme — same reasoning as
// ScreenshotTests.
final class CourseMapTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["API_BASE_URL"] =
            ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:3000"
        app.launchEnvironment["UI_TEST_ANONYMOUS"] = "1"
        app.launch()
    }

    func testWalkSurvivesOpeningACourseAndComingBack() {
        XCTAssertTrue(app.buttons["Course Map"].waitForExistence(timeout: 30))
        app.buttons["Course Map"].tap()

        // Walk one hop away from whichever course the map opens on.
        let logic = app.buttons
            .containing(NSPredicate(format: "label CONTAINS %@", "Predicate Logic")).firstMatch
        XCTAssertTrue(logic.waitForExistence(timeout: 15), "no neighbour to walk to")
        logic.tap()
        let hero = app.staticTexts["First-Order Predicate Logic"]
        XCTAssertTrue(hero.waitForExistence(timeout: 10), "walking didn't change the focus")

        // The hero's link must reach the real course screen, not a dead press.
        let open = app.buttons
            .containing(NSPredicate(format: "label CONTAINS %@", "Open this course")).firstMatch
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        open.tap()
        XCTAssertTrue(app.navigationBars["First-Order Predicate Logic"].waitForExistence(timeout: 20),
                      "\"Open this course\" didn't open the course")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Course Map"].waitForExistence(timeout: 15))
        XCTAssertTrue(hero.waitForExistence(timeout: 10),
                      "coming back reset the map instead of keeping the walk")
    }
}
