@testable import Tree_Tracker
import XCTest

class ProtectEarthCodableTests: XCTestCase {
    
    private var decoder: JSONDecoder = JSONDecoder()
    private var encoder: JSONEncoder = JSONEncoder()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        encoder.outputFormatting = .init(arrayLiteral: [.sortedKeys, .withoutEscapingSlashes, .prettyPrinted])
        encoder.dateEncodingStrategy = .iso8601
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
    
    func testProtectEarthSiteDecoding() throws {
        let json = """
        [
          {
            "id": "497f6eca-6276-4993-bfeb-53cbbbba6f08",
            "name": "Bourton on the Water",
            "location": "Cheltenham, England",
            "url": "https://www.protect.earth/projects/bourton-on-the-water",
            "plantedTrees": 710,
            "coordinates": {
              "latitude": 51.87351,
              "longitude": -1.90973
            }
          },
          {
            "id": "497f6eca-6276-4993-cdac-53cbbbba6f08",
            "name": "Slapton Bottom",
            "location": "Bodmin, England",
            "url": "https://www.protect.earth/projects/slapton-bottom",
            "plantedTrees": 5,
            "coordinates": {
              "latitude": 53.99991,
              "longitude": -1.80173
            }
          },
          {
            "id":"54e7d6f8-8c2a-4d7b-8ba8-90de42b55087",
            "name":"4C93CA3C-F8FC-4743-9F63-8CD2ED2537AF",
            "location":"",
            "url":null,
            "plantedTrees":0,
            "coordinates": {
              "latitude":0,
              "longitude":0
            }
          }
        ]
        """.data(using: .utf8)!
        
        let sites = try decoder.decode([ProtectEarthSite].self, from: json)
        
        XCTAssertNotNil(sites)
        XCTAssertEqual(3, sites.count)
        XCTAssertEqual("497f6eca-6276-4993-bfeb-53cbbbba6f08", sites[0].id)
        XCTAssertEqual("Slapton Bottom", sites[1].name)
        
        let site_0 = sites[0].toSite()
        XCTAssertEqual("497f6eca-6276-4993-bfeb-53cbbbba6f08", site_0.id)
        XCTAssertEqual("Bourton on the Water", site_0.name)
        
        let site_1 = sites[1].toSite()
        XCTAssertEqual("497f6eca-6276-4993-cdac-53cbbbba6f08", site_1.id)
        XCTAssertEqual("Slapton Bottom", site_1.name)
        
        let json_empty = "[]".data(using: .utf8)!
        let sites_empty = try decoder.decode([ProtectEarthSite].self, from: json_empty)
        
        XCTAssertNotNil(sites_empty)
        XCTAssertEqual(0, sites_empty.count)
    }
    
    func testProtectEarthSpeciesDecoding() throws {
        let json = """
        [{"id":"96c266a9-928b-48a7-9349-d88948e84bb4","name":"Quickthorn"},
         {"id":"96c266a9-ae0d-42c7-bee2-2181159cbf82","name":"MYSTERY"},
         {"id":"96c266a9-b06d-4173-9d1c-dd64e237774d","name":"Bird Cherry"}]
        """.data(using: .utf8)!
        
        let species = try decoder.decode([ProtectEarthSpecies].self, from: json)
        
        XCTAssertNotNil(species)
        XCTAssertEqual(3, species.count)
        XCTAssertEqual("96c266a9-928b-48a7-9349-d88948e84bb4", species[0].id)
        XCTAssertEqual("Quickthorn", species[0].name)
        
        let species_0 = species[0].toSpecies()
        let species_1 = species[1].toSpecies()
        
        XCTAssertEqual("96c266a9-928b-48a7-9349-d88948e84bb4", species_0.id)
        XCTAssertEqual("Quickthorn", species_0.name)
        XCTAssertEqual("96c266a9-ae0d-42c7-bee2-2181159cbf82", species_1.id)
        XCTAssertEqual("MYSTERY", species_1.name)
        
        let json_empty = "[]".data(using: .utf8)!
        let species_empty = try decoder.decode([ProtectEarthSpecies].self, from: json_empty)
        
        XCTAssertNotNil(species_empty)
        XCTAssertEqual(0, species_empty.count)
    }
    
    func testProtectEarthUploadEncoding() throws {
        let identifier = ProtectEarthIdentifier(id: "497f6eca-6276-4993-bfeb-53cbbbba6f08")
        let dateString = "2019-08-24T14:15:22Z"
        let formatter = ISO8601DateFormatter()
        let plantedDate = formatter.date(from: dateString)
        let sut = ProtectEarthUpload(imageUrl: "https://google.com",
                                     latitude: 51.87351,
                                     longitude: -1.90973,
                                     plantedAt: plantedDate!,
                                     supervisor: identifier,
                                     site: identifier,
                                     species: identifier)
        
        let json = try encoder.encode(sut)
        let jsonString = String(data: json, encoding: .utf8)
        let output = jsonString!.description
        print(output)
        XCTAssertTrue(output.contains(#""image_url" : "https://google.com","#))
        XCTAssertTrue(output.contains("""
              "site" : {
                "id" : "497f6eca-6276-4993-bfeb-53cbbbba6f08"
              },
            """), "site missing or malformed")
        XCTAssertTrue(output.contains("""
              "latitude" : 51.87351,
            """), "latitude missing or malformed")
        XCTAssertTrue(output.contains("""
              "longitude" : -1.90973,
            """), "longitude missing or malformed")
        XCTAssertTrue(output.contains("""
              "planted_at" : "2019-08-24T14:15:22Z",
            """), "planted_at missing or malformed")
    }

}
