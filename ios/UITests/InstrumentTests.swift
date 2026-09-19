import XCTest

final class InstrumentTests: XCTestCase {
    @MainActor func testThemesControlsAndRotation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-state"]
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        XCTAssertTrue(app.buttons["theme-menu"].waitForExistence(timeout: 10))
        capture("portrait-light", app)
        app.buttons["theme-menu"].tap()
        app.buttons["Dark"].tap()
        XCTAssertEqual(app.buttons["theme-menu"].value as? String, "Dark")
        capture("portrait-dark", app)
        let accessible = app.buttons["control-pages"].exists
        if accessible {
            app.buttons["panel-toggle"].tap()
            XCTAssertTrue(app.buttons["control-bank"].isHittable)
            capture("accessible-controls", app)
            app.buttons["close-controls"].tap()
        } else {
            app.buttons["panel-toggle"].tap()
            XCTAssertFalse(app.buttons["control-bank"].isHittable)
        }
        XCTAssertTrue(app.buttons["theme-menu"].isHittable)
        capture("portrait-play", app)
        selectTab("synth", app)
        XCTAssertTrue(app.buttons["control-bank"].isHittable)
        if accessible { app.buttons["close-controls"].tap() }
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.buttons["panic"].waitForExistence(timeout: 5))
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.frame.width > app.frame.height
        }, object: nil)], timeout: 5), .completed)
        capture("landscape-synth", app)
        if accessible { selectTab("synth", app) }
        app.buttons["control-bank"].tap()
        chooseBank("FILTER", app)
        XCTAssertTrue(app.otherElements["cutoff"].isHittable)
        if accessible { app.buttons["close-controls"].tap() }
        selectTab("pad", app)
        app.buttons["control-bank"].tap()
        chooseBank("APPEARANCE", app)
        XCTAssertTrue(app.buttons["coloring"].isHittable)
        if accessible { app.buttons["close-controls"].tap() }
        app.buttons["panic"].tap()
        // A lifecycle transition flushes the preference before relaunch.
        XCUIDevice.shared.press(.home)
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertEqual(app.buttons["theme-menu"].value as? String, "Dark")
        app.buttons["theme-menu"].tap()
        app.buttons["System"].tap()
        XCTAssertEqual(app.buttons["theme-menu"].value as? String, "System")
        if !accessible {
            selectTab("pad", app)
            for layout in ["Hexagon", "Piano", "Keys (Chromatic)", "Keys (Piano)", "Square"] {
                app.buttons["control-bank"].tap()
                chooseBank("PADMATRIX", app)
                app.buttons["layout"].tap()
                app.buttons[layout].tap()
                XCTAssertEqual(app.buttons["layout"].value as? String, layout)
                app.buttons["panel-toggle"].tap()
                capture("layout-\(layout)", app)
                app.buttons["panel-toggle"].tap()
            }
        }
    }

    @MainActor private func chooseBank(_ name: String, _ app: XCUIApplication) {
        let bank = app.buttons[name]
        if app.collectionViews["bank-list"].exists {
            for _ in 0..<6 {
                if bank.exists && bank.isHittable { break }
                app.collectionViews["bank-list"].swipeUp()
            }
        }
        bank.tap()
    }

    @MainActor private func selectTab(_ tab: String, _ app: XCUIApplication) {
        if app.buttons["control-pages"].exists {
            app.buttons["control-pages"].tap()
            app.buttons["tab-\(tab)"].tap()
        } else if !app.buttons["tab-\(tab)"].isSelected {
            app.buttons["tab-\(tab)"].tap()
        }
    }

    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        // Wait for the native menu/rotation transaction to finish rendering.
        Thread.sleep(forTimeInterval: 0.6)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
