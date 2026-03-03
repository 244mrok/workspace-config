import XCTest

final class GoalEditUITests: XCTestCase {
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
        let path = "\(dir)/\(name).png"
        FileManager.default.createFile(atPath: path, contents: screenshot.pngRepresentation)
    }

    func testGoalCreateAndEdit() throws {
        let dashboardTab = app.tabBars.buttons["ダッシュボード"]
        guard dashboardTab.waitForExistence(timeout: 10) else {
            XCTFail("Dashboard tab should exist (user must be logged in)")
            return
        }
        dashboardTab.tap()
        sleep(2)
        saveScreenshot("goal_01_dashboard")

        // --- Step 1: Create a goal ---
        // Check if "目標を設定する" button exists.
        // With multi-goal support, this button shows when < 2 goals are active.
        let setGoalButton = app.staticTexts["目標を設定する"]
        let hasAddButton = setGoalButton.waitForExistence(timeout: 3)
        // Check if a goal card already exists on the dashboard
        let hasExistingGoal = app.staticTexts["目標"].exists

        if hasAddButton {
            // Tap the "目標を設定する" button to open goal setting sheet
            setGoalButton.tap()
            sleep(1)
            saveScreenshot("goal_02_setting_sheet_create")

            // Verify create mode title
            let createTitle = app.navigationBars["目標を設定"]
            XCTAssertTrue(createTitle.waitForExistence(timeout: 3), "Title should be '目標を設定' in create mode")

            // Type picker: enabled when no goals exist, disabled when adding a second goal type
            let weightSegment = app.buttons["体重"]
            XCTAssertTrue(weightSegment.exists)
            if hasExistingGoal {
                XCTAssertFalse(weightSegment.isEnabled, "Type picker should be disabled when one goal type already exists")
            } else {
                XCTAssertTrue(weightSegment.isEnabled, "Type picker should be enabled with no existing goals")
            }

            // Fill in 現在値 (first text field with placeholder "0.0")
            let textFields = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.0'"))
            guard textFields.count >= 2 else {
                XCTFail("Expected at least 2 text fields with placeholder '0.0'")
                return
            }

            let startValueField = textFields.element(boundBy: 0)
            startValueField.tap()
            startValueField.typeText("72")

            let targetValueField = textFields.element(boundBy: 1)
            targetValueField.tap()
            targetValueField.typeText("65")
            saveScreenshot("goal_03_values_filled")

            // Dismiss keyboard if visible
            if app.keyboards.count > 0 {
                createTitle.tap()
                sleep(1)
            }

            // Tap 保存
            let saveButton = app.buttons["保存"]
            XCTAssertTrue(saveButton.exists)
            saveButton.tap()
            sleep(3)
            saveScreenshot("goal_04_after_create")
        } else {
            saveScreenshot("goal_02_all_goals_set")
        }

        // --- Step 2: Verify goal card appears on dashboard ---
        let goalLabel = app.staticTexts["目標"]
        XCTAssertTrue(
            goalLabel.waitForExistence(timeout: 5),
            "Goal card with '目標' label should appear on dashboard"
        )
        saveScreenshot("goal_05_goal_card_visible")

        // --- Step 3: Tap goal card to open edit sheet ---
        goalLabel.tap()
        sleep(1)
        saveScreenshot("goal_06_edit_sheet")

        // Verify edit mode title
        let editTitle = app.navigationBars["目標を編集"]
        XCTAssertTrue(
            editTitle.waitForExistence(timeout: 3),
            "Title should be '目標を編集' in edit mode"
        )

        // Verify 現在値 is read-only (static text, not a text field) in edit mode.
        // In create mode there are 2 text fields; in edit mode only 1 (目標値).
        let editTextFields = app.textFields.allElementsBoundByIndex
        let editableFieldCount = editTextFields.count
        XCTAssertEqual(editableFieldCount, 1, "Edit mode should have only 1 editable text field (目標値)")
        saveScreenshot("goal_07_edit_mode_verified")

        // --- Step 4: Change the target value ---
        // Find the target value text field (should be the only "0.0" placeholder field, or has existing value)
        if editableFieldCount > 0 {
            let targetField = editTextFields[0]
            targetField.tap()
            // Select all and replace
            targetField.press(forDuration: 1.0)
            sleep(1)
            if app.menuItems["Select All"].waitForExistence(timeout: 2) {
                app.menuItems["Select All"].tap()
            }
            targetField.typeText("63")
            saveScreenshot("goal_08_target_changed")
        }

        // Dismiss keyboard
        if app.keyboards.count > 0 {
            editTitle.tap()
            sleep(1)
        }

        // Save the edit
        let saveEditButton = app.buttons["保存"]
        saveEditButton.tap()
        sleep(3)
        saveScreenshot("goal_09_after_edit_save")

        // Verify we're back on dashboard with updated goal
        XCTAssertTrue(
            dashboardTab.waitForExistence(timeout: 5),
            "Should return to dashboard after saving edit"
        )
        saveScreenshot("goal_10_final_dashboard")
    }
}
