@testable import Tree_Tracker
import XCTest
import Resolver

class ProtectEarthSupervisorServiceTests: XCTestCase {
    
    private var supervisorService: SupervisorService?
    private let DEFAULT_EXPECTATION_TIMEOUT = TimeInterval(5)

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Resolver.root = Resolver.protectEarthApi
        supervisorService = Resolver.resolve(SupervisorService.self)
        
        let expectation = expectation(description: "Sync()")
        supervisorService!.sync() { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
    
    func test_sut_available() {
        XCTAssertNotNil(supervisorService)
    }

    func test_fetchAll() throws {
        let expectation = expectation(description: "Get supervisors")
        supervisorService!.fetchAll() { result in
            expectation.fulfill()
            do {
                let supervisors = try result.get()
                XCTAssertTrue( supervisors.isNotEmpty )
                XCTAssertTrue( supervisors.count > 1 )
                supervisors.forEach() { XCTAssertNotNil( UUID(uuidString: $0.id) ) }
            } catch {
                XCTFail("Error fetching sites: \(error)")
            }
        }
        waitForExpectations(timeout: DEFAULT_EXPECTATION_TIMEOUT)
    }

}
