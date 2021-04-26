@testable import Tree_Tracker
import XCTest

final class RecentSpeciesManagerTests: XCTestCase {
    var defaults: Defaults!
    var manager: RecentSpeciesManager!
    
    override func setUp() {
        defaults = Defaults(userDefaults: UserDefaults(suiteName: "com.test.userdefaults\(Int.random(in: 0...1_000_000_000))")!)
        manager = RecentSpeciesManager(defaults: defaults, strategy: .todayUsedSpecies)
    }
    
    override func tearDown() {
        for (key, _) in defaults.userDefaults.dictionaryRepresentation() {
            defaults.userDefaults.removeObject(forKey: key)
        }
    }
    
    func test_fetchReturnsNothing_whenDidntAddAnythingYet() {
        XCTAssertEqual(manager.fetch(), [])
    }
    
    func test_fetchSpeciesRecentlyAdded_whenStrategyTodayUsedSpecies() {
        let species = Species(id: "1", name: "test")
        manager.add(species, timestamp: .now)
        
        XCTAssertEqual(manager.fetch(), [species])
    }
    
    func test_fetchSpeciesOnlyFromToday_whenStrategyTodayUsedSpecies() {
        let todaySpecies = [Species(id: "1", name: "test1"), Species(id: "3", name: "test3")]
        let oldSpecies = [Species(id: "2", name: "test2"), Species(id: "4", name: "test4")]
        
        todaySpecies.forEach { manager.add($0, timestamp: .now) }
        oldSpecies.forEach { manager.add($0, timestamp: .generateRandomYesterdayDate()) }
        
        XCTAssertEqual(manager.fetch(), todaySpecies)
    }
    
    func test_fetchReturnsNothing_whenStrategyTodayUsedSpeciesButWeClearedAll() {
        let species = Species(id: "1", name: "test")
        manager.add(species, timestamp: .now)
        manager.clearAll()
        
        XCTAssertEqual(manager.fetch(), [])
    }
}
