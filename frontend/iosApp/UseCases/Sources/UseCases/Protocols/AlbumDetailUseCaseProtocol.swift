import Foundation
import Domains

public enum AlbumDetailUseCaseModel {
    public struct PageInfo: Sendable {
        public let memories: [Memory]
        public let hasMore: Bool

        public init(memories: [Memory], hasMore: Bool) {
            self.memories = memories
            self.hasMore = hasMore
        }
    }

    public enum DisplayResult: Sendable {
        case success(PageInfo)
        case failure(Error)

        public enum Error: Sendable, Equatable {
            case networkError
            case unknown
        }
    }

    public enum NextResult: Sendable {
        case success(PageInfo)
        case failure(Error)

        public enum Error: Sendable, Equatable {
            case networkError
            case unknown
        }
    }
}

public protocol AlbumDetailUseCaseProtocol: Sendable {
    func display(albumId: Int) async -> AlbumDetailUseCaseModel.DisplayResult
    func next(albumId: Int, page: Int) async -> AlbumDetailUseCaseModel.NextResult
}
