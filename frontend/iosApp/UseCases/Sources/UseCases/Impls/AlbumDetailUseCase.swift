import Foundation
import Combine
import Domains
import Repositories
@preconcurrency import Shared
import APIGateways

public final class AlbumDetailUseCase: AlbumDetailUseCaseProtocol, @unchecked Sendable {
    private let memoryRepository: MemoryRepositoryProtocol
    private let albumRepository: AlbumRepositoryProtocol
    private let albumGateway: AlbumGatewayProtocol
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
        albumGateway: AlbumGatewayProtocol,
        memoryGateway: MemoryGatewayProtocol,
        reachabilityRepository: ReachabilityRepositoryProtocol
    ) {
        self.memoryRepository = memoryRepository
        self.albumRepository = albumRepository
        self.albumGateway = albumGateway
        self.memoryGateway = memoryGateway
        self.reachabilityRepository = reachabilityRepository
    }

    public func display(album: Album) async -> AlbumDetailUseCaseModel.DisplayResult {
        // If album is not synced yet, only show local memories
        guard let albumServerId = album.id else {
            let cached = await memoryRepository.getAll(albumLocalId: album.localIdUUID)
            return .success(AlbumDetailUseCaseModel.PageInfo(memories: cached, hasMore: false))
        }

        if reachabilityRepository.isConnected {
            do {
                let response = try await memoryGateway.getMemories(albumId: albumServerId, page: 1, pageSize: Const.pageSize)
                let memories = response.items.compactMap { Shared.MemoryMapper.shared.toDomain(response: $0, albumLocalId: album.localId) }
                try? await memoryRepository.syncSet(memories, albumLocalId: album.localIdUUID)
                let allMemories = await memoryRepository.getAll(albumLocalId: album.localIdUUID)
                let hasMore = Int(response.page) * Int(response.pageSize) < Int(response.total)
                return .success(AlbumDetailUseCaseModel.PageInfo(memories: allMemories, hasMore: hasMore))
            } catch {
                // Fallback to cache on error
                let cached = await memoryRepository.getAll(albumLocalId: album.localIdUUID)
                if !cached.isEmpty {
                    return .success(AlbumDetailUseCaseModel.PageInfo(memories: cached, hasMore: false))
                }
                return .failure(mapDisplayError(error))
            }
        } else {
            // Offline: get from cache (empty is valid - album may have no memories yet)
            let cached = await memoryRepository.getAll(albumLocalId: album.localIdUUID)
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
            let memories = response.items.compactMap { Shared.MemoryMapper.shared.toDomain(response: $0, albumLocalId: album.localId) }
            try? await memoryRepository.syncAppend(memories)
            let allMemories = await memoryRepository.getAll(albumLocalId: album.localIdUUID)
            let hasMore = Int(response.page) * Int(response.pageSize) < Int(response.total)
            return .success(AlbumDetailUseCaseModel.PageInfo(memories: allMemories, hasMore: hasMore))
        } catch {
            return .failure(mapNextError(error))
        }
    }

    public func resolveAlbum(serverId: Int) async -> AlbumDetailUseCaseModel.ResolveAlbumResult {
        if reachabilityRepository.isConnected {
            do {
                let response = try await albumGateway.getAlbum(id: serverId)
                let album = Shared.AlbumMapper.shared.toDomain(response: response)
                try? await albumRepository.syncSet([album])
                // Return from cache to get preserved localId
                if let cachedAlbum = await albumRepository.get(byServerId: serverId) {
                    return .success(cachedAlbum)
                }
                return .success(album)
            } catch let error as Shared.ApiError {
                if error is Shared.ApiError.NotFound {
                    return .failure(.notFound)
                }
                if error is Shared.ApiError.NetworkError {
                    return .failure(.networkError)
                }
                return .failure(.notFound)
            } catch {
                return .failure(.notFound)
            }
        } else {
            // Offline: try cache
            if let cachedAlbum = await albumRepository.get(byServerId: serverId) {
                return .success(cachedAlbum)
            }
            return .failure(.offlineUnavailable)
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
