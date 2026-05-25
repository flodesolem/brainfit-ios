import XCTest
import UIKit

final class BrainfitIPadTests: XCTestCase {
    func testAppLaunchesOnIPadAndShowsHome() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Start dagens trening"].waitForExistence(timeout: 5),
                      "Forventet å se 'Start dagens trening' på Hjem-skjermen på iPad")
    }

    /// Verifies all three navigation destinations are reachable on iPad.
    /// iPadOS uses sidebar layout for TabView by default, so we query buttons
    /// across the whole app hierarchy rather than the tabBars container.
    func testIPadShowsAllTabs() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Hjem"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Statistikk"].exists)
        XCTAssertTrue(app.buttons["Innstillinger"].exists)
    }

    /// Verifies the app runs in native iPad mode, not iPhone-compatibility mode.
    /// On a 13" iPad the native width is well over 800pt; iPhone-compat mode caps
    /// the app window at iPhone-sized bounds (~430-635pt).
    /// Skipped when the test is executed on an iPhone simulator.
    func testIPadUsesNativeIPadWindowSize() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad,
                          "Only meaningful on iPad simulators")
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Start dagens trening"].waitForExistence(timeout: 5))
        let frame = app.windows.firstMatch.frame
        XCTAssertGreaterThan(frame.width, 800,
                             "Forventet native iPad-bredde (>800pt), fikk \(frame.width). " +
                             "Sannsynligvis kjører appen i iPhone-kompatibilitetsmodus.")
    }
}
