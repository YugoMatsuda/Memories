import Foundation

public struct GetAlbumRequest: APIRequestProtocol {
    public let albumId: Int

    public init(albumId: Int) {
        self.albumId = albumId
    }

    public var path: String { "/albums/\(albumId)" }
    public var method: HTTPMethod { .get }
    public var headerType: HeaderType { .getJson }
    public var httpBody: Data? { nil }
    public var queryItems: [URLQueryItem]? { nil }
}
