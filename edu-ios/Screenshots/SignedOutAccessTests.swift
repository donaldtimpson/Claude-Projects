import XCTest

// Guideline 5.1.1(i): the app must not demand an account for content that doesn't
// need one. 1.0.0 put the whole app behind a login and was rejected for it. These
// tests pin the corrected behaviour, so it can't quietly regress into a wall again.
//
// Runs signed OUT and against the LOCAL dev server by default (the browse endpoints
// are public, so no seeded account is needed). Not in the Lyceum scheme — same
// reasoning as ScreenshotTests.
final class SignedOutAccessTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["API_BASE_URL"] =
            ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:3000"
        // Deliberately NO UI_TEST_EMAIL / UI_TEST_PASSWORD: this is the anonymous visitor.
        // The simulator Keychain outlives an app uninstall, so ask the app to start from
        // a genuinely signed-out state rather than trusting the device to be clean.
        app.launchEnvironment["UI_TEST_ANONYMOUS"] = "1"
        app.launch()
    }

    /// The app opens on the catalog, not on a login screen.
    func testLaunchesIntoTheCatalogWithoutAnAccount() {
        XCTAssertTrue(tab("Learn").waitForExistence(timeout: 30),
                      "the tab bar should exist signed out — the app must not open behind a login")
        // The sign-in form must NOT be what greets an anonymous visitor.
        XCTAssertFalse(app.buttons["Sign in"].exists,
                       "a signed-out launch landed on the sign-in screen")
        // SectionHeader uppercases its title, so that's the accessibility label.
        XCTAssertTrue(app.staticTexts["CURRENTLY TEACHING"].waitForExistence(timeout: 30)
                      || app.staticTexts["BROWSE BY CATEGORY"].waitForExistence(timeout: 5),
                      "the catalog never rendered for an anonymous visitor")
    }

    /// Every tab is reachable without an account; the personal ones explain themselves.
    func testAllTabsAreReachableSignedOut() {
        XCTAssertTrue(tab("Learn").waitForExistence(timeout: 30))
        for label in ["Review", "Drills", "Profile", "Learn"] {
            let t = tab(label)
            XCTAssertTrue(t.waitForExistence(timeout: 10), "\(label) tab missing signed out")
            t.tap()
            settle()
        }
    }

    /// Drills are fully playable anonymously — no account, no gate.
    func testDrillsAreUsableSignedOut() {
        XCTAssertTrue(tab("Drills").waitForExistence(timeout: 30))
        tab("Drills").tap()
        settle()
        XCTAssertFalse(app.buttons["Sign in or create an account"].exists,
                       "Drills must not be gated — they work without an identity")
    }

    /// Review is the one tab that genuinely needs an identity, and it says so.
    func testReviewExplainsWhyItNeedsAnAccount() {
        XCTAssertTrue(tab("Review").waitForExistence(timeout: 30))
        tab("Review").tap()
        settle()
        XCTAssertTrue(app.buttons["Sign in or create an account"].waitForExistence(timeout: 10),
                      "Review should offer a way to sign in")
        XCTAssertTrue(app.staticTexts["Everything else in the app works without one."].exists,
                      "the gate should make clear the rest of the app is open")
    }

    private func tab(_ label: String) -> XCUIElement {
        let byLabel = app.buttons.matching(NSPredicate(format: "label == %@", label))
        if byLabel.count > 0 { return byLabel.firstMatch }
        return app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    private func settle(_ seconds: TimeInterval = 2) {
        _ = app.wait(for: .runningForeground, timeout: 1)
        Thread.sleep(forTimeInterval: seconds)
    }
}
