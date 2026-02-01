import Foundation
import Combine
import Domains
import Repositories
import APIGateways

public final class AlbumListUseCase: AlbumListUseCaseProtocol, @unchecked Sendable {
    private let userRepository: UserRepositoryProtocol
    private let albumRepository: AlbumRepositoryProtocol
    private let albumGateway: AlbumGatewayProtocol
    private let reachabilityRepository: ReachabilityRepositoryProtocol

    public var observeUser: AnyPublisher<User, Never> {
        userRepository.userPublisher
    }

    public var localChangePublisher: AnyPublisher<LocalAlbumChangeEvent, Never> {
        albumRepository.localChangePublisher
    }

    public init(
        userRepository: UserRepositoryProtocol,
        albumRepository: AlbumRepositoryProtocol,
        albumGateway: AlbumGatewayProtocol,
        reachabilityRepository: ReachabilityRepositoryProtocol
    ) {
        self.userRepository = userRepository
        self.albumRepository = albumRepository
        self.albumGateway = albumGateway
        self.reachabilityRepository = reachabilityRepository
    }

    public func display() async -> AlbumListUseCaseModel.DisplayResult {
        print("[AlbumListUseCase] display")
        if reachabilityRepository.isConnected {
            do {
                let response = try await albumGateway.getAlbums(page: 1, pageSize: Const.pageSize)
                let albums = response.items.map { AlbumMapper.toDomain($0) }
                do {
                    try await albumRepository.syncSet(albums)
                } catch {
                    print("[AlbumListUseCase] Failed to sync albums to cache: \(error)")
                }
                let hasMore = response.page * response.pageSize < response.total
                return .success(AlbumListUseCaseModel.PageInfo(albums: albums, hasMore: hasMore))
            } catch {
                // Fallback to cache on error
                let cached = await albumRepository.getAll()
                if !cached.isEmpty {
                    return .success(AlbumListUseCaseModel.PageInfo(albums: cached, hasMore: false))
                }
                return .failure(mapDisplayError(error))
            }
        } else {
            // Offline: get from cache
            let cached = await albumRepository.getAll()
            if cached.isEmpty {
                return .failure(.offline)
            }
            return .success(AlbumListUseCaseModel.PageInfo(albums: cached, hasMore: false))
        }
    }

    public func next(page: Int) async -> AlbumListUseCaseModel.NextResult {
        print("[AlbumListUseCase] next page: \(page)")
        // Pagination requires online
        guard reachabilityRepository.isConnected else {
            return .failure(.offline)
        }

        do {
            let response = try await albumGateway.getAlbums(page: page, pageSize: Const.pageSize)
            let albums = response.items.map { AlbumMapper.toDomain($0) }
            do {
                try await albumRepository.syncAppend(albums)
            } catch {
                print("[AlbumListUseCase] Failed to append albums to cache: \(error)")
            }
            let allAlbums = await albumRepository.getAll()
            let hasMore = response.page * response.pageSize < response.total
            return .success(AlbumListUseCaseModel.PageInfo(albums: allAlbums, hasMore: hasMore))
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

// MARK: - Const

extension AlbumListUseCase {
    private enum Const {
        static let pageSize = 5
    }
}
