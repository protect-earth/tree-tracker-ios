import XCTest

final class SettingsUITests: XCTestCase {
    
    private let app: XCUIApplication = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    func testSettingsSitesContainsTestSite() throws {
        app.tabBars["Tab Bar"].buttons["Settings"].tap()
        
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Sites"]/*[[".cells.staticTexts[\"Sites\"]",".staticTexts[\"Sites\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        XCTAssert(app.navigationBars["Sites"].buttons["Refresh"].exists)
        XCTAssert(app.navigationBars["Sites"].buttons["Add"].exists == false)
        
        XCTAssert(tablesQuery.cells.containing(.staticText, identifier: "TEST SITE").element.exists)
                
    }
}
