import Foundation

public struct GetAlbumsRequest: APIRequestProtocol {
    public let page: Int
    public let pageSize: Int

    public init(page: Int = 1, pageSize: Int = 20) {
        self.page = page
        self.pageSize = pageSize
    }

    public var path: String { "/albums" }
    public var method: HTTPMethod { .get }
    public var headerType: HeaderType { .getJson }
    public var httpBody: Data? { nil }

    public var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: String(pageSize))
        ]
    }
}
