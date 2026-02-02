import Foundation
import Shared

// Type alias for KMP AuthSession
public typealias AuthSession = Shared.AuthSession

// MARK: - Swift-friendly extensions

extension Shared.AuthSession {
    /// Create AuthSession with Swift Int
    public static func create(token: String, userId: Int) -> Shared.AuthSession {
        Shared.AuthSession(token: token, userId: Int32(userId))
    }

    /// User ID as Swift Int
    public var userIdInt: Int {
        Int(userId)
    }
}
