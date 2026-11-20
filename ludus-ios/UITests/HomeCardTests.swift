import XCTest

// Opens a landmark's arrival card, then scrolls the map: a short scroll keeps the card,
// scrolling the landmark out of view rolls the card away.
final class HomeCardTests: XCTestCase {
    func testScrollWithCardOpen() throws {
        let app = XCUIApplication()
        app.launchEnvironment["LUDUS_MUTE"] = "1"
        app.launch()
        sleep(3)
        let seal = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'The Library'")).firstMatch
        XCTAssertTrue(seal.waitForExistence(timeout: 10))
        seal.tap()
        sleep(5)
        save("card-open")
        let mid = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
        mid.press(forDuration: 0.05, thenDragTo: mid.withOffset(CGVector(dx: 0, dy: -60)))
        sleep(2)
        save("small-scroll")
        mid.press(forDuration: 0.05, thenDragTo: mid.withOffset(CGVector(dx: 0, dy: -500)))
        sleep(2)
        save("big-scroll")
    }

    private func save(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
    }
}
