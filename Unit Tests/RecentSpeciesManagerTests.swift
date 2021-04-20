@testable import Tree_Tracker
import XCTest

final class RecentSpeciesManagerTests: XCTestCase {
    var defaults: Defaults!
    var manager: RecentSpeciesManager!
    
    override func setUp() {
        defaults = Defaults(userDefaults: UserDefaults(suiteName: "com.test.userdefaults")!)
        manager = RecentSpeciesManager(defaults: defaults, strategy: .todayUsedSpecies)
    }
    
    func test_fetchReturnsNothing_whenDidntAddAnythingYet() {
        XCTAssertTrue(manager.fetch().isEmpty)
    }
    
    func test_fetchReturnsSpeciesRecentlyAdded_whenStrategyTodayUsedSpecies() {
        let species = Species(id: "1", name: "test")
        manager.add(species)
        
        XCTAssertEqual(manager.fetch(), [species])
    }
}
