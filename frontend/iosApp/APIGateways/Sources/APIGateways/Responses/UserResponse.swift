import Foundation

public struct UserResponse: Decodable, Sendable {
    public let id: Int
    public let name: String
    public let username: String
    public let birthday: String?
    public let avatarUrl: String?

    public init(id: Int, name: String, username: String, birthday: String?, avatarUrl: String?) {
        self.id = id
        self.name = name
        self.username = username
        self.birthday = birthday
        self.avatarUrl = avatarUrl
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case username
        case birthday
        case avatarUrl = "avatar_url"
    }
}
