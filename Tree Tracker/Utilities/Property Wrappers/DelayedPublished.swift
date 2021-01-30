import Combine
import Foundation

@propertyWrapper
final class DelayedPublished<Value> {
    typealias Publisher = AnyPublisher<Value, Never>

    private var _value: Value? = nil
    private var subject = PassthroughSubject<Value, Never>()

    var wrappedValue: Value {
        get {
            guard let value = _value else {
                fatalError("Property accessed before being initialized.")
            }
            return value
        }
        set {
            _value = newValue
            subject.send(newValue)
        }
    }

    var projectedValue: Publisher {
        return subject.eraseToAnyPublisher()
    }
}
