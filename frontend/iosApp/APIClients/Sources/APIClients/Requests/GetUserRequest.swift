import Foundation

public struct GetUserRequest: APIRequestProtocol {
    public init() {}

    public var path: String { "/me" }
    public var method: HTTPMethod { .get }
    public var headerType: HeaderType { .getJson }
    public var httpBody: Data? { nil }
    public var queryItems: [URLQueryItem]? { nil }
}
