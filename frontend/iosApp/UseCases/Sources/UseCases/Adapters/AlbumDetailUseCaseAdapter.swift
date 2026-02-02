import Foundation
import Combine
import Domains
import Repositories
@preconcurrency import Shared

/// Adapter that wraps KMP AlbumDetailUseCase to conform to Swift AlbumDetailUseCaseProtocol
public final class AlbumDetailUseCaseAdapter: AlbumDetailUseCaseProtocol, @unchecked Sendable {
    private let kmpUseCase: Shared.AlbumDetailUseCase

    public init(kmpUseCase: Shared.AlbumDetailUseCase) {
        self.kmpUseCase = kmpUseCase
    }

    // MARK: - Observe (KMP Flow → Swift Publisher)

    public var localChangePublisher: AnyPublisher<Repositories.LocalMemoryChangeEvent, Never> {
        kmpUseCase.localChangeFlow
            .asPublisher()
            .compactMap { kmpEvent -> Repositories.LocalMemoryChangeEvent? in
                if let created = kmpEvent as? Shared.LocalMemoryChangeEvent.Created {
                    return .created(created.memory)
                }
                return nil
            }
            .eraseToAnyPublisher()
    }

    public var observeAlbumUpdate: AnyPublisher<Repositories.LocalAlbumChangeEvent, Never> {
        kmpUseCase.observeAlbumUpdate
            .asPublisher()
            .compactMap { kmpEvent -> Repositories.LocalAlbumChangeEvent? in
                if let created = kmpEvent as? Shared.LocalAlbumChangeEvent.Created {
                    return .created(created.album)
                } else if let updated = kmpEvent as? Shared.LocalAlbumChangeEvent.Updated {
                    return .updated(updated.album)
                }
                return nil
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Actions (delegated to KMP UseCase)

    public func display(album: Album) async -> AlbumDetailUseCaseModel.DisplayResult {
        do {
            let result = try await kmpUseCase.display(album: album)
            if let success = result as? Shared.MemoryDisplayResult.Success {
                let pageInfo = AlbumDetailUseCaseModel.PageInfo(
                    memories: success.pageInfo.memories,
                    hasMore: success.pageInfo.hasMore
                )
                return .success(pageInfo)
            } else if let failure = result as? Shared.MemoryDisplayResult.Failure {
                return .failure(mapDisplayError(failure.error))
            }
            return .failure(.unknown)
        } catch {
            return .failure(.unknown)
        }
    }

    public func next(album: Album, page: Int) async -> AlbumDetailUseCaseModel.NextResult {
        do {
            let result = try await kmpUseCase.next(album: album, page: Int32(page))
            if let success = result as? Shared.MemoryNextResult.Success {
                let pageInfo = AlbumDetailUseCaseModel.PageInfo(
                    memories: success.pageInfo.memories,
                    hasMore: success.pageInfo.hasMore
                )
                return .success(pageInfo)
            } else if let failure = result as? Shared.MemoryNextResult.Failure {
                return .failure(mapNextError(failure.error))
            }
            return .failure(.unknown)
        } catch {
            return .failure(.unknown)
        }
    }

    public func resolveAlbum(serverId: Int) async -> AlbumDetailUseCaseModel.ResolveAlbumResult {
        do {
            let result = try await kmpUseCase.resolveAlbum(serverId: Int32(serverId))
            if let success = result as? Shared.ResolveAlbumResult.Success {
                return .success(success.album)
            } else if let failure = result as? Shared.ResolveAlbumResult.Failure {
                return .failure(mapResolveError(failure.error))
            }
            return .failure(.networkError)
        } catch {
            return .failure(.networkError)
        }
    }

    // MARK: - Error Mapping

    private func mapDisplayError(_ error: Shared.MemoryDisplayError) -> AlbumDetailUseCaseModel.DisplayResult.Error {
        switch error {
        case .offline: return .offline
        case .networkError: return .networkError
        default: return .unknown
        }
    }

    private func mapNextError(_ error: Shared.MemoryNextError) -> AlbumDetailUseCaseModel.NextResult.Error {
        switch error {
        case .offline: return .offline
        case .networkError: return .networkError
        default: return .unknown
        }
    }

    private func mapResolveError(_ error: Shared.ResolveAlbumError) -> AlbumDetailUseCaseModel.ResolveAlbumResult.Error {
        switch error {
        case .notFound: return .notFound
        case .networkError: return .networkError
        case .offlineUnavailable: return .offlineUnavailable
        default: return .networkError
        }
    }
}
