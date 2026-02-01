import Foundation

/// Represents an optional update operation for a field.
/// Used in `with` copy methods to distinguish between:
/// - Not changing the field
/// - Explicitly setting the field to nil
/// - Setting a new value
public enum OptionalUpdate<T> {
    /// Keep the current value (don't update)
    case noChange
    /// Set to nil
    case setNil
    /// Set to a new value
    case set(T)

    /// Creates an OptionalUpdate from an optional value
    /// - nil becomes .setNil
    /// - value becomes .set(value)
    public static func from(_ value: T?) -> OptionalUpdate<T> {
        if let value = value {
            return .set(value)
        } else {
            return .setNil
        }
    }

    /// Resolves the update against the current value
    public func resolve(current: T?) -> T? {
        switch self {
        case .noChange:
            return current
        case .setNil:
            return nil
        case .set(let value):
            return value
        }
    }
}
