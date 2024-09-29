@testable import Tree_Tracker
import XCTest
import Resolver

class ProtectEarthSiteServiceTests: XCTestCase {
    
    private var siteService: SiteService?
    private let DEFAULT_EXPECTATION_TIMEOUT = TimeInterval(5)

    override func setUpWithError() throws {
        siteService = Resolver.resolve(SiteService.self)
        
        let expectation = expectation(description: "Sync()")
        siteService!.sync() { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    override func tearDownWithError() throws {
        // Revert to integrationTest resolver when leaving tests
        Resolver.root = Resolver.integrationTest
    }
    
    func test_sut_available() {
        XCTAssertNotNil(siteService)
    }

    func test_fetchAll() throws {
        let expectation = expectation(description: "Get sites")
        siteService!.fetchAll() { result in
            expectation.fulfill()
            do {
                let sites = try result.get()
                XCTAssertTrue( sites.isNotEmpty )
                XCTAssertTrue( sites.count > 1 )
                sites.forEach() { XCTAssertNotNil( UUID(uuidString: $0.id) ) }
            } catch {
                XCTFail("Error fetching sites: \(error)")
            }
        }
        waitForExpectations(timeout: DEFAULT_EXPECTATION_TIMEOUT)
    }

}
