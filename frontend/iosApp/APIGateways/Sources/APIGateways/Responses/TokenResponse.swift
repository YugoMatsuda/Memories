import Foundation

public struct TokenResponse: Decodable, Sendable {
    public let token: String

    public init(token: String) {
        self.token = token
    }
}
