import XCTest
import Resolver

final class UploadSessionUITests: XCTestCase {
    
    private let app: XCUIApplication = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["--integration-test"]
        app.launch()
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
        
        app.buttons["Start new session"].tap()
        
        app.otherElements["Photos"].scrollViews.otherElements.images.firstMatch.tap()
        app.scrollViews.otherElements.textFields["Species"].tap()
        
        let speciesPicker = app.pickerWheels.firstMatch
        speciesPicker.swipeUp()
        let speciesName = String(describing: speciesPicker.value!)
        app.buttons["Done"].tap()
        
        app.buttons["Save"].tap()
        
        app.navigationBars["Photos"].buttons["Cancel"].tap()
        
        // Confirm queue is 1+ initial size
        app.tabBars["Tab Bar"].buttons["Queue"].tap()
        XCTAssertEqual(initialQueueSize + 1, app.collectionViews.cells.count)
        
        // Open edit view for most recent tree
        app.collectionViews.images.firstMatch.tap()
        
        let supervisorFinal = app.scrollViews.otherElements.textFields["Supervisor"].value!
        let speciesFinal = app.scrollViews.otherElements.textFields["Species"].value!
        let siteFinal = app.scrollViews.otherElements.textFields["Site"].value!
        
        // Confirm site/super/species are the values we selected earlier
        XCTAssertEqual(supervisorName, String(describing: supervisorFinal))
        XCTAssertEqual(speciesName, String(describing: speciesFinal))
        XCTAssertEqual(siteName, String(describing: siteFinal))
    }
}
