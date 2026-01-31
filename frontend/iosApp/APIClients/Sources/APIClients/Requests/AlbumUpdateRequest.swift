import Foundation

public struct AlbumUpdateRequest: APIRequestProtocol {
    public let albumId: Int
    public let title: String?
    public let coverImageUrl: String?

    public init(albumId: Int, title: String?, coverImageUrl: String?) {
        self.albumId = albumId
        self.title = title
        self.coverImageUrl = coverImageUrl
    }

    public var path: String { "/albums/\(albumId)" }
    public var method: HTTPMethod { .put }
    public var headerType: HeaderType { .postJson }
    public var queryItems: [URLQueryItem]? { nil }

    public var httpBody: Data? {
        var body: [String: String] = [:]
        if let title { body["title"] = title }
        if let coverImageUrl { body["cover_image_url"] = coverImageUrl }
        return try? JSONEncoder().encode(body)
    }
}
