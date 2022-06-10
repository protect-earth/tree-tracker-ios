@testable import Tree_Tracker
import Foundation
import Resolver
import XCTest
import Combine

class AirtableSiteServiceTests: XCTestCase {
    
    @Injected private var siteService: SiteService
    @Injected private var sessionFactory: AirtableSessionFactory
    
    private var newSiteName: String = UUID.init().uuidString
    
    private var cancellables: Set<AnyCancellable> = []
    
    private var deleteQueue: [Site] = []
    
    override func setUp() {
        let expectation = expectation(description: "Sync()")
        siteService.sync() { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
    
    override func tearDown() {
        // Delete the sites from Airtable otherwise these will accumulate!!
        let session = sessionFactory.get()
        if deleteQueue.isNotEmpty {
            deleteQueue.forEach { site in
                var siteUrl = sessionFactory.getSitesUrl()
                siteUrl.appendPathComponent(site.id)
                let request = session.request(siteUrl,
                                              method: .delete)
                
                let expectation = expectation(description: "Site deletion")
                
                request.validate().response { _ in
                    print("Deleted site \(site.id)")
                    expectation.fulfill()
                }
            }
            waitForExpectations(timeout: 5)
        }
    }
    
    func test_sut_available() {
        XCTAssertNotNil(siteService)
    }
    
    func test_fetchAll() {
        let expectation = expectation(description: "Get sites")
        siteService.fetchAll() { result in
            expectation.fulfill()
            do {
                let sites = try result.get()
                XCTAssertTrue( sites.isNotEmpty )
                XCTAssertTrue( sites.count > 1 )
            } catch {
                XCTFail("Error fetching sites: \(error)")
            }
        }
        waitForExpectations(timeout: 5)
    }
    
    func test_fetchAll_andAdd() {
        
        var initialSites: [Site] = []
        var newSites: [Site] = []
        
        // expect and wait for fetching sites before add
        let getInitialExpectation = expectation(description: "Get initial sites list")
        
        siteService.fetchAll() { result in
            getInitialExpectation.fulfill()
            do {
                initialSites = try result.get()
            } catch {
                XCTFail("Error fetching sites: \(error)")
            }
        }
        
        waitForExpectations(timeout: 1)
        
        // expect and wait for addition of new site
        let addSiteExpectation = expectation(description: "Add site")
        
        siteService.addSite(name: newSiteName) { _ in
            addSiteExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
        // expect and wait for the results of a subsequent fetch of sites
        let getUpdatedExpectation = expectation(description: "Get updated sites list")
            
        siteService.fetchAll() { result in
            getUpdatedExpectation.fulfill()
            do {
                newSites = try result.get()
            } catch {
                XCTFail("Error fetching sites: \(error)")
            }
        }
        
        waitForExpectations(timeout: 1)
        
        XCTAssertNotNil(newSites)
        // new sites should be 1 more than original list
        XCTAssertTrue(newSites.count == (initialSites.count + 1))
        // and should contain a site with our new name
        let newSite = newSites.first(where: { $0.name == newSiteName })
        XCTAssertNotNil(newSite)
        
        deleteQueue.append(newSite!)
    }
    
    func test_addPublishesUpdatedSitesList() {
        
        var initialSites: [Site] = []
        var newPublishedSites: [Site] = []
        
        // expect and wait for fetching sites before add
        let getInitialExpectation = expectation(description: "Get initial sites list")
        
        siteService.fetchAll() { result in
            getInitialExpectation.fulfill()
            do {
                initialSites = try result.get()
            } catch {
                XCTFail("Error fetching sites: \(error)")
            }
        }
        
        waitForExpectations(timeout: 1)
        
        let publisherExpectation = expectation(description: "Add triggers publisher")
        
        // capture publishing of updated sites (happens later!)
        siteService.sitesPublisher.sink() { sites in
            if ( sites.count == (initialSites.count + 1) &&
                 sites.contains(where: { self.newSiteName == $0.name })) {
                newPublishedSites = sites
                // We have fulfilled the expectation that sites list should be increased
                // and should contain a site with our new name
                publisherExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // now add the new site, fire and forget style
        let addExpectation = expectation(description: "Add site")
        siteService.addSite(name: newSiteName, completion: { _ in
            addExpectation.fulfill()
        })
        
        // wait for the add site and publisher expectations (getInitial having already been fulfilled)
        // note that this is effectively also an assertion
        waitForExpectations(timeout: 1)
        
        // and should also contain a site with our new name
        let newSite = newPublishedSites.first(where: { $0.name == newSiteName })
        XCTAssertNotNil(newSite)
        
        deleteQueue.append(newSite!)
    }
    
}
