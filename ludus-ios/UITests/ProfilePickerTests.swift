import XCTest

// The "Who's playing?" picker, always in the DEBUG demo sandbox (LUDUS_DEMO_PLAYERS), so a real
// install's players and saves are never touched. SCREENSHOT_DIR (optional) receives a PNG per step.
final class ProfilePickerTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// Saves are separate: player one keeps the pre-profiles bank, player two's coins stay theirs,
    /// erasing a player erases their save, and the last player can't be erased (Profiles.swift).
    func testSavesAreSeparate() {
        let app = launch(["LUDUS_DEMO_PLAYERS": "0", "LUDUS_DEMO_BANK": "777", "LUDUS_PROFILE_SELFTEST": "1"])
        let pass = app.staticTexts["PROFILE SELFTEST PASS"]
        XCTAssertTrue(pass.waitForExistence(timeout: 10),
                      app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: "\n"))
    }

    /// First use from "Switch player": name the child who has been playing, add a sibling, pick them.
    func testFirstRunFlow() {
        let app = launch(["LUDUS_DEMO_PLAYERS": "0", "LUDUS_DEMO_BANK": "777", "LUDUS_SCREEN": "players"])
        XCTAssertTrue(app.staticTexts["Who has been playing so far?"].waitForExistence(timeout: 8))
        shot("01-first-name")
        let field = app.textFields["name-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap(); field.typeText("Marcus")
        shot("02-first-typed")
        app.buttons["save-player"].tap()
        XCTAssertTrue(app.buttons["seal-Marcus"].waitForExistence(timeout: 4))
        sleep(1); shot("03-one-player")

        app.buttons["add-player"].tap()
        XCTAssertTrue(app.staticTexts["A new player"].waitForExistence(timeout: 4))
        app.textFields["name-field"].tap(); app.textFields["name-field"].typeText("Julia")
        app.buttons["save-player"].tap()
        XCTAssertTrue(app.buttons["seal-Julia"].waitForExistence(timeout: 4))
        sleep(1); shot("04-two-players")

        app.buttons["seal-Julia"].tap()
        XCTAssertTrue(app.buttons["seal-Julia"].waitForNonExistence(timeout: 5), "picking a seal closes the picker")
    }

    /// Launch with 2+ players: no way out but choosing; grown-ups hold unlocks editing; the last
    /// player has no erase.
    func testLaunchPickerAndGrownUps() {
        let app = launch(["LUDUS_DEMO_PLAYERS": "2"])
        XCTAssertTrue(app.buttons["seal-Marcus"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["close-picker"].exists, "launch picker has no cancel")
        app.buttons["grownups"].press(forDuration: 2.4)
        XCTAssertTrue(app.buttons["grownups-done"].waitForExistence(timeout: 3))
        shot("05-grownups")
        app.buttons["seal-Julia"].tap()
        XCTAssertTrue(app.staticTexts["Change Julia"].waitForExistence(timeout: 3))
        shot("06-edit")
        app.buttons["erase-player"].tap()
        let erase = app.alerts.buttons["Erase"]
        XCTAssertTrue(erase.waitForExistence(timeout: 3))
        shot("07-erase-confirm")
        erase.tap()
        XCTAssertTrue(app.buttons["seal-Julia"].waitForNonExistence(timeout: 3))
        app.buttons["seal-Marcus"].tap()
        XCTAssertTrue(app.staticTexts["Change Marcus"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["erase-player"].exists, "the last player can't be erased")
    }

    // MARK: -

    private func launch(_ env: [String: String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = env.merging(["LUDUS_MUTE": "1"]) { a, _ in a }
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        return app
    }

    private func shot(_ name: String) {
        guard let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] else { return }
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? XCUIScreen.main.screenshot().pngRepresentation
            .write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
    }
}
