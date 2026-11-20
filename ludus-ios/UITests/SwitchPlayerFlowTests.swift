import XCTest

// The real path to the player picker: map → rank plaque → Tabularium → "Switch player".
// Runs in the throwaway demo store (LUDUS_DEMO_PLAYERS) so real saves are never touched.
final class SwitchPlayerFlowTests: XCTestCase {
    func testSwitchPlayerFromTabularium() throws {
        for players in ["0", "2"] {
            let app = XCUIApplication()
            app.launchEnvironment = ["LUDUS_MUTE": "1", "LUDUS_DEMO_PLAYERS": players]
            app.launch()
            if players == "2" {
                // 2+ players: the picker greets at launch; pick the first seal.
                let seal = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Marcus'")).firstMatch
                XCTAssertTrue(seal.waitForExistence(timeout: 10), "launch picker missing")
                seal.tap()
                sleep(2)
            }
            let rank = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Rank:'")).firstMatch
            XCTAssertTrue(rank.waitForExistence(timeout: 10))
            rank.tap()
            let sw = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Switch player' OR label == 'Add a player'")).firstMatch
            XCTAssertTrue(sw.waitForExistence(timeout: 10), "switch button missing")
            if !sw.isHittable { app.swipeUp() }
            sw.tap()
            let picker = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'playing'")).firstMatch
            XCTAssertTrue(picker.waitForExistence(timeout: 10), "picker never appeared (players=\(players))")
            app.terminate()
        }
    }
}
