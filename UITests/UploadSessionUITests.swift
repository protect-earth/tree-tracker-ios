import XCTest

final class UploadSessionUITests: XCTestCase {
    
    private let app: XCUIApplication = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    func x_testStartSessionSelectingSiteAndSupervisor() throws {
        app.tabBars["Tab Bar"].buttons["Session"].tap()
        app.textFields["Supervisor"].tap()
        
        let pickerWheel = app/*@START_MENU_TOKEN@*/.pickerWheels["--"]/*[[".pickers.pickerWheels[\"--\"]",".pickerWheels[\"--\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        pickerWheel.swipeUp()
        app/*@START_MENU_TOKEN@*/.staticTexts["Done"]/*[[".buttons[\"Done\"].staticTexts[\"Done\"]",".staticTexts[\"Done\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        app.textFields["Site"].tap()
        let sitePicker = app.pickerWheels["--"]
        sitePicker.swipeUp()
        app/*@START_MENU_TOKEN@*/.staticTexts["Done"]/*[[".buttons[\"Done\"].staticTexts[\"Done\"]",".staticTexts[\"Done\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        app/*@START_MENU_TOKEN@*/.staticTexts["Start new session"]/*[[".buttons[\"Start new session\"].staticTexts[\"Start new session\"]",".staticTexts[\"Start new session\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
}
