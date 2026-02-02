import Foundation
import Combine
import Domains
import Repositories
import APIGateways

public final class AlbumDetailUseCase: AlbumDetailUseCaseProtocol, @unchecked Sendable {
    private let memoryRepository: MemoryRepositoryProtocol
    private let albumRepository: AlbumRepositoryProtocol
    private let memoryGateway: MemoryGatewayProtocol
    private let reachabilityRepository: ReachabilityRepositoryProtocol

    public var localChangePublisher: AnyPublisher<LocalMemoryChangeEvent, Never> {
        memoryRepository.localChangePublisher
    }

    public var observeAlbumUpdate: AnyPublisher<LocalAlbumChangeEvent, Never> {
        albumRepository.localChangePublisher
    }

    public init(
        memoryRepository: MemoryRepositoryProtocol,
        albumRepository: AlbumRepositoryProtocol,
        memoryGateway: MemoryGatewayProtocol,
        reachabilityRepository: ReachabilityRepositoryProtocol
    ) {
        self.memoryRepository = memoryRepository
        self.albumRepository = albumRepository
        self.memoryGateway = memoryGateway
        self.reachabilityRepository = reachabilityRepository
    }

    public func display(album: Album) async -> AlbumDetailUseCaseModel.DisplayResult {
        // If album is not synced yet, only show local memories
        guard let albumServerId = album.id else {
            let cached = await memoryRepository.getAll(albumLocalId: album.localId)
            return .success(AlbumDetailUseCaseModel.PageInfo(memories: cached, hasMore: false))
        }

        if reachabilityRepository.isConnected {
            do {
                let response = try await memoryGateway.getMemories(albumId: albumServerId, page: 1, pageSize: Const.pageSize)
                let memories = response.items.compactMap { MemoryMapper.toDomain($0, albumLocalId: album.localId) }
                try? await memoryRepository.syncSet(memories, albumLocalId: album.localId)
                let allMemories = await memoryRepository.getAll(albumLocalId: album.localId)
                let hasMore = response.page * response.pageSize < response.total
                return .success(AlbumDetailUseCaseModel.PageInfo(memories: allMemories, hasMore: hasMore))
            } catch {
                // Fallback to cache on error
                let cached = await memoryRepository.getAll(albumLocalId: album.localId)
                if !cached.isEmpty {
                    return .success(AlbumDetailUseCaseModel.PageInfo(memories: cached, hasMore: false))
                }
                return .failure(mapDisplayError(error))
            }
        } else {
            // Offline: get from cache (empty is valid - album may have no memories yet)
            let cached = await memoryRepository.getAll(albumLocalId: album.localId)
            return .success(AlbumDetailUseCaseModel.PageInfo(memories: cached, hasMore: false))
        }
    }

    public func next(album: Album, page: Int) async -> AlbumDetailUseCaseModel.NextResult {
        // Pagination requires online and synced album
        guard reachabilityRepository.isConnected else {
            return .failure(.offline)
        }

        guard let albumServerId = album.id else {
            return .failure(.offline)
        }

        do {
            let response = try await memoryGateway.getMemories(albumId: albumServerId, page: page, pageSize: Const.pageSize)
            let memories = response.items.compactMap { MemoryMapper.toDomain($0, albumLocalId: album.localId) }
            try? await memoryRepository.syncAppend(memories)
            let allMemories = await memoryRepository.getAll(albumLocalId: album.localId)
            let hasMore = response.page * response.pageSize < response.total
            return .success(AlbumDetailUseCaseModel.PageInfo(memories: allMemories, hasMore: hasMore))
        } catch {
            return .failure(mapNextError(error))
        }
    }

    private func mapDisplayError(_ error: Error) -> AlbumDetailUseCaseModel.DisplayResult.Error {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkError
        }
        return .unknown
    }

    private func mapNextError(_ error: Error) -> AlbumDetailUseCaseModel.NextResult.Error {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkError
        }
        return .unknown
    }
}

// MARK: - Const

extension AlbumDetailUseCase {
    private enum Const {
        static let pageSize = 5
    }
}
