@testable import Tree_Tracker
import XCTest

class ProtectEarthCodableTests: XCTestCase {
    
    private var decoder: JSONDecoder = JSONDecoder()
    private var encoder: JSONEncoder = JSONEncoder()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testProtectEarthSupervisorDecoding() throws {
        let json = """
        [
          {
            "id": "497f6eca-6276-4993-bfeb-53cbbbba6f08",
            "name": "Spag Bol"
          },
          {
            "id": "334f6bbc-6276-4993-bfeb-53cbbbba6f08",
            "name": "Clam Chowder"
          }
        ]
        """.data(using: .utf8)!
        
        let supervisors = try decoder.decode([ProtectEarthSupervisor].self, from: json)
        
        XCTAssertNotNil(supervisors)
        XCTAssertEqual(2, supervisors.count)
        XCTAssertEqual("Spag Bol", supervisors[0].name)
        XCTAssertEqual("497f6eca-6276-4993-bfeb-53cbbbba6f08", supervisors[0].id)
        XCTAssertEqual("Clam Chowder", supervisors[1].name)
        XCTAssertEqual("334f6bbc-6276-4993-bfeb-53cbbbba6f08", supervisors[1].id)
        
        let super_0 = supervisors[0].toSupervisor()
        XCTAssertEqual("Spag Bol", super_0.name)
        XCTAssertEqual("497f6eca-6276-4993-bfeb-53cbbbba6f08", super_0.id)
        
        let json_empty = "[]".data(using: .utf8)!
        let supervisors_empty = try decoder.decode([ProtectEarthSupervisor].self, from: json_empty)
        
        XCTAssertNotNil(supervisors_empty)
        XCTAssertEqual(0, supervisors_empty.count)
    }

}
