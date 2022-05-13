@testable import Tree_Tracker
import Foundation

extension Date {
    static func generateRandomYesterdayDate() -> Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    }
}
