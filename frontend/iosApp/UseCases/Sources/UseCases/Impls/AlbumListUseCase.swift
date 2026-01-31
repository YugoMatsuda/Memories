import Foundation
import Combine
import Domains
import Repositories
import APIGateways

public final class AlbumListUseCase: AlbumListUseCaseProtocol, @unchecked Sendable {
    private let userRepository: UserRepositoryProtocol
    private let albumGateway: AlbumGatewayProtocol
    private let pageSize = 8

    public var observeUser: AnyPublisher<User, Never> {
        userRepository.userPublisher
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    public init(userRepository: UserRepositoryProtocol, albumGateway: AlbumGatewayProtocol) {
        self.userRepository = userRepository
        self.albumGateway = albumGateway
    }

    public func display() async -> AlbumListUseCaseModel.DisplayResult {
        do {
            print("AlbumListUseCase display")
            let response = try await albumGateway.getAlbums(page: 1, pageSize: pageSize)
            let albums = response.items.map { AlbumMapper.toDomain($0) }
            let hasMore = response.page * response.pageSize < response.total
            return .success(AlbumListUseCaseModel.PageInfo(albums: albums, hasMore: hasMore))
        } catch {
            return .failure(mapDisplayError(error))
        }
    }

    public func next(page: Int) async -> AlbumListUseCaseModel.NextResult {
        do {
            print("AlbumListUseCase Next", page)
            let response = try await albumGateway.getAlbums(page: page, pageSize: pageSize)
            let albums = response.items.map { AlbumMapper.toDomain($0) }
            let hasMore = response.page * response.pageSize < response.total
            return .success(AlbumListUseCaseModel.PageInfo(albums: albums, hasMore: hasMore))
        } catch {
            return .failure(mapNextError(error))
        }
    }

    private func mapDisplayError(_ error: Error) -> AlbumListUseCaseModel.DisplayResult.Error {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkError
        }
        return .unknown
    }

    private func mapNextError(_ error: Error) -> AlbumListUseCaseModel.NextResult.Error {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkError
        }
        return .unknown
    }
}
