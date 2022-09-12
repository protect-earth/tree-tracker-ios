@testable import Tree_Tracker
import XCTest
import Resolver

class ProtectEarthSpeciesServiceTests: XCTestCase {
    
    private var speciesService: SpeciesService?
    private let DEFAULT_EXPECTATION_TIMEOUT = TimeInterval(5)

    override func setUpWithError() throws {
        speciesService = Resolver.resolve(SpeciesService.self)
        
        let expectation = expectation(description: "Sync()")
        speciesService!.sync() { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
    
    override func tearDownWithError() throws {
        // Revert to integrationTest resolver when leaving tests
        Resolver.root = Resolver.integrationTest
    }
    
    func test_sut_available() {
        XCTAssertNotNil(speciesService)
    }
    
    func test_fetchAll() throws {
        let expectation = expectation(description: "Get species")
        speciesService!.fetchAll() { result in
            expectation.fulfill()
            do {
                let species = try result.get()
                XCTAssertTrue( species.isNotEmpty )
                XCTAssertTrue( species.count > 1 )
                species.forEach() { XCTAssertNotNil( UUID(uuidString: $0.id) ) }
            } catch {
                XCTFail("Error fetching species: \(error)")
            }
        }
        waitForExpectations(timeout: DEFAULT_EXPECTATION_TIMEOUT)
    }
    
}
