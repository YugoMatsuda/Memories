import Foundation

@propertyWrapper
public struct EquatableNoop<Value>: Equatable {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public static func == (lhs: EquatableNoop<Value>, rhs: EquatableNoop<Value>) -> Bool {
        true
    }
}

extension EquatableNoop: Sendable where Value: Sendable {}
