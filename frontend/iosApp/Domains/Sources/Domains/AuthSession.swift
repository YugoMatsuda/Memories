import Foundation

public struct AuthSession: Sendable {
    public let token: String
    public let userId: Int

    public init(token: String, userId: Int) {
        self.token = token
        self.userId = userId
    }
}
