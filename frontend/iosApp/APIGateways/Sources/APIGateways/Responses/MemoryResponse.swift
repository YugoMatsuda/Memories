import Foundation

public struct MemoryResponse: Decodable, Sendable {
    public let id: Int
    public let albumId: Int
    public let title: String
    public let imageLocalUri: String?
    public let imageRemoteUrl: String?
    public let createdAt: String

    public init(id: Int, albumId: Int, title: String, imageLocalUri: String?, imageRemoteUrl: String?, createdAt: String) {
        self.id = id
        self.albumId = albumId
        self.title = title
        self.imageLocalUri = imageLocalUri
        self.imageRemoteUrl = imageRemoteUrl
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case albumId = "album_id"
        case title
        case imageLocalUri = "image_local_uri"
        case imageRemoteUrl = "image_remote_url"
        case createdAt = "created_at"
    }
}
