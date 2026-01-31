import Foundation

public struct PaginatedAlbumsResponse: Decodable, Sendable {
    public let items: [AlbumResponse]
    public let page: Int
    public let pageSize: Int
    public let total: Int

    public init(items: [AlbumResponse], page: Int, pageSize: Int, total: Int) {
        self.items = items
        self.page = page
        self.pageSize = pageSize
        self.total = total
    }

    enum CodingKeys: String, CodingKey {
        case items
        case page
        case pageSize = "page_size"
        case total
    }
}
