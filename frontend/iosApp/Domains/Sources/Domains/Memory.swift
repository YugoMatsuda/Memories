import Foundation

public struct Memory: Sendable, Equatable, Hashable, Identifiable {
    public let id: Int
    public let albumId: Int
    public let title: String
    public let imageUrl: URL
    public let createdAt: Date

    public init(id: Int, albumId: Int, title: String, imageUrl: URL, createdAt: Date) {
        self.id = id
        self.albumId = albumId
        self.title = title
        self.imageUrl = imageUrl
        self.createdAt = createdAt
    }
}
