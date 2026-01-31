import Foundation

public struct AlbumResponse: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let coverImageUrl: String?
    public let createdAt: String

    public init(id: Int, title: String, coverImageUrl: String?, createdAt: String) {
        self.id = id
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case coverImageUrl = "cover_image_url"
        case createdAt = "created_at"
    }
}
