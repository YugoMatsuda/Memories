import Foundation
import Combine
import Domains
import Repositories

public enum AlbumListUseCaseModel {
    public struct PageInfo: Sendable {
        public let albums: [Album]
        public let hasMore: Bool

        public init(albums: [Album], hasMore: Bool) {
            self.albums = albums
            self.hasMore = hasMore
        }
    }

    public enum DisplayResult: Sendable {
        case success(PageInfo)
        case failure(Error)

        public enum Error: Sendable, Equatable {
            case networkError
            case offline
            case unknown
        }
    }

    public enum NextResult: Sendable {
        case success(PageInfo)
        case failure(Error)

        public enum Error: Sendable, Equatable {
            case networkError
            case offline
            case unknown
        }
    }
}

public protocol AlbumListUseCaseProtocol: Sendable {
    var observeUser: AnyPublisher<User, Never> { get }
    var localChangePublisher: AnyPublisher<LocalAlbumChangeEvent, Never> { get }
    func display() async -> AlbumListUseCaseModel.DisplayResult
    func next(page: Int) async -> AlbumListUseCaseModel.NextResult
}
