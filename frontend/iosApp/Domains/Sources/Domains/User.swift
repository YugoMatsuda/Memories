import Foundation

public struct User: Sendable, Equatable, Hashable {
    public let id: Int
    public let name: String
    public let username: String
    public let birthday: Date?
    public let avatarUrl: URL?

    public init(id: Int, name: String, username: String, birthday: Date?, avatarUrl: URL?) {
        self.id = id
        self.name = name
        self.username = username
        self.birthday = birthday
        self.avatarUrl = avatarUrl
    }
}
