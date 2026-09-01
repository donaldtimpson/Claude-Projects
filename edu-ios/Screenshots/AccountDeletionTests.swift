import XCTest

// Guideline 5.1.1(v): an app that lets you make an account must let you delete it
// from inside the app, and must NOT require a password to do it.
//
// 1.0 (3) was rejected because the delete screen asked for the account password —
// added as a safeguard against a stolen token, but the guideline reads a password
// field there as the prohibited barrier whether or not the account has one. These
// tests pin the corrected flow, because this is the third rejection under this
// one guideline and it must not drift back.
//
// Runs against the LOCAL dev server: the test creates a throwaway account and
// deletes it, so it must never be pointed at production.
final class AccountDeletionTests: XCTestCase {
    private var app: XCUIApplication!
    private var email: String!

    override func setUpWithError() throws {
        continueAfterFailure = false
        email = "uitest-delete-\(Int(Date().timeIntervalSince1970))@example.invalid"
        app = XCUIApplication()
        app.launchEnvironment["API_BASE_URL"] =
            ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:3000"
        app.launchEnvironment["UI_TEST_ANONYMOUS"] = "1"
        app.launch()
    }

    /// The whole flow, end to end: make an account, then delete it with nothing
    /// but the typed confirmation.
    func testAccountCanBeDeletedWithOnlyATypedConfirmation() throws {
        try register()

        openDeleteSheet()

        // Wait for the sheet to actually be on screen BEFORE asserting what is not
        // on it — otherwise "no password field" passes vacuously against a screen
        // that hasn't loaded, which is the one way this test could lie.
        let deleteButton = app.buttons["Delete my account"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 15), "delete sheet never appeared")

        // The finding, pinned: no secure entry anywhere on this screen.
        XCTAssertEqual(app.secureTextFields.count, 0,
                       "the delete screen must not ask for a password (Guideline 5.1.1(v))")

        let confirm = app.textFields.firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "no confirmation field")
        XCTAssertFalse(deleteButton.isEnabled,
                       "deleting should stay disabled until the phrase is typed")

        confirm.tap()
        confirm.typeText("DELETE")
        XCTAssertTrue(deleteButton.isEnabled,
                      "the typed phrase alone must be enough to enable deletion")

        deleteButton.tap()

        // Deleting clears the session, so the Profile tab falls back to the auth
        // form — that form reappearing is how we know the account is gone.
        XCTAssertTrue(app.buttons["Create account"].waitForExistence(timeout: 30)
                      || app.buttons["Sign in"].waitForExistence(timeout: 5),
                      "the app should return to a signed-out state after deletion")
    }

    /// Deletion has to be reachable from inside the app, not just documented.
    func testDeleteAccountIsReachableFromProfile() throws {
        try register()
        openDeleteSheet()
        XCTAssertTrue(app.buttons["Delete my account"].waitForExistence(timeout: 5))
    }

    // MARK: helpers

    private func register() throws {
        tab("Progress").tap()

        let toRegister = app.buttons["New here? Create an account"]
        XCTAssertTrue(toRegister.waitForExistence(timeout: 20), "auth form never appeared")
        toRegister.tap()

        let fields = app.textFields
        XCTAssertTrue(fields.element(boundBy: 1).waitForExistence(timeout: 10),
                      "register form should show name and email")
        fields.element(boundBy: 0).tap()
        fields.element(boundBy: 0).typeText("UI Test")
        fields.element(boundBy: 1).tap()
        fields.element(boundBy: 1).typeText(email)
        app.secureTextFields.firstMatch.tap()
        app.secureTextFields.firstMatch.typeText("TestPassword123!")

        app.buttons["Create account"].tap()

        // Signed in, the Profile tab becomes My Progress.
        XCTAssertTrue(app.buttons["Delete Account"].waitForExistence(timeout: 30),
                      "registration did not complete")
    }

    private func openDeleteSheet() {
        let entry = app.buttons["Delete Account"]
        XCTAssertTrue(entry.waitForExistence(timeout: 10))
        // The control sits at the very bottom of My Progress, under the coursework.
        if !entry.isHittable { app.swipeUp() }
        entry.tap()
    }

    /// `.sidebarAdaptable` gives iPad both a sidebar and a tab bar, so a label can
    /// match twice; take the first.
    private func tab(_ label: String) -> XCUIElement {
        let byLabel = app.buttons.matching(NSPredicate(format: "label == %@", label))
        if byLabel.count > 0 { return byLabel.firstMatch }
        return app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", label)).firstMatch
    }
}
