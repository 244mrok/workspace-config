import XCTest

final class MeasurementInputBugTest: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    private func saveScreenshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let dir = "/tmp/heroacademia_evidence"
        try? FileManager.default.createDirectory(
            atPath: dir, withIntermediateDirectories: true
        )
        FileManager.default.createFile(
            atPath: "\(dir)/\(name).png",
            contents: screenshot.pngRepresentation
        )
    }

    private func navigateToMeasurementInput() {
        let tab = app.tabBars.buttons["計測記録"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()
        sleep(1)

        let navBar = app.navigationBars["計測記録"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5))
        navBar.buttons.element(boundBy: 0).tap()
        sleep(1)
    }

    private func dismissKeyboard() {
        if app.keyboards.count > 0 {
            app.navigationBars["計測を記録"].tap()
            sleep(1)
        }
    }

    // MARK: - Test 1: Weight only → body fat stays empty

    func testWeightOnlySave() throws {
        navigateToMeasurementInput()

        let weightField = app.textFields["weightField"]
        let bodyFatField = app.textFields["bodyFatField"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))
        XCTAssertTrue(bodyFatField.exists)

        // Type weight only
        weightField.tap()
        sleep(1)
        weightField.typeText("68.5")
        saveScreenshot("t1_01_weight_typed")

        // Body fat must still be empty
        let fatVal = bodyFatField.value as? String ?? ""
        XCTAssertTrue(
            fatVal.isEmpty || fatVal == "0.0",
            "Body fat must be empty, got: '\(fatVal)'"
        )

        // Save
        dismissKeyboard()
        app.buttons["保存"].tap()
        sleep(3)
        saveScreenshot("t1_02_after_save")

        // Verify weight appears in list
        let weightCell = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '68.5'"))
        XCTAssertTrue(weightCell.firstMatch.waitForExistence(timeout: 10), "Weight 68.5 should appear")
    }

    // MARK: - Test 2: Body fat only → weight stays empty

    func testBodyFatOnlySave() throws {
        navigateToMeasurementInput()

        let weightField = app.textFields["weightField"]
        let bodyFatField = app.textFields["bodyFatField"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))

        // Type body fat only
        bodyFatField.tap()
        sleep(1)
        bodyFatField.typeText("22.3")
        saveScreenshot("t2_01_bodyfat_typed")

        // Weight must still be empty
        let weightVal = weightField.value as? String ?? ""
        XCTAssertTrue(
            weightVal.isEmpty || weightVal == "0.0",
            "Weight must be empty, got: '\(weightVal)'"
        )

        // Save
        dismissKeyboard()
        app.buttons["保存"].tap()
        sleep(3)
        saveScreenshot("t2_02_after_save")

        // Verify body fat appears
        let fatCell = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '22.3'"))
        XCTAssertTrue(fatCell.firstMatch.waitForExistence(timeout: 10), "Body fat 22.3 should appear")
    }

    // MARK: - Test 3: Weight first, then body fat → both saved independently

    func testBothFieldsIndependent() throws {
        navigateToMeasurementInput()

        let weightField = app.textFields["weightField"]
        let bodyFatField = app.textFields["bodyFatField"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))

        // Type weight
        weightField.tap()
        sleep(1)
        weightField.typeText("71.0")
        saveScreenshot("t3_01_weight_typed")

        // Switch to body fat and type
        bodyFatField.tap()
        sleep(1)
        bodyFatField.typeText("19.5")
        saveScreenshot("t3_02_bodyfat_typed")

        // Verify weight wasn't overwritten
        let weightAfter = weightField.value as? String ?? ""
        XCTAssertTrue(
            weightAfter.contains("71"),
            "Weight should still be ~71.0, got: '\(weightAfter)'"
        )

        // Verify body fat is correct
        let fatAfter = bodyFatField.value as? String ?? ""
        XCTAssertTrue(
            fatAfter.contains("19.5"),
            "Body fat should be 19.5, got: '\(fatAfter)'"
        )

        // Save
        dismissKeyboard()
        app.buttons["保存"].tap()
        sleep(3)
        saveScreenshot("t3_03_after_save")

        // Verify both values in list
        let weightText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '71.0'"))
        let fatText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '19.5'"))
        XCTAssertTrue(weightText.firstMatch.waitForExistence(timeout: 10), "Weight 71.0 should appear")
        XCTAssertTrue(fatText.firstMatch.waitForExistence(timeout: 5), "Body fat 19.5 should appear")
        saveScreenshot("t3_04_verified")
    }

    // MARK: - Test 4: Body fat first, then weight → both saved independently

    func testBodyFatFirstThenWeight() throws {
        navigateToMeasurementInput()

        let weightField = app.textFields["weightField"]
        let bodyFatField = app.textFields["bodyFatField"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))

        // Type body fat first
        bodyFatField.tap()
        sleep(1)
        bodyFatField.typeText("16.8")
        saveScreenshot("t4_01_bodyfat_first")

        // Switch to weight and type
        weightField.tap()
        sleep(1)
        weightField.typeText("74.2")
        saveScreenshot("t4_02_weight_second")

        // Verify body fat wasn't overwritten
        let fatAfter = bodyFatField.value as? String ?? ""
        XCTAssertTrue(
            fatAfter.contains("16.8"),
            "Body fat should still be 16.8, got: '\(fatAfter)'"
        )

        // Save
        dismissKeyboard()
        app.buttons["保存"].tap()
        sleep(3)
        saveScreenshot("t4_03_after_save")

        let weightText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '74.2'"))
        let fatText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '16.8'"))
        XCTAssertTrue(weightText.firstMatch.waitForExistence(timeout: 10), "Weight 74.2 should appear")
        XCTAssertTrue(fatText.firstMatch.waitForExistence(timeout: 5), "Body fat 16.8 should appear")
        saveScreenshot("t4_04_verified")
    }
}
