import Foundation

public struct PaginatedMemoriesResponse: Decodable, Sendable {
    public let items: [MemoryResponse]
    public let page: Int
    public let pageSize: Int
    public let total: Int

    public init(items: [MemoryResponse], page: Int, pageSize: Int, total: Int) {
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
