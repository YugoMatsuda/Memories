import Foundation

public struct AlbumCreateRequest: APIRequestProtocol {
    public let title: String
    public let coverImageUrl: String?

    public init(title: String, coverImageUrl: String?) {
        self.title = title
        self.coverImageUrl = coverImageUrl
    }

    public var path: String { "/albums" }
    public var method: HTTPMethod { .post }
    public var headerType: HeaderType { .postJson }
    public var queryItems: [URLQueryItem]? { nil }

    public var httpBody: Data? {
        var body: [String: String] = ["title": title]
        if let coverImageUrl { body["cover_image_url"] = coverImageUrl }
        return try? JSONEncoder().encode(body)
    }
}
