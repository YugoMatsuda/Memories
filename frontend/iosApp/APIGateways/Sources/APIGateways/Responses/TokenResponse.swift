import Foundation

public struct TokenResponse: Decodable, Sendable {
    public let token: String
    public let userId: Int

    public init(token: String, userId: Int) {
        self.token = token
        self.userId = userId
    }

    private enum CodingKeys: String, CodingKey {
        case token
        case userId = "user_id"
    }
}
