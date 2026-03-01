import XCTest

final class AuthFlowUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    /// Save a screenshot as XCTest attachment and to /tmp/evidence/
    private func saveScreenshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()

        // Attach to test results
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // Also save to /tmp/evidence/ for easy extraction
        let dir = "/tmp/heroacademia_evidence"
        try? FileManager.default.createDirectory(
            atPath: dir, withIntermediateDirectories: true
        )
        let path = "\(dir)/\(name).png"
        FileManager.default.createFile(atPath: path, contents: screenshot.pngRepresentation)
    }

    // MARK: - Full Flow Test

    func testFullSignUpAndMeasurementFlow() throws {
        let measurementNavTitle = app.navigationBars["計測記録"]
        let emailField = app.textFields["emailField"]

        if measurementNavTitle.waitForExistence(timeout: 3) {
            saveScreenshot("01_already_logged_in")
            try testMeasurementAddFlow()
            try testMeasurementDeleteFlow()
        } else {
            XCTAssertTrue(emailField.waitForExistence(timeout: 10), "Email field should exist")
            saveScreenshot("01_login_screen")
            try testSignUpFlow()
            try testMeasurementAddFlow()
        }
    }

    // MARK: - Sign Up Flow

    private func testSignUpFlow() throws {
        let toggleButton = app.buttons["toggleModeButton"]
        XCTAssertTrue(toggleButton.exists)
        toggleButton.tap()
        saveScreenshot("02_signup_mode")

        let emailField = app.textFields["emailField"]
        emailField.tap()
        emailField.typeText("uitest\(Int(Date().timeIntervalSince1970))@test.com")

        let passwordField = app.secureTextFields["passwordField"]
        passwordField.tap()
        passwordField.typeText("testpass123")
        saveScreenshot("03_signup_filled")

        let submitButton = app.buttons["submitButton"]
        submitButton.tap()

        let measurementNavTitle = app.navigationBars["計測記録"]
        XCTAssertTrue(
            measurementNavTitle.waitForExistence(timeout: 15),
            "Should navigate to measurement list after signup"
        )
        saveScreenshot("04_after_signup")
    }

    // MARK: - Add Measurement Flow

    private func testMeasurementAddFlow() throws {
        let measurementNavTitle = app.navigationBars["計測記録"]
        XCTAssertTrue(measurementNavTitle.waitForExistence(timeout: 5))

        let addButton = measurementNavTitle.buttons.element(boundBy: 0)
        XCTAssertTrue(addButton.exists, "Add button should exist")
        addButton.tap()

        let saveButton = app.buttons["保存"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Save button should appear")
        saveScreenshot("05_input_empty")

        let weightField = app.textFields["weightField"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))
        if weightField.isHittable {
            weightField.tap()
        } else {
            app.swipeDown()
            sleep(1)
            weightField.tap()
        }
        weightField.typeText("65.3")

        let bodyFatField = app.textFields["bodyFatField"]
        bodyFatField.tap()
        bodyFatField.typeText("15.8")
        saveScreenshot("06_input_filled")

        if app.keyboards.count > 0 {
            app.navigationBars["計測を記録"].tap()
            sleep(1)
        }
        saveScreenshot("07_input_ready")

        saveButton.tap()
        XCTAssertTrue(measurementNavTitle.waitForExistence(timeout: 10))

        let weightText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '65.3'"))
        XCTAssertTrue(
            weightText.firstMatch.waitForExistence(timeout: 10),
            "Measurement with weight 65.3 should appear"
        )
        saveScreenshot("08_after_add")
    }

    // MARK: - Delete Measurement Flow

    private func testMeasurementDeleteFlow() throws {
        let measurementNavTitle = app.navigationBars["計測記録"]
        XCTAssertTrue(measurementNavTitle.waitForExistence(timeout: 5))

        let cellsBefore = app.cells.count
        guard cellsBefore > 0 else {
            XCTFail("Need at least one measurement to test delete")
            return
        }
        saveScreenshot("09_before_delete")

        let firstCell = app.cells.element(boundBy: 0)
        firstCell.swipeLeft()
        sleep(1)
        saveScreenshot("10_swipe_delete")

        if app.buttons["Delete"].waitForExistence(timeout: 3) {
            app.buttons["Delete"].tap()
        } else if app.buttons["削除"].waitForExistence(timeout: 3) {
            app.buttons["削除"].tap()
        }

        // Wait for Firestore listener to update
        sleep(3)
        saveScreenshot("11_after_delete")

        let cellsAfter = app.cells.count
        XCTAssertEqual(cellsAfter, cellsBefore - 1, "Should have one less measurement")
    }

    // MARK: - Validation Test

    func testMeasurementValidation() throws {
        let measurementNavTitle = app.navigationBars["計測記録"]
        guard measurementNavTitle.waitForExistence(timeout: 5) else { return }

        measurementNavTitle.buttons.element(boundBy: 0).tap()

        let saveButton = app.buttons["保存"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveScreenshot("12_empty_form")

        saveButton.tap()
        sleep(1)
        saveScreenshot("13_validation_error")

        let errorText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '入力してください'")
        )
        XCTAssertTrue(
            errorText.firstMatch.waitForExistence(timeout: 5),
            "Validation error should appear when no data entered"
        )

        let cancelButton = app.buttons["キャンセル"]
        if cancelButton.exists {
            cancelButton.tap()
        }
        saveScreenshot("14_after_cancel")
    }
}
