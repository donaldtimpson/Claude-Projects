import XCTest

// Moves things around the villa and checks the spots stick: a fountain dragged across the lawn, and
// a statue dropped onto another statue's plinth (they swap). Then relaunches — and on an iPad turns
// sideways — and checks everything is where it was left. Spots are compared as fractions of the
// villa canvas (`villa-canvas`), which is what the app saves, so they hold across orientations.
// Writes before/after screenshots to SCREENSHOT_DIR when set.
final class VillaDragTests: XCTestCase {
    private let app = XCUIApplication()

    private func launch(reset: Bool) {
        app.terminate()
        app.launchEnvironment = ["LUDUS_MUTE": "1", "LUDUS_SCREEN": "villa",
                                 "LUDUS_VILLA_OWN": "fountain+bust+sundial"]
        if reset { app.launchEnvironment["LUDUS_VILLA_RESET"] = "1" }
        app.launch()
    }

    private func item(_ id: String) -> XCUIElement { app.descendants(matching: .any)["villa-item-\(id)"] }
    private var canvas: XCUIElement { app.descendants(matching: .any)["villa-canvas"] }

    /// An item's feet (bottom-center of its frame) as fractions of the canvas.
    private func spot(_ id: String) -> CGPoint {
        let c = canvas.frame, f = item(id).frame
        return CGPoint(x: (f.midX - c.minX) / c.width, y: (f.maxY - c.minY) / c.height)
    }

    private func drag(_ id: String, by d: CGVector) {
        let c = canvas.frame
        let start = item(id).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        let end = start.withOffset(CGVector(dx: d.dx * c.width, dy: d.dy * c.height))
        start.press(forDuration: 0.25, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
        sleep(1)
    }

    private func near(_ a: CGPoint, _ b: CGPoint, _ tol: CGFloat = 0.02, _ what: String) {
        XCTAssertEqual(a.x, b.x, accuracy: tol, "\(what) x")
        XCTAssertEqual(a.y, b.y, accuracy: tol, "\(what) y")
    }

    private func save(_ name: String) {
        guard let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] else { return }
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? XCUIScreen.main.screenshot().pngRepresentation
            .write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
    }

    func testDraggedThingsStay() throws {
        XCUIDevice.shared.orientation = .portrait
        launch(reset: true)
        XCTAssert(item("fountain").waitForExistence(timeout: 10))
        save("drag-0-before")

        // the fountain starts at its old home, then goes left and down the lawn
        let f0 = spot("fountain")
        near(f0, CGPoint(x: 0.50, y: 0.76), 0.03, "fountain home")
        drag("fountain", by: CGVector(dx: -0.30, dy: 0.12))
        let f1 = spot("fountain")
        XCTAssertGreaterThan(f0.x - f1.x, 0.2, "fountain moved left")

        // the bust dropped near the sundial's plinth takes it; the sundial moves to the bust's plinth
        let b0 = spot("bust"), s0 = spot("sundial")
        drag("bust", by: CGVector(dx: s0.x - b0.x + 0.02, dy: s0.y - b0.y - 0.02))
        let b1 = spot("bust"), s1 = spot("sundial")
        near(b1, s0, 0.03, "bust on the sundial's plinth")
        near(s1, b0, 0.03, "sundial on the bust's plinth")

        // dropped in the sky: it comes back down onto the lawn
        drag("fountain", by: CGVector(dx: 0, dy: -0.6))
        let f2 = spot("fountain")
        XCTAssertGreaterThan(f2.y, 0.55, "fountain kept on the lawn")
        XCTAssertLessThan(f2.y, 0.70, "fountain at the top of the lawn")
        save("drag-1-after")

        // relaunch: everything where it was left
        launch(reset: false)
        XCTAssert(item("fountain").waitForExistence(timeout: 10))
        near(spot("fountain"), f2, 0.02, "fountain after relaunch")
        near(spot("bust"), b1, 0.02, "bust after relaunch")
        near(spot("sundial"), s1, 0.02, "sundial after relaunch")

        // sideways (iPad only; phones stay upright): the same spots on the canvas
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
            sleep(2)
            near(spot("fountain"), f2, 0.02, "fountain sideways")
            near(spot("bust"), b1, 0.02, "bust sideways")
            save("drag-2-sideways")
            XCUIDevice.shared.orientation = .portrait
        }
    }
}
