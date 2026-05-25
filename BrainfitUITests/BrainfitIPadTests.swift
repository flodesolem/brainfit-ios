import XCTest

final class BrainfitIPadTests: XCTestCase {
    func testAppLaunchesOnIPadAndShowsHome() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Start dagens trening"].waitForExistence(timeout: 5),
                      "Forventet å se 'Start dagens trening' på Hjem-skjermen på iPad")
    }

    func testIPadShowsAllTabs() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Hjem"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Statistikk"].exists)
        XCTAssertTrue(app.tabBars.buttons["Innstillinger"].exists)
    }

    /// Verifies the app runs in native iPad mode, not iPhone-compatibility mode.
    /// On a 13" iPad the native width is well over 800pt; iPhone-compat mode caps
    /// the app window at iPhone-sized bounds (~430pt).
    func testIPadUsesNativeIPadWindowSize() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Start dagens trening"].waitForExistence(timeout: 5))
        let frame = app.windows.firstMatch.frame
        XCTAssertGreaterThan(frame.width, 800,
                             "Forventet native iPad-bredde (>800pt), fikk \(frame.width). " +
                             "Sannsynligvis kjører appen i iPhone-kompatibilitetsmodus.")
    }
}
