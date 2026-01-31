import Foundation

public struct UserUpdateRequest: APIRequestProtocol {
    public let name: String?
    public let birthday: String?
    public let avatarUrl: String?

    public init(name: String?, birthday: String?, avatarUrl: String?) {
        self.name = name
        self.birthday = birthday
        self.avatarUrl = avatarUrl
    }

    public var path: String { "/me" }
    public var method: HTTPMethod { .put }
    public var headerType: HeaderType { .postJson }
    public var queryItems: [URLQueryItem]? { nil }

    public var httpBody: Data? {
        var body: [String: String] = [:]
        if let name { body["name"] = name }
        if let birthday { body["birthday"] = birthday }
        if let avatarUrl { body["avatar_url"] = avatarUrl }
        return try? JSONEncoder().encode(body)
    }
}
