import Foundation

protocol Logging {
    func log(_ message: String)
    func log(_ category: LogCategory, _ message: String)
}

struct LogCategory {
    let name: String
}

struct Logger: Logging {
    enum Output {
        case print
        case osLog
        case disabled
    }
    
    var output: Output
    
    func log(_ category: LogCategory, _ message: String) {
        _log(category: category, message)
    }
    
    func log(_ message: String) {
        _log(message)
    }
    
    private func _log(category: LogCategory? = nil, _ message: String) {
        switch output {
        case .print:
            if let category = category {
                print("[\(category.name)] \(message)")
            } else {
                print(message)
            }
        case .osLog:
            break
        case .disabled:
            break
        }
    }
}
