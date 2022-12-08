import XCTest
import Resolver

final class UploadSessionUITests: XCTestCase {
    
    private let app: XCUIApplication = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app.launchArguments = ["--integration-test"]
        app.launch()
        
        // prime settings
        app.tabBars["Tab Bar"].buttons["Settings"].tap()
        
        let tablesQuery = app.tables
        for entity in ["Sites","Supervisors","Species"] {
            tablesQuery.staticTexts[entity].tap()
            app.navigationBars[entity].buttons["Refresh"].tap()
            app.navigationBars[entity].buttons["Settings"].tap()
        }
        
    }
    
    func testStartSessionSelectingSiteAndSupervisor() throws {
        // Get initial queue size
        app.tabBars["Tab Bar"].buttons["Queue"].tap()
        let initialQueueSize = app.collectionViews.cells.count
        
        // Add one more tree to the queue
        app.tabBars["Tab Bar"].buttons["Session"].tap()
        app.textFields["Supervisor"].tap()
        
        let pickerWheel = app.pickerWheels.firstMatch
        pickerWheel.swipeUp()
        let supervisorName = String(describing: pickerWheel.value!)
        app.buttons["Done"].tap()
        
        app.textFields["Site"].tap()
        let sitePicker = app.pickerWheels.firstMatch
        sitePicker.swipeUp()
        let siteName = String(describing: sitePicker.value!)
        app.buttons["Done"].tap()
        
        _ = app.buttons["Start new session"].waitForExistence(timeout: 5)
        
        app.buttons["Start new session"].tap()
        
        // NOTE: In Simulator we only have photo library, but on device and in GitHub Actions, we have a camera picker controller!
        app.otherElements["Photos"].scrollViews.otherElements.images.firstMatch.tap()
        waitAndApproveAlertModal()
        app.scrollViews.otherElements.textFields["Species"].tap()
        
        let speciesPicker = app.pickerWheels.firstMatch
        speciesPicker.swipeUp()
        let speciesName = String(describing: speciesPicker.value!)
        app.buttons["Done"].tap()
        
        app.buttons["Save"].tap()
        
        app.navigationBars["Photos"].buttons["Cancel"].tap()
        
        // Confirm queue is 1+ initial size
        app.tabBars["Tab Bar"].buttons["Queue"].tap()
        XCTAssertEqual(initialQueueSize + 1, app.collectionViews.cells.count, "Upload queue length not incremented by the expected amount")
        
        // Open edit view for most recent tree
        app.collectionViews.images.firstMatch.tap()
        
        let supervisorFinal = app.scrollViews.otherElements.textFields["Supervisor"].value!
        let speciesFinal = app.scrollViews.otherElements.textFields["Species"].value!
        let siteFinal = app.scrollViews.otherElements.textFields["Site"].value!
        
        // Confirm site/super/species are the values we selected earlier
        XCTAssertEqual(supervisorName, String(describing: supervisorFinal), "Unexpected supervisor")
        XCTAssertEqual(speciesName, String(describing: speciesFinal), "Unexpected species")
        XCTAssertEqual(siteName, String(describing: siteFinal), "Unexpected site")
        
        
        
        
//        let app = XCUIApplication()
//        app/*@START_MENU_TOKEN@*/.staticTexts["Start new session"]/*[[".buttons[\"Start new session\"].staticTexts[\"Start new session\"]",".staticTexts[\"Start new session\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        app/*@START_MENU_TOKEN@*/.buttons["PhotoCapture"]/*[[".buttons[\"Take Picture\"]",".buttons[\"PhotoCapture\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        
//        let doneButton = app/*@START_MENU_TOKEN@*/.buttons["Done"]/*[[".buttons[\"Use Photo\"]",".buttons[\"Done\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
//        doneButton.tap()
//        
//        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0)
//        element.tap()
//        doneButton.tap()
//        element.tap()
//        doneButton.tap()
//                
//        
        
        
        
    }
    
    private func waitAndApproveAlertModal() {
        // Ref: https://stackoverflow.com/questions/39973904/handler-of-adduiinterruptionmonitor-is-not-called-for-alert-related-to-photos
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        let alertAllowButton = springboard.buttons.element(boundBy: 1)
        if alertAllowButton.waitForExistence(timeout: 5) {
           alertAllowButton.tap()
        }
    }
}
