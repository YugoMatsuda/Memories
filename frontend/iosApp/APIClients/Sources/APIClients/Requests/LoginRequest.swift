import Foundation

public struct LoginRequest: APIRequestProtocol {
    public let username: String
    public let password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    public var path: String { "/auth/login" }
    public var method: HTTPMethod { .post }
    public var headerType: HeaderType { .postJson }
    public var queryItems: [URLQueryItem]? { nil }

    public var httpBody: Data? {
        let body = ["username": username, "password": password]
        return try? JSONEncoder().encode(body)
    }
}
