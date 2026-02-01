import Foundation
import Combine
import Domains
import Repositories

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
            case offline
            case networkError
            case unknown
        }
    }

    public enum NextResult: Sendable {
        case success(PageInfo)
        case failure(Error)

        public enum Error: Sendable, Equatable {
            case offline
            case networkError
            case unknown
        }
    }
}

public protocol AlbumDetailUseCaseProtocol: Sendable {
    func display(album: Album) async -> AlbumDetailUseCaseModel.DisplayResult
    func next(album: Album, page: Int) async -> AlbumDetailUseCaseModel.NextResult
    var localChangePublisher: AnyPublisher<LocalMemoryChangeEvent, Never> { get }
    var observeAlbumUpdate: AnyPublisher<LocalAlbumChangeEvent, Never> { get }
}
