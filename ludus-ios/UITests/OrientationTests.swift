import XCTest

// Rotates the app and saves a screenshot of each orientation, so the iPad layout can be
// checked sideways too (there's no Simulator window to rotate by hand on this Mac).
// Writes to SCREENSHOT_DIR when set, otherwise only attaches to the result bundle.
final class OrientationTests: XCTestCase {
    func testOrientations() throws {
        let app = XCUIApplication()
        app.launchEnvironment["LUDUS_MUTE"] = "1"
        for (k, v) in ProcessInfo.processInfo.environment where k.hasPrefix("LUDUS_") {
            app.launchEnvironment[k] = v
        }
        app.launch()
        sleep(3)
        let shots: [(String, UIDeviceOrientation)] = [
            ("portrait", .portrait), ("landscape-left", .landscapeLeft),
            ("landscape-right", .landscapeRight), ("portrait-again", .portrait),
        ]
        for (name, o) in shots {
            XCUIDevice.shared.orientation = o
            sleep(2)
            save(name)
        }
    }

    private func save(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(screenshot: shot)
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }
}
