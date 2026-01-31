import Foundation

public struct Album: Sendable, Equatable, Hashable, Identifiable {
    public let id: Int
    public let title: String
    public let coverImageUrl: URL?
    public let createdAt: Date

    public init(id: Int, title: String, coverImageUrl: URL?, createdAt: Date) {
        self.id = id
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.createdAt = createdAt
    }
}
