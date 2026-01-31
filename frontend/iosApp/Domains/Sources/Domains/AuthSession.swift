import Foundation

public struct AuthSession: Sendable {
    public let token: String

    public init(token: String) {
        self.token = token
    }
}
