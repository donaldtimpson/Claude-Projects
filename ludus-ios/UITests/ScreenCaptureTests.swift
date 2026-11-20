import XCTest

// Captures a list of screens in one orientation, relaunching the app per screen.
//   TEST_RUNNER_CAPTURE_SPECS = "name|KEY=V,KEY=V|wait;name2|…"  (LUDUS_ env per screen, seconds to wait)
//   TEST_RUNNER_CAPTURE_ORIENT = portrait | landscape
//   TEST_RUNNER_SCREENSHOT_DIR = where the PNGs go
// Landscape only shows anything when the app is built with landscape allowed (the shipped app
// is portrait-locked), e.g. by overriding the orientation build settings on the command line.
final class ScreenCaptureTests: XCTestCase {
    func testCaptureScreens() throws {
        let env = ProcessInfo.processInfo.environment
        guard let specs = env["CAPTURE_SPECS"], let dir = env["SCREENSHOT_DIR"] else { return }
        let landscape = env["CAPTURE_ORIENT"] == "landscape"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let app = XCUIApplication()
        for spec in specs.split(separator: ";") {
            let parts = spec.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            app.terminate()
            app.launchEnvironment = ["LUDUS_MUTE": "1"]
            if parts.count > 1 {
                for kv in parts[1].split(separator: ",") {
                    let p = kv.split(separator: "=", maxSplits: 1).map(String.init)
                    if p.count == 2 { app.launchEnvironment[p[0]] = p[1] }
                }
            }
            XCUIDevice.shared.orientation = landscape ? .landscapeLeft : .portrait
            app.launch()
            Thread.sleep(forTimeInterval: Double(parts.count > 2 ? parts[2] : "") ?? 3)
            let shot = XCUIScreen.main.screenshot()
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(parts[0]).png"))
        }
    }
}
