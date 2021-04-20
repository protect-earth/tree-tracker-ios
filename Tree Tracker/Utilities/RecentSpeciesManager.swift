import Foundation

protocol RecentSpeciesManaging {
    func fetch() -> [Species]
    func add(_ species: Species)
    func clearAll()
}

final class RecentSpeciesManager: RecentSpeciesManaging {
    enum Strategy {
        case todayUsedSpecies
    }
    
    private let defaults: DefaultsProviding
    private let strategy: Strategy
    
    init(defaults: DefaultsProviding, strategy: Strategy) {
        self.defaults = defaults
        self.strategy = strategy
    }
    
    func fetch() -> [Species] {
        let allRecentSpecies = defaults[.recentSpecies] ?? []
        let filteredRecentSpecies = allRecentSpecies.filter { species in
            switch strategy {
            case .todayUsedSpecies:
                return species.timestamp.isToday
            }
        }
        defaults[.recentSpecies] = filteredRecentSpecies
        
        return filteredRecentSpecies.map(\.species)
    }
    
    func add(_ species: Species) {
        var recentSpecies = defaults[.recentSpecies] ?? []
        guard !recentSpecies.contains(where: { $0.species == species }) else { return }
        
        recentSpecies.append(RecentSpecies(timestamp: Date(), species: species))
        defaults[.recentSpecies] = recentSpecies
    }
    
    func clearAll() {
        defaults[.recentSpecies] = []
    }
}
