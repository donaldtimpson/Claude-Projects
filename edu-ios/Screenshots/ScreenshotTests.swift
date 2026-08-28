import XCTest

// Captures the App Store Connect screenshot set by driving the real app on a
// simulator. App Store Connect wants one set per required display size, so this
// runs twice — once on an iPhone 16 Pro Max (6.9") and once on an iPad Pro 13" —
// via tools/screenshots.sh.
//
// It signs into the seeded review account on PRODUCTION rather than a local dev
// server (scripts/seed-review-account.ts in edu-web), so the shots show real
// courses with real progress instead of an empty account.
//
// Not part of the Lyceum scheme: a normal `xcodebuild test` shouldn't spend a
// minute launching the UI.
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!
    private var outputDir: URL!
    private var shotIndex = 0

    override func setUpWithError() throws {
        continueAfterFailure = false

        let env = ProcessInfo.processInfo.environment
        let dir = env["SCREENSHOT_DIR"] ?? NSTemporaryDirectory() + "LyceumScreenshots"
        outputDir = URL(fileURLWithPath: dir, isDirectory: true)
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        app = XCUIApplication()
        // Point the app at production and hand it the review credentials. The app
        // already reads API_BASE_URL from the environment (see AppConfig).
        app.launchEnvironment["API_BASE_URL"] =
            env["API_BASE_URL"] ?? "https://timpson-lyceum.vercel.app"
        app.launchEnvironment["UI_TEST_EMAIL"] = env["REVIEW_EMAIL"] ?? ""
        app.launchEnvironment["UI_TEST_PASSWORD"] = env["REVIEW_PASSWORD"] ?? ""
        app.launch()
    }

    func testCaptureAppStoreScreenshots() throws {
        try signInIfNeeded()

        // 1. Learn — the catalog, which is what the app opens on.
        let learn = tab("Learn")
        XCTAssertTrue(learn.waitForExistence(timeout: 30), "Learn tab never appeared")
        learn.tap()
        waitForSettle()
        shoot("learn-catalog")

        // 2. A course, opened from the catalog: the lecture list with thumbnails.
        let course = app.descendants(matching: .any)["courseRow"].firstMatch
        if tapWhenReady(course) {
            waitForSettle()
            shoot("course-lectures")

            // 3. A lecture. The simulator can't play YouTube, so capture the Notes
            //    tab rather than the player — the more distinctive screen anyway.
            let lecture = app.descendants(matching: .any)["lectureRow"].firstMatch
            if tapWhenReady(lecture) {
                waitForSettle()
                tapIfPresent(app.buttons["Notes"])
                waitForSettle(seconds: 6) // KaTeX renders in a web view
                shoot("lecture-notes")
            }
            backToRoot()
        }

        // 4. Drills hub, then a drill's own screen.
        if tapWhenReady(tab("Drills")) {
            waitForSettle()
            shoot("drills-hub")

            if tapWhenReady(app.descendants(matching: .any)["drillCategoryRow"].firstMatch) {
                waitForSettle()
                if tapWhenReady(app.descendants(matching: .any)["drillRow"].firstMatch) {
                    waitForSettle()
                    shoot("drill-detail")
                }
            }
            backToRoot()
        }

        // 5. Review. The landing screen is just a count and a button, so start the
        //    session and capture an actual card — that's the feature worth showing.
        if tapWhenReady(tab("Review")) {
            waitForSettle(seconds: 5)
            if tapWhenReady(app.buttons["Start review"]) {
                waitForSettle()
                shoot("review-card")
            } else {
                shoot("review-deck")
            }
            backToRoot()
        }

        // 6. My Progress: streak, badges, cards due, classes.
        if tapWhenReady(tab("Progress")) {
            waitForSettle()
            shoot("profile")

            // 7. The full badge wall.
            if tapWhenReady(app.buttons["View all"]) {
                waitForSettle()
                shoot("achievements")
            }
        }

        print("SCREENSHOTS_WRITTEN_TO \(outputDir.path)")
    }

    // MARK: - sign in

    private func signInIfNeeded() throws {
        let email = app.textFields["Email"]
        guard email.waitForExistence(timeout: 30) else { return } // already signed in
        let creds = ProcessInfo.processInfo.environment
        let user = creds["REVIEW_EMAIL"] ?? ""
        let pass = creds["REVIEW_PASSWORD"] ?? ""
        XCTAssertFalse(user.isEmpty, "Set REVIEW_EMAIL / REVIEW_PASSWORD before running")

        email.tap()
        email.typeText(user)
        let password = app.secureTextFields["Password"]
        XCTAssertTrue(password.waitForExistence(timeout: 5))
        password.tap()
        password.typeText(pass)
        app.buttons["Sign in"].tap()

        // The tab bar only exists once RootView has a user.
        XCTAssertTrue(tab("Learn").waitForExistence(timeout: 45), "Sign-in did not complete")

        // iOS offers to save the password into Keychain right after a SecureField
        // submit. The sheet belongs to SpringBoard, not the app, so it sits on top
        // of the first screenshot (and blocks taps) until it's dismissed.
        dismissSystemAlert()
    }

    // Tap through any SpringBoard-owned sheet in front of the app. Runs before each
    // capture because the password prompt isn't the only one that can appear.
    private func dismissSystemAlert() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Not Now", "Cancel", "Dismiss", "Continue", "Allow"] {
            let button = springboard.buttons[label]
            if button.exists && button.isHittable {
                button.tap()
                Thread.sleep(forTimeInterval: 1)
                return
            }
        }
    }

    // MARK: - capture

    private func shoot(_ name: String) {
        dismissSystemAlert()
        shotIndex += 1
        let numbered = String(format: "%02d-%@", shotIndex, name)
        let shot = XCUIScreen.main.screenshot()

        // Write straight to the host filesystem — simulator processes can reach it,
        // and it beats digging PNGs back out of an .xcresult bundle.
        let url = outputDir.appendingPathComponent("\(numbered).png")
        do {
            try shot.pngRepresentation.write(to: url)
        } catch {
            XCTFail("Could not write \(url.path): \(error)")
        }

        // Attach as well, so the shots are recoverable from the result bundle if the
        // direct write is ever blocked.
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = numbered
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - navigation helpers

    private func tab(_ label: String) -> XCUIElement {
        // .sidebarAdaptable gives iPad both a sidebar and a tab bar, so a plain
        // subscript matches more than one element and tapping throws. Take the
        // first match by label instead of asserting uniqueness.
        let byLabel = app.buttons.matching(NSPredicate(format: "label == %@", label))
        if byLabel.count > 0 { return byLabel.firstMatch }
        return app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
    }

    // Tap an element once it exists and is hittable. Returns false instead of
    // failing so one missing screen doesn't cost the whole run.
    @discardableResult
    private func tapWhenReady(_ element: XCUIElement, timeout: TimeInterval = 15) -> Bool {
        guard element.waitForExistence(timeout: timeout) else { return false }
        let deadline = Date().addingTimeInterval(5)
        while !element.isHittable && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.25)
        }
        guard element.isHittable else { return false }
        element.tap()
        return true
    }

    private func tapIfPresent(_ element: XCUIElement) {
        if element.exists && element.isHittable { element.tap() }
    }

    private func backToRoot() {
        for _ in 0..<3 {
            let back = app.navigationBars.buttons.firstMatch
            guard back.exists && back.isHittable else { break }
            back.tap()
            waitForSettle(seconds: 1)
        }
    }

    // Network-backed screens need time to load; there's no spinner to wait on that
    // covers every case, so settle on a fixed pause.
    private func waitForSettle(seconds: TimeInterval = 3) {
        _ = app.wait(for: .runningForeground, timeout: 1)
        Thread.sleep(forTimeInterval: seconds)
    }
}
